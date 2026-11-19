local T = require "tests/support/test"
local Simulator = require "tests/support/lightweight_runtime_simulator"

local baseOptions = {
    worldSeed = 123456,
    actorCount = 100,
    nearbyActors = 14,
    expectedPromotedActors = 6,
    zombieCount = 40,
    playerCount = 1,
    clientCount = 1,
    simulatedMs = 15000,
    stepMs = 50,
    deepDurationMs = 5000,
    quiet = true,
}

local function withMode(mode, overrides)
    local opts = {}
    for k, v in pairs(baseOptions) do opts[k] = v end
    for k, v in pairs(overrides or {}) do opts[k] = v end
    opts.profilerMode = mode
    return Simulator.New(opts):Run()
end

local offReport = withMode("OFF")
local coarseReport = withMode("COARSE")
local deepReport = withMode("DEEP")

print("OFF:    " .. Simulator.FormatSummary(offReport))
print("COARSE: " .. Simulator.FormatSummary(coarseReport))
print("DEEP:   " .. Simulator.FormatSummary(deepReport))

-- 1. Zero SafePhase failures in any mode.
T.equal(offReport.SafePhaseFailures, 0, "OFF mode SafePhase failures")
T.equal(coarseReport.SafePhaseFailures, 0, "COARSE mode SafePhase failures")
T.equal(deepReport.SafePhaseFailures, 0, "DEEP mode SafePhase failures")

-- 2. Strict OFF invariants: zero wrappers, zero backend loaded, zero wrapper calls.
T.equal(offReport.ProfilerLoaded, false, "OFF must not load Profiler backend")
T.equal(offReport.InitialCoarseWrappersInstalled, 0, "OFF coarse wrappers installed")
T.equal(offReport.InitialDeepWrappersInstalled, 0, "OFF deep wrappers installed")
T.equal(offReport.ProfilerCoarseWrapperCalls, 0, "OFF coarse wrapper calls")
T.equal(offReport.ProfilerDeepWrapperCalls, 0, "OFF deep wrapper calls")
T.equal(offReport.InitialTimingLabel, "off", "OFF timing label")
T.equal(offReport.RestoredCleanly, true, "OFF clean state")

-- 3. Coarse invariants: bounded coarse wrappers only, zero deep wrappers, clean disable restore.
T.equal(coarseReport.ProfilerLoaded, true, "COARSE did not load Profiler backend")
T.truthy(coarseReport.InitialCoarseWrappersInstalled > 0
    and coarseReport.InitialCoarseWrappersInstalled <= 15,
    "COARSE wrapper count out of bounds")
T.equal(coarseReport.InitialDeepWrappersInstalled, 0, "COARSE installed deep wrappers")
T.truthy(coarseReport.ProfilerCoarseWrapperCalls > 0, "COARSE recorded zero coarse calls")
T.equal(coarseReport.ProfilerDeepWrapperCalls, 0, "COARSE recorded deep calls")
T.equal(coarseReport.InitialTimingLabel, "coarse_sampled", "COARSE initial timing label")
T.equal(coarseReport.EndTimingLabel, "coarse_sampled", "COARSE end timing label")
T.equal(coarseReport.RestoredCleanly, true, "COARSE clean restore on Disable")

-- 4. Deep invariants: explicit opt-in wraps deep, labels diagnostic-only, expires back to coarse mid-run.
T.equal(deepReport.ProfilerLoaded, true, "DEEP did not load Profiler backend")
T.truthy(deepReport.InitialDeepWrappersInstalled > 0, "DEEP installed zero deep wrappers")
T.truthy(deepReport.ProfilerDeepWrapperCalls > 0, "DEEP recorded zero deep calls")
T.equal(deepReport.InitialTimingLabel, "deep_instrumented_diagnostic_only", "DEEP initial timing label")
T.equal(deepReport.DeepExpired, true, "DEEP did not expire mid-run")
T.equal(deepReport.EndDeepWrappersInstalled, 0, "DEEP wrappers survived expiry")
T.truthy(deepReport.EndCoarseWrappersInstalled > 0, "COARSE wrappers lost on deep expiry")
T.equal(deepReport.EndTimingLabel, "coarse_sampled", "DEEP post-expiry timing label")
T.equal(deepReport.RestoredCleanly, true, "DEEP clean restore on Disable")

