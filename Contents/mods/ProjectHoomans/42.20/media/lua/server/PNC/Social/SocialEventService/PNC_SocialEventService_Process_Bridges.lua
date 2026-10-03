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
    return output
end

Internal.ApplyPostProcess = applyPostProcess

return Internal

