---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P0"
phase_commit_message: "phase(P0): docs: bootstrap semantic harness Core migration goal"
phase_commit_vector: "project-hoomans=self"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "d1da19d15426956852ddf4e0d9517f028797b541"
updated_at: "2026-11-09T21:59:35.963733Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P1"
chunk: "P1-A"
retrieval_tier: "verify"
---


# Handoff — Semantic Harness Core Migration

**updated_at:** 2026-11-09T21:58:36Z

**state:** CLEAN_CHECKPOINT

**parent_status:** IN_PROGRESS

**phase/chunk:** P0 accepted; P1-A ready

**checkpoint:** Hoomans `fbbf9728`; Core `3abbb21`; DynamicTrading `39a3fd03`

## What is true

The protocol-only migration is committed. The Hoomans worker still loads its
98-module provider-owned worker tree, while Core's worker is intentionally a
minimal standalone seam. The full harness and test estate therefore remain
split.

## Resume action

Classify Hoomans harness modules and tests into Core kernel, provider adapter,
provider policy, and adopter acceptance groups. Start with transport/session,
scenario state, lifecycle, and projection dependencies; use graph coverage
checks and direct source reads for changed/unindexed Core files.

## Validation

Core Python and Lua protocol checks, Hoomans worker-module/persistence/
persistent-worker checks, JSON documentation validation, and cross-repository
stale-path scans passed. Native Project Zomboid acceptance was not run.

## Acceptance for P1-A

The move list names exact source/test paths, ownership, inbound callers,
provider callback seams, and the first safe Core extraction boundary. No source
file is deleted until the later import-zero and behavior gates pass.
