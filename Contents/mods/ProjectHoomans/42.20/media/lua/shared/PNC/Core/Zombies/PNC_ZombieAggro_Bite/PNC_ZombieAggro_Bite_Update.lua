local ZombieAggro = PNC.ZombieAggro
local BiteInternal = ZombieAggro.BiteInternal
local AggroInternal = ZombieAggro.Internal
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Settings = PNC.Sandbox
local State = ZombieAggro.State

local function updateRelease(zombieId, entry, record, zombie, now)
    local action
    BiteInternal.SignalBumpFinish(zombie)
    action = BiteInternal.ActionState(zombie)
    BiteInternal.SetBiteDiagnostic(record, entry, entry.releaseReason)
    if (action ~= "bumped"
            and (now - (tonumber(entry.releaseAt) or now)) >= 35)
        or now >= (tonumber(entry.releaseDeadline) or now)
    then
        BiteInternal.FinalizeRelease(
            zombieId, entry, now,
            action == "bumped" and "release_timeout"
                or entry.releaseReason
        )
    end
end

local function invalidTargetReason(record, npcBody)
    if not record or not npcBody or record.alive == false
        or record.presenceState ~= Const.PRESENCE_LIVE
        or (npcBody.isDead and npcBody:isDead())
    then
        return "target_invalid"
    end
    if not Settings.CanZombieTargetRecord(record) then
        return "target_protected"
    end
    return nil
end

local function biteDistance(zombie, npcBody)
    return Core.Distance(
        zombie:getX(), zombie:getY(), npcBody:getX(), npcBody:getY()
    )
end

local function shouldReleaseActiveBite(zombie, npcBody, record)
    local clear
    local reason = invalidTargetReason(record, npcBody)
    if reason then return reason end
    if biteDistance(zombie, npcBody)
        > (Const.ZOMBIE_BITE_DISTANCE * 1.35)
    then
        return "target_out_of_range"
    end
    clear, reason = ZombieAggro.HasBiteLane(zombie, npcBody, record)
    BiteInternal.RememberAttackLane(record, clear, reason)
    if not clear then
        return reason or "bite_lane_blocked"
    end
    return nil
end

function ZombieAggro.UpdateBiteState(zombie, now)
    local zombieId
    local entry
    local record
    local npcBody
    local releaseReason
    if not zombie then return false end
    zombieId = AggroInternal.ensureZombieID(zombie)
    entry = BiteInternal.GetBiteEntry(zombieId)
    if not entry then return false end
    now = tonumber(now) or Core.Now()
    record = Registry.Get(entry.npcId)
    npcBody = entry.npcBody
    if zombie.isDead and zombie:isDead() then
        BiteInternal.BeginRelease(zombieId, npcBody, "attacker_dead", now)
        return true
    end
    if entry.phase == "release" then
        updateRelease(zombieId, entry, record, zombie, now)
        return true
    end
    releaseReason = shouldReleaseActiveBite(zombie, npcBody, record)
    if releaseReason then
        BiteInternal.BeginRelease(zombieId, npcBody, releaseReason, now)
        return true
    end
    if entry.appliedDamage ~= true
        and now >= (tonumber(entry.applyAt) or now)
    then
        BiteInternal.ApplyBiteDamage(entry, record, zombie, npcBody, now)
    end
    if now >= (tonumber(entry.clearAt) or now) then
        BiteInternal.BeginRelease(zombieId, npcBody, "complete", now)
    end
    return true
end

function ZombieAggro.PumpBiteRecovery(now)
    local zombieId
    local entry
    local zombie
    local releaseAt
    now = tonumber(now) or Core.Now()
    for zombieId, entry in pairs(State.bites or {}) do
        zombie = entry and entry.zombie or nil
        if not zombie then
            BiteInternal.FinalizeRelease(
                zombieId, entry, now, "attacker_missing"
            )
        elseif (zombie.isDead and zombie:isDead())
            or (zombie.getSquare and zombie:getSquare() == nil)
        then
            BiteInternal.BeginRelease(
                zombieId, entry.npcBody, "attacker_lost", now
            )
            releaseAt = tonumber(entry.releaseAt) or now
            BiteInternal.SignalBumpFinish(zombie)
            if (now - releaseAt) >= 35
                or now >= (tonumber(entry.releaseDeadline) or now)
            then
                BiteInternal.FinalizeRelease(
                    zombieId, entry, now, "attacker_lost"
                )
            end
        elseif entry.phase == "release" then
            ZombieAggro.UpdateBiteState(zombie, now)
        end
    end
end
