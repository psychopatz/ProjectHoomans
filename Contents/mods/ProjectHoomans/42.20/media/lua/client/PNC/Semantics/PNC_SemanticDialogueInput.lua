-- Hybrid conversation input. Lua handles deterministic utterances first;
-- only the policy's explicit fallback route may call PBrainZ.
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput"
require "PsychopatzCore/Semantics/PsychopatzSemanticDialogueRouter"
require "PNC/Semantics/PNC_SemanticDiagnostics"
local DialogueRuntime = PNC and PNC.Semantics
    and PNC.Semantics.SemanticDialogueRuntime or nil
if type(DialogueRuntime) ~= "table" then
    local loadedDialogueRuntime = require
        "PNC/Semantics/PNC_SemanticDialogueRuntime"
    DialogueRuntime = type(loadedDialogueRuntime) == "table"
        and loadedDialogueRuntime
        or PNC and PNC.Semantics
            and PNC.Semantics.SemanticDialogueRuntime
        or {
            IsEnabled = function() return true end,
        }
end
-- Optional module boundary: a legacy package must keep its ordinary
-- deterministic conversation path if this diagnostic spoke is absent.
local handshakeLoaded, SemanticCapabilityHandshake = pcall(require,
    "PNC/Semantics/PNC_SemanticCapabilityHandshake")
if not handshakeLoaded or type(SemanticCapabilityHandshake) ~= "table" then
    SemanticCapabilityHandshake = nil
end
-- The semantic input is a client entry point as well as a shared-composition
-- consumer. Load the Hoomans vocabulary here so a partial composition cannot
-- silently fall through to the generic LLM wait path.
require "PNC/Semantics/PNC_SemanticCatalog"
require "PNC/Semantics/PNC_SemanticConsumptionCatalog"
require "PNC/Semantics/PNC_SemanticDialoguePolicy"
require "PNC/Semantics/PNC_SemanticDialogueResponseCatalog"
require "PNC/Semantics/PNC_SemanticCommandAdapter"
require "PNC/Semantics/PNC_SemanticTaskAdapter"
require "PNC/Semantics/PNC_SemanticInventoryQueryAdapter"

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Policy = PNC.Semantics.DialoguePolicy
local Text = PsychopatzCore.Conversation.Text
local ResponseCatalog = PNC.Semantics.ResponseCatalog
local LocalResponse = PNC.Semantics.LocalResponse
local Diagnostics = PNC.Semantics.SemanticDiagnostics
local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input

if LocalResponse and type(LocalResponse.RegisterTextFallbacks) == "function" then
    LocalResponse.RegisterTextFallbacks()
end
if Policy and type(Policy.RegisterTextFallbacks) == "function" then
    Policy.RegisterTextFallbacks()
end
if ResponseCatalog and type(ResponseCatalog.RegisterTextFallbacks) == "function" then
    -- History may contain semantic keys written before keyed fallbacks were
    -- persisted. Register the current catalog before a full-screen session
    -- loads that history so those old rows remain readable as well.
    ResponseCatalog.RegisterTextFallbacks()
end

if SemanticCapabilityHandshake
    and type(SemanticCapabilityHandshake.Report) == "function"
then
    SemanticCapabilityHandshake.Report()
elseif Diagnostics
    and type(Diagnostics.IsEnabled) == "function"
    and Diagnostics.IsEnabled() == true
    and type(Diagnostics.Record) == "function"
then
    Diagnostics.Record("semantic.capability_handshake", {
        ok = false,
        sourceMarker = "missing",
        failures = { "capability_handshake_module_unavailable" },
    }, { dedupeKey = "semantic-capability-handshake" })
end

Input.VERSION = 2
Input.MAX_INPUT_LENGTH = 4000
Input.Internal = Input.Internal or {}

require "PNC/Semantics/PNC_SemanticDialogueInput_Context"
require "PNC/Semantics/PNC_SemanticDialogueInput_Recovery"
require "PNC/Semantics/PNC_SemanticDialogueInput_QuestResults"
require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation"
require "PNC/Semantics/PNC_SemanticDialogueInput_Actions"
require "PNC/Semantics/PNC_SemanticDialogueInput_GiftPresentation"
require "PNC/Semantics/PNC_SemanticDialogueInput_Gifts"
require "PNC/Semantics/PNC_SemanticDialogueInput_Inventory"
require "PNC/Semantics/PNC_SemanticDialogueInput_Tasks"
require "PNC/Semantics/PNC_SemanticDialogueInput_Trace"
require "PNC/Semantics/PNC_SemanticDialogueInput_ProviderFallback"
require "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle"
local Suggestions = PNC.Semantics.DialogueSuggestions
if type(Suggestions) ~= "table" then
    require "PNC/Semantics/PNC_SemanticDialogueSuggestions"
    Suggestions = PNC.Semantics.DialogueSuggestions
end
Suggestions = type(Suggestions) == "table" and Suggestions or {}

