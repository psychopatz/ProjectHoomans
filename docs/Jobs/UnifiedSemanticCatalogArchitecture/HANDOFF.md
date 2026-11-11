---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P3E"
phase_commit_message: "phase(P3E): phase(P3E): extract Conversation shard assembly"
updated_at: "2026-11-11T14:45:09.606979Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P3 — Compiler modularization"
chunk: "P4 — migrate runtime consumers from the legacy conversation tree"
retrieval_tier: "verify"
phase_commit_vector: "project-hoomans=self;psychopatz-core=f40c42859bdb13eccf6ac23814f00ead0f7c303c;dynamic-trading=8ece4d3c8dbb3b6bc8bac176ce77eef506cbabe7"
phase_residual_vector: "project-hoomans=e5db3fd088b4fd119d9c786d7ffbcb06721b1ee3a96e757e3192f2256795b7f4;psychopatz-core=858b44f5cf795c753aa278225bad8d630c071ea03b602a079ceb03f5303cfb33;dynamic-trading=dafa3368287d0774225ebc447f3c3705b85f8754cabd2d9274abf52640d86d90"
residual_worktree_fingerprint: "e5db3fd088b4fd119d9c786d7ffbcb06721b1ee3a96e757e3192f2256795b7f4"
codebase_memory_indexed_commit: "5bdcacc31dab7c49d5bd14294739b2467699098d"
---




# Session Handoff

## What is true

- The unified semantic catalog goal is active.
- Project Hoomans is the primary job repository; PsychopatzCore and Dynamic
  Trading are participant repositories.
- Core owns the only harness and canonical CodeBuilder locale catalogs.
- All 122 Core semantic shards and the Dynamic Trading external pack use
  `psychopatz.semantic.shard.v2` with explicit ownership and profiles.
- Duplicate filename stems and response kind/path mismatches are resolved;
  the source audit reports zero issues.
- Runtime artifacts were regenerated after the renames. The composition gate
  resolves 123 shards, 703 records, and 157 generated modules with no hard
  context-health errors.
- Catalog generation is deterministic and preserves all 27 TL fallback markers.

## Remaining

- Audit whether any future domain split is needed; current source shards are
  below hard size and record budgets.
- Modularize the compiler into bounded components in P3 without output change.
- Migrate PNC runtime consumers and remove the legacy conversation tree in P4.
- Run the Core-only, PNC-only, DTAbstract, DTHoomans, and expansion-pack
  composition matrix in P5.

## Resume

1. Inventory every PNC legacy conversation loader and map it to the Core-generated contract.
2. Migrate one runtime consumer family at a time with focused Lua smoke coverage.
3. Remove the legacy tree only after no runtime or harness references remain.
