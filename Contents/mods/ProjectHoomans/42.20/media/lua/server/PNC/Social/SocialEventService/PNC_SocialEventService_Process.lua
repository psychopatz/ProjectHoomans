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
        memoriesCreated = #details,
        relationshipsChanged = #details,
        details = details,
        conductEvidenceCreated = transactionDetails.conductEvidenceCreated,
        conductDetails = transactionDetails.conductDetails,
    })
    return Internal.ApplyPostProcess(event, output, definition)
end

return SocialEvents
