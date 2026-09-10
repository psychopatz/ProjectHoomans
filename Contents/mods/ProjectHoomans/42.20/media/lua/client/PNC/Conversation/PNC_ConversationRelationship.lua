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

local function copyRecruitmentPreview(value)
    if type(value) ~= "table" then return nil end
    local function copyBreakdown(source)
        if type(source) ~= "table" then return nil end
        local output = {}
        for _, route in ipairs({ "admire", "fear" }) do
            local sourceRoute = source[route]
            if type(sourceRoute) == "table" then
                local routeCopy = {
                    scoreModifier = tonumber(sourceRoute.scoreModifier) or 0,
                    modifiers = {},
                }
                for _, item in ipairs(sourceRoute.modifiers or {}) do
                    if type(item) == "table" then
                        routeCopy.modifiers[#routeCopy.modifiers + 1] = {
                            id = tostring(item.id or ""),
                            label = tostring(item.label or ""),
                            value = tonumber(item.value) or 0,
                        }
                    end
                end
                output[route] = routeCopy
            end
        end
        return output
    end
    local graphContext = type(value.graphContext) == "table"
        and { bonus = tonumber(value.graphContext.bonus) or 0 }
        or nil
    return {
        graphContext = graphContext,
        score = tonumber(value.score) or 0,
        threshold = tonumber(value.threshold) or 0,
        margin = tonumber(value.margin) or 0,
        personalityBreakdown = copyBreakdown(value.personalityBreakdown),
        approvalMinimum = tonumber(value.approvalMinimum),
        respectMinimum = tonumber(value.respectMinimum),
        meetsMinimums = value.meetsMinimums == true,
        normalEligible = value.normalEligible == true,
        fearEligible = value.fearEligible == true,
    }
end

local function sameBreakdown(left, right)
    if type(left) ~= "table" or type(right) ~= "table" then
        return left == right
    end
    for _, route in ipairs({ "admire", "fear" }) do
        local leftRoute = left[route]
        local rightRoute = right[route]
        if type(leftRoute) ~= type(rightRoute) then return false end
        if type(leftRoute) == "table" then
            if (tonumber(leftRoute.scoreModifier) or 0)
                ~= (tonumber(rightRoute.scoreModifier) or 0)
            then
                return false
            end
            local leftModifiers = leftRoute.modifiers or {}
            local rightModifiers = rightRoute.modifiers or {}
            if #leftModifiers ~= #rightModifiers then return false end
            for index = 1, #leftModifiers do
                local leftItem = leftModifiers[index]
                local rightItem = rightModifiers[index]
                if tostring(leftItem.id or "")
                    ~= tostring(rightItem.id or "")
                    or tostring(leftItem.label or "")
                        ~= tostring(rightItem.label or "")
                    or (tonumber(leftItem.value) or 0)
                        ~= (tonumber(rightItem.value) or 0)
                then
                    return false
                end
            end
        end
    end
    return true
end

local function copyDeparturePreview(value)
    if type(value) ~= "table" then return nil end
    local output = {
        version = tonumber(value.version) or 0,
        approvalThreshold = tonumber(value.approvalThreshold) or -60,
        respectThreshold = tonumber(value.respectThreshold) or -60,
        recoveryApprovalThreshold =
            tonumber(value.recoveryApprovalThreshold) or -45,
        recoveryRespectThreshold =
            tonumber(value.recoveryRespectThreshold) or -45,
        bothAxesRequired = value.bothAxesRequired == true,
        confirmationChecks = math.max(
            1, math.floor(tonumber(value.confirmationChecks) or 2)
        ),
        modifiers = {},
    }
    for _, item in ipairs(value.modifiers or {}) do
        if type(item) == "table" then
            output.modifiers[#output.modifiers + 1] = {
                id = tostring(item.id or ""),
                label = tostring(item.label or ""),
                value = tonumber(item.value) or 0,
            }
        end
    end
    return output
end

