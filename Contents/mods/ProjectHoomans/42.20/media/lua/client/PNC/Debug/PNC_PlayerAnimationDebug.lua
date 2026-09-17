require "PsychopatzCore/Animation/PsychopatzPlayerAnimationController"
require "PNC/Debug/PNC_PlayerAnimationDebugCatalog"

PNC = PNC or {}
PNC.PlayerAnimationDebug = PNC.PlayerAnimationDebug or {}

local Debug = PNC.PlayerAnimationDebug
local Catalog = PNC.PlayerAnimationDebugCatalog
local Player = PsychopatzCore.Animation.Player
local OWNER = "ProjectHoomans.PlayerAnimationLab"
local staleHandleAtLoad = Debug.handle

-- Compatibility facade. The reusable playback state lives in
-- PsychopatzCore.Animation.Player; Hoomans supplies only its catalog and
-- action-specific event aliases.
local ACTION_EVENTS = {
    Loot = "EventLootItem",
    Bandage = "EventBandage",
}

local function sync()
    Debug.active = Player.GetActiveRecord()
    Debug.lastResult = Player.lastResult
    Debug.loopEnabled = Player.IsLoopEnabled()
end

function Debug.Play(entry)
    local ok, reason, handle = Player.Play(
        Player.ResolveLocalPlayer(), entry, {
            owner = OWNER,
            actionEvents = ACTION_EVENTS,
        })
    if ok then Debug.handle = handle end
    sync()
    return ok, reason
end

function Debug.Stop(reason)
    local ok, result = Player.Stop(Debug.handle, reason or "stopped")
    if not Player.GetActiveRecord() then Debug.handle = nil end
    sync()
    return ok, result
end

function Debug.Replay()
    local ok, reason, handle = Player.Replay(Debug.handle)
    if ok then Debug.handle = handle end
    sync()
    return ok, reason
end

function Debug.IsLoopEnabled()
    return Player.IsLoopEnabled()
end

function Debug.SetLoopEnabled(enabled)
    local result, reason = Player.SetLoopEnabled(enabled)
    sync()
    return result, reason
end

function Debug.ToggleLoop()
    local result, reason = Player.ToggleLoop()
    sync()
    return result, reason
end

function Debug.HoldCurrentFrame()
    return Player.HoldCurrentFrame()
end

function Debug.IsHoldPoseEnabled()
    return Player.IsHoldPoseEnabled()
end

function Debug.SetHoldPose()
    return Player.SetHoldPose()
end

function Debug.Maintain()
    local result = Player.Maintain()
    sync()
    return result
end

function Debug.Runtime()
    sync()
    return Player.Runtime()
end

function Debug.Dump()
    sync()
    return Player.Dump()
end

function Debug.GetCatalog()
    return Catalog
end

-- Preserve the old class name for consumers that only used it for test
-- instrumentation or type checks.
PNCPlayerAnimationDebugAction = Player.Action

if staleHandleAtLoad then
    Player.Stop(staleHandleAtLoad, "module_reload")
    Debug.handle = nil
end

sync()
return Debug
