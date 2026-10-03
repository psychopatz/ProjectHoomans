-- Short-lived horde avoidance target resolver for live follower movement.

PNC = PNC or {}
PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}
PNC.BehaviorCompanion.Internal = PNC.BehaviorCompanion.Internal or {}

local Companion = PNC.BehaviorCompanion
local Internal = Companion.Internal
local H = Internal.FollowHazardTargetResolver
if type(H) ~= "table" then
    return Companion
end

local Core = H.Core
local Const = H.Const
local CandidatePlanner = H.CandidatePlanner

function H.Resolve(record, slotTarget, slotDist, hazard, now)
    local runtime = record.runtime or {}
    local target = runtime.followAvoidanceTarget or {}
    local candidateX
    local candidateY
    local candidateZ

    record.runtime = runtime
    runtime.followAvoidanceTarget = target
    if not slotTarget
        or not hazard
        or hazard.active ~= true
        or slotTarget.indoorApproach == true
        or math.abs((tonumber(slotTarget.z) or record.z) - record.z) >= 1
    then
        target.active = false
        return nil
    end
    if target.active == true
        and now < (tonumber(target.expiresAt) or 0)
        and Core.DistanceSq(
            record.x,
            record.y,
            tonumber(target.x) or record.x,
            tonumber(target.y) or record.y
        ) > 0.49
    then
        return target
    end

    if CandidatePlanner and CandidatePlanner.Plan then
        candidateX, candidateY, candidateZ = CandidatePlanner.Plan(
            record,
            slotTarget,
            slotDist,
            hazard
        )
    end
    if not candidateX then
        target.active = false
        return nil
    end

    target.x = candidateX
    target.y = candidateY
    target.z = candidateZ
    target.stopDistance = 0.55
    target.active = true
    target.avoidance = true
    target.hazardCount = hazard.count
    target.expiresAt = now
        + (tonumber(Const.FOLLOW_HORDE_STEER_MS) or 350)
    return target
end

return Companion
