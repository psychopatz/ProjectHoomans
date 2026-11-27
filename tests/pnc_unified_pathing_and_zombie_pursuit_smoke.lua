local T = require "tests/support/test"

T.addPackagePaths()

local clockMs = 1000
PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        ZOMBIE_AGGRO_ASTAR_PER_SEC = 16,
        ZOMBIE_AGGRO_ASTAR_BURST = 2,
        ZOMBIE_AGGRO_ASTAR_INFLIGHT_MAX = 4,
        ZOMBIE_AGGRO_FINDER_DEDUP_TILES = 2.0,
        ZOMBIE_AGGRO_STALL_MS = 2500,
        ZOMBIE_NPC_PATH_REFRESH_MS = 500,
    },
    Core = {
        Now = function() return clockMs end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx, dy = x2 - x1, y2 - y1
            return (dx * dx) + (dy * dy)
        end,
        IsClientOnly = function() return true end,
    },
    PerformanceScalingDiagnostics = {
        Increment = function() end,
    },
}

-- 1. ZombieAggro.PathPolicy + RequestCoordinatePath (pathToSound)
T.load("ProjectHoomans", "shared", "PNC/Core/Zombies/PNC_ZombieAggro_Update_Core.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Zombies/PNC_ZombieAggro_PathPolicy.lua")

local ZombieAggro = PNC.ZombieAggro
local Policy = ZombieAggro.PathPolicy
Policy.Reset()

local pathStateSingleton = { name = "PathFindState" }
PathFindState = { instance = function() return pathStateSingleton end }

