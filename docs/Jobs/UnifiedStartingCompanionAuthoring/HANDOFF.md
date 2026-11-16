---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P1"
phase_commit_message: "phase(P1): phase(P1): complete canonical NPC authoring pipeline"
phase_commit_vector: "project-hoomans=self;psychopatz-core=9acedbea036769214ef9b5040fa906b347545c81;dynamic-trading=9c8cb3dead56d66e32fccb901b9abd3dd6c2f393"
phase_residual_vector: "project-hoomans=f7c4b306b468c5385d3887290d5c055b26f47dcfc5994f34ab273a73a1e90fe0;psychopatz-core=5e07394d60cae39c19e67aaca8e4953b6e3517cf2712657b5d4ba2df5a943d6a;dynamic-trading=3ed15f0cd080d9eb1ebcf5d1bbab66bbfdb230223af48407f02091a54ce020a5"
residual_worktree_fingerprint: "f7c4b306b468c5385d3887290d5c055b26f47dcfc5994f34ab273a73a1e90fe0"
codebase_memory_indexed_commit: "539bcb63d49148b5468f0bf611efb8c355f2ceea"
updated_at: "2026-11-16T00:49:19.408005Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P2"
chunk: "Add one provider-neutral normal/co-op character-creation extension seam"
retrieval_tier: "verify"
---


# Session Handoff

## What became true

- P1's canonical NPC authoring registry, sparse blueprint, policy resolver,
  deterministic seed/fingerprint contract, compact codec, and shared trace are
  implemented.
- Existing Unique NPC draft/storage/registration/resolution/debug inspection
  now consumes that pipeline; no companion-only authoring model was added.
- `identity.nickname` round-trips through draft, canonical save/load, Unique
  resolve, and runtime identity. Superseded Unique authoring/persistence aliases
  are no longer read or emitted.
- P1 focused verification passed. The full suite has four unrelated failures
  in pre-existing dirty areas; see `PROGRESS.md`.

## Remaining

P2-P6 of the parent goal remain. Do not add companion UI before the P1 phase
commit is verified and the generic character-creation seam is established.

## Resume

Use Codebase Memory at the recorded verification tier, then inspect current
source and Git status before editing; the repository is intentionally dirty
outside the exact P1-owned paths.

Exact next action:

1. Inspect the existing PsychopatzCore `CharacterCreationProfession` patch and
   the Build 42 normal/co-op inheritance seam.
2. Add only a provider-neutral extension registry/notification path; keep all
   Project Hoomans companion semantics in Project Hoomans.
3. Add focused harness coverage proving normal and co-op paths use the same
   extension point.

## Evidence

- `TEST_VERIFIED`: focused harness 14/14 and required starter/Unique regressions
  pass.
- `CODE_VERIFIED`: registry-driven serializer/codec, explicit absent/value/clear
  blueprint semantics, deterministic resolver trace, Unique cutover, and debug
  Resolution Inspector are present in P1-owned files.
- `UNVERIFIED`: native SP/MP/co-op UI, companion session/presets, and MP
  lifecycle authority are intentionally still open.

## Expensive discoveries worth preserving

- `StartingCompanionService` remains the canonical spawn/recruitment,
  relationship, knowledge, faction/community, persistence, and reconnect owner.
- Existing relationship specs already provide Brother/Sister/Mom/Dad/Lover/
  Friend policy data; Lover orientation must continue through
  `StartingCompanionTraits.ResolveCompanionFemale`.
- `CoopCharacterCreationProfession` derives from the normal profession class,
  so a single generic parent seam should cover both.
- `name` in Unique runtime records is now explicitly a derived projection, not
  a second authored/persisted field.

## Blockers / open decisions

- None for P1.
- Native Build 42 acceptance remains user-owned and must not be inferred from
  headless tests.

## Acceptance

P1 is accepted only after `agent-phase commit` creates the exact local commit
with this handoff and verifies the residual unrelated worktree fingerprint.
