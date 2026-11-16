---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P2"
phase_commit_message: "phase(P2): phase(P2): add provider-neutral character creation seam"
phase_commit_vector: "project-hoomans=self;psychopatz-core=dfcf9f6e73ef50fc6c69da3bdf2aa4a5e5c61680;dynamic-trading=9c8cb3dead56d66e32fccb901b9abd3dd6c2f393"
phase_residual_vector: "project-hoomans=f7c4b306b468c5385d3887290d5c055b26f47dcfc5994f34ab273a73a1e90fe0;psychopatz-core=5e07394d60cae39c19e67aaca8e4953b6e3517cf2712657b5d4ba2df5a943d6a;dynamic-trading=3ed15f0cd080d9eb1ebcf5d1bbab66bbfdb230223af48407f02091a54ce020a5"
residual_worktree_fingerprint: "f7c4b306b468c5385d3887290d5c055b26f47dcfc5994f34ab273a73a1e90fe0"
codebase_memory_indexed_commit: "539bcb63d49148b5468f0bf611efb8c355f2ceea"
updated_at: "2026-11-16T01:04:11.364958Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "P3"
chunk: "Build the selected-trait keyed starting-companion session, composer, and presets"
retrieval_tier: "verify"
---


# Session Handoff

## What became true

- P1's canonical NPC authoring registry, sparse blueprint, deterministic
  resolver, compact codec, fingerprints, and shared resolution trace are
  implemented and committed.
- Unique NPC draft/storage/registration/resolution and the Debug Resolution
  Inspector consume that shared pipeline. Canonical `identity.nickname`
  survives draft, save, load, resolve, and runtime identity creation.
- PsychopatzCore now owns one provider-neutral character-creation extension
  seam. It wraps the normal `CharacterCreationProfession` base methods and
  therefore covers `CoopCharacterCreationProfession` through inheritance.
- Project Hoomans registers a starting-companion adapter that receives bounded
  actual selected-trait snapshots and maps them to canonical companion trait
  IDs. Core remains unaware of Hoomans semantics.

## Remaining

P3 must attach the selected-trait keyed session to this adapter, then build the
generic NPC composer, source indicators/resolved preview, deterministic
Randomize/Reset/Revert actions, presets, and shared Unique NPC import
sanitization.

## Resume

Use Codebase Memory at the recorded verification tier, then inspect current
source and Git status before editing; unrelated dirty work is intentional.

Exact next action:

1. Inspect `PNC_StartingCompanionTraits`, the existing starting service, and
   the generic Unique NPC editor controls as the P3 session/UI seams.
2. Implement session reconciliation from the adapter's actual selected set;
   preserve removed-slot cache and restore it on re-add.
3. Add focused tests before wiring UI presentation.

## Evidence

- `TEST_VERIFIED`: Hoomans focused suite **PASS 15/15**; Core trait and
  character-creation extension smoke tests pass.
- `CODE_VERIFIED`: Core extension registry, normal/co-op inherited lifecycle
  path, Hoomans adapter, and selected-trait snapshot are present.
- `STATIC_ONLY`: changed Lua passed `luac -p` and targeted Kahlua verification.
- `UNVERIFIED`: native SP/MP/co-op UI, companion session/presets, MP lifecycle
  authority, and final Build 42.20 acceptance remain open.

## Expensive discoveries worth preserving

- `CoopCharacterCreationProfession` derives from the normal profession class;
  the Core base wrapper is the reusable co-op seam.
- Starting-companion relationship specs and orientation behavior remain owned
  by `PNC_StartingCompanionTraits`; UI/session code must not duplicate them.
- `StartingCompanionService` remains the canonical spawn, recruitment,
  relationship, knowledge, faction/community, persistence, and reconnect owner.
- The P1 `name` runtime value is a derived projection, not a second authored or
  persisted truth.

## Blockers / open decisions

- None for P2.
- Native Build 42 acceptance remains user-owned and must not be inferred from
  headless tests.

## Acceptance

P2 is accepted when the exact participant and primary phase commits succeed,
the committed handoff/vector verifies, and the Core seam plus Hoomans adapter
remain free of companion-specific semantics in Core.
