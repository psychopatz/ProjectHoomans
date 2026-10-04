local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local now = 1000
local clearCalls = 0
local haltCalls = 0
local animationCalls = 0
local facingCalls = 0

PNC = {
    Core = {
        Now = function() return now end,
    },
    Const = {
        FOLLOW_HOLD_REFRESH_MS = 1000,
        FOLLOW_HOLD_FACING_INTERVAL_MS = 750,
    },
    BehaviorCompanion = { Internal = {} },
    Animation = {
        Apply = function() animationCalls = animationCalls + 1 end,
    },
    BehaviorCommon = {
        ClearCombatTarget = function(record)
            clearCalls = clearCalls + 1
            record.runtime.target = nil
        end,
        HaltMovement = function()
            haltCalls = haltCalls + 1
        end,
    },
    PathService = {
        RequestAmbientFacing = function() return false end,
        RequestIdleFacing = function()
            facingCalls = facingCalls + 1
            return true
        end,
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_Internal.lua"
)
local Internal = PNC.BehaviorCompanion.Internal

local record = { runtime = {} }
local owner = {
    getX = function() return 0 end,
    getY = function() return 0 end,
}
local body = {}

Internal.HoldAndFaceOwner(
    record, body, owner, "idle_near_owner", "test_hold", now
)
T.equal(clearCalls, 1, "hold entered with one combat clear")
T.equal(haltCalls, 1, "hold entered with one movement halt")
T.equal(animationCalls, 1, "hold entered with one idle animation write")
T.equal(facingCalls, 1, "hold entered with one facing request")

now = 1200
Internal.HoldAndFaceOwner(
    record, body, owner, "idle_near_owner", "test_hold", now
)
T.equal(clearCalls, 1, "stable hold repeated combat clear")
T.equal(haltCalls, 1, "stable hold repeated movement halt")
T.equal(animationCalls, 1, "stable hold repeated idle animation write")
T.equal(facingCalls, 1, "stable hold repeated facing request")

now = 2000
Internal.HoldAndFaceOwner(
    record, body, owner, "idle_near_owner", "test_hold", now
)
T.equal(clearCalls, 1, "hold refresh repeated combat clear")
T.equal(haltCalls, 1, "hold refresh repeated movement halt")
T.equal(facingCalls, 2, "hold refresh did not refresh facing on schedule")

record.runtime.target = { kind = "threat" }
now = 2100
Internal.HoldAndFaceOwner(
    record, body, owner, "idle_near_owner", "test_hold", now
)
T.equal(clearCalls, 2, "new combat target did not wake hold cleanup")

record.runtime.pathing = { phase = "active" }
now = 2200
Internal.HoldAndFaceOwner(
    record, body, owner, "idle_near_owner", "test_hold", now
)
T.equal(haltCalls, 2, "unexpected route did not repair hold ownership")

T.finish("pnc_follow_hold_budget_smoke")
