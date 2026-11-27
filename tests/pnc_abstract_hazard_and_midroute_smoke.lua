local T = require "tests/support/test"
T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Base/PNC_Sandbox.lua")
T.load("ProjectHoomans", "server", "PNC/Director/PNC_AbstractCombatProfile.lua")
T.load("ProjectHoomans", "server", "PNC/Director/PNC_AbstractHazardResolver.lua")

local function assertTrue(cond, label)
    if not cond then error((label or "assertTrue") .. " failed") end
end

local function assertEq(a, b, label)
    if a ~= b then error((label or "assertEq") .. ": expected " .. tostring(b) .. ", got " .. tostring(a)) end
end

local Hazard = PNC.AbstractHazardResolver
assertTrue(type(Hazard.EvaluateThreatAt) == "function", "EvaluateThreatAt exists")
assertTrue(type(Hazard.ApplyColonistLossPolicy) == "function", "ApplyColonistLossPolicy exists")

-- Mock IsoMetaGrid with zombie intensity + nearby shelter building.
local prevGetWorld = _G.getWorld
_G.getWorld = function()
    return {
        getMetaGrid = function()
            return {
                getChunkData = function(_, cx, cy)
                    return {
                        getZombieIntensity = function()
                            if cx == 100 and cy == 100 then return 120 end
                            return 10
                        end,
                    }
                end,
                getBuildingsIntersecting = function()
                    return {
                        size = function() return 1 end,
                        get = function()
                            return {
                                getX = function() return 1015 end,
                                getY = function() return 1012 end,
                                getW = function() return 8 end,
                                getH = function() return 6 end,
                            }
                        end,
                    }
                end,
            }
        end,
    }
end

-- 1. MetaGrid zombie intensity + pluggable horde threat provider.
local tBase = Hazard.EvaluateThreatAt(1005, 1005, 5.0)
assertEq(tBase.metaIntensity, 120, "metaIntensity reads IsoMetaChunk")
assertEq(tBase.totalThreat, 120, "totalThreat without provider")

assertTrue(Hazard.RegisterThreatProvider("test_horde", function(x, y)
    if x >= 1000 and x <= 1050 then return 80 end
    return 0
end), "threat provider registered")

local tWithHorde = Hazard.EvaluateThreatAt(1005, 1005, 5.0)
assertEq(tWithHorde.providerThreat, 80, "providerThreat added")
assertEq(tWithHorde.totalThreat, 200, "totalThreat = meta + provider")
Hazard.UnregisterThreatProvider("test_horde")

-- 2. Colonist loss policy: 100% SOS shelters in nearby building with item loss.
local prevSandbox = _G.SandboxVars
_G.SandboxVars = {
    ProjectHoomans = {
        OffCameraColonistSOSChance = 100.0,
        OffCameraColonistSOSItemLossPercent = 50.0,
    },
}

local weakColonist = {
    id = "col_sos_1",
    name = "Alex Mercer",
    alive = true,
    recruited = true,
    x = 1005,
    y = 1005,
    z = 0,
    health = { current = 80, max = 100 },
    equipment = {},
    inventory = {
        { fullType = "Base.WaterBottleFull", count = 1 },
        { fullType = "Base.TinnedBeans", count = 1 },
        { fullType = "Base.Bandage", count = 1 },
        { fullType = "Base.Hammer", count = 1 },
    },
}

local resSOS = Hazard.ResolveForParticipants({ weakColonist }, 1005, 1005, 12.0, {
    entityId = "npc:col_sos_1",
    isPlayerColonist = true,
    threatOverride = { totalThreat = 220 },
})
assertEq(resSOS.outcome, "OVERWHELMED", "weak colonist overwhelmed by 220 threat")
assertEq(resSOS.policyOutcome, "SOS", "100% SOS chance yields SOS")
assertTrue(weakColonist.alive ~= false, "SOS colonist remains alive")
assertTrue(type(weakColonist.sosState) == "table" and weakColonist.sosState.active == true, "sosState active")
assertTrue(weakColonist.sosState.shelteredInBuilding == true, "sheltered inside MetaGrid building")
assertEq(weakColonist.x, 1019, "moved to building center x")
assertEq(weakColonist.y, 1015, "moved to building center y")

-- 3. Colonist loss policy: 0% SOS yields permadeath.
_G.SandboxVars.ProjectHoomans.OffCameraColonistSOSChance = 0.0
local doomedColonist = {
    id = "col_dead_1",
    name = "Morgan Reed",
    alive = true,
    recruited = true,
    x = 1005,
    y = 1005,
    z = 0,
    health = { current = 80, max = 100 },
    equipment = {},
}
local resDead = Hazard.ResolveForParticipants({ doomedColonist }, 1005, 1005, 12.0, {
    entityId = "npc:col_dead_1",
    isPlayerColonist = true,
    threatOverride = { totalThreat = 220 },
})
assertEq(resDead.outcome, "OVERWHELMED", "doomed colonist overwhelmed")
assertEq(resDead.policyOutcome, "DEAD", "0% SOS chance yields DEAD")
assertEq(doomedColonist.alive, false, "doomed colonist marked alive=false")

-- 4. Debug snapshot captures recent events.
local snap = Hazard.GetDebugSnapshot()
assertTrue(#snap.recentEvents >= 2, "recentEvents populated for debug map")

_G.SandboxVars = prevSandbox
_G.getWorld = prevGetWorld
print("PASS: pnc_abstract_hazard_and_midroute_smoke")
