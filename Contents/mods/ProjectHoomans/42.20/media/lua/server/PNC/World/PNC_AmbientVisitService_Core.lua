-- Temporary, server-owned access for friendly NPC visitors and faction
-- ambient campers. This is deliberately separate from settlement admission:
-- it never transfers faction/community ownership and never creates needs.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.AmbientVisitService = PNC.AmbientVisitService or {}

local Service = PNC.AmbientVisitService
local MobileSites = {}
local Const = PNC.Const or {}
local Core = PNC.Core
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

Service.VERSION = 1
Service.DEFAULT_DURATION_HOURS = 4
Service.MAX_DURATION_HOURS = 12
Service.MAX_ACTIVE_LEASES = 16
Service.PUMP_INTERVAL_HOURS = 2 / 60
Service.PUMP_BUDGET = 4
Service.MOBILE_SHELTER_RETRY_HOURS = 0.25
Service.MOBILE_SHELTER_DURATION_HOURS = 12
Service.MAX_MOBILE_SITE_CACHE = 8

Service.Runtime = Service.Runtime or {}
Service.Runtime.leases = Service.Runtime.leases or {}
Service.Runtime.byNPC = Service.Runtime.byNPC or {}
Service.Runtime.mobileSites = Service.Runtime.mobileSites or {}
Service.Runtime.sequence = tonumber(Service.Runtime.sequence) or 0

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
    if valueType ~= "table" or (depth or 0) >= 5 then return nil end
    output = {}
    for key, childValue in pairs(value) do
        if type(key) == "string" or type(key) == "number" then
            child = primitiveCopy(childValue, (depth or 0) + 1)
            if child ~= nil then output[key] = child end
        end
    end
    return output
end

local function worldHours(value)
    local gameTime
    local result
    if value ~= nil then return number(value, 0) end
    gameTime = type(getGameTime) == "function" and getGameTime() or nil
    if gameTime and type(gameTime.getWorldAgeHours) == "function" then
        result = gameTime:getWorldAgeHours()
        if number(result) ~= nil then return number(result) end
    end
    return 0
end

local function isAuthority()
    return not Core or not Core.IsAuthority
        or Core.IsAuthority() == true
end

local function recordID(record)
    return text(record and record.id, nil, 128)
end

local function activeCount()
    local count = 0
    for _, lease in pairs(Service.Runtime.leases) do
        if lease and lease.status == "active" then count = count + 1 end
    end
    return count
end

local function liveBody(record)
    local registry = PNC.Registry
    local body
    if not registry or type(registry.GetLiveZombie) ~= "function" then
        return nil
    end
    body = registry.GetLiveZombie(record and record.id)
    if not body then return nil end
    if type(body.isDead) == "function" and body:isDead() then return nil end
    return body
end

local function blockedRuntime(record)
    local runtime = record and record.runtime or nil
    local health = record and record.health or nil
    if not runtime then return false end
    if runtime.target ~= nil or runtime.combatTarget ~= nil
        or runtime.attackAction ~= nil or runtime.facilityActivity ~= nil
        or runtime.workOrderId ~= nil or runtime.taskLeaseId ~= nil
        or runtime.medicalCare ~= nil or runtime.treatment ~= nil
    then
        return true
    end
    if health and health.state == "incapacitated" then return true end
    return false
end

local function normalizedScope(value)
    value = string.lower(tostring(value or ""))
    if value == "inside" or value == "building" then return "room" end
    if value == "fire" or value == "firepit" then return "campfire" end
    if value == "room" or value == "campfire" then return value end
    return nil
end

local function copyBounds(bounds)
    if type(bounds) ~= "table" then return nil end
    if PNC.Semantics and PNC.Semantics.CampSite
        and PNC.Semantics.CampSite.NormalizeBounds
    then
        return PNC.Semantics.CampSite.NormalizeBounds(bounds)
    end
    return primitiveCopy(bounds)
end

