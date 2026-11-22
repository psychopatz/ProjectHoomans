---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "U6"
phase_commit_message: "phase(U6): refactor(ai,persistence): fold autonomy executors into PNC.Tasking and retire legacy shims/migrations"
phase_commit_vector: "psychopatz-core=d5e80c5900a777625afe8cabbf79e94305b10d44;project-hoomans=self;dynamic-trading=3081b132f18b66a6ff6070f84a7e0644ba782f0a"
phase_residual_vector: "psychopatz-core=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;project-hoomans=1576504c9f9ac39ce733ed9397adc0ec7b1518589930e4d3d2851e472ffd63d4;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "1576504c9f9ac39ce733ed9397adc0ec7b1518589930e4d3d2851e472ffd63d4"
codebase_memory_indexed_commit: "0e35ae37deb6e385a806136bfa1edbca9acfe8e6"
updated_at: "2026-11-22T01:31:04.688617Z"
state: "USER_ACCEPTANCE"
parent_status: "READY_FOR_USER_LIVE_TEST"
phase: "Phase U6 (Complete — User Live Acceptance)"
chunk: "USER_LIVE_TEST"
retrieval_tier: "verify"
---








# Session Handoff: UnifiedSchemaDrivenNPCAI

## What became true

- **Developer-side Phases U0–U6 COMPLETE (`READY FOR USER LIVE TEST`):**
  - **U6:** Added Kahlua2-clean `tests/pnc_u6_unified_ai_scale_smoke.lua` (`pz-verify --kahlua --severity ERROR` 0 errors/warnings) verifying cross-tier complexity contracts (`O(N)`/`O(L)` 200 abstract + 6 live, `<= 64` ads, `SAME_BAND_MARGIN = 0.08`, 8-band wall, `<= 8`/tick LOS queue on 32 threats, demotion teardown, 200-event `PsychopatzShockingEventBus` FIFO `128` cap + `1000ms` dedup + `HARD_EMERGENCY` `JointSceneLease` abort, `O(dirty)` 4-chore `WorkService` + `AbortOrder`, 3-NPC micro-beat + global mix-in `llmCalls = 0`, RDR2 `ANTAGONIZE` + witness-only hearsay, narrow `SecondaryChannel` presence delta, and profiler-OFF zero overhead).
  - Closed Check #3 adversarial verifier finding: updated `PNC_Presence_Abstract.notifyAbstraction` to forward `zombie` into `PNC.SecondaryChannel.ClearForRecord(record, zombie)` and updated `PNC_BodyLifecycle_Reanimation.ReleaseReanimatedNPC` to call `PNC.SecondaryChannel.ClearForRecord(record)` + `PNC.AgitationService.Clear(record.id)` right after `clearManagedState`.
  - **Post-U6 Follow-up (Combat Cone Wiring, Live Cone Overlay & Unified AI Debug Lab — `0251345ad`):**
    - Wired `PNC_PerceptionService.PassesBodyVisionCone` (with `2.5m` 360-degree peripheral ring + engaged-threat bypass and LOS budget conservation) into `PNC_Perception_Frame.GetVisibleZombieEntries`, `Visibility.CollectEnemyZombies`, and `ActorSearch.FindNearestEnemyPlayer`/`FindNearestEnemyNPC`; added O(1)-guarded `PumpLOSQueue` (only when `HasPendingLOS()`), `SweepTimeouts`, and `SweepExpired` calls to `PNC_Server_SubsystemPumps.FinishTick`.
    - Upgraded live combat debug overlay (`AttackPayload`, `PresencePayload_CombatDebug`, `PNC_NameplateRenderer_CombatDebug*`, `DebugText`) to stream and render compiled `PerceptionService` cone radius/FOV, `2.5m` peripheral ring, bounded clue markers, `coneRejectedCount`, agitation stage/score, and secondary-channel alert/posture/state both in combat and idle (`coneOnly`).
    - Added interactive **Unified AI & Cone Debug Lab** (`PNC_UnifiedAIDebugService`, `PNC_UnifiedAIDebugWindow`, PsychopatzCore Debug Hub tool `pnc.unifiedAI` at `order = 205`, SP local dispatch `unified_ai_debug_action` in `PNC_ClientActions_Debug_State`, MP request/response commands, and 18 EN/TL `Debug.json` keys with full parity).
  - **Post-U6 Clean Sweep & Executor Fold (Option 2):**
    - `psychopatzCore`: retired `PsychopatzActorMigration.lua`, `PsychopatzSurvivorWorldImport.lua`, `Store.ImportPNC`, `Social.MigrateAliases` / `Authority.MigrateAliases`, `PlayerIdentity.GetLegacyKeys`, `Core.RequireLegacySharedFull` / `pack.core_legacy_full`, and one-time conversation history/opacity schema migrations (`psychopatz_survivor_world_pnc_import_smoke.lua` retired; 7 Core tests updated; `core_lua` `74/74` inside `test_acceptance_runner.py`).
    - `DynamicTrading`: retired `DTCommon_PreSurvivorWorldImport.lua`, `DTAbstract_PreSurvivorWorldImport.lua`, `GetLegacyKeys` / `MigrateAliases` call paths, and `tests/dt_abstract_pre_survivor_world_import_smoke.lua` (4 DT tests updated).
    - `ProjectHoomans`: retired 2 legacy 1-line LLM require forwarders, folded 15 legacy `Settlement/FacilityJobs/` ambient/seat modules into 16 modular `PNC/Tasking/Autonomy/Executors/` modules with zero standalone polling bypasses, and retired pre-publication persistence/SurvivorWorld/social/relationship-key migrations (`PNC_Persistence_ImportPlan*`, `PNC_Persistence_CoreMigration`, `PNC_SurvivorWorldImportSource`, `MigrateLegacyRecordToCore`, `MigrateTargetKey`, `LegacyPlayerTargetKey`, `RepairRelationshipKey`, `ImportPreSurvivorWorld`, `CoreWorldDiscoveryAdapter.Merge`), adding empty-Core social seeding (`SeedEmptyCoreSocial`) for fresh Core actors (`mp_server_file_guard` @ `1070`, `constants_presence_boundary` @ `678`, `relationship_service_presence_boundary` @ `15`).
  - Updated `/home/psychopatz/Zomboid/Workshop/ProjectHoomans/docs/01_SYSTEM_MAP.md` and reconciled `PROGRESS.md` / `HANDOFF.md` to `READY FOR USER LIVE TEST`.
