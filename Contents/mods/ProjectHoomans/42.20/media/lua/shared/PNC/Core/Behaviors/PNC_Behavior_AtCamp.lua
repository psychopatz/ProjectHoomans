-- Stable idle behavior for colonists assigned to remain at a temporary camp.
-- Camp is a durable anchor order; survival activities temporarily replace it
-- with facility_activity and restore it when the activity ends.

PNC = PNC or {}
PNC.BehaviorAtCamp = PNC.BehaviorAtCamp or {}

local AtCamp = PNC.BehaviorAtCamp
local Common = PNC.BehaviorCommon
local Animation = PNC.Animation
local Const = PNC.Const
local Core = PNC.Core
-- The behavior consumes the primitive camp-order contract but does not load
-- the semantic resolver itself. Shared composition loads that contract before
-- behaviors; keeping this edge optional prevents the behavior layer from
-- depending on the conversation/semantic composition graph.
local CampSite = PNC.Semantics and PNC.Semantics.CampSite
local Geometry = PNC.Semantics and PNC.Semantics.CampSiteGeometry
local ROOM_SCOPE = "room"
local CAMPFIRE_SCOPE = "campfire"

local function normalizeScope(value)
    value = string.lower(tostring(value or ""))
    if value == "inside" or value == "building" then return ROOM_SCOPE end
    if value == "fire" or value == "firepit" then return CAMPFIRE_SCOPE end
    if value == "here" or value == ROOM_SCOPE
        or value == CAMPFIRE_SCOPE
    then
        return value
    end
    return nil
end

local function boundsContain(bounds, x, y, z)
    if CampSite and type(CampSite.BoundsContain) == "function" then
        return CampSite.BoundsContain(bounds, x, y, z)
    end
    if type(bounds) ~= "table" then return false end
    x = tonumber(x)
    y = tonumber(y)
    if x == nil or y == nil then return false end
    local minX = tonumber(bounds.minX or bounds.x)
    local minY = tonumber(bounds.minY or bounds.y)
    local maxX = tonumber(bounds.maxX or bounds.x2)
    local maxY = tonumber(bounds.maxY or bounds.y2)
    local boundZ = tonumber(bounds.z)
    if not minX or not minY or not maxX or not maxY then return false end
    if x < minX or x > maxX or y < minY or y > maxY then return false end
    return boundZ == nil
        or math.abs((tonumber(z) or 0) - boundZ) <= 0.75
end

local function isWithinCamp(record, zombie, anchorX, anchorY, anchorZ, radius,
    order)
    local query = PNC.TraversalQuery
    local anchorSquare
    local bodySquare
    local anchorIndoor
    local bodyIndoor
    if order and (normalizeScope(order.scope) == ROOM_SCOPE
        or normalizeScope(order.siteScope) == ROOM_SCOPE)
    then
        bodySquare = zombie and zombie.getCurrentSquare
            and zombie:getCurrentSquare() or nil
        if bodySquare and Geometry
            and type(Geometry.MatchesRoom) == "function"
        then
            return Geometry.MatchesRoom(bodySquare, order) == true
        end
        -- Abstract records do not have an IsoGridSquare. Bounds are a safe
        -- primitive fallback until the live body is materialized.
        return boundsContain(order.roomBounds,
            record and record.x, record and record.y, record and record.z)
    end
    local distance = Core.Distance(record.x, record.y, anchorX, anchorY)
    if distance > radius then return false end
    if not zombie or not query
        or not query.GetSquare
        or not query.GetInteriorState
    then
        return true
    end

    anchorSquare = query.GetSquare(anchorX, anchorY, anchorZ)
    anchorIndoor = query.GetInteriorState(anchorSquare)
    if anchorIndoor ~= true then
        return true
    end

    bodySquare = zombie.getCurrentSquare
        and zombie:getCurrentSquare() or nil
    bodyIndoor = query.GetInteriorState(bodySquare)
    -- An indoor camp is not complete while the body is still outside, even
    -- when the Euclidean camp radius overlaps the exterior side of a wall.
    return bodyIndoor ~= false
end

