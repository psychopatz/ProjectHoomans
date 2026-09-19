-- Camp order context, geometry boundary, and bounded runtime cache.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CampResourceService = PNC.CampResourceService or {}

local Service = PNC.CampResourceService
local Internal = Service.Internal or {}
Service.Internal = Internal
local Const = PNC.Const or {}
local CampSite = PNC.Semantics and PNC.Semantics.CampSite
    or require "PNC/Semantics/PNC_SemanticCampSite"
local Geometry = PNC.Semantics and PNC.Semantics.CampSiteGeometry
    or require "PNC/Semantics/PNC_SemanticCampSiteGeometry"

-- Bump this whenever resource classification or target metadata changes. Old
-- camp snapshots are world-state caches, not authoritative sleep decisions.
Service.SCHEMA_VERSION = 4
Service.Providers = Service.Providers or {}
Service.Runtime = Service.Runtime or {}
Service.Runtime.camps = Service.Runtime.camps or {}
Service.MAX_ROOM_SCAN_SQUARES = 4096
Service.MAX_CACHE_ENTRIES = Service.MAX_CACHE_ENTRIES or 256

local function number(value, fallback)
    local result = tonumber(value)
    return result ~= nil and result or fallback
end

local function campFacilityId(campId)
    campId = tostring(campId or "")
    return string.sub(campId, 1, 5) == "camp:"
        and campId or "camp:" .. campId
end

local function campOrder(record)
    local order = record and record.orderSpec or nil
    if tostring(order and order.kind or "") ~= tostring(Const.ORDER_CAMP or "camp") then
        return nil
    end
    return order
end

local function campScope(order)
    return CampSite.NormalizeScope(order and (order.scope
        or order.siteScope)) or CampSite.SCOPES.CAMPFIRE
end

local function roomBounds(order)
    return CampSite.NormalizeBounds(order and order.roomBounds)
end

-- Facility activities temporarily replace the camp order. Keep the camp
-- anchor available to resource revalidation while a need task is active.
local function campContext(record)
    local order = campOrder(record)
    if order then return order end
    local activity = record and record.runtime
        and record.runtime.facilityActivity or nil
    local state = record and record.campState or nil
    if not activity or activity.campActivity ~= true then return nil end
    return {
        kind = Const.ORDER_CAMP or "camp",
        campId = tostring(activity.campId or state and state.campId
            or "camp:" .. tostring(record.id)),
        x = number(activity.campX or state and state.anchorX,
            record and record.anchorX or record and record.x or 0),
        y = number(activity.campY or state and state.anchorY,
            record and record.anchorY or record and record.y or 0),
        z = number(activity.campZ or state and state.anchorZ,
            record and record.anchorZ or record and record.z or 0),
        radius = number(activity.campRadius or state and state.campRadius,
            Const.CAMP_RADIUS or 3),
        resourceRadius = number(activity.resourceRadius
            or state and state.resourceRadius,
            Const.CAMP_RESOURCE_RADIUS or 12),
        scope = activity.scope or activity.siteScope
            or state and (state.scope or state.siteScope),
        siteScope = activity.siteScope or activity.scope
            or state and (state.siteScope or state.scope),
        siteID = activity.siteID or state and state.siteID,
        roomID = activity.roomID or state and state.roomID,
        buildingID = activity.buildingID or state and state.buildingID,
        roomType = activity.roomType or state and state.roomType,
        roomName = activity.roomName or state and state.roomName,
        roomBounds = activity.roomBounds or state and state.roomBounds,
        campfireID = activity.campfireID or state and state.campfireID,
        zoneID = activity.zoneID or state and state.zoneID,
        zoneLabel = activity.zoneLabel or state and state.zoneLabel,
        zoneScope = activity.zoneScope or state and state.zoneScope,
        campRootX = activity.campRootX or state and state.campRootX,
        campRootY = activity.campRootY or state and state.campRootY,
        campRootZ = activity.campRootZ or state and state.campRootZ,
        campRootScope = activity.campRootScope
            or state and state.campRootScope,
        campRootSiteID = activity.campRootSiteID
            or state and state.campRootSiteID,
    }
end

