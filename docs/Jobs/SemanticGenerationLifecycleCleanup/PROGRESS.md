# Progress — Semantic Generation Lifecycle Cleanup

**Status:** IN_PROGRESS.
**Current phase:** G6 — Agent workflow and documentation acceptance.
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

Evidence: `CODE_VERIFIED`, `TEST_VERIFIED` (`tools.semantic_harness.tests.test_reconcile_apply`).

### G4 — Programmatic legacy retirement and repository cleanup (`ACCEPTED`)

Evidence: `CODE_VERIFIED`, `TEST_VERIFIED`, `GENERATED_OUTPUT_VERIFIED` (`generation_recipe.json`, `reconcile.py --check`, `test_semantic_authority_boundaries`, `test_semantic_observatory_scale`).

### G5 — Regression and determinism closure (`ACCEPTED`)

Evidence: `CODE_VERIFIED`, `TEST_VERIFIED`, `GENERATED_OUTPUT_VERIFIED` (`tools.semantic_harness.tests.test_semantic_generation_lifecycle_g5`, `test_convo_engine_s6m8_audit`, `test_convo_engine_s9r_closure`, `test_convo_engine_s9_regressions`, `test_generation_ownership`).

- Added permanent lifecycle regression suite `psychopatzCore/tools/semantic_harness/tests/test_semantic_generation_lifecycle_g5.py` covering source deletion, source rename, owner migration (`ProjectHoomans → PsychopatzCore → DTCommon`), mixed UI generated-key deletion with authored key preservation, obsolete translation domain pruning, `Conversation/Text` closed-set pruning, retired path reintroduction detection and cleanup, unknown/unowned neighbor preservation + strict-closure failure, active hash-shard preservation, and two-pass byte/mtime determinism.
- Verified 70 tests across 13 CodeBuilder/ConvoEngine/ownership test suites pass.
- Verified a second consecutive `reconcile_apply()` on the real three-repository workspace writes 0 files, prunes 0 files/keys, and leaves Git status unchanged.

## Parent completion boundary

The parent goal remains IN PROGRESS until G0–G6 are accepted.

## Next Chunk

**G6 — Finalize the durable `AGENTS.md` workflow, update CodeBuilder documentation, and verify agent discoverability and final closure.**

1. Inspect and finalize the brief semantic-generation workflow in root `AGENTS.md` files (`ProjectHoomans`, `psychopatzCore`) and `psychopatzCore/tools/semantic_harness/codebuilder/README.md` so documentation and CLI agree and no instruction tells agents to manually patch/delete generated semantic runtime artifacts.
2. Add a G6 workflow/discoverability test verifying that the recipe, `--help` output, and `--explain` / report output answer which source to edit, which command checks state, which command applies cleanup, and why a candidate was deleted or preserved without reading the full generated tree.
3. Run final canonical `reconcile.py --check` across all enabled owners and full regression suites to close G6 and the parent goal.
