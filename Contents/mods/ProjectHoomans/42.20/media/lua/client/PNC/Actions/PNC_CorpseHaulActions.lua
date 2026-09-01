-- Client-side bridge to Build 42's vanilla corpse timed actions.
--
-- The server chooses the task and destination. The client that owns the NPC
-- runs the actual ISGrabCorpseAction/ISDropCorpseAction animation. In a
-- dedicated server, the action's state-changing grapple call is requested
-- from the server because NPC-to-NPC grapple state is not in vanilla zombie
-- replication; the server then sends a local visual sync back to this client.

PNC = PNC or {}
PNC.CorpseHaulActions = PNC.CorpseHaulActions or {}

local function loadVanillaAction(moduleName)
    pcall(require, moduleName)
end

loadVanillaAction("TimedActions/ISTimedActionQueue")
loadVanillaAction("TimedActions/ISGrabCorpseAction")
loadVanillaAction("TimedActions/ISDropCorpseAction")
loadVanillaAction("TimedActions/ISUnequipAction")

local Actions = PNC.CorpseHaulActions
local Core = PNC.Core
local states = setmetatable({}, { __mode = "k" })
local pendingDrops = setmetatable({}, { __mode = "k" })

local function isPureClient()
    return Core and Core.IsClientOnly and Core.IsClientOnly() == true
end

local function queueFor(character)
    return character and ISTimedActionQueue
        and ISTimedActionQueue.getTimedActionQueue(character) or nil
end

local function hasAction(character, taskId)
    local queue = queueFor(character)
    if not queue or not queue.queue then return false end
    for _, action in ipairs(queue.queue) do
        if action and action.PNCCorpseHaulTaskId == tostring(taskId) then
            return true
        end
    end
    return false
end

local function player()
    return getSpecificPlayer and getSpecificPlayer(0) or nil
end

local function ack(state, event, reason)
    local playerObject = player()
    local args = {
        taskId = state.taskId, npcId = state.npcId,
        event = event, reason = reason,
    }
    if Core.IsClientOnly and Core.IsClientOnly() == true then
        if playerObject and sendClientCommand then
            sendClientCommand(playerObject, PNC.Const.MODULE,
                PNC.Const.CMD_CORPSE_HAUL_ACK, args)
        end
    elseif PNC.CorpseHaulService
        and PNC.CorpseHaulService.HandleClientAck
    then
        PNC.CorpseHaulService.HandleClientAck(playerObject, args)
    end
end

local function tag(action, state)
    if not action then return end
    action.PNCCorpseHaulTaskId = state.taskId
    local vanillaStop = action.stop
    action.stop = function(self)
        local current = states[self.character]
        if current and current.taskId == state.taskId
            and current.status == "running"
        then current.status = "failed" end
        if vanillaStop then return vanillaStop(self) end
    end
end

local function forceLocalTimedActionMode(action)
    if not action or not isPureClient() then return end
    local vanillaCreate = action.create
    action.create = function(self)
        if vanillaCreate then vanillaCreate(self) end
        -- Build 42's default remote timed-action path casts the actor to
        -- IsoPlayer. Hoomans actors are IsoZombies, so use the local action
        -- path and send only the validated grapple request ourselves.
        if self.action and self.action.setCustomRemoteTimedActionSync then
            self.action:setCustomRemoteTimedActionSync(true)
        end
    end
end

local function useServerGrappleForGrab(action, state)
    if not action or not isPureClient() then return end
    forceLocalTimedActionMode(action)
    local vanillaPerform = action.perform
    action.perform = function(self)
        local current = states[self.character]
        if current and current.taskId == state.taskId
            and isPureClient()
        then
            -- A client-owned NPC's NPC-to-NPC grapple is not included in the
            -- vanilla zombie packet. The server therefore performs the real
            -- pickUpCorpse call after validating this request.
            if current.status ~= "awaiting_server" then
                current.status = "awaiting_server"
                current.requestedAt = Core.Now and Core.Now() or 0
                ack(current, "grab_request")
            end
            if vanillaPerform then vanillaPerform(self) end
            return true
        end
        if vanillaPerform then return vanillaPerform(self) end
    end
end

