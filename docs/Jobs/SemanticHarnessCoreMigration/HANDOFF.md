---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P2-C"
phase_commit_message: "phase(P2-C): docs: record Dynamic Trading semantic adapters"
phase_commit_vector: "project-hoomans=self"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "d1da19d15426956852ddf4e0d9517f028797b541"
updated_at: "2026-11-09T23:09:08.482708Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P2"
chunk: "P2-C"
retrieval_tier: "verify"
---



# Handoff — Semantic Harness Core Migration

## What became true

P2-B adds Core `worker/SemanticExecution.lua` with schema
`semantic.harness_execution.v1`. Hoomans registers a physical adapter and
routes context, text, preview, semantic-frame, and snapshot operations through
the contract. PNC dialogue policy, translations, authority, and output
projection remain Hoomans-owned. Optional interaction callbacks fail closed.

## Remaining

Implement P2-C: register Dynamic Trading adopters against the same contract.
DTCommon/DTAbstract must operate abstractly; DTHoomans may request physical
materialization. Keep merchant stock/budget/trade policy in DTCommon and
physical actor creation in DTHoomans.

## Resume

1. Verify Core, Hoomans, and DynamicTrading HEADs and worktree fingerprints.
2. Inspect DTCommon, DTAbstract, and DTHoomans provider entry points and their
   existing Core actor/trade contracts.
3. Add abstract and physical adapter descriptors without creating a second
   worker or importing provider policy into Core.
4. Run Core contract tests and DynamicTrading focused tests before extracting
   any Hoomans semantic module.

## Evidence

- `CODE_VERIFIED`: Hoomans `INPUT`, `PREVIEW`, and semantic-frame paths use the
  Core execution object; capability metadata advertises physical mode.
- `TEST_VERIFIED`: Core execution smoke, Core Python suite (27), Hoomans
  semantic-execution adapter check, envelope contract, worker-module smoke,
  and grounded dialogue smoke pass.
- `STATIC_ONLY`: DTAbstract and DTHoomans adapter implementations are not yet
  registered against this callback surface.
- `UNVERIFIED`: native Project Zomboid SP/MP behavior remains user-owned.

## Residual findings

The broader Hoomans `test_harness` suite still reproduces three unrelated
translation/identity failures: false-name response disclosure, Tagalog
identity translation, and Tagalog identity/self-reflection catalog use. The
P2-B changes do not own those catalogs.

## Acceptance for P2-B

- Core owns the typed callback contract and materialization metadata.
- Hoomans consumes the contract without moving PNC policy into Core.
- Missing optional operations fail closed.
- Core participant commits precede the Hoomans primary commit.
- No native runtime or Workshop publication claim is made.
