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
    "GlobalSaveCalls",
    "FullSnapshots",
    "PresenceDeltas",
    "CombatDeltas",
    "CensusScans",
    "PerNpcGlobalZombieScans",
}) do
    T.equal(coarseReport[field], offReport[field], "COARSE determinism mismatch on " .. field)
    T.equal(deepReport[field], offReport[field], "DEEP determinism mismatch on " .. field)
end

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

T.finish("pnc_lightweight_runtime_simulation_smoke")
