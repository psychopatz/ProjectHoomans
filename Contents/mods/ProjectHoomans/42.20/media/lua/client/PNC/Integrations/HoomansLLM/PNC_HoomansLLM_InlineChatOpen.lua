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

function Integration.SubmitInline(view, value, part)
    local accepted, reason = Integration.Submit(view, value, part)
    if accepted == true then
        Integration.CloseInline("message_submitted")
    else
        Diagnostics.LogSubmitRejection(view, reason)
    end
    return accepted, reason
end

function Integration.OpenInline(binding)
    if not Integration.IsBridgeEnabled
        or not Integration.IsBridgeEnabled()
        or Integration.GetPending and Integration.GetPending()
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
