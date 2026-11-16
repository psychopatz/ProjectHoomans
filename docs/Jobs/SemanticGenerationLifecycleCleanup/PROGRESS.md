# Progress — Semantic Generation Lifecycle Cleanup

**Status:** IN_PROGRESS.
**Current phase:** G5 — Regression and determinism closure.
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

- Encoded confirmed G0 retirements and anti-regression tombstones in `psychopatzCore/tools/semantic_harness/codebuilder/generation_recipe.json`.
- Verified `reconcile.py --check` before apply detected all retired files (`Conversation/Command.json` in `EN`/`TL`), retired mixed UI keys (7 keys in `ProjectHoomans` `Conversation/UI.json` in `EN`/`TL`), and drifted manifests (`DTCommon` `Registry.lua`/`Manifest.lua`, `ProjectHoomans` `manifests/Conversation.json`).
- Executed `reconcile.py --apply` across `PsychopatzCore`, `ProjectHoomans`, and `DynamicTrading` while preserving all 27 active hash-suffixed shards, all 38 preserved authored files/catalogs, and all unrelated concurrent worktree changes.
- Verified post-apply `reconcile.py --check` reports `missing = 0`, `drifted = 0`, `stale = 0`, `retired_present = 0`, `ambiguous = 0` across `DTCommon`, `ProjectHoomans`, and `PsychopatzCore`.
- Updated `test_semantic_authority_boundaries.py` and `test_semantic_observatory_scale.py` so `ProjectHoomans` tests assert `Command.json` retirement rather than its presence.

## Parent completion boundary

The parent goal remains IN PROGRESS until G0–G6 are accepted.

## Next Chunk

**G5 — Add permanent regression coverage for the full HARNESS_ACCEPTANCE matrix and two-pass determinism.**

1. Add comprehensive lifecycle regression suite (`test_semantic_generation_lifecycle_g5.py`) covering:
   - source deletion removes obsolete generated file;
   - source rename retires old path;
   - owner migration `ProjectHoomans → PsychopatzCore` removes former Hoomans output;
   - owner migration to `DTCommon` routes and cleans correctly;
   - mixed UI generated-key deletion preserves authored keys;
   - obsolete translation domain file is pruned;
   - `Conversation/Text` retains closed-set behavior;
   - retired path reintroduction fails `--check` (`retired_present`) and is cleaned by `--apply`;
   - unknown/unowned neighbor file is never automatically deleted;
   - active hash-suffixed shard in desired ledger is preserved;
   - two consecutive apply passes are byte-identical and produce zero diff.
2. Run affected Python tests, full CodeBuilder generation tests, and relevant repository test suites.
