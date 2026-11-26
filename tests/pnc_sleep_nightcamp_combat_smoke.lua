local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "shared" },
})

local now = 50000
local worldHours = 23.0

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
    Const = { PRESENCE_LIVE = "live" },
    SleepRuntime = { SurfaceOccupants = {}, LiveObjects = {} },
}

getGameTime = function()
    return { getWorldAgeHours = function() return worldHours end }
end

local function makeDir(name) return { _name = name } end
IsoDirections = {
    N = makeDir("N"), S = makeDir("S"), E = makeDir("E"), W = makeDir("W"),
    fromString = function(s) return IsoDirections[s] end,
}

ZombieIdleState = { instance = function() return "IDLE_STATE" end }

-- 1. Unified IsSleeping recognizes roamAmbient sleepers
PNC.LiveBodyControl = { Internal = {} }
T.load("ProjectHoomans", "shared",
    "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_State_Presentation.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_State_Posture.lua")

local roamSleeper = {
    id = "roam_1",
    alive = true,
    presenceState = "live",
    runtime = {
        roamAmbient = {
            action = "sleep",
            sleepSurfaceEntered = true,
            phase = "SLEEPING",
        },
    },
}
T.truthy(PNC.LiveBodyControl.IsSleeping(roamSleeper),
    "IsSleeping recognizes roamAmbient sleepers")
T.equal(PNC.LiveBodyControl.GetPosture(roamSleeper, nil), "SLEEPING",
    "roamAmbient sleeper resolves to SLEEPING posture")
T.truthy(PNC.LiveBodyControl.IsBodyRotationLocked(roamSleeper, nil),
    "roamAmbient sleeper locks body rotation")

-- 2. PrepareSleepSurface sets setOnBed(true), respects N facing, never fires EventSitOnFurniture
PNC.FacilityJobsBehaviorInternal = {}
T.load("ProjectHoomans", "shared",
    "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Surfaces_Helpers.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Surfaces_Sleep.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_SleepPlacement.lua")

local bedObj = { setSatChair = function() end }
PNC.FacilityJobsBehaviorInternal.LiveSleepObject = function() return bedObj end

local eventsFired = {}
local bodyState = { onBed = false, facing = nil, bed = nil }
local sleepBody = {
    getX = function() return 10.5 end,
    getY = function() return 20.5 end,
    getZ = function() return 0 end,
    setOnFloor = function() end,
    setSitOnGround = function() end,
    setSittingOnFurniture = function() end,
    setSitOnFurnitureObject = function() end,
    setSitOnFurnitureDirection = function() end,
    setForwardIsoDirection = function(_, d) bodyState.facing = d end,
    setOnBed = function(_, v) bodyState.onBed = v end,
    setIsResting = function() end,
    setBed = function(_, b) bodyState.bed = b end,
    setVariable = function() end,
    clearVariable = function() end,
    reportEvent = function(_, ev) eventsFired[#eventsFired + 1] = ev end,
}

local sleepRuntime = {
    capability = "sleep",
    sleepSurface = "bed",
    resourceKey = "bed:10:20:0",
    sleepFacing = "N",
    sleepAxis = "y",
}
local okPrep = PNC.FacilityJobsBehaviorInternal.PrepareSleepSurface(
    roamSleeper, sleepBody, sleepRuntime, sleepRuntime)
T.truthy(okPrep, "PrepareSleepSurface succeeds on bed")
T.truthy(bodyState.onBed, "PrepareSleepSurface sets setOnBed(true)")
T.equal(bodyState.facing, IsoDirections.N,
    "PrepareSleepSurface respects sleepFacing N instead of forcing S")
T.equal(#eventsFired, 0,
    "PrepareSleepSurface does not fire EventSitOnFurniture on a bed")

-- 3. Combat-wake fast-path exits in 1 tick even when attacker occupies bedside square
local attacker = { id = "zombie_attacker" }
local squares = {}
local function makeSq(x, y, z, opts)
    opts = opts or {}
    local sq = {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
        isSolid = function() return opts.solid == true end,
        isSolidTrans = function() return false end,
        haveFire = function() return false end,
        isOutside = function() return opts.outside ~= false end,
        getBuilding = function() return opts.building end,
        getCampfire = function() return opts.campfire end,
        isFree = function() return opts.occupied ~= true and opts.solid ~= true end,
        getMovingObjects = function()
            local list = opts.occupied and { attacker } or {}
            return {
                size = function() return #list end,
                get = function(_, idx) return list[idx + 1] end,
            }
        end,
    }
    squares[tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)] = sq
    return sq
end

makeSq(10, 20, 0, { solid = true })
makeSq(11, 20, 0, { occupied = true }) -- Attacker standing on approach square!
getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            return squares[tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)]
        end,
    }
end

local normalExit = PNC.FacilityJobsBehaviorInternal.FindSleepExit(
    roamSleeper, sleepBody, { approachPosition = { x = 11.5, y = 20.5, z = 0 } }, nil)
T.falsy(normalExit, "normal sleep exit avoids occupied square")

local emergencyExit = PNC.FacilityJobsBehaviorInternal.FindSleepExit(
    roamSleeper, sleepBody, { approachPosition = { x = 11.5, y = 20.5, z = 0 } },
    nil, { emergency = true })
T.truthy(emergencyExit, "combat emergency sleep exit succeeds even when bedside square is occupied")
T.near(emergencyExit.x, 11.5, 0.01, "emergency exit picks bedside square")

-- 4. NightCampService: Indoor bedroom preference + O(1) cache
local addedCampfires = 0
local removedCampfires = 0
local liveCampfires = {}