- **Committed across participants & primary:** `psychopatzCore` @ `d5e80c5900a777625afe8cabbf79e94305b10d44`, `DynamicTrading` @ `3081b132f18b66a6ff6070f84a7e0644ba782f0a`, `ProjectHoomans` U0–U6 + Post-U6 (`0251345ad`) + Option 2 Clean Sweep (`phase_commit: "self"`).

## Remaining

- **User-owned native Project Zomboid SP & MP live acceptance testing** (developer-side Phases U0–U6 complete; native PZ binary/GUI intentionally NOT launched by agent):
  1. Verify Build 42 SP & dedicated/hosted MP colony work (`FARMING`, `FISHING`, `LUMBER`, `CORPSE_HAUL`) runs smoothly without `Events.OnTick` stutter and cleans up claims on interruption.
  2. Verify Sims band-gated `OPTIONAL`/`IDLE` autonomy + co-presence situations + Colonists Debug GUI (`debug` tab) rows (`debug_ai_*`).
  3. Verify gunshot/explosion/weapon-aimed reactivity, `SecondaryChannel` AnimSet vars (`PNCAlertLevel`, `PNCPosture`), `faceLocationF` gaze without warnings, and bark cooldowns across server->client MP deltas, plus the updated Combat Debug overlay cone & **Unified AI & Cone Debug Lab** (`pnc.unifiedAI` in PsychopatzCore Debug Hub) in both SP and MP.
  4. Verify RDR2 street acts (`GREET`/`ANTAGONIZE`/`DEFUSE`), 2–4 participant micro-beat conversations, and witness-only social memories/hearsay.
  5. Verify standalone `DynamicTrading` (`PsychopatzCore` + `DTCommon` + `DTAbstract`) boots cleanly with `ProjectHoomans` disabled.
  6. Optional: if re-running `pz-runtime-harness` JVM compilation against Build 42.22, provide a local JDK 25 `--javac` (PZ 42.22 uses classfile major `69`; host currently has JDK 17 max `61`).

## Resume

No further autonomous developer phases remain. Resume only after user native SP/MP live test feedback.

## Evidence

