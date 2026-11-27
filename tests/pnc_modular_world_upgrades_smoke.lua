local T = require "tests/support/test"
T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Base/PNC_Sandbox.lua")
T.load("ProjectHoomans", "server", "PNC/Director/PNC_AbstractCombatProfile.lua")
T.load("ProjectHoomans", "server", "PNC/Director/PNC_AbstractAftermathService.lua")
T.load("ProjectHoomans", "server", "PNC/Director/PNC_AbstractAftermathMaterializer.lua")
T.load("ProjectHoomans", "server", "PNC/Director/PNC_AbstractHazardResolver.lua")
T.load("ProjectHoomans", "server", "PNC/Director/PNC_AbstractCombatContinuity.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Behaviors/PNC_Behavior_Travel_Tactics.lua")

local function assertTrue(cond, label)
    if not cond then error((label or "assertTrue") .. " failed") end
end

local function assertEq(a, b, label)
    if a ~= b then error((label or "assertEq") .. ": expected " .. tostring(b) .. ", got " .. tostring(a)) end
end

local Tactics = PNC.BehaviorTravelTactics
local Aftermath = PNC.AbstractAftermathService
local Materializer = PNC.AbstractAftermathMaterializer
local Continuity = PNC.AbstractCombatContinuity
local WorldEvents = require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldEvents"

-- 1. Squad-shared live tactics caching: 4 members -> only 1 SpatialIndex scan!
local spatialCalls = 0
local prevSpatial = PNC.SpatialIndex
local zeds = {}
for i = 1, 5 do
    zeds[i] = {
        getX = function() return 108 + i end,
        getY = function() return 103 end,
        getZ = function() return 0 end,
        isDead = function() return false end,
    }
end
PNC.SpatialIndex = {
    QueryZombies = function()
        spatialCalls = spatialCalls + 1
        return zeds
    end,
}

Tactics.GroupCache = {}
local target = { x = 200, y = 100, z = 0 }
local decisions = {}
for i = 1, 4 do
    local member = {
        id = "squad_m_" .. i,
        alive = true,
        x = 100, y = 100, z = 0,
        health = { current = 100, max = 100 },
        travel = { handoffGroupId = "grp_shared_1" },
        runtime = {},
    }
    decisions[i] = Tactics.Evaluate(member, nil, target, 5000)
    assertEq(decisions[i].action, "flank", "squad member " .. i .. " shares flank directive")
end
assertEq(spatialCalls, 1, "4-person squad executed only 1 SpatialIndex scan")

-- 2. Physical aftermath loot materialization (one-shot when player approaches).
WorldEvents.Reset()
local droppedItems = {}
local prevGetCell = _G.getCell
_G.getCell = function()
    return {
        getGridSquare = function(_, x, y)
            if x == 1300 and y == 1300 then
                return {
                    AddWorldInventoryItem = function(_, itemType)
                        droppedItems[#droppedItems + 1] = itemType
                    end,
                }
            end
            return nil
        end,
    }
end

Aftermath.RegisterSite({
    kind = "COLONIST_DEAD",
    x = 1300,
    y = 1300,
    lootTier = "high",
    npcName = "Fallen Scout",
}, 10.0)

local playerNear = { getX = function() return 1310 end, getY = function() return 1305 end }
local spawnedCount = Materializer.Pump(11.0, 2, { playerNear })
assertEq(spawnedCount, 1, "aftermath site materialized once")
assertTrue(#droppedItems >= 3, "high-tier aftermath loot dropped on square")
local againCount = Materializer.Pump(12.0, 2, { playerNear })
assertEq(againCount, 0, "second pump does not duplicate loot")

-- 3. Live -> Abstract combat continuity finishes mid-fight off-camera.
local prevSandbox = _G.SandboxVars
_G.SandboxVars = {
    ProjectHoomans = {
        OffCameraColonistSOSChance = 100.0,
        OffCameraColonistSOSItemLossPercent = 0.0,
    },
}
local fightingColonist = {
    id = "col_midfight_1",
    name = "Riley",
    alive = true,
    recruited = true,
    x = 1500, y = 1500, z = 0,
    health = { current = 40, max = 100 },
    equipment = {},
    runtime = {
        inCombat = true,
        inCombatUntil = 999999,
        travelTactics = { lastDecision = { threatCount = 12 } },
    },
}
local handedOff, outcome, res = Continuity.OnLiveCombatAbstracted(
    fightingColonist, nil, "range_exit", 14.0, 5000
)
assertTrue(handedOff == true, "mid-fight abstraction handed off to off-camera resolver")
assertEq(outcome, "OVERWHELMED", "weak colonist in 12-zed fight resolved overwhelmed")
assertEq(res.policyOutcome, "SOS", "100% SOS chance sheltered colonist off-camera")

-- 4. SOS Rescue Completion clears sosState and cancels the Core COLONIST_SOS event.
local rescuedOk, rescuedReason = Materializer.CompleteSOSRescue(fightingColonist, nil)
assertTrue(rescuedOk == true and rescuedReason == "rescued", "SOS rescue succeeded")
assertEq(fightingColonist.sosState, nil, "sosState cleared after rescue")
assertEq(#WorldEvents.List({ kind = "COLONIST_SOS" }), 0, "COLONIST_SOS world event cancelled")

-- 5. Emergent radio sighting for traveling TRADER caravan + cooldown enforcement.
Aftermath._lastSightingGlobalAt = -100
Aftermath._sightingGroupCooldowns = {}
local traderGroup = {
    id = "grp_trader_sight_1",
    groupType = "TRADER",
    state = "TRAVELING",
    journey = { state = "en_route", x = 1420, y = 1180 },
}
local pub1, kind1 = Aftermath.MaybePublishSighting(traderGroup, 20.0)
assertTrue(pub1 == true and kind1 == "CARAVAN_SIGHTING", "trader caravan sighting published")
assertEq(#WorldEvents.List({ kind = "CARAVAN_SIGHTING" }), 1, "sighting registered in Core WorldEvents")
local pub2, reason2 = Aftermath.MaybePublishSighting(traderGroup, 21.0)
assertTrue(pub2 == false and reason2 == "global_cooldown", "sighting respects global cooldown")

_G.SandboxVars = prevSandbox
_G.getCell = prevGetCell
PNC.SpatialIndex = prevSpatial
WorldEvents.Reset()
print("PASS: pnc_modular_world_upgrades_smoke")
