local T = require "tests/support/test"

local addedTick
local body = { dragging = false }
local target = {}

function body:isDraggingCorpse() return self.dragging end
function body:setDoGrappleLetGo() self.dragging = false end

function target:Grappled(grappler)
    grappler.dragging = true
end

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return false end },
}
PNC = {
    Const = {
        MODULE = "PNC",
        CMD_CORPSE_HAUL_ACTION = "CorpseHaulAction",
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

Events = { OnTick = { Add = function(callback) addedTick = callback end } }
ISTimedActionQueue = {
    add = function() error("NPC corpse sync must not use timed actions") end,
}

local Sync = T.load("ProjectHoomans", "client",
    "PNC/Networking/PNC_CorpseHaulSync.lua")
local args = {
    taskId = "work:1", npcId = "npc:worker", haulToken = "corpse:one",
}

T.truthy(Sync.ReceiveCommand({
    action = "sync_grab", taskId = args.taskId, npcId = args.npcId,
    grappleTargetOnlineID = 501,
}), "server grapple sync attaches the local replica")
T.truthy(body.dragging, "local replica reports corpse dragging")

T.truthy(Sync.ReceiveCommand({
    action = "sync_drop", taskId = args.taskId, npcId = args.npcId,
}), "server release sync completes the local replica")
T.falsy(body.dragging, "local replica releases the dragged corpse")
T.truthy(addedTick, "corpse sync registers its retry pump")

T.finish("pnc_corpse_haul_mp_action_smoke")
