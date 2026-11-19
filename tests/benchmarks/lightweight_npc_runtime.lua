-- Deterministic headless scale acceptance benchmark matrix (NON-NATIVE Lua simulator).
-- Run from repository root: lua tests/benchmarks/lightweight_npc_runtime.lua
local T = require "tests/support/test"
local Simulator = require "tests/support/lightweight_runtime_simulator"

local function runCase(opts)
    local cfg = {}
    for k, v in pairs(opts or {}) do cfg[k] = v end
    cfg.quiet = true
    return Simulator.New(cfg):Run()
end

local function assertCommonInvariants(label, r)
    T.equal(r.SafePhaseFailures, 0, label .. ": SafePhaseFailures")
    T.equal(r.PromotedAtStartup, 0, label .. ": PromotedAtStartup")
    T.equal(r.PerNpcGlobalZombieScans, 0, label .. ": PerNpcGlobalZombieScans")
    T.equal(r.DirtyRecordsEnd, 0, label .. ": DirtyRecordsEnd")
    T.equal(r.TerminalPersistenceOutcomes, 0, label .. ": TerminalPersistenceOutcomes")
    T.equal(r.RetryablePersistenceFailures, 0, label .. ": RetryablePersistenceFailures")
    T.equal(r.GlobalSaveCalls, 1, label .. ": GlobalSaveCalls")
end

local function printScaleHeader(title)
    print("\n" .. title .. " [HEADLESS LUA SIMULATOR — NON-NATIVE]")
    print(string.rep("-", 154))
    print(string.format(
        "%-18s | %5s | %4s/%4s | %4s | %5s/%3s | %5s/%3s | %4s/%3s/%4s | %4s/%4s/%4s | %4s/%4s/%4s | %6s | %5s | %8s | %6s/%6s/%6s",
        "Scenario", "CoreN", "PkPr", "EnPr", "PkLv",
        "MatAt", "Ok", "SchPr", "Def",
        "Com", "Pmp", "SerA",
        "PrsD", "CmbD", "HWEq",
        "Full", "Rep", "Fb",
        "Census", "ZAggr",
        "TickMs", "Avg", "P95", "Max"
    ))
    print(string.rep("-", 154))
end

local function printScaleRow(label, r)
    print(string.format(
        "%-18s | %5d | %4d/%4d | %4d | %5d/%3d | %5d/%3d | %4d/%3d/%4d | %4d/%4d/%4d | %4d/%4d/%4d | %6d | %5d | %8.2f | %6.2f/%6.2f/%6.2f",
        label,
        r.CoreActors,
        r.PeakPromotedHoomansRecords,
        r.EndPromotedHoomansRecords,
        r.PeakLiveBodies,
        r.MaterializationAttempts,
        r.Materializations,
        r.SchedulerProcessed,
        r.SchedulerDeferred,
        r.LogicalCommits,
        r.PersistencePumps,
        r.SerializationAttempts,
        r.PresenceDeltas,
        r.CombatDeltas,
        (r.HealthOrWoundDeltas or 0) + (r.EquipmentDeltas or 0),
        r.FullSnapshots,
        r.RepairSnapshots or 0,
        r.FallbackSnapshots or 0,
        r.CensusScans,
        r.ZombieAggroProcessed or 0,
        r.TickLoopCpuMs,
        r.AvgTickCpuMs or 0,
        r.P95TickCpuMs or 0,
        r.MaxTickCpuMs or 0
    ))
end

-- ============================================================================
-- A. Core Population Scaling O(L) vs O(N): N = 100 / 500 / 1000 / 2000 (OFF)
-- ============================================================================
printScaleHeader("A. CORE POPULATION SCALING (L=6, nearby=14, Z=50, C=1, 12s, profiler=OFF)")
local baseCore
for _, n in ipairs({ 100, 500, 1000, 2000 }) do
    local label = "N" .. tostring(n) .. "_L6_Z50"
    local r = runCase({
        actorCount = n,
        nearbyActors = 14,
        expectedPromotedActors = 6,
        zombieCount = 50,
        clientCount = 1,
        simulatedMs = 12000,
        stepMs = 50,
        profilerMode = "OFF",
    })
    printScaleRow(label, r)
    assertCommonInvariants(label, r)
    if not baseCore then
        baseCore = r
    else
        T.equal(r.PeakPromotedHoomansRecords, baseCore.PeakPromotedHoomansRecords,
            label .. ": promoted records must remain invariant with Core N")
        T.equal(r.SchedulerProcessed, baseCore.SchedulerProcessed,
            label .. ": scheduler work must remain invariant with Core N")
        T.equal(r.FullSnapshots, baseCore.FullSnapshots,
            label .. ": full snapshots must remain invariant with Core N")
        T.equal(r.PresenceDeltas, baseCore.PresenceDeltas,
            label .. ": presence deltas must remain invariant with Core N")
        T.equal(r.ZombieAggroProcessed, baseCore.ZombieAggroProcessed,
            label .. ": zombie aggro work must remain invariant with Core N")
    end
