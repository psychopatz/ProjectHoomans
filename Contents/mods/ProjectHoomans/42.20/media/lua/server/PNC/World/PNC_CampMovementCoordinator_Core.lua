-- Bounded, server-owned movement sequencing for group camps.
--
-- Group CAMP admission and zone discovery happen once. This coordinator then
-- gives the normal AtCamp behavior one live movement owner at a time. Other
-- members already have their durable camp order, but remain held until their
-- turn; no per-NPC action plan or competing path request is created.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.CampMovementCoordinator = PNC.CampMovementCoordinator or {}

local Coordinator = PNC.CampMovementCoordinator
local Core = PNC.Core
local Const = PNC.Const

Coordinator.VERSION = 1
Coordinator.PUMP_INTERVAL_MS = 250
Coordinator.NEXT_PLACEMENT_DELAY_MS = 400
Coordinator.MAX_MOVE_MS = 60000
Coordinator.BLOCKED_TIMEOUT_MS = 10000
Coordinator.MAX_QUEUE = 32
Coordinator.MAX_SESSIONS = 8
Coordinator.Sessions = Coordinator.Sessions or {}
Coordinator.SessionOrder = Coordinator.SessionOrder or {}
Coordinator.ActiveSessionID = Coordinator.ActiveSessionID
Coordinator.PendingCount = tonumber(Coordinator.PendingCount)
    or #Coordinator.SessionOrder
Coordinator.NextPumpAt = tonumber(Coordinator.NextPumpAt) or 0

local function number(value, fallback)
    value = tonumber(value)
    if value ~= nil and value == value then return value end
    return fallback
end

local function text(value, fallback, maximum)
    if value == nil then return fallback end
    value = tostring(value)
    if maximum then value = string.sub(value, 1, maximum) end
    return value ~= "" and value or fallback
end

local function call(object, method, ...)
    local fn = object and object[method]
    local ok
    local first
    local second
    if type(fn) ~= "function" then return nil end
    ok, first, second = pcall(fn, object, ...)
    if not ok then return nil end
    return first, second
end

local function primitiveCopy(value, depth)
    local valueType = type(value)
    local output
    local child
    if value == nil then return nil end
    if valueType == "number" or valueType == "string"
        or valueType == "boolean"
    then
        return value
    end
    if valueType ~= "table" or (depth or 0) >= 3 then return nil end
    output = {}
    for key, childValue in pairs(value) do
        if type(key) == "string" or type(key) == "number" then
            child = primitiveCopy(childValue, (depth or 0) + 1)
            if child ~= nil then output[key] = child end
        end
    end
    return output
end

local function compactSite(site)
    local output = {}
    local bounds
    if type(site) ~= "table" then return output end
    output.kind = text(site.kind, "camp_site", 32)
    output.scope = text(site.scope or site.siteScope, "campfire", 32)
    output.siteScope = output.scope
    output.siteID = text(site.siteID, nil, 128)
    output.roomID = text(site.roomID, nil, 128)
    output.buildingID = text(site.buildingID, nil, 128)
    output.roomType = text(site.roomType, nil, 48)
    output.roomName = text(site.roomName, nil, 64)
    output.campfireID = text(site.campfireID, nil, 128)
    output.label = text(site.label, "room", 64)
    output.risk = text(site.risk, nil, 32)
    output.x = number(site.x or site.targetX)
    output.y = number(site.y or site.targetY)
    output.z = number(site.z or site.targetZ, 0)
    output.movementX = number(site.movementX or output.x)
    output.movementY = number(site.movementY or output.y)
    output.movementZ = number(site.movementZ or output.z, 0)
    output.radius = number(site.radius, 3)
    output.resourceRadius = number(site.resourceRadius, 12)
    output.stopDistance = number(site.stopDistance, 0.7)
    bounds = primitiveCopy(site.roomBounds)
    if bounds then output.roomBounds = bounds end
    return output
end

local function compactAssignment(assignment, zone)
    local output = {}
    assignment = type(assignment) == "table" and assignment or {}
    output.zoneID = text(zone and zone.siteID or assignment.zoneID, nil, 128)
    output.zoneLabel = text(zone and zone.label or assignment.zoneLabel,
        "room", 64)
    output.needKind = text(assignment.needKind, nil, 32)
    output.reason = text(assignment.reason, "initial_root_zone", 64)
    output.score = number(assignment.score)
    output.assignmentRevision = number(assignment.assignmentRevision)
    return output
