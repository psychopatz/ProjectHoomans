local T = require "tests/support/test"
T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Base/PNC_Sandbox.lua")
T.load("ProjectHoomans", "server", "PNC/Director/PNC_AbstractCombatProfile.lua")
T.load("ProjectHoomans", "server", "PNC/Director/PNC_AbstractAftermathService.lua")
T.load("ProjectHoomans", "server", "PNC/Director/PNC_AbstractHazardResolver.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Behaviors/PNC_Behavior_Travel_Tactics.lua")

local function assertTrue(cond, label)
    if not cond then error((label or "assertTrue") .. " failed") end
end

local function assertEq(a, b, label)
    if a ~= b then error((label or "assertEq") .. ": expected " .. tostring(b) .. ", got " .. tostring(a)) end
end

local Tactics = PNC.BehaviorTravelTactics
local Hazard = PNC.AbstractHazardResolver
local Aftermath = PNC.AbstractAftermathService
local WorldEvents = require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldEvents"
local CoreHazards = require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldHazards"

local function fakeZed(x, y)
    return {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return 0 end,
        isDead = function() return false end,
    }
end

local prevSpatial = PNC.SpatialIndex
local mockZombies = {}
PNC.SpatialIndex = {
    QueryZombies = function() return mockZombies end,
}

local guard = {
    id = "tactics_guard_1",
    alive = true,
    recruited = true,
    x = 100,
    y = 100,
    z = 0,
    health = { current = 100, max = 100 },
    affiliation = { role = "guard" },
    equipment = {
        primaryFullType = "Base.Shotgun",
        ammoCount = 24,
        wornItems = { "Base.Vest_BulletArmy" },
    },
    runtime = {},
}
local target = { x = 200, y = 100, z = 0 }

-- 1. Clear road -> proceed.
mockZombies = {}
local dClear = Tactics.Evaluate(guard, nil, target, 1000)
assertEq(dClear.action, "proceed", "clear road proceeds")

-- 2. Single close zombie -> proactive engage.
mockZombies = { fakeZed(104, 100) }
local dEngage = Tactics.Evaluate(guard, nil, target, 2000)
assertEq(dEngage.action, "engage", "single close zombie triggers proactive engage")
assertTrue(dEngage.combatTarget ~= nil, "proactive combatTarget populated")

-- 3. Medium pack ahead -> lateral flank detour away from horde centroid (y=102 -> flank to negative y).
mockZombies = {
    fakeZed(108, 102), fakeZed(109, 103), fakeZed(110, 102),
    fakeZed(111, 104), fakeZed(112, 103),
}
local dFlank = Tactics.Evaluate(guard, nil, target, 3000)
assertEq(dFlank.action, "flank", "medium pack triggers lateral flank detour")
assertTrue(dFlank.moveY < 100, "flank steers away from horde centroid side")

-- 4. Overwhelming horde -> break contact & flee + temporary corridor penalty.
CoreHazards.Reset()
mockZombies = {}
for i = 1, 12 do
    mockZombies[i] = fakeZed(106 + (i % 4), 100 + math.floor(i / 4))
end
local dFlee = Tactics.Evaluate(guard, nil, target, 4000)
assertEq(dFlee.action, "flee", "overwhelming horde triggers flee")
assertEq(dFlee.mode, "run", "flee sprints")
assertTrue(dFlee.moveX < 100, "flee moves away from horde centroid")
assertTrue(guard.runtime.fleeingFromThreat == true, "fleeingFromThreat flag set for off-camera SOS handoff")
assertTrue(CoreHazards.GetDebugSummary().temporaryPenaltyCount >= 1, "live horde applied temporary corridor penalty")

-- 5. Off-camera SOS refuge priority: forest fallback when no building, then area fallback.
local prevSandbox = _G.SandboxVars
_G.SandboxVars = {
    ProjectHoomans = {
        OffCameraColonistSOSChance = 100.0,
        OffCameraColonistSOSItemLossPercent = 0.0,
    },
}
local prevGetWorld = _G.getWorld
_G.getWorld = function()
    return {
        getMetaGrid = function()
            return {
                getBuildingsIntersecting = function()
                    return { size = function() return 0 end }
                end,
                getZonesIntersecting = function()
                    return {
                        size = function() return 1 end,
                        get = function()
                            return {
                                getType = function() return "DeepForest" end,
                                getX = function() return 140 end,
                                getY = function() return 130 end,
                                getWidth = function() return 20 end,
                                getHeight = function() return 20 end,
                            }
                        end,
                    }
                end,
            }
        end,
    }
end

WorldEvents.Reset()
local forestCol = { id = "col_forest", name = "Forest Scout", alive = true, recruited = true, x = 100, y = 100, z = 0, health = { current = 100, max = 100 } }
local outcomeForest = Hazard.ApplyColonistLossPolicy(forestCol, 100, 100, 10.0, "live_flee_escape", "forest_test")
assertEq(outcomeForest, "SOS", "forest refuge triggers SOS")
assertEq(forestCol.sosState.refugeKind, "forest", "forest zone chosen when no building nearby")
assertEq(forestCol.x, 150, "moved to forest center x")

-- No building and no forest -> open area fallback.
_G.getWorld = function() return nil end
local areaCol = { id = "col_area", name = "Road Scout", alive = true, recruited = true, x = 100, y = 100, z = 0, health = { current = 100, max = 100 } }
local outcomeArea = Hazard.ApplyColonistLossPolicy(areaCol, 100, 100, 10.0, "live_flee_escape", "area_test")
assertEq(outcomeArea, "SOS", "area refuge triggers SOS")
assertEq(areaCol.sosState.refugeKind, "area", "area refuge used when no building or forest")

-- 6. Reload durability: aftermath/SOS events survive WorldEvents reset via Store.Registry.
local prevStore = PNC.HoomansWorldView
PNC.HoomansWorldView = { Registry = {}, WorldAgeHours = function() return 15.0 end }
-- Re-bind aftermath store sync via direct snapshot round-trip.
local snap = WorldEvents.ExportSnapshot()
WorldEvents.Reset()
assertEq(#WorldEvents.List(), 0, "cleared before restore")
local restoredCount = WorldEvents.RestoreSnapshot(snap, 15.0)
assertTrue(restoredCount >= 2, "both SOS events restored across server restart")

PNC.HoomansWorldView = prevStore
PNC.SpatialIndex = prevSpatial
_G.SandboxVars = prevSandbox
_G.getWorld = prevGetWorld
CoreHazards.Reset()
WorldEvents.Reset()
print("PASS: pnc_travel_tactics_and_durability_smoke")
