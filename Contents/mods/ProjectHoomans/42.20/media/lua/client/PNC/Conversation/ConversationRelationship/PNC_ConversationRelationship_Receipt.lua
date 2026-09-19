-- Admit relationship snapshots and route their client-side effects.
local Relationship = PNC.Conversation.Relationship
local Snapshot = require "PNC/Conversation/ConversationRelationship/PNC_ConversationRelationship_Snapshot"
local presentationCache = Relationship.presentationCache or {}
Relationship.presentationCache = presentationCache
local conversationRefreshHandler

function Relationship.SetConversationRefreshHandler(handler)
    if handler ~= nil and type(handler) ~= "function" then
        return false, "invalid_refresh_handler"
    end
    conversationRefreshHandler = handler
    return true
end

function Relationship.ReceivePresentation(summary, delta, metadata)
    if type(summary) ~= "table" or not summary.npcID then return false end
    local npcID = tostring(summary.npcID)
    local diary = PNC.Conversation and PNC.Conversation.Diary or nil
    if diary and diary.Hydrate
        and type(summary.interactionJournal) == "table"
    then
        diary.Hydrate(
            npcID,
            summary.interactionJournal,
            summary.interactionRevision
        )
    end
    local previous = presentationCache[npcID]
    local settlementVisitChanged = not Snapshot.SameSettlementVisit(
        previous,
        summary
    )
    local ambientVisitChanged = not Snapshot.SameAmbientVisitPreview(
        previous,
        summary
    )
    local incomingRevision = tonumber(summary.revision) or 0
    local previousRevision = previous
        and (tonumber(previous.revision) or 0) or nil
    if previousRevision and incomingRevision < previousRevision then
        return true
    end
    if previous and Snapshot.Same(previous, summary) then
        return true
    end
    presentationCache[npcID] = Snapshot.Copy(summary)
    local feedback = PNC.NameplateRelationshipFeedback
    if feedback and feedback.Observe then
        metadata = type(metadata) == "table" and metadata or {}
        if metadata.source == nil then
            metadata.source = "relationship_presentation"
        end
        feedback.Observe(npcID, previous, summary, delta, metadata)
    end
    local state = PNC.Network and PNC.Network.ClientState or nil
    if state then
        state.conversationRelationships = state.conversationRelationships or {}
        state.conversationRelationships[npcID] = summary
        state.conversationRelationshipDiagnostics =
            state.conversationRelationshipDiagnostics or {}
        state.conversationRelationshipDiagnostics[npcID] = {
            identityKey = summary.identityKey,
            relationshipLookup = summary.relationshipLookup,
            socialRevision = summary.socialRevision,
            relationshipRevision = summary.revision,
            interactionRevision = summary.interactionRevision,
            identityDiagnostics = summary.identityDiagnostics,
            receivedAt = PNC.Core and PNC.Core.Now
                and PNC.Core.Now() or 0,
        }
        state.lastConversationRelationshipReceiveAt = PNC.Core
            and PNC.Core.Now and PNC.Core.Now() or 0
        if state.relationshipDebug
            and state.relationshipDebug.observer
            and tostring(state.relationshipDebug.observer.npcID
                or state.relationshipDebug.observer.id or "") == npcID
            and state.relationshipDebug.target
            and state.relationshipDebug.target.kind == "player"
        then
            state.relationshipDebug.relationship = summary
            state.relationshipDebug.generatedAt = state.lastConversationRelationshipReceiveAt
            state.lastRelationshipDebugReceiveAt = state.lastConversationRelationshipReceiveAt
        end
    end
    local view = PsychopatzCore
        and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
    if view and view.spec
        and tostring(view.spec.npcID or "") == npcID
    then
        local refreshed = false
        if (settlementVisitChanged or ambientVisitChanged)
            and conversationRefreshHandler
        then
            refreshed = conversationRefreshHandler(npcID, summary) == true
        end
        if not refreshed and view.extensionParts
            and view.extensionParts.relationship
            and view.extensionParts.relationship.setRelationship
        then
            view.extensionParts.relationship:setRelationship(summary)
        end
    end
    return true
end

function Relationship.ReceiveAfter(npcID, after, delta, metadata)
    if type(after) ~= "table" then return false end
    local previous = Relationship.GetPresentation(npcID)
    return Relationship.ReceivePresentation({
        npcID = npcID,
        exists = true,
        approval = after.approval,
        respect = after.respect,
        familiarity = after.familiarity,
        state = after.state,
        previousState = after.previousState,
        revision = after.revision,
        interactionRevision = after.interactionRevision,
        interactionJournal = after.interactionJournal,
        identityKey = after.identityKey,
        relationshipLookup = after.relationshipLookup,
        socialRevision = after.socialRevision,
        identityDiagnostics = after.identityDiagnostics,
        recruitmentPreview = after.recruitmentPreview
            or previous and previous.recruitmentPreview,
        departurePreview = after.departurePreview
            or previous and previous.departurePreview,
        ambientVisitPreview = after.ambientVisitPreview
            or previous and previous.ambientVisitPreview,
    }, delta, metadata)
end

function Relationship.ResetPresentationCache()
    for npcID, _ in pairs(presentationCache) do
        presentationCache[npcID] = nil
    end
    local feedback = PNC.NameplateRelationshipFeedback
    if feedback and feedback.Reset then feedback.Reset() end
end

function Relationship.ReceiveDebugSnapshot(snapshot)
    local observer = snapshot and snapshot.observer or nil
    local target = snapshot and snapshot.target or nil
    local relationship = snapshot and snapshot.relationship or nil
    if not observer or not relationship
        or not target or target.kind ~= "player"
    then
        return false
    end
    local summary = PNC.RelationshipPresentation.Summarize(
        relationship,
        relationship.exists == true
    )
    summary.npcID = tostring(observer.npcID or "")
    if summary.npcID == "" then return false end
    local state = PNC.Network and PNC.Network.ClientState or nil
    if state then
        state.conversationRelationships =
            state.conversationRelationships or {}
        state.conversationRelationships[summary.npcID] = summary
    end
    return Relationship.ReceivePresentation(summary)
end

function Relationship.RequestPresentation(npcID)
    if PNC.Client and PNC.Client.RequestConversationRelationship then
        return PNC.Client.RequestConversationRelationship(npcID)
    end
    return false, "presentation_unavailable"
end

