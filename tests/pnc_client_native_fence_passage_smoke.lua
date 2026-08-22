local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
})

local fence = {}
local fromSquare = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local toSquare = {
    getX = function() return 1 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local position = { x = 0.5, y = 0.5, z = 0 }
local bumpType
local leases = 0

PNC = {
    TraversalQuery = {
        FindPassageToward = function()
            return {
                object = fence,
                fromSquare = fromSquare,
                toSquare = toSquare,
                dirX = 2,
                dirY = 0,
            }
        end,
        IsFence = function(object)
            return object == fence, false
        end,
    },
    PathService = { Internal = {} },
    Animation = {
        PlayBump = function(_, _, value)
            bumpType = value
            return true
        end,
        FinishBump = function() return true end,
    },
    LiveBodyControl = {
        SetAuthoritativePosition = function(_, x, y, z)
            position.x, position.y, position.z = x, y, z
            return true
        end,
    },
    ClientPresenceSync = { Internal = {
        IsLocalZombieController = function() return true end,
        NativePathController = {
            ClearOwnedPath = function() return true end,
            BeginMovementLease = function()
                leases = leases + 1
                return true
            end,
            LogState = function() end,
            DescribeBody = function() return "body" end,
            STALL_TIMEOUT_MS = 2200,
            RETRY_BASE_MS = 180,
            WINDOW_SMASH_IMPACT_MS = 350,
            WINDOW_SMASH_FINISH_MS = 900,
        },
    } },
}

local body = {
    getX = function() return position.x end,
    getY = function() return position.y end,
    getZ = function() return position.z end,
    getSquare = function() return math.floor(position.x) == 0
        and fromSquare or toSquare end,
    setLx = function() end,
    setLy = function() end,
    faceThisObject = function() end,
}

T.load("ProjectHoomans", "client",
    "PNC/PresenceSync/ClientNativePathController/"
        .. "PNC_ClientNativePathController_Passage.lua")

local Controller = PNC.ClientPresenceSync.Internal.NativePathController
local state = {}
local handled, reason = Controller.TryNativePassage(
    { id = "fence-npc" }, body, state,
    { x = 3.5, y = 0.5, z = 0 }, 1000)
T.truthy(handled, "fence intercepted before vanilla path request")
T.equal(reason, "native_fence_climb", "fence passage reason")
T.equal(bumpType, "PNC_LegacyClimbFenceStart", "fence raise scene selected")
T.equal(state.passageAction.kind, "fence_climb", "fence action retained")
T.equal(state.passageAction.phase, "up", "fence starts in raise phase")

handled, reason = Controller.UpdateWindowSmash(body, state, 1200)
T.truthy(handled, "fence action remains active at midpoint")
T.equal(reason, "native_fence_climb", "midpoint action reason")
T.equal(position.x, 0.5, "fence raise holds the contact point")

handled, reason = Controller.UpdateWindowSmash(body, state, 1450)
T.truthy(handled, "fence crossing phase remains active")
T.equal(bumpType, "PNC_LegacyClimbFenceEnd", "fence landing scene selected")
T.equal(state.passageAction.phase, "cross", "fence enters crossing phase")

handled, reason = Controller.UpdateWindowSmash(body, state, 1700)
T.truthy(handled, "fence action remains active during crossing")
T.equal(reason, "native_fence_climb", "crossing action reason")
T.truthy(position.x > 0.5 and position.x < 1.5,
    "owned body advances through the fence scene")

handled, reason = Controller.UpdateWindowSmash(body, state, 2401)
T.truthy(handled, "fence completion handled")
T.equal(reason, "native_fence_crossed", "fence completion reason")
T.equal(position.x, 1.5, "owned body reaches landing square")
T.equal(state.passageAction, nil, "fence action clears after landing")
T.truthy(leases >= 2, "movement ownership remains leased during crossing")

handled, reason = Controller.TryNativePassage(
    { id = "fence-npc" }, body, state,
    { x = -3.5, y = 0.5, z = 0 }, 1950)
T.truthy(handled, "same fence is held during the landing cooldown")
T.equal(reason, "native_fence_cooldown", "same fence cooldown reason")
T.equal(state.passageAction, nil, "cooldown did not start another climb")

T.finish("pnc_client_native_fence_passage_smoke")
