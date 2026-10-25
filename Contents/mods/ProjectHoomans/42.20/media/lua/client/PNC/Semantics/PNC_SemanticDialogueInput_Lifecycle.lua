-- Submission lifecycle for hybrid semantic dialogue input.
--
-- This spoke owns validation, routing, context recording, optional LLM
-- fallback, action dispatch, and response scheduling. Presentation, semantic
-- context construction, and domain adapters remain separate spokes.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Conversation/Memory/PNC_ConversationMemory"
require "PNC/Conversation/Definitions/Memory/ConversationTopics/00_PNC_ConversationMemoryTopics"

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local CampSiteHints = require "PNC/Semantics/PNC_SemanticCampSiteHints"
local LocationObservation = PNC.Semantics.LocationObservation
    or require "PNC/Semantics/PNC_SemanticLocationObservation"

local Internal = Input.Internal or {}
Input.Internal = Internal
local DialogueInputTrace = PNC.Semantics.DialogueInputTrace
local audit = DialogueInputTrace.Audit
local traceTurn = DialogueInputTrace.RecordTurn
local Suggestions = PNC.Semantics.DialogueSuggestions
if type(Suggestions) ~= "table" then
    require "PNC/Semantics/PNC_SemanticDialogueSuggestions"
    Suggestions = PNC.Semantics.DialogueSuggestions
end
Suggestions = type(Suggestions) == "table" and Suggestions or {}
local InteractionLifecycle = PNC.Semantics.InteractionLifecycle
if type(InteractionLifecycle) ~= "table" then
    local loaded = require
        "PNC/Semantics/PNC_SemanticInteractionLifecycle"
    InteractionLifecycle = type(loaded) == "table" and loaded or nil
end

local function suggestionText(row)
    local display = row and row.display or {}
    return tostring(
        display.label
            or display.labelFallback
            or display.utterance
            or display.utteranceFallback
            or row and (row.id or row.action)
            or ""
    )
end

local function suggestionTooltip(row)
    local eligibility = row and row.eligibility or nil
    local status = row and row.status or eligibility
        and eligibility.status or ""
    local text = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Text or nil
    if status == "requires_destination"
        or status == "selected_requires_destination"
    then
        return text and type(text.Resolve) == "function"
            and text.Resolve({
                key = "UI_PNC_Conversation_Suggestion_NeedsDestination_Tooltip",
                fallback = "Choose a destination first.",
            }) or "Choose a destination first."
    end
    if status ~= "" and string.sub(status, 1, 12) == "unavailable_" then
        local reasonKey = row and row.reasonKey
            or eligibility and eligibility.reasonKey
        local reasonFallback = row and row.reasonFallback
            or eligibility and eligibility.reasonFallback
        if reasonKey then
            return text and type(text.Resolve) == "function"
                and text.Resolve({
                    key = reasonKey,
                    fallback = reasonFallback
                        or "Unavailable in the current situation.",
                }) or reasonFallback
                or "Unavailable in the current situation."
        end
        return text and type(text.Resolve) == "function"
            and text.Resolve({
                key = "UI_PNC_Conversation_Suggestion_Unavailable_Tooltip",
                fallback = "Unavailable in the current situation.",
            }) or "Unavailable in the current situation."
    end
    return nil
end

local function interactionContext(view, context)
    context = type(context) == "table" and context or {}
    local session = view and view.session or nil
    local spec = view and view.spec or nil
    local playerUUID = context.characterUUID or context.playerUUID
        or session and session.characterUUID
        or spec and spec.characterUUID
    local lifecycle = context.interactionLifecycle
        or session and session.semanticInteractionLifecycle
    local thread = type(lifecycle) == "table" and lifecycle or nil
    local beat = thread and thread.activeBeat or nil
    local npcEnvelope = view and view.lastNPCSemanticInteraction
        or session and session.semanticNPCProvenance
    local provenance = beat and {
        beatID = beat.id,
        responsePlanID = beat.responsePlanID,
        flowID = beat.flowID,
        poolID = beat.poolID,
        factRefs = beat.factRefs,
    } or npcEnvelope and npcEnvelope.provenance or nil
    local campSiteCandidates = context.campSiteCandidates
    if type(campSiteCandidates) ~= "table" and type(CampSiteHints.Enumerate) == "function" then
        local discovered = CampSiteHints.Enumerate(context, { maxRooms = 8 })
        if type(discovered) == "table" and #discovered > 0 then
            campSiteCandidates = discovered
        end
    end
    return {
        actorID = playerUUID or context.actorID,
        targetID = spec and spec.npcID or context.targetID,
        campSiteCandidates = campSiteCandidates,
        playerUUID = playerUUID,
        topic = beat and beat.topic or npcEnvelope and npcEnvelope.topic
            or context.currentTopic
            or context.authoredTopic
            or context.conversationTopic,
        worldHour = context.worldHour or context.occurredAt,
        provenance = provenance,
    }
end

local function attachInteractionEnvelope(
    view, result, source, ir, context, frame
)
    if not InteractionLifecycle
        or type(InteractionLifecycle.Envelope) ~= "table"
    then
        return nil
    end
    local Envelope = InteractionLifecycle.Envelope
    local envelope
    if source == "semantic_choice"
        and type(Envelope.SemanticChoice) == "function"
    then
        envelope = Envelope.SemanticChoice(
            frame or {}, interactionContext(view, context)
        )
    elseif type(Envelope.TypedText) == "function" then
        envelope = Envelope.TypedText(
            ir or {}, interactionContext(view, context)
        )
    end
    if not envelope then return nil end
    if type(result) == "table" then result.interaction = envelope end
    if view then view.lastSemanticInteractionEnvelope = envelope end
    return envelope
