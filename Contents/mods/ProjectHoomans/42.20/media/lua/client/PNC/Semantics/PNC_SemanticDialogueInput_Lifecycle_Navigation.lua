-- Internal implementation spoke for semantic dialogue input lifecycle.
-- The public entry point remains PNC_SemanticDialogueInput_Lifecycle.lua.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Input = PNC.Semantics.DialogueInput
local Internal = Input.Internal

local CampSiteHints = Internal.CampSiteHints
local LocationObservation = Internal.LocationObservation
local DialogueInputTrace = Internal.DialogueInputTrace
local audit = Internal.audit
local traceTurn = Internal.traceTurn
local Suggestions = Internal.Suggestions
local InteractionLifecycle = Internal.InteractionLifecycle

local buildCoreChoices = Internal.buildCoreChoices
local presentSemanticChoices = Internal.presentSemanticChoices
local applyCoreChoices = Internal.applyCoreChoices
local suggestionText = Internal.suggestionText
local suggestionTooltip = Internal.suggestionTooltip
local restoreSemanticChoices = Internal.restoreSemanticChoices
local recordSemanticChoiceClick = Internal.recordSemanticChoiceClick

function Internal.RefreshSuggestions(view, result)
    if not view or type(result) ~= "table"
        or type(Suggestions.Build) ~= "function"
    then
        return nil
    end
    local semanticContext = type(Internal.ShallowContext) == "function"
        and Internal.ShallowContext(view) or {}
    local existingGroupID = view.semanticSuggestions
        and view.semanticSuggestions.currentGroupID or nil
    local preservedGroupID = existingGroupID
        and existingGroupID ~= Suggestions.ROOT_GROUP_ID
        and existingGroupID or nil
    semanticContext.activeSuggestionGroupID = preservedGroupID
        or view.session and view.session.semanticSuggestionGroupID
        or semanticContext.semanticSuggestionGroupID
        or view.semanticSuggestionGroupID
    if preservedGroupID and view.spec and view.spec.context then
        view.spec.context.semanticSuggestionGroupID = preservedGroupID
    end
    local campSiteCandidates = result.campSiteCandidates
        or (result.npcState and result.npcState.campSiteCandidates)
        or semanticContext.campSiteCandidates
    if LocationObservation
        and type(LocationObservation.Observe) == "function"
    then
        local locationObservation = LocationObservation.Observe({
            locationObservation = result.locationObservation
                or semanticContext.locationObservation,
            player = result.player or semanticContext.player,
            origin = result.selectionOrigin or semanticContext.selectionOrigin,
            selectionOrigin = result.selectionOrigin
                or semanticContext.selectionOrigin,
            cell = result.cell or semanticContext.cell,
            campSiteCandidates = campSiteCandidates,
            campfireCandidates = result.campfireCandidates
                or semanticContext.campfireCandidates,
        }, { maxCampSites = 8 })
        if type(locationObservation) == "table" then
            semanticContext.locationObservation = locationObservation
            local discovered = locationObservation.campSiteCandidates
            if type(discovered) == "table" and #discovered > 0 then
                campSiteCandidates = discovered
            end
        end
    end
    semanticContext.campSiteCandidates = campSiteCandidates
    if type(Internal.AttachSemanticHubPresentation) == "function" then
        semanticContext = Internal.AttachSemanticHubPresentation(
            semanticContext, view
        )
    end
    local projection = Suggestions.Build(result, semanticContext, nil)
    view.semanticSuggestions = projection
    view.semanticSuggestionRevision = projection
        and projection.revision or nil
    applyCoreChoices(view, projection)
    return projection
end

-- Rebuild the semantic surface from the current production root node without
-- inventing a turn or advancing router state. This is used when a Core choice
-- transition returns to the menu and on the initial root presentation.
function Internal.RefreshRootSuggestions(view)
    if not view or type(Suggestions.Build) ~= "function"
        or type(Internal.ShallowContext) ~= "function"
    then
        return nil
    end
    if view.closed == true or view.closing == true
        or view.lifecycleFinished == true
        or view.session and view.session.closed == true
    then
        view.semanticSuggestions = nil
        return nil
    end
    local context = Internal.ShallowContext(view)
    if LocationObservation
        and type(LocationObservation.Observe) == "function"
    then
        local observation = LocationObservation.Observe(context, {
            maxCampSites = 8,
        })
        if type(observation) == "table" then
            context.locationObservation = observation
            if type(observation.campSiteCandidates) == "table"
                and #observation.campSiteCandidates > 0
            then
                context.campSiteCandidates = observation.campSiteCandidates
            end
        end
    end
    if type(context.conversationRoot) ~= "table" then return nil end
    if view.semanticSuggestionGroupID == nil
        and view.session and view.session.semanticSuggestionGroupID == nil
    then
        view.semanticSuggestionGroupID = Suggestions.ROOT_GROUP_ID
    end
    view.semanticSuggestionGroupID = view.session
        and view.session.semanticSuggestionGroupID
        or view.semanticSuggestionGroupID
    context.activeSuggestionGroupID = view.semanticSuggestionGroupID
    context.semanticSuggestionGroupID = view.semanticSuggestionGroupID
    if type(Internal.AttachSemanticHubPresentation) == "function" then
        context = Internal.AttachSemanticHubPresentation(context, view)
    end
    if view.spec and view.spec.context then
        view.spec.context.semanticSuggestionGroupID =
            view.semanticSuggestionGroupID
    end
    if view.session then
        view.session.semanticSuggestionGroupID = view.semanticSuggestionGroupID
    end
    -- Do not create the semantic router merely to paint the initial menu.
    -- RouterFor owns turn state initialization, and doing that here changes
    -- the authoritative contextBefore snapshot before the first input. Reuse
    -- an existing router when a prior turn already created one; otherwise the
    -- initial root revision is the canonical zero revision.
    local router = view.session and view.session.semanticDialogueRouter
    local revision = router and router.state
        and tonumber(router.state.sequence) or 0
    local projection = Suggestions.Build({
        accepted = false,
        sequence = revision,
        state = { sequence = revision },
        ir = {},
        decision = {},
    }, context, nil)
    view.semanticSuggestions = projection
    view.semanticSuggestionRevision = projection
        and projection.revision or nil
    applyCoreChoices(view, projection)
    return projection
