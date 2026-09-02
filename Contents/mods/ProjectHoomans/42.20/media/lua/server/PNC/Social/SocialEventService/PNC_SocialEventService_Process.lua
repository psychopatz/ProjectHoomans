-- Authoritative social-event transaction and downstream bridges.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEvents = PNC.SocialEvents or {}
local SocialEvents = PNC.SocialEvents
local Internal = SocialEvents.Internal
local Conduct = PNC.Conduct
local ConductDefinitions = PNC.ConductDefinitions
local FACTION_INCIDENT_BY_SOCIAL_EVENT =
    Internal.FactionIncidentBySocialEvent
local factionIDForEntityKey = Internal.FactionIDForEntityKey
local result = Internal.Result
local enabled = Internal.Enabled
local isAuthority = Internal.IsAuthority
local observerSpecs = Internal.ObserverSpecs
local preflightObserver = Internal.PreflightObserver
local personalRelationshipCommands =
    Internal.PersonalRelationshipCommands

local function rejected(reason, fields, definition)
    local output = result(false, reason, fields)
    if PNC.SocialEventDebug
        and PNC.SocialEventDebug.LogRejected
    then
        PNC.SocialEventDebug.LogRejected(output, definition)
    end
    return output
end

function SocialEvents.Process(eventSpec)
    local validated
    local event
    local definition
    local observers
    local work = {}
    local skippedDuplicates = 0
    local index
    local observer
    local prepared
    local reason
    local rejectionDetails
    local applied
    local mutationResult
    local details = {}
    local conductPrepared
    local conductDetails
    local conductDefinition
    local conductRequired
    local conductApplied
    if not isAuthority() then
        return rejected("not_authority")
    end
    if not enabled() then
        return rejected("feature_disabled")
    end
    validated = SocialEvents.Validate(eventSpec)
    if not validated.ok then
        return validated
    end
    event = validated.event
    definition = validated.definition
    observers = observerSpecs(event, definition)
    if #observers == 0 then
        return rejected("no_npc_observer", {
            eventID = event.id,
            eventType = event.type,
            actorKey = event.actorKey,
            targetKey = event.targetKey,
        }, definition)
    end
    for index = 1, #observers do
        observer = observers[index]
        prepared, reason, rejectionDetails = preflightObserver(
            event,
            definition,
            observer
        )
        if prepared then
            work[#work + 1] = prepared
        elseif reason == "duplicate_event" then
            skippedDuplicates = skippedDuplicates + 1
        else
            return rejected(reason, {
                eventID = event.id,
                eventType = event.type,
                actorKey = event.actorKey,
                targetKey = event.targetKey,
                observerNPCID = observer.observerNPCID,
                aboutKey = observer.aboutKey,
                rejectionDetails = rejectionDetails,
                memoriesCreated = 0,
                relationshipsChanged = 0,
            }, definition)
        end
    end
    if #work == 0 and skippedDuplicates > 0 then
        return rejected("duplicate_event", {
            eventID = event.id,
            eventType = event.type,
            actorKey = event.actorKey,
            targetKey = event.targetKey,
            memoriesCreated = 0,
            relationshipsChanged = 0,
        }, definition)
    end
    conductDefinition = ConductDefinitions
        and ConductDefinitions[event.type] or nil
    conductRequired = not conductDefinition
        or conductDefinition.required ~= false
    if conductRequired then
        if not conductDefinition or not Conduct
            or not Conduct.PrepareSocialEvent
        then
            return rejected("conduct_definition_unavailable", {
                eventID = event.id,
                memoriesCreated = 0,
                relationshipsChanged = 0,
                conductEvidenceCreated = 0,
            }, definition)
        end
        conductPrepared, reason = Conduct.PrepareSocialEvent(
            event,
            conductDefinition
        )
        if not conductPrepared then
            return rejected(reason, {
                eventID = event.id,
                memoriesCreated = 0,
                relationshipsChanged = 0,
                conductEvidenceCreated = 0,
            }, definition)
        end
    end
    for index = 1, #work do
        prepared = work[index]
        applied, reason, mutationResult =
            personalRelationshipCommands().ApplyEventMutation(
                prepared.observerNPCID,
                prepared.aboutKey,
                prepared.mutation
            )
        if not applied then
            return rejected(reason, {
                eventID = event.id,
                memoriesCreated = #details,
                relationshipsChanged = #details,
            }, definition)
        end
        details[#details + 1] = {
            observerNPCID = prepared.observerNPCID,
            aboutKey = prepared.aboutKey,
            memoryID = mutationResult.memoryID,
            relationshipBefore = prepared.relationshipBefore,
            relationshipAfter = mutationResult.relationship,
            moraleAfter = mutationResult.morale,
            saturationBefore = prepared.saturationBefore,
            saturationAfter = prepared.saturationAfter,
            modifierBreakdown = prepared.modifierBreakdown,
            baseEffects = prepared.baseEffects,
            modifiedEffects = prepared.modifiedEffects,
        }
    end
    if conductRequired then
        conductApplied, reason, conductDetails =
            Conduct.CommitPrepared(conductPrepared)
        if not conductApplied then
            return rejected(reason, {
                eventID = event.id,
                memoriesCreated = #details,
                relationshipsChanged = #details,
                conductEvidenceCreated = 0,
                transactionInvariantFailed = true,
            }, definition)
        end
    end
    local output = result(true, nil, {
        eventID = event.id,
        eventType = event.type,
        actorKey = event.actorKey,
        targetKey = event.targetKey,
        memoriesCreated = #details,
        relationshipsChanged = #details,
        details = details,
        conductEvidenceCreated = #(conductDetails or {}),
        conductDetails = conductDetails or {},
    })
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
            if event.type == "survived_combat_together" then
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

return SocialEvents
