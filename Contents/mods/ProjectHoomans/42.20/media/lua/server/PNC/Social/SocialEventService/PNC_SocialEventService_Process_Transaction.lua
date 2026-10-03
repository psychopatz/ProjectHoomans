-- Social-event relationship and conduct transaction provider.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEvents = PNC.SocialEvents or {}
local SocialEvents = PNC.SocialEvents
local Internal = SocialEvents.Internal
local Conduct = PNC.Conduct
local ConductDefinitions = PNC.ConductDefinitions
local personalRelationshipCommands =
    Internal.PersonalRelationshipCommands

local function applyTransaction(event, definition, work)
    local index
    local prepared
    local reason
    local applied
    local mutationResult
    local details = {}
    local conductPrepared
    local conductDetails
    local conductDefinition
    local conductRequired
    local conductApplied
    conductDefinition = ConductDefinitions
        and ConductDefinitions[event.type] or nil
    conductRequired = not conductDefinition
        or conductDefinition.required ~= false
    if conductRequired then
        if not conductDefinition or not Conduct
            or not Conduct.PrepareSocialEvent
        then
            return false, "conduct_definition_unavailable", {
                eventID = event.id,
                memoriesCreated = 0,
                relationshipsChanged = 0,
                conductEvidenceCreated = 0,
            }
        end
        conductPrepared, reason = Conduct.PrepareSocialEvent(
            event,
            conductDefinition
        )
        if not conductPrepared then
            return false, reason, {
                eventID = event.id,
                memoriesCreated = 0,
                relationshipsChanged = 0,
                conductEvidenceCreated = 0,
            }
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
            return false, reason, {
                eventID = event.id,
                memoriesCreated = #details,
                relationshipsChanged = #details,
            }
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
            return false, reason, {
                eventID = event.id,
                memoriesCreated = #details,
                relationshipsChanged = #details,
                conductEvidenceCreated = 0,
                transactionInvariantFailed = true,
            }
        end
    end
    return true, nil, {
        details = details,
        conductEvidenceCreated = #(conductDetails or {}),
        conductDetails = conductDetails or {},
    }
end

Internal.ApplyTransaction = applyTransaction

return Internal

