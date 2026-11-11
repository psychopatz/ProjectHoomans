---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P2A"
phase_commit_message: "phase(P2A): phase(P2A): record normalized semantic envelope checkpoint"
updated_at: "2026-11-11T14:00:35.848097Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P2 — Semantic shard normalization"
chunk: "P2B — naming collisions, repeated metadata, and bounded domain splits"
retrieval_tier: "verify"
phase_commit_vector: "project-hoomans=self;psychopatz-core=f72394ce49539295b0cea954b0d52850704740aa;dynamic-trading=51a1ac1c61012f2728fdd877d5958de045cfac7c"
phase_residual_vector: "project-hoomans=e5db3fd088b4fd119d9c786d7ffbcb06721b1ee3a96e757e3192f2256795b7f4;psychopatz-core=61ec16637fec1ad2aff33606aeafc19c7252672851614a6d57524b4d3afec51d;dynamic-trading=dafa3368287d0774225ebc447f3c3705b85f8754cabd2d9274abf52640d86d90"
residual_worktree_fingerprint: "e5db3fd088b4fd119d9c786d7ffbcb06721b1ee3a96e757e3192f2256795b7f4"
codebase_memory_indexed_commit: "5bdcacc31dab7c49d5bd14294739b2467699098d"
---


# Session Handoff

## What is true

- The unified semantic catalog goal is active.
- Project Hoomans is the primary job repository; PsychopatzCore and Dynamic
  Trading are participant repositories.
- Core owns the only harness and canonical CodeBuilder locale catalogs.
- All 122 Core semantic shards and the Dynamic Trading external pack now use
  `psychopatz.semantic.shard.v2`.
- Shards carry explicit `shardId`, `owner`, and `sourceProfile`; repeated
  provenance is held in the Core manifest's `sourceProfiles` index.
- The compiler reconstructs provenance only in memory and rejects manifest or
  shard identity mismatches.
- P2A parity is verified: 123 shards, 703 records, 157 modules, health pass,
  and byte-identical output against a migrated copy of the pre-migration Git
  tree.

## Remaining

- Complete P2B naming, duplicate-stem, and bounded-domain audit/migrations.
- Modularize the compiler in P3.
- Migrate PNC runtime consumers and remove the legacy conversation tree in P4.
- Run the complete Core-only, PNC-only, DTAbstract, DTHoomans, and expansion
  composition matrix in P5.

## Resume

1. Inspect duplicate stems, broad domains, and repeated metadata remaining in
   the v2 source tree.
2. Propose stable path/name changes while preserving record and translation
   identities.
3. Split only bounded oversized domains, then run the parity and composition
   gates before accepting P2B.