-- A target must remain local to the captured camp anchor. This is a safety
-- boundary as well as a performance boundary for stale or malformed targets.
local function targetWithinCamp(record, target)
    local order = campContext(record)
    local targetX = tonumber(target and target.x)
    local targetY = tonumber(target and target.y)
    local targetZ = tonumber(target and target.z)
    local anchorTargetX
    local anchorTargetY
    local anchorTargetZ
    local radius
    if not order or not targetX or not targetY or not targetZ then
        return false
    end
    radius = number(order.radius, Const.CAMP_RADIUS or 3)
    if Geometry and Geometry.ContainsPoint then
        if not Geometry.ContainsPoint(order, targetX, targetY, targetZ, {
            radius = radius,
        }) then
            return false
        end
        anchorTargetX = tonumber(target.seatAnchorX)
        anchorTargetY = tonumber(target.seatAnchorY)
        anchorTargetZ = tonumber(target.seatAnchorZ or target.z)
        if anchorTargetX and anchorTargetY and anchorTargetZ then
            return Geometry.ContainsPoint(order, anchorTargetX,
                anchorTargetY, anchorTargetZ, { radius = radius })
        end
        return true
    end
    -- Compatibility fallback for a partially loaded older geometry adapter.
    local scope = campScope(order)
    if scope == CampSite.SCOPES.ROOM then
        return CampSite.BoundsContain(roomBounds(order),
            math.floor(targetX), math.floor(targetY), targetZ)
    end
    local anchorX = tonumber(order.x)
    local anchorY = tonumber(order.y)
    local anchorZ = tonumber(order.z)
    if not anchorX or not anchorY or not anchorZ
        or math.abs(targetZ - anchorZ) > 0.5
    then
        return false
    end
    local dx, dy = targetX - anchorX, targetY - anchorY
    return (dx * dx) + (dy * dy)
        <= (radius + 0.5) * (radius + 0.5)
end

function Service.IsWithinCamp(record, target)
    return targetWithinCamp(record, target)
end

local function worldHour()
    if PNC.NeedsUtils and PNC.NeedsUtils.WorldAgeHours then
        return PNC.NeedsUtils.WorldAgeHours()
    end
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function now()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function markDirty(record, reason)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, reason or "camp_resources")
    end
end

local function campDimensions(order)
    local radius = math.max(1, math.min(24, number(
        order and order.resourceRadius,
        number(Const.CAMP_RESOURCE_RADIUS, 12))))
    local campRadius = math.max(0.5, math.min(24, number(
        order and order.radius,
        number(Const.CAMP_RADIUS, 3))))
    return radius, campRadius
end

local function campCacheKey(record, order)
    local campID = tostring(order and order.campId
        or "camp:" .. tostring(record and record.id or "unknown"))
    local zoneID = tostring(order and order.zoneID or "")
    if zoneID ~= "" then return campID .. "|zone:" .. zoneID end
    return campID
end

local function cacheEntry(record, order, create)
    local key = campCacheKey(record, order)
    local entry = Service.Runtime.camps[key]
    if not entry and create ~= false then
        entry = { campId = key, members = {}, state = nil,
            lastUsedAt = now() }
        Service.Runtime.camps[key] = entry
    end
    if entry then entry.lastUsedAt = now() end
    return entry, key
end

local function detachRecord(record)
    local runtime = record and record.runtime or nil
    local key = runtime and runtime.campCacheId or nil
    local entry
    local memberID
    local hasMembers
    if not key then return end
    entry = Service.Runtime.camps[tostring(key)]
    memberID = tostring(record and record.id or "")
    if entry and entry.members then entry.members[memberID] = nil end
    if entry and entry.members then
        hasMembers = false
        for _ in pairs(entry.members) do
            hasMembers = true
            break
        end
        if not hasMembers then
            Service.Runtime.camps[tostring(key)] = nil
        end
    end
    runtime.campCacheId = nil
    if record then record.campState = nil end
end

local function hasMembers(members)
    if not members then return false end
    for _ in pairs(members) do return true end
    return false
end

local function evictCacheEntries()
    local count = 0
    local oldestKey
    local oldestAt
    local entry
    for key, candidate in pairs(Service.Runtime.camps) do
        count = count + 1
        entry = candidate
        if entry and not entry.capture and not hasMembers(entry.members)
        then
            local usedAt = tonumber(entry.lastUsedAt) or 0
            if oldestAt == nil or usedAt < oldestAt then
                oldestKey, oldestAt = key, usedAt
            end
        end
    end
    if count <= math.max(1, math.floor(Service.MAX_CACHE_ENTRIES)) then
        return
    end
    if oldestKey then Service.Runtime.camps[oldestKey] = nil end
end

function Service.Attach(record, order)
    local runtime
    local entry
    local key
    local memberID
    if not record then return nil end
    order = order or campContext(record)
    if not order then return nil end
    runtime = record.runtime or {}
    record.runtime = runtime
    if runtime.campCacheId
        and tostring(runtime.campCacheId) ~= tostring(campCacheKey(record, order))
    then
        detachRecord(record)
    end
    entry, key = cacheEntry(record, order, true)
    memberID = tostring(record.id or "")
    entry.members[memberID] = true
    runtime.campCacheId = key
    evictCacheEntries()
    return entry
end

function Service.Detach(record)
    detachRecord(record)
end

Internal.Number = number
Internal.CampFacilityId = campFacilityId
Internal.CampOrder = campOrder
Internal.CampScope = campScope
Internal.RoomBounds = roomBounds
Internal.CampContext = campContext
Internal.TargetWithinCamp = targetWithinCamp
Internal.WorldHour = worldHour
Internal.Now = now
Internal.MarkDirty = markDirty
Internal.CampDimensions = campDimensions
Internal.CampCacheKey = campCacheKey
Internal.CacheEntry = cacheEntry
Internal.DetachRecord = detachRecord
Internal.EvictCacheEntries = evictCacheEntries

return Service
