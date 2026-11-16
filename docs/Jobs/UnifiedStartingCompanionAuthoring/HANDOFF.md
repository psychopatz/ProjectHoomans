---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P5R2"
phase_commit_message: "phase(P5R2): repair companion editor interaction and usability"
phase_commit_vector: "project-hoomans=self;psychopatz-core=1f8125f8eb9fae30703909bbc172dd726c71a5aa;dynamic-trading=9c8cb3dead56d66e32fccb901b9abd3dd6c2f393"
phase_residual_vector: "project-hoomans=2f03db5367e1a8b90b863496523905afaf7f2aa2beabae4d135eb6a47b60dc3f;psychopatz-core=dcf1338564139bd8c279f17add564e4c1d5652eb1cfb351b3f1a2dae289344c1;dynamic-trading=bad633077ce318386be4253dbb66f903c215774b7fc93ff46ff70f59a53e53ab"
residual_worktree_fingerprint: "2f03db5367e1a8b90b863496523905afaf7f2aa2beabae4d135eb6a47b60dc3f"
updated_at: "2026-11-16T15:30:00.237692Z"
state: "USER_ACCEPTANCE"
parent_status: "IN_PROGRESS"
phase: "P5R2"
chunk: "P6 native SP/MP/co-op acceptance"
retrieval_tier: "verify"
codebase_memory_indexed_commit: "24965c9c6cef4f9b0dbadc949c9db7867a94f2a9"
---


# Session Handoff

## What became true

- P1 through P4 and P5R remain accepted. The final-screen Companions action,
  one-session lifecycle, pre-commit validation/staging, default path, and P4
  authority behavior were preserved.
- P5R2 now has one Project Hoomans-owned `PNC_NPCAuthoringEditor` presentation
  component. The debug Unique NPC creator and starting-companion editor both
  instantiate it; the companion host adds relationship policy and workflow
  actions through an adapter.
- The companion surface now uses `PsychopatzFixedWindow`, human translations,
  the mature portrait/appearance/voice/skills/traits controls, canonical
  nickname editing, Resolution Inspector diagnostics, and the existing starter
  preset store for SAVE, SAVE SET, and LOAD.
- Inherited/derived values remain read-only and rebinding updates the resolved
  preview without mutating blueprint intent or the deterministic seed.
- Native testing exposed and the follow-up fix now initializes the definition
  index's derived NPC file list before `UniqueNPCDefinitionStore.List()` is
  called by the shared editor.
- P5R2 R1-R5 developer repair is complete in Project Hoomans: native callback
  semantics now drive one atomic selected-companion transaction; preview
  identity includes slot, blueprint, seed, and relevant player context; the
  shared editor now has character-creation General/Appearance composition,
  visible/removable configured collections, bounded Advanced Clothing
  Overrides, and explicit no-selection clearing.
- The companion host remains fixed/non-collapsible and both debug and starting
  companion surfaces still instantiate the same `PNC_NPCAuthoringEditor`.
- The accepted definition-index repair remains in place: `emptyIndex()` owns
  the derived NPC file list before `UniqueNPCDefinitionStore.List()` runs.

## Next handoff

P5R2 R1-R5 developer gates are complete in the local Project Hoomans phase
commit. P6 is now the user-owned native SP/MP/co-op acceptance pass. Use a
fresh Build 42.20 session so the watcher-backed media tree loads the accepted
definition-index and editor changes.

The native matrix should cover the final-screen selector, Brother/Sister/
Mom/Dad/Lover policy bindings, Friend editing, nickname and appearance edits,
Randomize versus Reset versus Revert, preset Save/Save Set/Load, default and
open/close no-op paths, final-player rebinding, and SP/MP/co-op reconnect and
replacement-survivor authority behavior.

## Evidence

- `TEST_VERIFIED`: R1-R5 interaction/layout/collection tests, shared-editor,
  adapter, P5R journey, starter-authority, customization, relationship, and
  Unique NPC suites passed.
- `TEST_VERIFIED`: full harness passed 1035/1039; the four failures remain the
  documented unrelated animation-scene route, context scene-lab,
  population-director initialization, and dirty-work translation expectation.
- `TEST_VERIFIED`: definition-index regression plus the affected owner suite
  passed after the native-discovered fix.
- `STATIC_ONLY`: `luac -p`, targeted production `pz_verify --kahlua`,
  refactor-binding smoke, translation JSON parsing, and `git diff --check`
  passed.
- `UNVERIFIED`: native Project Zomboid SP/MP/co-op acceptance remains user
  owned.

## Expensive discoveries worth preserving

- The companion editor must remain a workflow host around the shared component;
  its raw `FieldRows()` trace is an Inspector/debug surface, not a second
  primitive editor.
- The adapter compares the edited resolved draft with a view snapshot and sends
  only editable canonical changes through `StartingCompanionSession`, which is
  what preserves no-op/open-close and inherited-field semantics.

## Blockers / open decisions

- P6 is ready for user-owned native SP/MP/co-op acceptance; the agent must not
  launch native Project Zomboid without explicit authorization.
- No architecture reset is required: retain the shared editor, fixed host,
  canonical session/resolver, P5R pre-commit flow, and P4 authority model.
- Product direction for the repair is fixed by the ROADMAP: normal companion
  General/Appearance should be character-creation focused, with dense per-body
  clothing overrides moved to an explicit advanced surface.
