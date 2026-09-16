-- Inline widget construction and the public submit/open actions.
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput"

PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Internal = PNC.HoomansLLM.Internal or {}

local Integration = PNC.HoomansLLM
local Internal = Integration.Internal
local Config = Internal.InlineChatConfig
local Resolver = PNC.CompanionTargetResolver
local Inline = Integration.Inline
local Diagnostics = Internal.InlineChatDiagnostics
local Targets = Internal.InlineChatTargets
local Hosts = Internal.InlineChatHosts
local Open = Internal.InlineChatOpen or {}
Internal.InlineChatOpen = Open
local LLMInput = PsychopatzConversationLLMInput

local function semanticInput()
    local semantics = PNC.Semantics
    local input = semantics and semantics.DialogueInput or nil
    local ok
    if input and type(input.Submit) == "function" then return input end
    ok = pcall(
        require,
        "PNC/Semantics/PNC_SemanticDialogueInput"
    )
    semantics = PNC.Semantics
    input = semantics and semantics.DialogueInput or nil
    if ok and input and type(input.Submit) == "function" then
        return input
    end
    return nil
end

function Integration.SubmitInline(view, value, part)
    local input = semanticInput()
    local accepted, reason
    if input and type(input.Submit) == "function" then
        accepted, reason = input.Submit(view, value, part)
        if accepted == true then
            local result = view and view.lastSemanticDialogueResult
            local route = result and result.decision
                and result.decision.route or "deterministic"
            -- A local semantic response is already queued in the headless
            -- session. Keep the inline conversation open for the next turn;
            -- only the remote fallback path needs to detach the widget.
            if route == "llm_fallback" then
                Integration.CloseInline("message_submitted")
            end
        end
    else
        -- Do not bypass the semantic router when a partial composition has
        -- not loaded it yet. The old integration path unconditionally starts
        -- an LLM request and can present a misleading wait for local input.
        accepted, reason = false, "semantic_input_unavailable"
    end
    if accepted == true then
        return true, reason
    end
    Diagnostics.LogSubmitRejection(view, reason)
    return false, reason
end

function Integration.OpenInline(binding)
    if Integration.GetPending and Integration.GetPending()
    then
        return false
    end
    if Targets.CurrentView() then return false end
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    if not player or not Resolver then return false end
    Inline.mode = Resolver.NormalizeMode(Inline.mode or Config.MODE_NEAREST)
    Inline.scope = Resolver.NormalizeScope(
        Inline.scope or Config.SCOPE_COLONISTS
    )
    local resolved = Targets.ResolveRecipients(player)
    local candidate = resolved and resolved.primary
    if not candidate then return false end
    if Inline.part and tostring(Inline.targetID) == tostring(candidate.id)
        and Inline.mode == (Inline.part.inputMode or Inline.mode)
    then
        Targets.RefreshHighlights(0)
        if Inline.part.bringToTop then Inline.part:bringToTop() end
        Diagnostics.PrepareFocus(binding)
        return true
    end
    if Inline.part then Integration.CloseInline("retargeted") end
    if not Hosts.Rebuild(player, resolved) then return false end
    Inline.nextLifecycleAt = 0
    Inline.nextContextRefreshAt = 0
    Inline.nextControlsRefreshAt = 0
    local part = LLMInput:new(0, 0, Config.WIDTH, Config.HEIGHT, {
        owner = Inline.host,
        partID = "llmInlineInput",
        title = Config.TITLE,
        submit = Integration.SubmitInline,
        getState = Integration.GetInlineState,
        resolveText = Integration.ResolveInlineText,
        maxInputLength = Config.MAX_INPUT_LENGTH,
        submitOnEnter = true,
        tooltipKey = "llm.input_tooltip",
        sendKey = "llm.send",
        sendTitle = "SEND",
        modeButtons = Config.MODE_BUTTONS,
        initialMode = Inline.mode,
        onModeChanged = Integration.SetInlineMode,
        onModeCommitted = Diagnostics.OnModeCommitted,
        onVisualRefresh = Diagnostics.OnVisualRefresh,
        onNativeControlState = Diagnostics.OnNativeControlState,
        toggleButton = Config.SCOPE_TOGGLE,
        initialToggleValue = Inline.scope == Config.SCOPE_OTHER,
        onToggleChanged = Integration.SetInlineScope,
        maxInputLines = 6,
        maxInputHeight = 122,
        showClose = true,
        onClose = function() Integration.CloseInline("user_closed") end,
        closeTitle = "X",
    })
    part:initialise()
    part:instantiate()
    part:addToUIManager()
    part:setReveal(1)
    if part.setAlwaysOnTop then part:setAlwaysOnTop(true) end
    Inline.part = part
    part:refreshControls()
    Targets.RefreshHighlights(0)
    Targets.Position(0, player)
    if part.bringToTop then part:bringToTop() end
    Diagnostics.PrepareFocus(binding)
    return true
end

return Open