end

local function runtimeNow(fallback)
    if number(fallback) ~= nil then return number(fallback) end
    if Core and type(Core.Now) == "function" then
        local value = Core.Now()
        if number(value) ~= nil then return number(value) end
    end
    return 0
end

local function playerKey(player)
    local value
    if player and type(player.getOnlineID) == "function" then
        local onlineID = player:getOnlineID()
        if onlineID ~= nil then value = tostring(onlineID) end
    end
    if value and value ~= "" then return value end
    if player and type(player.getUsername) == "function" then
        local username = player:getUsername()
        if username ~= nil and tostring(username) ~= "" then
            return tostring(username)
        end
    end
    return "player"
end

local function recordFor(npcID)
    local registry = PNC.Registry
    if not registry or type(registry.Get) ~= "function" then return nil end
    return registry.Get(npcID)
end

local function liveBody(record)
    local registry = PNC.Registry
    if not registry or type(registry.GetLiveZombie) ~= "function" then
        return nil
    end
    local body = registry.GetLiveZombie(record and record.id)
    if not body then return nil end
    if body.isDead and body:isDead() then return nil end
    return body
end

local function bodyCoordinate(body, record, method, fieldName)
    local value = call(body, method)
    if number(value) ~= nil then return number(value) end
    return number(record and record[fieldName])
end

local function isLiveRecord(record)
    local expected = Const and Const.PRESENCE_LIVE or "live"
    local presence
    if not record or record.alive == false then return false end
    presence = record.presenceState
    if presence ~= nil and tostring(presence) ~= tostring(expected) then
        return false
    end
    return liveBody(record) ~= nil
end

local function distanceTo(site, body, record)
    local x = bodyCoordinate(body, record, "getX", "x")
    local y = bodyCoordinate(body, record, "getY", "y")
    local sx = number(site and (site.movementX or site.x))
    local sy = number(site and (site.movementY or site.y))
    if x == nil or y == nil or sx == nil or sy == nil then return nil end
    return math.sqrt((x - sx) * (x - sx) + (y - sy) * (y - sy))
end

local function boundsContain(bounds, x, y, z)
    local minX
    local minY
    local maxX
    local maxY
    local boundZ
    if type(bounds) ~= "table" then return false end
    x = number(x)
    y = number(y)
    if x == nil or y == nil then return false end
    minX = number(bounds.minX or bounds.x)
    minY = number(bounds.minY or bounds.y)
    maxX = number(bounds.maxX or bounds.x2)
    maxY = number(bounds.maxY or bounds.y2)
    boundZ = number(bounds.z)
    if minX == nil or minY == nil or maxX == nil or maxY == nil then
        return false
    end
    if x < minX or x > maxX or y < minY or y > maxY then return false end
    return boundZ == nil
        or math.abs((number(z) or 0) - boundZ) <= 0.75
end

local function reached(zone, body, record)
    local scope = string.lower(tostring(zone and (
        zone.scope or zone.siteScope) or ""))
    local x = bodyCoordinate(body, record, "getX", "x")
    local y = bodyCoordinate(body, record, "getY", "y")
    local z = bodyCoordinate(body, record, "getZ", "z") or 0
    local distance = distanceTo(zone, body, record)
    local stopDistance = math.max(0.25, number(zone and zone.stopDistance,
        scope == "room" and 0.7 or 1.25))
    if scope == "room" then
        local square = call(body, "getCurrentSquare")
        local geometry = PNC.Semantics
            and PNC.Semantics.CampSiteGeometry or nil
        if square and geometry and type(geometry.MatchesRoom) == "function" then
            local matched = geometry.MatchesRoom(square, zone)
            if matched == true then return true end
        end
        if boundsContain(zone and zone.roomBounds, x, y, z) then
            return true
        end
        if math.abs(z - number(zone and zone.z, z)) > 0.75 then
            return false
        end
        return distance ~= nil
            and distance <= math.max(stopDistance,
                number(zone and zone.radius, 3))
    end
    if distance == nil then return false end
    if math.abs(z - number(zone and zone.z, z)) > 0.75 then return false end
    return distance <= stopDistance
