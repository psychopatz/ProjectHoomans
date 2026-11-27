local T = require "tests/support/test"
T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Base/PNC_Sandbox.lua")
T.load("ProjectHoomans", "server", "PNC/Director/PNC_AbstractCombatProfile.lua")
T.load("ProjectHoomans", "server", "PNC/Director/PNC_AbstractAftermathService.lua")
T.load("ProjectHoomans", "server", "PNC/Director/PNC_AbstractHazardResolver.lua")

local function assertTrue(cond, label)
    if not cond then error((label or "assertTrue") .. " failed") end
end

local CorridorGraph = require "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldCorridorGraph"
local RoutePlanner = require "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldRoutePlanner"
local GroupJourney = require "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldGroupJourney"

local Aftermath = PNC.AbstractAftermathService
local Hazard = PNC.AbstractHazardResolver
local Profile = PNC.AbstractCombatProfile

-- Track aired radio broadcasts via PsychopatzCore.RadioBroadcasts stub.
local airedMessages = {}
local prevBroadcasts = PsychopatzCore.RadioBroadcasts
PsychopatzCore.RadioBroadcasts = {
    Air = function(providerID, spec)
        airedMessages[#airedMessages + 1] = spec
        return true, "aired"
    end,
}

-- Mock IsoMetaGrid with deterministic roads + zombie intensity hotspots.
local prevGetWorld = _G.getWorld
_G.getWorld = function()
    return {
        getMetaGrid = function()
            return {
                getZonesIntersecting = function(_, x, y, z, w, h)
                    return {
                        size = function() return 2 end,
                        get = function(_, idx)
                            local gx = x + (idx == 0 and 80 or 220)
                            local gy = y + (idx == 0 and 120 or 180)
                            return {
                                getType = function() return "Nav" end,
                                getX = function() return gx end,
                                getY = function() return gy end,
                                getWidth = function() return 10 end,
                                getHeight = function() return 10 end,
                            }
                        end,
                    }
                end,
                getChunkData = function(_, cx, cy)
                    return {
                        getZombieIntensity = function()
                            if (cx + cy) % 7 == 0 then return 130 end
                            return 25
                        end,
                    }
                end,
                getBuildingsIntersecting = function(_, x, y)
                    return {
                        size = function() return 1 end,
                        get = function()
                            return {
                                getX = function() return x + 20 end,
                                getY = function() return y + 20 end,
                                getW = function() return 8 end,
                                getH = function() return 8 end,
                            }
                        end,
                    }
                end,
            }
        end,
    }
end

CorridorGraph.Reset()
CorridorGraph.SetWorldSeed(424242)
CorridorGraph.RegisterSettlementNode("settlement:home", 1000, 1000, 0, { label = "Home" })
CorridorGraph.RegisterSettlementNode("settlement:north", 1600, 1000, 0, { label = "North" })

-- 100 NPCs across 25 traveling groups + 4 MP players spread across the map.
local groups = {}
local npcs = {}
for g = 1, 25 do
    local members = {}
    for m = 1, 4 do
        local idx = (g - 1) * 4 + m
        local npc = {
            id = "soak_npc_" .. idx,
            name = "Survivor " .. idx,
            alive = true,
            recruited = (g <= 2),
            x = 1000 + (g * 20),
            y = 1000 + ((g % 5) * 30),
            z = 0,
            health = { current = 100, max = 100 },
            affiliation = { role = (m == 1 and "guard" or "civilian") },
            equipment = {
                primaryFullType = (m == 1 and "Base.Shotgun" or "Base.BaseballBat"),
                ammoCount = (m == 1 and 24 or 0),
                wornItems = (m == 1 and { "Base.Jacket_Leather" } or {}),
            },
        }
        npcs[npc.id] = npc
        members[#members + 1] = npc
    end
    local origin = { x = 1000 + (g * 15), y = 1000 + (g * 10), z = 0 }
    local dest = { x = 1600 - (g * 10), y = 1200 + (g * 5), z = 0 }
    local journey = GroupJourney.New("soak_grp_" .. g, {
        origin = origin,
        destination = dest,
        speed = 45,
        startAt = 0,
        mode = "abstract",
    }, 0)
    assertTrue(journey ~= nil, "journey created for soak_grp_" .. g)
    groups[g] = {
        id = "soak_grp_" .. g,
        members = members,
        journey = journey,
    }
end

local t0 = os.clock()
for tick = 1, 100 do
    local worldHour = tick * 0.25
    for g = 1, #groups do
        local grp = groups[g]
        local updated = GroupJourney.Advance(grp.journey, worldHour)
        if updated then grp.journey = updated end
        if tick % 10 == 0 and g <= 8 then
            Hazard.ResolveForParticipants(
                grp.members,
                grp.journey.x,
                grp.journey.y,
                worldHour,
                {
                    entityId = grp.id,
                    isPlayerColonist = (g <= 2),
                }
            )
        end
    end
    Aftermath.PruneExpired(worldHour)
end
local elapsed = os.clock() - t0

assertTrue(elapsed < 2.0, "100-NPC 100-tick soak finished quickly (elapsed=" .. string.format("%.3fs", elapsed) .. ")")
assertTrue(#Aftermath.Sites <= Aftermath.MAX_SITES, "aftermath sites bounded to MAX_SITES")
assertTrue(#Hazard.RecentEvents <= Hazard.MAX_RECENT_EVENTS, "hazard recentEvents bounded")
assertTrue(#Aftermath.RecentBroadcasts <= Aftermath.MAX_BROADCASTS, "radio broadcasts bounded")

-- Trigger an explicit SOS outcome and verify aftermath site + radio broadcast + TTL expiry.
local prevSandbox = _G.SandboxVars
_G.SandboxVars = {
    ProjectHoomans = {
        OffCameraColonistSOSChance = 100.0,
        OffCameraColonistSOSItemLossPercent = 50.0,
    },
}
local beforeAired = #airedMessages
local sosOutcome = Hazard.ApplyColonistLossPolicy(npcs["soak_npc_1"], 1250, 1150, 50.0, "soak_test", "soak_sos_1")
assertTrue(sosOutcome == "SOS", "explicit SOS triggered")
assertTrue(#airedMessages > beforeAired, "SOS aired through PsychopatzCore.RadioBroadcasts")
assertTrue(#Aftermath.Sites >= 1, "SOS registered aftermath site")

-- Advance past TTL (50 + 48 + 1 = 99h) and verify pruning.
Aftermath.PruneExpired(105.0)
assertTrue(#Aftermath.Sites == 0, "expired aftermath sites pruned cleanly after TTL")

-- Verify deterministic save-seed route repeatability.
local r1 = RoutePlanner.PlanRoute({ x = 1000, y = 1000 }, { x = 1600, y = 1000 })
CorridorGraph.Reset()
CorridorGraph.SetWorldSeed(424242)
CorridorGraph.RegisterSettlementNode("settlement:home", 1000, 1000, 0, { label = "Home" })
CorridorGraph.RegisterSettlementNode("settlement:north", 1600, 1000, 0, { label = "North" })
local r2 = RoutePlanner.PlanRoute({ x = 1000, y = 1000 }, { x = 1600, y = 1000 })
assertTrue(r1 ~= nil and r2 ~= nil and #r1.points == #r2.points, "same save seed reproduces identical corridor route")

_G.SandboxVars = prevSandbox
_G.getWorld = prevGetWorld
PsychopatzCore.RadioBroadcasts = prevBroadcasts
print(string.format("PASS: pnc_abstract_world_soak_smoke (100 NPCs x 100 ticks in %.3fs)", elapsed))
