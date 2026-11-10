---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P3-E"
phase_commit_message: "phase(P3-E): compose optional DynamicTrading launch matrix"
phase_commit_vector: "project-hoomans=self"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "d1da19d15426956852ddf4e0d9517f028797b541"
updated_at: "2026-11-10T00:01:11.379618Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P3"
chunk: "P3-E"
retrieval_tier: "verify"
---





# Handoff — Semantic Harness Core Migration

## What became true

P3-C moves the generic worker-client configuration seam into Core. Core's
`WorkerLaunchSpec` can consume validated profile metadata and emits the
neutral `SEMANTIC_HARNESS_*` launch environment. Core's process lifecycle
remains the only implementation of transport, correlation, bounded errors,
and shutdown handling.

Project Hoomans keeps provider policy local: repository/runtime discovery,
physical worker selection, private environment aliases, worker arguments,
scenario defaults, and production-module registration. Its
`build_worker_launch_spec()` adapter now creates Core's launch spec directly.

All production and test callers now import Core directly for process,
protocol, and serialized session mechanics. The unreferenced Hoomans facade
files `runtime/process.py`, `runtime/protocol.py`, and
`runtime/worker_session.py` were deleted. Remaining Hoomans scenario,
activity, configuration, UI, and production-policy modules are intentional
adopter surfaces or compatibility boundaries for the next chunk.

DynamicTrading remains optional and owns only its declarative provider
manifest, DTCommon merchant policy, DTAbstract abstract capability, and
DTHoomans physical capability. Core does not import DynamicTrading or
Project Hoomans.

## P3-E result

Hoomans includes DTCommon/DTHoomans in launch metadata only when the optional
DynamicTrading runtime is discovered. DynamicTrading's abstract and physical
profile selections both round-trip through Core `WorkerLaunchSpec` with the
same neutral environment contract.

## Resume

1. Verify the three repository worktrees and phase commits.
2. Run Core's full semantic-harness suite, the Hoomans migration/regression
   slice, and DynamicTrading provider adapter gates.
3. Audit remaining Hoomans runtime/worker Lua modules for provider-neutral
   duplicates as the P4 cleanup boundary.
4. Keep native Project Zomboid SP/MP validation user-owned unless explicitly
   requested.

## Evidence

- `CODE_VERIFIED`: Core owns the neutral launch metadata seam and Hoomans has
  no remaining callers of the three deleted runtime paths.
- `TEST_VERIFIED`: Core suite 36 tests; Hoomans migration/regression slice;
  DynamicTrading provider-adapter Python and Lua smoke gates.
- `STATIC_ONLY`: provider callbacks are declared and adapter-smoked but not
  executed by the minimal Core worker.
- `UNVERIFIED`: native Project Zomboid SP/MP behavior remains user-owned.
- No Workshop publication is claimed.

## Residual findings

The broader Hoomans `test_harness` suite retains the previously documented
three unrelated translation/identity catalog failures: false-name response
disclosure, Tagalog identity translation, and Tagalog identity/self-reflection
catalog use. They are outside this migration boundary.
