---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P1-K"
phase_commit_message: "phase(P1-K): docs: close scenario boundary audit"
phase_commit_vector: "project-hoomans=self"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "d1da19d15426956852ddf4e0d9517f028797b541"
updated_at: "2026-11-09T22:46:47.392174Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P2"
chunk: "P2-A"
retrieval_tier: "verify"
---


# Handoff — Semantic Harness Core Migration

## What became true

P1-K closes the mixed Python scenario audit. Hoomans already delegates generic
document mechanics to Core. Its remaining defaults, health normalization, NPC
validation, available-mod policy, and save/import normalization are provider or
domain policy and remain local.

## Remaining

Start P2-A: audit semantic execution seams. Compare Hoomans semantic adapters,
conversation orchestration, output projection, and interaction lifecycle code
with existing Core semantic services. Move generic contracts and orchestration
only; keep provider callbacks and provider data in adopters.

## Resume

1. Verify the three repository HEADs and worktree fingerprints.
2. Inspect Core semantic conversation/identity/interaction services and Hoomans
   adapter call sites.
3. Record the first typed provider callback boundary before extracting code.
4. Add Core contract smoke coverage and Hoomans compatibility coverage before
   deleting any Hoomans module.

## Evidence

- `CODE_VERIFIED`: Hoomans scenario module aliases the generic Core document
  helpers; remaining code is provider/domain policy.
- `TEST_VERIFIED`: Core Python suite (27), Hoomans state/save-backed tests,
  envelope contract, worker-module smoke, and grounded dialogue smoke pass.
- `STATIC_ONLY`: most provider-neutral semantic execution modules and tests
  remain Hoomans-owned; DTAbstract and DTHoomans are not yet full Core
  adopters.
- `UNVERIFIED`: native Project Zomboid SP/MP behavior remains user-owned.

## Residual findings

The broader Hoomans `test_harness` suite still reproduces three unrelated
translation/identity failures: false-name response disclosure, Tagalog
identity translation, and Tagalog identity/self-reflection catalog use. The
P1-K changes do not own those catalogs; keep them as a follow-up regression.

## Acceptance for P1-K

- No provider policy was moved into Core merely to reduce Hoomans file count.
- The remaining scenario split and P2 entry boundary are documented.
- No native runtime or Workshop publication claim is made.
