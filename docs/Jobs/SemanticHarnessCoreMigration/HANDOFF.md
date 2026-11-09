---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P1-E"
phase_commit_message: "phase(P1-E): refactor(hoomans): adopt Core session envelope"
phase_commit_vector: "project-hoomans=self"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "d1da19d15426956852ddf4e0d9517f028797b541"
updated_at: "2026-11-09T22:26:36.853259Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P1"
chunk: "P1-F"
retrieval_tier: "verify"
---


# Handoff — Semantic Harness Core Migration

## What became true

P1-E adds the provider-neutral Core `SessionEnvelope`. It projects immutable
source state, effective working state, revision metadata, opaque namespaced
provider payloads, and extensions without interpreting provider policy.

Hoomans now exposes the envelope beside its existing compatibility payload
fields. Explicit snapshots retain raw source/provider data for inspection;
mutation responses compact those fields. Hoomans still owns rehydration, PNC
relationship/knowledge state, synthetic defaults, and legacy response fields.

## Remaining

Implement P1-F: use the Core envelope internally in Hoomans `ScenarioSession`
where duplicate source/working projection mechanics can be removed without
changing compatibility responses. Keep provider policy in Hoomans until its
own boundary is classified.

## Resume

1. Verify the three repository HEADs and clean-state fingerprints.
2. Trace Hoomans `ScenarioSession` source/working projections against the Core
   envelope and identify behavior-preserving substitutions.
3. Add focused projection tests before deleting any duplicate mechanics.
4. Preserve the inspector-versus-mutation response boundary.

## Evidence

- `CODE_VERIFIED`: Core `SessionEnvelope` schema, projection, and compacting
  implementation are committed in the participant repository.
- `TEST_VERIFIED`: Core Lua envelope smoke, Core Python harness suite (26),
  Hoomans envelope contract, worker-module smoke, and grounded-dialogue smoke
  pass.
- `STATIC_ONLY`: full provider-neutral harness migration is not complete; most
  worker modules, Python harness modules, and tests remain Hoomans-owned.
- `UNVERIFIED`: native Project Zomboid SP/MP behavior remains user-owned.

## Residual findings

The broader Hoomans `test_harness` suite reproduces three unrelated
translation/identity failures: false-name response disclosure, Tagalog
identity translation, and Tagalog identity/self-reflection catalog use. The
P1-E focused contract passes and the changed files do not own those catalogs;
these failures remain a follow-up regression, not a reason to broaden this
phase.

## Acceptance for P1-E

- Core owns the neutral session-envelope contract.
- Hoomans consumes it without deleting provider policy or compatibility fields.
- Inspector and mutation response boundaries are tested.
- Core participant commit precedes the Hoomans primary commit.
- No native runtime or Workshop publication claim is made.
