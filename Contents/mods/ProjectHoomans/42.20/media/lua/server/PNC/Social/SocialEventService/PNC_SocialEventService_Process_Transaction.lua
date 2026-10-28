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

local function finalizeConductPersistence(
    rows,
    details,
    required
)
    rows = type(rows) == "table" and rows or {}
    details = type(details) == "table" and details or {}
    if not required then
        return {
            status = "not_required",
            persisted = 0,
            pruned = 0,
            dropped = 0,
            total = 0,
        }, {}
    end

    local persisted = {}
    for _, detail in ipairs(details) do
        persisted[tostring(detail.evidenceID or "")] = true
    end

    local counts = {
        persisted = 0,
        pruned = 0,
        dropped = 0,
        total = #rows,
    }
    for _, row in ipairs(rows) do
        if row.status == "prepared"
            and persisted[tostring(row.evidenceID or "")]
        then
            row.status = "persisted"
            row.reason = "applied"
            row.durable = true
        end
        if row.status == "persisted" then
            counts.persisted = counts.persisted + 1
        elseif row.status == "pruned" then
            counts.pruned = counts.pruned + 1
        elseif row.status == "dropped" then
            counts.dropped = counts.dropped + 1
        end
    end

    if counts.pruned > 0 or counts.dropped > 0 then
        counts.status = "bounded"
    elseif counts.persisted > 0 then
        counts.status = "persisted"
    else
        counts.status = "none"
    end
    return counts, rows
end

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
    local conductPersistence = {}
    local relationshipMemoriesPersisted = 0
    local relationshipMemoryOutcomes = {}
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
        conductPrepared, reason, conductPersistence =
            Conduct.PrepareSocialEvent(
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
        local memoryOutcome = type(mutationResult.relationshipMemoryOutcome)
            == "table" and mutationResult.relationshipMemoryOutcome or {
                status = mutationResult.memoryID and "persisted" or "unknown",
                durable = mutationResult.memoryID ~= nil,
                memoryID = mutationResult.memoryID,
            }
        if memoryOutcome.durable == true
            or memoryOutcome.status == "persisted"
            or memoryOutcome.status == "coalesced"
        then
            relationshipMemoriesPersisted = relationshipMemoriesPersisted + 1
        end
        relationshipMemoryOutcomes[#relationshipMemoryOutcomes + 1] =
            memoryOutcome
        details[#details + 1] = {
            observerNPCID = prepared.observerNPCID,
            aboutKey = prepared.aboutKey,
            memoryID = mutationResult.memoryID,
            proposedMemoryID = mutationResult.proposedMemoryID,
            relationshipMemoryOutcome = memoryOutcome,
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
    local conductOutcome
    conductOutcome, conductPersistence = finalizeConductPersistence(
        conductPersistence,
        conductDetails,
        conductRequired
    )
    return true, nil, {
        details = details,
        relationshipMemoriesPersisted = relationshipMemoriesPersisted,
        relationshipMemoryOutcomes = relationshipMemoryOutcomes,
        conductEvidenceCreated = conductOutcome.persisted,
        conductDetails = conductDetails or {},
        conductPersistence = conductPersistence,
        conductEvidenceOutcome = conductOutcome,
    }
end

Internal.ApplyTransaction = applyTransaction

return Internal

