# Progress — Semantic Generation Lifecycle + Portable PSDL Toolchain

**Status:** IN PROGRESS.
**Current phase:** G8A — compact authoring schema + formal compiler boundary (G7R1–G7R3 complete).

## Verified current truth

Portable foundations already exist:
- actor-neutral canonical Semantic Dialogue IR;
- compiler support for dialogue, behavior, beat and realization;
- declarative social beats/behaviors;
- camp source already separates dialogue/action orchestration from actual Hoomans gameplay execution.

Compactness audit:
- 571 current semantic source files total about 1.4 MB across Core + Hoomans roots;
- all 571 repeat `schema`, `kind`, and `owner`;
- 558 repeat `namespace`;
- 371/372 explicit participant declarations are the same default pair;
- large wording banks and provenance-heavy manifests dominate agent reads even when only logic is being audited.

G8 must therefore use compact PSDL source + explicit normalized IR rather than minifying the canonical IR itself.

Current portability gaps:
- hard-coded package/owner routing and PZ output paths;
- no portable Dialogue Plan IR/backend ABI/reference runtime;
- profanity/social recognition still partly handwritten;
- fuzzy semantics not yet formalized as versioned cross-backend runtime behavior.

## Accepted G7R closure

- **G7R1 — Structural authored Lua ownership (`CODE_VERIFIED`, `TEST_VERIFIED`)**:
  - Removed `conversation_lua.preserved` from `generation_recipe.json`.
  - Marked all 12 legitimate engine/adapter Lua files (`11` in `PsychopatzCore/ConvoEngine/*.lua`, `1` `PNC/ConvoEngine/DialogueBlocks.lua`) with `-- ConvoEngine: hand-written` and updated `reconcile.py` (`_has_handwritten_convo_lua_header`) so unmarked/unknown Lua files still fail closed as `ambiguous`.
- **G7R2 — Core mixed UI seam (`CODE_VERIFIED`, `TEST_VERIFIED`)**:
  - Bounded `PsychopatzCore` `Conversation/UI.json` via `_structural_generated_ui_keys` (`UI_PNC_Conversation_Suggestion_*` / `UI_DT_Conversation_Suggestion_*`), pruning removed generated keys without receipts or recipe edits while preserving `UI_PsychopatzConversation_*` authored keys.
- **G7R3 — Committed multi-repository closure (`CODE_VERIFIED`, `TEST_VERIFIED`)**:
  - Committed all G7R-owned outputs across `psychopatzCore`, `DynamicTrading`, and `ProjectHoomans`, and verified canonical `--check`, `audit-s6m8 --check-determinism`, and lifecycle tests on an isolated `git archive` committed-vector reconstruction before any `--apply`.

## Next Chunk

**G8A — compact authoring schema + formal compiler boundary.**