local function makeMockZombie(x, y, z, inPathState)
    local vars = { bPathfind = false }
    local locCalls = {}
    local cancels, resets, stateChanges = 0, 0, 0
    local modData = {}
    local targetX, targetY, targetZ = x, y, z
    local action = inPathState and "pathfind" or "idle"
    local currentState = inPathState and pathStateSingleton or nil
    local behavior = {
        getTargetX = function() return targetX end,
        getTargetY = function() return targetY end,
        getTargetZ = function() return targetZ end,
        cancel = function() cancels = cancels + 1 end,
        reset = function() resets = resets + 1 end,
        pathToLocationF = function(_, fx, fy, fz)
            locCalls[#locCalls + 1] = { x = fx, y = fy, z = fz }
            targetX, targetY, targetZ = fx, fy, fz
        end,
    }
    return {
        locCalls = locCalls,
        modData = modData,
        getCancels = function() return cancels end,
        getResets = function() return resets end,
        getStateChanges = function() return stateChanges end,
        setAction = function(_, a) action = a end,
        setPos = function(_, nx, ny, nz) x, y, z = nx, ny, nz end,
        setFinderTarget = function(_, fx, fy, fz) targetX, targetY, targetZ = fx, fy, fz end,
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
        isDead = function() return false end,
        getModData = function() return modData end,
        getActionStateName = function() return action end,
        getCurrentState = function() return currentState end,
        changeState = function(_, s) currentState = s; stateChanges = stateChanges + 1 end,
        getPathFindBehavior2 = function() return behavior end,
        setVariable = function(_, k, v) vars[k] = v end,
        getVariableBoolean = function(_, k) return vars[k] == true end,
        setPath2 = function() end,
    }
end

-- Idle zombie enters PathFindState with exact float coordinates
local zWalk = makeMockZombie(10, 10, 0, false)
local okWalk, apiWalk = ZombieAggro.RequestCoordinatePath(zWalk, 14.4, 12.7, 0)
T.truthy(okWalk, "RequestCoordinatePath should succeed")
T.equal(apiWalk, "behavior2_pathfind_state", "should use PathFindState")
T.equal(#zWalk.locCalls, 1, "pathToLocationF should be invoked once")
T.near(zWalk.locCalls[1].x, 14.4, 0.001, "exact float x preserved")
T.near(zWalk.locCalls[1].y, 12.7, 0.001, "exact float y preserved")
T.equal(zWalk.getStateChanges(), 1, "enters PathFindState from idle")
T.equal(Policy.State.inflightCount, 1, "tracks inflight A* zombie")

-- Already in PathFindState: seamless update without cancel/reset or state churn
local zPath = makeMockZombie(10, 10, 0, true)
local okPath, apiPath = ZombieAggro.RequestCoordinatePath(zPath, 14.2, 12.1, 1)
T.truthy(okPath, "seamless PathFindState update should succeed")
T.equal(apiPath, "behavior2_pathfind_state", "stays on PathFindState")
T.equal(zPath.getCancels(), 0, "must not cancel active PathFindState")
T.equal(zPath.getResets(), 0, "must not reset active PathFindState")
T.equal(zPath.getStateChanges(), 0, "must not re-enter PathFindState")
T.equal(Policy.State.inflightCount, 2, "inflight tracks second zombie")

-- Finder deduplication skips repath when already heading near target on same floor
zPath:setAction("pathfind")
T.truthy(
    Policy.IsFinderNearGoal(zPath, 15.0, 12.5, 1),
    "finder already near goal should deduplicate"
)
T.falsy(
    Policy.IsFinderNearGoal(zPath, 15.0, 12.5, 0),
    "different floor must not deduplicate"
)

-- Regression: distant player spotted (turnalerted / far lunge) must not steal
-- a zombie that is leased to chase a nearby NPC, while close-range attack yields.
T.load("ProjectHoomans", "shared", "PNC/Core/Zombies/PNC_ZombieAggro_State_Pursuit.lua")
local PursuitInternal = PNC.ZombieAggro.Internal
instanceof = function(obj, cls) return type(obj) == "table" and obj._cls == cls end
local farPlayer = { _cls = "IsoPlayer", getX = function() return 20 end, getY = function() return 10 end, isDead = function() return false end }
local closePlayer = { _cls = "IsoPlayer", getX = function() return 11 end, getY = function() return 10 end, isDead = function() return false end }
local leasedZ = {
    x = 10, y = 10, z = 0, target = farPlayer, action = "turnalerted",
    modData = { PNC_ZombiePursuitOwner = "ProjectHoomans", PNC_ZombiePursuitUntil = 9000 },
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
    getTarget = function(self) return self.target end,
    getActionStateName = function(self) return self.action end,
    getModData = function(self) return self.modData end,
}
T.falsy(
    PursuitInternal.ShouldYieldToNativePlayerAttack(leasedZ, 2000),
    "turnalerted on distant player must not abort NPC pursuit"
)
leasedZ.action = "lunge"
T.falsy(
    PursuitInternal.ShouldYieldToNativePlayerAttack(leasedZ, 2000),
    "distant lunge (>2.5 tiles) while leased to NPC must not steal zombie"
)
leasedZ.target = closePlayer
T.falsy(
    PursuitInternal.ShouldYieldToNativePlayerAttack(leasedZ, 2000),
    "merely walking near an NPC-leased zombie must not steal it without attacking"
)
leasedZ.getAttackedBy = function() return closePlayer end
T.truthy(
    PursuitInternal.ShouldYieldToNativePlayerAttack(leasedZ, 2000),
    "player attacking/shoving an NPC-leased zombie must organically draw aggro"
)
leasedZ.getAttackedBy = function() return nil end
leasedZ.modData = {}
leasedZ.target = farPlayer
T.falsy(
    PursuitInternal.ShouldYieldToNativePlayerAttack(leasedZ, 2000),
    "distant lunge (>2.5 tiles) on unleased zombie must still allow closer NPC acquisition"
)
leasedZ.target = closePlayer
T.truthy(
    PursuitInternal.ShouldYieldToNativePlayerAttack(leasedZ, 2000),
    "close-range lunge (<=2.5 tiles) on unleased zombie yields to player"
)

-- Velocity lead prediction (same floor, moving away)
local leadData = {}
local lx1, ly1 = Policy.ComputeLeadGoal(leadData, 10, 10, 0, 15, 10, 0, 1000)
T.near(lx1, 15, 0.001, "first sample has no lead")
local lx2, ly2 = Policy.ComputeLeadGoal(leadData, 10, 10, 0, 17, 10, 0, 1500)
T.near(lx2, 19, 0.001, "500ms lead capped at +2 tiles")
T.near(ly2, 10, 0.001, "y unchanged")

-- Progress & exponential stall backoff
local progData = {}
T.falsy(Policy.UpdateProgress(zWalk, progData, 1000), "initial sample not stalled")
T.truthy(Policy.UpdateProgress(zWalk, progData, 3600), "no movement for 2.6s is stalled")
local wait1 = Policy.ComputeRepathCooldown(progData, true, false)
local wait2 = Policy.ComputeRepathCooldown(progData, true, false)
T.truthy(wait2 > wait1, "stall backoff should grow exponentially")
zWalk:setPos(11, 10, 0)
T.falsy(Policy.UpdateProgress(zWalk, progData, 4000), "moving resets stall")
T.equal(progData.PNC_AggroBackoffMs, nil, "moving clears backoff")

-- Token bucket caps burst
Policy.Reset()
T.truthy(Policy.ConsumeToken(2000), "burst token 1")
T.truthy(Policy.ConsumeToken(2000), "burst token 2")
T.falsy(Policy.ConsumeToken(2000), "burst token 3 denied")

-- 2. NPC FloorAssist: standable floor snapping, refusal cache, two-stage stair assist
T.load("ProjectHoomans", "shared", "PNC/Core/Pathing/PNC_EnginePathPlanner/PNC_EnginePathPlanner_FloorAssist.lua")
local FloorInternal = PNC.EnginePathPlanner.Internal

local grid = {}
local function key(x, y, z) return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z) end
local function makeSq(x, y, z, solid, free, stairs, building)
    local sq = {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
        TreatAsSolidFloor = function() return solid == true end,
        isFree = function() return free ~= false end,
        HasStairs = function() return stairs == true end,
        getBuilding = function() return building end,
    }
    grid[key(x, y, z)] = sq
    return sq
end

getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            return grid[key(math.floor(x), math.floor(y), math.floor(z))]
        end,
    }
