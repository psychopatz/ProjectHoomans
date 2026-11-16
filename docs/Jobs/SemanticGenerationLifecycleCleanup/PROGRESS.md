# Progress — Semantic Generation Lifecycle Cleanup

**Status:** IN_PROGRESS.
**Current phase:** G4 — Programmatic legacy retirement and repository cleanup.
**Primary repository:** ProjectHoomans.
**Participant implementation repository:** psychopatzCore.
**Conditional participant:** DynamicTrading/DTCommon.

## Accepted phases

### G0 — Baseline inventory and ownership classification (`ACCEPTED`)

Evidence: `CODE_VERIFIED`, `GENERATED_OUTPUT_VERIFIED` (`docs/Jobs/SemanticGenerationLifecycleCleanup/G0_SURFACE_INVENTORY.json`).

### G1 — Generation recipe and desired-artifact ledger (`ACCEPTED`)

Evidence: `CODE_VERIFIED`, `TEST_VERIFIED` (`tools.semantic_harness.tests.test_generation_recipe`).

### G2 — Check-mode reconciler (`ACCEPTED`)

Evidence: `CODE_VERIFIED`, `TEST_VERIFIED` (`tools.semantic_harness.tests.test_reconcile_check`).

### G3 — Apply-mode safe cleanup and mixed-key ownership (`ACCEPTED`)

Evidence: `CODE_VERIFIED`, `TEST_VERIFIED` (`tools.semantic_harness.tests.test_reconcile_apply`, `test_convo_engine_s9h6_build_planner`, `tools.providers.pnc.tests.test_generation_ownership`).

- Unified `write_conversation_output()` in `build.py` and `BuildPlanner.apply()` with `reconcile_apply()` so all generation entrypoints execute the same desired-artifact ledger and post-write closure semantics.
- Added generated-key ownership tracking and receipt persistence (`load_owner_receipt` / `write_owner_receipt`) for mixed `Conversation/UI.json` catalogs so obsolete formerly generated keys are pruned while package-authored keys survive untouched.
- Verified with `test_reconcile_apply.py` that:
  - `generate A+B → remove B → apply → B absent` while `A` and declared preserved authored neighbors (`DialogueBlocks.lua`) remain byte-stable with unchanged mtime;
  - removing a generated UI suggestion source prunes its generated `UI.json` keys while preserving authored keys;
  - compile/validation failure aborts before mutation and leaves existing runtime outputs and planted stale files untouched.

## Parent completion boundary

The parent goal remains IN PROGRESS until G0–G6 are accepted.

## Next Chunk

**G4 — Encode confirmed historical leftovers as recipe retirements/tombstones and run the reconciler against isolated fixtures and real participant repositories.**

1. Add the G0-audited retirement/tombstone entries (`Conversation/Command.json` in `EN`/`TL`, the 7 obsolete formerly generated `UI.json` keys in `ProjectHoomans`, and anti-regression tombstones for historical roots and pre-S5 content domain catalogs) to `generation_recipe.json`.
2. Verify check/apply retirement against isolated fixtures first.
3. Run `reconcile.py --check` then `reconcile.py --apply` then `reconcile.py --check` across `PsychopatzCore`, `ProjectHoomans`, and `DynamicTrading` while preserving unrelated dirty work.
4. Update the two test references in `ProjectHoomans` (`test_semantic_authority_boundaries.py`, `test_semantic_observatory_scale.py`) that still point at retired `Conversation/Command.json`.
