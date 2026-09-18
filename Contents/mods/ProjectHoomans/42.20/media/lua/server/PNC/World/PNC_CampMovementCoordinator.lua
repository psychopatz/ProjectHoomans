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
        local ok, value = pcall(Core.Now)
        if ok and number(value) ~= nil then return number(value) end
    end
    return 0
end

local function playerKey(player)
    local value
    if player and type(player.getOnlineID) == "function" then
        local ok, onlineID = pcall(player.getOnlineID, player)
        if ok and onlineID ~= nil then value = tostring(onlineID) end
    end
    if value and value ~= "" then return value end
    if player and type(player.getUsername) == "function" then
        local ok, username = pcall(player.getUsername, player)
        if ok and username ~= nil and tostring(username) ~= "" then
            return tostring(username)
        end
    end
    return "player"
end

local function recordFor(npcID)
    local registry = PNC.Registry
    if not registry or type(registry.Get) ~= "function" then return nil end
    local ok, record = pcall(registry.Get, npcID)
    return ok and record or nil
end

local function liveBody(record)
    local registry = PNC.Registry
    if not registry or type(registry.GetLiveZombie) ~= "function" then
        return nil
    end
    local ok, body = pcall(registry.GetLiveZombie, record and record.id)
    if not ok or not body then return nil end
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
            local ok, matched = pcall(geometry.MatchesRoom, square, zone)
            if ok and matched == true then return true end
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
    local ok, state = pcall(getter, record, body, at)
    return ok and state or nil
end

local function buildOrder(session, entry, record, placementState)
    local commands = PNC.CompanionCommands
    local definition = commands and type(commands.Get) == "function"
        and commands.Get("camp") or nil
    local options
    local ok
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
    ok, order = pcall(definition.buildOrder, record, nil, options)
    if not ok or type(order) ~= "table" then
        return nil, ok and "invalid_camp_order" or tostring(order)
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
    local previousPlacement
    local ok
    local errorMessage
    if not record or not orderSystem
        or type(orderSystem.SetOrder) ~= "function"
    then
        return false, "camp_order_system_unavailable"
    end
    order, errorMessage = buildOrder(session, entry, record, state)
    if not order then return false, errorMessage end
    record.runtime = record.runtime or {}
    previousPlacement = record.runtime.campPlacement
    writePlacementRuntime(record, session, entry, state, at, reason)
    ok, errorMessage = pcall(orderSystem.SetOrder, record, order)
    if not ok then
        record.runtime.campPlacement = previousPlacement
        return false, tostring(errorMessage)
    end
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

local function removeSessionFromOrder(sessionID)
    for index = #Coordinator.SessionOrder, 1, -1 do
        if tostring(Coordinator.SessionOrder[index]) == tostring(sessionID) then
            table.remove(Coordinator.SessionOrder, index)
        end
    end
end

local function pruneSessionOrder()
    for index = #Coordinator.SessionOrder, 1, -1 do
        if not Coordinator.Sessions[Coordinator.SessionOrder[index]] then
            table.remove(Coordinator.SessionOrder, index)
        end
    end
end

local function finishSession(session, phase, reason)
    if not session then return end
    session.phase = phase or "completed"
    session.reason = reason
    session.updatedAt = runtimeNow()
    if tostring(Coordinator.ActiveSessionID or "") == tostring(session.id) then
        Coordinator.ActiveSessionID = nil
    end
    Coordinator.Sessions[session.id] = nil
    removeSessionFromOrder(session.id)
    Coordinator.PendingCount = math.max(0,
        (tonumber(Coordinator.PendingCount) or 1) - 1)
end

local function activeSession()
    local id = Coordinator.ActiveSessionID
    local session = id and Coordinator.Sessions[id] or nil
    if session and session.phase == "running" then return session end
    Coordinator.ActiveSessionID = nil
    return nil
end

local function selectSession()
    local session = activeSession()
    if session then return session end
    for index = 1, #Coordinator.SessionOrder do
        session = Coordinator.Sessions[Coordinator.SessionOrder[index]]
        if session and session.phase == "running" then
            Coordinator.ActiveSessionID = session.id
            return session
        end
    end
    return nil
end