end

-- ============================================================================
-- B. Active Set Scaling: L = 1 / 6 / 12 / 24 (N=500, Z=50, C=1, 12s, OFF)
-- ============================================================================
printScaleHeader("B. RELEVANT/LIVE SET SCALING (N=500, Z=50, C=1, 12s, profiler=OFF)")
for _, l in ipairs({ 1, 6, 12, 24 }) do
    local label = "N500_L" .. tostring(l) .. "_Z50"
    local r = runCase({
        actorCount = 500,
        nearbyActors = 0,
        expectedPromotedActors = l,
        massInterestActors = l,
        zombieCount = 50,
        clientCount = 1,
        simulatedMs = 12000,
        stepMs = 50,
        profilerMode = "OFF",
    })
    printScaleRow(label, r)
    assertCommonInvariants(label, r)
    T.truthy(r.MaxPromotionsInSingleRefresh <= 4,
        label .. ": MaxPromotionsInSingleRefresh <= 4")
    T.truthy(r.MaxMaterializationsInSingleTick <= 2,
        label .. ": MaxMaterializationsInSingleTick <= 2")
    T.truthy(r.PeakLiveBodies <= 20,
        label .. ": single-player live body cap <= 20")
end

-- ============================================================================
-- C. Zombie Pressure Scaling: Z = 0 / 50 / 200 (L=6) & Z=200 IDLE L=0 (OFF)
-- ============================================================================
printScaleHeader("C. ZOMBIE PRESSURE & IDLE CADENCE (N=500, C=1, 12s, profiler=OFF)")
for _, spec in ipairs({
    { label = "N500_L6_Z0", L = 6, nearby = 14, Z = 0, idle = false },
    { label = "N500_L6_Z50", L = 6, nearby = 14, Z = 50, idle = false },
    { label = "N500_L6_Z200", L = 6, nearby = 14, Z = 200, idle = false },
    { label = "N500_IDLE0_Z200", L = 0, nearby = 0, Z = 200, idle = true },
}) do
    local r = runCase({
        actorCount = 500,
        nearbyActors = spec.nearby,
        expectedPromotedActors = spec.L,
        zombieCount = spec.Z,
        clientCount = 1,
        simulatedMs = 12000,
        stepMs = 50,
        profilerMode = "OFF",
    })
    printScaleRow(spec.label, r)
    assertCommonInvariants(spec.label, r)
    if spec.idle then
        T.equal(r.PeakPromotedHoomansRecords, 0, spec.label .. ": zero promoted")
        T.equal(r.ZombieAggroProcessed, 0, spec.label .. ": zero aggro work")
        T.truthy(r.CensusScans <= 16, spec.label .. ": slow idle census cadence")
    end
end

-- ============================================================================
-- D. Client Fan-Out & Mixed-Capability Repair: C = 1 / 4 / 16 & MIX_REPAIR
-- ============================================================================
printScaleHeader("D. CLIENT FAN-OUT & MIXED CAPABILITY REPAIR (N=500, L=6, Z=50, 10s, OFF)")
for _, c in ipairs({ 1, 4, 16 }) do
    local label = "N500_C" .. tostring(c)
    local r = runCase({
        actorCount = 500,
        nearbyActors = 14,
        expectedPromotedActors = 6,
        zombieCount = 50,
        clientCount = c,
        simulatedMs = 10000,
        stepMs = 50,
        profilerMode = "OFF",
    })
    printScaleRow(label, r)
    assertCommonInvariants(label, r)
    T.truthy(r.PresenceDeltas >= c * 50, label .. ": presence deltas fan out across clients")
end

local mixReport = runCase({
    actorCount = 500,
    nearbyActors = 14,
    expectedPromotedActors = 6,
    zombieCount = 50,
    clientCount = 4,
    mixedCapabilities = true,
    injectRevisionGap = true,
    simulatedMs = 8000,
    stepMs = 50,
    profilerMode = "OFF",
})
printScaleRow("N500_C4_MIX_REP", mixReport)
assertCommonInvariants("N500_C4_MIX_REP", mixReport)
T.truthy((mixReport.FallbackSnapshots or 0) > 0, "N500_C4_MIX_REP: legacy client received fallback")
T.truthy((mixReport.RepairSnapshots or 0) >= 1, "N500_C4_MIX_REP: gap repair converged")

