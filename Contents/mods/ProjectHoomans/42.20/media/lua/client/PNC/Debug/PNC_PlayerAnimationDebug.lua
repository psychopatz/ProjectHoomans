require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
require "PNC/Debug/PNC_PlayerAnimationDebugCatalog"

PNC = PNC or {}
PNC.PlayerAnimationDebug = PNC.PlayerAnimationDebug or {}

local Debug = PNC.PlayerAnimationDebug
local Catalog = PNC.PlayerAnimationDebugCatalog
local Core = PNC.Core
local staleActiveAtLoad = Debug.active

-- This debugger deliberately uses native player action/emote context: timed
-- actions for bandaging/NPC treatment and playEmote for the emote state. It
-- does not index raw animation userdata, change track priority, or toggle
-- force override.

Debug.lastResult = Debug.lastResult or nil
Debug.loopEnabled = Debug.loopEnabled == true

local ACTION_EVENTS = {
    Loot = "EventLootItem",
    Bandage = "EventBandage",
}

local function currentEmote(player)
    return player and player.getVariableString
        and player:getVariableString("emote") or nil
end

local function emotePlaying(player)
    return player and player.getVariableBoolean
        and player:getVariableBoolean("EmotePlaying") or false
end

local function cancelActionPressed(player)
    return player and player.pressedCancelAction
        and player:pressedCancelAction() == true
end

local function nowMillis()
    return Core and Core.Now and Core.Now() or 0
end

local function playerName(player)
    return tostring(player:getUsername() or "local")
end

local function resolveLocalPlayer()
    if type(getSpecificPlayer) == "function" then
        local player = getSpecificPlayer(0)
        if player then return player end
    end
    if type(getPlayer) == "function" then return getPlayer() end
    return nil
end

local function validatePlayer(player)
    if not player then return false, "no_local_player" end
    if player.isLocalPlayer and not player:isLocalPlayer() then
        return false, "player_is_not_local"
    end
    if player:isDead() then return false, "player_is_dead" end
    if player.isSeatedInVehicle and player:isSeatedInVehicle() then
        return false, "player_seated_in_vehicle"
    end
    return true
end

local function actionQueue(player)
    return player and ISTimedActionQueue.getTimedActionQueue(player) or nil
end

local function queueLength(queue)
    return queue and queue.queue and #queue.queue or 0
end

local function queueIsIdle(player)
    local queue = actionQueue(player)
    return not queue or queueLength(queue) == 0
end

local function fail(reason)
    Debug.lastResult = {
        ok = false,
        reason = tostring(reason or "preview_failed"),
        at = nowMillis(),
    }
    return false, reason
end

local function markActionInactive(action, reason, ok)
    local active = Debug.active
    if not active or active.action ~= action then return end
    active.finished = true
    Debug.lastResult = {
        ok = ok == true,
        reason = tostring(reason),
        at = nowMillis(),
    }
end

PNCPlayerAnimationDebugAction = ISBaseTimedAction:derive(
    "PNCPlayerAnimationDebugAction")

function PNCPlayerAnimationDebugAction:new(character, entry)
    local action = ISBaseTimedAction.new(self, character)
    action.entry = entry
    action.stopOnWalk = true
    action.stopOnRun = true
    action.stopOnAim = true
    action.useProgressBar = false
    action.ignoreHandsWounds = true
    action.loopRequested = Debug.loopEnabled == true
    -- The action context owns the actual clip duration. This inspection quantum
    -- keeps one-shots alive long enough to inspect; loop mode requeues another
    -- native action when this quantum completes.
    action.maxTime = tonumber(entry.debugDuration) or 120
    return action
end

function PNCPlayerAnimationDebugAction:isValidStart()
    local valid = validatePlayer(self.character)
    return valid == true
end

function PNCPlayerAnimationDebugAction:isValid()
    local valid = validatePlayer(self.character)
    return valid == true
end

