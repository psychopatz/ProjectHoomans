-- Inline widget construction and unified semantic-first submit/open actions.
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.InlineChat = PNC.Conversation.InlineChat or {}
PNC.Conversation.InlineChat.Internal = PNC.Conversation.InlineChat.Internal or {}

local InlineChat = PNC.Conversation.InlineChat
local Internal = InlineChat.Internal
local Config = Internal.Config
local Resolver = PNC.CompanionTargetResolver
local State = InlineChat.State
local Diagnostics = Internal.Diagnostics
local Targets = Internal.Targets
local Hosts = Internal.Hosts
local Open = Internal.Open or {}
Internal.Open = Open
local LLMInput = PsychopatzConversationLLMInput

local function reject(reason, details)
    if Diagnostics and Diagnostics.LogOpenRejected then
        Diagnostics.LogOpenRejected(reason, details)
    end
    return false
end

local function semanticInput()
    pcall(require, "PNC/ConvoEngine/RuntimeFacade")
    local engine = PNC.ConvoEngine
    local input = engine and engine.DialogueInput or nil
    if input and type(input.Submit) == "function" then return input end
    return nil
end

function InlineChat.Submit(view, value, part)
    local input = semanticInput()
    local accepted, reason
    if input and type(input.Submit) == "function" then
        accepted, reason = input.Submit(view, value, part)
        if accepted == true then
            State.hasUserSubmitted = true
            local result = view and view.lastSemanticDialogueResult
            local decision = result and result.decision
            local route = decision and decision.route or "deterministic"
            if decision and (decision.branch == "FAREWELL_ACKNOWLEDGED"
                or decision.action == "FAREWELL_ACKNOWLEDGED"
                or decision.closeConversation == true)
            then
                InlineChat.Close("semantic_farewell")
            elseif route == "llm_fallback" then
                InlineChat.Close("message_submitted")
            end
        end
    else
        accepted, reason = false, "semantic_input_unavailable"
    end
    if accepted == true then return true, reason end
    Diagnostics.LogSubmitRejection(view, reason)
    return false, reason
end

function InlineChat.Open(binding)
    local pbrainz = PNC.PBrainZ
    local pending = pbrainz and pbrainz.GetPending and pbrainz.GetPending() or nil
    if pending then
        return reject("request_pending", "npc=" .. tostring(pending.npcID or "unknown"))
    end
    local currentView = Targets.CurrentView()
    if currentView then
        return reject("conversation_active",
            "npc=" .. tostring(currentView.spec and currentView.spec.npcID or "unknown"))
    end
    local player = getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
    if not player then return reject("player_unavailable") end
    if not Resolver then return reject("target_resolver_unavailable") end
    State.mode = Resolver.NormalizeMode(State.mode or Config.MODE_NEAREST)
    State.scope = Resolver.NormalizeScope(State.scope or Config.SCOPE_COLONISTS)
    local resolved = Targets.ResolveRecipients(player)
    local candidate = resolved and resolved.primary
    if not candidate then
        return reject("no_primary_target",
            "mode=" .. tostring(State.mode) .. " scope=" .. tostring(State.scope)
                .. " count=" .. tostring(resolved and #(resolved.targets or {}) or 0))
    end
    if State.part and tostring(State.targetID) == tostring(candidate.id)
        and State.mode == (State.part.inputMode or State.mode)
    then
        Targets.RefreshHighlights(0)
        if State.part.bringToTop then State.part:bringToTop() end
        Diagnostics.PrepareFocus(binding)
        return true
    end
    if State.part then InlineChat.Close("retargeted") end
    local rebuilt, rebuildReason = Hosts.Rebuild(player, resolved)
    if not rebuilt then
        return reject(rebuildReason or "host_rebuild_failed",
            "target=" .. tostring(candidate.id or "unknown"))
    end
    State.hasUserSubmitted = false
    State.nextLifecycleAt = 0
    State.nextContextRefreshAt = 0
    State.nextControlsRefreshAt = 0
    local part = LLMInput:new(0, 0, Config.WIDTH, Config.HEIGHT, {
        owner = State.host,
        partID = "llmInlineInput",
        title = Config.TITLE,
        submit = InlineChat.Submit,
        getState = InlineChat.GetState,
        resolveText = InlineChat.ResolveText,
        maxInputLength = Config.MAX_INPUT_LENGTH,
        submitOnEnter = true,
        tooltipKey = "UI_PsychopatzConversation_LLM_InputTooltip",
        sendKey = "UI_PsychopatzConversation_LLM_Send",
        sendTitle = "UI_PsychopatzConversation_LLM_Send",
        modeButtons = Config.MODE_BUTTONS,
        initialMode = State.mode,
        onModeChanged = InlineChat.SetMode,
        onModeCommitted = Diagnostics.OnModeCommitted,
        onVisualRefresh = Diagnostics.OnVisualRefresh,
        onNativeControlState = Diagnostics.OnNativeControlState,
        toggleButton = Config.SCOPE_TOGGLE,
        initialToggleValue = State.scope == Config.SCOPE_OTHER,
        onToggleChanged = InlineChat.SetScope,
        maxInputLines = 6,
        maxInputHeight = 122,
        showClose = true,
        onClose = function() InlineChat.Close("user_closed") end,
        closeTitle = "X",
    })
    if not part then return reject("input_widget_unavailable") end
    part:initialise()
    part:instantiate()
    part:addToUIManager()
    part:setReveal(1)
    if part.setAlwaysOnTop then part:setAlwaysOnTop(true) end
    State.part = part
    part:refreshControls()
    Targets.RefreshHighlights(0)
    Targets.Position(0, player)
    if part.bringToTop then part:bringToTop() end
    Diagnostics.PrepareFocus(binding)
    return true
end

return Open