local Internal = Input.Internal

local function semanticFrameKey(view, frame)
    local session = view and view.session or {}
    return tostring(session.conversationID or "")
        .. ":" .. tostring(frame and frame.requestRevision or "")
        .. ":" .. tostring(frame and frame.candidateID or "")
end

local function beginDirectFrame(view, frame)
    if not view or not view.session then
        return false, "conversation_unavailable"
    end
    if type(Internal.Interactive) == "function"
        and not Internal.Interactive(view)
    then
        return false, "conversation_busy"
    end
    local context = view.spec and view.spec.context or nil
    if type(context) == "table"
        and context.pendingConversationRequest ~= nil
    then
        return false, "conversation_request_pending"
    end
    local router = type(Internal.RouterFor) == "function"
        and Internal.RouterFor(view) or nil
    if not router then return false, "semantic_router_unavailable" end
    local key = semanticFrameKey(view, frame)
    view.session.semanticSuggestionReceipts =
        view.session.semanticSuggestionReceipts or {}
    if view.session.semanticSuggestionReceipts[key] then
        return false, "duplicate_suggestion"
    end
    local expected = tonumber(frame and frame.requestRevision)
    local current = tonumber(router.state and router.state.sequence) or 0
    if expected == nil or expected ~= current then
        return false, "stale_suggestion"
    end
    return true, key
end

local function finishDirectFrame(view, key)
    if not view or not view.session or not key then return end
    view.session.semanticSuggestionReceipts =
        view.session.semanticSuggestionReceipts or {}
    view.session.semanticSuggestionReceipts[key] = {
        status = "accepted",
        sequence = key,
    }
end

function Input.Submit(view, value, part)
    if not DialogueRuntime.IsEnabled() then
        return false, "semantic_dialogue_disabled"
    end
    local group = view and view.groupConversation
    if group and type(group.Submit) == "function" then
        return group:Submit(value, part)
    end
    return Internal.SubmitSingle(view, value, part)
end

