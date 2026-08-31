-- Build 42.20 relationship resolver for conversations.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Relationship = PNC.Conversation.Relationship or {}
PNC.Conversation.Relationship = Relationship
local presentationCache = Relationship.presentationCache or {}
Relationship.presentationCache = presentationCache

Relationship.categories = {
    FirstMeet = true,
    Acquaintance = true,
    Member = true,
    Lover = true,
}

-- Kept on during development. Gameplay can disable this before opening a
-- conversation, then reveal it in a dialogue branch such as "What do you
-- think of me?" without changing the relationship data flow.
Relationship.presentationVisible = Relationship.presentationVisible ~= false

local aliases = {
    firstmeet = "FirstMeet",
    first_meet = "FirstMeet",
    stranger = "FirstMeet",
    acquaintance = "Acquaintance",
    acuaintance = "Acquaintance",
    known = "Acquaintance",
    friend = "Acquaintance",
    member = "Member",
    companion = "Member",
    factionmember = "Member",
    faction_member = "Member",
    lover = "Lover",
    partner = "Lover",
    spouse = "Lover",
}

function Relationship.Normalize(value)
    if Relationship.categories[tostring(value or "")] then
        return tostring(value)
    end
    local normalized = string.lower(tostring(value or ""))
    normalized = string.gsub(normalized, "[%s%-]", "_")
    return aliases[normalized] or "FirstMeet"
end

local function playerKey(player)
    if player and player.getUsername then
        return tostring(player:getUsername())
    end
    if player and player.getOnlineID then
        return tostring(player:getOnlineID())
    end
    return nil
end

function Relationship.Resolve(entry, player)
    local snapshot = entry and entry.snapshot or {}
    local record = entry and entry.record or {}
    local relation = entry and entry.relationship
        or snapshot.relationship
        or record.relationship
        or {}
    local value = entry and (
            entry.conversationRelationship
            or entry.relationshipCategory
        )
        or snapshot.conversationRelationship
        or snapshot.relationshipCategory
        or record.conversationRelationship
        or record.relationshipCategory
        or relation.category
        or relation.status
    local verifier = PNC.Identity and PNC.Identity.Verifier or nil
    local ownership = verifier
        and verifier.BuildOwnershipSummary
        and verifier.BuildOwnershipSummary(entry)
        or nil
    local recruited = ownership
        and (ownership.recruited or ownership.colonyOwned)
        or snapshot.recruited == true
        or record.recruited == true
        or snapshot.ownerUsername
        or record.ownerUsername
    if value ~= nil then
        local normalized = Relationship.Normalize(value)
        -- A stale relationship presentation must not turn an already-owned
        -- NPC back into a recruit candidate. Lovers retain their special
        -- relationship category, while all other owned NPCs are Members.
        return recruited and normalized ~= "Lover"
            and "Member" or normalized
    end
    if recruited then
        return "Member"
    end
    local presentation = snapshot.mapPresentation
        or record.mapPresentation
        or {}
    local knownBy = presentation.knownBy or {}
    local key = playerKey(player)
    if key and knownBy[key] == true then return "Acquaintance" end
    return Relationship.Normalize(value)
end

function Relationship.GetPresentation(npcID)
    local state = PNC.Network and PNC.Network.ClientState or {}
    return state.conversationRelationships
        and state.conversationRelationships[tostring(npcID or "")]
        or nil
end

local function copyPresentation(summary)
    return {
        npcID = tostring(summary.npcID or ""),
        exists = summary.exists == true,
        approval = tonumber(summary.approval) or 0,
        respect = tonumber(summary.respect) or 0,
        familiarity = tonumber(summary.familiarity) or 0,
        state = summary.state,
        previousState = summary.previousState,
        revision = tonumber(summary.revision) or 0,
    }
end

function Relationship.ReceivePresentation(summary, delta, metadata)
    if type(summary) ~= "table" or not summary.npcID then return false end
    local npcID = tostring(summary.npcID)
    local previous = presentationCache[npcID]
    presentationCache[npcID] = copyPresentation(summary)
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
    end
    local view = PsychopatzCore
        and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
    if view and view.spec
        and tostring(view.spec.npcID or "") == npcID
        and view.extensionParts
        and view.extensionParts.relationship
        and view.extensionParts.relationship.setRelationship
    then
        view.extensionParts.relationship:setRelationship(summary)
    end
    return true
end

function Relationship.ReceiveAfter(npcID, after, delta, metadata)
    if type(after) ~= "table" then return false end
    return Relationship.ReceivePresentation({
        npcID = npcID,
        exists = true,
        approval = after.approval,
        respect = after.respect,
        familiarity = after.familiarity,
        state = after.state,
        previousState = after.previousState,
        revision = after.revision,
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

function Relationship.SetPreviewRequirement(npcID, requirement, context)
    local view = PsychopatzCore
        and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
    if not view or not view.spec
        or tostring(view.spec.npcID or "") ~= tostring(npcID or "")
    then
        return false, "conversation_unavailable"
    end
    local panel = view.extensionParts
        and view.extensionParts.relationship or nil
    if not panel or not panel.setRequirement then
        return false, "relationship_panel_unavailable"
    end
    panel:setRequirement(requirement, context)
    return true
end

function Relationship.ClearPreviewRequirement(npcID)
    return Relationship.SetPreviewRequirement(npcID, "inspect")
end

function Relationship.IsPresentationVisible()
    return Relationship.presentationVisible ~= false
end

function Relationship.SetPresentationVisible(visible)
    Relationship.presentationVisible = visible == true
    local view = PsychopatzCore
        and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
    local panel = view and view.extensionParts
        and view.extensionParts.relationship or nil
    if panel and panel.setVisible then
        panel:setVisible(Relationship.IsPresentationVisible())
    end
end

function Relationship.ApplyDebugStanding(npcID, standingID)
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
        or not PNC.Client.SendDebug
    then
        return false, "not_authorized"
    end
    return PNC.Client.SendDebug("relationship_debug_baseline", {
        observerNPCID = tostring(npcID or ""),
        targetKind = "current_player",
        standingID = tostring(standingID or ""),
    })
end

function Relationship.TriggerDebugEvent(npcID, eventType)
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
        or not PNC.Client.SendDebug
    then
        return false, "not_authorized"
    end
    return PNC.Client.SendDebug("social_trigger_event", {
        observerNPCID = tostring(npcID or ""),
        targetKind = "current_player",
        eventType = tostring(eventType or ""),
    })
end

function Relationship.OpenLaboratory(npcID)
    if PNC.RelationshipDebugUI and PNC.RelationshipDebugUI.Open then
        return PNC.RelationshipDebugUI.Open(npcID)
    end
    return nil
end

function Relationship.OpenDossier(npcID)
    if PNC.NPCDossierUI and PNC.NPCDossierUI.Open then
        return PNC.NPCDossierUI.Open(npcID)
    end
    return nil
end

return Relationship
