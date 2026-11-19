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

local function withMode(mode)
    local opts = {}
    for k, v in pairs(baseOptions) do opts[k] = v end
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
    "PromotedHoomansRecords",
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

T.finish("pnc_lightweight_runtime_simulation_smoke")
