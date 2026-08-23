PNC = PNC or {}
PNC.Perception = PNC.Perception or {}
PNC.Perception.Internal = PNC.Perception.Internal or {}

local Perception = PNC.Perception
local Internal = Perception.Internal
local Core = PNC.Core
local Const = PNC.Const
local Spatial = PNC.SpatialIndex

function Perception.FindBestEnemyZombie(record, radius)
    local candidates
    local best
    local bestScore
    local i
    local j
    local entry
    local other
    local crowdCount
    local score
    local target
    local targetIsThreat
    local bestIsThreat
    local crowdRadiusSq = (tonumber(Const.COMBAT_TARGET_CROWD_RADIUS) or 2.2) ^ 2
    local crowdPenalty = 1.6

    if not record or record.hostility and record.hostility.attackZombies == false then
        return nil
    end

    candidates = Internal.CollectEnemyZombies(record, radius)
    bestScore = math.huge
    for i = 1, #candidates do
        entry = candidates[i]
        if entry and entry.zombie then
            crowdCount = 0
            for j = 1, #candidates do
                other = candidates[j]
                if other and other.zombie and other.zombie ~= entry.zombie
                    and math.abs(other.zombie:getZ() - entry.zombie:getZ()) < 1
                    and Core.DistanceSq(entry.zombie:getX(), entry.zombie:getY(), other.zombie:getX(), other.zombie:getY()) <= crowdRadiusSq
                then
                    crowdCount = crowdCount + 1
                end
            end
            score = entry.distSq + (crowdCount * crowdCount * crowdPenalty)
            target = Internal.BuildZombieTarget(record, entry.zombie, entry.distSq, entry.visibilityKind)
            targetIsThreat = Internal.IsImmediateThreat(target)
            bestIsThreat = Internal.IsImmediateThreat(best)
            if (targetIsThreat and not bestIsThreat)
                or (targetIsThreat == bestIsThreat and score < bestScore)
            then
                best = target
                bestScore = score
            end
        end
    end
    return best
end

function Perception.CountEnemyZombies(record, radius)
    local zombies
    local count = 0
    local i
    local entry

    if not record or record.hostility and record.hostility.attackZombies == false then
        return 0
    end

    if Perception.CountZombiesInFrame then
        return Perception.CountZombiesInFrame(
            record,
            tonumber(radius) or Const.ZOMBIE_TARGET_RADIUS
        )
    end
    zombies = Internal.CollectEnemyZombies(record, radius)
    for i = 1, #zombies do
        entry = zombies[i]
        if entry then
            count = count + 1
        end
    end

    return count
end

function Perception.FindZombieByID(zombieId)
    local zombie
    if not zombieId or not Spatial or not Spatial.FindZombieByID then
        return nil
    end
    zombie = Spatial.FindZombieByID(zombieId)
    if zombie then
        return zombie
    end
    if Spatial.Rebuild then
        Spatial.Rebuild(Core.Now(), false)
        return Spatial.FindZombieByID(zombieId)
    end
    return nil
end