-- 5. Deterministic operation equivalence across OFF, COARSE, and DEEP.
for _, field in ipairs({
    "CoreActors",
    "PromotedAtStartup",
    "PeakPromotedHoomansRecords",
    "EndPromotedHoomansRecords",
    "SchedulerProcessed",
    "LogicalCommits",
    "DirtyDomainMarks",
    "PersistencePumps",
    "GlobalSaveCalls",
    "CoreRuntimeStoreSaves",
    "TerminalPersistenceOutcomes",
    "RetryablePersistenceFailures",
    "FullSnapshots",
    "PresenceDeltas",
    "CombatDeltas",
    "HealthOrWoundDeltas",
    "EquipmentDeltas",
    "RepairSnapshots",
    "MaterializationAttempts",
    "Materializations",
    "ZombieAggroProcessed",
    "SpatialRebuilds",
    "CensusScans",
    "PerNpcGlobalZombieScans",
}) do
    T.equal(coarseReport[field], offReport[field], "COARSE determinism mismatch on " .. field)
    T.equal(deepReport[field], offReport[field], "DEEP determinism mismatch on " .. field)
end

-- 5a. L3 domain-delta vs full-snapshot invariants on OFF baseline.
T.truthy((offReport.PresenceDeltas or 0) > 0, "OFF run must emit narrow presence deltas")
T.truthy((offReport.CombatDeltas or 0) > 0, "OFF run must emit narrow combat deltas")
T.truthy((offReport.HealthOrWoundDeltas or 0) > 0, "OFF run must emit narrow health/wound deltas")
T.truthy((offReport.EquipmentDeltas or 0) > 0, "OFF run must emit narrow equipment deltas")
T.truthy((offReport.FullSnapshots or 0) <= 40,
    "OFF run ordinary mutations must not rebuild full snapshots; got "
        .. tostring(offReport.FullSnapshots))

-- 5a-L4. Zero extra zombie scans + bounded materialization/census cadence.
T.equal(offReport.PerNpcGlobalZombieScans, 0,
    "OFF run must have 0 extra getZombieList scans outside WorldCensus")
T.truthy((offReport.CensusScans or 0) <= 105,
    "OFF run calm WorldCensus scans must stay <= 105; got "
        .. tostring(offReport.CensusScans))
T.truthy((offReport.MaterializationAttempts or 0) <= 55,
    "OFF run MaterializationAttempts must stay <= 55 (no thrashing); got "
        .. tostring(offReport.MaterializationAttempts))
T.equal(offReport.Materializations, 9,
    "OFF run must still materialize all 9 active nearby NPCs")

-- 5b. L2 deferred physical persistence invariants on OFF baseline.
T.equal(offReport.GlobalSaveCalls, 1, "ordinary OFF run should call GlobalModData.save only on OnSave")
T.equal(offReport.DirtyRecordsEnd, 0, "OFF run must finish with 0 dirty records")
T.equal(offReport.TerminalPersistenceOutcomes, 0, "OFF run must have 0 terminal errors")
T.equal(offReport.RetryablePersistenceFailures, 0, "OFF run must have 0 retryable failures")
T.truthy((offReport.CoreRuntimeStoreSaves or 0) <= 2,
    "Core RuntimeStore.Save must stay deferred until OnSave, got "
        .. tostring(offReport.CoreRuntimeStoreSaves))

-- 6. L1 lazy promotion invariants: zero bulk startup hydration; active set stays O(L), not O(N).
T.equal(offReport.PromotedAtStartup, 0, "startup bulk hydration must be removed")
T.truthy(offReport.PeakPromotedHoomansRecords <= baseOptions.expectedPromotedActors + 6,
    "promoted Hoomans records must stay bounded to active nearby set L, not N=100; got "
        .. tostring(offReport.PeakPromotedHoomansRecords))

-- 7. L1 scale invariance: growing compact Core actors from N=100 to N=300 leaves Hoomans work unchanged.
local scale300Report = withMode("OFF", { actorCount = 300 })
print("OFF_300: " .. Simulator.FormatSummary(scale300Report))
T.equal(scale300Report.PromotedAtStartup, 0, "N=300 startup must remain 0 promoted")
T.equal(scale300Report.PeakPromotedHoomansRecords, offReport.PeakPromotedHoomansRecords,
    "peak promoted records must be invariant across N=100 vs N=300")
