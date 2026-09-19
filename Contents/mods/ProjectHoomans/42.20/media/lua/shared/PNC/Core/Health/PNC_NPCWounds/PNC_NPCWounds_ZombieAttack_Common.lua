PNC = PNC or {}
local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal
local Core = PNC.Core
local Const = PNC.Const
local LIVE_PRESENCE = Const and Const.PRESENCE_LIVE or "live"

function Internal.HasServerAuthority()
    return Core and type(Core.IsAuthority) == "function"
        and Core.IsAuthority() == true
end

function Internal.IsLiveZombieTarget(record, npcBody)
    if not record or record.alive == false then
        return false
    end
    if record.health and record.health.state == "dead" then
        return false
    end
    if record.presenceState ~= LIVE_PRESENCE then
        return false
    end
    return not (npcBody and npcBody.isDead and npcBody:isDead())
end

function Internal.RecordZombieDamage(
    record,
    attacker,
    attackerZombieId
)
    if PNC.SocialEncounterTracker
        and PNC.SocialEncounterTracker.RecordNPCDamaged
        and PNC.SocialEventHooks
    then
        PNC.SocialEncounterTracker.RecordNPCDamaged(
            record,
            attackerZombieId,
            PNC.SocialEventHooks.WorldAgeHours(),
            {
                x = attacker and attacker.getX
                    and attacker:getX() or record.x,
                y = attacker and attacker.getY
                    and attacker:getY() or record.y,
                z = attacker and attacker.getZ
                    and attacker:getZ() or record.z,
            }
        )
    end
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent = "npc_wound"
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "wounds")
    end
end

function Internal.EmitZombieDamageHook(
    record,
    npcBody,
    attacker,
    damage,
    wound,
    attackerZombieId,
    source
)
    local socialHooks = PNC.SocialEventHooksInternal
    if not socialHooks or not socialHooks.RecordNPCDamagedByZombie then
        return
    end
    local scalarDamage = tonumber(damage) or 0
    -- This is an addon-owned callback boundary; a hook failure must not undo accepted damage.
    pcall(
        socialHooks.RecordNPCDamagedByZombie,
        record,
        npcBody,
        attacker,
        {
            amount = scalarDamage,
            damage = scalarDamage,
            healthLoss = scalarDamage,
            woundType = wound.type,
            attackerKind = "zombie",
            attackerZombieID = attackerZombieId,
            attackerID = attackerZombieId,
            source = source,
        }
    )
end

function Internal.ApplyZombieWoundDamage(
    record,
    npcBody,
    attacker,
    attackerZombieId,
    part,
    woundType,
    rejectedResult
)
    if not Internal.HasServerAuthority() then
        return nil, { outcome = "not_authority" }
    end
    if not Internal.IsLiveZombieTarget(record, npcBody) then
        return nil, { outcome = "target_invalid", partId = part.id }
    end
    if not PNC.Health or type(PNC.Health.ApplyDamage) ~= "function" then
        return nil, { outcome = "damage_unavailable", partId = part.id }
    end
    local body = Wounds.Ensure(record)
    local previousWound = body.wounds[part.id]
        and Core.DeepCopy(body.wounds[part.id]) or nil
    local previousInfection = body.infection
        and Core.DeepCopy(body.infection) or nil
    local wound, damage = Internal.AddWound(
        record,
        part,
        woundType,
        Core.Now()
    )
    local applied = wound and PNC.Health.ApplyDamage(record, npcBody, {
        amount = damage,
        partId = part.id,
        type = "zombie_" .. woundType,
        attackerKind = "zombie",
        attackerZombieId = attackerZombieId,
        x = attacker and attacker.getX
            and attacker:getX() or record.x,
        y = attacker and attacker.getY
            and attacker:getY() or record.y,
        z = attacker and attacker.getZ
            and attacker:getZ() or record.z,
    })
    if not applied then
        body.wounds[part.id] = previousWound
        body.infection = previousInfection
        Wounds.Recalculate(record)
        return nil, rejectedResult or {
            outcome = "damage_rejected",
            partId = part.id,
        }
    end
    return wound, nil, damage
end

return Wounds
