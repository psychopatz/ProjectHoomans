-- Inline panel/host session ownership and deferred fallback handoff.
PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Internal = PNC.HoomansLLM.Internal or {}

local Integration = PNC.HoomansLLM
local Internal = Integration.Internal
local Config = Internal.InlineChatConfig
local Runtime = Internal.Runtime
local Inline = Integration.Inline
local Diagnostics = Internal.InlineChatDiagnostics
local Targets = Internal.InlineChatTargets
local Session = Internal.InlineChatSession or {}
Internal.InlineChatSession = Session

function Integration.CloseInline(reason)
    local part = Inline.part
    local hosts = Inline.hosts or {}
    local closed = {}
    Targets.ClearHighlights(0)
    if part then
        if part.blurInput then
            part:blurInput()
        elseif part.entry and part.entry.unfocus then
            part.entry:unfocus()
        end
        if part.setVisible then part:setVisible(false) end
        if part.removeFromUIManager then part:removeFromUIManager() end
    end
    for _, host in ipairs(hosts) do
        if host and not closed[host] and host.close then
            host:close(reason or "inline_closed")
            closed[host] = true
        end
    end
    if Inline.host and not closed[Inline.host] and Inline.host.close then
        Inline.host:close(reason or "inline_closed")
    end
    Inline.part = nil
    Inline.host = nil
    Inline.hosts = nil
    Inline.targets = nil
    Inline.entries = nil
    Inline.target = nil
    Inline.targetID = nil
    Inline.directTarget = nil
    Inline.nextLifecycleAt = nil
    Inline.nextContextRefreshAt = nil
    Inline.nextControlsRefreshAt = nil
    Inline.recoveryStartedAt = nil
    Inline.recoveryDeadlineAt = nil
    Inline.nextRecoveryAt = nil
    Inline.focusAfterTriggerRelease = false
    Inline.triggerBinding = nil
    return true
end

local function clearFallback()
    Inline.pendingTargetEntry = nil
    Inline.pendingFallbackMode = nil
    Inline.pendingFallbackScope = nil
    Inline.pendingFallbackReason = nil
    Inline.pendingFallbackDeadline = nil
    Inline.pendingFallbackNextAttemptAt = nil
end

local function queueFallback(entry, reason)
    local id = tostring(entry and entry.id or "")
    if id == "" then return false end
    Inline.pendingTargetEntry = entry
    Inline.pendingFallbackMode = Config.MODE_NEAREST
    Inline.pendingFallbackScope = Config.SCOPE_OTHER
    if not Inline.part then
        Inline.targetID = id
        Inline.directTarget = entry
        Inline.mode = Config.MODE_NEAREST
        Inline.scope = Config.SCOPE_OTHER
        Diagnostics.LogMode(
            "fallback_queued", Config.MODE_NEAREST, Inline.mode, reason
        )
    else
        Diagnostics.LogMode(
            "fallback_deferred", Config.MODE_NEAREST, Inline.mode, reason
        )
    end
    Inline.pendingFallbackReason = tostring(reason or "conversation_handoff")
    Inline.pendingFallbackDeadline = Runtime.Now() + 5000
    Inline.pendingFallbackNextAttemptAt = 0
    return true
end

function Session.OpenQueuedFallback(binding)
    local entry = Inline.pendingTargetEntry
    if not entry then return false end
    local now = Runtime.Now()
    if now > (tonumber(Inline.pendingFallbackDeadline) or 0) then
        clearFallback()
        return false
    end
    if now < (tonumber(Inline.pendingFallbackNextAttemptAt) or 0) then
        return false
    end
    Inline.pendingFallbackNextAttemptAt = now + 250
    Inline.targetID = tostring(entry.id)
    Inline.directTarget = entry
    Inline.mode = Inline.pendingFallbackMode or Config.MODE_NEAREST
    Inline.scope = Inline.pendingFallbackScope or Config.SCOPE_OTHER
    if Integration.OpenInline(binding) then
        clearFallback()
        return true
    end
    return false
end

function Integration.OpenInlineForTarget(entry, binding)
    if Integration.GetPending and Integration.GetPending()
    then
        return false
    end
    if not queueFallback(entry, "conversation_handoff") then return false end
    local view = Targets.CurrentView()
    if view then
        if view.close then view:close("nameplate_fallback") end
        return true
    end
    return Session.OpenQueuedFallback(binding)
end

function Integration.RequestInlineFallback(entry, reason, view)
    if not queueFallback(entry, reason) then return false end
    local current = Targets.CurrentView()
    if current and (not view or current == view) and current.close then
        current:close("nameplate_fallback")
    end
    return true
end

return Session