T.equal(scale300Report.EndPromotedHoomansRecords, offReport.EndPromotedHoomansRecords,
    "end promoted records must be invariant across N=100 vs N=300")
T.equal(scale300Report.SchedulerMembersAtEnd, offReport.SchedulerMembersAtEnd,
    "scheduler membership must be invariant across N=100 vs N=300")
T.equal(scale300Report.SpatialMembersAtEnd, offReport.SpatialMembersAtEnd,
    "spatial membership must be invariant across N=100 vs N=300")
T.equal(scale300Report.SchedulerProcessed, offReport.SchedulerProcessed,
    "scheduler work processed must be invariant across N=100 vs N=300")
T.equal(scale300Report.PerNpcGlobalZombieScans, 0,
    "N=300 run must have 0 extra zombie scans")
T.equal(scale300Report.ZombieAggroProcessed, offReport.ZombieAggroProcessed,
    "zombie aggro processed must be invariant across N=100 vs N=300")

-- 8. L1 departure & reversible demotion: leaving range abstracts & demotes cleanly without losing Core actors.
local departReport = withMode("OFF", { departAtMs = 6000, simulatedMs = 15000 })
print("DEPART:  " .. Simulator.FormatSummary(departReport))
T.equal(departReport.SafePhaseFailures, 0, "DEPART mode SafePhase failures")
T.truthy(departReport.DemotionsCount > 0, "departure must trigger reversible demotions")
T.equal(departReport.EndPromotedHoomansRecords, 0, "all departed bystanders must demote")
T.equal(departReport.SchedulerMembersAtEnd, 0, "demoted actors must leave scheduler")
T.equal(departReport.SpatialMembersAtEnd, 0, "demoted actors must leave spatial index")
T.equal(departReport.CoreActors, baseOptions.actorCount, "demotion must preserve canonical Core actors")

-- 9. L1 mass interest entry obeys bounded per-refresh promotion & per-tick materialization budgets.
local massReport = withMode("OFF", {
    actorCount = 100,
    nearbyActors = 0,
    expectedPromotedActors = 40,
    massInterestActors = 40,
    simulatedMs = 5000,
})
print("MASS40:  " .. Simulator.FormatSummary(massReport))
T.equal(massReport.SafePhaseFailures, 0, "MASS40 SafePhase failures")
T.truthy(massReport.MaxPromotionsInSingleRefresh <= 4,
    "single interest refresh must respect CORE_PROMOTE_MAX_PER_REFRESH=4, got "
        .. tostring(massReport.MaxPromotionsInSingleRefresh))
T.truthy(massReport.MaxMaterializationsInSingleTick <= 2,
    "single tick must respect MATERIALIZE_MAX_PER_TICK=2, got "
        .. tostring(massReport.MaxMaterializationsInSingleTick))
T.truthy(massReport.PeakPromotedHoomansRecords <= 24,
    "mass nearby entry must respect live admission headroom, got "
        .. tostring(massReport.PeakPromotedHoomansRecords))

-- 10. L2 mutation storm: rapid logical knowledge mutations coalesce without synchronous flushes.
local mutStormReport = withMode("OFF", {
    actorCount = 100,
    simulatedMs = 6000,
    knowledgeMutationIntervalMs = 250,
})
print("MUT_STRM:" .. Simulator.FormatSummary(mutStormReport))
T.equal(mutStormReport.SafePhaseFailures, 0, "MUT_STORM SafePhase failures")
T.truthy(mutStormReport.LogicalCommits >= 20,
    "MUT_STORM must exercise >= 20 logical commits, got "
        .. tostring(mutStormReport.LogicalCommits))
T.equal(mutStormReport.GlobalSaveCalls, 1,
    "MUT_STORM must coalesce global flushes to 1 OnSave call")
T.truthy(mutStormReport.PersistencePumps < mutStormReport.LogicalCommits,
    "MUT_STORM pumps (" .. tostring(mutStormReport.PersistencePumps)
        .. ") must be < logical commits (" .. tostring(mutStormReport.LogicalCommits) .. ")")
T.truthy(mutStormReport.SerializationAttempts <= 20,
    "MUT_STORM must not re-serialize unchanged abstract actors, got "
        .. tostring(mutStormReport.SerializationAttempts))
