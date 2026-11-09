---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P1-D"
phase_commit_message: "phase(P1-D): docs: define Core ScenarioSession boundary"
phase_commit_vector: "project-hoomans=self"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "d1da19d15426956852ddf4e0d9517f028797b541"
updated_at: "2026-11-09T22:14:33.179189Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P1"
chunk: "P1-E"
retrieval_tier: "verify"
---


# Handoff — Semantic Harness Core Migration

## What became true

P1-D traced ScenarioSession lifecycle, payload, projection, defaults, and
snapshot callers. The reusable boundary is a Core `SessionEnvelope`; Hoomans
must retain rehydration, PNC relationship/knowledge state, synthetic defaults,
and legacy response compatibility.

## Remaining

Implement P1-E: add the Core `SessionEnvelope` and a Hoomans compatibility
projection that exposes it without changing existing response fields.

## Resume

1. Read `P1D_SESSION_BOUNDARY.md` and verify current three-repository HEADs.
2. Add bounded Core envelope mechanics and focused Core smoke coverage.
3. Add the Hoomans neutral-envelope projection, run existing worker/persistence
   tests, and defer response-field deletion.

## Evidence

- `CODE_VERIFIED`: ScenarioSession source/caller boundary is documented.
- `TEST_VERIFIED`: P1-C Core/Hoomans gates remain green.
- `STATIC_ONLY`: Core SessionEnvelope implementation has not started.
- `UNVERIFIED`: native Project Zomboid SP/MP acceptance.

## Expensive discoveries worth preserving

- ScenarioSession directly reads `PNC` and Hoomans production rehydration state;
  moving it wholesale would make Core provider-specific.
- Existing Hoomans response fields are consumed by the Python worker/UI and
  must remain during envelope adoption.
- The Core envelope must namespace opaque provider payloads by provider ID.

## Blockers / open decisions

- None for P1-E. Keep the envelope bounded and preserve immutable-source and
  working-world revision semantics.

## Acceptance

Core owns the neutral SessionEnvelope, Hoomans exposes it through an adapter,
existing Hoomans fields remain compatible, focused tests pass, and no provider
policy moves into Core.
