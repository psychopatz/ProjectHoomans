# Progress — Semantic Generation Lifecycle Cleanup

**Status:** IN_PROGRESS.
**Current phase:** G3 — Apply-mode safe cleanup and mixed-key ownership.
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

- Implemented `psychopatzCore/tools/semantic_harness/codebuilder/reconcile.py` with `--recipe` and `--check` (plus `--format json|summary`).
- Verified that check mode reports `desired`, `missing`, `drifted`, `stale`, `retired_present`, `ambiguous`, `mixed_stale_keys`, and `preserved` across Lua, ordinary translation, `Conversation/Text`, retired paths, unknown neighbors, and mixed UI catalog cases without performing any disk writes.

## Parent completion boundary

The parent goal remains IN PROGRESS until G0–G6 are accepted.

## Next Chunk

**G3 — Unify `build.py` and `BuildPlanner` with the recipe-driven apply-mode reconciler, mixed UI key ownership, and fail-closed transaction tests.**

1. Delegate `write_conversation_output()` in `build.py` to the recipe-driven desired-artifact ledger and reconciler so `build.py`, `BuildPlanner.apply()`, and `reconcile.py --apply` share one lifecycle model.
2. Persist/consume generated-key ownership for mixed `Conversation/UI.json` catalogs so obsolete generated keys are pruned while package-authored keys remain untouched.
3. Add G3 fixture tests verifying `generate A+B → remove B → apply → B absent`, mixed UI key removal with authored key preservation, and fail-closed transaction safety when compilation/validation fails.
