---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P1-H"
phase_commit_message: "phase(P1-H): refactor(hoomans): delegate worker dispatch to Core"
phase_commit_vector: "project-hoomans=self"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "d1da19d15426956852ddf4e0d9517f028797b541"
updated_at: "2026-11-09T22:37:57.503032Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P1"
chunk: "P1-I"
retrieval_tier: "verify"
---


# Handoff — Semantic Harness Core Migration

## What became true

P1-H moves the provider-neutral ordered handler dispatch loop into Core
`worker/Router.lua`. Hoomans supplies its existing handlers, session command
policy, transport-evidence configuration, and provider-specific catalogs. Core
preserves handler control results, optional transport annotation, and the
canonical unknown-command failure.

## Remaining

Implement P1-I: audit Core worker lifecycle ownership. Compare the minimal Core
worker loop with the Hoomans JSON-lines process loop and identify the smallest
provider-neutral lifecycle/process seam that can be shared without importing
Hoomans modules into Core.

## Resume

1. Verify the three repository HEADs and worktree fingerprints.
2. Trace Python process ownership and Lua JSON-lines loop boundaries.
3. Keep Core independent of Hoomans and DynamicTrading module paths.
4. Add lifecycle smoke coverage before changing the process loop.

## Evidence

- `CODE_VERIFIED`: Hoomans `CommandRouter` delegates ordered dispatch to Core.
- `TEST_VERIFIED`: Core router smoke, Core Python suite (26), Hoomans
  envelope/patch contract, worker-module smoke, and grounded-dialogue smoke
  pass.
- `STATIC_ONLY`: most provider-neutral harness modules and tests remain
  Hoomans-owned; DTAbstract and DTHoomans are not yet full Core adopters.
- `UNVERIFIED`: native Project Zomboid SP/MP behavior remains user-owned.

## Residual findings

The broader Hoomans `test_harness` suite still reproduces three unrelated
translation/identity failures: false-name response disclosure, Tagalog
identity translation, and Tagalog identity/self-reflection catalog use. The
P1-H changed files do not own those catalogs; keep them as a follow-up
regression rather than widening this migration phase.

## Acceptance for P1-H

- Core owns generic dispatch, not provider command policy.
- Hoomans handler ordering and transport evidence behavior remain tested.
- Core participant commits precede the Hoomans primary commit.
- No native runtime or Workshop publication claim is made.
