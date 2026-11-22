---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "H5"
phase_commit_message: "phase(H5): H5: implement Director-style ally wound reaction arbitration and <= 4 scene participant caps"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "H6"
chunk: "Beat -> player response -> DialogueFlowKernel -> LocalResponse -> multi-actor Scene handoff with hard offer constraints"
retrieval_tier: "verify"
phase_commit_vector: "psychopatz-core=add35a03bda79f2dcfaad01ab6823ddba7bebac1;project-hoomans=self;dynamic-trading=62757d0b7fc1c114873735387827ccad9d828077"
phase_residual_vector: "psychopatz-core=d5ab49b048b324682250973dc18fa8799c0fa2f257c42b50e0999159772132d5;project-hoomans=85b9014c8761b1df96c6f20d4f08cbd6fd04124e2ad63eb247a0def60852fed4;dynamic-trading=37b4cc682480a62d0180cc5e402013c24e9123af6cb41c92e7f1885195e87f5d"
residual_worktree_fingerprint: "85b9014c8761b1df96c6f20d4f08cbd6fd04124e2ad63eb247a0def60852fed4"
codebase_memory_indexed_commit: "0e35ae37deb6e385a806136bfa1edbca9acfe8e6"
updated_at: "2026-11-22T22:32:44.659984Z"
---


# Session Handoff

## What became true

- H5 complete: `SelectWoundResponders` scores candidates via numeric disposition, relationship, medical skill/supplies, leadership, panic, cooldown, and distance; selects 1 responder normally and 2 only for bite conflict or critical+medic pairing (`<= 4` participants, all files `< 1750` tokens).

## Remaining

- Execute H6 through H10 sequentially on `main`.

## Resume

1. Implement H6 (`PNC_SemanticSpeechTransport.lua`, `PNC_SemanticCombatTargetCallouts_Delivery.lua`, `_WoundDelivery.lua`, `Situation_State.lua`, `Social_Reactions_AllyWarn.lua`, `EventReactions_Core.lua`, `combat_injury_interactive_exchange.json`, Scene handoff).
2. Verify token limits, Kahlua lint, and Beat -> Suggestions -> FlowKernel -> LocalResponse -> Scene end-to-end flow, then commit H6.

## Evidence

- `TEST_VERIFIED`: `file_token_bloat_scan.py` (`0 / 3` over 2000), `pz_verify.py --kahlua` (0 issues), `tests/run_tests.py` (`2/2` PASS), and `H5_PROBE_OK`.

## Blockers / open decisions

- None.

## Acceptance

H6 passes when injury Beat payloads propagate `responsePlanID`/`realizationID`/`offerIDs`/`flowID` (`observerOnly = false`), `DialogueSuggestions.Build` enforces hard `npcState` constraints, `combat.injury.triage_exchange` nodes define `responsePool`s so `DialoguePolicy`/`LocalResponse` resolve replies, and triage turns promote a multi-actor `Scene` with `activeInjuryTriageState`.