local function cancelOwnedSessions(ownerKey, reason)
    local ids = {}
    local session
    for index = 1, #Coordinator.SessionOrder do
        session = Coordinator.Sessions[Coordinator.SessionOrder[index]]
        if session and session.ownerKey == ownerKey then
            ids[#ids + 1] = session.id
        end
    end
    for index = 1, #ids do
        Coordinator.Cancel(ids[index], reason or "camp_replaced")
    end
end

function Coordinator.IsPlacementLocked(record)
    local runtime = record and record.runtime or nil
    local placement = runtime and runtime.campPlacement or nil
    local order = record and record.orderSpec or nil
    local state = placement and placement.state
        or order and order.placementState or ""
    state = string.lower(tostring(state))
    return state == "queued" or state == "moving" or state == "failed"
end

function Coordinator.Get(campID)
    return Coordinator.Sessions[tostring(campID or "")]
end

function Coordinator.Cancel(campID, reason)
    local session = Coordinator.Sessions[tostring(campID or "")]
    local record
    local entry
    if not session then return false, "camp_session_not_found" end
    for index = 1, #session.queue do
        entry = session.queue[index]
        if entry.state == "queued" or entry.state == "moving"
            or entry.state == "failed"
        then
            record = recordFor(entry.npcID)
            if record and record.runtime and record.runtime.campPlacement
                and tostring(record.runtime.campPlacement.campID)
                    == tostring(session.id)
            then
                record.runtime.campPlacement.state = "cancelled"
                record.runtime.campPlacement.reason = reason
                if record.orderSpec
                    and tostring(record.orderSpec.campId or "")
                        == tostring(session.id)
                then
                    record.orderSpec.placementState = "cancelled"
                end
            end
            entry.state = "cancelled"
        end
    end
    finishSession(session, "cancelled", reason or "cancelled")
    return true, "cancelled"
end

function Coordinator.StartGroupCamp(campSite, records, directory, options)
    local root
    local ownerKey
    local sessionID
    local session
    local assignment
    local zone
    local entry
    local record
    local state
    local accepted = 0
    local affectedTargets = {}
    local activeAssigned = false
    local slotOccupied
    local at
    options = type(options) == "table" and options or {}
    if type(campSite) ~= "table" or type(records) ~= "table"
        or #records == 0
    then
        return nil, "camp_coordinator_input_invalid"
    end
    root = compactSite(campSite)
    if root.x == nil or root.y == nil then
        return nil, "camp_root_position_missing"
    end
    sessionID = tostring(options.campId or "")
    if sessionID == "" then return nil, "camp_session_id_missing" end
    ownerKey = tostring(options.ownerKey or "player")
    cancelOwnedSessions(ownerKey, "camp_replaced")
    pruneSessionOrder()
    if #Coordinator.SessionOrder >= Coordinator.MAX_SESSIONS then
        return 0, "camp_coordinator_busy", affectedTargets
    end
    slotOccupied = selectSession() ~= nil
    session = {
        version = Coordinator.VERSION,
        id = sessionID,
        ownerKey = ownerKey,
        root = root,
        directoryRevision = directory and directory.revision or nil,
        queue = {},
        cursor = 1,
        activeEntry = nil,
        phase = "running",
        startedAt = runtimeNow(options.now),
        updatedAt = runtimeNow(options.now),
        nextEligibleAt = 0,
    }
    Coordinator.Sessions[sessionID] = session
    Coordinator.SessionOrder[#Coordinator.SessionOrder + 1] = sessionID
    Coordinator.PendingCount = (tonumber(Coordinator.PendingCount) or 0) + 1
    at = session.startedAt

    for index = 1, math.min(#records, Coordinator.MAX_QUEUE) do
        record = records[index]
        if record and record.id ~= nil and isLiveRecord(record) then
            assignment = directory and directory.assignments
                and directory.assignments[tostring(record.id)] or nil
            -- First iteration deliberately uses the validated root for every
            -- member. Adjacent-room/need placement is a later coordinator
            -- policy; it must not reintroduce a second broad scan here.
            zone = root
            entry = {
                npcID = tostring(record.id),
                index = #session.queue + 1,
                zone = compactSite(zone),
                assignment = compactAssignment(assignment, zone),
                state = "queued",
            }
            if not slotOccupied and not activeAssigned then
                state = "moving"
            else
                state = "queued"
            end
            local applied, applyReason = setRecordOrder(
                session, entry, record, state, at, "camp_started")
            if applied then
                entry.state = state
                session.queue[#session.queue + 1] = entry
                accepted = accepted + 1
                affectedTargets[#affectedTargets + 1] = tostring(record.id)
                if state == "moving" then
                    entry.startedAt = at
                    session.activeEntry = entry
                    activeAssigned = true
                    slotOccupied = true
                end
            else
                entry.state = "skipped"
                entry.reason = applyReason
            end
        end
    end
    if accepted <= 0 then
        finishSession(session, "failed", "no_live_targets")
        return 0, "no_targets", affectedTargets
    end
    if activeAssigned then Coordinator.ActiveSessionID = sessionID end
    Coordinator.NextPumpAt = 0
    return accepted, "commanded", affectedTargets
end

local function nextQueued(session)
    local entry
    while session.cursor <= #session.queue do
        entry = session.queue[session.cursor]
        session.cursor = session.cursor + 1
        if entry and entry.state == "queued" then return entry end
    end
    return nil
end

local function markEntry(session, entry, state, at, reason)
    local record = recordFor(entry.npcID)
    local applied
    if record then
        applied = setRecordOrder(session, entry, record, state, at, reason)
    end
    entry.state = state
    entry.reason = reason
    entry.updatedAt = at
    if applied == true and state == "arrived"
        and PNC.Tasking and PNC.Tasking.Events
        and PNC.Tasking.Events.Emit
    then
        -- Needs may be evaluated while a member is queued, but must not take
        -- the movement tick away from AtCamp. Re-open need selection only at
        -- the authoritative arrival boundary.
        PNC.Tasking.Events.Emit("NPC_NEEDS_CHANGED", {
            npcId = entry.npcID,
            source = "CampMovementCoordinator",
            entityId = entry.npcID,
            cause = "CAMP_PLACEMENT_ARRIVED",
        })
    end
    return applied == true
end

local function advanceSession(session, at)
    local entry = session.activeEntry
    local record
    local body
    local path
    local progressAt
    local nextEntry
    local applied
    local reason
    if entry then
        record = recordFor(entry.npcID)
        if not record or not isLiveRecord(record)
            or tostring(record.orderSpec and record.orderSpec.kind or "")
                ~= tostring(Const and Const.ORDER_CAMP or "camp")
            or tostring(record.orderSpec and record.orderSpec.campId or "")
                ~= tostring(session.id)
        then
            entry.state = "skipped"
            entry.reason = "npc_unavailable_or_order_replaced"
            session.activeEntry = nil
            session.nextEligibleAt = at + Coordinator.NEXT_PLACEMENT_DELAY_MS
            return
        end
        body = liveBody(record)
        if reached(entry.zone, body, record) then
            markEntry(session, entry, "arrived", at, "camp_zone_reached")
            session.activeEntry = nil
            session.nextEligibleAt = at + Coordinator.NEXT_PLACEMENT_DELAY_MS
            return
        end
        path = movementState(record, body, at)
        progressAt = path and tonumber(path.lastProgressAt) or nil
        if path and path.forceRecovery == true then
            markEntry(session, entry, "failed", at, "camp_path_recovery_required")
            session.activeEntry = nil
            session.nextEligibleAt = at + Coordinator.NEXT_PLACEMENT_DELAY_MS
            return
        end
        if path and path.phase == "blocked"
            and at - (progressAt or entry.startedAt or at)
                >= Coordinator.BLOCKED_TIMEOUT_MS
        then
            markEntry(session, entry, "failed", at, "camp_path_blocked")
            session.activeEntry = nil
            session.nextEligibleAt = at + Coordinator.NEXT_PLACEMENT_DELAY_MS
            return
        end
        if at - (entry.startedAt or session.startedAt or at)
            >= Coordinator.MAX_MOVE_MS
        then
            markEntry(session, entry, "failed", at, "camp_move_timeout")
            session.activeEntry = nil
            session.nextEligibleAt = at + Coordinator.NEXT_PLACEMENT_DELAY_MS
            return
        end
        return
    end
    if at < (tonumber(session.nextEligibleAt) or 0) then return end
    nextEntry = nextQueued(session)
    if not nextEntry then
        finishSession(session, "completed", "all_targets_processed")
        return
    end
    record = recordFor(nextEntry.npcID)
    if not record or not isLiveRecord(record)
        or tostring(record.orderSpec and record.orderSpec.kind or "")
            ~= tostring(Const and Const.ORDER_CAMP or "camp")
        or tostring(record.orderSpec and record.orderSpec.campId or "")
            ~= tostring(session.id)
    then
        nextEntry.state = "skipped"
        nextEntry.reason = "npc_unavailable_or_order_replaced"
        session.nextEligibleAt = at
        return
    end
    applied, reason = setRecordOrder(
        session, nextEntry, record, "moving", at, "camp_placement_started")
    if applied then
        nextEntry.state = "moving"
        nextEntry.startedAt = at
        session.activeEntry = nextEntry
    else
        nextEntry.state = "skipped"
        nextEntry.reason = reason or "camp_order_failed"
        session.nextEligibleAt = at
    end
end

function Coordinator.Pump(at)
    local session
    at = runtimeNow(at)
    if (tonumber(Coordinator.PendingCount) or 0) <= 0 then return false end
    if at < (tonumber(Coordinator.NextPumpAt) or 0) then return false end
    Coordinator.NextPumpAt = at + Coordinator.PUMP_INTERVAL_MS
    session = selectSession()
    if not session then return false end
    session.updatedAt = at
    advanceSession(session, at)
    return true
end

return Coordinator
