if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

local Hooks = PNC.SocialEventHooks
local H = PNC.SocialEventHooksInternal
local Core = PNC.Core
local EntityRef = PNC.EntityRef
local Registry = PNC.Registry
local Network = PNC.Network
local Factions = PNC.Factions
local WITNESS_RADIUS = tonumber(H.WitnessRadius) or 12
local call = H.DamageCall
local audit = H.DamageAudit
local nowMillis = H.DamageNowMillis
local isAuthority = H.DamageIsAuthority
local nextEventID = H.DamageNextEventID
local positionOf = H.DamagePositionOf
local emitRelationshipEvent = H.DamageEmitRelationshipEvent
local emitForWitness = H.DamageEmitForWitness
local sameID = H.DamageSameID
local factionIDForRecord = H.DamageFactionIDForRecord
local playerFactionIDFor = H.DamagePlayerFactionIDFor
local factionIDForMember = H.DamageFactionIDForMember
local socialRole = H.DamageSocialRole
local playerCanReceive = H.DamagePlayerCanReceive
local witnessCanSeeDamage = H.DamageWitnessCanSeeDamage
local damageAttackerID = H.DamageAttackerID
local deliverTeammateDamageFlavor = H.DeliverTeammateDamageFlavor
local copyHurtContext = H.DamageCopyHurtContext
local PLAYER_HURT_WITNESS_COOLDOWN_MS =
    tonumber(Hooks.PlayerHurtWitnessCooldownMs) or 750
local PLAYER_HURT_WITNESS_MAX_KEYS = 256

function H.RecordPlayerDamagedNPC(player, record, hit)
    local actorKey
    local amount
    local eventID
    local context
    local result
    local reason
    if not isAuthority() then
        return false, "not_authority"
    end
    if not player or not record or not record.id then
        audit({
            "luaSide=server",
            "event=PlayerDamagedNPC",
            "phase=damage_observed",
            "result=false",
            "reason=missing_attacker_or_target",
        })
        return false, "missing_attacker_or_target"
    end
    actorKey = Hooks.ResolvePlayerKey(player)
    amount = tonumber(hit and (hit.damage or hit.amount)) or 0
    if not actorKey then
        return false, "player_identity_unavailable"
    end
    if amount <= 0 then
        return false, "invalid_damage"
    end
    eventID = nextEventID("player_damaged_npc", actorKey, record.id)
    context = {
        damage = amount,
        acceptedDamage = amount,
        attackType = hit and hit.attackType or nil,
        attackKind = hit and hit.attackKind or nil,
        woundType = hit and hit.woundType or nil,
        killed = record.alive == false,
        source = hit and hit.source or "player_weapon",
    }
    audit({
        "luaSide=server",
        "event=PlayerDamagedNPC",
        "phase=damage_observed",
        "result=true",
        "playerKey=" .. tostring(actorKey),
        "npcID=" .. tostring(record.id),
        "damage=" .. tostring(amount),
        "killed=" .. tostring(context.killed),
        "eventID=" .. tostring(eventID),
    })
    result, reason = emitRelationshipEvent(
        player,
        record.id,
        "player_damaged_npc",
        eventID,
        context,
        positionOf(player)
    )
    H.RecordFactionMemberAttack(player, record, {
        amount = amount,
        damage = amount,
        attackType = hit and hit.attackType or nil,
        attackKind = hit and hit.attackKind or nil,
        source = hit and hit.source or "player_weapon",
    }, actorKey)
    return result, reason
end

