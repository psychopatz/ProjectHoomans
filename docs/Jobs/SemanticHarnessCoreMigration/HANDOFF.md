---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P2-D"
phase_commit_message: "phase(P2-D): docs: record Core profile bootstrap"
phase_commit_vector: "project-hoomans=self"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "d1da19d15426956852ddf4e0d9517f028797b541"
updated_at: "2026-11-09T23:14:23.570637Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P2"
chunk: "P2-C"
retrieval_tier: "verify"
---





# Handoff — Semantic Harness Core Migration

## What became true

P2-D completes the generic profile bootstrap after P2-C added Core validation
for the bounded
`semantic.harness_execution.v1` provider descriptor. DynamicTrading now owns a
thin declarative manifest plus Core-contract Lua adapters:

- `DTCommon` declares shared trading conversation, identity, and interaction
  capabilities;
- `DTAbstract` composes the `dtabstract` profile in `abstract` mode;
- `DTHoomans` composes the `dthoomans` profile in `physical` mode;
- both profiles use the same Core callback names and schema;
- merchant stock, budget, quote, and trade authority remain DTCommon-owned;
- physical body materialization remains DTHoomans-only.

The Core worker accepts externally composed profile metadata without importing
DynamicTrading or Project Hoomans. The Hoomans worker remains a compatibility
path at this checkpoint. No legacy Hoomans worker/runtime files were deleted.

## Remaining

Implement P3-A: connect provider callbacks to the Core execution bootstrap,
then continue P3/P4 extraction and deletion only after import and behavior
gates pass.

## Resume

1. Verify Core, Hoomans, and DynamicTrading HEADs and worktree fingerprints.
2. Inspect DTCommon, DTAbstract, and DTHoomans provider entry points and their
   existing Core actor/trade contracts.
3. Connect DTCommon execution callbacks through the Core execution object;
   keep provider modules optional and fail closed.
4. Continue the Hoomans extraction only after Core and adopter import gates
   pass.

## Evidence

- `CODE_VERIFIED`: Core descriptors validate the execution schema; the profile
  loader composes optional registrars; the Core worker advertises selected
  profile metadata without adopter imports.
- `TEST_VERIFIED`: Core Python suite (31), DynamicTrading adapter tests, the
  DT semantic-execution smoke, and the full DynamicTrading smoke suite (87)
  pass.
- `STATIC_ONLY`: DT provider callbacks are not yet executed by the minimal
  Core worker; that is the P3 boundary.
- `UNVERIFIED`: native Project Zomboid SP/MP behavior remains user-owned.

## Residual findings

The broader Hoomans `test_harness` suite still reproduces three unrelated
translation/identity failures: false-name response disclosure, Tagalog
identity translation, and Tagalog identity/self-reflection catalog use. The
P2-B changes do not own those catalogs.

## Acceptance for P2-D

- Core owns typed callback contract, bounded descriptor metadata, profile
  composition, and launch metadata transport.
- DynamicTrading profiles resolve through the Core loader without adopter
  imports in the Core worker.
- The Core worker advertises abstract profile metadata without a second worker.
- Missing Core execution contract fails closed in the DT Lua adapters.
- Core participant commits precede the Hoomans primary commit.
- No native runtime or Workshop publication claim is made.