-- ============================================================================
-- E. Demotion & Knowledge Mutation Storm Stress (N=500, OFF)
-- ============================================================================
printScaleHeader("E. LIFECYCLE DEMOTION & KNOWLEDGE MUTATION STORM (N=500, OFF)")
local depReport = runCase({
    actorCount = 500,
    nearbyActors = 14,
    expectedPromotedActors = 6,
    zombieCount = 50,
    clientCount = 1,
    departAtMs = 5000,
    simulatedMs = 12000,
    stepMs = 50,
    profilerMode = "OFF",
})
printScaleRow("N500_DEPART_DEM", depReport)
assertCommonInvariants("N500_DEPART_DEM", depReport)
T.truthy(depReport.DemotionsCount > 0, "N500_DEPART_DEM: reversible demotions executed")
T.equal(depReport.EndPromotedHoomansRecords, 0, "N500_DEPART_DEM: ended with 0 promoted records")

local mutReport = runCase({
    actorCount = 500,
    nearbyActors = 14,
    expectedPromotedActors = 6,
    zombieCount = 50,
    clientCount = 1,
    knowledgeMutationIntervalMs = 250,
    simulatedMs = 8000,
    stepMs = 50,
    profilerMode = "OFF",
})
printScaleRow("N500_MUT_STORM", mutReport)
assertCommonInvariants("N500_MUT_STORM", mutReport)
T.truthy(mutReport.LogicalCommits >= 25, "N500_MUT_STORM: >= 25 logical commits")
T.truthy(mutReport.PersistencePumps < mutReport.LogicalCommits, "N500_MUT_STORM: coalesced pumps")

-- ============================================================================
-- F. Profiler Overhead Control: OFF vs COARSE vs DEEP (20s)
-- ============================================================================
print("\nF. PROFILER OVERHEAD CONTROL (Z=64, 20s) — DEEP timings are explicit deep_instrumented_diagnostic_only")
print(string.rep("-", 116))
print(string.format(
    "%-14s | %-6s | %5s | %8s | %7s | %8s | %8s | %8s | %9s | %10s",
    "Scenario", "Mode", "CoreN", "Promoted", "DirtyEd", "FullSnap", "CoarseWr", "DeepWr", "DeepCalls", "TickCpuMs"
))
print(string.rep("-", 116))

for _, scenario in ipairs({
    { label = "N100_Z64_20s", actorCount = 100, nearbyActors = 14, expectedPromotedActors = 6, zombieCount = 64, simulatedMs = 20000, stepMs = 50 },
    { label = "N500_Z64_20s", actorCount = 500, nearbyActors = 14, expectedPromotedActors = 6, zombieCount = 64, simulatedMs = 20000, stepMs = 50 },
}) do
    local results = {}
    for _, mode in ipairs({ "OFF", "COARSE", "DEEP" }) do
        local opts = {}
        for k, v in pairs(scenario) do opts[k] = v end
        opts.profilerMode = mode
        opts.deepDurationMs = 60000
        local r = runCase(opts)
        results[mode] = r
        T.equal(r.SafePhaseFailures, 0, scenario.label .. " " .. mode .. " SafePhaseFailures")
        T.equal(r.RestoredCleanly, true, scenario.label .. " " .. mode .. " RestoredCleanly")
        if mode == "OFF" then
            T.equal(r.ProfilerDeepWrapperCalls, 0, scenario.label .. " OFF zero deep calls")
        end
        print(string.format(
            "%-14s | %-6s | %5d | %8d | %7d | %8d | %8d | %8d | %9d | %10.2f",
            scenario.label,
            mode,
            r.CoreActors,
            r.PromotedHoomansRecords,
            r.DirtyRecordsEnd,
            r.FullSnapshots,
            r.InitialCoarseWrappersInstalled,
            r.InitialDeepWrappersInstalled,
            r.ProfilerDeepWrapperCalls,
            r.TickLoopCpuMs
        ))
    end
    for _, field in ipairs({ "PromotedHoomansRecords", "DirtyRecordsEnd", "FullSnapshots", "SchedulerProcessed", "GlobalSaveCalls" }) do
        T.equal(results.COARSE[field], results.OFF[field], scenario.label .. " COARSE==OFF " .. field)
        T.equal(results.DEEP[field], results.OFF[field], scenario.label .. " DEEP==OFF " .. field)
    end
    local offMs = results.OFF.TickLoopCpuMs
    print(string.format(
        "  Delta vs OFF (%s): COARSE=%+.2f ms | DEEP=%+.2f ms (diagnostic only) | commits=%d serAtt=%d globalSaves=%d schedProc=%d",
        scenario.label,
        results.COARSE.TickLoopCpuMs - offMs,
        results.DEEP.TickLoopCpuMs - offMs,
        results.OFF.LogicalCommits,
        results.OFF.SerializationAttempts,
        results.OFF.GlobalSaveCalls,
        results.OFF.SchedulerProcessed
    ))
end

print("\nALL L5 BENCHMARK MATRIX ASSERTIONS PASSED.")
