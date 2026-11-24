-- Periodic inline host recovery and lifecycle pump.
require "PNC/Conversation/InlineChat/PNC_InlineChatSession"
require "PNC/Conversation/InlineChat/PNC_InlineChatControls"
require "PNC/Conversation/InlineChat/PNC_InlineChatOpen"
require "PNC/Conversation/InlineChat/PNC_InlineChatLifecycle_Keybind"

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
local Session = Internal.Session
local Lifecycle = Internal.Lifecycle or {}
Internal.Lifecycle = Lifecycle

local function nowMs()
    return (PNC.Core and PNC.Core.Now and PNC.Core.Now())
        or (getTimeInMillis and getTimeInMillis()) or 0
end

local function rebindGroup(activeHosts, activeEntries)
    if not (State.groupConversation and type(State.groupConversation.Rebind) == "function") then
        return
    end
    local rebound = State.groupConversation:Rebind(activeHosts, activeEntries, State.host)
    if not rebound then
        State.groupConversation = nil
        for _, host in ipairs(activeHosts) do
            host.groupConversation = nil
            host.groupMemberID = nil
            host.groupPrimary = nil
        end
    else
        State.host = State.groupConversation:PrimaryView()
        local primary = State.groupConversation:MemberForHost(State.host)
        State.target = primary and primary.entry or State.target
        State.targetID = State.target and tostring(State.target.id or "") or State.targetID
    end
end

local function updateHostLifecycles()
    local hosts, entries = State.hosts or {}, State.entries or {}
    local activeHosts, activeEntries = {}, {}
    local primaryHost, primaryPresent, primaryFailed = State.host, false, false
    local primaryFailureReason, failureReason
    for index, host in ipairs(hosts) do
        local interruption = host and host.updateLifecycle and host:updateLifecycle() or nil
        if not interruption and host and host.session and type(host.session.update) == "function" then
            local wasBusy = host.session.busy == true or #(host.session.queue or {}) > 0
            host.session:update()
            local isBusy = host.session.busy == true or #(host.session.queue or {}) > 0
            if wasBusy ~= isBusy then
                State.nextControlsRefreshAt = 0
            end
        end
        if interruption or (host and host.closed) then
            failureReason = failureReason or interruption or "conversation_interrupted"
            if host == primaryHost then
                primaryFailed = true
                primaryFailureReason = interruption or "conversation_interrupted"
            end
        elseif host then
            activeHosts[#activeHosts + 1] = host
            activeEntries[#activeEntries + 1] = entries[index]
            if host == primaryHost then primaryPresent = true end
        end
    end
    if #activeHosts == 0 then
        State.hosts, State.entries, State.host, State.target, State.groupConversation = {}, {}, nil, nil, nil
        Targets.ClearHighlights(0)
        return false, failureReason or "conversation_interrupted"
    end
    if primaryFailed then
        if State.mode ~= Config.MODE_NEARBY
            or (primaryFailureReason ~= "npc_unavailable" and primaryFailureReason ~= "conversation_interrupted")
        then
            return false, primaryFailureReason or "conversation_interrupted"
        end
        State.host, State.target = activeHosts[1], activeEntries[1]
        State.targetID = State.target and tostring(State.target.id or "") or nil
    elseif not primaryPresent then
        return false, "conversation_interrupted"
    end
    State.hosts, State.entries = activeHosts, activeEntries
    rebindGroup(activeHosts, activeEntries)
    return true
end

local function recoverHosts(player, current)
    if not State.part or not player then return false end
    if current < (tonumber(State.nextRecoveryAt) or 0) then return false end
    if current > (tonumber(State.recoveryDeadlineAt) or 0) then return false end
    State.nextRecoveryAt = current + Config.RECOVERY_INTERVAL_MS
    local resolved = Targets.ResolveRecipients(player, { selectClosest = true })
    if not resolved or #resolved.targets == 0 then return false end
    if not Hosts.Rebuild(player, resolved) then return false end
    InlineChat.ResetRecovery()
    State.nextLifecycleAt = current + Config.LIFECYCLE_INTERVAL_MS
    State.nextContextRefreshAt = current
    State.nextControlsRefreshAt = current
    Targets.RefreshHighlights(0)
    State.part.owner = State.host
    State.part:refreshControls()
    Targets.Position(0, player)
    return true
end

function InlineChat.Update()
    if Targets.CurrentView() then
        if State.part then InlineChat.Close("conversation_opened") end
        return
    end
    if State.pendingTargetEntry then Session.OpenQueuedFallback("conversation_handoff") end
    if not State.part then return end
    local current = nowMs()
    local player = getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
    if current >= (tonumber(State.nextLifecycleAt) or 0) then
        local active, reason = updateHostLifecycles()
        if not active and (reason == "npc_unavailable" or reason == "conversation_interrupted") then
            if not State.recoveryStartedAt then
                State.recoveryStartedAt = current
                State.recoveryDeadlineAt = current + Config.RECOVERY_GRACE_MS
                State.nextRecoveryAt = current
            end
            active = recoverHosts(player, current)
            if not active and current < (tonumber(State.recoveryDeadlineAt) or 0) then
                Targets.RefreshHighlights(0)
                State.part.owner = nil
                State.nextLifecycleAt = current + Config.LIFECYCLE_INTERVAL_MS
                if current >= (tonumber(State.nextControlsRefreshAt) or 0) and State.part.refreshControls then
                    State.part:refreshControls()
                    State.nextControlsRefreshAt = current + Config.CONTROLS_REFRESH_INTERVAL_MS
                end
                Targets.Position(0, player)
                return
            end
        end
        if not active then
            InlineChat.Close(reason)
            return
        end
        InlineChat.ResetRecovery()
        State.nextLifecycleAt = current + Config.LIFECYCLE_INTERVAL_MS
    end
    if current >= (tonumber(State.nextContextRefreshAt) or 0) then
        Hosts.RefreshLocked(player)
        State.nextContextRefreshAt = current + Config.CONTEXT_REFRESH_INTERVAL_MS
    end
    Targets.RefreshHighlights(0)
    State.part.owner = State.host
    State.part.title = Config.TITLE
    if State.part.inputMode
        and Resolver.NormalizeMode(State.part.inputMode) ~= Resolver.NormalizeMode(State.mode or Config.MODE_NEAREST)
    then
        Diagnostics.LogMode("mode_desync", State.part.inputMode, State.mode, "adapter_sync")
    end
    if current >= (tonumber(State.nextControlsRefreshAt) or 0) then
        State.part:refreshControls()
        State.nextControlsRefreshAt = current + Config.CONTROLS_REFRESH_INTERVAL_MS
    end
    Targets.Position(0, player)
    Diagnostics.FocusWhenReady()
end

return Lifecycle
