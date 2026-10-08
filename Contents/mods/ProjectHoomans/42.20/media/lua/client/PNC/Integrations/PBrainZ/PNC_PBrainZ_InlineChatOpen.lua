-- Inline widget construction and the public submit/open actions.
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput"

PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Internal = PNC.PBrainZ.Internal or {}

local Integration = PNC.PBrainZ
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

local function reject(reason, details)
    if Diagnostics and Diagnostics.LogOpenRejected then
        Diagnostics.LogOpenRejected(reason, details)
    end
    return false
end

local function semanticInput()
    pcall(require, "PNC/PNC_ConversationSemantics")
    local semantics = PNC.Semantics
    local input = semantics and semantics.DialogueInput or nil
    if input and type(input.Submit) == "function" then return input end
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
    local pending = Integration.GetPending and Integration.GetPending() or nil
    if pending then
        return reject("request_pending",
            "npc=" .. tostring(pending.npcID or "unknown"))
    end
    local currentView = Targets.CurrentView()
    if currentView then
        return reject("conversation_active",
            "npc=" .. tostring(currentView.spec
                and currentView.spec.npcID or "unknown"))
    end
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    if not player then return reject("player_unavailable") end
    if not Resolver then return reject("target_resolver_unavailable") end
    Inline.mode = Resolver.NormalizeMode(Inline.mode or Config.MODE_NEAREST)
    Inline.scope = Resolver.NormalizeScope(
        Inline.scope or Config.SCOPE_COLONISTS
    )
    local resolved = Targets.ResolveRecipients(player)
    local candidate = resolved and resolved.primary
    if not candidate then
        return reject("no_primary_target",
            "mode=" .. tostring(Inline.mode)
                .. " scope=" .. tostring(Inline.scope)
                .. " count=" .. tostring(resolved
                    and #(resolved.targets or {}) or 0))
    end
    if Inline.part and tostring(Inline.targetID) == tostring(candidate.id)
        and Inline.mode == (Inline.part.inputMode or Inline.mode)
    then
        Targets.RefreshHighlights(0)
        if Inline.part.bringToTop then Inline.part:bringToTop() end
        Diagnostics.PrepareFocus(binding)
        return true
    end
    if Inline.part then Integration.CloseInline("retargeted") end
    local rebuilt, rebuildReason = Hosts.Rebuild(player, resolved)
    if not rebuilt then
        return reject(rebuildReason or "host_rebuild_failed",
            "target=" .. tostring(candidate.id or "unknown"))
    end
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
    if not part then return reject("input_widget_unavailable") end
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
