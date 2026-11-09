---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P1-J"
phase_commit_message: "phase(P1-J): refactor(hoomans): use Core semantic harness state"
phase_commit_vector: "project-hoomans=self"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "d1da19d15426956852ddf4e0d9517f028797b541"
updated_at: "2026-11-09T22:45:16.356857Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P1"
chunk: "P1-K"
retrieval_tier: "verify"
---


# Handoff — Semantic Harness Core Migration

## What became true

P1-J moves the provider-neutral Python source/working-world state engine into
Core `semantic_harness.state`. Hoomans `runtime/state.py` is now a thin
compatibility re-export, preserving existing worker and save-provider imports.
Core owns provenance labels, immutable source snapshots, working baselines,
bounded patch diffs, and reset behavior. Hoomans retains defaults, health and
NPC validation, save import, production rehydration, and conversation policy.

## Remaining

Implement P1-K: audit the remaining mixed Python scenario layer. Determine
whether any additional normalization or document validation is genuinely
provider-neutral, while keeping Hoomans defaults, health policy, save import,
and production rehydration behind the adopter boundary.

## Resume

1. Verify the three repository HEADs and worktree fingerprints.
2. Trace Core `scenario.py` and Hoomans `runtime/scenario.py` callers.
3. Classify neutral document mechanics from Hoomans fixture/domain policy.
4. Add focused Core and Hoomans compatibility tests before extraction.

## Evidence

- `CODE_VERIFIED`: Hoomans state imports resolve to Core `semantic_harness.state`.
- `TEST_VERIFIED`: Core Python suite (27), Core state contract, Hoomans
  save-backed and production rehydration tests, envelope contract, worker
  module smoke, and grounded dialogue smoke pass.
- `STATIC_ONLY`: most provider-neutral harness modules and tests remain
  Hoomans-owned; DTAbstract and DTHoomans are not yet full Core adopters.
- `UNVERIFIED`: native Project Zomboid SP/MP behavior remains user-owned.

## Residual findings

The broader Hoomans `test_harness` suite still reproduces three unrelated
translation/identity failures: false-name response disclosure, Tagalog
identity translation, and Tagalog identity/self-reflection catalog use. The
P1-J changed files do not own those catalogs; keep them as a follow-up
regression rather than widening this migration phase.

## Acceptance for P1-J

- Core owns the Python source/working-world state engine.
- Hoomans keeps a compatibility import path without a duplicate state engine.
- Save-backed and provider-rehydration callers remain green.
- Core participant commits precede the Hoomans primary commit.
- No native runtime or Workshop publication claim is made.
