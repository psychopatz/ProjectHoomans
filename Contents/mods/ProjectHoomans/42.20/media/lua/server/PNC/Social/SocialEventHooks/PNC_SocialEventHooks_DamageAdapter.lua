-- Server-authoritative combat damage observations for social relationships.

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

local POLL_INTERVAL_MS = 100
local VANILLA_MARKER_WINDOW_MS = 500
local WITNESS_RADIUS = tonumber(H.WitnessRadius) or 12

Hooks.CombatEventSequence = Hooks.CombatEventSequence or 0
Hooks.VanillaDamageSnapshots = Hooks.VanillaDamageSnapshots or {}
Hooks.VanillaDamageMarkers = Hooks.VanillaDamageMarkers or {}
Hooks.LastVanillaDamagePollAt = Hooks.LastVanillaDamagePollAt or 0

local function call(object, method, ...)
    if not object or not object[method] then
        return nil
    end
    local ok, value = pcall(object[method], object, ...)
    if ok then
        return value
    end
    return nil
end

local function audit(fields)
    local message = "[RelationshipCombatAudit] " .. table.concat(fields, " ")
    if Core and Core.LogInfo then
        Core.LogInfo(message)
    elseif print then
        print("[PNC][INFO] " .. message)
    end
end

local function nowMillis()
    if Core and Core.Now then
        return tonumber(Core.Now()) or 0
    end
    return 0
end

local function worldAgeHours()
    if H and H.WorldAgeHours then
        return tonumber(H.WorldAgeHours()) or 0
    end
    return 0
end

local function isAuthority()
    if Core and Core.IsAuthority then
        return Core.IsAuthority() == true
    end
    return true
end

local function nextEventID(eventType, actorKey, subjectID)
    Hooks.CombatEventSequence = Hooks.CombatEventSequence + 1
    return "social:" .. tostring(eventType) .. ":"
        .. tostring(actorKey) .. ":" .. tostring(subjectID) .. ":"
        .. tostring(worldAgeHours()) .. ":"
        .. tostring(Hooks.CombatEventSequence)
end

local function relationshipDelta(before, after)
    return {
        approval = (tonumber(after and after.approval) or 0)
            - (tonumber(before and before.approval) or 0),
        respect = (tonumber(after and after.respect) or 0)
            - (tonumber(before and before.respect) or 0),
        familiarity = (tonumber(after and after.familiarity) or 0)
            - (tonumber(before and before.familiarity) or 0),
    }
end

local function positionOf(object)
    return {
        x = call(object, "getX"),
        y = call(object, "getY"),
        z = call(object, "getZ"),
    }
end

