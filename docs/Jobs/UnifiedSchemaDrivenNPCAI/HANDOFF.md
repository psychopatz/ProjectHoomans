---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "U4"
phase_commit_message: "phase(U4): implement GTA/RDR2 behavioral reactivity, perception clues, agitation, scenarios, and secondary channel"
phase_commit_vector: "psychopatz-core=2a32bb7eb43a8331a95ff3a8760d94abd70ca127;project-hoomans=self;dynamic-trading=2b66a9583fcbe3d9e915b6c16ab9d6851d053eab"
phase_residual_vector: "psychopatz-core=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "6635ccc81e21f02383feb598dc3b92c91b093d6a"
updated_at: "2026-11-21T20:47:20.704765Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "Phase U5"
chunk: "U5A"
retrieval_tier: "verify"
---




# Session Handoff: UnifiedSchemaDrivenNPCAI

## What became true

- Phase U4 (`psychopatzCore` @ `2a32bb7eb43a8331a95ff3a8760d94abd70ca127` + `ProjectHoomans`) implemented and verified:
  - Added bounded spatial `PsychopatzShockingEventBus` (`core.shocking_events`, omitted from `DynamicTrading` packs `pack.trading_{common,abstract,hoomans}`) with `MAX_EVENTS=128` FIFO eviction, dedup window, spatial cells, and lazy TTL pruning.
  - Added `PNC_PerceptionService` (`cosHalfFov` + squared-dist cone pre-filter, `<= 8`/tick budgeted LOS queue, bounded `ClueMemory`, `OnWorldSound` listener/shock hook), sparse lazy-decay `PNC_AgitationService`, `PNC_ReactionPolicyEvaluator`, `PNC_ShockingReactionTaskProvider` (all 5 non-lethal intents + `PNC.Tasking.Claims`), `PNC_ScenarioScheduler` (time-of-day chaining + intra-band autonomy boost), and horde-transition shock hook in `PNC_SocialEventHooks_CombatAdapter_Awareness`.
  - Added orthogonal `PNC_SecondaryChannel` (coincident-guarded `faceLocationF`, Build 42 `AnimSet` variables replicated via `BuildPresenceDelta` & reset on reanimation/demotion/abstraction, speech-priority-gated barks with `180s` lazy line-exhaustion recovery & `NPCVoice.Stop` cleanup, zero task preemption) and Colonists Debug GUI reactivity rows.
- Phases U1 (`a598e8b9...`), U2 (`010a6260...` / `13ca3255...`), and U3 (`24d7bcd9...`) committed and checkpoint-verified.

## Remaining

- Execute **Phase U5a** (`ConvoEngine` S13D–S13F closure across `psychopatzCore`, `ProjectHoomans`, and `DynamicTrading`) followed by **Phase U5b** (Façade-inspired Micro-Beat Dialogue Director & RDR2 Street Interaction) and **Phase U6** (Scale Proof & Final Acceptance).

## Resume

Exact next action:

1. Inspect `psychopatzCore` `ConvoEngine` S13D–S13F open tasks/audits (`tools/semantic_harness/codebuilder/` and any S13 docs) alongside `ProjectHoomans/42.20/media/lua/server/PNC/ConvoEngine/Interaction/SceneAdopters.lua` and `PNC_SocialGreetingService.lua`.
2. Close S13D–S13F cleanly across Core/Hoomans/DT first, then plan and implement Phase U5b Dialogue Director (`JointSceneLease`, 5-stage micro-beats, global mix-ins, `GREET`/`ANTAGONIZE`/`DEFUSE`, witness-only hearsay).

## Evidence

- `TEST_VERIFIED` (U4): Core `psychopatz_shocking_event_bus_smoke`, `psychopatz_capability_contract_smoke`, `psychopatz_boundary_isolation_smoke` OK; `DynamicTrading` 92/92 PASS; ProjectHoomans 13 suites (`u4_reactivity` 1/1, `u3_autonomy` 1/1, `mp_server_file_guard` 1/1 @ 1067, `composition_bootstrap` 1/1, `tasking` 8/8, `perception` 5/5, `voice` 5/5, `domain_delta` 1/1, `local_snapshot` 2/2, `reanimation` 1/1, `awareness` 1/1, `colonist_ui` 1/1, `colonist_task` 1/1) — 29/29 PASS.
- `TEST_VERIFIED` (U3): `u3_autonomy` (1/1), `follow_need_preemption` (1/1), `mp_server_file_guard` (1/1, 1063 files), `seating` (1/1), `roam_ambient` (1/1), `roaming_floor_seat` (1/1), `colonist_ui` (1/1), `colonist_activities` (1/1), `colonist_task` (1/1), `tasking` (8/8), `composition_bootstrap` (1/1), `seated_threat` (1/1), `player_roam` (1/1) — 20/20 PASS.
- `TEST_VERIFIED` (U2): `psychopatzCore` `python3 -m unittest` 30/30 OK; Core Lua social tests 5/5 PASS; `reconcile.py --check` clean; `convo_engine_naming_audit.py --summary` (`ok=true, activeCurrentPsdlIdentityCount=0`); `DynamicTrading` 92/92 PASS; `PASS generated_ai_ir_registries_lua_load`.
- `TEST_VERIFIED` (U1): `u1_work_foundation` + focused work/farming/lumber/fishing/corpse/tasking suites — 81/81 PASS.
- `STATIC_ONLY`: `pz-verify --kahlua --severity ERROR` 0 errors on 3 Core U4 files and all 22 Hoomans U4 production Lua files.

## Expensive discoveries worth preserving

- `PsychopatzCore.Require(capId, consumer)` returns two values `(ok, facade)` — callers capturing only the first return receive boolean `true`.
- `PsychopatzShockingEventBus.Reset()` clears active subscribers as well as queued events; `PNC_ShockingReactionTaskProvider.Reset()` calls `Provider.EnsureSubscribed()` so test resets stay self-healing.
- `PNC.ReactionPolicyEvaluator.ResolveRelTier` resolves real NPC relationship/faction tiers (`friend`/`hostile`/`neutral`) plus optional `event.relTier` or `event.payload.relTier` (`PsychopatzShockingEventBus.Emit` preserves `sourceId`, `targetId`, and `payload`).
- `tests/pnc_mp_server_file_guard_smoke.lua` now enforces `1067` server `.lua` files (`+4` for U4: `PNC_AgitationService`, `PNC_ReactionPolicyEvaluator`, `PNC_ShockingReactionTaskProvider`, `PNC_ScenarioScheduler`).

## Blockers / open decisions

- Hard gate U5a (`ConvoEngine` S13D–S13F closure) must complete before U5b Dialogue Director work begins.

## Acceptance

- Phase U4 local commits (`psychopatzCore` `2a32bb7eb43a8331a95ff3a8760d94abd70ca127` + `ProjectHoomans` U4) and `checkpoint.py verify` green, then enter Phase U5 planning.
