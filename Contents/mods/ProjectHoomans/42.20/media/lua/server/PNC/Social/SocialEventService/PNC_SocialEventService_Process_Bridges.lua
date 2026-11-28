-- Social-event downstream bridge provider.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEvents = PNC.SocialEvents or {}
local SocialEvents = PNC.SocialEvents
local Internal = SocialEvents.Internal
local FACTION_INCIDENT_BY_SOCIAL_EVENT =
    Internal.FactionIncidentBySocialEvent
local factionIDForEntityKey = Internal.FactionIDForEntityKey

local NPC_KNOWLEDGE_SHARE_EVENTS = {
    survived_combat_together = true,
    survived_horde_attack = true,
    treated_wound = true,
    saved_from_incapacitation = true,
    protected_from_attacker = true,
    friendship_established = true,
    shared_meal = true,
    conversation = true,
    friendly_conversation = true,
    chatted = true,
    socialized = true,
}

local function npcIDFromEntityKey(entityKey)
    local EntityRef = PNC.EntityRef
    if not EntityRef or type(EntityRef.IsNPC) ~= "function"
        or not EntityRef.IsNPC(entityKey)
    then
        return nil
    end
    if type(EntityRef.ExtractID) == "function" then
        return EntityRef.ExtractID(entityKey)
    end
    return string.match(tostring(entityKey or ""), "^npc:(.+)$")
end

local function isHostileNPCPair(actorRecord, targetKey)
    local rels = actorRecord and actorRecord.social
        and actorRecord.social.relationships or nil
    local rel = type(rels) == "table" and rels[targetKey] or nil
    local state = type(rel) == "table" and tostring(rel.state or "") or ""
    return state == "enemy" or state == "rival"
end

-- Lightweight mutual NPC-to-NPC world-knowledge exchange on cooperative
-- interactions. Bounded to 2 facts per pair with a 24h runtime cooldown
-- (cooldowns stay in memory, never persisted to ModData).
local function propagateNPCWorldKnowledge(event)
    if not NPC_KNOWLEDGE_SHARE_EVENTS[event.type] then return end
    local worldKnowledge = PNC.WorldKnowledge
    if not worldKnowledge
        or type(worldKnowledge.PropagateConversation) ~= "function"
        or not PNC.Registry or type(PNC.Registry.Get) ~= "function"
    then
        return
    end
    local actorID = npcIDFromEntityKey(event.actorKey)
    local targetID = npcIDFromEntityKey(event.targetKey)
    if not actorID or not targetID or actorID == targetID then return end
    local actorRecord = PNC.Registry.Get(actorID)
    local targetRecord = PNC.Registry.Get(targetID)
    if not actorRecord or not targetRecord
        or actorRecord.alive == false or targetRecord.alive == false
    then
        return
    end
    if isHostileNPCPair(actorRecord, event.targetKey)
        or isHostileNPCPair(targetRecord, event.actorKey)
    then
        return
    end
    local opts = {
        authorized = true,
        channel = "conversation",
        max = 2,
        cooldown = 24,
        now = event.occurredAt,
        source = "npc_social:" .. tostring(event.type),
    }
    worldKnowledge.PropagateConversation(actorRecord, targetRecord, opts)
    worldKnowledge.PropagateConversation(targetRecord, actorRecord, opts)
end

local function applyPostProcess(event, output, definition)
    local factionIncidentType =
        FACTION_INCIDENT_BY_SOCIAL_EVENT[event.type]
    if factionIncidentType and PNC.FactionIncidentService then
        local actorFactionID =
            factionIDForEntityKey(event.actorKey)
        local targetFactionID =
            factionIDForEntityKey(event.targetKey)
        if PNC.FactionTelemetry then
            PNC.FactionTelemetry.RecordCallback({
                operation = "social_event_faction_bridge",
                worldAgeHours = event.occurredAt,
                actorKey = event.actorKey,
                subjectKey = event.targetKey,
                sourceFactionID = actorFactionID,
                targetFactionID = targetFactionID,
                result = actorFactionID and targetFactionID
                    and actorFactionID ~= targetFactionID
                    and "accepted" or "rejected",
                reason = not actorFactionID
                    and "actor_faction_missing"
                    or not targetFactionID
                        and "victim_faction_missing"
                    or actorFactionID == targetFactionID
                        and "same_faction"
                    or factionIncidentType,
            })
        end
        if actorFactionID and targetFactionID
            and actorFactionID ~= targetFactionID
        then
            local incidentOK, incidentReason, incidentDetails =
                PNC.FactionIncidentService.RecordPositiveEvent(
                    actorFactionID,
                    targetFactionID,
                    factionIncidentType,
                    {
                        worldAgeHours = event.occurredAt,
                        actorKey = event.actorKey,
                        subjectKey = event.targetKey,
                        externalID = "social-faction:"
                            .. event.id,
                        public = true,
                        witnessed = true,
                    }
                )
            output.factionIncident = {
                ok = incidentOK,
                reason = incidentReason,
                details = incidentDetails,
            }
            if event.type == "survived_combat_together"
                or event.type == "survived_horde_attack"
            then
                PNC.FactionIncidentService.RecordPositiveEvent(
                    targetFactionID,
                    actorFactionID,
                    factionIncidentType,
                    {
                        worldAgeHours = event.occurredAt,
                        actorKey = event.targetKey,
                        subjectKey = event.actorKey,
                        externalID = "social-faction-reciprocal:"
                            .. event.id,
                        public = true,
                        witnessed = true,
                    }
                )
            end
        end
    end
    if PNC.SocialEventDebug and PNC.SocialEventDebug.LogProcessed then
        PNC.SocialEventDebug.LogProcessed(output, definition)
    end
    if PNC.KnowledgeSocialEventAdapter
        and PNC.KnowledgeSocialEventAdapter.Record
    then
        output.knowledgeEvidenceCreated =
            PNC.KnowledgeSocialEventAdapter.Record(event)
    end
    pcall(propagateNPCWorldKnowledge, event)
    return output
end

Internal.ApplyPostProcess = applyPostProcess

return Internal