end

local function restoreSemanticChoices(view)
    local composer = PNC.Conversation
        and PNC.Conversation.Composer or nil
    local composerInternal = composer and composer.Internal or nil
    if composerInternal
        and type(composerInternal.RestoreCurrentChoices) == "function"
    then
        return composerInternal.RestoreCurrentChoices(view)
    end
    if type(Internal.RefreshRootSuggestions) == "function" then
        return Internal.RefreshRootSuggestions(view)
    end
    return false
end

local function submitLifecycleEnvelope(view, result, actionResult)
    local interaction = type(result) == "table"
        and result.interaction or nil
    if type(interaction) ~= "table"
        or interaction.source ~= "typed_text"
        or not sendClientCommand
    then
        return false, "lifecycle_transport_unavailable"
    end
    -- Ordinary authored deterministic turns still belong to the existing
    -- parser/router/ConversationBlocks path.  The lifecycle command is only
    -- needed when an NPC semantic beat or response-plan provenance is
    -- present; otherwise this adapter would create a generic network side
    -- effect for commands and proposal turns that already have their own
    -- authoritative route.
    local provenance = interaction.provenance or {}
    if not provenance.beatID
        and not provenance.responsePlanID
        and not provenance.flowID
        and not provenance.poolID
    then
        return false, "lifecycle_context_unavailable"
    end
    -- Directed hostility already enters the authoritative SocialEvent route;
    -- sending a second generic lifecycle mutation would duplicate its event.
    local act = string.upper(tostring(interaction.act or ""))
    if act == "INSULT" or act == "HOSTILE_REMARK" or act == "THREATEN" then
        return false, "authoritative_social_event_route"
    end
    local session = view and view.session or nil
    local lifecycle = view and view.spec and view.spec.context
        and view.spec.context.conversationLifecycleState or nil
    local requestID = table.concat({
        tostring(session and session.conversationID or "conversation"),
        tostring(result.sequence or 0),
        tostring(Internal.Now()),
    }, ":")
    sendClientCommand(
        PNC.Const.MODULE,
        PNC.Const.CMD_SEMANTIC_INTERACTION_LIFECYCLE,
        {
            requestID = requestID,
            npcID = view and view.spec and view.spec.npcID,
            token = lifecycle and lifecycle.token
                or session and session.token,
            interaction = interaction,
        }
    )
    return true, "submitted"
end

local function recordSemanticChoiceClick(view, frame, eventName, reason)
    local session = view and view.session or nil
    local router = session and session.semanticDialogueRouter or nil
    local state = router and router.state or nil
    audit(eventName, {
        npcID = view and view.spec and view.spec.npcID,
        conversationID = session and session.conversationID,
        candidateID = frame and frame.candidateID,
        frameKind = frame and frame.kind,
        requestRevision = frame and frame.requestRevision,
        currentRevision = state and state.sequence,
        reason = reason,
        currentNodeID = session and session.currentNodeID,
        busy = session and session.busy == true,
        pendingRequest = view and view.spec and view.spec.context
            and view.spec.context.pendingConversationRequest ~= nil,
    })
end

local function authoredRootChoice(authoredChoices, frame)
    local extensions = type(frame) == "table"
        and type(frame.extensions) == "table" and frame.extensions or nil
    if not extensions or extensions.origin ~= "conversation_root" then
        return nil
    end
    local requestedID = tostring(
        extensions.rootChoiceID or extensions.actionID
            or extensions.choiceID or ""
    )
    if requestedID == "" then return nil end
    for _, authoredChoice in ipairs(authoredChoices or {}) do
        if type(authoredChoice) == "table"
            and tostring(authoredChoice.id or "") == requestedID
        then
            return authoredChoice
        end
    end
    return nil
end

local function preserveAuthoredValue(value, authoredChoice)
    if type(value) ~= "function" then return value end
    return function(context, _, session)
        return value(
            context,
            authoredChoice and authoredChoice.source,
            session
        )
    end
end

