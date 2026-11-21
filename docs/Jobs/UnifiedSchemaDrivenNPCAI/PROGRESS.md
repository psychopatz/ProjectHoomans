# Progress: UnifiedSchemaDrivenNPCAI

Parent goal: IN PROGRESS
Current phase: Phase U6 — Cross-Tier Scale Proof, Full Harness Acceptance & Final Closure

Accepted:

* Phase U0 — Live Workspace Audit, Prerequisite Verification & Manifest Freeze (`d987bf1c9902cd824cd1c455c597651dc3863de0`).
* Phase U1 — RimWorld Work Foundation Unification (`a598e8b9c1e2fe86b505e543b73cd63f52dfd2a5`).
* Phase U2 — `CodeBuilder` Multi-IR Expansion (`psychopatzCore` @ `010a6260cabe39f210095ba3d1bfb710d35b98cf`, `ProjectHoomans` @ `13ca3255df7dab59202ba2322920239a83f3f7d0`).
* Phase U3 — Sims Band-Gated Autonomy & Co-Presence Unification (`24d7bcd96389cce3b6541248a9f1c7f4d1c27c61`).
* Phase U4 — GTA V / RDR2 Behavioral Reactivity & Secondary Channel (`psychopatzCore` @ `2a32bb7eb43a8331a95ff3a8760d94abd70ca127`, `ProjectHoomans` @ `6800ec9c9185366815d68e3deb34093dcc75b425`).
* Phase U5 — S13D–S13F Prerequisite Gate + Façade-Inspired Dialogue Director & RDR2 Street Interaction (`psychopatzCore` @ `bbd9fee90a96f63323129ea29e5bf76e2f1525be`, `DynamicTrading` @ `d4034fac5f547e00253dc3b9db5fd4554e37b535`, `ProjectHoomans`):
  * Closed `ConvoEngine` S13D–S13F across Core, DynamicTrading, and Hoomans: retired all duplicate `Behaviors/Director/*` & `Beats/Director/*` projections, generated `ConvoEngine/Index/Director.lua`, and updated provider tests.
  * Added `PNC_DialogueMicroBeatDirector` (5-stage deterministic micro-beats, ephemeral scene tension, causally independent global mix-ins, zero LLM calls), `PNC_JointSceneLeaseService` (server-owned 2–4 participant leases with secondary listener reactivity and `HARD_EMERGENCY`/demotion/reanimation abort cleanup), `PNC_StreetInteractionService` (`GREET`/`ANTAGONIZE`/`DEFUSE` acts linked to `AgitationService`, `SecondaryChannel`, and `DialogueMicroBeatDirector`), and `PNC_SocialWitnessService` (witness-only `PsychopatzSocial` memory recording + deduplicated 1-hop hearsay).
  * Wired `PNC_SemanticEventRuntime`, `PNC_CoPresenceService` (`InteractionSceneAdopters`), `PNC_SocialGreetingService.HandleStreetAct`, `PNC_Presence_Abstract`, `PNC_BodyLifecycle_Reanimation`, `PNC_Tasking_Queries.BuildBrain`, Colonists Debug GUI (`debug_ai_dialogue_director`), and fixed `PNC_ColonistDepartureService_Depart` nil `PNC.OrderSystem` guard.

Current evidence:

* `TEST_VERIFIED` (U5):
  * `psychopatzCore`: `357/357` Python unittests OK; `14/14` Core Lua smokes PASS; `reconcile.py --check` clean (`missing=0, drifted=0, stale=0, retired_present=0, ambiguous=0`); `convo_engine_cli director-readiness --summary` `ok=true` (all 5 counters `0`, all 8 `readinessChecks=true`); `audit-integrity --check-determinism` OK (`fileCount=446`, `diffs=[]`); `convo_engine_naming_audit --summary` (`ok=true, activeCurrentPsdlIdentityCount=0`); `pz-verify --kahlua` 0 errors.
  * `DynamicTrading`: `92/92` PASS; `pz-verify --kahlua` 0 errors on reconciled `DTCommon/ConvoEngine/Registry.lua`.
  * `ProjectHoomans`: `32/32` U5b focused Lua suites PASS (`u5_dialogue`, `semantic_interaction`, `social_director`, `social_conversation`, `social_greeting`, `social_event`, `u4_reactivity`, `u3_autonomy`, `mp_server_file_guard` @ `1071`, `composition_bootstrap`, `tasking`, `colonist_ui`, `colonist_task`, `reanimation`); `19/19` U5a provider Python OK; `test_dialogue_completeness_workbench` PASS; full provider Python `156/165` modules PASS (`651` tests run, `27` skipped, `10` failures + `3` errors across 9 pre-U0 semantic-harness fixture drifts untouched).
* `STATIC_ONLY` (U5): `pz-verify --kahlua --severity ERROR` returned `0` errors across all 16 U5 production, generated, and test Lua files (`pnc_mp_server_file_guard_smoke.lua` expectedly uses host `io.*`). `git diff --check` clean.
* `TEST_VERIFIED` (U4): Core `psychopatz_shocking_event_bus_smoke`, `psychopatz_capability_contract_smoke`, `psychopatz_boundary_isolation_smoke` OK; `DynamicTrading` 92/92 PASS; ProjectHoomans 13 suites — 29/29 PASS.
* `TEST_VERIFIED` (U3): ProjectHoomans 13 Lua suites — 20/20 PASS.
* `TEST_VERIFIED` (U2): `psychopatzCore` 30/30 Python + 5/5 Lua + `reconcile.py --check` clean; `DynamicTrading` 92/92 PASS; `PASS generated_ai_ir_registries_lua_load`.
* `TEST_VERIFIED` (U1): `u1_work_foundation` + focused work/farming/lumber/fishing/corpse/tasking suites — 81/81 passed.

Known gap:

* **Phase U6**: Add cross-tier scale proof (`tests/pnc_u6_unified_ai_scale_smoke.lua`), run full multi-repo suites + real PZ headless Kahlua JVM harness (`pz-runtime-harness`), run independent adversarial verification pass, and reconcile `docs/01_SYSTEM_MAP.md` & final job closure (`READY FOR USER LIVE TEST`).

Next Chunk: Chunk U6A — Create `tests/pnc_u6_unified_ai_scale_smoke.lua`, execute full 3-repo + headless Kahlua JVM verification, run adversarial verification, and close U6 docs/commit.

Immediate acceptance:

* Full Lua suite passes 100%, `DynamicTrading` (`Core + DTCommon + DTAbstract`) passes 92/92, Core suites pass 100%, `pz-runtime-harness` passes cleanly, zero mandatory verifier findings, and parent is marked `READY FOR USER LIVE TEST`.
