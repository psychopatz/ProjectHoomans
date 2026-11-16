# Progress — Semantic Generation Lifecycle Cleanup

**Status:** IN_PROGRESS.
**Current phase:** G2 — Check-mode reconciler.
**Primary repository:** ProjectHoomans.
**Participant implementation repository:** psychopatzCore.
**Conditional participant:** DynamicTrading/DTCommon.

## Accepted phases

### G0 — Baseline inventory and ownership classification (`ACCEPTED`)

Evidence: `CODE_VERIFIED`, `GENERATED_OUTPUT_VERIFIED` (`docs/Jobs/SemanticGenerationLifecycleCleanup/G0_SURFACE_INVENTORY.json`).

- Audited exact workspaces across `ProjectHoomans` (`02c7fb18e714`), `psychopatzCore` (`e3eb7ddce389`), and `DynamicTrading` (`9c8cb3dead56`) without deleting any runtime or generated files.
- Classified all semantic generation surfaces (`conversation_lua`, `conversation_ui`, `conversation_text`, `conversation_translations`, `lexicon_lua`) and identified concrete retired artifacts (`Conversation/Command.json` in `EN`/`TL` and 7 obsolete formerly generated keys in `ProjectHoomans` `Conversation/UI.json`).

### G1 — Generation recipe and desired-artifact ledger (`ACCEPTED`)

Evidence: `CODE_VERIFIED`, `TEST_VERIFIED` (`tools.semantic_harness.tests.test_generation_recipe`, `test_codebuilder`, `test_conversation_text_catalog`, `test_convo_engine_s9h6_build_planner`).

- Added `psychopatzCore/tools/semantic_harness/codebuilder/generation_recipe.json` and `generation_recipe.py` with fail-closed validation on unknown owners, generators, surfaces, or policies.
- Fixed `uiLocations` lookup precedence in `conversation_translation_catalogs_by_owner()` so `question.wellbeing` and `question.activity` UI suggestion keys route to `PsychopatzCore`.
- Added effect-free `plan_runtime_text_catalogs()` in `conversation_text_catalog.py` and `build_desired_artifact_ledger()` in `generation_recipe.py` producing complete desired-artifact rows (`owner`, `surface`, `path`, `artifact_kind`, `source_lineage`, `cleanup_policy`, `content_fingerprint`, `generated_keys`) across all enabled owners without runtime filesystem writes.

## Parent completion boundary

The parent goal remains IN PROGRESS until G0–G6 are accepted.

## Next Chunk

**G2 — Implement the dry/check-mode reconciler entrypoint (`reconcile.py --check`) in PsychopatzCore.**

1. Implement `reconcile.py` in `psychopatzCore/tools/semantic_harness/codebuilder/` with `--recipe` and `--check`.
2. Report `desired`, `missing`, `drifted`, `stale`, `retired_present`, `ambiguous`, `mixed_stale_keys`, and `preserved` per owner and overall with zero filesystem mutations in check mode.
3. Validate with fixture tests across Lua, ordinary translation, `Conversation/Text`, retired paths, unknown neighbors, and mixed UI catalog cases.
