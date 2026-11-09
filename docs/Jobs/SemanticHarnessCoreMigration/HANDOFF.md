---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P2-C"
phase_commit_message: "phase(P2-C): docs: refresh Dynamic Trading phase handoff"
phase_commit_vector: "project-hoomans=self"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "d1da19d15426956852ddf4e0d9517f028797b541"
updated_at: "2026-11-09T23:10:43.446875Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P2"
chunk: "P2-C"
retrieval_tier: "verify"
---




# Handoff — Semantic Harness Core Migration

## What became true

P2-C adds Core validation for the bounded
`semantic.harness_execution.v1` provider descriptor. DynamicTrading now owns a
thin declarative manifest plus Core-contract Lua adapters:

- `DTCommon` declares shared trading conversation, identity, and interaction
  capabilities;
- `DTAbstract` composes the `dtabstract` profile in `abstract` mode;
- `DTHoomans` composes the `dthoomans` profile in `physical` mode;
- both profiles use the same Core callback names and schema;
- merchant stock, budget, quote, and trade authority remain DTCommon-owned;
- physical body materialization remains DTHoomans-only.

The Core worker and Hoomans worker remain separate at this checkpoint. No
legacy Hoomans worker/runtime files were deleted.

## Remaining

Implement P2-D: connect optional provider manifests to a Core-owned profile
loader/worker bootstrap without creating a DynamicTrading worker or importing
Project Hoomans into Core. Then continue P3/P4 extraction and deletion only
after import and behavior gates pass.

## Resume

1. Verify Core, Hoomans, and DynamicTrading HEADs and worktree fingerprints.
2. Inspect DTCommon, DTAbstract, and DTHoomans provider entry points and their
   existing Core actor/trade contracts.
3. Connect profile selection to the Core worker through an explicit loader;
   keep provider modules optional and fail closed.
4. Continue the Hoomans extraction only after Core and adopter import gates
   pass.

## Evidence

- `CODE_VERIFIED`: Core descriptors validate the execution schema; DynamicTrading
  exposes `dtabstract` and `dthoomans` manifests plus thin Lua adapters.
- `TEST_VERIFIED`: Core Python suite (28), DynamicTrading adapter tests, the
  DT semantic-execution smoke, and the full DynamicTrading smoke suite (87)
  pass.
- `STATIC_ONLY`: the optional DT profiles are not yet selected by the
  Core-owned worker bootstrap.
- `UNVERIFIED`: native Project Zomboid SP/MP behavior remains user-owned.

## Residual findings

The broader Hoomans `test_harness` suite still reproduces three unrelated
translation/identity failures: false-name response disclosure, Tagalog
identity translation, and Tagalog identity/self-reflection catalog use. The
P2-B changes do not own those catalogs.

## Acceptance for P2-C

- Core owns typed callback contract, bounded descriptor metadata, and profile
  validation.
- DynamicTrading abstract and physical adapters use the same Core execution
  schema.
- The DTAbstract profile resolves without DTHoomans.
- Missing Core execution contract fails closed in the DT Lua adapters.
- Core participant commits precede the Hoomans primary commit.
- No native runtime or Workshop publication claim is made.
