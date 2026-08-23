PNC = PNC or {}
PNC.Perception = PNC.Perception or {}
PNC.Perception.Internal = PNC.Perception.Internal or {}

local Perception = PNC.Perception
local Internal = Perception.Internal
local Core = PNC.Core
local Const = PNC.Const

local function resolveObservedAttacker(record, now, limit)
    local observed
    local observedZombie
    local observedDistSq
    local observedVisible
    local observedVisibilityKind
    local observedTarget
    observed = record.runtime and record.runtime.zombieAttacker or nil
    if not observed
        or now - (tonumber(observed.observedAt) or 0)
            > (tonumber(Const.ZOMBIE_ATTACKER_OBSERVATION_MS) or 1500)
    then
        return nil
    end
    observedZombie = Perception.FindZombieByID
        and Perception.FindZombieByID(observed.zombieId)
        or nil
    if not observedZombie
        or observedZombie:isDead()
        or math.abs(observedZombie:getZ() - record.z) >= 1
    then
        return nil
    end
    observedDistSq = Core.DistanceSq(
        record.x,
        record.y,
        observedZombie:getX(),
        observedZombie:getY()
    )
    if observedDistSq > limit * limit then return nil end
    observedVisible, observedVisibilityKind =
        Perception.CanSeeWorldObject(record, observedZombie)
    if not observedVisible then return nil end
    observedTarget = Internal.BuildZombieTarget(
        record,
        observedZombie,
        observedDistSq,
        observedVisibilityKind or "aggro_observed",
        observed.zombieId
    )
    if observedTarget then observedTarget.threatening = true end
    return observedTarget
end

local function findThreatInFrame(record, limit)
    local frame
    local entries
    local entry
    local candidate
    local best
    local visible
    local visibilityKind
    if not Perception.GetZombieFrame then return nil end
    frame = Perception.GetZombieFrame(record, limit)
    entries = frame and frame.entries or nil
    for i = 1, #(entries or {}) do
        entry = entries[i]
        if entry and entry.zombie
            and (tonumber(entry.distSq) or math.huge) <= limit * limit
        then
            visible, visibilityKind = Perception.CanSeeWorldObject(
                record,
                entry.zombie
            )
            if visible then
                candidate = Internal.BuildZombieTarget(
                    record,
                    entry.zombie,
                    entry.distSq,
                    visibilityKind or "immediate_threat"
                )
                if candidate and candidate.threatening == true then
                    best = Internal.PickNearest(best, candidate)
                end
            end
        end
    end
    return best
end

-- A no-initiation policy does not make a zombie harmless. This query is
-- deliberately independent of attackZombies and only returns a visible
-- zombie whose engine target is this NPC (or one remembered from damage).
function Perception.FindImmediateZombieThreat(record, radius)
    local now
    local recent
    local observedTarget
    local limit = tonumber(radius)
        or tonumber(Const.TARGET_IMMEDIATE_THREAT_RADIUS)
        or 4
    if not record then return nil end
    now = Core.Now and Core.Now() or 0
    recent = Perception.ResolveRecentAttacker(record, now)
    if recent and recent.kind == "zombie" then return recent end

    -- Multiplayer coordinate pursuit has no engine target. ZombieAggro keeps
    -- this observation fresh; the helper still enforces body, range, floor,
    -- and line-of-sight checks before returning it.
    observedTarget = resolveObservedAttacker(record, now, limit)
    if observedTarget then return observedTarget end
    return findThreatInFrame(record, limit)
end
