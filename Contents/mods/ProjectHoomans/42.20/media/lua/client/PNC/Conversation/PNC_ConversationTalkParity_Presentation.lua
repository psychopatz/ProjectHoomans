-- Native Talk start and live presentation projection.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local TalkParity = PNC.Conversation.TalkParity
local Conversation = PNC.Conversation
local Internal = TalkParity.Internal
local copy = Internal.copy

local function resolvedText(value)
    if type(value) == "string" then return value end
    if type(value) ~= "table" then return tostring(value or "") end
    local core = PsychopatzCore
        and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Text or nil
    if core and type(core.Resolve) == "function" then
        local resolved = core.Resolve(value)
        if resolved ~= nil and resolved ~= "" then
            return tostring(resolved)
        end
    end
    return tostring(value.text or value.fallback or value.key or "")
end

local function choicesFor(view)
    local session = view and view.session
    local source = session and session.choices
        or session and session.currentNode and session.currentNode.choices
        or {}
    local choices = {}
    for _, choice in ipairs(source) do
        if type(choice) == "table" then
            choices[#choices + 1] = {
                id = choice.id,
                text = resolvedText(choice.text),
                textKey = choice.textKey,
                enabled = choice.enabled ~= false,
                frame = copy(
                    choice.source and choice.source.semanticFrame
                ),
                action = choice.actionID
                    or choice.semantic and choice.semantic.actionID,
                route = choice.semantic and choice.semantic.route,
            }
        end
    end
    return choices
end

function TalkParity.StartProjection(context, value, view)
    local Runtime = context.Runtime
    local scenario = Runtime.scenario or {}
    local resolved, reason = TalkParity.Resolve(
        scenario, value, context.player
    )
    if not resolved then return nil, reason end
    local runtime = scenario.runtime or {}
    local npc = scenario.npc or {}
    local dynamicTradingLoad = Runtime.dynamicTradingLoad or {
        requested = runtime.availableMods
            and runtime.availableMods.DTHoomans == true or false,
        loaded = false,
        reason = "disabled",
    }
    local traderOverlay = tostring(npc.role or "") == "trader"
    local integration = {
        pbrainz = {
            inlineAvailable = resolved.hostileInlineAvailable == true,
            reason = resolved.hostileInlineReason,
        },
        dynamicTrading = context.Values.copy(dynamicTradingLoad),
        traderOverlay = {
            enabled = traderOverlay,
            providerID = traderOverlay and "dynamictrading.trader" or nil,
            targetType = resolved.targetType,
            tacticalClass = resolved.tacticalClass,
        },
    }
    local graph = context.Conversation
        and type(context.Conversation.graphProjection) == "function"
        and context.Conversation.graphProjection(view) or nil
    return {
        schema = TalkParity.SCHEMA,
        target = resolved,
        route = resolved.route,
        targetType = resolved.targetType,
        audience = resolved.audience,
        hostile = resolved.hostile,
        integration = integration,
        opening = {
            nodeID = view and view.session and view.session.currentNodeID,
            messages = context.Values.copy(Runtime.transcript or {}),
            choices = choicesFor(view),
            suggestions = context.Values.copy(
                view and view.semanticSuggestions
            ),
            graph = context.Values.copy(graph),
        },
    }
end

local function presentationRows(view)
    local session = view and view.session
    local source = session and session.choices or {}
    local rows = {}
    for _, choice in ipairs(source) do
        if type(choice) == "table" then
            local choiceSource = type(choice.source) == "table"
                and choice.source or {}
            local frame = choiceSource.semanticFrame
            rows[#rows + 1] = {
                id = choice.id,
                text = resolvedText(choice.text),
                enabled = choice.enabled ~= false,
                -- Keep both names during the projection migration. The
                -- worker's established diagnostic spelling is frame; the
                -- semantic authority contract calls it semanticFrame.
                frame = copy(frame),
                semanticFrame = copy(frame),
                source = {
                    kind = choiceSource.source
                        and choiceSource.source.kind or nil,
                    groupID = choiceSource.groupID,
                },
            }
        end
    end
    return rows
end

local function compactProjectionMessages(messages)
    local result = {}
    local values = type(messages) == "table" and messages or {}
    local first = #values > 64 and #values - 63 or 1
    for index = first, #values do
        local message = values[index]
        if type(message) == "table" then
            result[#result + 1] = {
                id = message.id or message.messageID,
                speaker = message.speaker,
                text = resolvedText(message.payload or message.value),
                kind = message.kind,
            }
        end
    end
    return result