function H.RecordPlayerHurtWitnesses(player, attacker, context)
    local actorKey
    local radiusSq = WITNESS_RADIUS * WITNESS_RADIUS
    local candidates = 0
    local emitted = 0
    local attackerNPCID = context and context.attackerNPCID or nil
    local attackerID = context and context.attackerID
        or call(attacker, "getOnlineID")
        or "unknown"
    local position
    local safeContext
    local throttleKey
    local currentTime
    if not isAuthority() then
        return 0, 0, "not_authority"
    end
    if not player or not attacker or not Registry
        or type(Registry.ForEachLive) ~= "function"
    then
        return 0, 0, "witness_registry_unavailable"
    end
    actorKey = Hooks.ResolvePlayerKey(player)
    if not actorKey then
        return 0, 0, "player_identity_unavailable"
    end
    throttleKey = tostring(actorKey) .. ":" .. tostring(attackerID)
    currentTime = nowMillis()
    if Hooks.LastPlayerHurtWitnessAt[throttleKey]
        and currentTime < Hooks.LastPlayerHurtWitnessAt[throttleKey]
    then
        -- Witness notifications are presentation/social work.  Damage and
        -- the attacker's authoritative combat state are already committed;
        -- repeated hit callbacks do not need another full live-NPC scan.
        return 0, 0, "witness_cooldown"
    end
    if Hooks.LastPlayerHurtWitnessAt[throttleKey] == nil then
        local order = Hooks.PlayerHurtWitnessThrottleOrder
        order[#order + 1] = throttleKey
        if #order > PLAYER_HURT_WITNESS_MAX_KEYS then
            local oldest = table.remove(order, 1)
            Hooks.LastPlayerHurtWitnessAt[oldest] = nil
        end
    end
    Hooks.LastPlayerHurtWitnessAt[throttleKey] =
        currentTime + PLAYER_HURT_WITNESS_COOLDOWN_MS
    position = positionOf(attacker)
    safeContext = copyHurtContext(context, attacker)
    safeContext.attackerID = attackerID
    Registry.ForEachLive(function(record, body, npcID)
        local eventID
        local targetKey
        local result
        local reason
        if not record or record.alive == false or not body or not npcID
            or (body.isDead and body:isDead())
            or (attackerNPCID and tostring(attackerNPCID) == tostring(npcID))
        then
            return
        end
        if not H.LiveNPCIsWitness
            or not H.LiveNPCIsWitness(
                record,
                body,
                player,
                attacker,
                radiusSq
            )
        then
            return
        end
        candidates = candidates + 1
        targetKey = EntityRef and EntityRef.ForNPC
            and EntityRef.ForNPC(npcID) or nil
        if not targetKey then
            return
        end
        eventID = nextEventID(
            "witnessed_player_hurt",
            actorKey,
            npcID
        )
        safeContext.witnessNPCID = tostring(npcID)
        result, reason = emitForWitness(
            player,
            npcID,
            "witnessed_player_hurt",
            eventID,
            safeContext,
            position
        )
        if result then emitted = emitted + 1 end
        audit({
            "luaSide=server",
            "event=PlayerHurtWitness",
            "phase=witness_scan",
            "result=" .. tostring(result == true),
            "reason=" .. tostring(reason or "nil"),
            "playerKey=" .. tostring(actorKey),
            "witnessNPCID=" .. tostring(npcID),
            "attackerID=" .. tostring(attackerID),
            "damage=" .. tostring(safeContext.damage),
            "woundType=" .. tostring(safeContext.woundType or "unknown"),
        })
    end)
    audit({
        "luaSide=server",
        "event=PlayerHurtWitnessScan",
        "phase=witness_scan",
        "result=" .. tostring(emitted > 0),
        "reason=" .. tostring(
            emitted > 0 and "witnesses_notified"
                or "no_witness_event_emitted"
        ),
        "playerKey=" .. tostring(actorKey),
        "attackerID=" .. tostring(attackerID),
        "witnessCandidates=" .. tostring(candidates),
        "witnessCount=" .. tostring(emitted),
        "damage=" .. tostring(safeContext.damage),
        "woundType=" .. tostring(safeContext.woundType or "unknown"),
    })
    return emitted, candidates, emitted > 0
        and "witnesses_notified" or "no_witness_event_emitted"
end

function H.RecordNPCDamagedPlayer(player, attackerRecord, attackerBody, hit)
    local amount = tonumber(hit and (hit.healthLoss or hit.amount)) or 0
    if not attackerRecord or not attackerRecord.id then
        return 0, 0, "attacker_record_unavailable"
    end
    if amount <= 0 then
        return 0, 0, "invalid_damage"
    end
    return H.RecordPlayerHurtWitnesses(player, attackerBody, {
        damage = amount,
        healthLoss = tonumber(hit and hit.healthLoss) or amount,
        woundType = hit and hit.woundType or "scratch",
        attackerKind = "npc",
        attackerID = attackerRecord.id,
        attackerNPCID = attackerRecord.id,
        source = "hoomans_npc_attack",
    })
end


return H