local function useServerGrappleForDrop(action, state)
    if not action or not isPureClient() then return end
    forceLocalTimedActionMode(action)
    local vanillaStart = action.start
    action.start = function(self)
        local current = states[self.character]
        if current and current.taskId == state.taskId
            and isPureClient()
        then
            -- Keep the vanilla timed action/animation, but defer the state
            -- transition to the authoritative server.
            if self.action and self.action.setAllowedWhileDraggingCorpses then
                self.action:setAllowedWhileDraggingCorpses(true)
            end
            if current.status ~= "awaiting_server" then
                current.status = "awaiting_server"
                current.requestedAt = Core.Now and Core.Now() or 0
                ack(current, "drop_request")
            end
            return
        end
        if vanillaStart then return vanillaStart(self) end
    end
end

local function resolveBody(npcId)
    local sync = PNC.ClientPresenceSync
    local body = sync and sync.BodyByID and sync.BodyByID[tostring(npcId)] or nil
    if body then return body end
    return PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(npcId) or nil
end

local function resolveCorpse(args)
    local cell = getCell and getCell() or nil
    local square = cell and cell.getGridSquare
        and cell:getGridSquare(math.floor(tonumber(args.sourceX) or 0),
            math.floor(tonumber(args.sourceY) or 0),
            math.floor(tonumber(args.sourceZ) or 0)) or nil
    local found
    local lifecycle = PNC.BodyLifecycle
    if not square or not lifecycle or not lifecycle.Internal
        or not lifecycle.Internal.forEachCorpse
    then return nil end
    lifecycle.Internal.forEachCorpse(square, function(corpse)
        local data = corpse.getModData and corpse:getModData() or nil
        local token = data and (data.PNC_CorpseHaulToken
            or data.PNC_CorpseToken) or nil
        if not found and tostring(token or "") == tostring(args.haulToken or "") then
            found = corpse
        end
    end)
    return found
end

local function queueActions(character, state, actions)
    if not character or not actions or #actions <= 0
        or hasAction(character, state.taskId)
    then return false end
    states[character] = state
    for _, action in ipairs(actions) do
        tag(action, state)
        if ISTimedActionQueue.add(action) == nil then
            state.status = "failed"
            ISTimedActionQueue.clear(character)
            return false
        end
    end
    state.status = "running"
    ack(state, state.kind == "grab" and "grab_queued" or "drop_queued")
    return true
end

function Actions.QueueGrab(character, corpse, args)
    local primary
    local secondary
    local state
    local action
    if not ISTimedActionQueue or not ISGrabCorpseAction
        or not ISUnequipAction
        or not character or not corpse or character:isDraggingCorpse()
    then
        return false
    end
    state = {
        kind = "grab", status = "queued", taskId = tostring(args.taskId),
        npcId = tostring(args.npcId), haulToken = tostring(args.haulToken or ""),
    }
    ISTimedActionQueue.clear(character)
    if character:isSitOnGround() then character:setVariable("forceGetUp", true) end
    primary, secondary = character:getPrimaryHandItem(), character:getSecondaryHandItem()
    if primary then ISUnequipAction:new(character, primary, 1):complete() end
    if secondary and secondary ~= primary then
        ISUnequipAction:new(character, secondary, 1):complete()
    end
    action = ISGrabCorpseAction:new(character, corpse)
    useServerGrappleForGrab(action, state)
    return queueActions(character, state, {
        action,
    })
end

function Actions.QueueDrop(character, args)
    local state
    local action
    if not ISTimedActionQueue or not ISDropCorpseAction
        or not character or not character:isDraggingCorpse()
    then return false end
    state = {
        kind = "drop", status = "queued", taskId = tostring(args.taskId),
        npcId = tostring(args.npcId), haulToken = tostring(args.haulToken or ""),
    }
    ISTimedActionQueue.clear(character)
    action = ISDropCorpseAction:new(character, character:getSquare())
    useServerGrappleForDrop(action, state)
    return queueActions(character, state, {
        action,
    })
end

