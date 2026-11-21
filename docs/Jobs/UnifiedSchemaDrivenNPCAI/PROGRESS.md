# Progress: UnifiedSchemaDrivenNPCAI

Parent goal: IN PROGRESS
Current phase: Phase U5 — S13D–S13F Prerequisite Gate + Façade-Inspired Dialogue Director & RDR2 Street Interaction

Accepted:

* Phase U0 — Live Workspace Audit, Prerequisite Verification & Manifest Freeze (`d987bf1c9902cd824cd1c455c597651dc3863de0`).
* Phase U1 — RimWorld Work Foundation Unification (`a598e8b9c1e2fe86b505e543b73cd63f52dfd2a5`).
* Phase U2 — `CodeBuilder` Multi-IR Expansion (`psychopatzCore` @ `010a6260cabe39f210095ba3d1bfb710d35b98cf`, `ProjectHoomans` @ `13ca3255df7dab59202ba2322920239a83f3f7d0`).
* Phase U3 — Sims Band-Gated Autonomy & Co-Presence Unification (`24d7bcd96389cce3b6541248a9f1c7f4d1c27c61`).
* Phase U4 — GTA V / RDR2 Behavioral Reactivity & Secondary Channel (`psychopatzCore` @ `2a32bb7eb43a8331a95ff3a8760d94abd70ca127`, `ProjectHoomans`):
  * Added bounded spatial `PsychopatzShockingEventBus` (`core.shocking_events`, excluded from `DynamicTrading` packs) with 128-event capacity eviction, 1000ms dedup, spatial cell queries, and TTL pruning.
  * Added `PNC_PerceptionService` (activity-sensitive cadence, squared-distance + `cosHalfFov` cone pre-filter, budgeted `<= 8`/tick LOS queue, bounded `ClueMemory`, `OnWorldSound` hook), sparse lazy-decay `PNC_AgitationService`, deterministic `PNC_ReactionPolicyEvaluator`, `PNC_ShockingReactionTaskProvider` (all 5 non-lethal intents + `Tasking.Claims`), and `PNC_ScenarioScheduler`.
  * Added orthogonal `PNC_SecondaryChannel` (coincident-guarded `faceLocationF`, Build 42 `AnimSet` variables replicated via `BuildPresenceDelta` and reset cleanly on reanimation/demotion/abstraction, speech-priority-gated barks with `180s` lazy line-exhaustion recovery & `NPCVoice.Stop` cleanup, zero cancellation of active tasks) and Colonists Debug GUI reactivity rows.

Current evidence:

* `TEST_VERIFIED` (U4): Core `psychopatz_shocking_event_bus_smoke`, `psychopatz_capability_contract_smoke`, `psychopatz_boundary_isolation_smoke` OK; `DynamicTrading` 92/92 PASS; ProjectHoomans 13 suites (`u4_reactivity` 1/1, `u3_autonomy` 1/1, `mp_server_file_guard` 1/1 @ 1067, `composition_bootstrap` 1/1, `tasking` 8/8, `perception` 5/5, `voice` 5/5, `domain_delta` 1/1, `local_snapshot` 2/2, `reanimation` 1/1, `awareness` 1/1, `colonist_ui` 1/1, `colonist_task` 1/1) — 29/29 PASS.
* `TEST_VERIFIED` (U3): ProjectHoomans Lua focused suites: `u3_autonomy` (1/1), `follow_need_preemption` (1/1), `mp_server_file_guard` (1/1, 1063 files), `seating` (1/1), `roam_ambient` (1/1), `roaming_floor_seat` (1/1), `colonist_ui` (1/1), `colonist_activities` (1/1), `colonist_task` (1/1), `tasking` (8/8), `composition_bootstrap` (1/1), `seated_threat` (1/1), `player_roam` (1/1) — 20/20 passed.
* `TEST_VERIFIED` (U2): `psychopatzCore` `python3 -m unittest` (30/30 OK), Core Lua social tests (5/5 PASS), `reconcile.py --check` clean, `convo_engine_naming_audit.py --summary` (`ok=true, activeCurrentPsdlIdentityCount=0`), `DynamicTrading` (92/92 PASS), `PASS generated_ai_ir_registries_lua_load`.
* `TEST_VERIFIED` (U1): `u1_work_foundation` + focused work/farming/lumber/fishing/corpse/tasking suites — 81/81 passed.
* `STATIC_ONLY`: `pz-verify --kahlua --severity ERROR` returned 0 errors across 3 Core U4 files, 22 Hoomans U4 production files, all U1–U3 Lua files, and `PsychopatzSocial*.lua`.

Known gap:

* Hard gate **U5a** (`ConvoEngine` S13D–S13F in `psychopatzCore` + `ProjectHoomans` + `DynamicTrading`): collapse duplicate `Behaviors/Director/*` & `Beats/Director/*` projections into canonical `Behavior/*` & `Beat/*` and freeze Director metadata.
* **U5b**: Deterministic zero-LLM Dialogue Director atop `ConvoEngine v1` & `SemanticSocialConversationDirector` (5-stage micro-beats, ephemeral scene tension, global mix-ins, server-owned `JointSceneLease`, `GREET`/`ANTAGONIZE`/`DEFUSE` acts linked to `AgitationService`, witness-only `PsychopatzSocial` hearsay propagation).

Next Chunk: Chunk U5A — Audit `psychopatzCore` S13D–S13F status, close S13D–S13F cleanly across Core/Hoomans/DT first, then implement Phase U5b Dialogue Director & RDR2 Street Interaction.

Immediate acceptance:

* S13D–S13F readiness counters zero (`duplicateBehaviorProjectionBodies=0`, `duplicateBeatProjectionBodies=0`, `obsoleteDirectorProjectionCallers=0`).
* Multi-NPC 2–4 participant micro-beats, global mix-in interrupts, `GREET`/`ANTAGONIZE`/`DEFUSE` acts, and witness-only hearsay run deterministically with zero LLM calls; `DynamicTrading` (`Core + DTCommon + DTAbstract`) passes 100%.
