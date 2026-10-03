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


return H
