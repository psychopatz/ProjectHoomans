local T = require "tests/support/test"

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local moveCalls = 0
local haltCalls = 0
local registered = {}

PNC = {
    Const = { ORDER_LUMBER = "lumber" },
    Core = {
        Distance = function(x1, y1, x2, y2)
            local dx, dy = x1 - x2, y1 - y2
            return math.sqrt(dx * dx + dy * dy)
        end,
    },
    OrderSystem = {
        RegisterNormalizer = function(kind) registered.normalizer = kind end,
    },
    JobSystem = {
        RegisterOrder = function(kind) registered.order = kind end,
    },
    BehaviorRegistry = {
        Register = function(job) registered.job = job end,
    },
    BehaviorCommon = {
        ClearCombatTarget = function() end,
        MoveRecord = function() moveCalls = moveCalls + 1 end,
        HaltMovement = function() haltCalls = haltCalls + 1 end,
    },
}

local Lumber = T.load("ProjectHoomans", "shared",
    "PNC/Core/Behaviors/PNC_Behavior_Lumber.lua")
T.equal(registered.normalizer, "lumber", "lumber order normalizer registered")
T.equal(registered.order, "lumber", "lumber order registered")
T.equal(registered.job, "Lumber", "lumber behavior registered")

local record = {
    id = "worker:live", x = 0, y = 0, z = 0,
    runtime = {
        lumber = {
            phase = "TRAVEL", approachX = 10.5, approachY = 20.5,
            approachZ = 0, treeX = 10, treeY = 20,
        },
    },
}
local body = {
    getX = function() return 10.5 end,
    getY = function() return 20.5 end,
    getZ = function() return 0 end,
    faceLocationF = function() end,
}

T.truthy(Lumber.TickWork(record, body, {
    operation = "LUMBER", x = 1.5, y = 1.5, z = 0,
}), "live lumber behavior accepts the production order")
T.equal(moveCalls, 0,
    "live lumber does not reissue travel from stale record coordinates")
T.equal(haltCalls, 1,
    "live lumber holds the body at the approach point")

T.finish("pnc_lumber_behavior_smoke")