local function normalize(record, spec)
    spec = type(spec) == "table" and spec or {}
    local scope = normalizeScope(spec.scope or spec.siteScope)
        or CAMPFIRE_SCOPE
    return {
        kind = Const.ORDER_CAMP or "camp",
        x = tonumber(spec.x) or tonumber(record and record.x)
            or tonumber(record and record.anchorX),
        y = tonumber(spec.y) or tonumber(record and record.y)
            or tonumber(record and record.anchorY),
        z = tonumber(spec.z) or tonumber(record and record.z)
            or tonumber(record and record.anchorZ) or 0,
        radius = math.max(0.5, tonumber(spec.radius)
            or tonumber(Const.CAMP_RADIUS) or 3),
        campId = tostring(spec.campId or "camp:" .. tostring(record and record.id or "")),
        resourceRadius = math.max(1, math.min(24, tonumber(spec.resourceRadius)
            or tonumber(Const.CAMP_RESOURCE_RADIUS) or 12)),
        scope = scope,
        siteScope = normalizeScope(spec.siteScope or spec.scope) or scope,
        siteID = spec.siteID and tostring(spec.siteID) or nil,
        roomID = spec.roomID and tostring(spec.roomID) or nil,
        buildingID = spec.buildingID and tostring(spec.buildingID) or nil,
        roomType = spec.roomType and tostring(spec.roomType) or nil,
        roomName = spec.roomName and tostring(spec.roomName) or nil,
        roomBounds = CampSite and type(CampSite.NormalizeBounds) == "function"
            and CampSite.NormalizeBounds(spec.roomBounds)
            or spec.roomBounds,
        campfireID = spec.campfireID and tostring(spec.campfireID) or nil,
        label = spec.label and tostring(spec.label) or nil,
        risk = spec.risk and tostring(spec.risk) or nil,
        stopDistance = math.max(0.25, tonumber(spec.stopDistance)
            or (scope == ROOM_SCOPE and 0.7
                or tonumber(Const.CAMP_STOP_DISTANCE) or 0.45)),
    }
end

function AtCamp.Tick(record, zombie)
    local order = record.orderSpec or {}
    local anchorX = tonumber(order.x) or record.anchorX or record.x
    local anchorY = tonumber(order.y) or record.anchorY or record.y
    local anchorZ = tonumber(order.z) or record.anchorZ or record.z or 0
    local radius = math.max(0.5, tonumber(order.radius)
        or tonumber(Const.CAMP_RADIUS) or 3)
    if not isWithinCamp(
        record, zombie, anchorX, anchorY, anchorZ, radius, order
    ) then
        record.activeBehavior = "AtCamp:returning"
        Common.ClearCombatTarget(record, "returning_to_camp", zombie)
        Common.MoveRecord(
            record,
            zombie,
            anchorX,
            anchorY,
            anchorZ,
            "walk",
            order.stopDistance
                or math.max(tonumber(Const.CAMP_STOP_DISTANCE) or 0.45,
                    radius),
            "camp_anchor"
        )
        return true
    end

    record.activeBehavior = "AtCamp"
    if PNC.NavigationRouter and PNC.NavigationRouter.Clear then
        PNC.NavigationRouter.Clear(record)
    end
    Common.ClearCombatTarget(record, "at_camp", zombie)
    Common.HaltMovement(record, zombie, "at_camp")
    if zombie and Animation and Animation.Apply then
        Animation.Apply(zombie, record, "Idle")
    end
    return true
end

if PNC.OrderSystem and PNC.OrderSystem.RegisterNormalizer then
    PNC.OrderSystem.RegisterNormalizer(Const.ORDER_CAMP or "camp", normalize)
end
if PNC.JobSystem and PNC.JobSystem.RegisterOrder then
    PNC.JobSystem.RegisterOrder(
        Const.ORDER_CAMP or "camp",
        Const.JOB_AT_CAMP or "AtCamp"
    )
end
if PNC.BehaviorRegistry and PNC.BehaviorRegistry.Register then
    PNC.BehaviorRegistry.Register(
        Const.JOB_AT_CAMP or "AtCamp",
        AtCamp.Tick
    )
end

return AtCamp
