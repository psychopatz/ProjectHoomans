-- Periodic inline host recovery and input-event registration.
require "PsychopatzCore/Input/PsychopatzKeybinds"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_InlineChatSession"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_InlineChatControls"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_InlineChatOpen"

PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Internal = PNC.HoomansLLM.Internal or {}

local Integration = PNC.HoomansLLM
local Internal = Integration.Internal
local Config = Internal.InlineChatConfig
local Runtime = Internal.Runtime
local Resolver = PNC.CompanionTargetResolver
local Keybinds = PsychopatzCore.Keybinds
local Inline = Integration.Inline
local Diagnostics = Internal.InlineChatDiagnostics
local Targets = Internal.InlineChatTargets
local Hosts = Internal.InlineChatHosts
local Session = Internal.InlineChatSession
local Lifecycle = Internal.InlineChatLifecycle or {}
Internal.InlineChatLifecycle = Lifecycle

local function updateHostLifecycles()
    local hosts = Inline.hosts or {}
    local entries = Inline.entries or {}
    local activeHosts = {}
    local activeEntries = {}
    local primaryHost = Inline.host
    local primaryPresent = false
    local primaryFailed = false
    local primaryFailureReason
    local failureReason
    for index, host in ipairs(hosts) do
        local interruption
        if host and host.updateLifecycle then
            interruption = host:updateLifecycle()
        end
        if not interruption and host and host.session
            and type(host.session.update) == "function"
        then
            -- Compact conversations use a headless Core host. Visible views
            -- drive Session:update from their panel loop, so the inline
            -- heartbeat must drive the same queue here or a local semantic
            -- response remains stuck in the "NPC IS SPEAKING" state.
            host.session:update()
        end
        if interruption or host and host.closed then
            failureReason = failureReason
                or interruption or "conversation_interrupted"
            if host == primaryHost then
                primaryFailed = true
                primaryFailureReason = interruption
                    or "conversation_interrupted"
            end
        elseif host then
            activeHosts[#activeHosts + 1] = host
            activeEntries[#activeEntries + 1] = entries[index]
            if host == primaryHost then primaryPresent = true end
        end
    end
    if #activeHosts == 0 then
        Inline.hosts = {}
        Inline.entries = {}
        Inline.host = nil
        Inline.target = nil
        Targets.ClearHighlights(0)
        return false, failureReason or "conversation_interrupted"
    end
    if primaryFailed then
        if Inline.mode ~= Config.MODE_NEARBY
            or (primaryFailureReason ~= "npc_unavailable"
                and primaryFailureReason ~= "conversation_interrupted")
        then
            return false, primaryFailureReason or "conversation_interrupted"
        end
        Inline.host = activeHosts[1]
        Inline.target = activeEntries[1]
        Inline.targetID = Inline.target
            and tostring(Inline.target.id or "") or nil
    elseif not primaryPresent then
        return false, "conversation_interrupted"
    end
    Inline.hosts = activeHosts
    Inline.entries = activeEntries
    return true
end

local function recoverHosts(player, now)
    if not Inline.part or not player then return false end
    if now < (tonumber(Inline.nextRecoveryAt) or 0) then return false end
    if now > (tonumber(Inline.recoveryDeadlineAt) or 0) then return false end
    Inline.nextRecoveryAt = now + Config.RECOVERY_INTERVAL_MS
    local resolved = Targets.ResolveRecipients(player, { selectClosest = true })
    if not resolved or #resolved.targets == 0 then return false end
    if not Hosts.Rebuild(player, resolved) then return false end
    Integration.ResetInlineRecovery()
    Inline.nextLifecycleAt = now + Config.LIFECYCLE_INTERVAL_MS
    Inline.nextContextRefreshAt = now
    Inline.nextControlsRefreshAt = now
    Targets.RefreshHighlights(0)
    Inline.part.owner = Inline.host
    Inline.part:refreshControls()
    Targets.Position(0, player)
    return true
end

function Integration.UpdateInline()
    if Targets.CurrentView() then
        if Inline.part then Integration.CloseInline("conversation_opened") end
        return
    end
    if Inline.pendingTargetEntry then
        Session.OpenQueuedFallback("conversation_handoff")
    end
    if not Inline.part then return end
    local now = Runtime.Now()
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    if now >= (tonumber(Inline.nextLifecycleAt) or 0) then
        local active, reason = updateHostLifecycles()
        if not active and (reason == "npc_unavailable"
            or reason == "conversation_interrupted")
        then
            if not Inline.recoveryStartedAt then
                Inline.recoveryStartedAt = now
                Inline.recoveryDeadlineAt = now + Config.RECOVERY_GRACE_MS
                Inline.nextRecoveryAt = now
            end
            active = recoverHosts(player, now)
            if not active
                and now < (tonumber(Inline.recoveryDeadlineAt) or 0)
            then
                Targets.RefreshHighlights(0)
                Inline.part.owner = nil
                Inline.nextLifecycleAt = now + Config.LIFECYCLE_INTERVAL_MS
                if now >= (tonumber(Inline.nextControlsRefreshAt) or 0)
                    and Inline.part.refreshControls
                then
                    Inline.part:refreshControls()
                    Inline.nextControlsRefreshAt =
                        now + Config.CONTROLS_REFRESH_INTERVAL_MS
                end
                Targets.Position(0, player)
                return
            end
        end
        if not active then
            Integration.CloseInline(reason)
            return
        end
        Integration.ResetInlineRecovery()
        Inline.nextLifecycleAt = now + Config.LIFECYCLE_INTERVAL_MS
    end
    if now >= (tonumber(Inline.nextContextRefreshAt) or 0) then
        Hosts.RefreshLocked(player)
        Inline.nextContextRefreshAt = now + Config.CONTEXT_REFRESH_INTERVAL_MS
    end
    Targets.RefreshHighlights(0)
    Inline.part.owner = Inline.host
    Inline.part.title = Config.TITLE
    if Inline.part.inputMode
        and Resolver.NormalizeMode(Inline.part.inputMode)
            ~= Resolver.NormalizeMode(Inline.mode or Config.MODE_NEAREST)
    then
        Diagnostics.LogMode(
            "mode_desync", Inline.part.inputMode, Inline.mode, "adapter_sync"
        )
    end
    if now >= (tonumber(Inline.nextControlsRefreshAt) or 0) then
        Inline.part:refreshControls()
        Inline.nextControlsRefreshAt = now + Config.CONTROLS_REFRESH_INTERVAL_MS
    end
    Targets.Position(0, player)
    Diagnostics.FocusWhenReady()
end

local function closeOnEscape(key)
    if Inline.part and Keyboard and key == Keyboard.KEY_ESCAPE then
        Integration.CloseInline("escape")
    end
end

function Lifecycle.Register()
    if Keybinds and Keybinds.RegisterPress then
        Keybinds.RegisterPress({
            id = "ProjectHoomans.LLMChat",
            label = "UI_PNC_HoomansLLM_TalkKey",
            tooltip = "UI_PNC_HoomansLLM_TalkTooltip",
            defaultKey = getKeyCode and (tonumber(getKeyCode("V")) or 47)
                or 47,
            isEnabled = function()
                return not (Integration.GetPending
                        and Integration.GetPending())
                    and not Targets.CurrentView()
            end,
            onTrigger = Integration.OpenInline,
        })
    end
    if Events and Events.OnTick and not Integration._inlineTickHookRegistered then
        Events.OnTick.Add(Integration.UpdateInline)
        Integration._inlineTickHookRegistered = true
    end
    if Events and Events.OnKeyPressed
        and not Integration._inlineEscapeHookRegistered
    then
        Events.OnKeyPressed.Add(closeOnEscape)
        Integration._inlineEscapeHookRegistered = true
    end
end

return Lifecycle
