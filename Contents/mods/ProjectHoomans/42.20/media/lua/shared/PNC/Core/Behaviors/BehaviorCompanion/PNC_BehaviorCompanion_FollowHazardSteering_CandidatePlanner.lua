-- Candidate-vector policy for horde avoidance steering.

PNC = PNC or {}
PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}
PNC.BehaviorCompanion.Internal = PNC.BehaviorCompanion.Internal or {}

local Companion = PNC.BehaviorCompanion
local H = Companion.Internal.FollowHazardCandidatePlanner
if type(H) ~= "table" then
    return Companion
end

local Const = H.Const
local TraversalQuery = H.TraversalQuery
local NormalizeDirection = H.NormalizeDirection

local function canUseFollowSteer(record, x, y, z, dirX, dirY)
    if TraversalQuery and TraversalQuery.CanStep
        and not TraversalQuery.CanStep(
            record.x,
            record.y,
            record.z,
            record.x + (dirX * 0.75),
            record.y + (dirY * 0.75),
            z
        )
    then
        return false
    end
    return not TraversalQuery
        or not TraversalQuery.CanOccupy
        or TraversalQuery.CanOccupy(x, y, z)
end

function H.Plan(record, slotTarget, slotDist, hazard)
    local baseX
    local baseY
    local repelX
    local repelY
    local tangentX
    local tangentY
    local dirX
    local dirY
    local dot
    local distance
    local candidateX
    local candidateY
    local candidateZ = tonumber(slotTarget.z) or record.z

    baseX, baseY = NormalizeDirection(
        slotTarget.x - record.x,
        slotTarget.y - record.y
    )
    repelX, repelY = NormalizeDirection(
        tonumber(hazard.repelX) or 0,
        tonumber(hazard.repelY) or 0
    )
    if not baseX or not repelX then
        return nil
    end

    dirX, dirY = NormalizeDirection(
        baseX + (
            repelX * math.min(1.35, 0.45 + hazard.count * 0.2)
        ),
        baseY + (
            repelY * math.min(1.35, 0.45 + hazard.count * 0.2)
        )
    )
    dot = dirX and ((dirX * baseX) + (dirY * baseY)) or -1
    if dot < 0.55 then
        tangentX = -baseY
        tangentY = baseX
        if (tangentX * repelX) + (tangentY * repelY) < 0 then
            tangentX = -tangentX
            tangentY = -tangentY
        end
        dirX, dirY = NormalizeDirection(
            (baseX * 0.68) + (tangentX * 0.72),
            (baseY * 0.68) + (tangentY * 0.72)
        )
    end
    if not dirX then
        return nil
    end

    distance = math.min(
        tonumber(Const.FOLLOW_HORDE_STEER_DISTANCE) or 3.4,
        math.max(0.65, tonumber(slotDist) or 0.65)
    )
    candidateX = record.x + (dirX * distance)
    candidateY = record.y + (dirY * distance)
    if not canUseFollowSteer(
        record,
        candidateX,
        candidateY,
        candidateZ,
        dirX,
        dirY
    ) then
        -- The opposite side still makes forward progress toward the owner.
        dirX, dirY = NormalizeDirection(
            (baseX * 0.68) + (baseY * 0.72),
            (baseY * 0.68) - (baseX * 0.72)
        )
        candidateX = record.x + (dirX * distance)
        candidateY = record.y + (dirY * distance)
        if not canUseFollowSteer(
            record,
            candidateX,
            candidateY,
            candidateZ,
            dirX,
            dirY
        ) then
            return nil
        end
    end
    return candidateX, candidateY, candidateZ
end

return Companion
