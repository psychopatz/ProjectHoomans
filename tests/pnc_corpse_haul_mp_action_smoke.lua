local T = require "tests/support/test"

local sent = {}
local queue = { queue = {} }
local addedTick
local body = { dragging = false }
local target = {}
local corpse = {}

function body:isDraggingCorpse() return self.dragging end
function body:getSquare() return {} end
function body:isSitOnGround() return false end
function body:getPrimaryHandItem() return nil end
function body:getSecondaryHandItem() return nil end
function body:setDoGrappleLetGo() self.dragging = false end

function target:Grappled(grappler)
    grappler.dragging = true
end

local function newAction(character, object)
    return {
        character = character, corpseBody = object,
        create = function(self)
            self.action = {
                setCustomRemoteTimedActionSync = function(_, value)
                    self.customRemoteSync = value
                end,
            }
        end,
        perform = function(self) self.performed = true end,
        start = function(self) self.started = true end,
        stop = function() end,
    }
end

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return false end },
}
PNC = {
    Const = {
        MODULE = "PNC",
        CMD_CORPSE_HAUL_ACTION = "CorpseHaulAction",
        CMD_CORPSE_HAUL_ACK = "CorpseHaulAck",
    },
    Core = {
        IsClientOnly = function() return true end,
        Now = function() return 1000 end,
    },
    Registry = {
        GetLiveZombie = function() return body end,
    },
    Network = {
        FindZombieByOnlineID = function() return target end,
    },
    Client = {
        Internal = {
            RegisterServerCommand = function() return true end,
        },
    },
}

ISTimedActionQueue = {
    getTimedActionQueue = function() return queue end,
    clear = function() queue.queue = {} end,
    add = function(action)
        queue.queue[#queue.queue + 1] = action
        return action
    end,
}
ISGrabCorpseAction = {
    new = function(_, character, object)
        return newAction(character, object)
    end,
}
ISDropCorpseAction = {
    new = function(_, character)
        return newAction(character, nil)
    end,
}
ISUnequipAction = {
    new = function() return { complete = function() end } end,
}

getSpecificPlayer = function() return {} end
sendClientCommand = function(_, _, command, args)
    sent[#sent + 1] = { command = command, args = args }
end
Events = { OnTick = { Add = function(callback) addedTick = callback end } }

local Actions = T.load("ProjectHoomans", "client",
    "PNC/Actions/PNC_CorpseHaulActions.lua")
local grabArgs = {
    taskId = "corpse_haul:one", npcId = "npc:worker", haulToken = "corpse:one",
}
T.truthy(Actions.QueueGrab(body, corpse, grabArgs),
    "MP grab queues the vanilla action")
local grab = queue.queue[1]
grab:create()
T.truthy(grab.customRemoteSync,
    "MP NPC grapple avoids the IsoPlayer-only remote timed-action path")
grab:perform()
T.equal(sent[#sent].args.event, "grab_request",
    "MP grab asks the server to perform the grapple")

T.truthy(Actions.ReceiveCommand({
    action = "sync_grab", taskId = grabArgs.taskId, npcId = grabArgs.npcId,
    grappleTargetOnlineID = 501,
}), "server grapple sync attaches the local replica")
T.truthy(body.dragging, "local replica reports corpse dragging")

T.truthy(Actions.ReceiveCommand({
    action = "drop", taskId = grabArgs.taskId, npcId = grabArgs.npcId,
}), "MP drop queues after the local grapple sync")
local drop = queue.queue[1]
drop:create()
T.truthy(drop.customRemoteSync,
    "MP drop also avoids the IsoPlayer-only remote timed-action path")
drop:start()
T.equal(sent[#sent].args.event, "drop_request",
    "MP drop asks the server to release the grapple")
T.truthy(Actions.ReceiveCommand({
    action = "sync_drop", taskId = grabArgs.taskId, npcId = grabArgs.npcId,
}), "server release sync completes the local replica")
T.falsy(body.dragging, "local replica releases the dragged corpse")
T.truthy(addedTick, "corpse action bridge registers its retry pump")

T.finish("pnc_corpse_haul_mp_action_smoke")