local function copySite(site)
    local scope
    local output
    if type(site) ~= "table" then return nil, "ambient_visit_site_missing" end
    scope = normalizedScope(site.scope or site.siteScope)
    if not scope then return nil, "ambient_visit_site_scope_invalid" end
    output = {
        kind = "camp_site",
        scope = scope,
        siteScope = scope,
        siteID = text(site.siteID, nil, 128),
        roomID = text(site.roomID, nil, 128),
        buildingID = text(site.buildingID, nil, 128),
        roomType = text(site.roomType, nil, 48),
        roomName = text(site.roomName, nil, 64),
        roomBounds = copyBounds(site.roomBounds),
        campfireID = text(site.campfireID, nil, 128),
        x = number(site.x or site.targetX),
        y = number(site.y or site.targetY),
        z = number(site.z or site.targetZ, 0),
        movementX = number(site.movementX or site.x or site.targetX),
        movementY = number(site.movementY or site.y or site.targetY),
        movementZ = number(site.movementZ or site.z or site.targetZ, 0),
        radius = math.max(0.5, number(site.radius, 3)),
        resourceRadius = math.max(1, math.min(24,
            number(site.resourceRadius, 12))),
        stopDistance = math.max(0.25, number(site.stopDistance,
            scope == "room" and 0.7 or 1.25)),
        label = text(site.label, scope == "room" and "room" or "campfire", 64),
        risk = text(site.risk, nil, 32),
    }
    if output.x == nil or output.y == nil then
        return nil, "ambient_visit_site_position_missing"
    end
    if scope == "room" and not output.siteID and not output.roomID
        and not output.buildingID and not output.roomBounds
    then
        return nil, "ambient_visit_room_identity_missing"
    end
    if scope == "campfire" and not output.campfireID
        and not output.siteID
    then
        return nil, "ambient_visit_campfire_identity_missing"
    end
    return output
end

local function leaseFor(recordOrID)
    local id
    local leaseID
    local record
    if type(recordOrID) == "table" then
        record = recordOrID
        id = recordID(record)
        leaseID = record.runtime and record.runtime.ambientVisit
            and record.runtime.ambientVisit.leaseID or nil
    else
        id = text(recordOrID, nil, 128)
    end
    if not leaseID and id and Service.Runtime.leases[id] then
        return Service.Runtime.leases[id], record
    end
    if not leaseID and id then leaseID = Service.Runtime.byNPC[id] end
    if not leaseID then return nil, record end
    return Service.Runtime.leases[tostring(leaseID)], record
end

local function orderIsLease(record, lease)
    local order = record and record.orderSpec or nil
    return order and lease
        and tostring(order.ambientVisitID or "") == tostring(lease.id or "")
end

local function boundsOverlap(left, right)
    if type(left) ~= "table" or type(right) ~= "table" then
        return false
    end
    return number(left.minX, -math.huge) <= number(right.maxX, math.huge)
        and number(right.minX, -math.huge) <= number(left.maxX, math.huge)
        and number(left.minY, -math.huge) <= number(right.maxY, math.huge)
        and number(right.minY, -math.huge) <= number(left.maxY, math.huge)
end

local function mobileShelterKey(order)
    if type(order) ~= "table" then return nil end
    if order.ambientSourceID then
        return tostring(order.ambientSourceID)
    end
    if order.shelterSiteID then
        return tostring(order.shelterSiteID)
    end
    return string.format(
        "%.1f:%.1f:%s",
        number(order.x, 0),
        number(order.y, 0),
        tostring(number(order.z, 0))
    )
end

local function notify(record, reason)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, reason or "ambient_visit")
    end
    if PNC.Network and PNC.Network.BroadcastRecord then
        PNC.Network.BroadcastRecord(record, reason or "ambient_visit")
    end
    if PNC.SimulationClock and PNC.SimulationClock.Wake then
        PNC.SimulationClock.Wake(record, nil,
            Core and Core.Now and Core.Now() or 0)
    end
end

local function setOrder(record, order)
    if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
        local ok, reason = pcall(PNC.OrderSystem.SetOrder, record, order)
        if not ok then return false, tostring(reason or "order_failed") end
        return true
    end
    record.orderSpec = order
    return true
end

local function resolveRecord(recordOrID)
    if type(recordOrID) == "table" then return recordOrID end
    if PNC.Registry and PNC.Registry.Get then
        return PNC.Registry.Get(tostring(recordOrID or ""))
    end
    return nil
end

local function relationshipState(relationship)
    local states = PNC.RelationshipStates
    local resolved
    if states and type(states.ResolveState) == "function" then
        local ok, value = pcall(states.ResolveState, relationship or {})
        if ok and value then resolved = value end
    end
    return tostring(resolved or relationship and relationship.state or "")
