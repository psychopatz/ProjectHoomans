PNC = PNC or {}
PNC.TacticalSpatialProjection = PNC.TacticalSpatialProjection or {}

local Projection = PNC.TacticalSpatialProjection
local Registry = PNC.Registry
local Core = PNC.Core
local Facing = PNC.ActorFacing
    or require "PNC/Core/Spatial/PNC_ActorFacing"
local Relation = PsychopatzCore
    and PsychopatzCore.SpatialRelation
    or require "PsychopatzCore/Spatial/PsychopatzSpatialRelation"

Projection.DEFAULT_MAX_THREAT_AGE_MS = 2000

local function finite(value)
    local number = tonumber(value)
    if not number or number ~= number
        or number == math.huge or number == -math.huge
    then
        return nil
    end
    return number
end

local function resolveBody(record, options)
    if type(options) == "table" and options.body ~= nil then
        return options.body
    end
    if not record or not record.id or not Registry
        or type(Registry.GetLiveZombie) ~= "function"
    then
        return nil
    end
    return Registry.GetLiveZombie(record.id)
end

local function observerPoint(record, body)
    if body and type(body.getX) == "function"
        and type(body.getY) == "function"
    then
        return {
            x = body:getX(),
            y = body:getY(),
            z = type(body.getZ) == "function" and body:getZ()
                or record and record.z or 0,
        }, "live_body"
    end
    if not record then return nil end
    return {
        x = record.x,
        y = record.y,
        z = record.z or 0,
    }, "record"
end

function Projection.Project(record, threat, options)
    if type(record) ~= "table" then return nil, "RECORD_REQUIRED" end
    if type(threat) ~= "table" then return nil, "THREAT_REQUIRED" end
    options = type(options) == "table" and options or {}

    local now = finite(options.now)
        or (Core and type(Core.Now) == "function" and finite(Core.Now()))
        or 0
    local observedAt = finite(threat.observedAt)
    local maxAge = finite(options.maxThreatAgeMs)
        or Projection.DEFAULT_MAX_THREAT_AGE_MS
    if maxAge < 0 then maxAge = 0 end
    if observedAt and now > 0 and now - observedAt > maxAge then
        return nil, "THREAT_STALE"
    end

    local body = resolveBody(record, options)
    local origin, originSource = observerPoint(record, body)
    local heading, headingReason = Facing.Resolve(record, {
        body = body,
        now = now,
        allowCached = options.allowCachedFacing,
        maxCachedAgeMs = options.maxCachedFacingAgeMs,
    })
    if not heading then
        return nil, headingReason or "HEADING_UNAVAILABLE"
    end

    local target = {
        x = threat.x,
        y = threat.y,
        z = threat.z ~= nil and threat.z or record.z or 0,
    }
    local relation, relationReason = Relation.RelativeToHeading(
        origin,
        target,
        { x = heading.x, y = heading.y },
        {
            sameAreaThreshold = options.sameAreaThreshold,
            distanceBands = options.distanceBands,
        }
    )
    if not relation then return nil, relationReason end

    local ageMs
    if observedAt and now > 0 then
        ageMs = math.max(0, now - observedAt)
    end

    return {
        targetKind = threat.kind or "unknown",
        targetRef = threat.id or threat.ref,
        targetPositionSource = threat.positionSource or "provided",
        observerPositionSource = originSource,
        headingSource = heading.source,
        headingObservedAt = heading.observedAt,
        headingAgeMs = heading.ageMs,
        observedAt = observedAt,
        freshnessMs = ageMs,
        clockHour = relation.clockHour,
        clockToken = relation.clockToken,
        relativeSector8 = relation.relativeSector8,
        distance = relation.distance,
        horizontalDistance = relation.horizontalDistance,
        distanceBand = relation.distanceBand,
        sameArea = relation.sameArea,
        relativeAngleDegrees = relation.relativeAngleDegrees,
        bearingDegrees = relation.bearingDegrees,
    }
end

return Projection
