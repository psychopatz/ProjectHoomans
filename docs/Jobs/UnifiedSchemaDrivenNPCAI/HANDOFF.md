---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "U6"
phase_commit_message: "phase(U6): phase(U6): add unified AI scale proof, multi-repo and adversarial verification, and close developer-side gates"
phase_commit_vector: "psychopatz-core=bbd9fee90a96f63323129ea29e5bf76e2f1525be;project-hoomans=self;dynamic-trading=d4034fac5f547e00253dc3b9db5fd4554e37b535"
phase_residual_vector: "psychopatz-core=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "0e35ae37deb6e385a806136bfa1edbca9acfe8e6"
updated_at: "2026-11-21T21:40:26.921693Z"
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
  - Updated `/home/psychopatz/Zomboid/Workshop/ProjectHoomans/docs/01_SYSTEM_MAP.md` and reconciled `ROADMAP.md` / `PROGRESS.md` / `HANDOFF.md` to `READY FOR USER LIVE TEST`.
- **Committed across participants & primary:** `psychopatzCore` @ `bbd9fee90a96f63323129ea29e5bf76e2f1525be` (U2+U4+U5a), `DynamicTrading` @ `d4034fac5f547e00253dc3b9db5fd4554e37b535` (U5a guard), `ProjectHoomans` U0–U5 (`d987bf1c9`, `a598e8b9c`, `13ca3255d`, `24d7bcd96`, `6800ec9c9`, `0e35ae37d`) + U6 (`phase_commit: "self"`).

## Remaining

- **User-owned native Project Zomboid SP & MP live acceptance testing** (developer-side Phases U0–U6 complete; native PZ binary/GUI intentionally NOT launched by agent):
  1. Verify Build 42 SP & dedicated/hosted MP colony work (`FARMING`, `FISHING`, `LUMBER`, `CORPSE_HAUL`) runs smoothly without `Events.OnTick` stutter and cleans up claims on interruption.
  2. Verify Sims band-gated `OPTIONAL`/`IDLE` autonomy + co-presence situations + Colonists Debug GUI (`debug` tab) rows (`debug_ai_*`).
  3. Verify gunshot/explosion/weapon-aimed reactivity, `SecondaryChannel` AnimSet vars (`PNCAlertLevel`, `PNCPosture`), `faceLocationF` gaze without warnings, and bark cooldowns across server->client MP deltas.
  4. Verify RDR2 street acts (`GREET`/`ANTAGONIZE`/`DEFUSE`), 2–4 participant micro-beat conversations, and witness-only social memories/hearsay.
  5. Verify standalone `DynamicTrading` (`PsychopatzCore` + `DTCommon` + `DTAbstract`) boots cleanly with `ProjectHoomans` disabled.
  6. Optional: if re-running `pz-runtime-harness` JVM compilation against Build 42.22, provide a local JDK 25 `--javac` (PZ 42.22 uses classfile major `69`; host currently has JDK 17 max `61`).

## Resume

No further autonomous developer phases remain. Resume only after user native SP/MP live test feedback.

## Evidence

- `TEST_VERIFIED` (U6 post-final-edit):
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
