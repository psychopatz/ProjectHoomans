# Progress: UnifiedSchemaDrivenNPCAI

Parent goal: READY FOR USER LIVE TEST
Current phase: User-Owned Native SP/MP Live Acceptance (Developer-side Phases U0–U6 COMPLETE)

Accepted:

* Phase U0 — Live Workspace Audit, Prerequisite Verification & Manifest Freeze (`d987bf1c9902cd824cd1c455c597651dc3863de0`).
* Phase U1 — RimWorld Work Foundation Unification (`a598e8b9c1e2fe86b505e543b73cd63f52dfd2a5`).
* Phase U2 — `CodeBuilder` Multi-IR Expansion (`psychopatzCore` @ `010a6260cabe39f210095ba3d1bfb710d35b98cf`, `ProjectHoomans` @ `13ca3255df7dab59202ba2322920239a83f3f7d0`).
* Phase U3 — Sims Band-Gated Autonomy & Co-Presence Unification (`24d7bcd96389cce3b6541248a9f1c7f4d1c27c61`).
* Phase U4 — GTA V / RDR2 Behavioral Reactivity & Secondary Channel (`psychopatzCore` @ `2a32bb7eb43a8331a95ff3a8760d94abd70ca127`, `ProjectHoomans` @ `6800ec9c9185366815d68e3deb34093dcc75b425`).
* Phase U5 — S13D–S13F Prerequisite Gate + Façade-Inspired Dialogue Director & RDR2 Street Interaction (`psychopatzCore` @ `bbd9fee90a96f63323129ea29e5bf76e2f1525be`, `DynamicTrading` @ `d4034fac5f547e00253dc3b9db5fd4554e37b535`, `ProjectHoomans` @ `0e35ae37deb6e385a806136bfa1edbca9acfe8e6`).
* Phase U6 — Cross-Tier Scale Proof, Multi-Repo Verification, Adversarial Audit & Closure (`ProjectHoomans` local commit):
  * Added Kahlua2-clean `tests/pnc_u6_unified_ai_scale_smoke.lua` (`pz-verify --kahlua --severity ERROR` 0 errors/0 warnings) verifying `O(N)`/`O(L)` 200-abstract + 6-live scaling, `<= 64` autonomy evaluation cap, `SAME_BAND_MARGIN = 0.08`, 8-band wall, `<= 8`/tick LOS queue on 32 threats, demotion teardown, 200-event `PsychopatzShockingEventBus` FIFO `128` cap + `1000ms` dedup + `HARD_EMERGENCY` `JointSceneLease` abort, `O(dirty)` 4-chore `WorkService` + `AbortOrder`, 3-NPC micro-beat + global mix-in (`llmCalls = 0`), RDR2 `GREET`/`ANTAGONIZE`/`DEFUSE` + witness-only `PsychopatzSocial` hearsay, compact `SecondaryChannel` presence delta, and profiler-OFF zero overhead.
  * Closed adversarial Check #3 finding: updated `PNC_Presence_Abstract.notifyAbstraction` to pass `zombie` into `PNC.SecondaryChannel.ClearForRecord(record, zombie)` and updated `PNC_BodyLifecycle_Reanimation.ReleaseReanimatedNPC` to call `PNC.SecondaryChannel.ClearForRecord(record)` + `PNC.AgitationService.Clear(record.id)` right after `clearManagedState(record, zombie)`.
  * Reconciled `docs/01_SYSTEM_MAP.md` and `docs/Jobs/UnifiedSchemaDrivenNPCAI/*` to `READY FOR USER LIVE TEST`.
* **Post-U6 Clean Sweep & Executor Fold (Option 2):**
  * `psychopatzCore`: retired `PsychopatzActorMigration.lua`, `PsychopatzSurvivorWorldImport.lua`, `Store.ImportPNC`, `Social.MigrateAliases` / `Authority.MigrateAliases`, `PlayerIdentity.GetLegacyKeys`, `Core.RequireLegacySharedFull` / `pack.core_legacy_full`, and one-time conversation history/opacity schema migrations (`tests/psychopatz_survivor_world_pnc_import_smoke.lua` retired; 7 Core tests updated; `core_lua` `74/74` inside `test_acceptance_runner.py`).
  * `DynamicTrading`: retired `DTCommon_PreSurvivorWorldImport.lua`, `DTAbstract_PreSurvivorWorldImport.lua`, legacy key expansion (`GetLegacyKeys` / `MigrateAliases`), and `tests/dt_abstract_pre_survivor_world_import_smoke.lua` (4 DT tests updated).
  * `ProjectHoomans`: retired 2 legacy 1-line LLM require forwarders, folded 15 legacy `Settlement/FacilityJobs/` ambient/seat modules into 16 modular `PNC/Tasking/Autonomy/Executors/` modules with zero standalone polling bypasses, and retired pre-publication persistence/SurvivorWorld/social/relationship-key migrations (`PNC_Persistence_ImportPlan*`, `PNC_Persistence_CoreMigration`, `PNC_SurvivorWorldImportSource`, `MigrateLegacyRecordToCore`, `MigrateTargetKey`, `LegacyPlayerTargetKey`, `RepairRelationshipKey`, `ImportPreSurvivorWorld`, `CoreWorldDiscoveryAdapter.Merge`), adding empty-Core social seeding (`SeedEmptyCoreSocial`) for fresh Core actors (`mp_server_file_guard` @ `1070`, `constants_presence_boundary` @ `678`, `relationship_service_presence_boundary` @ `15`).

