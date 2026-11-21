---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "U5"
phase_commit_message: "phase(U5): phase(U5): close ConvoEngine S13D-S13F and implement DialogueMicroBeatDirector, JointSceneLease, StreetInteraction, and SocialWitness"
phase_commit_vector: "psychopatz-core=bbd9fee90a96f63323129ea29e5bf76e2f1525be;project-hoomans=self;dynamic-trading=d4034fac5f547e00253dc3b9db5fd4554e37b535"
phase_residual_vector: "psychopatz-core=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "6635ccc81e21f02383feb598dc3b92c91b093d6a"
updated_at: "2026-11-21T21:22:10.998342Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "Phase U6"
chunk: "U6A"
retrieval_tier: "verify"
---





# Session Handoff: UnifiedSchemaDrivenNPCAI

## What became true

- **Phase U5 (`psychopatzCore` @ `bbd9fee90a96f63323129ea29e5bf76e2f1525be` + `DynamicTrading` @ `d4034fac5f547e00253dc3b9db5fd4554e37b535` + `ProjectHoomans`) implemented and verified:**
  - **U5a (`ConvoEngine` S13D–S13F):** Retired all duplicate `Behaviors/Director/*` and `Beats/Director/*` projections across Core, Hoomans, and DT; emitted `ConvoEngine/Index/Director.lua`; verified `director-readiness --summary` (`ok=true`, all 5 counters `0`, all 8 `readinessChecks=true`), `audit-integrity --check-determinism` (`446` files, `diffs=[]`), and `reconcile.py --check` clean.
  - **U5b (Façade Micro-Beat Dialogue Director & RDR2 Street Interaction):**
    - `PNC_DialogueMicroBeatDirector` (`server/PNC/ConvoEngine/Social/`): 5-stage deterministic micro-beats (`transition_in`, `body`, `local_or_global_mixin`, `wait_with_timeout`, `transition_out`), ephemeral scene tension tracking, causally independent global mix-ins, zero LLM calls (`llmCalls = 0`).
    - `PNC_JointSceneLeaseService`: atomic server-owned 2–4 participant `JointSceneLease` with `PNC.Tasking.Claims` (`scene:<sceneId>`, `npc_convo_turn:<id>`), listener `SecondaryChannel` gaze/posture, and `HARD_EMERGENCY`/demotion/reanimation abort cleanup.
    - `PNC_StreetInteractionService`: `GREET`/`AGREE`/`PRAISE`/`ANTAGONIZE`/`CRITICIZE`/`DISAGREE`/`DEFUSE`/`PACIFY` acts wired to `PNC_SocialGreetingService.HandleStreetAct`, `AgitationService`, `SecondaryChannel`, and `DialogueMicroBeatDirector`.
    - `PNC_SocialWitnessService`: witness-only `PsychopatzSocial` memory recording (range + hearing + LOS gated) and deduplicated 1-hop hearsay propagation (`hopCount = 1`, `sourceMode = "hearsay"`).
    - Wired `PNC_SemanticEventRuntime`, `PNC_CoPresenceService` (`InteractionSceneAdopters` compatibility), `PNC_Presence_Abstract`, `PNC_BodyLifecycle_Reanimation`, `PNC_Tasking_Queries.BuildBrain`, Colonists Debug GUI (`debug_ai_dialogue_director`), and fixed `PNC_ColonistDepartureService_Depart` nil `PNC.OrderSystem` guard.
- Phases U1 (`a598e8b9c1e2fe86b505e543b73cd63f52dfd2a5`), U2 (`010a6260cabe39f210095ba3d1bfb710d35b98cf` / `13ca3255df7dab59202ba2322920239a83f3f7d0`), U3 (`24d7bcd96389cce3b6541248a9f1c7f4d1c27c61`), and U4 (`2a32bb7eb43a8331a95ff3a8760d94abd70ca127` / `6800ec9c9185366815d68e3deb34093dcc75b425`) committed and checkpoint-verified.

## Remaining

