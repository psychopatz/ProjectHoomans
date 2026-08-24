if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Factions = PNC.Factions
local Internal = Factions.Internal
local Core = PNC.Core
local EntityRef = PNC.EntityRef
function Factions.OnNPCAggression(
    attackerRecord,
    targetRecord,
    worldAgeHours,
    context
)
    local attackerFactionID =
        Factions.GetOrganizationalFactionID(attackerRecord)
    local targetFactionID =
        Factions.GetOrganizationalFactionID(targetRecord)
    context = type(context) == "table" and context or {}
    Internal.traceFactionCallback("callback", {
        operation = context.callback or "npc_aggression",
        worldAgeHours = worldAgeHours,
        actorKey = attackerRecord and attackerRecord.id
            and EntityRef.ForNPC(attackerRecord.id) or nil,
        subjectKey = targetRecord and targetRecord.id
            and EntityRef.ForNPC(targetRecord.id) or nil,
        sourceFactionID = attackerFactionID,
        targetFactionID = targetFactionID,
        result = "received",
        damage = context.damage,
        severe = context.severe,
        killed = context.killed,
    })
    if not attackerFactionID or not targetFactionID then
        Internal.traceFactionCallback("attribution", {
            operation = "resolve_npc_attack",
            worldAgeHours = worldAgeHours,
            actorKey = attackerRecord and attackerRecord.id
                and EntityRef.ForNPC(attackerRecord.id) or nil,
            subjectKey = targetRecord and targetRecord.id
                and EntityRef.ForNPC(targetRecord.id) or nil,
            sourceFactionID = attackerFactionID,
            targetFactionID = targetFactionID,
            result = "rejected",
            reason = not attackerFactionID
                and "actor_faction_missing"
                or "victim_faction_missing",
        })
        return false, "unaffiliated"
    end
    if attackerFactionID == targetFactionID then
        Internal.traceFactionCallback("attribution", {
            operation = "resolve_npc_attack",
            worldAgeHours = worldAgeHours,
            sourceFactionID = attackerFactionID,
            targetFactionID = targetFactionID,
            result = "rejected",
            reason = "same_faction",
        })
        return false, "same_faction"
    end
    if not PNC.FactionIncidentService then
        return false, "incident_service_unavailable"
    end
    Internal.traceFactionCallback("attribution", {
        operation = "resolve_npc_attack",
        worldAgeHours = worldAgeHours,
        actorKey = EntityRef.ForNPC(attackerRecord.id),
        subjectKey = EntityRef.ForNPC(targetRecord.id),
        sourceFactionID = attackerFactionID,
        targetFactionID = targetFactionID,
        result = "accepted",
        reason = "accepted_cross_faction_attack",
    })
    return PNC.FactionIncidentService.RecordAttack(
        attackerFactionID,
        targetFactionID,
        {
            worldAgeHours = worldAgeHours,
            actorKey = EntityRef.ForNPC(attackerRecord.id),
            subjectKey = EntityRef.ForNPC(targetRecord.id),
            targetRecord = targetRecord,
            callbackID = context.callbackID,
            severe = context.severe,
            killed = context.killed,
            damage = context.damage,
            intentionality = context.intentionality,
        }
    )
end

