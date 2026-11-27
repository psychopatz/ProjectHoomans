-- Mode and recipient-scope transactions for the inline panel.
require "PNC/Commands/PNC_CompanionTargetResolver"

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
local Controls = Internal.Controls or {}
Internal.Controls = Controls

local function resetRecovery()
    State.recoveryStartedAt = nil
    State.recoveryDeadlineAt = nil
    State.nextRecoveryAt = nil
end

InlineChat.ResetRecovery = resetRecovery

local function hasPendingLLM()
    local pbrainz = PNC.PBrainZ
    return pbrainz and pbrainz.GetPending and pbrainz.GetPending() ~= nil
end

function InlineChat.SetMode(_, mode, part)
    local previousMode = Resolver.NormalizeMode(
        State.mode or Config.DEFAULT_MODE or Config.MODE_NEARBY
    )
    local requestedMode = Resolver.NormalizeMode(mode)
    Diagnostics.LogMode("mode_click", requestedMode, previousMode, "callback_begin")
    if part and part ~= State.part then
        Diagnostics.LogMode("mode_rejected", requestedMode, previousMode, "stale_part")
        return false
    end
    if not State.part then
        Diagnostics.LogMode("mode_rejected", requestedMode, previousMode, "panel_closed")
        return false
    end
    if hasPendingLLM() then
        Diagnostics.LogMode("mode_rejected", requestedMode, previousMode, "llm_pending")
        return false
    end
    if previousMode == requestedMode then
        Diagnostics.LogMode("mode_unchanged", requestedMode, previousMode, "already_selected")
        return true
    end
    local player = getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
    local resolved = Targets.ResolveRecipients(player, {
        mode = requestedMode,
        cycleNearest = false,
        selectClosest = previousMode == Config.MODE_NEARBY and requestedMode == Config.MODE_NEAREST,
    })
    if not resolved or #resolved.targets == 0 then
        Diagnostics.LogMode("mode_rejected", requestedMode, previousMode, "recipient_unavailable")
        return false
    end
    if not Hosts.Rebuild(player, resolved, requestedMode) then
        Diagnostics.LogMode("mode_rejected", requestedMode, previousMode, "host_build_failed")
        return false
    end
    State.mode = requestedMode
    State.nextLifecycleAt = 0
    State.nextContextRefreshAt = 0
    State.nextControlsRefreshAt = 0
    resetRecovery()
    Targets.RefreshHighlights(0)
    State.part.owner = State.host
    if State.part.refreshControls then State.part:refreshControls() end
    Targets.Position(0, player)
    if State.part.focusInput then State.part:focusInput(false) end
    Diagnostics.LogMode("mode_transaction_accepted", requestedMode, State.mode, nil)
    return true
end

function InlineChat.SetScope(_, value, part)
    if part and part ~= State.part then return false end
    if not State.part or hasPendingLLM() then return false end
    local previousScope = Resolver.NormalizeScope(State.scope or Config.SCOPE_COLONISTS)
    local requestedScope = value == true and Config.SCOPE_OTHER or Config.SCOPE_COLONISTS
    local player = getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
    local resolved = Targets.ResolveRecipients(player, {
        scope = requestedScope,
        selectClosest = requestedScope ~= previousScope,
    })
    if not resolved or #resolved.targets == 0 then return false end
    if not Hosts.Rebuild(player, resolved, State.mode) then return false end
    State.scope = requestedScope
    State.nextLifecycleAt = 0
    State.nextContextRefreshAt = 0
    State.nextControlsRefreshAt = 0
    resetRecovery()
    Targets.RefreshHighlights(0)
    State.part.owner = State.host
    if State.part.refreshControls then State.part:refreshControls() end
    Targets.Position(0, player)
    if State.part.focusInput then State.part:focusInput(false) end
    return true
end

return Controls
