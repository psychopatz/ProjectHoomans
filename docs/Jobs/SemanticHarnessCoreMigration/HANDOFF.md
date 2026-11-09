---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P1-I"
phase_commit_message: "phase(P1-I): refactor(hoomans): use Core worker lifecycle"
phase_commit_vector: "project-hoomans=self"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "d1da19d15426956852ddf4e0d9517f028797b541"
updated_at: "2026-11-09T22:41:00.512884Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P1"
chunk: "P1-J"
retrieval_tier: "verify"
---


# Handoff — Semantic Harness Core Migration

## What became true

P1-I confirms that the Python process lifecycle was already Core-backed by the
Hoomans compatibility facade. Core now also owns the shared Lua JSON-lines
`WorkerLoop`; Core and Hoomans supply only provider-specific bootstrap, hello,
and dispatch callbacks. Handshake, request IDs, protocol failure handling, and
quit behavior are shared without importing Hoomans modules into Core.

## Remaining

Implement P1-J: audit the Python scenario/session compatibility layer. Separate
provider-neutral scenario normalization, worker-session state, and process
facades from Hoomans fixture/provider policy. Keep Hoomans import paths as thin
compatibility adapters.

## Resume

1. Verify the three repository HEADs and worktree fingerprints.
2. Trace Hoomans `runtime/scenario.py`, `runtime/worker_session.py`, and Core
   `scenario.py`/`worker_session.py` ownership and callers.
3. Classify neutral normalization/state from Hoomans fixture and provider
   policy before moving code.
4. Add focused Core and Hoomans compatibility tests before extraction.

## Evidence

- `CODE_VERIFIED`: both Lua worker entry points delegate their JSON-lines loop
  to Core `WorkerLoop`.
- `TEST_VERIFIED`: Core worker-loop smoke, direct Core handshake, Core Python
  suite (26), Hoomans envelope contract, worker-module smoke, and grounded
  dialogue smoke pass.
- `STATIC_ONLY`: most provider-neutral harness modules and tests remain
  Hoomans-owned; DTAbstract and DTHoomans are not yet full Core adopters.
- `UNVERIFIED`: native Project Zomboid SP/MP behavior remains user-owned.

## Residual findings

The broader Hoomans `test_harness` suite still reproduces three unrelated
translation/identity failures: false-name response disclosure, Tagalog
identity translation, and Tagalog identity/self-reflection catalog use. The
P1-I changed files do not own those catalogs; keep them as a follow-up
regression rather than widening this migration phase.

## Acceptance for P1-I

- Core owns the shared worker loop and Hoomans remains a provider bootstrap.
- Core and Hoomans worker profiles preserve handshake/request/quit behavior.
- Core participant commits precede the Hoomans primary commit.
- No native runtime or Workshop publication claim is made.
