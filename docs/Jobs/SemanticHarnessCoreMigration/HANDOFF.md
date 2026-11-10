---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P5-C"
phase_commit_message: "phase(P5-C): docs: prepare P5-C native acceptance runbook"
phase_commit_vector: "project-hoomans=self;psychopatz-core=c07babcee33291256bf20847200341265a755969;dynamic-trading=0bd7b1472f6b921275f136f9a0900bacd2eb2e3d"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;psychopatz-core=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "d1da19d15426956852ddf4e0d9517f028797b541"
updated_at: "2026-11-10T02:06:31.853397Z"
state: "USER_ACCEPTANCE"
parent_status: "IN_PROGRESS"
phase: "P5"
chunk: "P5-C"
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

## P4-A result

The import-zero audit removed the remaining pure Hoomans activity/state and
CodeBuilder naming/translation facades plus duplicate generic tests. Remaining
Hoomans runtime/Lua modules are provider policy, save/profiler ingestion,
authoring, or physical-worker integration and require a separate behavior
contract before any further move.

## P4-D result

The active native log exposed two concrete migration defects. Hoomans records
were created without a canonical Core actor, so social synchronization returned
`core_actor_not_found`; partially migrated Hoomans world records could then
reference factions absent from Core, so group commits returned
`survivor_world_group_faction_missing`.

The phase implementation adds Core's idempotent actor ensure seam, Hoomans
actor adoption at lifecycle and affiliation boundaries, and an additive
Hoomans SurvivorWorld repair ordered as factions, locations, communities, then
groups. Existing Core records are not overwritten. Fresh native confirmation is
not claimed yet.

## Resume

1. Verify the P5-B phase commit vector across Core, DynamicTrading, and
   Hoomans.
2. Hand the P5-C native SP/MP matrix to the user with the running game/save
   authority.
3. Keep native Project Zomboid validation user-owned unless explicitly
   requested.

## Evidence

- `CODE_VERIFIED`: Core owns neutral launch metadata and optional-adopter
  loading; Hoomans has no remaining callers of the three deleted runtime
  paths.
- `TEST_VERIFIED`: Core 45/45, DynamicTrading provider tests 5/5, Hoomans
  runtime/provider slice 11/11, DT Lua adapter smoke, and direct Lua load
  checks.
- `STATIC_ONLY`: native Project Zomboid behavior and full SP/MP provider
  traversal remain unverified.
- `UNVERIFIED`: native Project Zomboid SP/MP behavior remains user-owned.
- No Workshop publication is claimed.

## P4-B result

The final ownership inventory is recorded in
`P4B_OWNERSHIP_AUDIT.md`. Core has no adopter imports, deleted Hoomans
Core-only paths are absent, and the focused developer-side gates pass. The
remaining unverified work is native SP/MP acceptance of restart persistence,
optional-mod toggles, nearby physical materialization, abstract traversal,
and cross-provider conversation/trade behavior.

## P4-E result

PsychopatzCore now owns the provider-neutral high-level `SemanticWorker`
facade for process startup, source snapshots, working-world state,
reset/reload/restart, and generic request/status/capability access. Hoomans
`LuaSemanticWorker` subclasses it and retains only Hoomans scenario policy,
fixture provenance, bounded save/registry/item side requests, and semantic
operation spokes. Core suite 38/38 and Hoomans worker/runtime slice 16/16 pass.

## P4-F result

Core now owns the provider-neutral engine fixture, health, item catalog,
profiler projection, and native player decoder modules. Hoomans retains only
thin adapters for PNC identity matching and Project Hoomans profiler aliases;
remaining Hoomans runtime modules are save, scenario, physical-worker,
authoring, knowledge, and provider-policy code. Core generic projection
modules contain no adopter identifiers. Core 43/43 and the Hoomans
engine-projection/worker slice 23 tests passed, with environment-dependent
skips.

## P5-A result

The developer-side cross-provider matrix passed: Core profile/worker/process/
registry/layout checks 15/15; Hoomans optional-provider and real-Lua checks
8/8; DynamicTrading provider-adapter checks 4/4; and the DynamicTrading Lua
semantic-execution adapter smoke passed. Core-only, Hoomans, DTAbstract, and
DTHoomans metadata paths are covered. No native Project Zomboid process was
launched.

## Residual findings

The broader Hoomans `test_harness` suite retains the previously documented
three unrelated translation/identity catalog failures: false-name response
disclosure, Tagalog identity translation, and Tagalog identity/self-reflection
catalog use. They are outside this migration boundary.

## P5-B result

PsychopatzCore now owns the optional-adopter worker loading seam.
`WorkerLaunchSpec` emits neutral module-path, module-name, and
execution-provider metadata. The Core Lua worker loads only the modules named
by that metadata, validates their Core `SemanticExecution` result, advertises
the loaded descriptions, and dispatches generic `SEMANTIC_PROVIDER` operations.
Empty metadata preserves the standalone Core worker.

DynamicTrading supplies `provider_worker_launch_values()` as its thin adapter.
Actual DTAbstract and DTHoomans modules load through the same Core worker and
receive the same operation dispatch; only `abstract` versus `physical`
materialization differs. No native Project Zomboid process was launched.

## P5-C preparation

The executable native acceptance checklist is
`P5C_NATIVE_ACCEPTANCE_RUNBOOK.md`. It covers Core-only bootstrap, Hoomans
physical materialization, DTHoomans shared identity/conversation/trade,
DTAbstract abstract traversal, independent adopter toggles, restart persistence,
and native multiplayer authority/reconnect. It is explicitly user-owned and
currently **UNVERIFIED**; no native Project Zomboid process was launched by
this phase.

## Next

P5-C is the user-owned native SP/MP matrix: restart persistence, independent
mod toggles, nearby DTHoomans materialization, DTAbstract abstract traversal,
and shared conversation/trade behavior. The parent goal remains in progress.