end

function Internal.SelectSemanticGroup(view, frame)
    if not view or not view.session
        or type(Suggestions.IsGroupFrame) ~= "function"
        or not Suggestions.IsGroupFrame(frame)
    then
        return false, "semantic_group_frame_invalid"
    end
    local projection = view.semanticSuggestions
    if type(projection) ~= "table" then
        return false, "semantic_suggestions_unavailable"
    end
    if tonumber(frame.requestRevision) ~= tonumber(projection.revision) then
        return false, "stale_suggestion"
    end
    local selected
    for _, group in ipairs(projection.groups or {}) do
        if tostring(group.id or "") == tostring(frame.groupID) then
            selected = group
            break
        end
    end
    if not selected then return false, "semantic_group_unknown" end
    view.semanticSuggestionGroupID = selected.id
    view.session.semanticSuggestionGroupID = selected.id
    if view.spec and view.spec.context then
        view.spec.context.semanticSuggestionGroupID = selected.id
    end
    projection.currentGroupID = selected.id
    local applied, reason = applyCoreChoices(view, projection)
    if not applied then return false, reason end
    return true, "accepted"
end

local function clearSemanticTopicFocus(view)
    local session = view and view.session or nil
    local dialogueState = session and session.semanticDialogueState or nil
    if type(dialogueState) == "table" then
        if type(dialogueState.ClearTopicFocus) == "function" then
            dialogueState:ClearTopicFocus()
        else
            if dialogueState.currentTopic then
                dialogueState.previousTopic = dialogueState.currentTopic
            end
            dialogueState.currentTopic = nil
        end
    end
    local contextState = session and session.semanticDialogueContext or nil
    if type(contextState) == "table" then
        if type(contextState.ClearTopicFocus) == "function" then
            contextState:ClearTopicFocus()
        else
            if contextState.currentTopic then
                contextState.previousTopic = contextState.currentTopic
            end
            contextState.currentTopic = nil
        end
    end
end

function Internal.SelectSemanticRoot(view, frame, options)
    options = type(options) == "table" and options or {}
    if not view or not view.session
        or type(Suggestions.IsBackFrame) ~= "function"
        or not Suggestions.IsBackFrame(frame)
    then
        return false, "semantic_back_frame_invalid"
    end
    local projection = view.semanticSuggestions
    if type(projection) ~= "table" then
        return false, "semantic_suggestions_unavailable"
    end
    if tonumber(frame.requestRevision) ~= tonumber(projection.revision) then
        return false, "stale_suggestion"
    end
    if projection.allowBack == false then
        return false, "semantic_back_disabled"
    end
    local rootID = tostring(projection.rootGroupID or "")
    local targetGroupID = tostring(frame.groupID or "")
    if rootID == "" or targetGroupID == "" then
        return false, "semantic_root_unknown"
    end
    if tostring(projection.currentGroupID or "") == targetGroupID then
        return false, "semantic_root_already_selected"
    end
    for _, group in ipairs(projection.groups or {}) do
        if tostring(group.id or "")
            == tostring(projection.currentGroupID or "")
        then
            if group.allowBack == false then
                return false, "semantic_back_disabled"
            end
            break
        end
    end
    local target
    for _, group in ipairs(projection.groups or {}) do
        if tostring(group.id or "") == targetGroupID then
            target = group
            break
        end
    end
    if not target then return false, "semantic_root_unknown" end
    local fromGroupID = tostring(frame.fromGroupID or "")
    if fromGroupID ~= ""
        and tostring(projection.currentGroupID or "") ~= fromGroupID
    then
        return false, "stale_suggestion"
    end
    if targetGroupID == rootID then clearSemanticTopicFocus(view) end
    view.semanticSuggestionGroupID = targetGroupID
    view.session.semanticSuggestionGroupID = targetGroupID
    if view.spec and view.spec.context then
        view.spec.context.semanticSuggestionGroupID = targetGroupID
    end
    projection.currentGroupID = targetGroupID
    local applied, reason = applyCoreChoices(view, projection)
    if not applied then return false, reason end
    local reply = frame.utterance or frame.textFallback
    if frame.playerReply == true
        and options.skipPlayerReply ~= true
        and type(reply) == "string"
        and reply ~= ""
    then
        local group = view.groupConversation
        local session = group and type(group.PrimarySession) == "function"
            and group:PrimarySession() or view.session
        if session and type(session.append) == "function" then
            session:append("player", reply, {
                source = {
                    kind = "semantic",
                    channel = "navigation",
                },
                candidateID = frame.candidateID,
                fromGroupID = frame.fromGroupID,
                groupID = group and group.id or nil,
                participants = group and group.participantIDs or nil,
                groupTurnID = group and group.activeTurn
                    and group.activeTurn.id or nil,
            })
        end
    end
    return true, "accepted"
end


Internal.clearSemanticTopicFocus = clearSemanticTopicFocus