function PNCPlayerAnimationDebugAction:start()
    local entry = self.entry
    self:setActionAnim(tostring(entry.action))
    for _, variable in ipairs(entry.variables or {}) do
        if variable.name and variable.value ~= nil then
            local value = variable.value
            if variable.kind == "BOOL" then value = tostring(value) == "true" end
            self:setAnimVariable(variable.name, value)
        end
    end
    self:setOverrideHandModels(nil, nil)
    local event = entry.event or ACTION_EVENTS[entry.action]
    if event then self.character:reportEvent(event) end
end

function PNCPlayerAnimationDebugAction:stop()
    markActionInactive(self, "player_action_stopped", false)
    -- BaseAction.stopTimedActionAnim, called by the engine, clears exactly the
    -- animation variables registered by this action and exits PlayerActionsState.
    -- ISBaseTimedAction.stop also releases this action from the Lua queue.
    ISBaseTimedAction.stop(self)
end

function PNCPlayerAnimationDebugAction:perform()
    if self.loopRequested == true then
        -- Requeue through ISTimedActionQueue instead of relying on the Java
        -- loopAction flag. The latter only keeps the local BaseAction alive;
        -- LuaTimedActionNew has a separate multiplayer ActionManager
        -- transaction which must be completed and recreated normally.
        self:beginAddingActions()
        local nextAction = PNCPlayerAnimationDebugAction:new(
            self.character, self.entry)
        nextAction.loopRequested = true
        ISTimedActionQueue.add(nextAction)
        self:endAddingActions()
        ISBaseTimedAction.perform(self)

        local active = Debug.active
        if active and active.action == self then
            active.action = nextAction
            active.loopCount = (tonumber(active.loopCount) or 0) + 1
            active.startedAt = nowMillis()
            Debug.lastResult = {
                ok = true,
                reason = "player_action_replayed",
                at = nowMillis(),
            }
        end
        return
    end
    markActionInactive(self, "player_action_finished", true)
    ISBaseTimedAction.perform(self)
end

local function stopInternal(reason)
    local active = Debug.active
    if not active then return false, "nothing_playing" end

    if active.mode == "player_emote_state" then
        local player = resolveLocalPlayer()
        -- Do not cancel an emote that replaced this preview. The user may have
        -- started it from the normal radial menu while the lab was open.
        if player == active.body and currentEmote(player) == active.entry.emote
            and emotePlaying(player)
        then
            -- PlayerEmoteState owns clearing `emote` and model restoration on
            -- state exit. Only request the normal state transition here.
            player:setVariable("EmotePlaying", false)
        end
        Debug.active = nil
        Debug.lastResult = {
            ok = true,
            reason = tostring(reason or "stopped"),
            at = nowMillis(),
        }
        print("[PNC][PLAYERANIM] stop reason="
            .. tostring(reason or "stopped"))
        return true, tostring(reason or "stopped")
    end

    local queue = actionQueue(active.body)
    if queue and queue.current == active.action and queueLength(queue) > 1 then
        return fail("debug_action_has_queued_actions")
    end

    -- Stop only the debugger-owned timed action. No StopAllActionQueue and no
    -- raw animation reset is used. The direct Java stop finishes the action
    -- synchronously; the force-stop flag makes the normal character update
    -- remove it as well.
    if active.action then
        active.action:forceStop()
        if active.action.action then active.action.action:stop() end
    end
    Debug.active = nil
    Debug.lastResult = {
        ok = true,
        reason = tostring(reason or "stopped"),
        at = nowMillis(),
    }
    print("[PNC][PLAYERANIM] stop reason=" .. tostring(reason or "stopped"))
    return true, tostring(reason or "stopped")
end

