---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "G0"
phase_commit_message: "phase(G0): complete semantic generation surface inventory and ownership classification"
updated_at: "2026-11-16T12:43:13.891997Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "G1"
chunk: "G1A — Add CodeBuilder generation recipe, schema validation, and desired-artifact ledger"
retrieval_tier: "verify"
phase_commit_vector: "project-hoomans=self;psychopatz-core=e3eb7ddce389dd86129f3a40651f8e646b09afec;dynamic-trading=9c8cb3dead56d66e32fccb901b9abd3dd6c2f393"
phase_residual_vector: "project-hoomans=360b2b3e6e567149dd34fcc418f6a02441393d0be8fc6378c06cd7ceabd93167;psychopatz-core=98c4feb14bac393496f4679faf59200587d2260968b87ce88648bec1aff92c8e;dynamic-trading=3ed15f0cd080d9eb1ebcf5d1bbab66bbfdb230223af48407f02091a54ce020a5"
residual_worktree_fingerprint: "360b2b3e6e567149dd34fcc418f6a02441393d0be8fc6378c06cd7ceabd93167"
codebase_memory_indexed_commit: "02c7fb18e714bf1a3adce052c0659a972313f081"
---


# Session Handoff

## What became true

- Completed G0 baseline inventory (`G0_SURFACE_INVENTORY.json`) across `ProjectHoomans`, `psychopatzCore`, and `DynamicTrading/DTCommon` with zero deletions.
- Classified all generated Lua, `Conversation/Text`, `Conversation/UI.json`, and `Conversation/*.json` translation surfaces with explicit owner, lineage, and evidence.
- Identified concrete retired artifacts in `ProjectHoomans`: `Conversation/Command.json` (`EN`/`TL`) and 7 obsolete formerly generated keys in `Conversation/UI.json` (`EN`/`TL`), plus anti-regression tombstones for historical roots and domain files.
- Identified `uiLocations` lookup precedence bug in `conversation_translation_catalogs_by_owner()`.

## Remaining

- Implement G1–G6: generation recipe + desired-artifact ledger (G1), check-mode reconciler (G2), apply-mode safe cleanup + mixed UI key ownership (G3), programmatic legacy retirement and repository cleanup (G4), regression and determinism closure (G5), and durable agent workflow/documentation acceptance (G6).

## Resume

Use Codebase Memory at the recorded retrieval tier for the target repository.
Retrieve current structure rather than relying on a copied dependency inventory.

Exact next action:

1. Implement `generation_recipe.json`, recipe schema validation, and the effect-free desired-artifact ledger in `psychopatzCore/tools/semantic_harness/codebuilder/`.
2. Run CodeBuilder unit tests to accept G1, commit G1, and continue into G2.

## Evidence

- `CODE_VERIFIED`: Inspected `build.py`, `conversation_compiler.py`, `conversation_text_catalog.py`, `generation_ownership.py`, and Git history across all three repositories.
- `GENERATED_OUTPUT_VERIFIED`: Isolated staging output compared against live `PsychopatzCore`, `ProjectHoomans`, and `DTCommon` trees (`G0_SURFACE_INVENTORY.json`).
- `TEST_VERIFIED`: 23 existing PNC semantic authority/translation tests pass (`test_semantic_authority_boundaries`, `test_semantic_observatory_scale`, `test_semantic_translation_integration`, `test_wellbeing_wording_authority`, `test_social_apology_wording_authority`).

## Expensive discoveries worth preserving

- `Command.json` (`EN`/`TL`, 571 keys) is the sole surviving pre-S5 generated phrase-family catalog in `ProjectHoomans`; its sources migrated to ConvoEngine in `e7e44b80` and now register inline via `ConvoPlanFamily.lua`. Only `test_semantic_authority_boundaries.py` and `test_semantic_observatory_scale.py` still reference `Command.json` as a test fixture path and must be updated in G4 when `Command.json` is retired.
- The other 10 non-`Text/` catalogs under `ProjectHoomans/.../Conversation/` (`Flows`, `Patterns`, `Identity/Responses`, `Journal/Events`, `PBrainZ/Interface`, `Semantic/*`, `Telemetry/Diagnostics`, `WorldEvents/Events`) have active runtime Lua callers and must be preserved and included in `manifests/Conversation.json`.
- `conversation_translation_catalogs_by_owner()` must check `model["uiLocations"]` before `model["locations"]` for UI suggestions so `question.wellbeing` and `question.activity` UI keys route to `PsychopatzCore`.

## Blockers / open decisions

- None.

## Acceptance

G0 gate passed: every candidate cleanup surface has explicit owner, policy, and evidence in `G0_SURFACE_INVENTORY.json` and `AUDIT.md` with zero files deleted.