end

local function movementState(record, body, at)
    local pathService = PNC.PathService
    local getter = pathService and pathService.GetMovementRecoveryState
    if type(getter) ~= "function" then return nil end
    return getter(record, body, at)
end

local function buildOrder(session, entry, record, placementState)
    local commands = PNC.CompanionCommands
    local definition = commands and type(commands.Get) == "function"
        and commands.Get("camp") or nil
    local options
    local order
    if not definition or type(definition.buildOrder) ~= "function" then
        return nil, "camp_definition_unavailable"
    end
    options = {
        x = entry.zone.movementX or entry.zone.x,
        y = entry.zone.movementY or entry.zone.y,
        z = entry.zone.movementZ or entry.zone.z,
        movementX = entry.zone.movementX or entry.zone.x,
        movementY = entry.zone.movementY or entry.zone.y,
        movementZ = entry.zone.movementZ or entry.zone.z,
        campId = session.id,
        campSite = entry.zone,
        campRoot = session.root,
        zone = entry.zone,
        zoneAssignment = entry.assignment,
        campDirectoryRevision = session.directoryRevision,
        placementState = placementState,
        placementCampID = session.id,
        placementIndex = entry.index,
    }
    order = definition.buildOrder(record, nil, options)
    if type(order) ~= "table" then
        return nil, "invalid_camp_order"
    end
    return order
end

local function writePlacementRuntime(record, session, entry, state, at,
    reason)
    local runtime
    local previous
    if not record then return end
    runtime = record.runtime or {}
    record.runtime = runtime
    previous = runtime.campPlacement
    runtime.campPlacement = {
        campID = session.id,
        state = state,
        queueIndex = entry.index,
        queueCount = #session.queue,
        startedAt = state == "moving" and at
            or previous and previous.startedAt or nil,
        updatedAt = at,
        reason = reason,
        zoneID = entry.assignment and entry.assignment.zoneID,
        zoneLabel = entry.assignment and entry.assignment.zoneLabel,
        needKind = entry.assignment and entry.assignment.needKind,
    }
end

local function setRecordOrder(session, entry, record, state, at, reason)
    local orderSystem = PNC.OrderSystem
    local network = PNC.Network
    local order
    local errorMessage
    if not record or not orderSystem
        or type(orderSystem.SetOrder) ~= "function"
    then
        return false, "camp_order_system_unavailable"
    end
    order, errorMessage = buildOrder(session, entry, record, state)
    if not order then return false, errorMessage end
    record.runtime = record.runtime or {}
    writePlacementRuntime(record, session, entry, state, at, reason)
    orderSystem.SetOrder(record, order)
    record.runtime.lastCompanionCommand = "camp"
    record.runtime.lastCompanionCommandAt = at
    record.runtime.lastCompanionCommandRevision =
        (tonumber(record.runtime.lastCompanionCommandRevision) or 0) + 1
    record.runtime.lastCompanionCommandOwner = session.ownerKey
    record.runtime.campZoneAssignment = {
        zoneID = entry.assignment and entry.assignment.zoneID,
        zoneLabel = entry.assignment and entry.assignment.zoneLabel,
        needKind = entry.assignment and entry.assignment.needKind,
        reason = entry.assignment and entry.assignment.reason,
        score = entry.assignment and entry.assignment.score,
        revision = entry.assignment
            and entry.assignment.assignmentRevision,
    }
    if network and type(network.BroadcastRecord) == "function" then
        network.BroadcastRecord(record, "companion_command_camp")
    end
    return true, "commanded"
end


Coordinator.Internal = Coordinator.Internal or {}
local Internal = Coordinator.Internal
Internal.number = number
Internal.text = text
Internal.call = call
Internal.primitiveCopy = primitiveCopy
Internal.compactSite = compactSite
Internal.compactAssignment = compactAssignment
Internal.runtimeNow = runtimeNow
Internal.recordFor = recordFor
Internal.liveBody = liveBody
Internal.isLiveRecord = isLiveRecord
Internal.reached = reached
Internal.movementState = movementState
Internal.buildOrder = buildOrder
Internal.writePlacementRuntime = writePlacementRuntime
Internal.setRecordOrder = setRecordOrder

return Coordinator
