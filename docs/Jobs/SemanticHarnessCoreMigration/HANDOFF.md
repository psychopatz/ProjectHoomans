---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P2-A"
phase_commit_message: "phase(P2-A): docs: define semantic execution boundary"
phase_commit_vector: "project-hoomans=self"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "d1da19d15426956852ddf4e0d9517f028797b541"
updated_at: "2026-11-09T22:50:42.488415Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P2"
chunk: "P2-B"
retrieval_tier: "verify"
---


# Handoff — Semantic Harness Core Migration

## What became true

P2-A audited the semantic execution split. Core already owns parser/IR, actor
conversation, identity, social, knowledge, journey, and conversation-landing
primitives. Hoomans worker conversation files remain mixed PNC adapters that
combine generic turn bookkeeping with provider health/faction/knowledge,
authority, translation, and interaction-lifecycle policy. No mixed file was
moved wholesale.

## Remaining

Implement P2-B: add the typed Core semantic-execution contract and wire Hoomans
to it. The contract must cover context, text/frame submission, snapshots,
bounded turn results, interaction operations, and abstract/physical
materialization metadata without importing provider policy into Core.

## Resume

1. Verify the three repository HEADs and worktree fingerprints.
2. Design a small Core callback contract around existing actor/conversation
   service boundaries.
3. Add a Core contract smoke with a fake provider and an Hoomans adapter smoke.
4. Keep PNC, Dynamic Trading merchant data, and provider defaults outside Core.

## Evidence

- `CODE_VERIFIED`: Core semantic service inventory and Hoomans adapter call
  sites were inspected directly; graph coverage has no recorded gaps for the
  cited worker files, with changed-file caveats applied.
- `STATIC_ONLY`: P2 contract code is not implemented yet; most semantic worker
  modules and tests remain Hoomans-owned.
- `UNVERIFIED`: native Project Zomboid SP/MP behavior remains user-owned.

## Residual findings

The broader Hoomans `test_harness` suite still reproduces three unrelated
translation/identity failures: false-name response disclosure, Tagalog
identity translation, and Tagalog identity/self-reflection catalog use. The
P2-A documentation does not alter those catalogs.

## Acceptance for P2-A

- Mixed semantic files were classified rather than copied into Core.
- The first typed callback boundary and extraction order are documented.
- No native runtime or Workshop publication claim is made.
