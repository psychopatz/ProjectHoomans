-- Puppet-owned local-player movement adapter.

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}
PNC.PuppetOpera.PlayerMovement = PNC.PuppetOpera.PlayerMovement or {}

require "TimedActions/WalkToTimedAction"
require "TimedActions/ISTimedActionQueue"

local Adapter = PNC.PuppetOpera.PlayerMovement
local Anchors = PNC.PuppetOpera.Anchors
local CorePlayer = PsychopatzCore
    and PsychopatzCore.Animation
    and PsychopatzCore.Animation.Player
    or nil

local function player()
    if CorePlayer and CorePlayer.ResolveLocalPlayer then
        return CorePlayer.ResolveLocalPlayer()
    end
    if type(getSpecificPlayer) == "function" then
        return getSpecificPlayer(0)
    end
    return nil
end

local function queueOf(body)
    if not body or not ISTimedActionQueue
        or not ISTimedActionQueue.getTimedActionQueue
    then
        return nil
    end
    return ISTimedActionQueue.getTimedActionQueue(body)
end

local function queueIsIdle(queue)
    return not queue or not queue.queue or #queue.queue == 0
end

local function targetSquare(target)
    if type(getCell) ~= "function" or type(target) ~= "table" then
        return nil
    end
    local cell = getCell()
    if not cell or not cell.getGridSquare then return nil end
    return cell:getGridSquare(
        tonumber(target.x) or 0,
        tonumber(target.y) or 0,
        tonumber(target.z) or 0
    )
end

local function validPlayer(body)
    if CorePlayer and CorePlayer.Validate then
        return CorePlayer.Validate(body)
    end
    if not body then return false, "no_local_player" end
    if body.isDead and body:isDead() then return false, "player_is_dead" end
    if body.isSeatedInVehicle and body:isSeatedInVehicle() then
        return false, "player_seated_in_vehicle"
    end
    return true
end

function Adapter.Start(sessionID, target, callbacks)
    local body = player()
    local valid, reason = validPlayer(body)
    if not valid then return false, reason end
    local queue = queueOf(body)
    if not queueIsIdle(queue) then return false, "player_movement_busy" end
    if type(ISWalkToTimedAction) ~= "table"
        or type(ISWalkToTimedAction.new) ~= "function"
    then
        return false, "native_player_walk_action_unavailable"
    end
    local square = targetSquare(target)
    if not square then return false, "player_anchor_square_unavailable" end

    callbacks = type(callbacks) == "table" and callbacks or {}
    local context = {
        sessionId = tostring(sessionID),
        onArrived = callbacks.onArrived,
    }
    local action = ISWalkToTimedAction:new(body, square)
    action.puppetOperaSessionId = tostring(sessionID)
    action.puppetOperaTarget = {
        x = target.x,
        y = target.y,
        z = target.z,
    }
    if action.setOnComplete then
        action:setOnComplete(function(completion)
            if completion and type(completion.onArrived) == "function" then
                completion.onArrived(completion.sessionId)
            end
        end, context)
    end
    ISTimedActionQueue.add(action)
    Adapter.Active = {
        sessionId = tostring(sessionID),
        body = body,
        action = action,
        target = target,
        startedAt = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
        completed = false,
    }
    return true, "player_movement_requested", Adapter.Active
end

function Adapter.IsOwned(sessionID)
    return Adapter.Active ~= nil
        and tostring(Adapter.Active.sessionId or "") == tostring(sessionID or "")
end

function Adapter.Observe(sessionID)
    local active = Adapter.Active
    if not active or tostring(active.sessionId or "") ~= tostring(sessionID or "") then
        return false, "player_movement_not_owned"
    end
    local body = player()
    if body ~= active.body then return false, "local_player_changed" end
    local valid, reason = validPlayer(body)
    if not valid then return false, reason end
    local queue = queueOf(body)
    if queue and queue.current == active.action then
        if Anchors.IsAt(body, active.target, 0.75) then
            active.completed = true
            return true, "arrived"
        end
        return true, "moving"
    end
    if active.completed or Anchors.IsAt(body, active.target, 0.75) then
        active.completed = true
        return true, "arrived"
    end
    return false, "player_movement_cancelled"
end

function Adapter.Stop(sessionID)
    local active = Adapter.Active
    if not active or tostring(active.sessionId or "") ~= tostring(sessionID or "") then
        return false, "player_movement_not_owned"
    end
    local queue = queueOf(active.body)
    if queue and queue.current == active.action then
        if queue.queue and #queue.queue > 1 then
            return false, "player_movement_has_queued_actions"
        end
        if active.action.forceStop then
            active.action:forceStop()
            return true, "player_movement_stop_requested"
        end
        return false, "player_movement_stop_api_unavailable"
    end
    return false, "player_movement_already_released"
end

function Adapter.Clear(sessionID)
    if Adapter.Active
        and tostring(Adapter.Active.sessionId or "") == tostring(sessionID or "")
    then
        Adapter.Active = nil
        return true
    end
    return false
end

function Adapter.Face(target)
    local body = player()
    local valid, reason = validPlayer(body)
    if not valid then return false, reason end
    if not body.faceLocation then return false, "player_facing_api_unavailable" end
    local point = Anchors.WorldPoint(target)
    if not point then return false, "player_facing_target_unavailable" end
    body:faceLocation(
        point.x,
        point.y
    )
    return true, "player_facing_requested"
end

function Adapter.GetPlayer()
    return player()
end

return Adapter
