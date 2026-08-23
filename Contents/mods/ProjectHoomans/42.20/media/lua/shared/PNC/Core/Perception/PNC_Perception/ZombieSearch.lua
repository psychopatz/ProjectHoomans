PNC = PNC or {}
PNC.Perception = PNC.Perception or {}
PNC.Perception.Internal = PNC.Perception.Internal or {}

local Perception = PNC.Perception
local Internal = Perception.Internal

function Perception.FindNearestEnemyZombie(record, radius)
    local zombies
    local best
    local i
    local entry
    local candidate

    if not record or record.hostility and record.hostility.attackZombies == false then
        return nil
    end

    best = nil
    zombies = Internal.CollectEnemyZombies(record, radius)
    for i = 1, #zombies do
        entry = zombies[i]
        if entry then
            candidate = Internal.BuildZombieTarget(record, entry.zombie, entry.distSq, entry.visibilityKind)
            best = Internal.PickNearest(best, candidate)
        end
    end

    return best
end
