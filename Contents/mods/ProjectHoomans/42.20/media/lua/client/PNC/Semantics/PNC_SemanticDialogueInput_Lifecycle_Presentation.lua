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


Internal.suggestionText = suggestionText
Internal.suggestionTooltip = suggestionTooltip
Internal.interactionContext = interactionContext
Internal.attachInteractionEnvelope = attachInteractionEnvelope
Internal.restoreSemanticChoices = restoreSemanticChoices
Internal.submitLifecycleEnvelope = submitLifecycleEnvelope
Internal.recordSemanticChoiceClick = recordSemanticChoiceClick
Internal.buildCoreChoices = buildCoreChoices
Internal.presentSemanticChoices = presentSemanticChoices
Internal.applyCoreChoices = applyCoreChoices

