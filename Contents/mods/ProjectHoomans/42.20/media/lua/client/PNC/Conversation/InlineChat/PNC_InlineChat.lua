-- Conversation-owned inline (headless) chat adapter facade.
--
-- Core owns the reusable input widget and ConvoEngine owns semantic input/reply
-- processing. This module provides the compact overhead surface on the same
-- conversation/semantic pipeline used by the full conversation UI.
require "PsychopatzCore/Input/PsychopatzKeybinds"
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput"
require "PNC/Commands/PNC_CompanionTargetResolver"
require "PNC/Conversation/InlineChat/PNC_InlineChatConfig"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.InlineChat = PNC.Conversation.InlineChat or {}
PNC.Conversation.InlineChat.Internal = PNC.Conversation.InlineChat.Internal or {}

local Conversation = PNC.Conversation
local InlineChat = Conversation.InlineChat
local Internal = InlineChat.Internal
local Config = Internal.Config
local Text = PsychopatzCore.Conversation.Text
local LLMInput = PsychopatzConversationLLMInput

InlineChat.State = InlineChat.State or {}

local function semanticInput()
    pcall(require, "PNC/ConvoEngine/RuntimeFacade")
    local engine = PNC.ConvoEngine
    local input = engine and engine.DialogueInput or nil
    if input and type(input.Submit) == "function" then return input end
    return nil
end

local function label(key, fallback)
    return Text.Resolve({ key = key, fallback = fallback }, fallback)
end

local function resolveRowLabel(row)
    if type(row) ~= "table" then return "" end
    local raw = row.label or row.text
        or (row.display and (row.display.label or row.display.labelFallback))
        or (row.frame and (row.frame.labelFallback or row.frame.utterance))
        or row.id
    if type(raw) == "table" then
        return Text.Resolve(raw, raw.fallback or raw.text or tostring(row.id or ""))
    end
    return tostring(raw or "")
end

local function isPrebuiltRootRow(row)
    local frame = type(row) == "table" and (row.frame or (row.source and row.source.semanticFrame)) or nil
    local kind = tostring(frame and frame.kind or "")
    local route = tostring(frame and frame.route or "")
    local id = tostring(row and row.id or "")
    if id == "view_dossier" or id == "show_debug_text" then return true end
    if kind == "conversation_category" or route == "conversation_category" then return true end
    if kind == "semantic_group" or kind == "semantic_back_navigation" then return true end
    if kind == "conversation_root_choice" and id ~= "goodbye" and id ~= "ask_name" then
        return true
    end
    return false
end

local function resolveRowTooltip(row)
    if type(row) ~= "table" then return nil end
    local raw = row.tooltip
        or (row.display and (row.display.tooltip or row.display.tooltipFallback))
        or (row.frame and row.frame.tooltipFallback)
        or nil
    if type(raw) == "table" then
        local txt = Text.Resolve(raw, raw.fallback or raw.text or "")
        return (txt ~= "") and txt or nil
    end
    if type(raw) == "string" and raw ~= "" then return raw end
    return nil
end