local function begin(entry)
    if type(entry) ~= "table" or entry.playable ~= true
        or (entry.mode ~= "emote"
            and (not entry.action or tostring(entry.action) == ""))
        or (entry.mode == "emote"
            and (not entry.emote or tostring(entry.emote) == ""))
    then
        return fail("selected_entry_has_no_player_action")
    end

    local player = resolveLocalPlayer()
    local valid, reason = validatePlayer(player)
    if not valid then return fail(reason) end
    if not queueIsIdle(player) then return fail("player_action_busy") end

    if Debug.active then
        local stopped = stopInternal("replaced")
        if not stopped then return false, "debug_action_stop_pending" end
    end

    if entry.mode == "emote" then
        player:playEmote(tostring(entry.emote))
        Debug.active = {
            body = player,
            playerName = playerName(player),
            entry = entry,
            startedAt = nowMillis(),
            mode = "player_emote_state",
            loopRequested = Debug.loopEnabled == true,
            loopCount = 0,
        }
        Debug.lastResult = {
            ok = true,
            reason = "player_emote_started",
            at = nowMillis(),
        }
        print("[PNC][PLAYERANIM] play player=" .. playerName(player)
            .. " emote=" .. tostring(entry.emote)
            .. " node=" .. tostring(entry.node)
            .. " clip=" .. tostring(entry.anim))
        return true, "player_emote_started"
    end

    local active = {
        body = player,
        playerName = playerName(player),
        entry = entry,
        startedAt = nowMillis(),
        action = PNCPlayerAnimationDebugAction:new(player, entry),
        mode = "player_action_context",
        loopRequested = Debug.loopEnabled == true,
        loopCount = 0,
    }
    Debug.active = active
    ISTimedActionQueue.add(active.action)
    Debug.lastResult = {
        ok = true,
        reason = "player_action_started",
        at = nowMillis(),
    }
    print("[PNC][PLAYERANIM] play player=" .. active.playerName
        .. " action=" .. tostring(entry.action)
        .. " node=" .. tostring(entry.node)
        .. " clip=" .. tostring(entry.anim))
    return true, "player_action_started"
end

function Debug.Play(entry)
    return begin(entry)
end

function Debug.Stop(reason)
    return stopInternal(reason or "stopped")
end

function Debug.Replay()
    local active = Debug.active
    if not active or not active.entry then return false, "nothing_playing" end
    local entry = active.entry
    local stopped, reason = stopInternal("replay")
    if not stopped then return false, reason end
    return begin(entry)
end

function Debug.IsLoopEnabled()
    return Debug.loopEnabled == true
end

function Debug.SetLoopEnabled(enabled)
    Debug.loopEnabled = enabled == true
    local active = Debug.active
    if active then
        active.loopRequested = Debug.loopEnabled
        if active.action then
            active.action.loopRequested = Debug.loopEnabled
        end
    end
    Debug.lastResult = {
        ok = true,
        reason = Debug.loopEnabled and "loop_enabled" or "loop_disabled",
        at = nowMillis(),
    }
    return true, Debug.loopEnabled and "loop_enabled" or "loop_disabled"
end

function Debug.ToggleLoop()
    return Debug.SetLoopEnabled(not Debug.loopEnabled)
end

-- Frame-level pausing is intentionally not exposed here. Track time setters
-- belong to the raw animation path and are not safe for an IsoPlayer
-- action-context preview.
function Debug.HoldCurrentFrame()
    return false, "action_context_has_no_safe_frame_freeze"
end

function Debug.IsHoldPoseEnabled()
    return false
end

function Debug.SetHoldPose()
    return false, "action_context_has_no_safe_pose_hold"
end

