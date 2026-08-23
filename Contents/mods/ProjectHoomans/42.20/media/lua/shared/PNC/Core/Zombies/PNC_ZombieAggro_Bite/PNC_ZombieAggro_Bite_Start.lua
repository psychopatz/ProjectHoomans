local ZombieAggro = PNC.ZombieAggro
local BiteInternal = ZombieAggro.BiteInternal
local AggroInternal = ZombieAggro.Internal
local Core = PNC.Core
local Const = PNC.Const
local State = ZombieAggro.State

local function validateTarget(zombie, npcBody, record)
    local laneClear
    local laneReason
    if not zombie or not npcBody or not record
        or BiteInternal.ShouldPreventZombieAttack(record)
    then
        return false
    end
    laneClear, laneReason = ZombieAggro.HasBiteLane(
        zombie, npcBody, record
    )
    BiteInternal.RememberAttackLane(record, laneClear, laneReason)
    return laneClear == true
end

local function canOwnBite(zombie, now)
    local action = BiteInternal.ActionState(zombie)
    local bumpType = zombie.getBumpType and zombie:getBumpType() or ""
    if action == "staggerback" or action == "bumped"
        or bumpType == "Bite" or bumpType == "BiteLow"
    then
        return false
    end
    if ZombieAggro.Activate then
        ZombieAggro.Activate(zombie, now, "bite")
    end
    return not AggroInternal.canZombieAttack
        or AggroInternal.canZombieAttack(zombie, now)
end

local function chooseBumpType(npcBody, record)
    if (record.health and record.health.state == "incapacitated")
        or (npcBody.isProne and npcBody:isProne())
        or (npcBody.isCrawling and npcBody:isCrawling())
    then
        return "BiteLow"
    end
    return "Bite"
end

local function configureAttack(zombie, npcBody, bumpType)
    local previousNoTeeth = zombie.isNoTeeth
        and zombie:isNoTeeth() or false
    if npcBody.setZombiesDontAttack then
        npcBody:setZombiesDontAttack(false)
    end
    -- BumpedChr owns this scripted attack; setTarget() would create an
    -- unsupported MP character goal for the IsoZombie NPC shell.
    if zombie.setBumpedChr then zombie:setBumpedChr(npcBody) end
    if zombie.setBumpDone then zombie:setBumpDone(false) end
    if zombie.setVariable then
        zombie:setVariable("PNCZombieBitingNPC", true)
        zombie:setVariable("BumpDone", false)
        zombie:setVariable("BumpAnimFinished", false)
    end
    if zombie.setBumpType then zombie:setBumpType(bumpType) end
    if zombie.setNoTeeth then
        -- PNC owns the damage roll; suppress native AttackState damage.
        zombie:setNoTeeth(true)
    end
    return previousNoTeeth
end

local function createEntry(
    zombieId, zombie, npcBody, record, bumpType, previousNoTeeth, now
)
    return {
        zombieId = zombieId,
        npcId = record.id,
        zombie = zombie,
        npcBody = npcBody,
        bumpType = bumpType,
        phase = "windup",
        startedAt = now,
        applyAt = now + Const.ZOMBIE_BITE_APPLY_DELAY_MS,
        clearAt = now + Const.ZOMBIE_BITE_CLEAR_DELAY_MS,
        appliedDamage = false,
        broadcastClear = false,
        previousNoTeeth = previousNoTeeth,
    }
end

local function announceBite(entry, record)
    if PNC.Network and PNC.Network.BroadcastZombieBite then
        PNC.Network.BroadcastZombieBite(
            entry.zombie, entry.npcBody, record.id,
            "start", entry.bumpType
        )
    end
    Core.LogRecordDebug(
        record,
        "Zombie " .. tostring(entry.zombieId)
            .. " started bite on NPC " .. tostring(record.id)
    )
end

function ZombieAggro.TryStartBite(zombie, npcBody, record)
    local zombieId
    local now
    local bumpType
    local entry
    if not validateTarget(zombie, npcBody, record) then return false end
    zombieId = AggroInternal.ensureZombieID(zombie)
    if not zombieId then return false end
    if BiteInternal.GetBiteEntry(zombieId) then return true end
    now = Core.Now()
    if not canOwnBite(zombie, now) then return false end
    bumpType = chooseBumpType(npcBody, record)
    entry = createEntry(
        zombieId, zombie, npcBody, record, bumpType,
        configureAttack(zombie, npcBody, bumpType), now
    )
    State.bites[zombieId] = entry
    BiteInternal.SetBiteDiagnostic(record, entry, "started")
    announceBite(entry, record)
    return true
end