function Input.SubmitSemanticFrame(view, frame)
    if not DialogueRuntime.IsEnabled() then
        return false, "semantic_dialogue_disabled"
    end
    if type(Suggestions.IsBackFrame) == "function"
        and Suggestions.IsBackFrame(frame)
    then
        local allowed, receiptOrReason = beginDirectFrame(view, frame)
        if not allowed then return false, receiptOrReason end
        if type(Internal.SelectSemanticRoot) ~= "function" then
            return false, "semantic_root_unavailable"
        end
        local accepted, rootReason = Internal.SelectSemanticRoot(view, frame)
        if accepted == true then
            finishDirectFrame(view, receiptOrReason)
        end
        return accepted, rootReason
    end
    if type(Suggestions.IsShortcutFrame) == "function"
        and Suggestions.IsShortcutFrame(frame)
    then
        local allowed, receiptOrReason = beginDirectFrame(view, frame)
        if not allowed then return false, receiptOrReason end
        local value = Suggestions.ResolveFrameText(frame)
        if value == "" then return false, "suggestion_frame_unavailable" end
        -- A shortcut is presentation-only. Submit its canonical utterance
        -- through the same raw parser path as the text box so semantic hub
        -- routing, authority, history, and response handling stay shared.
        local accepted, submitReason = Input.Submit(view, value)
        if accepted == true then
            finishDirectFrame(view, receiptOrReason)
        end
        return accepted, accepted == true and "accepted"
            or submitReason or "semantic_shortcut_rejected"
    end
    if type(Suggestions.IsGroupFrame) == "function"
        and Suggestions.IsGroupFrame(frame)
    then
        local allowed, reason = beginDirectFrame(view, frame)
        if not allowed then return false, reason end
        if type(Internal.SelectSemanticGroup) ~= "function" then
            return false, "semantic_group_unavailable"
        end
        local accepted, groupReason = Internal.SelectSemanticGroup(view, frame)
        if accepted == true then
            finishDirectFrame(view, reason)
        end
        return accepted, groupReason
    end
    local isRootChoice = type(Suggestions.IsConversationRootChoiceFrame)
        == "function" and Suggestions.IsConversationRootChoiceFrame(frame)
    if isRootChoice then
        local allowed, receiptOrReason = beginDirectFrame(view, frame)
        if not allowed then return false, receiptOrReason end
        Input.ActiveView = view
        local composer = PNC.Conversation
            and PNC.Conversation.Composer or nil
        if not composer then return false, "conversation_root_unavailable" end
        local choice
        local resolveReason
        if type(composer.ResolveSemanticRootChoice) == "function" then
            choice, resolveReason = composer.ResolveSemanticRootChoice(
                view, frame
            )
        else
            resolveReason = "conversation_root_resolver_unavailable"
        end
        if not choice then return false, resolveReason end
        local accepted
        local extensions = frame.extensions or {}
        if extensions.route == "conversation_category" then
            if type(composer.RequestCategory) ~= "function" then
                return false, "conversation_category_unavailable"
            end
            local npcID = view.spec and view.spec.npcID or nil
            accepted = composer.RequestCategory(
                npcID,
                extensions.categoryID,
                extensions.choiceID
            )
        elseif view.session and type(view.session.selectChoice) == "function" then
            accepted = view.session:selectChoice(choice)
        else
            return false, "conversation_root_choice_unavailable"
        end
        if accepted == true then finishDirectFrame(view, receiptOrReason) end
        return accepted, accepted == true and "accepted"
            or "conversation_root_choice_rejected"
    end
    if type(Suggestions.IsConversationCategoryFrame) == "function"
        and Suggestions.IsConversationCategoryFrame(frame)
    then
        -- Category suggestions are already typed by the production semantic
        -- layer. Route the canonical frame to the existing conversation
        -- composer/authority boundary; never reparse its display text.
        Input.ActiveView = view
        local composer = PNC.Conversation
            and PNC.Conversation.Composer or nil
        if not composer or type(composer.RequestCategory) ~= "function" then
            return false, "conversation_category_unavailable"
        end
        local allowed, receiptOrReason = beginDirectFrame(view, frame)
        if not allowed then return false, receiptOrReason end
        local npcID = view and view.spec and view.spec.npcID or nil
        local accepted = composer.RequestCategory(
            npcID,
            frame.extensions.categoryID
        )
        if accepted == true then finishDirectFrame(view, receiptOrReason) end
        return accepted, accepted == true and "accepted"
            or "conversation_category_rejected"
    end
    if type(Suggestions.IsConversationChoiceFrame) == "function"
        and Suggestions.IsConversationChoiceFrame(frame)
    then
        Input.ActiveView = view
        local composer = PNC.Conversation
            and PNC.Conversation.Composer or nil
        if not composer or type(composer.RequestChoice) ~= "function" then
            return false, "conversation_choice_unavailable"
        end
        local allowed, receiptOrReason = beginDirectFrame(view, frame)
        if not allowed then return false, receiptOrReason end
        local npcID = view and view.spec and view.spec.npcID or nil
        local extensions = frame.extensions
        local accepted = composer.RequestChoice(
            npcID,
            extensions.blockID,
            extensions.nodeID,
            extensions.choiceID
        )
        if accepted == true then finishDirectFrame(view, receiptOrReason) end
        return accepted, accepted == true and "accepted"
            or "conversation_choice_rejected"
    end
    local group = view and view.groupConversation
    if group and type(group.SubmitSemanticFrame) == "function" then
        return group:SubmitSemanticFrame(frame)
    end
    if type(Suggestions.ResolveFrameText) ~= "function" then
        return false, "suggestion_frame_unavailable"
    end
    if group and type(group.Submit) == "function" then
        return group:Submit(Suggestions.ResolveFrameText(frame), {
            semanticFrame = frame,
        })
    end
    return Internal.SubmitSingle(
        view,
        Suggestions.ResolveFrameText(frame),
        { semanticFrame = frame }
    )
end

function Input.GetState(view)
    if not view or not view.session then
        -- The full-screen view constructs extension parts before it creates
        -- its Session. Keep the field mounted during that short lifecycle
        -- gap; hiding it here makes the widget stay invisible because native
        -- child updates may be skipped while the part is hidden.
        return { visible = view ~= nil, enabled = false, statusText = "" }
    end
    if view.session.llmPending or view.session.semanticDialoguePending then
        return {
            visible = true,
            enabled = false,
            statusText = "",
        }
    end
    return {
        visible = true,
        enabled = Internal.Interactive(view),
        statusText = "",
        sendKey = "llm.send",
    }
end

function Input.ResolveText(key, fallback)
    return Text.Resolve({
        key = key,
        domain = "pnc.system.shared.categories",
        fallback = fallback,
    }, fallback)
end

function Input.CreatePart(bounds, options)
    options = options or {}
    local definition = options.definition
    local definitionPartID = type(definition) == "table"
        and definition.partID or nil
    options.partID = options.partID or definitionPartID or "llmInput"
    if options.title == nil and type(definition) == "table" then
        options.title = definition.title
    end
    options.minimumWidth = options.minimumWidth or 280
    options.minimumHeight = options.minimumHeight or 82
    options.submit = options.submit or Input.Submit
    options.getState = options.getState or Input.GetState
    options.resolveText = options.resolveText or Input.ResolveText
    options.maxInputLength = options.maxInputLength or Input.MAX_INPUT_LENGTH
    options.submitOnEnter = options.submitOnEnter ~= false
    options.tooltipKey = options.tooltipKey or "llm.input_tooltip"
    options.sendKey = options.sendKey or "llm.send"
    options.sendTitle = options.sendTitle or "SEND"
    return PsychopatzConversationLLMInput:new(
        bounds.x, bounds.y, bounds.width, bounds.height, options
    )
end

return Input
