---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "H6"
phase_commit_message: "phase(H6): H6: wire injury Beat to player suggestions, triage flow pools, and multi-actor Scene handoff"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "H7"
chunk: "Remove dialogue recommendedAction, implement Wounds.EvaluateBiteConflictPolicy, and record bounded high-salience injury memory"
retrieval_tier: "verify"
phase_commit_vector: "psychopatz-core=add35a03bda79f2dcfaad01ab6823ddba7bebac1;project-hoomans=self;dynamic-trading=62757d0b7fc1c114873735387827ccad9d828077"
phase_residual_vector: "psychopatz-core=d5ab49b048b324682250973dc18fa8799c0fa2f257c42b50e0999159772132d5;project-hoomans=c30bc975f4a960fb43726397321327ae7e5a4ddc89df49a4da0a5f86cdc9d871;dynamic-trading=37b4cc682480a62d0180cc5e402013c24e9123af6cb41c92e7f1885195e87f5d"
residual_worktree_fingerprint: "c30bc975f4a960fb43726397321327ae7e5a4ddc89df49a4da0a5f86cdc9d871"
codebase_memory_indexed_commit: "0e35ae37deb6e385a806136bfa1edbca9acfe8e6"
updated_at: "2026-11-22T23:04:13.040943Z"
---



# Session Handoff

## What became true

- H6 complete: injury Beats carry `responsePlanID`, `realizationID`, `offerIDs`, `flowID`, and `observerOnly = false`; `DialogueSuggestions.Build` enforces hard `npcState` constraints (`isBitten`, `hasOpenWounds`, `hasActiveInjury`); `combat.injury.triage_exchange` nodes resolve deterministic responses via `semantic.flow.combat.injury.triage.*` pools; `HandoffInjuryBeatToScene` cancels pending transient Beat replies, opens a bounded `<= 4` participant `Scene`, and writes `record.runtime.activeInjuryTriageState`.

## Remaining

- Execute H7 through H10 sequentially on `main`.

## Resume

1. Implement H7 (`PNC_NPCWounds_BiteConflictPolicy.lua`, remove `recommendedAction = "hostile_eliminate_bitten"` from `PNC_SemanticCombatTargetCallouts_WoundRoles.lua`/`_WoundDelivery.lua`, record bounded high-salience injury/triage memory provenance).
2. Verify token limits, Kahlua lint, and runtime probe, then commit H7.

## Evidence

- `TEST_VERIFIED`: `file_token_bloat_scan.py` (`0 / 21` over 2000), `pz_verify.py --kahlua` (0 issues), `tests/run_tests.py` (`2/2` PASS), and `H6_PROBE_OK`.

## Blockers / open decisions

- None.

## Acceptance

H7 passes when zero occurrences of `"recommendedAction"` remain in dialogue/callout modules, `Wounds.EvaluateBiteConflictPolicy` returns normalized stances (`none`, `protect`, `monitor`, `quarantine`, `abandon`, `threaten`, `execute_candidate`) honoring `activeInjuryTriageState` de-escalation, and bounded high-salience injury/triage memory provenance is recorded.
