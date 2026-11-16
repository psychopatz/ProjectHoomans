# Progress — Semantic Generation Lifecycle + Portable PSDL Toolchain

**Status:** COMPLETE (G0–G7, G7R1–G7R3, G8A–G8F accepted).
**Current phase:** COMPLETE.

## Accepted G7R closure

- **G7R1 — Structural authored Lua ownership (`CODE_VERIFIED`, `TEST_VERIFIED`)**:
  - Removed `conversation_lua.preserved` from `generation_recipe.json`.
  - Marked all 12 legitimate engine/adapter Lua files (`11` in `PsychopatzCore/ConvoEngine/*.lua`, `1` `PNC/ConvoEngine/DialogueBlocks.lua`) with `-- ConvoEngine: hand-written` and updated `reconcile.py` (`_has_handwritten_convo_lua_header`) so unmarked/unknown Lua files still fail closed as `ambiguous`.
- **G7R2 — Core mixed UI seam (`CODE_VERIFIED`, `TEST_VERIFIED`)**:
  - Bounded `PsychopatzCore` `Conversation/UI.json` via `_structural_generated_ui_keys` (`UI_PNC_Conversation_Suggestion_*` / `UI_DT_Conversation_Suggestion_*`), pruning removed generated keys without receipts or recipe edits while preserving `UI_PsychopatzConversation_*` authored keys.
- **G7R3 — Committed multi-repository closure (`CODE_VERIFIED`, `TEST_VERIFIED`)**:
  - Normalized `Manifest.lua` `sourceRepository` to portable repository names in `conversation_registry.py`, committed all phase-owned outputs across `psychopatzCore`, `DynamicTrading`, and `ProjectHoomans`, and verified canonical `--check`, `audit-s6m8 --check-determinism`, and lifecycle tests on an isolated `git archive` committed-vector reconstruction before any `--apply`.

## Accepted G8 portable PSDL toolchain

- **G8A — Compact authoring schema + formal compiler boundary (`CODE_VERIFIED`, `TEST_VERIFIED`)**:
  - Implemented `tools/semantic_harness/codebuilder/psdl_compact.py` (`psychopatz.psdl.v2` compact schema, `parse_predicate_expr`, shallow `package.json` + `provenance.lock` splitting, keyed `candidates` maps, family-owned `textSidecars`, and `psdl_compiler.py` integration) compiling into equivalent canonical IR.
- **G8B & G8C — Portable standard runtime & recreatable logic (`CODE_VERIFIED`, `TEST_VERIFIED`)**:
  - Implemented `tools/semantic_harness/codebuilder/portable_runtime.py` (`compile_portable_plan`, `PortableReferenceVM` v1.0.0 with predicate evaluation, exact/tolerant/`safe_recovered` fuzzy recognition, beat/behavior directors, realization anti-repeat selection, and generic action/outcome lifecycle).
- **G8D — Capability ABI + data-driven descriptors (`CODE_VERIFIED`, `TEST_VERIFIED`)**:
  - Implemented `tools/semantic_harness/codebuilder/capability_abi.py` (`validate_target_capabilities`, `generate_adapter_stub_guidance`) and enabled custom adopter owners on compact portable PSDL without hard-coded adopter routing.
- **G8E & G8F — Reference backend, progressive-disclosure UX & clean rebuild (`CODE_VERIFIED`, `TEST_VERIFIED`)**:
  - Implemented `tools/semantic_harness/codebuilder/psdl_inspect.py` and `convo_engine_cli.py get <id> --summary|--source|--ir` and `impact <id>`.
  - Verified full G8A–G8F acceptance in `tools/semantic_harness/tests/test_psdl_toolchain_g8.py` (`22/22` G8 + lifecycle tests passing) and clean two-pass no-op rebuilds.