- Execute **Phase U6**:
  1. Create `tests/pnc_u6_unified_ai_scale_smoke.lua` proving cross-tier scale (`O(N)`/`O(L)`/`O(live)`/`O(dirty)`), `HARD_EMERGENCY` aborts, witness isolation, domain-delta MP replication, and profiler-OFF zero overhead.
  2. Run full suites across `psychopatzCore`, `DynamicTrading`, and `ProjectHoomans` plus headless Kahlua JVM harness (`/home/psychopatz/Desktop/Projects/pz-runtime-harness/run.sh`).
  3. Run independent adversarial verification pass, update `docs/01_SYSTEM_MAP.md` & final U6 job docs (`READY FOR USER LIVE TEST`), and create the final U6 commit & checkpoint.

## Resume

Exact next action:

1. Create `/home/psychopatz/Zomboid/Workshop/ProjectHoomans/tests/pnc_u6_unified_ai_scale_smoke.lua` and run `pz-verify` + Lua smoke check.
2. Run all U6 multi-repo verification commands and `pz-runtime-harness` headless Kahlua JVM runs (`NEVER` launch native Project Zomboid GUI/binary).
3. Perform independent adversarial audit, reconcile `docs/01_SYSTEM_MAP.md` + U6 job docs, commit U6 locally, and verify checkpoint.

## Evidence

- `TEST_VERIFIED` (U5):
  - `psychopatzCore`: `357/357` Python OK; `14/14` Core Lua PASS; `reconcile.py --check` clean; `director-readiness --summary` (`ok=true`, 0 findings); `audit-integrity --check-determinism` OK (`446` files); `convo_engine_naming_audit` (`activeCurrentPsdlIdentityCount=0`).
  - `DynamicTrading`: `92/92` PASS; `pz-verify --kahlua` 0 errors.
  - `ProjectHoomans`: `32/32` U5b focused Lua PASS (`pnc_u5_dialogue_director_smoke`, `pnc_mp_server_file_guard_smoke` @ `1071`, `semantic_interaction`, `social_*`, `u4_reactivity`, `u3_autonomy`, `tasking`, `reanimation`, `colonist_*`); `19/19` U5a provider Python OK; `test_dialogue_completeness_workbench` PASS; full provider Python `156/165` modules PASS (`651` run, `27` skipped; 9 modules fail from pre-U0 semantic-harness fixture drift).
- `STATIC_ONLY` (U5): `pz-verify --kahlua --severity ERROR` 0 errors across all 16 U5 production, generated, and smoke Lua files; `git diff --check` clean.
- `TEST_VERIFIED` (U1–U4): U1 `81/81`, U2 `30/30` + `5/5`, U3 `20/20`, U4 `29/29` + Core `3/3` + DT `92/92`.

## Expensive discoveries worth preserving

- `PNC.AgitationService.ApplyTrigger` returns three values `(ok, stageOrErr, payloadTable)` — callers must capture the 3rd return value to read `{ score, stage, previousStage, delta, active }`.
- `PNC.CoPresenceService` exposes `TryTriggerForNPC(record, at, opts)` (not `TryTrigger`).
- `tests/pnc_mp_server_file_guard_smoke.lua` now enforces `1071` server `.lua` files (`+4` for U5b: `PNC_SocialWitnessService`, `PNC_JointSceneLeaseService`, `PNC_DialogueMicroBeatDirector`, `PNC_StreetInteractionService`).
- In full `tools/providers/pnc/tests`, 9 pre-U0 test modules (`test_grievance_evidence_*`, `test_contextual_talk_parity` line 725, `test_inventory_gift_workbench`, `test_save_backed_*`, `test_save_import`) fail against pre-existing semantic-harness fixture drift from `Portable Social State` / `L2` / `core-recruitment-authority` and are unrelated to U5.

## Blockers / open decisions

- None for U6 developer-side completion. Never launch native Project Zomboid GUI/binary.

## Acceptance

- Phase U5 local commit (`ProjectHoomans`) and `checkpoint.py verify` green, then execute Phase U6.
