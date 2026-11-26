local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

local now = 10000
PNC = {
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        Distance = function(x1, y1, x2, y2)
            local dx = (x2 or 0) - (x1 or 0)
            local dy = (y2 or 0) - (y1 or 0)
            return math.sqrt(dx * dx + dy * dy)
        end,
    },
    Const = {
        PRESENCE_LIVE = "live",
    },
}

local function makeDir(name)
    local d = { _name = name }
    function d:RotRight() return makeDir(name .. "_ROT_R") end
    function d:RotLeft() return makeDir(name .. "_ROT_L") end
    return d
end

IsoDirections = {
    N = makeDir("N"),
    S = makeDir("S"),
    E = makeDir("E"),
    W = makeDir("W"),
    fromString = function(s) return IsoDirections[s] end,
}

-- 1. Load LiveBodyControl State_Presentation + State_Posture
PNC.LiveBodyControl = { Internal = {} }
T.load("ProjectHoomans", "shared",
    "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_State_Presentation.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_State_Posture.lua")

local LBC = PNC.LiveBodyControl

-- Standing actor allows standing idle and body rotation
local standingRecord = {
    id = "npc_1",
    alive = true,
    presenceState = "live",
    orderSpec = { kind = "roam" },
    runtime = {},
}
local standingBody = {
    getX = function() return 10.5 end,
    getY = function() return 20.5 end,
    isSittingOnFurniture = function() return false end,
    isSitOnGround = function() return false end,
    getVariableBoolean = function() return false end,
}
T.equal(LBC.GetPosture(standingRecord, standingBody), "STANDING",
    "idle standing actor resolves to STANDING posture")
T.falsy(LBC.IsBodyRotationLocked(standingRecord, standingBody),
    "standing actor allows body rotation")
T.truthy(LBC.AllowsStandingIdle(standingRecord, standingBody),
    "standing actor allows standing idle scenes")

-- Furniture-seated roaming actor locks body rotation and blocks standing idle
local seatedRecord = {
    id = "npc_2",
    alive = true,
    presenceState = "live",
    orderSpec = { kind = "roam" },
    runtime = {
        roamingSeat = {
            seating = true,
            seatEntered = true,
            phase = "SEATED",
            seatDirection = "E",
            seatSide = "Left",
        },
    },
}
T.equal(LBC.GetPosture(seatedRecord, standingBody), "SEATED_FURNITURE",
    "roaming furniture seat resolves to SEATED_FURNITURE posture")
T.truthy(LBC.IsBodyRotationLocked(seatedRecord, standingBody),
    "furniture-seated actor locks body rotation")
T.falsy(LBC.AllowsStandingIdle(seatedRecord, standingBody),
    "furniture-seated roaming actor blocks standing idle injection")

-- Extensible custom posture provider (e.g. future wall leaning)
LBC.RegisterPostureProvider("test_lean", function(rec)
    if rec and rec.runtime and rec.runtime.leaning then
        return LBC.POSTURE_LEANING
    end
    return nil
end)
local leanRecord = {
    id = "npc_3",
    alive = true,
    presenceState = "live",
    orderSpec = { kind = "roam" },
    runtime = { leaning = true },
}
T.equal(LBC.GetPosture(leanRecord, standingBody), "LEANING",
    "custom posture provider resolves LEANING posture")
T.truthy(LBC.IsBodyRotationLocked(leanRecord, standingBody),
    "leaning posture locks body rotation")
T.falsy(LBC.AllowsStandingIdle(leanRecord, standingBody),
    "leaning posture blocks standing idle injection")
LBC.UnregisterPostureProvider("test_lean")

-- 2. Verify SecondaryChannel.ApplyGaze respects body rotation lock
local facedCount = 0
local gazeBody = {
    getX = function() return 10.0 end,
    getY = function() return 20.0 end,
    faceLocationF = function() facedCount = facedCount + 1 end,
}
local Secondary = T.load("ProjectHoomans", "shared",
    "PNC/Core/Visuals/PNC_SecondaryChannel.lua")
Secondary.RequestGaze(seatedRecord, 15.0, 20.0, 5000, now)
local gazeOk, gazeReason = Secondary.ApplyGaze(seatedRecord, gazeBody, now)
T.falsy(gazeOk, "gaze refuses to rotate furniture-seated body")
T.equal(gazeReason, "BODY_ROTATION_LOCKED",
    "gaze reports BODY_ROTATION_LOCKED while seated")
T.equal(facedCount, 0, "faceLocationF is not called on seated body")

Secondary.RequestGaze(standingRecord, 15.0, 20.0, 5000, now)
local standGazeOk = Secondary.ApplyGaze(standingRecord, gazeBody, now)
T.truthy(standGazeOk, "gaze still rotates standing body")
T.equal(facedCount, 1, "faceLocationF is called on standing body")

-- 3. Verify AnimationScenes.TryIdle blocks roamingSeat even when no scene active
PNC.AnimationScenes = {
    Internal = {
        NextRandom = function() return 0 end,
        ChoosePoolScene = function() return "idle.ambient" end,
    },
    Pools = { idle = { "idle.ambient" } },
    Request = function()
        error("TryIdle must not request idle scene for seated roaming NPC")
    end,
}
T.load("ProjectHoomans", "shared",
    "PNC/Core/Visuals/PNC_AnimationScenes/PNC_AnimationScenes_Idle.lua")
seatedRecord.runtime.nextIdleAnimationSceneAt = 0
local idleTriggered = PNC.AnimationScenes.TryIdle(seatedRecord, standingBody, now)
T.falsy(idleTriggered, "TryIdle refuses to override seated roaming NPC")

