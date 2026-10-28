-- Lifecycle interaction and semantic-choice presentation helpers.
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
        realizationID = beat.realizationID,
        eventRef = beat.eventRef,
        offerIDs = beat.offerIDs,
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
        eventRef = beat and beat.eventRef
            or npcEnvelope and npcEnvelope.eventRef
            or context.eventRef,
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
        or (interaction.source ~= "typed_text" and interaction.source ~= "semantic_choice")
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
    local Relations = require "PNC/Semantics/PNC_SemanticInteractionRelations"
    local compactAct = Relations.GetCompactType(interaction.act)
    if not provenance.beatID
        and not provenance.responsePlanID
        and not provenance.flowID
        and not provenance.poolID and not compactAct
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

Internal.suggestionText = suggestionText
Internal.suggestionTooltip = suggestionTooltip
Internal.interactionContext = interactionContext
Internal.attachInteractionEnvelope = attachInteractionEnvelope
Internal.restoreSemanticChoices = restoreSemanticChoices
Internal.submitLifecycleEnvelope = submitLifecycleEnvelope
Internal.recordSemanticChoiceClick = recordSemanticChoiceClick
Internal.authoredRootChoice = authoredRootChoice
Internal.preserveAuthoredValue = preserveAuthoredValue

return Internal

