-- Mode and recipient-scope transactions for the inline panel.
require "PNC/Commands/PNC_CompanionTargetResolver"

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
local Controls = Internal.InlineChatControls or {}
Internal.InlineChatControls = Controls

local function resetRecovery()
    Inline.recoveryStartedAt = nil
    Inline.recoveryDeadlineAt = nil
    Inline.nextRecoveryAt = nil
end

Integration.ResetInlineRecovery = resetRecovery

function Integration.SetInlineMode(_, mode, part)
    local previousMode = Resolver.NormalizeMode(
        Inline.mode or Config.MODE_NEAREST
    )
    local requestedMode = Resolver.NormalizeMode(mode)
    Diagnostics.LogMode(
        "mode_click", requestedMode, previousMode, "callback_begin"
    )
    if part and part ~= Inline.part then
        Diagnostics.LogMode(
            "mode_rejected", requestedMode, previousMode, "stale_part"
        )
        return false
    end
    if not Inline.part then
        Diagnostics.LogMode(
            "mode_rejected", requestedMode, previousMode, "panel_closed"
        )
        return false
    end
    if Integration.GetPending and Integration.GetPending() then
        Diagnostics.LogMode(
            "mode_rejected", requestedMode, previousMode, "llm_pending"
        )
        return false
    end
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    local resolved = Targets.ResolveRecipients(player, {
        mode = requestedMode,
        cycleNearest = previousMode == Config.MODE_NEAREST
            and requestedMode == Config.MODE_NEAREST,
        selectClosest = previousMode == Config.MODE_NEARBY
            and requestedMode == Config.MODE_NEAREST,
    })
    if not resolved or #resolved.targets == 0 then
        Diagnostics.LogMode(
            "mode_rejected", requestedMode, previousMode,
            "recipient_unavailable"
        )
        return false
    end
    if not Hosts.Rebuild(player, resolved, requestedMode) then
        Diagnostics.LogMode(
            "mode_rejected", requestedMode, previousMode, "host_build_failed"
        )
        return false
    end
    Inline.mode = requestedMode
    Inline.nextLifecycleAt = 0
    Inline.nextContextRefreshAt = 0
    Inline.nextControlsRefreshAt = 0
    resetRecovery()
    Targets.RefreshHighlights(0)
    Inline.part.owner = Inline.host
    Targets.Position(0, player)
    Diagnostics.LogMode(
        "mode_transaction_accepted", requestedMode, Inline.mode, nil
    )
    return true
end

function Integration.SetInlineScope(_, value, part)
    if part and part ~= Inline.part then return false end
    if not Inline.part then return false end
    if Integration.GetPending and Integration.GetPending() then return false end
    local previousScope = Resolver.NormalizeScope(
        Inline.scope or Config.SCOPE_COLONISTS
    )
    local requestedScope = value == true
        and Config.SCOPE_OTHER or Config.SCOPE_COLONISTS
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    local resolved = Targets.ResolveRecipients(player, {
        scope = requestedScope,
        selectClosest = requestedScope ~= previousScope,
    })
    if not resolved or #resolved.targets == 0 then return false end
    if not Hosts.Rebuild(player, resolved, Inline.mode) then return false end
    Inline.scope = requestedScope
    Inline.nextLifecycleAt = 0
    Inline.nextContextRefreshAt = 0
    Inline.nextControlsRefreshAt = 0
    resetRecovery()
    Targets.RefreshHighlights(0)
    Inline.part.owner = Inline.host
    Targets.Position(0, player)
    return true
end

return Controls