-- 4. Verify ApplySeatFacing does NOT apply 90-degree sideways rotation on Left/Right
PNC.FacilityJobsBehaviorInternal = {
    SEAT_STOP_DISTANCE = 0.10,
    SEAT_ARRIVAL_TOLERANCE = 0.14,
    IsFloorSeating = function() return false end,
    AuditSeat = function() end,
    ClearFurnitureOccupancy = function() end,
    MaintainFloorSeatPresentation = function() end,
}
T.load("ProjectHoomans", "shared",
    "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Seating.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Surfaces_Seats.lua")

local appliedFacing = nil
local seatBody = {
    setForwardIsoDirection = function(_, dir) appliedFacing = dir end,
    setSittingOnFurniture = function() end,
    setVariable = function() end,
    setIsResting = function() end,
}
PNC.FacilityJobsBehaviorInternal.ApplySeatFacing(seatBody, IsoDirections.N, "Left")
T.equal(appliedFacing, IsoDirections.N,
    "Left approach faces chair direction N directly (not rotated 90 degrees)")
PNC.FacilityJobsBehaviorInternal.ApplySeatFacing(seatBody, IsoDirections.W, "Right")
T.equal(appliedFacing, IsoDirections.W,
    "Right approach faces chair direction W directly (not rotated 90 degrees)")

appliedFacing = nil
local maintained = PNC.FacilityJobsBehaviorInternal.MaintainFurnitureSeat(
    seatedRecord, seatBody, seatedRecord.runtime.roamingSeat, nil)
T.truthy(maintained, "MaintainFurnitureSeat succeeds while seated")
T.equal(appliedFacing, IsoDirections.E,
    "MaintainFurnitureSeat reasserts chair forward direction E")

-- 5. Verify BuildSeatSpots uses SeatingManager.getTranslation for exact seat anchor
local squares = {}
local chairSquare = {
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
    isSolid = function() return false end,
    isSolidTrans = function() return false end,
    isFree = function() return true end,
}
local approachSq = {
    getX = function() return 11 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
    isSolid = function() return false end,
    isSolidTrans = function() return false end,
    isFree = function() return true end,
}
squares["10:20:0"] = chairSquare
squares["11:20:0"] = approachSq
getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            return squares[tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)]
        end,
    }
end
Vector3f = {
    new = function()
        local v = { vx = 0, vy = 0, vz = 0 }
        function v:x() return self.vx end
        function v:y() return self.vy end
        function v:z() return self.vz end
        return v
    end,
}
local chairObj = {
    getSquare = function() return chairSquare end,
    getSprite = function()
        return { getName = function() return "furniture_seating_outdoor_01_16" end }
    end,
}
SeatingManager = {
    getInstance = function()
        return {
            getTilePositionCount = function() return 1 end,
            getAdjacentPosition = function(_, _, _, dir, side, _, _, outPos)
                if dir == "E" and side == "Front" then
                    outPos.vx, outPos.vy, outPos.vz = 11.15, 20.5, 0
                    return true
                end
                return false
            end,
            getTranslation = function(_, _, dir, outVec)
                if dir == "E" then
                    outVec.vx, outVec.vy, outVec.vz = 0.12, -0.05, 0
                    return outVec
                end
                return nil
            end,
        }
    end,
}
local testChar = {
    getX = function() return 11.2 end,
    getY = function() return 20.5 end,
    canStandAt = function() return true end,
}
local Resources = T.load("ProjectHoomans", "server",
    "PNC/Settlement/PNC_FacilityResources.lua")
local spots = Resources.BuildSeatSpots(testChar, chairObj)
T.equal(#spots, 1, "BuildSeatSpots finds the E:Front seat spot")
T.near(spots[1].x, 11.15, 0.0001, "approach point keeps getAdjacentPosition x")
T.near(spots[1].seatAnchorX, 10.62, 0.0001,
    "seatAnchorX uses exact SeatingManager.getTranslation offset (10 + 0.5 + 0.12)")
T.near(spots[1].seatAnchorY, 20.45, 0.0001,
    "seatAnchorY uses exact SeatingManager.getTranslation offset (20 + 0.5 - 0.05)")

-- 6. Verify TickOwnership still ticks AnimationScenes while roamingSeat lease is active
local animTicked = 0
PNC.TaskLeaseService = {
    Get = function(id) return id == "lease_1" and { leaseId = "lease_1" } or nil end,
}
PNC.AutonomyExecutors = { RoamingSeat = {} }
PNC.BehaviorSystem = {
    Internal = {
        TickOwnership = {
            AnimationScenes = {
                InterruptForSafety = function() end,
                Tick = function()
                    animTicked = animTicked + 1
                    return true
                end,
            },
            choreographyOwnsBehavior = function() return false end,
        },
    },
}
T.load("ProjectHoomans", "shared",
    "PNC/Core/Behaviors/PNC_BehaviorSystem_Tick_Ownership.lua")
local leasedSeatRecord = {
    id = "npc_leased",
    runtime = {
        roamingSeat = { taskLeaseId = "lease_1", seating = true },
        animationScene = { id = "ambient.roam.sitFurniture" },
    },
}
local owned = PNC.BehaviorSystem.Internal.TickOwnership.Run(
    leasedSeatRecord, standingBody, now)
T.truthy(owned, "TickOwnership still retains ownership for leased roamingSeat")
T.equal(animTicked, 1,
    "TickOwnership ticks AnimationScenes while leased roamingSeat has active scene")