function Factions.OnNPCAttackPlayer(
    attackerRecord,
    player,
    worldAgeHours,
    context
)
    local attackerFactionID =
        Factions.GetOrganizationalFactionID(attackerRecord)
    local playerFaction
    context = type(context) == "table" and context or {}
    Internal.traceFactionCallback("callback", {
        operation = context.callback or "npc_attack_player",
        worldAgeHours = worldAgeHours,
        actorKey = attackerRecord and attackerRecord.id
            and EntityRef.ForNPC(attackerRecord.id) or nil,
        sourceFactionID = attackerFactionID,
        result = "received",
        damage = context.damage,
        severe = context.severe,
        killed = context.killed,
    })
    if not attackerFactionID then
        Internal.traceFactionCallback("attribution", {
            operation = "resolve_npc_attack_player",
            worldAgeHours = worldAgeHours,
            result = "rejected",
            reason = "actor_faction_missing",
        })
        return false, "attacker_unaffiliated"
    end
    playerFaction = Internal.factionForPlayer(
        player,
        true,
        worldAgeHours
    )
    if not playerFaction
        or playerFaction.id == attackerFactionID
    then
        Internal.traceFactionCallback("attribution", {
            operation = "resolve_npc_attack_player",
            worldAgeHours = worldAgeHours,
            actorKey = EntityRef.ForNPC(attackerRecord.id),
            subjectKey = playerFaction
                and playerFaction.ownerPlayerKey or nil,
            sourceFactionID = attackerFactionID,
            targetFactionID = playerFaction
                and playerFaction.id or nil,
            result = "rejected",
            reason = not playerFaction
                and "victim_faction_missing"
                or "same_faction",
        })
        return false, "same_or_missing_faction"
    end
    if not PNC.FactionIncidentService then
        return false, "incident_service_unavailable"
    end
    Internal.traceFactionCallback("attribution", {
        operation = "resolve_npc_attack_player",
        worldAgeHours = worldAgeHours,
        actorKey = EntityRef.ForNPC(attackerRecord.id),
        subjectKey = playerFaction.ownerPlayerKey,
        sourceFactionID = attackerFactionID,
        targetFactionID = playerFaction.id,
        result = "accepted",
        reason = "accepted_cross_faction_attack",
    })
    return PNC.FactionIncidentService.RecordAttack(
        attackerFactionID,
        playerFaction.id,
        {
            worldAgeHours = worldAgeHours,
            actorKey = EntityRef.ForNPC(attackerRecord.id),
            subjectKey = playerFaction.ownerPlayerKey,
            callbackID = context.callbackID,
            severe = context.severe,
            killed = context.killed,
            damage = context.damage,
            intentionality = context.intentionality,
        }
    )
end

function Factions.CanNPCTargetPlayer(record, player)
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ResolveIntent
    then
        local result = PNC.FactionBehavior.ResolveIntent(
            record,
            player,
            {}
        )
        return result and result.attackAllowed == true
    end
    return record and record.hostility
        and record.hostility.attackPlayers == true
end

function Factions.OnRelationshipChanged(
    observerRecord,
    targetKey,
    relationship
)
    local observerFactionID =
        Factions.GetOrganizationalFactionID(observerRecord)
    local targetFaction
    local parsed
    local livePlayer
    if not observerFactionID
        or not relationship
        or relationship.state ~= "enemy"
        or not EntityRef.IsPlayer(targetKey)
    then
        return false, "not_faction_enemy"
    end
    targetFaction =
        Factions.GetDiplomacyFactionForPlayerKey(targetKey)
    if not targetFaction then
        parsed = EntityRef.Parse(targetKey)
        livePlayer = parsed
            and PNC.PlayerCharacters
            and PNC.PlayerCharacters.RuntimeByUUID
            and PNC.PlayerCharacters.RuntimeByUUID[
                parsed.characterUUID
            ] or nil
        targetFaction = livePlayer
            and Internal.factionForPlayer(
                livePlayer,
                true,
                relationship.lastEvaluatedAt
            ) or nil
    end
    if not targetFaction
        or targetFaction.id == observerFactionID
    then
        return false, "target_faction_unavailable"
    end
    local rank = observerRecord.affiliation
        and observerRecord.affiliation.rank or "member"
    if rank ~= "leader" and rank ~= "second"
        and rank ~= "officer"
    then
        return false, "insufficient_faction_authority"
    end
    if not PNC.FactionIncidentService then
        return false, "incident_service_unavailable"
    end
    local ok, reason = PNC.FactionIncidentService.AddIncident(
        targetFaction.id,
        observerFactionID,
        "personal_grievance_report",
        {
            worldAgeHours = relationship.lastEvaluatedAt,
            actorKey = targetKey,
            subjectKey = EntityRef.ForNPC(observerRecord.id),
            relationSourceFactionID = observerFactionID,
            relationTargetFactionID = targetFaction.id,
            authorityRank = rank,
            externalID = "relationship:"
                .. observerRecord.id .. ":"
                .. targetKey .. ":"
                .. tostring(relationship.revision or 0),
        }
    )
    if ok and PNC.Config and PNC.Config.Factions
        and PNC.Config.Factions
            .EnemyRelationshipCanImmediatelyDeclareWar == true
    then
        return Factions.DeclareWar(
            observerFactionID,
            targetFaction.id,
            {
                worldAgeHours =
                    relationship.lastEvaluatedAt,
                reason = "scripted",
                instigatorFactionID = observerFactionID,
            }
        )
    end
    return ok, reason
end

return Factions
