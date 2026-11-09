---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P1-F"
phase_commit_message: "phase(P1-F): refactor(hoomans): source projections from Core envelope"
phase_commit_vector: "project-hoomans=self"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "d1da19d15426956852ddf4e0d9517f028797b541"
updated_at: "2026-11-09T22:30:40.931438Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P1"
chunk: "P1-G"
retrieval_tier: "verify"
---


# Handoff — Semantic Harness Core Migration

## What became true

P1-F makes the Core `SessionEnvelope` the internal source for Hoomans
`sourceSnapshot` and `workingWorld` compatibility projections. Hoomans still
returns the existing schemas and fields, including patch records, provenance
overrides, and transport compaction. Provider rehydration, PNC relationship and
knowledge state, synthetic defaults, and legacy response policy remain in the
adopter.

## Remaining

Implement P1-G: classify the remaining generic `ScenarioSession` mechanics.
Audit the bounded patch-diff projection and reset/revision orchestration as
separate seams. Move only provider-neutral mechanics into Core with focused
compatibility tests.

## Resume

1. Verify the three repository HEADs and worktree fingerprints.
2. Read `P1F_ENVELOPE_INTERNAL.md` and trace patch/reset callers.
3. Decide whether each candidate belongs in Core or remains a Hoomans policy
   adapter; record the boundary before moving code.
4. Add tests before removing any duplicate implementation.

## Evidence

- `CODE_VERIFIED`: compatibility source and working projections consume one
  Core envelope per response.
- `TEST_VERIFIED`: Hoomans envelope contract, worker-module smoke, grounded
  dialogue smoke, Core Python suite (26), and Kahlua checks pass.
- `STATIC_ONLY`: most provider-neutral harness modules and tests remain
  Hoomans-owned; DTAbstract and DTHoomans are not yet full Core adopters.
- `UNVERIFIED`: native Project Zomboid SP/MP behavior remains user-owned.

## Residual findings

The broader Hoomans `test_harness` suite still reproduces three unrelated
translation/identity failures: false-name response disclosure, Tagalog
identity translation, and Tagalog identity/self-reflection catalog use. The
P1-F changed files do not own those catalogs; keep them as a follow-up
regression rather than widening this migration phase.

## Acceptance for P1-F

- Core envelope is the canonical internal source for the two Hoomans
  compatibility projections.
- Existing compatibility response shapes remain stable under focused tests.
- No provider policy or production rehydration moved into Core.
- Core participant commits precede the Hoomans primary commit.
- No native runtime or Workshop publication claim is made.
