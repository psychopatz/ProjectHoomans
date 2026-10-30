-- Saved companion directives and departure/abandonment markers, without command dispatch.
local Repository = {}
local Codec = require "PNC/Core/Base/PNC_RecordCodec"
local Core = PNC.Core
local Const = PNC.Const

function Repository.NormalizeOrder(orderSpec, record)
    local spec = type(orderSpec) == "table" and Core.DeepCopy(orderSpec) or nil
    if not spec then
        return nil
    end
    if spec.points then
        spec.points = Codec.copyPoints(spec.points, record.anchorX, record.anchorY, record.anchorZ)
    end
    if spec.x ~= nil then
        spec.x = Codec.normalizeNumber(spec.x, record.anchorX)
    end
    if spec.y ~= nil then
        spec.y = Codec.normalizeNumber(spec.y, record.anchorY)
    end
    if spec.z ~= nil then
        spec.z = Codec.normalizeNumber(spec.z, record.anchorZ)
    end
    if spec.radius ~= nil then
        spec.radius = math.max(0.5, Codec.normalizeNumber(spec.radius, Const.ROAM_DEFAULT_RADIUS))
    end
    if spec.targetRadius ~= nil then
        spec.targetRadius = math.max(1, Codec.normalizeNumber(spec.targetRadius, Const.ROAM_TARGET_RADIUS))
    end
    if spec.reachedDistance ~= nil then
        spec.reachedDistance = math.max(0.1, Codec.normalizeNumber(spec.reachedDistance, Const.ROAM_REACHED_DISTANCE))
    end
    if spec.pauseMinMs ~= nil then
        spec.pauseMinMs = math.max(0, Codec.normalizeNumber(spec.pauseMinMs, Const.ROAM_PAUSE_MIN_MS))
    end
    if spec.pauseMaxMs ~= nil then
        local minimum = tonumber(spec.pauseMinMs) or Const.ROAM_PAUSE_MIN_MS
        spec.pauseMaxMs = math.max(minimum, Codec.normalizeNumber(spec.pauseMaxMs, Const.ROAM_PAUSE_MAX_MS))
    end
    spec.roamMode = Codec.normalizeString(spec.roamMode)
    spec.moveMode = Codec.normalizeString(spec.moveMode)
    spec.ownerUsername = Codec.normalizeString(spec.ownerUsername)
    spec.ownerCharacterUUID = Codec.normalizeString(
        spec.ownerCharacterUUID
    )
    -- Online IDs are session-scoped; the character UUID is the durable owner.
    spec.ownerOnlineID = nil
    spec.journeyId = Codec.normalizeString(spec.journeyId)
    return spec
end

function Repository.SerializePatrolPoints(record)
    local points = record and record.patrolPoints or nil
    local orderKind = record and record.orderSpec
        and tostring(record.orderSpec.kind or "") or ""
    if orderKind ~= tostring(Const.ORDER_PATROL or "patrol")
        and (type(points) ~= "table" or #points <= 1)
    then
        return nil
    end
    return Codec.copyPoints(points, record.anchorX, record.anchorY, record.anchorZ)
end
function Repository.NormalizeAbandonment(raw)
    local source = type(raw) == "table" and raw or nil
    local eventID
    local hostileKind
    if not source then return nil end
    eventID = Codec.normalizeString(source.eventID)
    hostileKind = Codec.normalizeString(source.hostileKind)
    if not eventID or (hostileKind ~= "zombie" and hostileKind ~= "npc") then
        return nil
    end
    return {
        eventID = string.sub(eventID, 1, 256),
        ownerKey = Codec.normalizeString(source.ownerKey),
        ownerUsername = Codec.normalizeString(source.ownerUsername),
        ownerOnlineID = source.ownerOnlineID ~= nil
            and (tonumber(source.ownerOnlineID) or tostring(source.ownerOnlineID))
            or nil,
        hostileKind = hostileKind,
        hostileID = Codec.normalizeString(source.hostileID),
        capturedAt = math.max(0, Codec.normalizeNumber(source.capturedAt, 0)),
        relationshipApplied = source.relationshipApplied == true,
    }
end

-- Relationship-triggered colonist departure is a separate persisted marker
-- from follow-phase combat abandonment. It is intentionally compact: a save
-- only needs the debounce/audit edge, never a copied relationship payload.
function Repository.NormalizeDeparture(raw)
    local source = type(raw) == "table" and raw or nil
    local state
    local eventID
    if not source then return nil end
    state = source.state == "completed" and "completed" or "pending"
    eventID = Codec.normalizeString(source.eventID)
    if not eventID then return nil end
    return {
        state = state,
        eventID = string.sub(eventID, 1, 256),
        ownerKey = Codec.normalizeString(source.ownerKey),
        sourceFactionID = Codec.normalizeString(source.sourceFactionID),
        destinationFactionID = Codec.normalizeString(
            source.destinationFactionID
        ),
        cause = Codec.normalizeString(source.cause),
        belowThresholdChecks = math.max(0, math.min(8, math.floor(
            Codec.normalizeNumber(source.belowThresholdChecks, 0)
        ))),
        firstDetectedAt = math.max(
            0, Codec.normalizeNumber(source.firstDetectedAt, 0)
        ),
        lastEvaluatedAt = math.max(
            0, Codec.normalizeNumber(source.lastEvaluatedAt, 0)
        ),
        completedAt = source.completedAt ~= nil and math.max(
            0, Codec.normalizeNumber(source.completedAt, 0)
        ) or nil,
        approvalThreshold = source.approvalThreshold ~= nil
            and Codec.normalizeNumber(source.approvalThreshold, -60)
            or nil,
        respectThreshold = source.respectThreshold ~= nil
            and Codec.normalizeNumber(source.respectThreshold, -60)
            or nil,
    }
end

function Repository.SerializeOrder(record)
    local order = record and record.orderSpec or nil
    if type(order) ~= "table"
        or tostring(order.kind or "") == "facility_activity"
    then
        return nil
    end
    return Repository.NormalizeOrder(order, record)
end

function Repository.RestoreDirective(record, raw)
    record.patrolPoints = Codec.copyPoints(raw.patrolPoints or record.patrolPoints, record.anchorX, record.anchorY, record.anchorZ)
    record.patrolIndex = math.max(1, math.floor(Codec.normalizeNumber(raw.patrolIndex, 1)))
    record.orderSpec = Repository.NormalizeOrder(raw.orderSpec, record)
    if record.orderSpec and PNC.OrderSystem and PNC.OrderSystem.Normalize then
        record.orderSpec = PNC.OrderSystem.Normalize(record, record.orderSpec)
    end
end

function Repository.RestoreMarkers(record, raw)
    record.followerAbandonment = Repository.NormalizeAbandonment(raw.followerAbandonment)
    record.colonistDeparture = Repository.NormalizeDeparture(raw.colonistDeparture)
end

function Repository.IsFollowing(record)
    return tostring(record.orderSpec and record.orderSpec.kind or "")
        == tostring(Const.ORDER_FOLLOW or "follow")
end

function Repository.SetTravelOrder(record, journeyID)
    record.orderSpec = { kind = Const.ORDER_TRAVEL or "travel", journeyId = journeyID }
end

return Repository
