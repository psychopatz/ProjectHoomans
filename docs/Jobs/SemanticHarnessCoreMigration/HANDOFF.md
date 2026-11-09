---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P1-G"
phase_commit_message: "phase(P1-G): refactor(hoomans): delegate working-world mechanics to Core"
phase_commit_vector: "project-hoomans=self"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "d1da19d15426956852ddf4e0d9517f028797b541"
updated_at: "2026-11-09T22:35:42.377694Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P1"
chunk: "P1-H"
retrieval_tier: "verify"
---


# Handoff — Semantic Harness Core Migration

## What became true

P1-G adds Core `WorkingWorld` mechanics for deterministic bounded patch
projection, `HARNESS_MUTATION` provenance, source-baseline selection, working
revision/reset counters, and first-baseline capture. Hoomans delegates to this
module while retaining provider rehydration, actor setup, and gameplay reset
policy. The Core module is provider-agnostic and does not interpret gameplay
records.

## Remaining

Implement P1-H: audit the remaining worker session/router boundary. Separate
generic request lifecycle, snapshot/mutation response routing, and
provider-specific command policy before moving anything else into Core.

## Resume

1. Verify the three repository HEADs and worktree fingerprints.
2. Trace `CommandRouter_Session` callers and the worker response lifecycle.
3. Classify generic routing versus Hoomans/PNC command policy.
4. Add Core routing tests and Hoomans compatibility tests before extraction.

## Evidence

- `CODE_VERIFIED`: Hoomans lifecycle and projection code delegate to Core
  `WorkingWorld`.
- `TEST_VERIFIED`: Core working-world smoke, Core Python suite (26), Hoomans
  envelope/patch contract, save-backed snapshot tests, fixture-provider tests,
  worker-module smoke, and grounded-dialogue smoke pass.
- `STATIC_ONLY`: most provider-neutral harness modules and tests remain
  Hoomans-owned; DTAbstract and DTHoomans are not yet full Core adopters.
- `UNVERIFIED`: native Project Zomboid SP/MP behavior remains user-owned.

## Residual findings

The broader Hoomans `test_harness` suite still reproduces three unrelated
translation/identity failures: false-name response disclosure, Tagalog
identity translation, and Tagalog identity/self-reflection catalog use. The
P1-G changed files do not own those catalogs; keep them as a follow-up
regression rather than widening this migration phase.

## Acceptance for P1-G

- Core owns generic working-world bookkeeping and bounded patch projection.
- Hoomans retains provider rehydration and gameplay reset policy.
- Existing patch and response compatibility shapes remain tested.
- Core participant commits precede the Hoomans primary commit.
- No native runtime or Workshop publication claim is made.
