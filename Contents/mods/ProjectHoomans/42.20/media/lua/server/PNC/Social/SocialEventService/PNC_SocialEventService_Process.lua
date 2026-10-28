-- Authoritative social-event transaction and downstream bridges.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEvents = PNC.SocialEvents or {}
local SocialEvents = PNC.SocialEvents
local Internal = SocialEvents.Internal
local result = Internal.Result
local enabled = Internal.Enabled
local isAuthority = Internal.IsAuthority
local observerSpecs = Internal.ObserverSpecs
local preflightObserver = Internal.PreflightObserver
local EntityRef = PNC.EntityRef
local InteractionLifecycle = PNC.Semantics
    and PNC.Semantics.InteractionLifecycle or nil
local InteractionPersistence = PNC.Conversation
    and PNC.Conversation.InteractionLifecyclePersistence or nil

require "PNC/Social/SocialEventService/PNC_SocialEventService_Process_Bridges"

require "PNC/Social/SocialEventService/PNC_SocialEventService_Process_Transaction"

local function rejected(reason, fields, definition)
    local output = result(false, reason, fields)
    if PNC.SocialEventDebug
        and PNC.SocialEventDebug.LogRejected
    then
        PNC.SocialEventDebug.LogRejected(output, definition)
    end
    return output
end

local function recordLifecycleEvent(event, output)
    if not InteractionPersistence or type(event) ~= "table"
        or type(output) ~= "table"
    then
        return
    end
    if type(InteractionPersistence.RegisterSharedEvent) == "function" then
        local _, sharedReason = InteractionPersistence.RegisterSharedEvent({
            id = event.id,
            type = event.type,
            occurredAt = event.occurredAt,
            source = event.sourceSystem,
        })
        if sharedReason == "shared_event_budget_exhausted"
            and PNC.Core and type(PNC.Core.LogWarn) == "function"
        then
            PNC.Core.LogWarn(
                "interaction shared event budget exhausted event="
                    .. tostring(event.id)
            )
        end
    end
    if not InteractionLifecycle
        or type(InteractionLifecycle.Envelope) ~= "table"
        or type(InteractionPersistence.Apply) ~= "function"
    then
        return
    end
    local actor = EntityRef and EntityRef.Parse
        and EntityRef.Parse(event.actorKey) or nil
    local directSemanticSpeech = type(event.context) == "table"
        and event.context.semanticPresentation == "semantic_event_speech"
    if not actor or actor.kind ~= "player" then return end
    for _, detail in ipairs(output.details or {}) do
        local envelope = InteractionLifecycle.Envelope.WorldEvent({
            id = event.id,
            type = event.type,
            eventType = event.type,
            occurredAt = event.occurredAt,
            factRefs = detail.memoryID and { detail.memoryID } or nil,
        }, {
            actorID = event.actorKey,
            targetID = detail.observerNPCID,
            playerUUID = event.actorKey,
            topic = event.type,
            worldHour = event.occurredAt,
        })
        local applied, reason = InteractionPersistence.Apply(envelope, {
            meaningful = true,
            eventRef = event.id,
            memory = detail.memoryID,
            worldHour = event.occurredAt,
        })
        local speechEnvelope
        if applied and not directSemanticSpeech
            and type(InteractionPersistence.RecordNPCSpeech)
            == "function"
        then
            local beatID = "beat:" .. tostring(event.type) .. ":"
                .. tostring(event.id)
            speechEnvelope = InteractionLifecycle.Envelope.NPCSpeech({
                npcID = detail.observerNPCID,
                targetID = event.actorKey,
                playerUUID = event.actorKey,
                act = "REACT",
                topic = event.type,
                beatID = beatID,
                responsePlanID = "social.reaction." .. tostring(event.type),
                eventType = event.type,
                eventRef = event.id,
                factRefs = detail.memoryID and { detail.memoryID } or nil,
                worldHour = event.occurredAt,
                meaningful = true,
            })
            local recorded, speechReason = InteractionPersistence.RecordNPCSpeech({
                npcID = detail.observerNPCID,
                targetID = event.actorKey,
                playerUUID = event.actorKey,
                act = "REACT",
                topic = event.type,
                beatID = beatID,
                responsePlanID = "social.reaction." .. tostring(event.type),
                eventType = event.type,
                eventRef = event.id,
                factRefs = detail.memoryID and { detail.memoryID } or nil,
                worldHour = event.occurredAt,
                meaningful = true,
            })
            if not recorded and PNC.Core
                and type(PNC.Core.LogWarn) == "function"
            then
                PNC.Core.LogWarn(
                    "social event speech provenance failed event="
                        .. tostring(event.id) .. " reason="
                        .. tostring(speechReason or "unknown")
                )
            end
        end
        -- Keep the exact grounded provenance beside the observer result so
        -- the existing presentation bridge can carry meaning without ever
        -- reparsing the rendered flavor line.
        -- Direct semantic event producers select and record their exact
        -- realization at the delivery edge.  Do not pre-create a generic
        -- speech beat here: that would make the later producer reuse a
        -- hard-coded plan and would either duplicate selection or hide the
        -- selected ResponsePlan offers.
        detail.interaction = directSemanticSpeech
            and nil or speechEnvelope or envelope
        if not applied and PNC.Core
            and type(PNC.Core.LogWarn) == "function"
        then
            PNC.Core.LogWarn(
                "social event lifecycle apply failed event="
                    .. tostring(event.id)
                    .. " reason=" .. tostring(reason or "unknown")
            )
        end
    end
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
    local transactionOK, transactionReason, transactionDetails =
        Internal.ApplyTransaction(event, definition, work)
    if not transactionOK then
        return rejected(transactionReason, transactionDetails, definition)
    end
    local details = transactionDetails.details
    local output = result(true, nil, {
        eventID = event.id,
        eventType = event.type,
        actorKey = event.actorKey,
        targetKey = event.targetKey,
        memoriesCreated = tonumber(
            transactionDetails.relationshipMemoriesPersisted
        ) or #details,
        relationshipsChanged = #details,
        details = details,
        relationshipMemoryOutcomes =
            transactionDetails.relationshipMemoryOutcomes,
        conductEvidenceCreated = transactionDetails.conductEvidenceCreated,
        conductDetails = transactionDetails.conductDetails,
        conductPersistence = transactionDetails.conductPersistence,
        conductEvidenceOutcome = transactionDetails.conductEvidenceOutcome,
    })
    output = Internal.ApplyPostProcess(event, output, definition)
    recordLifecycleEvent(event, output)
    return output
end

return SocialEvents