local function emitRelationshipEvent(
    player,
    npcID,
    eventType,
    eventID,
    context,
    position
)
    local targetKey
    local event
    local ok
    local processed
    local reason
    local detail
    local sent
    local presentationReason
    local callOK
    if not player or not npcID then
        return false, "missing_presentation_target"
    end
    targetKey = EntityRef and EntityRef.ForNPC
        and EntityRef.ForNPC(npcID) or nil
    if not targetKey then
        return false, "npc_key_unavailable"
    end
    if not PNC.SocialEvents
        or type(PNC.SocialEvents.Emit) ~= "function"
    then
        return false, "social_event_service_unavailable"
    end
    event = {
        id = eventID,
        type = eventType,
        actorKey = Hooks.ResolvePlayerKey(player),
        targetKey = targetKey,
        occurredAt = worldAgeHours(),
        sourceSystem = "combat",
        x = position and position.x or nil,
        y = position and position.y or nil,
        z = position and position.z or nil,
        context = context or {},
    }
    if not event.actorKey then
        return false, "player_identity_unavailable"
    end
    callOK, processed = pcall(PNC.SocialEvents.Emit, event)
    if not callOK then
        audit({
            "luaSide=server",
            "event=" .. tostring(eventType),
            "phase=relationship_dispatch",
            "result=false",
            "reason=emit_error",
            "eventID=" .. tostring(eventID),
            "npcID=" .. tostring(npcID),
        })
        return false, "emit_error"
    end
    reason = processed and processed.reason or "unknown_result"
    if not processed or processed.ok ~= true then
        audit({
            "luaSide=server",
            "event=" .. tostring(eventType),
            "phase=relationship_dispatch",
            "result=false",
            "reason=" .. tostring(reason),
            "eventID=" .. tostring(eventID),
            "npcID=" .. tostring(npcID),
        })
        return false, reason
    end
    detail = processed.details and processed.details[1] or nil
    if Network
        and type(Network.SendConversationRelationshipForNPC) == "function"
    then
        callOK, sent, presentationReason = pcall(
            Network.SendConversationRelationshipForNPC,
            player,
            npcID,
            eventType,
            {
                source = eventType,
                eventID = processed.eventID or eventID,
                relationshipBefore = detail
                    and detail.relationshipBefore or nil,
                relationshipAfter = detail
                    and detail.relationshipAfter or nil,
                relationshipDelta = relationshipDelta(
                    detail and detail.relationshipBefore or nil,
                    detail and detail.relationshipAfter or nil
                ),
                npcID = tostring(npcID),
            }
        )
        if not callOK then
            sent = false
            presentationReason = "transport_error"
        end
    else
        sent = false
        presentationReason = "relationship_transport_unavailable"
    end
    audit({
        "luaSide=server",
        "event=" .. tostring(eventType),
        "phase=relationship_feedback",
        "result=" .. tostring(sent == true),
        "reason=" .. tostring(presentationReason or "nil"),
        "eventID=" .. tostring(eventID),
        "npcID=" .. tostring(npcID),
        "approvalDelta=" .. tostring(
            relationshipDelta(
                detail and detail.relationshipBefore or nil,
                detail and detail.relationshipAfter or nil
            ).approval
        ),
        "respectDelta=" .. tostring(
            relationshipDelta(
                detail and detail.relationshipBefore or nil,
                detail and detail.relationshipAfter or nil
            ).respect
        ),
    })
    audit({
        "luaSide=server",
        "event=" .. tostring(eventType),
        "phase=relationship_dispatch",
        "result=true",
        "reason=applied",
        "eventID=" .. tostring(eventID),
        "npcID=" .. tostring(npcID),
    })
    return true, sent == true and "presented" or "applied_without_presentation"
end

local function emitForWitness(
    player,
    npcID,
    eventType,
    eventID,
    context,
    position
)
    local actorKey = Hooks.ResolvePlayerKey(player)
    local eventContext = type(context) == "table" and context or {}
    if not actorKey then
        return false, "player_identity_unavailable"
    end
    return emitRelationshipEvent(
        player,
        npcID,
        eventType,
        eventID,
        eventContext,
        position
    )
end

local function sameID(left, right)
    return left ~= nil and right ~= nil
        and tostring(left) == tostring(right)
end

local function factionIDForRecord(record)
    if Factions and Factions.GetFactionID then
        return Factions.GetFactionID(record)
    end
    return record and record.affiliation
        and record.affiliation.factionID or nil
end

local function playerFactionIDFor(player, actorKey)
    local faction
    if Factions and Factions.GetPlayerDiplomacyFaction then
        faction = Factions.GetPlayerDiplomacyFaction(player)
    end
    if not faction and actorKey
        and Factions
        and Factions.GetDiplomacyFactionForPlayerKey
    then
        faction = Factions.GetDiplomacyFactionForPlayerKey(actorKey)
    end
    return faction and faction.id or nil
end

local function factionIDForMember(member)
    return member and member.affiliation
        and member.affiliation.factionID or nil
end

