local ZombieAggro = PNC.ZombieAggro
local BiteInternal = ZombieAggro.BiteInternal
local AggroInternal = ZombieAggro.Internal
local Core = PNC.Core
local Const = PNC.Const
local State = ZombieAggro.State

local function validateTarget(zombie, npcBody, record)
    local laneClear
    local laneReason
    if not zombie or not npcBody or not record then
        return false, "missing_target"
    end
    if zombie.isDead and zombie:isDead() then
        return false, "zombie_dead"
    end
    if record.alive == false
        or record.health and record.health.state == "dead"
    then
        return false, "npc_dead"
    end
    if record.presenceState ~= Const.PRESENCE_LIVE then
        return false, "npc_not_live"
    end
    if npcBody.isDead and npcBody:isDead() then
        return false, "npc_body_dead"
    end
    if BiteInternal.ShouldPreventZombieAttack(record) then
        return false, "npc_attack_protected"
    end
    laneClear, laneReason = ZombieAggro.HasBiteLane(
        zombie, npcBody, record
    )
    BiteInternal.RememberAttackLane(record, laneClear, laneReason)
    if laneClear ~= true then
        return false, laneReason or "bite_lane_blocked"
    end
    return true
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
        -- BumpedChr is the PNC attack lane. Keep the carrier shell outside
        -- vanilla zombie target acquisition while the scripted bite runs.
        npcBody:setZombiesDontAttack(true)
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
    local valid
    local validationReason
    valid, validationReason = validateTarget(zombie, npcBody, record)
    if not valid then
        if ZombieAggro.LogPursuitDiagnostic then
            ZombieAggro.LogPursuitDiagnostic(
                zombie,
                record and record.id or nil,
                "bite",
                "validation_rejected",
                "reason=" .. tostring(validationReason),
                Core.Now()
            )
        end
        return false
    end
    zombieId = AggroInternal.ensureZombieID(zombie)
    if not zombieId then
        if ZombieAggro.LogPursuitDiagnostic then
            ZombieAggro.LogPursuitDiagnostic(
                zombie, record.id, "bite", "missing_zombie_id", "",
                Core.Now()
            )
        end
        return false
    end
    if BiteInternal.GetBiteEntry(zombieId) then
        if ZombieAggro.LogPursuitDiagnostic then
            ZombieAggro.LogPursuitDiagnostic(
                zombie, record.id, "bite", "bite_already_active",
                "zombieId=" .. tostring(zombieId), Core.Now()
            )
        end
        return true
    end
    now = Core.Now()
    if not canOwnBite(zombie, now) then
        if ZombieAggro.LogPursuitDiagnostic then
            ZombieAggro.LogPursuitDiagnostic(
                zombie, record.id, "bite", "action_or_cooldown_rejected",
                "zombieId=" .. tostring(zombieId)
                    .. " action=" .. tostring(
                        BiteInternal.ActionState(zombie)
                    )
                    .. " bumpType=" .. tostring(
                        zombie.getBumpType
                            and zombie:getBumpType() or ""
                    ),
                now
            )
        end
        return false
    end
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