end

local function activePlayerBase(player)
    local factions = PNC.Factions
    local communities = PNC.Communities
    local baseService = PNC.BaseService
    local faction
    local colony
    local base
    if not player or not factions
        or type(factions.GetPlayerFaction) ~= "function"
    then
        return nil, "visitor_player_faction_missing"
    end
    faction = factions.GetPlayerFaction(player)
    if not faction or not communities
        or type(communities.GetForFaction) ~= "function"
    then
        return nil, "visitor_colony_missing"
    end
    for _, candidate in ipairs(communities.GetForFaction(faction.id) or {}) do
        if candidate and candidate.status == "active" then
            colony = candidate
            break
        end
    end
    if not colony or not baseService
        or type(baseService.GetForColony) ~= "function"
    then
        return nil, "visitor_base_missing"
    end
    base = baseService.GetForColony(colony.id)
    if not base then return nil, "visitor_base_missing" end
    return base, nil, faction, colony
end

local function baseZone(base)
    local zone
    if not base or not base.baseZoneId then
        return nil, "visitor_base_zone_missing"
    end
    if type(Zones.get) ~= "function" then
        return nil, "visitor_base_zone_unavailable"
    end
    zone = Zones.get(base.baseZoneId)
    if not zone or type(zone.geometry) ~= "table" then
        return nil, "visitor_base_zone_missing"
    end
    if type(GridRegion.containsXY) ~= "function" then
        return nil, "visitor_base_geometry_unavailable"
    end
    return { base = base, zone = zone, grid = GridRegion }
end

local function pointInBase(baseContext, x, y)
    local geometry = baseContext and baseContext.zone
        and baseContext.zone.geometry or nil
    local grid = baseContext and baseContext.grid or nil
    x, y = number(x), number(y)
    if not geometry or not grid or x == nil or y == nil then return false end
    return grid.containsXY(geometry, math.floor(x), math.floor(y)) == true
end

local function sitePoint(site)
    if type(site) ~= "table" then return nil, nil end
    return number(site.movementX or site.x or site.targetX),
        number(site.movementY or site.y or site.targetY)
end

local function invitationFailure(reason)
    return {
        eligible = false,
        reason = tostring(reason or "ambient_visit_unavailable"),
    }
end

-- This is deliberately a cheap, server-derived preview. It is sent with the
-- relationship presentation so the menu can stay quiet for ineligible NPCs;
-- it never searches rooms, campfires, or loaded squares.
function Service.GetInvitationPreview(recordOrID, player, relationship)
    local record = resolveRecord(recordOrID)
    local eligible
    local reason
    local base
    if not isAuthority() then return invitationFailure("not_authority") end
    eligible, reason = Service.IsEligible(record, {
        requireMaterialized = true,
    })
    if not eligible then return invitationFailure(reason) end
    if relationshipState(relationship) ~= "friend" then
        return invitationFailure("visitor_relationship_not_friendly")
    end
    base, reason = activePlayerBase(player)
    if not base then return invitationFailure(reason) end
    return {
        eligible = true,
        reason = "eligible",
        baseID = tostring(base.id or ""),
        accessClass = "player_visitor",
        purpose = "invited_visit",
    }
end

Service.Internal = Service.Internal or {}
Service.Internal.MobileSites = MobileSites
Service.Internal.number = number
Service.Internal.text = text
Service.Internal.worldHours = worldHours
Service.Internal.primitiveCopy = primitiveCopy
Service.Internal.recordID = recordID
Service.Internal.activeCount = activeCount
Service.Internal.copySite = copySite
Service.Internal.notify = notify
Service.Internal.setOrder = setOrder
Service.Internal.resolveRecord = resolveRecord
Service.Internal.relationshipState = relationshipState
Service.Internal.activePlayerBase = activePlayerBase
Service.Internal.baseZone = baseZone
Service.Internal.pointInBase = pointInBase
Service.Internal.sitePoint = sitePoint
Service.Internal.liveBody = liveBody
Service.Internal.mobileShelterKey = mobileShelterKey
Service.Internal.leaseFor = leaseFor
Service.Internal.orderIsLease = orderIsLease
Service.Internal.blockedRuntime = blockedRuntime
Service.Internal.isAuthority = isAuthority
Service.Internal.boundsOverlap = boundsOverlap
Service.Internal.Const = Const

return Service
