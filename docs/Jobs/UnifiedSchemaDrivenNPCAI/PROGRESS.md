# Progress: UnifiedSchemaDrivenNPCAI

Parent goal: IN PROGRESS
Current phase: Phase U3 — Sims Band-Gated Autonomy & Co-Presence Unification

Accepted:

* Phase U0 — Live Workspace Audit, Prerequisite Verification & Manifest Freeze (`d987bf1c9902cd824cd1c455c597651dc3863de0`).
* Phase U1 — RimWorld Work Foundation Unification:
  * Added `PNC.Tasking.Claims` (`server/PNC/Tasking/PNC_Tasking_Claims.lua`) with automatic lease teardown (`PNC_TaskLeaseService_Release.lua`), rollback (`PNC_Tasking_Assignment.lua`), and orphan pruning (`PNC_Tasking_Pump_Reconciliation.lua`).
  * Added `WorkToilRunner.AbortOrder` (`PNC_WorkToilRunner.lua`) and bridged `WorkService`, `WorkZoneService`, `LumberService`, and `CorpseHaulService` claims.
  * Implemented missing `WorkService.RegisterOperation` (`PNC_WorkService_OperationRegistry.lua`, fixing live `FARMING`/`FISHING` registration) and sorted deterministic `ReconcileHandlers` dispatch (`PNC_WorkService_Scheduler_Pump.lua`).
  * Wired `FARMING`, `FISHING`, `LUMBER`, and `CORPSE_HAUL` onto `WorkService.RegisterReconciler`; gated standalone `CorpseHaulService` `Events.OnTick`, duplicate `LumberService.Pump` reconcile, and legacy `"farming"` Tasking provider when `WorkService` is active.
* Phase U2 — `CodeBuilder` Multi-IR Expansion (`psychopatzCore` @ `010a6260cabe39f210095ba3d1bfb710d35b98cf`, `ProjectHoomans` starter packages + generated artifacts):
  * Added `ai_ir_core.py`, `autonomy_ad_compiler.py`, `reaction_policy_compiler.py`, `work_scenario_compiler.py`, and two-pass `ai_cross_ir_linker.py` with `abstract`/`parent` flattening, JSON Patch overlays, and static Build 42 `AnimSets`/`PNC.NPCVoice.Catalog.Events` key validation.
  * Extended `SocialPolicy` compiler + `PsychopatzSocial.lua`/`PsychopatzSocialRetention.lua` runtime with `stackLimit`, `stackedEffectMultiplier`, and `nullifyingTraits`.
  * Aligned `reconcile.py` header checks, updated `generation_recipe.json`/`generation_ownership.py`/`targets/pz_packages.json`, authored `ProjectHoomans` starter packages (`autonomy_ad`, `reaction_policy`, `work_scenario`), and generated 6 clean flat Lua registries/defs.

Current evidence:

* `TEST_VERIFIED` (U1): ProjectHoomans Lua focused suites: `u1_work_foundation` (1/1), `mp_server_file_guard` (1/1, 1060 files), `work` (33/33), `farming` (5/5), `lumber` (8/8), `fishing` (10/10), `corpse` (15/15), `tasking` (8/8) — 81/81 passed.
* `TEST_VERIFIED` (U2): `psychopatzCore` `python3 -m unittest` (30/30 OK including `test_live_three_repository_integrity_audit_and_two_pass_determinism`), Core Lua social tests (5/5 PASS), `reconcile.py --check` clean (`missing=0, drifted=0, stale=0, retired_present=0, ambiguous=0`), `convo_engine_naming_audit.py --summary` (`ok=true, activeCurrentPsdlIdentityCount=0, violatingFiles={}`), `DynamicTrading` standalone suite (92/92 PASS), generated `ProjectHoomans` Lua registries load check (`PASS generated_ai_ir_registries_lua_load`).
* `STATIC_ONLY`: `pz-verify --kahlua --severity ERROR` returned 0 errors across all 22 U1 production Lua files, `PsychopatzSocial*.lua`, and all 6 U2 generated `ProjectHoomans` Lua files; zero `isFarmer` gates across `Contents/mods/ProjectHoomans/`.

Known gap:

* Phase U3 targets: `PNC_LivingRoomService` (`PNC_AmbientFacilityService`), `PNC_RoamingSeatService`, and `PNC_RoamAmbientService` still bypass `PNC.Tasking`; `PNC.AutonomyScorer` / `PNC.CoPresenceService` / `PNC.AutonomyTaskProvider` do not yet exist; Colonists Debug UI only requests `taskBrain` on the `"task"` tab and lacks active band, claims, autonomy candidates, and Co-Presence diagnostics.

Next Chunk: Phase U3 — Sims Band-Gated Autonomy & Co-Presence Unification (`PNC_AutonomyScorer`, `PNC_CoPresenceService`, `PNC_AutonomyTaskProvider`, ambient/behavior refactoring, lazy-promotion hydration, Colonists Debug GUI wiring).

Immediate acceptance:

* Zero bypassed `Registry.ForEach` ambient polling loops; all autonomous facilities, seats, and roaming register as `OPTIONAL`/`IDLE` `PNC.Tasking` candidates with hysteresis and cooldowns.
* Intra-band trait/mood/distance scoring never preempts higher semantic bands; Co-Presence Situations route into `SceneAdopters.SubmitSocial`.
* Colonists Debug GUI renders `taskBrain` + autonomy/claim diagnostics on `"debug"` tab with zero Debug-OFF overhead; U3 focused Lua suites and `pz-verify` pass cleanly.
