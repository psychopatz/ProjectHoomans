-- Regression smoke test for server/client hot-path optimizations:
-- Tasking.Collect emergency short-circuit, Autonomy Validate context reuse &
-- combat/follow guards, ShockingReaction vs CombatGuard preemption,
-- Provision combat bandage-rip guard, and SP/MP LocalSnapshots safety.
local T = require "tests/support/test"

T.addPackagePaths()

local fn, err = loadfile("tests/benchmarks/tasking_provision_and_snapshot_flow.lua")
assert(fn, "failed to load hotpath benchmark: " .. tostring(err))
fn()