SCampfireSystem = {
    instance = {
        getLuaObjectOnSquare = function(_, sq)
            return liveCampfires[tostring(sq:getX()) .. ":" .. tostring(sq:getY())]
        end,
        addCampfire = function(_, sq)
            addedCampfires = addedCampfires + 1
            local md = {}
            local iso = { getModData = function() return md end }
            local luaObj = {
                fuel = 0, lit = false,
                addFuel = function(self, f) self.fuel = f end,
                lightFire = function(self) self.lit = true end,
                saveData = function() end,
                getIsoObject = function() return iso end,
            }
            liveCampfires[tostring(sq:getX()) .. ":" .. tostring(sq:getY())] = luaObj
            return luaObj
        end,
        removeCampfire = function(_, luaObj)
            removedCampfires = removedCampfires + 1
            for k, v in pairs(liveCampfires) do
                if v == luaObj then liveCampfires[k] = nil end
            end
        end,
    },
}

local NightCamp = T.load("ProjectHoomans", "server",
    "PNC/World/PNC_NightCampService.lua")
NightCamp.Reset()

local roomCalls = 0
local fakeBuilding = {
    getDef = function()
        return {
            getID = function() return 42 end,
            getRooms = function()
                roomCalls = roomCalls + 1
                local list = {
                    { getName = function() return "kitchen" end, getX = function() return 30 end, getY = function() return 30 end, getW = function() return 2 end, getH = function() return 2 end, getZ = function() return 0 end },
                    { getName = function() return "bedroom" end, getX = function() return 35 end, getY = function() return 35 end, getW = function() return 2 end, getH = function() return 2 end, getZ = function() return 0 end },
                }
                return {
                    size = function() return #list end,
                    get = function(_, idx) return list[idx + 1] end,
                }
            end,
        }
    end,
}
makeSq(31, 31, 0, { outside = false, building = fakeBuilding })
makeSq(35, 35, 0, { outside = false, building = fakeBuilding })
makeSq(36, 35, 0, { outside = false, building = fakeBuilding })
makeSq(35, 36, 0, { outside = false, building = fakeBuilding })
makeSq(36, 36, 0, { outside = false, building = fakeBuilding })

local indoorBody = { getX = function() return 31.5 end, getY = function() return 31.5 end, getZ = function() return 0 end }
local indoorRec1 = { id = "in_1", identitySeed = 1 }
local indoorRec2 = { id = "in_2", identitySeed = 2 }

local inCand1 = NightCamp.ResolveNightCandidate(indoorRec1, indoorBody, { wakeAt = 30 }, now)
local inCand2 = NightCamp.ResolveNightCandidate(indoorRec2, indoorBody, { wakeAt = 30 }, now)
T.truthy(inCand1, "indoor NPC resolves a night room spot")
T.truthy(inCand1.target.x >= 35 and inCand1.target.y >= 35,
    "indoor NPC prefers bedroom over kitchen")
T.truthy(inCand2, "second indoor NPC resolves a night room spot")
T.equal(roomCalls, 1, "building room scan is cached O(1) across group members")

-- 5. NightCampService: Outdoor group shares 1 temporary campfire + 1 awake sentry + clean removal
for x = 48, 56 do
    for y = 48, 56 do
        makeSq(x, y, 0, { outside = true })
    end
end
local outBody = { getX = function() return 52.5 end, getY = function() return 52.5 end, getZ = function() return 0 end }
local campRec1 = { id = "bandit_1", factionID = "bandits_alpha" }
local campRec2 = { id = "bandit_2", factionID = "bandits_alpha" }

local outCand1 = NightCamp.ResolveNightCandidate(campRec1, outBody, { wakeAt = 30 }, now)
T.truthy(outCand1, "outdoor group builder resolves campfire build spot")
local gCamp
for _, camp in pairs(NightCamp.GroupCamps or {}) do
    gCamp = camp
    break
end
T.truthy(gCamp, "outdoor group creates a shared group camp")
NightCamp.CommitTemporaryCampfire(gCamp, now)
outCand1 = NightCamp.ResolveNightCandidate(campRec1, outBody, { wakeAt = 30 }, now)
local outCand2 = NightCamp.ResolveNightCandidate(campRec2, outBody, { wakeAt = 30 }, now)

T.truthy(outCand1 and outCand2, "outdoor group members both resolve camp spots")
T.equal(addedCampfires, 1, "outdoor group shares a single temporary SCampfireSystem campfire")
local sentryCand = outCand1.role == "sentry" and outCand1 or outCand2
local sleeperCand = outCand1.role == "sleeper" and outCand1 or outCand2
T.equal(sleeperCand.role, "sleeper", "one outdoor member sleeps")
T.equal(sentryCand.role, "sentry", "one outdoor member becomes awake campfire sentry")
T.equal(sentryCand.target.sceneId, "ambient.roam.camp.sentry",
    "sentry uses ambient.roam.camp.sentry scene")
T.equal(sleeperCand.target.sceneId, "ambient.roam.sleep.floor",
    "sleeper uses ambient.roam.sleep.floor scene")

-- Release all members -> temporary campfire is removed immediately (zero clutter/bloat)
NightCamp.ReleaseMember(campRec1)
T.equal(removedCampfires, 0, "campfire stays while sentry is still at camp")
NightCamp.ReleaseMember(campRec2)
T.equal(removedCampfires, 1, "temporary campfire is removed once last member leaves")
T.equal(NightCamp.TempCampfireCount, 0, "TempCampfireCount returns to 0")