function Debug.Maintain()
    local active = Debug.active
    if not active then return false end

    local player = resolveLocalPlayer()
    if player ~= active.body then
        stopInternal("local_player_changed")
        return false
    end
    local valid, reason = validatePlayer(player)
    if not valid then
        stopInternal(reason)
        return false
    end

    if active.mode == "player_emote_state" then
        local emote = currentEmote(player)
        if emote ~= active.entry.emote and emote ~= nil and emote ~= "" then
            Debug.active = nil
            Debug.lastResult = {
                ok = true,
                reason = "player_emote_finished",
                at = nowMillis(),
            }
            return false
        end
        if not emotePlaying(player) then
            -- PlayerEmoteState uses the same EmotePlaying flag for both a
            -- natural finishing event and the player's cancel input. Check
            -- the native input signal first so loop mode never defeats the
            -- normal cancel control.
            if cancelActionPressed(player) then
                Debug.active = nil
                Debug.lastResult = {
                    ok = true,
                    reason = "player_emote_cancelled",
                    at = nowMillis(),
                }
                return false
            end
            if active.loopRequested then
                -- Re-enter through the native emote API. This preserves the
                -- same SP/MP path used by the emote radial menu and avoids
                -- touching PlayerEmoteState or a raw AnimationTrack.
                player:playEmote(tostring(active.entry.emote))
                active.loopCount = (tonumber(active.loopCount) or 0) + 1
                active.startedAt = nowMillis()
                Debug.lastResult = {
                    ok = true,
                    reason = "player_emote_replayed",
                    at = nowMillis(),
                }
                return true
            end
            Debug.active = nil
            Debug.lastResult = {
                ok = true,
                reason = "player_emote_finished",
                at = nowMillis(),
            }
            return false
        end
        return true
    end

    local queue = actionQueue(player)
    if active.finished or not queue or queue.current ~= active.action then
        Debug.active = nil
        return false
    end
    return true
end

function Debug.Runtime()
    local active = Debug.active
    local currentPlayer = resolveLocalPlayer()
    local playerValid, playerReason = validatePlayer(currentPlayer)
    local busy = currentPlayer and not queueIsIdle(currentPlayer) or false
    if playerValid and busy and not active then playerReason = "player_action_busy" end

    local action = active and active.action or nil
    local javaAction = action and action.action or nil
    local actionTime = javaAction and tonumber(javaAction:getCurrentTime()) or nil
    local actionDuration = action and tonumber(action:getDuration()) or nil
    local entry = active and active.entry or nil
    return {
        active = active ~= nil,
        mode = active and active.mode or nil,
        playerAvailable = currentPlayer ~= nil,
        playerReady = playerValid == true and not busy,
        playerBusy = busy,
        playerReason = playerReason,
        playerName = active and active.playerName
            or (currentPlayer and playerName(currentPlayer) or nil),
        requestedState = entry and entry.state or nil,
        requestedAction = entry and entry.action or nil,
        requestedEmote = entry and entry.emote or nil,
        requestedClip = entry and entry.anim or nil,
        node = entry and entry.node or nil,
        looped = entry and entry.looped == true or false,
        loopRequested = active and active.loopRequested == true or false,
        loopCount = active and tonumber(active.loopCount) or 0,
        actionTime = actionTime,
        actionDuration = actionDuration,
        actionSource = entry and entry.path or nil,
        result = Debug.lastResult,
    }
end

function Debug.Dump()
    local runtime = Debug.Runtime()
    print("[PNC][PLAYERANIM] active=" .. tostring(runtime.active)
        .. " player=" .. tostring(runtime.playerName or "-")
        .. " mode=" .. tostring(runtime.mode or "-")
        .. " action=" .. tostring(runtime.requestedAction or "-")
        .. " emote=" .. tostring(runtime.requestedEmote or "-")
        .. " node=" .. tostring(runtime.node or "-")
        .. " clip=" .. tostring(runtime.requestedClip or "-")
        .. " loop=" .. tostring(runtime.loopRequested)
        .. " repeats=" .. tostring(runtime.loopCount or 0)
        .. " time=" .. tostring(runtime.actionTime or "-"))
    return runtime
end

function Debug.GetCatalog()
    return Catalog
end

local function onTick()
    Debug.Maintain()
end

if Events and Events.OnTick and Events.OnTick.Add and not Debug._tickHook then
    Events.OnTick.Add(onTick)
    Debug._tickHook = true
end

local function onResetLua()
    stopInternal("lua_reset")
end

if Events and Events.OnResetLua and Events.OnResetLua.Add
    and not Debug._resetHook
then
    Events.OnResetLua.Add(onResetLua)
    Debug._resetHook = true
end

if staleActiveAtLoad and Debug.active == staleActiveAtLoad then
    stopInternal("module_reload")
end

return Debug