local function applyServerGrappleSync(character, args)
    local state = states[character]
    local action = tostring(args and args.action or "")
    local target
    local attached
    if not state or state.taskId ~= tostring(args and args.taskId or "") then
        return false
    end
    if action == "sync_drop" then
        if character.isDraggingCorpse and character:isDraggingCorpse()
            and character.setDoGrappleLetGo
        then
            character:setDoGrappleLetGo()
        end
        state.pendingSync = nil
        state.status = "complete"
        pendingDrops[character] = nil
        return true
    end
    if action ~= "sync_grab" then return false end
    if character.isDraggingCorpse and character:isDraggingCorpse() then
        state.pendingSync = nil
        state.status = "dragging"
        return true
    end
    if not PNC.Network or not PNC.Network.FindZombieByOnlineID then
        state.pendingSync = args
        return false
    end
    target = PNC.Network.FindZombieByOnlineID(args.grappleTargetOnlineID)
    if not target or not target.Grappled then
        state.pendingSync = args
        return false
    end
    attached = pcall(function()
        -- Mirror the engine's corpse path on the receiving client. The
        -- server already created this grapple-only zombie and verified the
        -- source corpse; the client only attaches its replica for visuals.
        target:Grappled(character, nil, 1.0, "BwdDrag")
    end)
    if attached and character.isDraggingCorpse
        and character:isDraggingCorpse()
    then
        state.pendingSync = nil
        state.status = "dragging"
        return true
    end
    state.pendingSync = args
    return false
end

function Actions.ReceiveCommand(args)
    local action = tostring(args and args.action or "")
    local character = resolveBody(args and args.npcId)
    local localSync = PNC.ClientPresenceSync
    if not character or not args or tostring(args.taskId or "") == "" then
        return false
    end
    if localSync and localSync.Internal
        and localSync.Internal.IsLocalZombieController
        and not localSync.Internal.IsLocalZombieController(character)
    then
        return false
    end
    if action == "sync_grab" or action == "sync_drop" then
        return applyServerGrappleSync(character, args)
    end
    if action == "grab" then
        local corpse = resolveCorpse(args)
        return Actions.QueueGrab(character, corpse, args)
    end
    if action == "drop" then
        local queued = Actions.QueueDrop(character, args)
        if not queued and isPureClient()
            and character.isDraggingCorpse
            and not character:isDraggingCorpse()
        then
            -- The server's sync_grab and the following drop instruction can
            -- cross on a busy connection. Retry once the local zombie
            -- replica is attachable instead of treating that race as a task
            -- failure.
            pendingDrops[character] = args
            return true
        end
        return queued
    end
    return false
end

if PNC.Client and PNC.Client.Internal
    and PNC.Client.Internal.RegisterServerCommand
then
    PNC.Client.Internal.RegisterServerCommand(
        PNC.Const.CMD_CORPSE_HAUL_ACTION,
        function(args) return Actions.ReceiveCommand(args) end)
end

function Actions.Cancel(character, dropCorpse)
    local state = states[character]
    if state and (state.status == "running"
        or state.status == "awaiting_server")
    then
        state.status = "cancelled"
        ack(state, "failed", "cancelled")
    end
    local queue = queueFor(character)
    if queue and queue.queue then
        for index = #queue.queue, 1, -1 do
            local action = queue.queue[index]
            if state and action and action.PNCCorpseHaulTaskId
                == state.taskId
            then
                if action.forceCancel then action:forceCancel() end
                table.remove(queue.queue, index)
            end
        end
    end
    if dropCorpse and character and character:isDraggingCorpse()
        and not isPureClient()
    then
        character:setDoGrappleLetGo()
    end
    return true
end

local function pump()
    for character, state in pairs(states) do
        if pendingDrops[character] and state.status == "dragging"
            and not hasAction(character, state.taskId)
        then
            local args = pendingDrops[character]
            pendingDrops[character] = nil
            Actions.QueueDrop(character, args)
        end
        if state.pendingSync and state.status == "awaiting_server" then
            applyServerGrappleSync(character, state.pendingSync)
        end
        if state.status == "running" then
            local active = hasAction(character, state.taskId)
            local dragging = character.isDraggingCorpse
                and character:isDraggingCorpse() or false
            if state.kind == "grab" and dragging and not active then
                state.status = "complete"
                ack(state, "grab_complete")
            elseif state.kind == "drop" and not dragging and not active then
                state.status = "complete"
                ack(state, "drop_complete")
            elseif state.kind == "grab" and not active and not dragging then
                state.status = "failed"
                ack(state, "failed", "grab_action_stopped")
            end
        end
    end
end

if Events and Events.OnTick and not Actions.TickHookRegistered then
    Events.OnTick.Add(pump)
    Actions.TickHookRegistered = true
end

return Actions