local function sameDeparturePreview(left, right)
    left = left and left.departurePreview or nil
    right = right and right.departurePreview or nil
    if left == nil or right == nil then return left == right end
    return (tonumber(left.approvalThreshold) or 0)
            == (tonumber(right.approvalThreshold) or 0)
        and (tonumber(left.respectThreshold) or 0)
            == (tonumber(right.respectThreshold) or 0)
        and (tonumber(left.recoveryApprovalThreshold) or 0)
            == (tonumber(right.recoveryApprovalThreshold) or 0)
        and (tonumber(left.recoveryRespectThreshold) or 0)
            == (tonumber(right.recoveryRespectThreshold) or 0)
        and (tonumber(left.confirmationChecks) or 0)
            == (tonumber(right.confirmationChecks) or 0)
        and sameBreakdown(
            { admire = { modifiers = left.modifiers or {} } },
            { admire = { modifiers = right.modifiers or {} } }
        )
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
        interactionRevision = tonumber(summary.interactionRevision) or 0,
        socialRevision = tonumber(summary.socialRevision) or 0,
        identityKey = summary.identityKey,
        relationshipLookup = summary.relationshipLookup,
        recruitmentPreview = copyRecruitmentPreview(
            summary.recruitmentPreview
        ),
        departurePreview = copyDeparturePreview(summary.departurePreview),
    }
end

local function sameRecruitmentPreview(left, right)
    left = left and left.recruitmentPreview or nil
    right = right and right.recruitmentPreview or nil
    if left == nil or right == nil then return left == right end
    local leftContext = left.graphContext or {}
    local rightContext = right.graphContext or {}
    return (tonumber(left.score) or 0) == (tonumber(right.score) or 0)
        and (tonumber(left.threshold) or 0)
            == (tonumber(right.threshold) or 0)
        and (tonumber(left.margin) or 0) == (tonumber(right.margin) or 0)
        and (tonumber(left.approvalMinimum) or 0)
            == (tonumber(right.approvalMinimum) or 0)
        and (tonumber(left.respectMinimum) or 0)
            == (tonumber(right.respectMinimum) or 0)
        and (tonumber(leftContext.bonus) or 0)
            == (tonumber(rightContext.bonus) or 0)
        and sameBreakdown(
            left.personalityBreakdown,
            right.personalityBreakdown
        )
        and left.meetsMinimums == right.meetsMinimums
        and left.normalEligible == right.normalEligible
        and left.fearEligible == right.fearEligible
end

local function samePresentation(left, right)
    if type(left) ~= "table" or type(right) ~= "table" then
        return false
    end
    return (tonumber(left.revision) or 0) == (tonumber(right.revision) or 0)
        and (tonumber(left.approval) or 0) == (tonumber(right.approval) or 0)
        and (tonumber(left.respect) or 0) == (tonumber(right.respect) or 0)
        and (tonumber(left.familiarity) or 0)
            == (tonumber(right.familiarity) or 0)
        and tostring(left.state or "") == tostring(right.state or "")
        and tostring(left.previousState or "")
            == tostring(right.previousState or "")
        and (tonumber(left.interactionRevision) or 0)
            == (tonumber(right.interactionRevision) or 0)
        and (tonumber(left.socialRevision) or 0)
            == (tonumber(right.socialRevision) or 0)
        and sameRecruitmentPreview(left, right)
        and sameDeparturePreview(left, right)
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
    local incomingRevision = tonumber(summary.revision) or 0
    local previousRevision = previous
        and (tonumber(previous.revision) or 0) or nil
    if previousRevision and incomingRevision < previousRevision then
        return true
    end
    if previous and samePresentation(previous, summary) then
        return true
    end
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
    if tostring(requirement or "") == "recruit"
        and type(context) ~= "table"
    then
        local presentation = Relationship.GetPresentation(npcID)
        local preview = presentation
            and presentation.recruitmentPreview or nil
        context = preview and preview.graphContext or {}
    end
    local ok, reason = panel:setRequirement(requirement, context)
    if ok == false then return false, reason end
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