- `TEST_VERIFIED` (Option 2 Clean Sweep after final code edit):
  - `psychopatzCore`: `357/357` Python unittests OK (`Ran 357 tests in 123.492s`, including `test_acceptance_runner` `core_lua` `74/74`, `dynamic_trading` `91/91`, `convo_audit` `1/1`, and `test_dialogue_completeness_workbench`); `reconcile.py --check` `"clean": true` (`desired: 462`, `missing: 0`, `drifted: 0`, `stale: 0`).
  - `DynamicTrading`: `PASS 91/91`.
  - `ProjectHoomans`: `PASS 135/135` focused Wave 1–4 + U1–U6 Lua suite; full Lua suite `1082/1086` PASS (`4` pre-U0 baseline failures in untouched `pnc_animation_scene_debug_routes_smoke`, `pnc_context_debug_smoke`, `pnc_population_director_smoke`, `pz_custom_translation_manager_smoke`).
- `STATIC_ONLY` (Option 2 Clean Sweep): `pz_verify.py --kahlua --severity ERROR --no-snippets` `0` errors across all modified/created Lua files (`16` new `Autonomy/Executors` files also `0` token bloat); `git diff --check` clean across all 3 repos.
- `TEST_VERIFIED` (Post-U6 follow-up baseline):
  - `ProjectHoomans`: `52/52` PASS (`unified_ai_combat_cone`, `perception`, `combat`, `nameplate`, `mp_server_file_guard` @ `1072`, `composition_bootstrap`, `u1_work_foundation`, `u3_autonomy`, `u4_reactivity`, `u5_dialogue`, `u6_unified_ai_scale`); EN/TL `Debug.json` parity verified (`713` total keys, `18` new `UI_PNC_DebugHub_UnifiedAI_*` / `UI_PNC_UnifiedAI_*` keys).
  - `DynamicTrading`: `PASS 92/92`.
- `STATIC_ONLY` (Post-U6 follow-up): `pz-verify --kahlua --severity ERROR --no-snippets` `0` errors across all `24` modified/new Lua files (plus `--i18n` `0` hardcoded strings on `PNC_UnifiedAIDebugWindow.lua`, and re-verified `0` errors on `PNC_UnifiedAIDebugService.lua` after its final edit).
- `TEST_VERIFIED` (U6 post-final-edit baseline):
  - `ProjectHoomans`: `126/126` PASS (`u6_unified_ai_scale`, `u5_dialogue`, `u4_reactivity`, `u3_autonomy`, `u1_work_foundation`, `reanimation`, `presence`, `mp_server_file_guard` @ `1071`); full Lua suite `1086/1090` PASS (`4` pre-U0 failures in untouched `pnc_animation_scene_debug_routes_smoke`, `pnc_context_debug_smoke`, `pnc_population_director_smoke`, `pz_custom_translation_manager_smoke`); focused ConvoEngine Python `35/35` OK (`7/7` modules); U5 full Python `156/165` modules PASS (`651` run, `27` skipped; `9` pre-U0 semantic-harness fixture drifts untouched).
  - `psychopatzCore`: `357/357` Python OK; `reconcile.py --check` clean; `director-readiness --summary` (`ok=true`, 0 findings); `audit-integrity --check-determinism` OK (`446` files, `diffs=[]`); `convo_engine_naming_audit` (`activeCurrentPsdlIdentityCount=0`); `19/19` Core Lua smokes PASS.
  - `DynamicTrading`: `PASS 92/92`.
- `STATIC_ONLY` (U6): `pz-verify --kahlua --severity ERROR` 0 errors across `pnc_u6_unified_ai_scale_smoke.lua`, `PNC_Presence_Abstract.lua`, `PNC_BodyLifecycle_Reanimation.lua`, and all U1–U5 production/generated Lua files. Adversarial verifier audit: `17/17` checks PASS (`0` mandatory findings).
- Environment check (`pz-runtime-harness`): `toolchain_incompatible` (`engine_class_file_major=69` vs `javac 17` max `61`, no JDK 25 installed locally; host JDK preserved).

## Expensive discoveries worth preserving

- PZ Build 42.22 `projectzomboid.jar` uses Java 25 bytecode (`major=69`), while `jre64/` bundles only `java` (no `javac`), so `pz-runtime-harness` JVM compilation requires an external JDK 25 `--javac` when running on hosts with only JDK 17 installed.
- `PNC_BodyLifecycle_Reanimation.ReleaseReanimatedNPC` intentionally clears managed AnimSet vars via `clearVariable` before vanilla `corpse:reanimate()`, so calling `SecondaryChannel.ClearForRecord(record)` (without `zombie`) cleans `runtime.secondaryChannel` + `NPCVoice` without overwriting vanilla zombie AnimSet vars.

## Blockers / open decisions

- None (developer-side U0–U6 complete; handed off cleanly for user-owned native SP/MP acceptance).

## Acceptance

- User native SP/MP live test confirmation (or bug report follow-up if live engine testing surfaces an issue).
