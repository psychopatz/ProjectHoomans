# Progress: UnifiedSchemaDrivenNPCAI

Parent goal: IN PROGRESS
Current phase: Phase U4 — GTA V / RDR2 Behavioral Reactivity & Secondary Channel

Accepted:

* Phase U0 — Live Workspace Audit, Prerequisite Verification & Manifest Freeze (`d987bf1c9902cd824cd1c455c597651dc3863de0`).
* Phase U1 — RimWorld Work Foundation Unification (`a598e8b9c1e2fe86b505e543b73cd63f52dfd2a5`).
* Phase U2 — `CodeBuilder` Multi-IR Expansion (`psychopatzCore` @ `010a6260cabe39f210095ba3d1bfb710d35b98cf`, `ProjectHoomans` @ `13ca3255df7dab59202ba2322920239a83f3f7d0`).
* Phase U3 — Sims Band-Gated Autonomy & Co-Presence Unification:
  * Created `server/PNC/Tasking/Autonomy/{PNC_AutonomyScorer,PNC_CoPresenceService,PNC_AutonomyTaskProvider}.lua` driven by compiled `PNC.AutonomyAd.Registry` (`PNC_SharedComposition_Final.lua`, `PNC_TaskProviders.lua`), keeping `GetCandidates` read-only (`PreviewSeat`), bounding evaluations (`<= 64`) and neighbor scans (`<= 16`), and enforcing `OPTIONAL`/`IDLE` band precedence + `PNC.Tasking.Claims`.
  * Refactored `PNC_AmbientFacilityService`, removed `PNC_LivingRoomService` dead `Registry.ForEach` loop, gated `PNC_Server_SubsystemPumps` ambient poll, exposed `PNC_RoamingSeatService` helpers, updated `PNC_RoamAmbientTick` & `PNC_BehaviorSystem_Tick_Ownership` for `taskLeaseId` safety, exempted `Const.ORDER_ROAM` in `PNC_Tasking_Evaluation.H.ExternalCurrent`, routed idle behavior callers via `AMBIENT_OPPORTUNITY`, and wired `HydrateOnPromotion` in `PNC_Persistence_CoreProvider`.
  * Extended `PNC_Tasking_Queries.BuildBrain`, `PNC_ColonistWindow`, and `PNC_ColonistDebugRows` to project `activeBand`, `claims`, `leaseClaims`, `autonomyDiagnostics`, and Co-Presence rows on `"debug"` tab with zero Debug-OFF overhead.

Current evidence:

* `TEST_VERIFIED` (U3): ProjectHoomans Lua focused suites: `u3_autonomy` (1/1), `follow_need_preemption` (1/1), `mp_server_file_guard` (1/1, 1063 files), `seating` (1/1), `roam_ambient` (1/1), `roaming_floor_seat` (1/1), `colonist_ui` (1/1), `colonist_activities` (1/1), `colonist_task` (1/1), `tasking` (8/8), `composition_bootstrap` (1/1), `seated_threat` (1/1), `player_roam` (1/1) — 20/20 passed.
* `TEST_VERIFIED` (U2): `psychopatzCore` `python3 -m unittest` (30/30 OK), Core Lua social tests (5/5 PASS), `reconcile.py --check` clean, `convo_engine_naming_audit.py --summary` (`ok=true, activeCurrentPsdlIdentityCount=0`), `DynamicTrading` (92/92 PASS), `PASS generated_ai_ir_registries_lua_load`.
* `TEST_VERIFIED` (U1): `u1_work_foundation` + focused work/farming/lumber/fishing/corpse/tasking suites — 81/81 passed.
* `STATIC_ONLY`: `pz-verify --kahlua --severity ERROR` returned 0 errors across all 24 U3 production Lua files, all U1/U2 Lua files, and `PsychopatzSocial*.lua`.

Known gap:

* Phase U4 targets: bounded spatial `PsychopatzShockingEventBus` in `psychopatzCore` (`core.shocking_events`, omitted from DT packs); activity-sensitive `PerceptionService` (local squared-dist + precomputed cosine azimuth filter, budgeted `LosUtil.lineClear`/`CanSee` queue, `Events.OnWorldSound`, `ClueMemory`); compiled `ReactionPolicy IR` decision tables & non-lethal shocking-event providers; sparse lazy-decay `AgitationService`; time-of-day scenario chaining; orthogonal Non-Interrupting Secondary Layer (`faceLocationF`, Build 42 `AnimSets` state variables, priority-gated barks with line-exhaustion decay & cleanup).

Next Chunk: Chunk U4A — Plan and implement Phase U4 (`psychopatzCore` `PsychopatzShockingEventBus` + Core capability catalog first -> `ProjectHoomans` Perception, ReactionPolicy, Agitation, Scenario chaining, and Secondary Channel second).

Immediate acceptance:

* Spatial `PsychopatzShockingEventBus` works cleanly in Core and remains excluded from `DynamicTrading` (`Core + DTCommon + DTAbstract`).
* Zero per-tick tile scans or decay loops; alerted NPCs investigate bounded `ClueMemory` clues rather than wall-hacking; secondary gaze/barks never cancel active `PNC.Tasking` leases; domain-delta MP replication preserved.
