---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P1-B"
phase_commit_message: "phase(P1-B): refactor(hoomans): consume Core Lua runtime kernel"
phase_commit_vector: "project-hoomans=self"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "d1da19d15426956852ddf4e0d9517f028797b541"
updated_at: "2026-11-09T22:09:29.246657Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P1"
chunk: "P1-C"
retrieval_tier: "verify"
---


# Handoff — Semantic Harness Core Migration

## What became true

Core now owns the bounded Lua `RuntimeState` and `Values` kernel. The Hoomans
duplicates are deleted, and the worker resolves both modules through the
Core-first package path. Core and Hoomans focused gates pass.

## Remaining

Implement P1-C: isolate transport evidence classification behind a provider
command-classifier callback before moving mixed ScenarioSession families.

## Resume

1. Verify current Core/Hoomans/DynamicTrading HEADs and worktrees.
2. Extract generic transport partition/annotation behavior while preserving the
   Hoomans interaction-lifecycle classification.
3. Run Core worker, Hoomans worker-module, persistence, and provider matrix
   tests before moving ScenarioSession.

## Evidence

- `CODE_VERIFIED`: Core owns both kernel modules; Hoomans duplicates are absent.
- `TEST_VERIFIED`: Core kernel/worker tests and Hoomans worker-module/persistence
  tests pass after deletion.
- `STATIC_ONLY`: P1-C has not started.
- `UNVERIFIED`: native Project Zomboid SP/MP acceptance.

## Expensive discoveries worth preserving

- Hoomans Python process/protocol/session modules already delegate to Core.
- The Hoomans Lua worker still imports the remaining provider-owned module tree.
- ScenarioSession, Conversation, projections, routers, and engine boundaries
  mix reusable mechanics with Hoomans policy; do not move them wholesale.

## Blockers / open decisions

- None for P1-C. Define the command-classifier callback without importing PNC
  from Core.

## Acceptance

Core owns transport evidence mechanics, Hoomans supplies its classification
callback, focused Core/Hoomans tests pass, and no duplicate transport kernel
remains.