Current evidence:

* `TEST_VERIFIED` (Post-U6 Option 2 Clean Sweep after final code edit):
  * `psychopatzCore`: `357/357` Python unittests OK (`Ran 357 tests in 123.492s`, including `test_acceptance_runner` `core_lua` `74/74`, `dynamic_trading` `91/91`, `convo_audit` `1/1`, and `test_dialogue_completeness_workbench`); `reconcile.py --check` `"clean": true` (`desired: 462`, `missing: 0`, `drifted: 0`, `stale: 0`).
  * `DynamicTrading`: `PASS 91/91`.
  * `ProjectHoomans`: `PASS 135/135` focused Wave 1–4 + U1–U6 Lua suite; full Lua suite `1082/1086` PASS (`4` pre-U0 baseline failures in untouched `pnc_animation_scene_debug_routes_smoke`, `pnc_context_debug_smoke`, `pnc_population_director_smoke`, `pz_custom_translation_manager_smoke`).
* `STATIC_ONLY` (Option 2 Clean Sweep): `pz_verify.py --kahlua --severity ERROR --no-snippets` `0` errors across all modified/created Lua files (`16` new `Autonomy/Executors` files also `0` token bloat); `git diff --check` exit `0` across all 3 repos.
* `TEST_VERIFIED` (U6 post-final-edit baseline):
  * `ProjectHoomans`: `126/126` PASS (`u6_unified_ai_scale`, `u5_dialogue`, `u4_reactivity`, `u3_autonomy`, `u1_work_foundation`, `reanimation`, `presence`, `mp_server_file_guard` @ `1071`); full Lua suite `1086/1090` PASS (the 4 failures — `pnc_animation_scene_debug_routes_smoke`, `pnc_context_debug_smoke`, `pnc_population_director_smoke`, `pz_custom_translation_manager_smoke` — are pre-U0 baseline failures in untouched Context/Population/Translation modules); focused ConvoEngine Python suite `35/35` OK (`7/7` modules); U5 full Python run `156/165` modules PASS (`651` run, `27` skipped; 9 pre-U0 semantic-harness fixture drifts untouched).
  * `psychopatzCore` (`bbd9fee90a96f63323129ea29e5bf76e2f1525be`): `357/357` Python unittests OK; `reconcile.py --check` clean; `convo_engine_cli director-readiness --summary` (`ok=true`, all 5 counters `0`, 8 checks `true`); `audit-integrity --check-determinism` OK (`446` files, `0` violations, `diffs=[]`); `convo_engine_naming_audit --summary` (`ok=true`, `activeCurrentPsdlIdentityCount=0`); `19/19` Core ConvoEngine/Social/ShockingBus/Kernel Lua smokes PASS.
  * `DynamicTrading` (`d4034fac5f547e00253dc3b9db5fd4554e37b535`): `PASS 92/92`.
* `STATIC_ONLY` (U6):
  * `pz-verify --kahlua --severity ERROR` returns `0` errors across `tests/pnc_u6_unified_ai_scale_smoke.lua`, `PNC_Presence_Abstract.lua`, `PNC_BodyLifecycle_Reanimation.lua`, and all U1–U5 production/generated Lua files.
  * Independent read-only adversarial verifier audit (`17/17` checks across 7 areas): **PASS, 0 mandatory findings remaining**.
* Environment / toolchain notes:
  * `pz-runtime-harness` (`project-hoomans run --allow-runtime-mismatch` and `suite` with current Build 42.22 profile `baseline-79175035`): reports `toolchain_incompatible` because PZ 42.22 `projectzomboid.jar` uses Java 25 classfile major `69` while the host provides `javac 17.0.20.1` (max major `61`) with only JRE 25 bundled and no JDK 25 installed locally. Host JDK was left untouched per policy.
  * `git diff --check` clean across all modified files.

Known gap:

* User-owned native Project Zomboid Singleplayer and Multiplayer live acceptance testing (plus optional JDK 25 installation if re-running `pz-runtime-harness` JVM compilation against Build 42.22).

Next Chunk: USER_LIVE_TEST — Native Project Zomboid SP/MP live verification by user.

Immediate acceptance:

* Native SP & MP check of: colony work/hauling without stutter, Sims band-gated autonomy & co-presence situations, gunshot/weapon/explosion reactivity + `SecondaryChannel` AnimSet vars/gaze/barks, RDR2 `GREET`/`ANTAGONIZE`/`DEFUSE` + multi-NPC micro-beats + witness-only hearsay, Colonists Debug GUI telemetry, and standalone `DynamicTrading` load without `ProjectHoomans`.
