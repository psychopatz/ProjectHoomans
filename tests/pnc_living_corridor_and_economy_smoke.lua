local root = debug.getinfo(1, "S").source:match("^@?(.*)/tests/") or "."
local coreRoot = root .. "/../psychopatzCore"
package.path = root .. "/Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua;"
    .. root .. "/Contents/mods/ProjectHoomans/42.20/media/lua/server/?.lua;"
    .. coreRoot .. "/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua;"
    .. coreRoot .. "/Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua;"
    .. package.path

local SurvivorWorld = require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
local CorridorGraph = SurvivorWorld.CorridorGraph
local ScavengeLedger = SurvivorWorld.ScavengeLedger
local WorldEvents = SurvivorWorld.Events

PNC = PNC or {}
PNC.Core = PNC.Core or { Now = function() return 1000 end }
PNC.DirectorConfig = PNC.DirectorConfig or {}
require "PNC/Core/Director/PNC_DirectorConfig/PNC_DirectorConfig_Population"
require "PNC/Core/Base/PNC_Sandbox"
PNC.PopulationSectors = PNC.PopulationSectors or {
    CountGroups = function() return 0 end,
    CountSettlements = function() return 0 end,
    Ensure = function() return nil, {} end,
    NeighborIDs = function() return {} end,
    Runtime = {},
}
local Budget = require "PNC/Director/Population/PNC_PopulationBudget"
local Sustainability = require "PNC/Director/Population/PNC_CommunitySustainabilityService"

-- 1. Auto-normalized Sandbox NPC Share Weights & Largest-Remainder Slicer.
_G.SandboxVars = {
    ProjectHoomans = {
        WorldNPCShareLooters = 0.50,
        WorldNPCShareScavengers = 0.20,
        WorldNPCShareRefugees = 0.20,
        WorldNPCShareTraders = 0.10,
    },
}
local weights = PNC.Sandbox.WorldNPCShareWeights()
assert(math.abs((weights.LOOTER + weights.SCAVENGER + weights.REFUGEE + weights.TRADER) - 1.0) < 0.001,
    "share weights must normalize to 1.0")
local quotas = Budget.ComputeTypeQuotas(20)
assert(quotas.LOOTER == 10 and quotas.SCAVENGER == 4 and quotas.REFUGEE == 4 and quotas.TRADER == 2,
    "expected 10/4/4/2 quotas for cap=20")

-- 2. Player-owned NPCs (including former colonists who turn into refugees) are strictly excluded.
local records = {
    { id = "wild_ref_1", alive = true, archetype = "REFUGEE" },
    { id = "wild_ref_2", alive = true, archetype = "REFUGEE" },
    { id = "wild_ref_3", alive = true, archetype = "REFUGEE" },
    { id = "wild_ref_4", alive = true, archetype = "REFUGEE" },
    -- Player-origin refugee (former colonist): MUST NOT count toward wild quota!
    { id = "ex_colonist_ref", alive = true, archetype = "REFUGEE", playerOrigin = true },
    -- Recruited colonist: MUST NOT count toward wild quota!
    { id = "colonist_1", alive = true, archetype = "LOOTER", recruited = true },
}
local counts = Budget.CountWildNPCsByType(records)
assert(counts.REFUGEE == 4, "player-origin refugee must be excluded from wild count, got " .. tostring(counts.REFUGEE))
assert(counts.LOOTER == 0, "recruited colonist must be excluded from wild count, got " .. tostring(counts.LOOTER))
local canRef, curRef, qRef = Budget.CanSpawnArchetype("REFUGEE", 20, records)
assert(canRef == false and curRef == 4 and qRef == 4, "wild refugee quota should be full at 4/4")
local canLoot = Budget.CanSpawnArchetype("LOOTER", 20, records)
assert(canLoot == true, "wild looter quota should still allow spawning")

-- 3. Settlement supply sustainability: scavenger deposit + starvation collapse.
CorridorGraph.Reset()
WorldEvents.Reset()
local commA = {
    id = "comm_alpha",
    name = "Muldraugh Outpost",
    home = { x = 10600, y = 9800, z = 0 },
    population = 5,
    resources = { food = 10, water = 10, supplies = 5 },
}
CorridorGraph.RegisterSettlementNode(commA.id, commA.home.x, commA.home.y, 0, { owner = "ai" })
PNC.Communities = {
    Get = function(id) return id == commA.id and commA or nil end,
    List = function() return { commA } end,
}

-- Scavenger returns home and deposits 20 carriedSupplies -> +12 food, +5 water, +3 supplies.
local scavGroup = { id = "g_scav_1", homeCommunityId = commA.id, carriedSupplies = 20 }
local depOk, depInfo = Sustainability.DepositScavengerSupplies(scavGroup, 10)
assert(depOk and depInfo.food == 22 and scavGroup.carriedSupplies == 0, "scavenger deposit failed")

-- Drain food to 0 and advance 48+ starvation hours -> emergent collapse!
commA.resources.food = 0
Sustainability.TickCommunity(commA, 100) -- initialize tick timestamp
Sustainability.TickCommunity(commA, 124) -- +24h starving
assert(commA.status ~= "COLLAPSED", "should not collapse after only 24h")
local okCol, colState = Sustainability.TickCommunity(commA, 150) -- +26h = 50h starving -> collapse!
assert(okCol and colState == "collapsed" and commA.status == "COLLAPSED", "expected settlement collapse at 50h")
assert(not CorridorGraph.HasSettlementWithin(commA.home.x, commA.home.y, 50),
    "collapsed settlement must unregister from CorridorGraph")
local evs = WorldEvents.List()
local hasShortage, hasCollapsed = false, false
for i = 1, #evs do
    if evs[i].kind == "SUPPLY_SHORTAGE" then hasShortage = true end
    if evs[i].kind == "SETTLEMENT_COLLAPSED" then hasCollapsed = true end
end
assert(hasShortage, "expected SUPPLY_SHORTAGE Core world event before collapse")
assert(hasCollapsed, "expected SETTLEMENT_COLLAPSED Core world event")

-- 4. Player base Tier-1 hub registration enforces 400-tile hard / 800-tile preferred spacing.
CorridorGraph.RegisterSettlementNode("player_main_base", 5000, 5000, 0, { owner = "player" })
assert(CorridorGraph.HasSettlementWithin(5300, 5000, 400), "300 tiles from player base must be blocked by 400-tile hard spacing")
assert(not CorridorGraph.HasSettlementWithin(5500, 5000, 400), "500 tiles from player base must be allowed")
assert(PNC.DirectorConfig.Population.SETTLEMENT_HARD_MIN_DISTANCE == 400, "SETTLEMENT_HARD_MIN_DISTANCE must be 400")
assert(PNC.DirectorConfig.Population.SETTLEMENT_PREFERRED_DISTANCE == 800, "SETTLEMENT_PREFERRED_DISTANCE must be 800")

print("PASS pnc_living_corridor_and_economy_smoke")