-- Build rows for Core's native choice list. This is a data adapter only: Core
-- still owns layout, scrolling, hover, click gating, and session ordering; the
-- canonical semantic input path owns the click frame. Authored choices are
-- retained only as the current runtime normalization, never as persistence.
local function buildCoreChoices(view, projection, authoredChoices)
    projection = type(projection) == "table" and projection or {}
    local selectedGroup
    local requestedGroup = projection.currentGroupID
    for _, group in ipairs(projection.groups or {}) do
        if group.id == requestedGroup then
            selectedGroup = group
            break
        end
    end
    if not selectedGroup and #(projection.groups or {}) > 0 then
        selectedGroup = projection.groups[1]
    end

    local rows = {}
    local function append(row, enabled)
        local frame = row and row.frame or nil
        if type(frame) ~= "table" then return end
        local authoredChoice = authoredRootChoice(authoredChoices, frame)
        local rowEnabled = enabled == true
            and (not authoredChoice or authoredChoice.enabled ~= false)
        local semanticSource = {
            semanticFrame = frame,
            source = row.source,
            groupID = selectedGroup and selectedGroup.id
                or row.groupID,
        }
        rows[#rows + 1] = {
            id = row.id or row.action or ("semantic:" .. tostring(#rows + 1)),
            text = suggestionText(row),
            enabled = rowEnabled,
            tooltip = authoredChoice and authoredChoice.tooltip
                or suggestionTooltip(row),
            -- Root rows preserve Core's normalized authored behavior. Other
            -- semantic rows remain typed semantic adapters and do not create
            -- a second authored player turn.
            log = authoredChoice and authoredChoice.log ~= false or false,
            response = authoredChoice
                and preserveAuthoredValue(authoredChoice.response, authoredChoice)
                or nil,
            next = authoredChoice
                and preserveAuthoredValue(authoredChoice.next, authoredChoice)
                or nil,
            close = authoredChoice
                and preserveAuthoredValue(authoredChoice.close, authoredChoice)
                or nil,
            closeReason = authoredChoice
                and preserveAuthoredValue(
                    authoredChoice.closeReason, authoredChoice
                ) or nil,
            onHighlightChanged = authoredChoice
                and type(authoredChoice.onHighlightChanged) == "function"
                and function(_, highlighted)
                    return authoredChoice.onHighlightChanged(
                        authoredChoice, highlighted
                    )
                end or nil,
            source = semanticSource,
            action = function()
                local input = PNC.Semantics
                    and PNC.Semantics.DialogueInput or nil
                if not input or type(input.SubmitSemanticFrame)
                    ~= "function"
                then
                    view.lastSemanticSuggestionReason =
                        "semantic_input_unavailable"
                    view.lastSemanticSuggestionFailure = {
                        candidateID = frame.candidateID,
                        requestRevision = frame.requestRevision,
                        reason = "semantic_input_unavailable",
                    }
                    recordSemanticChoiceClick(
                        view, frame, "semantic.choice.rejected",
                        "semantic_input_unavailable"
                    )
                    return false
                end
                local previousCoreFrame = view.semanticCoreChoiceFrame
                view.semanticCoreChoiceFrame = frame
                local accepted, reason = input.SubmitSemanticFrame(
                    view,
                    frame,
                    authoredChoice and {
                        coreAuthoredChoice = true,
                        authoredChoice = authoredChoice,
                    } or nil
                )
                view.semanticCoreChoiceFrame = previousCoreFrame
                view.lastSemanticSuggestionReason = reason
                if accepted ~= true then
                    view.lastSemanticSuggestionFailure = {
                        candidateID = frame.candidateID,
                        frameKind = frame.kind,
                        requestRevision = frame.requestRevision,
                        reason = reason,
                        currentNodeID = view.session
                            and view.session.currentNodeID,
                    }
                    recordSemanticChoiceClick(
                        view, frame, "semantic.choice.rejected", reason
                    )
                    -- Core clears the presented row before invoking its
                    -- action. A stale, busy, or rejected semantic frame must
                    -- therefore restore the production choice surface so a
                    -- native click cannot leave the conversation blank.
                    restoreSemanticChoices(view)
                else
                    view.lastSemanticSuggestionFailure = nil
                    recordSemanticChoiceClick(
                        view, frame, "semantic.choice.accepted", "accepted"
                    )
                end
                return accepted
            end,
        }
    end

    local rootGroupID = projection.rootGroupID
    local navigation = selectedGroup and selectedGroup.navigation or {}
    if #navigation == 0
        and selectedGroup
        and rootGroupID
        and selectedGroup.id ~= rootGroupID
        and projection.allowBack ~= false
        and selectedGroup.allowBack ~= false
        and Suggestions.BuildBackFrame
    then
        -- Compatibility for projections produced before shared navigation was
        -- added. New projections carry this row in group.navigation.
        local frame = Suggestions.BuildBackFrame(
            projection.revision,
            selectedGroup.id,
            Internal.ShallowContext(view)
        )
        if frame then
            navigation = {{
                id = frame.candidateID,
                frame = frame,
                display = {
                    label = frame.labelFallback,
                    labelFallback = frame.labelFallback,
                },
                source = {
                    kind = "semantic_back_navigation",
                    revision = projection.revision,
                    fromGroupID = selectedGroup.id,
                },
            }}
        end
    end
    for _, row in ipairs(navigation) do
        append(row, true)
    end

    local candidates = selectedGroup and selectedGroup.candidates
        or projection.candidates or {}
    for _, candidate in ipairs(candidates) do
        append(candidate, candidate.enabled ~= false)
    end
    local capabilities = selectedGroup and selectedGroup.capabilities
        or projection.permittedCapabilities or {}
    for _, capability in ipairs(capabilities) do
        append(capability,
            (capability.status == "eligible"
                or capability.status == "selected_for_preflight")
                and capability.enabled ~= false)
    end
    -- Owned companion actions are real landing actions, not a topic browser.
    -- Keep them beside the landing choices while leaving unrelated groups
    -- behind the explicit context index.
    if selectedGroup and selectedGroup.id == rootGroupID then
        for _, group in ipairs(projection.groups or {}) do
            if group.id == "owned_actions" then
                for _, capability in ipairs(group.capabilities or {}) do
                    append(capability,
                        (capability.status == "eligible"
                            or capability.status == "selected_for_preflight")
                            and capability.enabled ~= false)
                end
                break
            end
        end
    end
    if view then view.semanticSuggestionRows = rows end
    return rows
end

-- This callback is installed in the Core conversation definition. Core calls
-- it after every authored choice normalization, including pending-response
-- completion and in-place spec refresh. Returning nil preserves Core's
-- normalized authored choices as the safe fallback.
local function presentSemanticChoices(view, authoredChoices)
    local projection = view and view.semanticSuggestions or nil
    if type(projection) ~= "table" then return nil end
    if view then view.semanticAuthoredChoices = authoredChoices end
    if view and view.session and view.session.busy == true then
        -- Do not replace Core's authored/pending surface while the opening or
        -- a response is still being delivered. Core rejects clicks in this
        -- state, so exposing semantic rows here creates dead buttons.
        view.semanticPresentationPending = projection
        return nil
    end
    local rows = buildCoreChoices(
        view, projection, view and view.semanticAuthoredChoices
    )
    if #rows > 0 then
        view.semanticPresentationPending = nil
        return rows
    end
    return nil
end

local function applyCoreChoices(view, projection, authoredChoices)
    local session = view and view.session or nil
    if not session or type(session.setPresentedChoices) ~= "function" then
        return false, "core_choices_unavailable"
    end
    authoredChoices = authoredChoices
        or view and view.semanticAuthoredChoices
    local rows = buildCoreChoices(view, projection, authoredChoices)
    if session.busy == true then
        -- Session:finishPending will call setChoices after the queued NPC
        -- response, at which point the presentation callback will apply the
        -- same production projection with an interactive Core session.
        view.semanticPresentationPending = projection
        return false, "semantic_choices_deferred"
    end
    if #rows < 1 then
        -- A projection can legitimately be empty while a dependency or
        -- current topic is unavailable. Restore the authored Core choices
        -- when the session is idle; never expose stale choices during a
        -- queued response.
        if session.busy == true then
            -- Session:finishPending will call Core's normal setChoices after
            -- the queued reply; its presentation callback then supplies the
            -- projection or the authored fallback.
            view.semanticPresentationPending = projection
            return false, "semantic_choices_deferred"
        end
        if projection
            and tostring(projection.currentGroupID or "")
                == tostring(projection.rootGroupID or "")
        then
            -- Back is still a valid presentation transition when the
            -- landing group has no currently eligible rows. Keep the
            -- production surface empty rather than rejecting the navigation
            -- frame as if the root itself were stale.
            view.semanticPresentationPending = nil
            session:setPresentedChoices({}, {
                source = "semantic_suggestions_empty",
                revision = projection.revision,
                presentedCount = 0,
            })
            return true, rows
        end
        local node = session.currentNode or {}
        if type(session.setChoices) == "function" then
            session:setChoices(node.choices or {})
        end
        return false, "semantic_choices_empty"
    end
    view.semanticPresentationPending = nil
    local applied = session:setPresentedChoices(rows, {
        source = "semantic_suggestions",
        revision = projection and projection.revision,
        presentedCount = #rows,
    })
    return applied == true, rows
end

Internal.PresentSemanticChoices = presentSemanticChoices
Internal.ApplySemanticChoices = applyCoreChoices

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

local function applyGeneratedFlowResult(view, result, actionResult)
    local flow = result and result.flow or nil
    local policy = PNC.Semantics and PNC.Semantics.DialoguePolicy or nil
    local kernel = policy and policy.Internal and policy.Internal.FlowKernel
    local state = view and view.session
        and view.session.semanticDialogueState or nil
    if type(flow) ~= "table" or flow.generated ~= true
        or type(actionResult) ~= "table"
        or not kernel or type(kernel.ApplyActionResult) ~= "function"
        or not state or type(Internal.ShallowContext) ~= "function"
    then
        return false
    end
    local updated, reason = kernel.ApplyActionResult(
        flow,
        actionResult,
        state,
        Internal.ShallowContext(view),
        { maxFlowStack = 4 }
    )
    if type(updated) ~= "table" then
        audit("semantic.generated_flow.result_unapplied", {
            flowID = flow.flowId,
            reason = reason,
            status = actionResult.status,
        })
        return false
    end
    result.flow = updated
    if type(result.decision) == "table" then
        result.decision.flow = updated
    end
    return true
end

local function groupMemberShouldHandle(view, result, value)
    local group = view and view.groupConversation
    if not group or type(group.MemberForHost) ~= "function"
        or type(group.ShouldRespond) ~= "function"
    then
        return true
    end
    local member = group:MemberForHost(view)
    return not member or group:ShouldRespond(member, result, value)
end

local function giftConsentResponseView(view, result)
    local consent = result and result.decision
        and result.decision.giftConsent or nil
    local group = view and view.groupConversation or nil
    if type(consent) ~= "table" or not consent.recipientID
        or not group or type(group.ViewFor) ~= "function"
    then
        return view
    end
    return group:ViewFor(consent.recipientID) or view
end

local function finishLocalSubmit(view, value, result, options)
    options = type(options) == "table" and options or {}
    local inputMessage = options.skipInputPresentation == true
        and true or Internal.AppendPlayerInput(
            view, options.inputValue or value, result
        )
    if not inputMessage then return false, "input_presentation_failed" end
    local actionResult
    local queued = false
    view.lastSemanticActionResult = nil
    if groupMemberShouldHandle(view, result, value) then
        actionResult = Internal.DispatchAction(view, result, value)
        view.lastSemanticActionResult = actionResult
        applyGeneratedFlowResult(view, result, actionResult)
        submitLifecycleEnvelope(view, result, actionResult)
        if Internal.ClearPendingGiftConsent then
            Internal.ClearPendingGiftConsent(view)
        end
        if options.deferResponse ~= true then
            queued = Internal.QueueDeterministicResponse(
                giftConsentResponseView(view, result),
                value,
                result,
                actionResult
            )
        end
    else
        audit("semantic.group.member_skipped", {
            groupID = view.groupConversation
                and view.groupConversation.id,
            turnID = view.groupConversation
                and view.groupConversation.activeTurn
                and view.groupConversation.activeTurn.id,
            npcID = view.spec and view.spec.npcID,
            reason = "not_addressed",
        })
    end
    audit("semantic.response.queued", {
        npcID = view.spec and view.spec.npcID,
        conversationID = view.session.conversationID,
        requestID = result.sequence,
        route = result.decision and result.decision.route,
        branch = result.decision and result.decision.branch,
        action = result.ir and result.ir.action,
        actionStatus = actionResult and actionResult.status,
        actionReason = actionResult and actionResult.reason,
        queued = queued == true,
        deferred = options.deferResponse == true,
    }, { requestID = result.sequence })
    return true
end

local SemanticTelemetryPrompt = require
    "PNC/Semantics/PNC_SemanticTelemetryPrompt"

local function recordAcceptedContextTurn(view, result, options)
    if not Internal.RecordContextTurn or not result
        or result.accepted ~= true or not result.ir
    then
        return false, "context_recording_skipped"
    end
    local recorded, event = Internal.RecordContextTurn(view, result.ir, options)
    audit("semantic.context.recorded", {
        npcID = view.spec and view.spec.npcID,
        conversationID = view.session.conversationID,
        requestID = result.sequence,
        recorded = recorded == true,
        reason = type(event) == "string" and event or nil,
        contextSequence = view.session.semanticDialogueContext
            and view.session.semanticDialogueContext.sequence or nil,
    }, { requestID = result.sequence })
    return recorded, event
end

local function recordConversationTopics(view, result, rawText)
    local session = view and view.session
    local events = PNC.Conversation and PNC.Conversation.Memory
        and PNC.Conversation.Memory.Events or nil
    if not session or not result or result.accepted ~= true
        or type(result.ir) ~= "table"
        or not events or type(events.AccumulateConversationTopics) ~= "function"
    then
        return false
    end
    local ok, recorded = pcall(
        events.AccumulateConversationTopics,
        session,
        result.ir,
        rawText
    )
    return ok and recorded == true
end

function Internal.SubmitCompound(view, value, parts, sourcePart)
    if type(parts) ~= "table" or #parts < 2 then
        return false, "compound_turn_invalid"
    end
    local index
    local part
    local submitted = true
    local reason
    local receipts = {}
    view.lastSemanticCompound = {
        schemaVersion = 1,
        rawText = value,
        parts = receipts,
    }
    for index = 1, #parts do
        part = parts[index]
        submitted, reason = Internal.SubmitSingle(view, part.text, {
            compoundPart = true,
            compoundRoot = value,
            compoundIndex = index,
            compoundCount = #parts,
            sourcePart = sourcePart,
        })
        receipts[index] = {
            index = index,
            text = part.text,
            accepted = submitted == true,
            reason = reason,
            pattern = view.lastSemanticDialogueResult
                and view.lastSemanticDialogueResult.ir
                and view.lastSemanticDialogueResult.ir.provenance
                and view.lastSemanticDialogueResult.ir.provenance.pattern,
            intent = view.lastSemanticDialogueResult
                and view.lastSemanticDialogueResult.ir
                and view.lastSemanticDialogueResult.ir.intent,
            subject = view.lastSemanticDialogueResult
                and view.lastSemanticDialogueResult.ir
                and view.lastSemanticDialogueResult.ir.subject,
            flow = view.lastSemanticDialogueResult
                and view.lastSemanticDialogueResult.decision
                and view.lastSemanticDialogueResult.decision.flow
                and view.lastSemanticDialogueResult.decision.flow.transition,
        }
        if not submitted then return false, reason end
    end
    return true
end

function Internal.SubmitSingle(view, value, part)
    if not view or not view.session then
        return false, "conversation_unavailable"
    end
    if view.session.llmPending
        or view.session.semanticDialoguePending
    then
        return false, "conversation_busy"
    end
    if not (type(part) == "table" and part.compoundPart == true) then
        view.lastSemanticCompound = nil
    end
    local semanticFrame = type(part) == "table"
        and part.semanticFrame or nil
    -- Keep the submitting host available to asynchronous local projections.
    -- Full-screen conversations are discoverable through Core's singleton,
    -- while compact/headless conversations are deliberately not global.  The
    -- reference is runtime-only and is never serialized or sent over the
    -- network.
    Input.ActiveView = view
    view.lastSemanticActionResult = nil
    if not Internal.Interactive(view) then return false, "conversation_busy" end
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if value == "" then return false, "empty_message" end
    value = string.sub(value, 1, Input.MAX_INPUT_LENGTH)

    if not semanticFrame
        and not (type(part) == "table" and part.compoundPart == true)
        and type(Internal.ParseTurn) == "function"
    then
        local turn = Internal.ParseTurn(value, nil, view)
        if type(turn) == "table" and turn.compound == true then
            return Internal.SubmitCompound(view, value, turn.parts, part)
        end
    end

    audit("semantic.input.received", {
        npcID = view.spec and view.spec.npcID,
        conversationID = view.session.conversationID,
        rawText = value,
    })

    local router, routerReason = Internal.RouterFor(view)
    if not router then
        audit("semantic.input.rejected", {
            npcID = view.spec and view.spec.npcID,
            conversationID = view.session.conversationID,
            rawText = value,
            reason = routerReason,
        })
        return false, routerReason
    end
    local service = Internal.ActorConversationService
        and Internal.ActorConversationService(view) or nil
    local context = Internal.ShallowContext(view)
    local options = {
        timestamp = Internal.Now(),
    }
    local preview
    local cognitionAccepted
    local cognitionRequestID
    local cognitionPending
    local clearSemanticMemoryTarget = false
    local frameIR
    if semanticFrame then
        local frameReason
        local expectedRevision = tonumber(semanticFrame.requestRevision)
        local receiptKey = tostring(view.session.conversationID or "")
            .. ":" .. tostring(expectedRevision)
            .. ":" .. tostring(semanticFrame.candidateID or "")
        view.session.semanticSuggestionReceipts =
            view.session.semanticSuggestionReceipts or {}
        if view.session.semanticSuggestionReceipts[receiptKey] then
            return false, "duplicate_suggestion"
        end
        local currentRevision = tonumber(router.state and router.state.sequence) or 0
        if expectedRevision == nil or expectedRevision ~= currentRevision then
            return false, "stale_suggestion"
        end
        frameIR, frameReason = Suggestions.FrameToIR(semanticFrame, view)
        if not frameIR then return false, frameReason end
        local eligible, eligibilityReason = Suggestions.CheckFrame(
            semanticFrame, context, frameIR
        )
        if eligible ~= true then return false, eligibilityReason end
        preview = {
            schemaVersion = 1,
            kind = "semantic_dialogue_preview",
            accepted = true,
            ir = frameIR,
            decision = router:Decide(frameIR, context, options),
            state = router.state,
            sequence = router.state and router.state.sequence,
        }
    elseif service and type(service.Preview) == "function" then
        preview = service:Preview(value, context, options)
    elseif type(router.Preview) == "function" then
        preview = router:Preview(value, context, options)
    else
        preview = router:Process(value, context, options)
    end
    if preview.accepted ~= true then
        audit("semantic.input.rejected", {
            npcID = view.spec and view.spec.npcID,
            conversationID = view.session.conversationID,
            rawText = value,
            reason = preview.reason,
        })
        return false, preview.reason or "semantic_input_rejected"
    end

    -- Recover only a bounded, question-shaped no-match when the current
    -- conversation supplies a single safe topic. The recovered IR is then
    -- routed through the same production policy and ProcessIR path as an
    -- authored pattern; actions still cannot be created by this spoke.
    if not semanticFrame
        and preview.ir and type(Internal.Recover) == "function"
    then
        local recovered = Internal.Recover(preview.ir, context, options)
        if recovered then
            preview.ir = recovered
            preview.decision = router:Decide(
                recovered,
                context,
                options
            )
            audit("semantic.input.recovered", {
                npcID = view.spec and view.spec.npcID,
                conversationID = view.session.conversationID,
                rawText = value,
                pattern = recovered.provenance
                    and recovered.provenance.pattern,
                topic = recovered.subject,
                confidence = recovered.confidence,
            }, { requestID = preview.sequence })
        end
    end

    attachInteractionEnvelope(
        view,
        preview,
        semanticFrame and "semantic_choice" or "typed_text",
        preview.ir,
        context,
        semanticFrame
    )

    if Internal.RequestCognitionForIR then
        cognitionAccepted, _, cognitionRequestID, cognitionPending =
            Internal.RequestCognitionForIR(view, preview.ir)
        if preview.ir and preview.ir.intent == "GOSSIP"
            and cognitionAccepted == true
            and cognitionPending ~= true
        then
            -- Single-player/server-hosted cognition can finish synchronously.
            -- Rebuild the snapshot after the server fills its memory cache so
            -- this same turn can use the returned gossip.
            context = Internal.ShallowContext(view)
            clearSemanticMemoryTarget = true
        end
    end
    local identityRequest = Internal.PrepareIdentityRequest
        and Internal.PrepareIdentityRequest(view, preview.ir, context)

    local decision = preview.decision or {}
    local isIdentityClaim = identityRequest
        and identityRequest.kind == "identity_claim"
    local isBackstoryDisclosure = identityRequest
        and identityRequest.kind == "backstory_disclosure"
    if decision.route == "llm_fallback"
        and not isIdentityClaim and not isBackstoryDisclosure
    then
        if Internal.ClearPendingGiftConsent then
            Internal.ClearPendingGiftConsent(view)
        end
        if Internal.SubmitProviderFallback then
            local submitted = Internal.SubmitProviderFallback(
                view, value, part, preview, decision, context, options
            )
            if submitted then
                if service and type(service.ObserveResult) == "function" then
                    service:ObserveResult(preview)
                end
                recordConversationTopics(view, preview, value)
                if clearSemanticMemoryTarget and view.session then
                    view.session.semanticMemoryTargetID = nil
                end
                return true
            end
        end
    end

    local result = preview
    if service and type(service.ProcessIR) == "function" then
        result = service:ProcessIR(preview.ir, context, options)
    elseif type(router.Preview) == "function" then
        result = router:ProcessIR(preview.ir, context, options)
    end
    if clearSemanticMemoryTarget and view.session then
        view.session.semanticMemoryTargetID = nil
    end
    view.lastSemanticDialogueResult = result
    if type(result) == "table" and preview.interaction then
        result.interaction = preview.interaction
    end

    local finalDecision = result and result.decision or {}
    local deferGossipResponse = cognitionPending == true
        and cognitionRequestID ~= nil
        and preview.ir and preview.ir.intent == "GOSSIP"
        and finalDecision.branch == "GOSSIP_RECEIVED"
        and not view.groupConversation
    if deferGossipResponse then
        view.session.semanticGossipRequestID = tostring(cognitionRequestID)
        view.session.semanticGossipRequestValue = value
        view.session.semanticGossipRequestResult = result
        view.session.semanticDialoguePending = {
            kind = "semantic_gossip",
            requestID = tostring(cognitionRequestID),
        }
    end
    if finalDecision.branch == "ASK_CLARIFICATION"
        and type(SemanticTelemetryPrompt) == "table"
        and type(SemanticTelemetryPrompt.Offer) == "function"
    then
        SemanticTelemetryPrompt.Offer(view, value, result, "local")
    end

    recordAcceptedContextTurn(view, result, options)
    recordConversationTopics(view, result, value)

    -- A deterministic parser result that already names an authored
    -- conversation category must use the same category authority lane as a
    -- typed semantic-click frame.  The parser owns recognition only; the
    -- composer/server path still owns block selection, node entry, effects,
    -- and all revalidation.  Do this before the generic semantic response is
    -- queued so the player never receives a redundant "ask the same thing"
    -- suggestion or acknowledgement.
    if not semanticFrame
        and type(Suggestions.BuildConversationCategoryFrame) == "function"
    then
        local categoryFrame = Suggestions.BuildConversationCategoryFrame(
            result and result.ir or nil,
            result and result.sequence
                or router.state and router.state.sequence or 0
        )
        if categoryFrame then
            local categoryVisible = true
            local categoryReason = "category_preflight"
            if type(Suggestions.IsConversationCategoryAvailable)
                == "function"
            then
                categoryVisible, categoryReason =
                    Suggestions.IsConversationCategoryAvailable(
                        categoryFrame, context
                    )
            end
            if categoryVisible then
                local accepted, routeReason =
                    Input.SubmitSemanticFrame(view, categoryFrame)
                if accepted ~= true then
                    traceTurn(view, value, result, "semantic_category_route", {
                        route = "conversation_category",
                        categoryID = categoryFrame.extensions.categoryID,
                        responseSubmitted = false,
                        responseReason = routeReason,
                    })
                    return false, routeReason or categoryReason
                end
                if service and type(service.ObserveResult) == "function" then
                    service:ObserveResult(result)
                end
                if type(Internal.AppendPlayerInput) == "function" then
                    Internal.AppendPlayerInput(
                        view,
                        Suggestions.ResolveFrameText(categoryFrame),
                        result
                    )
                end
                traceTurn(view, value, result, "semantic_category_route", {
                    route = "conversation_category",
                    categoryID = categoryFrame.extensions.categoryID,
                    responseSubmitted = true,
                    responseReason = routeReason,
                })
                return true, routeReason or "accepted"
            end
        end
    end

    -- Claimed identity and targeted preference disclosures are authoritative
    -- server responses. Do not also queue a local reply for those turns.
    local deferIdentityResponse = identityRequest
        and (identityRequest.kind == "identity_claim"
            or identityRequest.kind == "identity_evasion"
            or identityRequest.kind == "gift_preference_disclosure"
            or identityRequest.kind == "backstory_disclosure")
    local compoundPart = type(part) == "table"
        and part.compoundPart == true
    local compoundIndex = compoundPart and tonumber(part.compoundIndex) or nil
    local compoundCount = compoundPart and tonumber(part.compoundCount) or nil
    local deferCompoundResponse = compoundPart
        and compoundIndex ~= nil and compoundCount ~= nil
        and compoundIndex < compoundCount
    local submitted, submitReason = finishLocalSubmit(
        view,
        value,
        result,
        { deferResponse = deferIdentityResponse == true
            or deferGossipResponse == true
            or deferCompoundResponse == true,
            skipInputPresentation = compoundPart and compoundIndex ~= 1,
            inputValue = compoundPart and compoundIndex == 1
                and part.compoundRoot or value }
    )
    if submitted == true and service
        and type(service.ObserveResult) == "function"
    then
        service:ObserveResult(result)
    end
    if submitted == true and semanticFrame then
        local revision = tonumber(semanticFrame.requestRevision) or 0
        local receiptKey = tostring(view.session.conversationID or "")
            .. ":" .. tostring(revision)
            .. ":" .. tostring(semanticFrame.candidateID or "")
        view.session.semanticSuggestionReceipts =
            view.session.semanticSuggestionReceipts or {}
        view.session.semanticSuggestionReceipts[receiptKey] = {
            status = "accepted",
            sequence = result and result.sequence,
        }
    end
    if submitted == true then
        Internal.RefreshSuggestions(view, result)
    end
    traceTurn(view, value, result, "semantic_input_local", {
        providerAvailable = context.llmAvailable == true,
        providerUsed = false,
        actionStatus = view.lastSemanticActionResult
            and view.lastSemanticActionResult.status,
        actionAccepted = view.lastSemanticActionResult
            and view.lastSemanticActionResult.accepted,
        actionReason = view.lastSemanticActionResult
            and view.lastSemanticActionResult.reason,
        responseSubmitted = submitted == true,
        responseReason = submitReason,
        compoundRoot = compoundPart and part.compoundRoot or nil,
        compoundIndex = compoundIndex,
        compoundCount = compoundCount,
    })
    if identityRequest then
        local dispatched = false
        local dispatchReason
        local requestID
        if Internal.DispatchIdentityRequest then
            dispatched, dispatchReason, requestID =
                Internal.DispatchIdentityRequest(identityRequest)
        end
        if identityRequest.kind == "identity_claim"
            or identityRequest.kind == "identity_evasion"
        then
            audit("semantic.identity.request_dispatched", {
                requestID = requestID or result.sequence,
                inputSequence = result.sequence,
                npcID = tostring(identityRequest.npcID or ""),
                conversationID = view.session
                    and view.session.conversationID or nil,
                kind = tostring(identityRequest.kind or ""),
                accepted = dispatched == true,
                reason = tostring(dispatchReason or ""),
                claimedNamePresent = identityRequest.claimedName ~= nil
                    and tostring(identityRequest.claimedName) ~= "",
                conversationTokenPresent = identityRequest.conversationToken
                    ~= nil
                    and tostring(identityRequest.conversationToken) ~= "",
            }, { requestID = requestID or result.sequence })
        end
        if identityRequest.kind == "identity_claim" and dispatched ~= true
            and Internal.IdentityExchangeUnavailableResponse
            and Internal.QueueDeterministicResponse
        then
            Internal.QueueDeterministicResponse(
                view,
                value,
                result,
                nil,
                {
                    response = Internal.IdentityExchangeUnavailableResponse(),
                }
            )
        end
    end
    return submitted, submitReason
end

function Input.CompleteGossipRequest(request)
    local view = request and request.view or nil
    local session = request and request.session or nil
    local requestID = tostring(request and request.requestID or "")
    local result
    local decision
    local localResponse
    local context
    local value
    if not view or not session or requestID == ""
        or view.session ~= session or session.closed == true
        or view.closed == true or view.closing == true
        or tostring(session.semanticGossipRequestID or "") ~= requestID
        or type(session.semanticDialoguePending) ~= "table"
        or tostring(session.semanticDialoguePending.requestID or "")
            ~= requestID
    then
        return false, "stale_gossip_request"
    end
    result = session.semanticGossipRequestResult
    value = session.semanticGossipRequestValue
    decision = result and result.decision or nil
    if not result or not result.ir or not decision then
        return false, "gossip_response_unavailable"
    end
    context = Internal.ShallowContext(view)
    local groundedGossip = context and context.npcGossip or nil
    if not groundedGossip
        or groundedGossip.source ~= "world_knowledge"
    then
        local clientState = PNC.Network and PNC.Network.ClientState or nil
        local clientGossip = clientState
            and clientState.semanticWorldKnowledgeGossip or nil
        local npcID = view.spec and tostring(view.spec.npcID or "") or ""
        groundedGossip = clientGossip and clientGossip[npcID] or nil
    end
    if groundedGossip and groundedGossip.source == "world_knowledge"
        and type(groundedGossip.factRefs) == "table"
        and #groundedGossip.factRefs > 0
    then
        local response = result.decision.response
        if type(response) == "table" then
            response.groundedFactRefs = {}
            for index = 1, math.min(#groundedGossip.factRefs, 4) do
                response.groundedFactRefs[#response.groundedFactRefs + 1] =
                    groundedGossip.factRefs[index]
            end
            response.selectionSource = "world_knowledge"
            if type(response.plan) == "table" then
                response.plan.groundedFactRefs = response.groundedFactRefs
                response.plan.sourcePoolID = "world_knowledge"
            end
        end
    end
    localResponse = PNC.Semantics and PNC.Semantics.LocalResponse or nil
    if localResponse and type(localResponse.Resolve) == "function" then
        decision.response = localResponse.Resolve(
            result.ir,
            session.semanticDialogueState,
            context,
            decision.branch
        ) or decision.response
    end
    if groundedGossip and groundedGossip.source == "world_knowledge"
        and type(groundedGossip.factRefs) == "table"
        and #groundedGossip.factRefs > 0
        and type(decision.response) == "table"
    then
        decision.response.groundedFactRefs = {}
        for index = 1, math.min(#groundedGossip.factRefs, 4) do
            decision.response.groundedFactRefs[#decision.response.groundedFactRefs + 1] =
                groundedGossip.factRefs[index]
        end
        decision.response.selectionSource = "world_knowledge"
        if type(decision.response.plan) == "table" then
            decision.response.plan.groundedFactRefs =
                decision.response.groundedFactRefs
            decision.response.plan.sourcePoolID = "world_knowledge"
        end
    end
    session.semanticMemoryTargetID = nil
    session.semanticGossipRequestID = nil
    session.semanticGossipRequestResult = nil
    session.semanticGossipRequestValue = nil
    session.semanticDialoguePending = nil
    if type(Internal.QueueDeterministicResponse) ~= "function" then
        return false, "response_queue_unavailable"
    end
    return Internal.QueueDeterministicResponse(view, value, result, nil)
end

return Internal
