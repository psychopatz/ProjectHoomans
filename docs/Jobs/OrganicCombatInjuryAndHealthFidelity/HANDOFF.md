---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "H3"
phase_commit_message: "phase(H3): H3: add lightweight cold, sickness, fever, wetness, and thermoregulation parity for Live and Abstract NPCs"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "H4"
chunk: "Immediate wound, fighting-injured, escalation, treatment, physiology, and post-combat injury check Beats"
retrieval_tier: "verify"
phase_commit_vector: "psychopatz-core=add35a03bda79f2dcfaad01ab6823ddba7bebac1;project-hoomans=self;dynamic-trading=62757d0b7fc1c114873735387827ccad9d828077"
phase_residual_vector: "psychopatz-core=d5ab49b048b324682250973dc18fa8799c0fa2f257c42b50e0999159772132d5;project-hoomans=74b186a9940afb547544e54a8f4838ce9837730bffe124e3f53ad9fab82f566a;dynamic-trading=37b4cc682480a62d0180cc5e402013c24e9123af6cb41c92e7f1885195e87f5d"
residual_worktree_fingerprint: "74b186a9940afb547544e54a8f4838ce9837730bffe124e3f53ad9fab82f566a"
codebase_memory_indexed_commit: "0e35ae37deb6e385a806136bfa1edbca9acfe8e6"
updated_at: "2026-11-22T22:25:58.646033Z"
---


# Session Handoff

## What became true

- H3 complete: shared thermoregulation/wetness/cold/fever/sickness simulation runs on both Live (`Wounds.Update`) and Abstract (`Needs.Update`) NPCs, emits `NPC_PHYSIOLOGY_BAND_CHANGED` only on band transitions, and stays under 1800 tokens per file.

## Remaining

- Execute H4 through H10 sequentially on `main`.

## Resume

1. Implement H4 (`PNC_NPCWounds_Projection.lua`, `PNC_SemanticCombatTargetCallouts_WoundProfile.lua`, `_Wounds.lua`, `_Medical.lua`) separating `bite_possible_exposure` vs `bite_confirmed_symptomatic` vs `bite_non_transmissible`, adding `pelvis_groin` and dirty-bandage callouts, `OnInjuryStateTransition`, and post-combat injury check in `OnTargetCleared`.
2. Verify token budgets, Kahlua lint, and tests, then commit H4.

## Evidence

- `TEST_VERIFIED`: `file_token_bloat_scan.py` (`0 / 6` over 2000), `pz_verify.py --kahlua` (0 issues), `tests/run_tests.py` (`12/12` PASS), and `H3_PROBE_OK` Live/Abstract parity verification.

## Blockers / open decisions

- None.

## Acceptance

H4 passes when immediate wound, fighting-injured/patched, severity escalation, treatment transition, physiology transition, and post-combat injury check Beats map accurately without treating every fresh bite as confirmed `bite_lethal`.
