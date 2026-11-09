---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P1-A"
phase_commit_message: "phase(P1-A): docs: classify Semantic Harness Core migration boundary"
phase_commit_vector: "project-hoomans=self"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "d1da19d15426956852ddf4e0d9517f028797b541"
updated_at: "2026-11-09T22:04:41.892843Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P1"
chunk: "P1-B"
retrieval_tier: "verify"
---


# Handoff — Semantic Harness Core Migration

## What became true

P1-A classified the remaining Hoomans harness. Python process, protocol, and
worker-session paths are already Core-backed compatibility façades. The first
safe Lua extraction is the bounded `RuntimeState` and `Values` kernel. Mixed
ScenarioSession, Conversation, projection, router, and engine seams remain in
Hoomans until typed provider callbacks exist.

## Remaining

Implement P1-B: move the bounded Lua runtime kernel to Core and keep adopter
state in explicit extension buckets.

## Resume

1. Read `P1A_MOVE_MATRIX.md` and verify current Core/Hoomans/DynamicTrading
   HEADs and worktrees.
2. Add Core `RuntimeState` and `Values` modules, redirect Hoomans imports, and
   add Core/Hoomans boundary tests.
3. Run focused tests and inspect import-zero before any deletion.

## Evidence

- `CODE_VERIFIED`: source and dependency classification completed.
- `TEST_VERIFIED`: prior protocol, worker-module, persistence, and persistent
  worker checks remain the accepted baseline.
- `STATIC_ONLY`: P1-B extraction has not started.
- `UNVERIFIED`: native Project Zomboid SP/MP acceptance.

## Expensive discoveries worth preserving

- The Hoomans Python process/protocol/session modules delegate to Core already;
  do not recreate those engines in Core.
- The Hoomans Lua worker still imports 98 provider-owned modules. Core's worker
  is a minimal standalone seam, not a drop-in replacement yet.
- `RuntimeEnvironment`, `ScenarioSession`, `Conversation`, projections, and
  command routers mix reusable mechanics with Hoomans policy and must not be
  moved wholesale.

## Blockers / open decisions

- None for P1-B. Define extension-bucket schema before moving state fields.

## Acceptance

Core owns the bounded Lua runtime-state/value kernel, Hoomans imports it through
the Core worker path, focused Core/Hoomans tests pass, and no duplicate kernel
implementation remains.
