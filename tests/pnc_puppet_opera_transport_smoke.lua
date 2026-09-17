local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
})

local clock = 1000
local sent = {}
local handlers = {}
local queue = { queue = {}, current = nil }
local player
local currentRuntime = {
    active = false,
    owner = nil,
    result = nil,
}

package.preload["TimedActions/WalkToTimedAction"] = function()
    ISWalkToTimedAction = {
        new = function(_, body, square)
            local action = {
                character = body,
                location = square,
            }
            function action:setOnComplete(callback, context)
                self.onComplete = callback
                self.onCompleteContext = context
            end
            function action:forceStop()
                for index, queued in ipairs(queue.queue) do
                    if queued == self then
                        table.remove(queue.queue, index)
                        break
                    end
                end
                if queue.current == self then queue.current = nil end
            end
            return action
        end,
    }
end

package.preload["TimedActions/ISTimedActionQueue"] = function()
    ISTimedActionQueue = {
        getTimedActionQueue = function()
            return queue
        end,
        add = function(action)
            queue.queue[#queue.queue + 1] = action
            if not queue.current then queue.current = action end
        end,
    }
end

PNC = {
    Core = {
        Now = function() return clock end,
        IsClientOnly = function() return true end,
    },
    Const = {
        MODULE = "ProjectHoomans",
        CMD_PUPPET_OPERA_REQUEST = "PuppetOperaRequest",
        CMD_PUPPET_OPERA_STATE = "PuppetOperaState",
        CMD_PUPPET_OPERA_TRACE = "PuppetOperaTrace",
    },
    Client = {
        Internal = {
            RegisterServerCommand = function(command, handler)
                handlers[command] = handler
                return true
            end,
        },
    },
}

PsychopatzCore = {
    Animation = {
        Player = {
            ResolveLocalPlayer = function() return player end,
            Validate = function(body)
                return body ~= nil, body and nil or "player_missing"
            end,
            Play = function(_, entry, options)
                currentRuntime.active = true
                currentRuntime.owner = options.owner
                currentRuntime.result = nil
                currentRuntime.entry = entry
                return true, "player_action_started", {
                    owner = options.owner,
                }
            end,
            Runtime = function()
                return currentRuntime
            end,
            Stop = function()
                currentRuntime.active = false
                currentRuntime.result = {
                    ok = false,
                    reason = "stopped",
                    at = clock,
                }
                return true, "stopped"
            end,
        },
    },
}

Events = {
    OnTick = { Add = function(callback) Events.tick = callback end },
    OnResetLua = { Add = function(callback) Events.reset = callback end },
}

function sendClientCommand(target, module, command, payload)
    sent[#sent + 1] = {
        target = target,
        module = module,
        command = command,
        payload = payload,
    }
end

local square = {
    getX = function() return 99 end,
    getY = function() return 199 end,
    getZ = function() return 0 end,
}

function getCell()
    return {
        getGridSquare = function(_, x, y, z)
            return {
                getX = function() return x end,
                getY = function() return y end,
                getZ = function() return z end,
            }
        end,
    }
end

player = {
    x = 100.5,
    y = 200.5,
    z = 0,
    forwardX = 0,
    forwardY = 1,
}
function player:getX() return self.x end
function player:getY() return self.y end
function player:getZ() return self.z end
function player:getForwardDirectionX() return self.forwardX end
function player:getForwardDirectionY() return self.forwardY end
function player:getVehicle() return nil end
function player:isSeatedInVehicle() return false end
function player:isDead() return false end
function player:isLocalPlayer() return true end
function player:faceLocation(x, y)
    local dx = x - self.x
    local dy = y - self.y
    if math.abs(dx) >= math.abs(dy) then
        self.forwardX = dx >= 0 and 1 or -1
        self.forwardY = 0
    else
        self.forwardX = 0
        self.forwardY = dy >= 0 and 1 or -1
    end
end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/PuppetOpera/PNC_PuppetOpera_Blueprints.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/PuppetOpera/PNC_PuppetOpera_Anchors.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/PuppetOpera/PNC_PuppetOpera_Trace.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/PuppetOpera/PNC_PuppetOpera.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/PuppetOpera/PNC_PuppetOpera_Client.lua"
)

local Opera = PNC.PuppetOpera
local Client = Opera.Client
local blueprint = Opera.GetBlueprint("social.kiss_test")
local plan = Opera.Anchors.BuildPlan(blueprint, player)
T.truthy(plan, "transport test could not build anchor plan")

