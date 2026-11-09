---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P1-C"
phase_commit_message: "phase(P1-C): refactor(hoomans): configure Core transport evidence"
phase_commit_vector: "project-hoomans=self"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "d1da19d15426956852ddf4e0d9517f028797b541"
updated_at: "2026-11-09T22:13:14.791212Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P1"
chunk: "P1-D"
retrieval_tier: "verify"
---


# Handoff — Semantic Harness Core Migration

## What became true

Core owns the bounded Lua runtime/value kernel and generic transport evidence
partitioning. Hoomans configures its interaction-lifecycle fact command through
the Core transport module. The Hoomans duplicates are deleted and focused Core
and Hoomans gates pass.

## Remaining

Implement P1-D: split ScenarioSession lifecycle/projection mechanics from
Hoomans production payload and rehydration policy.

## Resume

1. Verify current Core/Hoomans/DynamicTrading HEADs and worktrees.
2. Trace ScenarioSession lifecycle, payload, projection, defaults, and snapshot
   callers before choosing a move boundary.
3. Define a Core-neutral session envelope with provider payload extensions;
   leave Hoomans rehydration and production records in the adopter.

## Evidence

- `CODE_VERIFIED`: Core owns RuntimeState, Values, and TransportEvidence;
  Hoomans duplicates are absent.
- `TEST_VERIFIED`: Core transport/worker checks and Hoomans worker-module,
  persistence, and persistent-worker checks pass after deletion.
- `STATIC_ONLY`: P1-D ScenarioSession boundary is not yet implemented.
- `UNVERIFIED`: native Project Zomboid SP/MP acceptance.

## Expensive discoveries worth preserving

- Hoomans Python process/protocol/session modules already delegate to Core.
- The Hoomans Lua worker still imports the remaining provider-owned module tree.
- ScenarioSession, Conversation, projections, routers, and engine boundaries
  mix reusable mechanics with Hoomans policy; do not move them wholesale.

## Blockers / open decisions

- None for P1-D. Provider payload extension names must remain namespaced and
  bounded so DTAbstract and DTHoomans can share the envelope.

## Acceptance

Core owns the generic ScenarioSession envelope/lifecycle seam, Hoomans retains
provider payload policy, focused Core/Hoomans tests pass, and no duplicate
session kernel remains.
