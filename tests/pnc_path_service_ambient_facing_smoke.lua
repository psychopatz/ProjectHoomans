local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/"

local now = 1000
local faceCalls = 0
local turnAlertedWrites = 0
local targets = {}
local forward = {
    getX = function() return 1 end,
    getY = function() return 0 end,
}

PNC = {
    Core = {
        Now = function() return now end,
    },
    Const = {
        PRESENCE_LIVE = "live",
    },
    PathService = {
        Internal = {},
    },
}

T.load(ROOT .. "PNC_PathService/PNC_PathService_Context.lua")
T.load(ROOT .. "PNC_PathService/PNC_PathService_Facing.lua")

PNC.PathService.Internal.ensureMoveLane = function(record)
    record.runtime = record.runtime or {}
    record.runtime.pathing = record.runtime.pathing or {}
    return record.runtime.pathing
end

T.load(ROOT .. "PNC_PathService/PNC_PathService_AmbientFacing.lua")

local body = {
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
    getForwardDirection = function() return forward end,
    getActionStateName = function() return "idle" end,
    getPath2 = function() return nil end,
    isAlive = function() return true end,
    isDead = function() return false end,
    faceLocation = function(_, x, y)
        faceCalls = faceCalls + 1
        targets[#targets + 1] = { x = x, y = y }
    end,
    setTurnAlertedValues = function()
        turnAlertedWrites = turnAlertedWrites + 1
    end,
}
local record = {
    alive = true,
    presenceState = "live",
    health = { state = "normal" },
    runtime = {},
}

T.equal(
    PNC.PathService.RequestAmbientFacing(record, body, "follow_owner"),
    false,
    "ambient scan started before its initial delay"
)
T.equal(faceCalls, 0, "ambient scan faced during its initial delay")

now = 5000
T.equal(
    PNC.PathService.RequestAmbientFacing(record, body, "follow_owner"),
    true,
    "ambient scan did not start after its initial delay"
)
T.equal(faceCalls, 1, "ambient scan applied more than one initial facing")
T.truthy(targets[1].x ~= 10 or targets[1].y ~= 20,
    "ambient scan chose the body position as its target")

now = 5200
T.equal(
    PNC.PathService.RequestAmbientFacing(record, body, "follow_owner"),
    true,
    "ambient lease was not retained"
)
T.equal(faceCalls, 1, "ambient lease caused per-frame facing writes")

now = 6000
T.equal(
    PNC.PathService.RequestAmbientFacing(record, body, "follow_owner"),
    false,
    "ambient scan ignored its cooldown"
)
T.truthy(
    PNC.PathService.RequestIdleFacing(record, body, 12, 20, "follow_owner"),
    "normal owner facing did not resume after ambient lease"
)
T.equal(faceCalls, 2, "owner facing was not restored after ambient lease")
T.equal(turnAlertedWrites, 0,
    "ambient facing re-armed vanilla turn-alerted state")

local state = record.runtime.ambientFacing
local function expectIneligible(label, mutate)
    state.activeUntil = 0
    state.nextAt = now
    mutate()
    T.equal(
        PNC.PathService.RequestAmbientFacing(record, body, label),
        false,
        label .. " allowed ambient facing"
    )
end

expectIneligible("moving_follow", function()
    record.runtime.followState = { ownerMoving = true }
end)
record.runtime.followState = nil
expectIneligible("targeted", function()
    record.runtime.target = {}
end)
record.runtime.target = nil
expectIneligible("native_path", function()
    record.runtime.localNavigation = { nativeActive = true }
end)
record.runtime.localNavigation = nil
expectIneligible("turnalerted", function()
    body.getActionStateName = function() return "turnalerted" end
end)

T.equal(faceCalls, 2, "ineligible ambient checks changed facing")
T.finish("pnc_path_service_ambient_facing_smoke")