T.truthy((mutStormReport.CoreRuntimeStoreSaves or 0) <= 2,
    "MUT_STORM CoreRuntimeStoreSaves <= 2, got "
        .. tostring(mutStormReport.CoreRuntimeStoreSaves))
T.equal(mutStormReport.DirtyRecordsEnd, 0, "MUT_STORM dirty records at end must be 0")
T.equal(mutStormReport.TerminalPersistenceOutcomes, 0, "MUT_STORM terminal errors must be 0")
T.equal(mutStormReport.RetryablePersistenceFailures, 0, "MUT_STORM retryable failures must be 0")

-- 11. L3 mixed-capability domain deltas + revision-gap repair scenario.
local netDeltaReport = withMode("OFF", {
    actorCount = 100,
    playerCount = 2,
    clientCount = 2,
    simulatedMs = 8000,
    mixedCapabilities = true,
    injectRevisionGap = true,
})
print("NET_DLT: " .. Simulator.FormatSummary(netDeltaReport))
T.equal(netDeltaReport.SafePhaseFailures, 0, "NET_DELTA SafePhase failures")
T.truthy((netDeltaReport.PresenceDeltas or 0) > 0, "NET_DELTA modern client received presence deltas")
T.truthy((netDeltaReport.CombatDeltas or 0) > 0, "NET_DELTA modern client received combat deltas")
T.truthy((netDeltaReport.FallbackSnapshots or 0) > 0,
    "NET_DELTA legacy fallback client must receive full snapshots")
T.truthy((netDeltaReport.RepairSnapshots or 0) >= 1,
    "NET_DELTA injected revision gap must produce targeted repair snapshot")

-- 12. L4 zombie-pressure scenario (Z=200 nearby ordinary zombies): shared census, bounded aggro.
local zPressureReport = withMode("OFF", {
    actorCount = 100,
    nearbyActors = 14,
    expectedPromotedActors = 6,
    zombieCount = 200,
    simulatedMs = 15000,
})
print("Z_PRESS: " .. Simulator.FormatSummary(zPressureReport))
T.equal(zPressureReport.SafePhaseFailures, 0, "Z_PRESSURE SafePhase failures")
T.equal(zPressureReport.PerNpcGlobalZombieScans, 0,
    "Z_PRESSURE must perform 0 per-NPC global zombie scans")
T.equal(zPressureReport.Materializations, 9,
    "Z_PRESSURE must still materialize all 9 active NPCs")
T.truthy((zPressureReport.MaterializationAttempts or 0) <= 55,
    "Z_PRESSURE MaterializationAttempts must stay <= 55; got "
        .. tostring(zPressureReport.MaterializationAttempts))
T.truthy((zPressureReport.ZombieAggroProcessed or 0) > 0
    and (zPressureReport.ZombieAggroProcessed or 0) <= 9500,
    "Z_PRESSURE ZombieAggroProcessed must stay active yet throttled; got "
        .. tostring(zPressureReport.ZombieAggroProcessed))

-- 13. L4 idle zero-live scenario (Z=200, L=0): slow census cadence and 0 aggro work.
local idleZeroReport = withMode("OFF", {
    actorCount = 100,
    nearbyActors = 0,
    expectedPromotedActors = 0,
    zombieCount = 200,
    simulatedMs = 15000,
})
print("IDLE_0:  " .. Simulator.FormatSummary(idleZeroReport))
T.equal(idleZeroReport.SafePhaseFailures, 0, "IDLE_ZERO SafePhase failures")
T.equal(idleZeroReport.PerNpcGlobalZombieScans, 0,
    "IDLE_ZERO must perform 0 extra zombie scans")
T.equal(idleZeroReport.ZombieAggroProcessed, 0,
    "IDLE_ZERO must process 0 zombie aggro entries")
T.equal(idleZeroReport.EndPromotedHoomansRecords, 0,
    "IDLE_ZERO must retain 0 promoted Hoomans records")
T.truthy((idleZeroReport.CensusScans or 0) <= 20,
    "IDLE_ZERO WorldCensus scans must obey idle cadence (<= 20 over 15s); got "
        .. tostring(idleZeroReport.CensusScans))

T.finish("pnc_lightweight_runtime_simulation_smoke")
