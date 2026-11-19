-- Deterministic headless L0 baseline benchmark (NON-NATIVE Lua simulator).
-- Run from repository root: lua tests/benchmarks/lightweight_npc_runtime.lua
local Simulator = require "tests/support/lightweight_runtime_simulator"

local scenarios = {
    { label = "N100_Z64_20s", actorCount = 100, nearbyActors = 14, expectedPromotedActors = 6, zombieCount = 64, simulatedMs = 20000, stepMs = 50 },
    { label = "N500_Z64_20s", actorCount = 500, nearbyActors = 14, expectedPromotedActors = 6, zombieCount = 64, simulatedMs = 20000, stepMs = 50 },
}

print("HEADLESS LUA SIMULATOR (NON-NATIVE) — L0 Profiler OFF vs COARSE vs DEEP Baseline")
print(string.rep("-", 110))
print(string.format(
    "%-14s | %-6s | %5s | %8s | %7s | %8s | %8s | %8s | %9s | %10s",
    "Scenario", "Mode", "CoreN", "Promoted", "DirtyEd", "FullSnap", "CoarseWr", "DeepWr", "DeepCalls", "TickCpuMs"
))
print(string.rep("-", 110))

for _, scenario in ipairs(scenarios) do
    local results = {}
    for _, mode in ipairs({ "OFF", "COARSE", "DEEP" }) do
        local opts = {}
        for k, v in pairs(scenario) do opts[k] = v end
        opts.profilerMode = mode
        opts.deepDurationMs = 60000
        opts.quiet = true
        local report = Simulator.New(opts):Run()
        results[mode] = report
        print(string.format(
            "%-14s | %-6s | %5d | %8d | %7d | %8d | %8d | %8d | %9d | %10.2f",
            scenario.label,
            mode,
            report.CoreActors,
            report.PromotedHoomansRecords,
            report.DirtyRecordsEnd,
            report.FullSnapshots,
            report.InitialCoarseWrappersInstalled,
            report.InitialDeepWrappersInstalled,
            report.ProfilerDeepWrapperCalls,
            report.TickLoopCpuMs
        ))
    end
    local offMs = results.OFF.TickLoopCpuMs
    local coarseDelta = results.COARSE.TickLoopCpuMs - offMs
    local deepDelta = results.DEEP.TickLoopCpuMs - offMs
    print(string.format(
        "  Delta vs OFF (%s): COARSE=%+.2f ms | DEEP=%+.2f ms | commits=%d serAttempts=%d globalSaves=%d schedProc=%d schedDef=%d",
        scenario.label,
        coarseDelta,
        deepDelta,
        results.OFF.LogicalCommits,
        results.OFF.SerializationAttempts,
        results.OFF.GlobalSaveCalls,
        results.OFF.SchedulerProcessed,
        results.OFF.SchedulerDeferred
    ))
end
