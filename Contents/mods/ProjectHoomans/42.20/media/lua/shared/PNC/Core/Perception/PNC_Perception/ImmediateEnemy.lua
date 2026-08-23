PNC = PNC or {}
PNC.Perception = PNC.Perception or {}
PNC.Perception.Internal = PNC.Perception.Internal or {}

local Perception = PNC.Perception
local Internal = Perception.Internal
local Const = PNC.Const

-- Immediate proximity does not override walls. Treating every nearby spatial
-- candidate as actionable made NPCs stare at zombies in the next room while
-- scripted bite damage continued through the shared wall.
function Perception.FindImmediateEnemyZombie(record, radius)
    local frame
    local entries
    local entry
    local visible
    local visibilityKind
    local i
    local limit = tonumber(radius)
        or tonumber(Const.TARGET_IMMEDIATE_THREAT_RADIUS)
        or 4
    local limitSq = limit * limit
    if not record
        or record.hostility and record.hostility.attackZombies == false
        or not Perception.GetZombieFrame
    then
        return nil
    end
    frame = Perception.GetZombieFrame(record, limit)
    entries = frame and frame.entries or nil
    for i = 1, #(entries or {}) do
        entry = entries[i]
        if entry and entry.zombie and entry.distSq <= limitSq then
            visible, visibilityKind =
                Perception.CanSeeWorldObject(
                    record,
                    entry.zombie
                )
            if visible then
                return Internal.BuildZombieTarget(
                    record,
                    entry.zombie,
                    entry.distSq,
                    visibilityKind or "proximity"
                )
            end
        end
    end
    return nil
end