end

local function lifecycleState(view, session)
    if view and view.lifecycleFinished == true
        or session and (session.closed == true
            or session.lifecycleFinished == true)
    then
        return "closed"
    end
    if view and view.suspended == true then return "suspended" end
    if view and view.closing == true then return "closing" end
    if session and session.busy == true then return "busy" end
    if session and (session.pendingChoices ~= nil
        or session.pendingNext ~= nil
        or session.pendingClose == true)
    then
        return "pending"
    end
    if session and session.currentNodeID == "greeting"
        and view and view.opened ~= true
    then
        return "opening"
    end
    return "active"
end

-- Export the exact production-facing Conversation projection used by native
-- Core after choicePresentation/buildCoreChoices. This is intentionally a
-- projection of the live session rows, not a rebuild from semanticSuggestions.
function TalkParity.BuildPresentationProjection(context, view)
    local Runtime = context and context.Runtime or {}
    local Values = context and context.Values
    local session = view and view.session or nil
    local spec = view and view.spec or {}
    local semantic = view and view.semanticSuggestions or {}
    local state = session and session.choicePresentationState or {}
    local suspended = Runtime.conversationSuspended == true
        or view and view.suspended == true
    local opened = Runtime.conversationOpened == true and not suspended
    local rows = opened and presentationRows(view) or {}
    local talkStart = spec.talkStartProjection
    if not talkStart then
        local scenario = Runtime.scenario or {}
        local targetID = scenario.runtime
            and scenario.runtime.semanticLabTalkTarget or "current"
        talkStart = TalkParity.Resolve(
            scenario, targetID, context and context.player
        )
    end
    local relationship = Conversation.Relationship
        and Conversation.Relationship.GetPresentation
        and Conversation.Relationship.GetPresentation(spec.npcID)
        or nil
    local relationshipVisible = Conversation.Relationship
        and Conversation.Relationship.IsPresentationVisible
        and Conversation.Relationship.IsPresentationVisible()
        or false
    local input = PNC.Semantics and PNC.Semantics.DialogueInput or nil
    local closed = view and (
        view.closed == true
            or view.lifecycleFinished == true
            or session and (
                session.closed == true
                    or session.lifecycleFinished == true
            )
    ) or false
    local inputAvailable = not closed
        and opened
        and input ~= nil
        and type(input.Submit) == "function"
    local copyValue = Values and Values.copy or copy
    local life = suspended and "suspended"
        or opened and lifecycleState(view, session) or "loaded"
    return {
        schema = "semantic.native_conversation_view.v1",
        version = 1,
        source = "PNC.Conversation.TalkParity",
        talkStart = copyValue(talkStart),
        opening = {
            nodeID = session and session.currentNodeID,
            messages = (opened or suspended)
                and compactProjectionMessages(Runtime.transcript or {})
                or {},
        },
        relationPresentation = {
            visible = relationshipVisible == true,
            value = copyValue(relationship),
            source = "PNC.Conversation.Relationship",
        },
        lifecycle = {
            state = life,
            busy = session and session.busy == true or false,
            pending = session and (
                session.pendingChoices ~= nil
                    or session.pendingNext ~= nil
                    or session.pendingClose == true
            ) or false,
            closing = view and view.closing == true or false,
            closed = closed == true,
            currentNodeID = session and session.currentNodeID,
        },
        responseChannel = {
            revision = (opened or suspended) and (
                state.revision
                or view and view.semanticSuggestionRevision
                or semantic.revision or 0
            ) or 0,
            groupID = (opened or suspended)
                and semantic.currentGroupID or nil,
            rows = rows,
            choiceSurface = opened and copyValue(state)
                or suspended and {
                source = "conversation_suspended",
                presentedCount = 0,
                busy = false,
                pending = false,
                revision = state.revision
                    or view and view.semanticSuggestionRevision
                    or semantic.revision or 0,
            } or {
                source = "conversation_not_open",
                presentedCount = 0,
                busy = false,
                pending = false,
            },
        },
        semanticInput = {
            available = inputAvailable == true,
            reason = inputAvailable and "production_input_ready"
                or suspended and "conversation_suspended"
                or not opened and "conversation_not_open"
                or closed and "conversation_closed"
                or "production_input_unavailable",
        },
    }
end

Internal.resolvedText = resolvedText
Internal.choicesFor = choicesFor
Internal.lifecycleState = lifecycleState
Internal.compactProjectionMessages = compactProjectionMessages

return TalkParity