function H.RecordFactionMemberAttack(player, record, hit, actorKey)
    local victimFactionID
    local playerFactionID
    local members
    local memberReason
    local candidates = 0
    local emitted = 0
    local skipped = 0
    local position
    local amount = tonumber(hit and (hit.damage or hit.amount)) or 0
    if not isAuthority() then
        return 0, 0, "not_authority"
    end
    if not player or not record or not record.id then
        return 0, 0, "missing_attacker_or_target"
    end
    actorKey = actorKey or Hooks.ResolvePlayerKey(player)
    if not actorKey then
        return 0, 0, "player_identity_unavailable"
    end
    if amount <= 0 then
        return 0, 0, "invalid_damage"
    end
    victimFactionID = factionIDForRecord(record)
    if not victimFactionID then
        audit({
            "luaSide=server",
            "event=FactionMemberAttack",
            "phase=faction_resolution",
            "result=false",
            "reason=victim_faction_missing",
            "playerKey=" .. tostring(actorKey),
            "victimNPCID=" .. tostring(record.id),
        })
        return 0, 0, "victim_faction_missing"
    end
    playerFactionID = playerFactionIDFor(player, actorKey)
    if not playerFactionID then
        audit({
            "luaSide=server",
            "event=FactionMemberAttack",
            "phase=faction_resolution",
            "result=false",
            "reason=player_faction_missing",
            "playerKey=" .. tostring(actorKey),
            "victimFactionID=" .. tostring(victimFactionID),
            "victimNPCID=" .. tostring(record.id),
        })
        return 0, 0, "player_faction_missing"
    end
    if sameID(playerFactionID, victimFactionID) then
        audit({
            "luaSide=server",
            "event=FactionMemberAttack",
            "phase=faction_resolution",
            "result=false",
            "reason=same_faction",
            "playerKey=" .. tostring(actorKey),
            "playerFactionID=" .. tostring(playerFactionID),
            "victimFactionID=" .. tostring(victimFactionID),
            "victimNPCID=" .. tostring(record.id),
        })
        return 0, 0, "same_faction"
    end
    if not Factions or not Factions.GetMembers then
        audit({
            "luaSide=server",
            "event=FactionMemberAttack",
            "phase=member_scan",
            "result=false",
            "reason=faction_membership_service_unavailable",
            "playerKey=" .. tostring(actorKey),
            "playerFactionID=" .. tostring(playerFactionID),
            "victimFactionID=" .. tostring(victimFactionID),
            "victimNPCID=" .. tostring(record.id),
        })
        return 0, 0, "faction_membership_service_unavailable"
    end
    members, memberReason = Factions.GetMembers(victimFactionID)
    if type(members) ~= "table" then
        audit({
            "luaSide=server",
            "event=FactionMemberAttack",
            "phase=member_scan",
            "result=false",
            "reason=" .. tostring(memberReason or "member_roster_unavailable"),
            "playerKey=" .. tostring(actorKey),
            "playerFactionID=" .. tostring(playerFactionID),
            "victimFactionID=" .. tostring(victimFactionID),
            "victimNPCID=" .. tostring(record.id),
        })
        return 0, 0, memberReason or "member_roster_unavailable"
    end
    position = positionOf(player)
    for _, member in ipairs(members) do
        local npcID = member and member.npcID or nil
        local memberFactionID = factionIDForMember(member)
        local skipReason
        local eventID
        local result
        local reason
        local eventContext
        if not npcID then
            skipReason = "member_id_missing"
        elseif sameID(npcID, record.id) then
            skipReason = "victim_direct_event"
        elseif member.alive == false then
            skipReason = "member_dead"
        elseif sameID(memberFactionID, playerFactionID) then
            skipReason = "player_faction_member"
        elseif not memberFactionID then
            skipReason = "member_faction_missing"
        elseif not sameID(memberFactionID, victimFactionID) then
            skipReason = "member_faction_mismatch"
        else
            candidates = candidates + 1
            eventID = nextEventID(
                "faction_member_attacked",
                actorKey,
                npcID
            )
            eventContext = {
                damage = amount,
                acceptedDamage = amount,
                attackType = hit and hit.attackType or nil,
                attackKind = hit and hit.attackKind or nil,
                killed = record.alive == false,
                source = hit and hit.source or "player_weapon",
                victimNPCID = tostring(record.id),
                victimFactionID = tostring(victimFactionID),
                attackerFactionID = tostring(playerFactionID),
                relationshipScope = "faction_member",
            }
            result, reason = emitRelationshipEvent(
                player,
                npcID,
                "faction_member_attacked",
                eventID,
                eventContext,
                position
            )
            if result then emitted = emitted + 1 end
            audit({
                "luaSide=server",
                "event=FactionMemberAttack",
                "phase=member_dispatch",
                "result=" .. tostring(result == true),
                "reason=" .. tostring(reason or "nil"),
                "playerKey=" .. tostring(actorKey),
                "playerFactionID=" .. tostring(playerFactionID),
                "victimFactionID=" .. tostring(victimFactionID),
                "victimNPCID=" .. tostring(record.id),
                "memberNPCID=" .. tostring(npcID),
                "damage=" .. tostring(amount),
                "eventID=" .. tostring(eventID),
            })
        end
        if skipReason then
            skipped = skipped + 1
            audit({
                "luaSide=server",
                "event=FactionMemberAttack",
                "phase=member_dispatch",
                "result=false",
                "reason=" .. tostring(skipReason),
                "playerKey=" .. tostring(actorKey),
                "playerFactionID=" .. tostring(playerFactionID),
                "victimFactionID=" .. tostring(victimFactionID),
                "victimNPCID=" .. tostring(record.id),
                "memberNPCID=" .. tostring(npcID or "nil"),
            })
        end
    end
    audit({
        "luaSide=server",
        "event=FactionMemberAttackScan",
        "phase=member_scan",
        "result=" .. tostring(emitted > 0),
        "reason=" .. tostring(
            emitted > 0 and "members_notified"
                or "no_member_event_emitted"
        ),
        "playerKey=" .. tostring(actorKey),
        "playerFactionID=" .. tostring(playerFactionID),
        "victimFactionID=" .. tostring(victimFactionID),
        "victimNPCID=" .. tostring(record.id),
        "memberCount=" .. tostring(#members),
        "candidateCount=" .. tostring(candidates),
        "emittedCount=" .. tostring(emitted),
        "skippedCount=" .. tostring(skipped),
        "damage=" .. tostring(amount),
    })
    return emitted, candidates, emitted > 0
        and "members_notified" or "no_member_event_emitted"
end

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

local function copyHurtContext(context, attacker)
    local source = type(context) == "table" and context or {}
    local damage = tonumber(source.damage or source.healthLoss) or 0
    return {
        damage = damage,
        healthLoss = tonumber(source.healthLoss) or damage,
        woundType = source.woundType,
        attackerKind = source.attackerKind or "zombie",
        attackerID = source.attackerID
            or call(attacker, "getOnlineID")
            or "unknown",
        source = source.source or "vanilla_zombie_poll",
    }
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
    local position = positionOf(attacker)
    local safeContext
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

local function partSnapshot(part)
    if not part then return nil end
    return {
        health = tonumber(call(part, "getHealth")) or 100,
        scratchTime = tonumber(call(part, "getScratchTime")) or 0,
        cutTime = tonumber(call(part, "getCutTime")) or 0,
        biteTime = tonumber(call(part, "getBiteTime")) or 0,
        scratched = call(part, "scratched") == true,
        cut = call(part, "isCut") == true,
        bitten = call(part, "bitten") == true,
    }
end

local function playerDamageSnapshot(player)
    local bodyDamage = call(player, "getBodyDamage")
    local parts = bodyDamage and call(bodyDamage, "getBodyParts") or nil
    local count = tonumber(parts and call(parts, "size")) or 0
    local snapshot = {
        overall = tonumber(
            bodyDamage and call(bodyDamage, "getOverallBodyHealth")
        ) or 100,
        hitReaction = tostring(call(player, "getHitReaction") or ""),
        parts = {},
    }
    local index
    for index = 0, count - 1 do
        snapshot.parts[index + 1] = partSnapshot(call(parts, "get", index))
    end
    return snapshot
end

local function woundDelta(previous, current)
    local bestDamage = 0
    local bestType
    local bestPriority = 0
    local index
    local before
    local after
    local healthLoss
    local damageType
    local priority
    if not previous or not current then
        return 0, nil
    end
    for index = 1, #current.parts do
        after = current.parts[index]
        before = previous.parts[index]
        if after and before then
            healthLoss = math.max(
                0,
                (tonumber(before.health) or 100)
                    - (tonumber(after.health) or 100)
            )
            damageType = nil
            priority = 0
            if after.biteTime > before.biteTime + 0.01
                or (after.bitten and not before.bitten)
            then
                damageType = "bite"
                priority = 3
            elseif after.cutTime > before.cutTime + 0.01
                or (after.cut and not before.cut)
            then
                damageType = "laceration"
                priority = 2
            elseif after.scratchTime > before.scratchTime + 0.01
                or (after.scratched and not before.scratched)
            then
                damageType = "scratch"
                priority = 1
            end
            if damageType and (healthLoss > bestDamage
                or priority > bestPriority)
            then
                bestDamage = healthLoss
                bestType = damageType
                bestPriority = priority
            end
        end
    end
    if not bestType then
        if current.hitReaction ~= ""
            and current.hitReaction ~= previous.hitReaction
        then
            bestDamage = math.max(
                0,
                (tonumber(previous.overall) or 100)
                    - (tonumber(current.overall) or 100)
            )
            if bestDamage > 0 then
                return bestDamage, "scratch"
            end
        end
        return 0, nil
    end
    if bestDamage <= 0 then
        bestDamage = bestType == "bite" and 12
            or bestType == "laceration" and 8 or 4
    end
    return bestDamage, bestType
end

local function isPlayer(value)
    return H.IsPlayer and H.IsPlayer(value) == true
end

local function isZombie(value)
    return H.IsZombie and H.IsZombie(value) == true
end

local function onBeingHitByZombie(first, second)
    local player = isPlayer(first) and first
        or isPlayer(second) and second or nil
    local zombie = isZombie(first) and first
        or isZombie(second) and second or nil
    if player and zombie then
        Hooks.VanillaDamageMarkers[player] = {
            zombie = zombie,
            at = nowMillis(),
        }
        audit({
            "luaSide=server",
            "event=OnBeingHitByZombie",
            "phase=engine_callback",
            "result=true",
            "attackerID=" .. tostring(call(zombie, "getOnlineID") or "nil"),
        })
    else
        audit({
            "luaSide=server",
            "event=OnBeingHitByZombie",
            "phase=engine_callback",
            "result=false",
            "reason=unexpected_callback_arguments",
        })
    end
end

local function pollPlayer(player)
    local previous = Hooks.VanillaDamageSnapshots[player]
    local current = playerDamageSnapshot(player)
    local marker = Hooks.VanillaDamageMarkers[player]
    local attacker = call(player, "getAttackedBy")
    local damage
    local woundType
    local emitted
    local candidates
    local reason
    if not previous then
        Hooks.VanillaDamageSnapshots[player] = current
        return
    end
    if not isZombie(attacker)
        and marker
        and nowMillis() - (tonumber(marker.at) or 0)
            <= VANILLA_MARKER_WINDOW_MS
    then
        attacker = marker.zombie
    end
    damage, woundType = woundDelta(previous, current)
    Hooks.VanillaDamageSnapshots[player] = current
    if marker and nowMillis() - (tonumber(marker.at) or 0)
        > VANILLA_MARKER_WINDOW_MS
    then
        Hooks.VanillaDamageMarkers[player] = nil
    end
    if damage <= 0 or not isZombie(attacker) then
        return
    end
    emitted, candidates, reason = H.RecordPlayerHurtWitnesses(
        player,
        attacker,
        {
            damage = damage,
            healthLoss = damage,
            woundType = woundType,
            attackerKind = "zombie",
            attackerID = H.ThreatIDFor and H.ThreatIDFor(attacker) or nil,
            source = "vanilla_zombie_poll",
        }
    )
    audit({
        "luaSide=server",
        "event=VanillaZombieDamage",
        "phase=damage_observed",
        "result=true",
        "attackerID=" .. tostring(
            H.ThreatIDFor and H.ThreatIDFor(attacker) or "unknown"
        ),
        "damage=" .. tostring(damage),
        "woundType=" .. tostring(woundType),
        "witnessCandidates=" .. tostring(candidates),
        "witnessCount=" .. tostring(emitted),
        "reason=" .. tostring(reason),
    })
end

local function onTick()
    local now = nowMillis()
    if now - (tonumber(Hooks.LastVanillaDamagePollAt) or 0)
        < POLL_INTERVAL_MS
    then
        return
    end
    Hooks.LastVanillaDamagePollAt = now
    if Core and Core.ForEachPlayer then
        Core.ForEachPlayer(pollPlayer)
    end
end

if Events and Events.OnBeingHitByZombie
    and Events.OnBeingHitByZombie.Add
    and not Hooks.VanillaDamageCallbackRegistered
then
    Events.OnBeingHitByZombie.Add(onBeingHitByZombie)
    Hooks.VanillaDamageCallbackRegistered = true
    audit({
        "luaSide=server",
        "event=OnBeingHitByZombie",
        "phase=registration",
        "result=true",
    })
elseif not Hooks.VanillaDamageCallbackRegistered then
    audit({
        "luaSide=server",
        "event=OnBeingHitByZombie",
        "phase=registration",
        "result=false",
        "reason=engine_event_unavailable",
    })
end

if Events and Events.OnTick and Events.OnTick.Add
    and not Hooks.VanillaDamagePollRegistered
then
    Events.OnTick.Add(onTick)
    Hooks.VanillaDamagePollRegistered = true
    audit({
        "luaSide=server",
        "event=VanillaZombieDamage",
        "phase=registration",
        "result=true",
        "pollIntervalMs=" .. tostring(POLL_INTERVAL_MS),
    })
elseif not Hooks.VanillaDamagePollRegistered then
    audit({
        "luaSide=server",
        "event=VanillaZombieDamage",
        "phase=registration",
        "result=false",
        "reason=ontick_unavailable",
    })
end

return Hooks
