local T = require "tests/support/test"
local Simulator = require "tests/support/lightweight_runtime_simulator"
local FollowWL = require "tests/support/lightweight_runtime_workloads/follow"
local CombatWL = require "tests/support/lightweight_runtime_workloads/combat"
local TravelWL = require "tests/support/lightweight_runtime_workloads/travel"
local InventoryWL = require "tests/support/lightweight_runtime_workloads/inventory"
local CombinedWL = require "tests/support/lightweight_runtime_workloads/combined"

-- 1. Family A: continuous FollowOwner movement (n=6)
local followRep = Simulator.New({
    actorCount = 20, nearbyActors = 0, expectedPromotedActors = 0, zombieCount = 0,
    simulatedMs = 9500, stepMs = 50, profilerMode = "OFF", quiet = true,
    workload = FollowWL.New({ scenario = "FOLLOW_WALK_OPEN", followers = 6, warmupMs = 5500 }),
}):Run()
print("L6_FOLLOW: " .. FollowWL.Format(followRep.Workload))
T.equal(followRep.SafePhaseFailures, 0, "L6_FOLLOW SafePhase failures")
T.equal(followRep.Workload.LiveAtStart, 6, "L6_FOLLOW all 6 companions live")
T.truthy(followRep.Workload.FollowDecisions > 0, "L6_FOLLOW exercised real follow decisions")
T.truthy(followRep.Workload.MaxFrameEnginePathRequests <= 2,
    "L6_FOLLOW same-frame engine path requests bounded <= 2; got "
        .. tostring(followRep.Workload.MaxFrameEnginePathRequests))
T.truthy(followRep.Workload.PathServiceResets <= 6,
    "L6_FOLLOW must not suffer periodic identity-bound path reset storms; got "
        .. tostring(followRep.Workload.PathServiceResets))

-- 2. Family B: synchronized combat-hit player sync coalescing + zombie/NPC hits
local combatPlayerRep = Simulator.New({
    actorCount = 20, nearbyActors = 0, expectedPromotedActors = 0, zombieCount = 0,
    simulatedMs = 2500, stepMs = 50, profilerMode = "OFF", quiet = true,
    workload = CombatWL.New({
        scenario = "COMBAT_NPC_PLAYER_HIT", attackers = 6, synchronized = true, witnesses = 6, rounds = 4,
    }),
}):Run()
print("L6_CMB_PL: " .. CombatWL.Format(combatPlayerRep.Workload))
T.equal(combatPlayerRep.SafePhaseFailures, 0, "L6_CMB_PL SafePhase failures")
T.equal(combatPlayerRep.Workload.HitsApplied, 24, "L6_CMB_PL all 24 authoritative hits applied")
T.equal(combatPlayerRep.Workload.PlayerBodyDamageUpdate, 4,
    "L6_CMB_PL BodyDamage:Update coalesced to 1 per burst tick")
T.equal(combatPlayerRep.Workload.PlayerStatsChange, 4,
    "L6_CMB_PL sendPlayerStatsChange coalesced to 1 per burst tick")

local combatZombieRep = Simulator.New({
    actorCount = 20, nearbyActors = 0, expectedPromotedActors = 0, zombieCount = 0,
    simulatedMs = 2500, stepMs = 50, profilerMode = "OFF", quiet = true,
    workload = CombatWL.New({
        scenario = "COMBAT_NPC_ZOMBIE_HIT", attackers = 3, synchronized = true, rounds = 3,
    }),
}):Run()
print("L6_CMB_ZB: " .. CombatWL.Format(combatZombieRep.Workload))
T.equal(combatZombieRep.SafePhaseFailures, 0, "L6_CMB_ZB SafePhase failures")
T.truthy(combatZombieRep.Workload.HitsApplied > 0 and combatZombieRep.Workload.KillsObserved > 0,
    "L6_CMB_ZB exercised hits and kill transition")

-- 3. Family C: abstract travel time leap + projected intercept
local travelLeapRep = Simulator.New({
    actorCount = 1, nearbyActors = 0, expectedPromotedActors = 0, zombieCount = 0,
    simulatedMs = 2500, stepMs = 50, profilerMode = "OFF", quiet = true,
    workload = TravelWL.New({ scenario = "ABSTRACT_ROUTE_TIME_LEAP", groupCount = 10, groupSize = 3 }),
}):Run()
print("L6_TRV_LP: " .. TravelWL.Format(travelLeapRep.Workload))
T.equal(travelLeapRep.SafePhaseFailures, 0, "L6_TRV_LP SafePhase failures")
T.truthy(travelLeapRep.Workload.TimeLeapDiff < 1e-6, "L6_TRV_LP big leap == small steps")
T.equal(travelLeapRep.Workload.PeakPromotedRecords, 0, "L6_TRV_LP distant actors stay compact")

-- 4. Family D: compact inventory subset materialization + zero legacy authority
local invSubRep = Simulator.New({
    actorCount = 1, nearbyActors = 0, expectedPromotedActors = 0, zombieCount = 0,
    simulatedMs = 1800, stepMs = 50, profilerMode = "OFF", quiet = true,
    workload = InventoryWL.New({
        scenario = "INVENTORY_MATERIALIZE_SUBSET", npcCount = 30, itemsPerNpc = 10, subsetLive = 4,
    }),
}):Run()
print("L6_INV_SB: " .. InventoryWL.Format(invSubRep.Workload))
T.equal(invSubRep.SafePhaseFailures, 0, "L6_INV_SB SafePhase failures")
T.equal(invSubRep.Workload.FullModeCount, 0, "L6_INV_SB compact inventories avoid FULL fallback")
T.truthy(invSubRep.Workload.HydrateCount <= 6 and invSubRep.Workload.PromotedAtEnd <= 6,
    "L6_INV_SB only nearby subset hydrated")
T.equal(invSubRep.Workload.LegacyAuthorityCount, 0, "L6_INV_SB zero legacy shadow authority")

-- 5. Combined: observation projection load stays strictly read-only
local obsRep = Simulator.New({
    actorCount = 1, nearbyActors = 0, expectedPromotedActors = 0, zombieCount = 0,
    simulatedMs = 2000, stepMs = 50, profilerMode = "OFF", quiet = true,
    workload = CombinedWL.New({ scenario = "OBSERVATION_PROJECTION_LOAD", fast = true }),
}):Run()
print("L6_OBS:    " .. CombinedWL.Format(obsRep.Workload))
T.equal(obsRep.SafePhaseFailures, 0, "L6_OBS SafePhase failures")
T.equal(obsRep.Workload.Promotions, 0, "L6_OBS observation never promotes")
T.equal(obsRep.Workload.Materializations, 0, "L6_OBS observation never materializes")

T.finish("pnc_lightweight_runtime_l6_smoke")