local previewAccepted = Client.StartPlacementPreview(
    "social.kiss_test",
    nil,
    { npc = "npc-client" },
    "social.kiss_test:preview_pending"
)
T.truthy(previewAccepted, "client did not send the placement preview request")
T.equal(sent[#sent].payload.action, "preview_start",
    "placement preview did not use the preview_start request action")
T.equal(sent[#sent].payload.actors.npc, "npc-client",
    "placement preview did not carry the actor-slot binding map")
T.falsy(sent[#sent].payload.x,
    "placement preview must not send an arbitrary world coordinate")
local pendingStopAccepted = Client.StopPlacementPreview()
T.truthy(pendingStopAccepted,
    "pending placement preview could not be cancelled")
T.equal(sent[#sent].payload.action, "preview_stop",
    "pending placement preview cancellation did not use preview_stop")

previewAccepted = Client.StartPlacementPreview(
    "social.kiss_test",
    nil,
    { npc = "npc-client" },
    "social.kiss_test:preview"
)
T.truthy(previewAccepted, "client could not restart the placement preview")

local previewSnapshot = {
    sessionId = "puppet:preview:1",
    blueprintId = "social.kiss_test",
    revision = 1,
    phase = Opera.Phases.MOVING,
    preview = true,
    actors = {
        player = { target = plan.actors.player },
        npc = { target = plan.actors.npc },
    },
}
Client.ReceiveState(previewSnapshot)
T.equal(queue.current and queue.current.puppetOperaSessionId,
    previewSnapshot.sessionId,
    "placement preview did not create the owned native walk action")
local previewStopAccepted = Client.StopPlacementPreview()
T.truthy(previewStopAccepted,
    "client did not send the placement preview stop request")
T.equal(sent[#sent].payload.action, "preview_stop",
    "placement preview stop used the wrong request action")
previewSnapshot.revision = 2
previewSnapshot.phase = Opera.Phases.RESTORED
previewSnapshot.restored = true
Client.ReceiveState(previewSnapshot)
T.falsy(queue.current,
    "placement preview stop left the native walk action owned")

local accepted = Client.Start("social.kiss_test", "npc-client", false, nil, {
    npc = "npc-client",
})
T.truthy(accepted, "client did not send the start request")
T.equal(sent[#sent].command, PNC.Const.CMD_PUPPET_OPERA_REQUEST,
    "start did not use the Puppet Opera request command")
T.equal(sent[#sent].payload.action, "start",
    "start request action changed")
T.equal(sent[#sent].payload.npcID, "npc-client",
    "start request NPC identity changed")
T.equal(sent[#sent].payload.actors.npc, "npc-client",
    "start request did not carry the actor-slot binding map")
T.falsy(sent[#sent].payload.x,
    "client request must not send an arbitrary world coordinate")

local sessionID = "puppet:client:1"
local snapshot = {
    sessionId = sessionID,
    blueprintId = "social.kiss_test",
    revision = 1,
    phase = Opera.Phases.MOVING,
    actors = {
        player = { target = plan.actors.player },
        npc = { target = plan.actors.npc },
    },
}
T.truthy(handlers[PNC.Const.CMD_PUPPET_OPERA_STATE],
    "client state command was not registered")
Client.ReceiveState(snapshot)
T.equal(queue.current and queue.current.puppetOperaSessionId, sessionID,
    "moving state did not create the owned native walk action")
T.equal(sent[#sent].payload.action, "player_moving",
    "moving state did not acknowledge the server revision")

player.x = plan.actors.player.worldX
player.y = plan.actors.player.worldY
Client.Pump()
T.equal(sent[#sent].payload.action, "player_arrived",
    "client did not acknowledge verified local arrival")

snapshot.revision = 2
snapshot.phase = Opera.Phases.FACING
Client.ReceiveState(snapshot)
Client.Pump()
T.equal(sent[#sent].payload.action, "player_facing",
    "client did not acknowledge verified local facing")

clock = 1200
snapshot.revision = 3
snapshot.phase = Opera.Phases.PLAYING
snapshot.beatIndex = 1
snapshot.beatStartAt = 1500
Client.ReceiveState(snapshot)
Client.Pump()
T.falsy(currentRuntime.entry,
    "player beat started before the synchronized beat timestamp")

clock = 1500
Client.Pump()
T.truthy(currentRuntime.entry,
    "player beat did not start at the synchronized timestamp")
T.equal(sent[#sent].payload.action, "player_beat_started",
    "client did not acknowledge player beat start")

clock = 1501
currentRuntime.active = false
currentRuntime.result = {
    ok = true,
    reason = "player_action_finished",
    at = clock,
}
Client.Pump()
T.equal(sent[#sent].payload.action, "player_beat_finished",
    "client did not acknowledge the completed player beat")

return T.finish("pnc_puppet_opera_transport_smoke")
