-- Inline panel/host session ownership, clean close dedup, and deferred handoff.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.InlineChat = PNC.Conversation.InlineChat or {}
PNC.Conversation.InlineChat.Internal = PNC.Conversation.InlineChat.Internal or {}

local InlineChat = PNC.Conversation.InlineChat
local Internal = InlineChat.Internal
local Config = Internal.Config
local State = InlineChat.State
local Diagnostics = Internal.Diagnostics
local Targets = Internal.Targets
local Session = Internal.Session or {}
Internal.Session = Session

local SILENT_CLOSE_REASONS = {
    danger = true,
    npc_unavailable = true,
    nameplate_fallback = true,
    lifecycle_error = true,
    replaced = true,
    headless_closed = true,
    conversation_opened = true,
    conversation_handoff = true,
    retargeted = true,
    message_submitted = true,
    conversation_interrupted = true,
    bridge_disabled = true,
    semantic_farewell = true,
    inline_silent_close = true,
    inline_group_silent_close = true,
}

local function nowMs()
    return (PNC.Core and PNC.Core.Now and PNC.Core.Now())
        or (getTimeInMillis and getTimeInMillis()) or 0
end

local function closeReasonForHost(host, baseReason, hadInteraction)
    local r = tostring(baseReason or "inline_closed")
    if SILENT_CLOSE_REASONS[r] then return r end
    if hadInteraction ~= true then return "inline_silent_close" end
    if State.host == nil or host == State.host then return r end
    return "inline_group_silent_close"
end

function InlineChat.Close(reason)
    local part = State.part
    local hosts = State.hosts or {}
    local closed = {}
    local hadInteraction = State.hasUserSubmitted == true
    if State.groupConversation then
        State.groupConversation.closed = true
    end
    Targets.ClearHighlights(0)
    if part then
        if part.blurInput then part:blurInput()
        elseif part.entry and part.entry.unfocus then part.entry:unfocus() end
        if part.setVisible then part:setVisible(false) end
        if part.removeFromUIManager then part:removeFromUIManager() end
    end
    for _, host in ipairs(hosts) do
        if host and not closed[host] and host.close then
            host:close(closeReasonForHost(host, reason, hadInteraction))
            closed[host] = true
        end
    end
    if State.host and not closed[State.host] and State.host.close then
        State.host:close(closeReasonForHost(State.host, reason, hadInteraction))
    end
    State.part = nil
    State.host = nil
    State.hosts = nil
    State.targets = nil
    State.entries = nil
    State.target = nil
    State.targetID = nil
    State.directTarget = nil
    State.groupConversation = nil
    State.hasUserSubmitted = false
    State.nextLifecycleAt = nil
    State.nextContextRefreshAt = nil
    State.nextControlsRefreshAt = nil
    State.recoveryStartedAt = nil
    State.recoveryDeadlineAt = nil
    State.nextRecoveryAt = nil
    State.focusAfterTriggerRelease = false
    State.triggerBinding = nil
    return true
end

local function clearFallback()
    State.pendingTargetEntry = nil
    State.pendingFallbackMode = nil
    State.pendingFallbackScope = nil
    State.pendingFallbackReason = nil
    State.pendingFallbackDeadline = nil
    State.pendingFallbackNextAttemptAt = nil
end

local function queueFallback(entry, reason)
    local id = tostring(entry and entry.id or "")
    if id == "" then return false end
    State.pendingTargetEntry = entry
    State.pendingFallbackMode = Config.MODE_NEAREST
    State.pendingFallbackScope = Config.SCOPE_OTHER
    if not State.part then
        State.targetID = id
        State.directTarget = entry
        State.mode = Config.MODE_NEAREST
        State.scope = Config.SCOPE_OTHER
        Diagnostics.LogMode("fallback_queued", Config.MODE_NEAREST, State.mode, reason)
    else
        Diagnostics.LogMode("fallback_deferred", Config.MODE_NEAREST, State.mode, reason)
    end
    State.pendingFallbackReason = tostring(reason or "conversation_handoff")
    State.pendingFallbackDeadline = nowMs() + 5000
    State.pendingFallbackNextAttemptAt = 0
    return true
end

function Session.OpenQueuedFallback(binding)
    local entry = State.pendingTargetEntry
    if not entry then return false end
    local current = nowMs()
    if current > (tonumber(State.pendingFallbackDeadline) or 0) then
        clearFallback()
        return false
    end
    if current < (tonumber(State.pendingFallbackNextAttemptAt) or 0) then return false end
    State.pendingFallbackNextAttemptAt = current + 250
    State.targetID = tostring(entry.id)
    State.directTarget = entry
    State.mode = State.pendingFallbackMode or Config.MODE_NEAREST
    State.scope = State.pendingFallbackScope or Config.SCOPE_OTHER
    if InlineChat.Open(binding) then
        clearFallback()
        return true
    end
    return false
end

function InlineChat.OpenForTarget(entry, binding)
    local pbrainz = PNC.PBrainZ
    if pbrainz and pbrainz.GetPending and pbrainz.GetPending() then return false end
    if not queueFallback(entry, "conversation_handoff") then return false end
    local view = Targets.CurrentView()
    if view then
        if view.close then view:close("nameplate_fallback") end
        return true
    end
    return Session.OpenQueuedFallback(binding)
end

function InlineChat.RequestFallback(entry, reason, view)
    if not queueFallback(entry, reason) then return false end
    local current = Targets.CurrentView()
    if current and (not view or current == view) and current.close then
        current:close("nameplate_fallback")
    end
    return true
end

return Session