end

local house = { id = "house1" }
makeSq(20, 20, 1, false, true, false, house) -- air on z=1
makeSq(21, 20, 1, true, true, false, house)  -- solid floor 1 tile away
local snapped, didSnap = FloorInternal.SnapToStandableGoal({ x = 20.5, y = 20.5, z = 1 })
T.truthy(didSnap, "air square on z=1 should snap to solid floor")
T.near(snapped.x, 21.5, 0.001, "snapped x")
T.near(snapped.y, 20.5, 0.001, "snapped y")

makeSq(50, 50, 2, false, true, false, house) -- isolated air on z=2
local noFloor, noFloorReason = FloorInternal.SnapToStandableGoal({ x = 50.5, y = 50.5, z = 2 })
T.equal(noFloor, nil, "isolated air on z=2 must be refused")
T.equal(noFloorReason, "target_no_solid_floor", "refusal reason matches")

-- TTL goal-refusal cache
local rec = { id = "npc1", runtime = {} }
FloorInternal.RefuseGoal(rec, { x = 50.5, y = 50.5, z = 2 }, 1000, 10000, "target_no_solid_floor")
local refusedNow = FloorInternal.IsGoalRefused(rec, { x = 50.8, y = 50.2, z = 2 }, 5000)
local refusedLater = FloorInternal.IsGoalRefused(rec, { x = 50.8, y = 50.2, z = 2 }, 12000)
T.truthy(refusedNow, "goal refused within TTL")
T.falsy(refusedLater, "goal refusal expires after TTL")

-- Two-stage stair assist
makeSq(15, 10, 0, true, true, true, house) -- stair on z=0
local npcBody = {
    x = 10.5, y = 10.5, z = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
}
local stage1, stage1Name = FloorInternal.ResolveFloorTransitionTarget(
    rec, npcBody, { x = 21.5, y = 20.5, z = 1 }, 1000
)
T.equal(stage1Name, "stair_approach", "far from stairs should stage stair_approach")
T.near(stage1.x, 15.5, 0.001, "stage1 targets stair x")
T.equal(stage1.z, 0, "stage1 stays on current floor")

npcBody.x, npcBody.y = 15.2, 10.4
local stage2, stage2Name = FloorInternal.ResolveFloorTransitionTarget(
    rec, npcBody, { x = 21.5, y = 20.5, z = 1 }, 1500
)
T.equal(stage2Name, "stair_traverse", "at stairs should stage stair_traverse")
T.equal(stage2.z, 1, "stage2 targets upper floor")

-- 3. MP ClientNativePathController seamless retarget (no cancel/reset mid-stride)
local pathStateInstance = { name = "PathFindState" }
PathFindState = { instance = function() return pathStateInstance end }
PNC.ClientPresenceSync = {
    Internal = {
        NativePathController = {
            BeginMovementLease = function() end,
            LogState = function() end,
            DescribeBody = function() return "" end,
        },
    },
}
T.load("ProjectHoomans", "client", "PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController_Request.lua")
local submitPathRequest = PNC.ClientPresenceSync.Internal.NativePathController.SubmitPathRequest

local cancels, resets, directCalls, stateChanges = 0, 0, 0, 0
local mpBehavior = {
    started = true,
    hasStartedMoving = function(self) return self.started end,
    getIsCancelled = function() return false end,
    cancel = function() cancels = cancels + 1 end,
    reset = function() resets = resets + 1 end,
    pathToLocationF = function() directCalls = directCalls + 1 end,
}
local mpBody = {
    getX = function() return 10 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
    getCurrentState = function() return pathStateInstance end,
    setVariable = function() end,
    changeState = function() stateChanges = stateChanges + 1 end,
    pathToLocationF = function() end,
}
local mpState = { owned = true, failed = false, requestKey = "old" }
submitPathRequest({}, mpBody, mpState, { x = 18, y = 12, z = 0, revision = 2 }, "new", mpBehavior, 2000)
T.equal(cancels, 0, "seamless MP retarget must not cancel active path")
T.equal(resets, 0, "seamless MP retarget must not reset active path")
T.equal(directCalls, 1, "seamless MP retarget updates Behavior2 directly")
T.equal(stateChanges, 0, "already in PathFindState avoids redundant state change")
