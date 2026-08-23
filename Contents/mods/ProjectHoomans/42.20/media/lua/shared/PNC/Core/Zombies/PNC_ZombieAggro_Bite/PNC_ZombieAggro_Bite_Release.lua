local ZombieAggro = PNC.ZombieAggro
local BiteInternal = ZombieAggro.BiteInternal
local AggroInternal = ZombieAggro.Internal
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local State = ZombieAggro.State

function BiteInternal.FinalizeRelease(zombieId, entry, now, reason)
    local zombie = entry and entry.zombie or nil
    local npcBody = entry and entry.npcBody or nil
    local record = entry and Registry.Get(entry.npcId) or nil
    if npcBody and npcBody.setZombiesDontAttack then
        npcBody:setZombiesDontAttack(
            BiteInternal.ShouldPreventZombieAttack(record)
        )
    end
    BiteInternal.SignalBumpFinish(zombie)
    if zombie and zombie.setBumpType then zombie:setBumpType("") end
    if zombie and zombie.setBumpedChr then zombie:setBumpedChr(nil) end
    if zombie and zombie.setVariable then
        zombie:setVariable("PNCZombieBitingNPC", false)
    end
    if zombie and zombie.setNoTeeth then
        zombie:setNoTeeth(entry and entry.previousNoTeeth == true or false)
    end
    if entry then
        entry.phase = "finished"
        entry.finishedAt = now
        entry.releaseReason = reason or entry.releaseReason
        BiteInternal.SetBiteDiagnostic(record, entry, entry.releaseReason)
    end
    State.bites[zombieId] = nil
end

function BiteInternal.BeginRelease(zombieId, npcBody, reason, now)
    local entry
    local record
    if not zombieId or not State.bites then return false end
    entry = State.bites[zombieId]
    if not entry then return false end
    if entry.phase == "release" then return true end
    now = tonumber(now) or Core.Now()
    entry.phase = "release"
    entry.releaseAt = now
    entry.releaseDeadline = now
        + (tonumber(Const.BITE_RELEASE_TIMEOUT_MS) or 650)
    entry.releaseReason = reason or "complete"
    entry.npcBody = entry.npcBody or npcBody
    BiteInternal.SignalBumpFinish(entry.zombie)
    if entry.broadcastClear ~= true
        and PNC.Network and PNC.Network.BroadcastZombieBite
    then
        entry.broadcastClear = true
        PNC.Network.BroadcastZombieBite(
            entry.zombie, entry.npcBody, entry.npcId,
            "clear", entry.bumpType
        )
    end
    record = Registry.Get(entry.npcId)
    BiteInternal.SetBiteDiagnostic(record, entry, entry.releaseReason)
    return true
end

function ZombieAggro.ClearBiteEntryForZombie(zombie, reason)
    local zombieId = AggroInternal.ensureZombieID(zombie)
    return BiteInternal.BeginRelease(
        zombieId, nil, reason or "cleared", Core.Now()
    )
end

function ZombieAggro.ClearBiteEntriesForNPCBody(npcBody, reason)
    local zombieId
    local entry
    if not npcBody or not State.bites then return end
    for zombieId, entry in pairs(State.bites) do
        if entry and entry.npcBody == npcBody then
            BiteInternal.BeginRelease(
                zombieId, npcBody, reason or "npc_body_cleared", Core.Now()
            )
        end
    end
end