local function extractSemanticQuickReplies(view)
    if type(view) ~= "table" then return nil end
    local out = {}
    local seen = {}
    local function push(row)
        if #out >= 6 or type(row) ~= "table" then return end
        if isPrebuiltRootRow(row) then return end
        local frame = row.frame or (row.source and row.source.semanticFrame) or nil
        local id = tostring(row.id or (frame and frame.candidateID) or ("reply_" .. tostring(#out + 1)))
        if seen[id] then return end
        local lbl = resolveRowLabel(row)
        if lbl == "" then return end
        seen[id] = true
        out[#out + 1] = {
            id = id,
            label = lbl,
            tooltip = resolveRowTooltip(row),
            enabled = row.enabled ~= false,
            frame = frame,
            action = row.action,
            semanticRole = row.semanticRole or (id == "goodbye" and "farewell" or nil),
            isFarewell = row.isFarewell == true or id == "goodbye",
            variant = row.variant,
            _source = "semantic_host",
        }
    end
    if type(view.semanticSuggestionRows) == "table" and #view.semanticSuggestionRows > 0 then
        for _, row in ipairs(view.semanticSuggestionRows) do push(row) end
    end
    if #out == 0 and type(view.semanticSuggestions) == "table" then
        local proj = view.semanticSuggestions
        local selectedGroup
        for _, group in ipairs(proj.groups or {}) do
            if group.id == proj.currentGroupID then selectedGroup = group; break end
        end
        if not selectedGroup and #(proj.groups or {}) > 0 then
            selectedGroup = proj.groups[1]
        end
        local candidates = (selectedGroup and selectedGroup.candidates) or proj.candidates or {}
        for _, cand in ipairs(candidates) do push(cand) end
    end
    if #out == 0 then return nil end
    return out
end

local function activeQuickReplies(view)
    local surface = PNC.ConvoEngine and PNC.ConvoEngine.CombatResponseSurface or nil
    local active = surface and surface.active or nil
    if type(active) == "table" and type(active.rows) == "table" and #active.rows > 0 then
        local promptNPC = tostring(active.npcID or "")
        local matches = (promptNPC == "")
            or (InlineChat.State and InlineChat.State.mode == Config.MODE_NEARBY)
            or (InlineChat.State and tostring(InlineChat.State.targetID or "") == promptNPC)
        if not matches then
            for _, entry in ipairs(InlineChat.State and InlineChat.State.entries or {}) do
                if tostring(entry and entry.id or "") == promptNPC then
                    matches = true
                    break
                end
            end
        end
        if matches then
            local rows = {}
            for i = 1, #active.rows do
                local r = active.rows[i]
                rows[i] = {
                    id = tostring(r.id or ""),
                    label = resolveRowLabel(r),
                    tooltip = resolveRowTooltip(r),
                    enabled = r.enabled ~= false,
                    semanticRole = r.semanticRole,
                    isFarewell = r.isFarewell,
                    variant = r.variant,
                    _source = "combat_surface",
                }
            end
            InlineChat.State.activeQuickReplies = rows
            return rows
        end
    end
    if InlineChat.State and InlineChat.State.hasUserSubmitted == true then
        local semanticRows = extractSemanticQuickReplies(view or InlineChat.State.host)
        InlineChat.State.activeQuickReplies = semanticRows
        return semanticRows
    end
    InlineChat.State.activeQuickReplies = nil
    return nil
end

local function stateFor(view, part)
    local input = semanticInput()
    local result
    if input and type(input.GetState) == "function" then
        result = input.GetState(view, part)
    else
        local pbrainz = PNC.PBrainZ
        local status, enabled, visible = "", false, true
        if not view or not view.session then
            status = label("UI_PsychopatzConversation_LLM_StatusOpen", "OPEN A CONVERSATION")
        elseif view.session.llmPending
            or view.session.semanticDialoguePending
            or (pbrainz and pbrainz.GetPending and pbrainz.GetPending())
        then
            status = label("UI_PsychopatzConversation_LLM_StatusWaiting", "WAITING FOR NPC RESPONSE...")
        elseif type(view.isConversationInteractive) ~= "function"
            or not view:isConversationInteractive()
        then
            status = label("UI_PsychopatzConversation_LLM_StatusSpeaking", "NPC IS SPEAKING...")
        else
            enabled = true
        end
        result = {
            visible = visible,
            enabled = enabled,
            statusText = status,
            sendKey = "UI_PsychopatzConversation_LLM_Send",
        }
    end
    if type(result) == "table" then
        if InlineChat.State and InlineChat.State.mode == Config.MODE_NEARBY then
            result.hasMultipleTargets = false
        end
        result.quickReplies = activeQuickReplies(view)
    end
    return result
end

local function submitSemanticFirst(view, value, part)
    local input = semanticInput()
    if input and type(input.Submit) == "function" then
        return input.Submit(view, value, part)
    end
    return false, "semantic_input_unavailable"
end

function InlineChat.CreateInputPart(bounds, options)
    options = options or {}
    options.partID = options.partID or "llmInput"
    options.minimumWidth = options.minimumWidth or 280
    options.minimumHeight = options.minimumHeight or 82
    options.title = options.title or {
        key = "UI_PsychopatzConversation_Panel_LLMInput",
        fallback = "TYPE TO TALK",
    }
    options.submit = options.submit or submitSemanticFirst
    options.getState = options.getState or stateFor
    options.resolveText = options.resolveText or label
    options.maxInputLength = options.maxInputLength or Config.MAX_INPUT_LENGTH
    options.submitOnEnter = options.submitOnEnter ~= false
    options.tooltipKey = options.tooltipKey
        or "UI_PsychopatzConversation_LLM_InputTooltip"
    options.sendKey = options.sendKey or "UI_PsychopatzConversation_LLM_Send"
    options.sendTitle = options.sendTitle or "UI_PsychopatzConversation_LLM_Send"
    return LLMInput:new(bounds.x, bounds.y, bounds.width, bounds.height, options)
end

function InlineChat.IsActive()
    return InlineChat.State and InlineChat.State.part ~= nil
end

InlineChat.GetState = stateFor
InlineChat.ResolveText = label
Conversation.CreateInlineInput = InlineChat.CreateInputPart

require "PNC/Conversation/InlineChat/PNC_InlineChatDiagnostics"
require "PNC/Conversation/InlineChat/PNC_InlineChatTargets"
require "PNC/Conversation/InlineChat/PNC_InlineChatHosts"
require "PNC/Conversation/InlineChat/PNC_InlineChatLifecycle"

local Lifecycle = Internal.Lifecycle
Lifecycle.Register()

return InlineChat
