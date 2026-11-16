# Progress — Semantic Generation Lifecycle Cleanup

**Status:** COMPLETE (G0–G7 accepted).
**Current phase:** G7 — Structural ownership refactor and recipe compaction (COMPLETE).
**Primary repository:** ProjectHoomans.
**Participant implementation repository:** psychopatzCore.
**Conditional participant:** DynamicTrading/DTCommon.

## Accepted groundwork & G7 completion

- **G0–G6**: Desired-artifact planning, check/apply reconciliation, safe pruning, ownership routing, deterministic generation, active hash-shard preservation, and agent-facing workflow documentation.
- **G7A — Preserve exception & structural ownership classification audit (`CODE_VERIFIED`)**:
  - Recorded complete caller/lineage/4-class classification in `docs/Jobs/SemanticGenerationLifecycleCleanup/G7A_PRESERVE_CLASSIFICATION.json` and `AUDIT.md` with zero deletions.
- **G7B — Semantic wording migration & application translation separation (`CODE_VERIFIED`, `TEST_VERIFIED`, `GENERATED_OUTPUT_VERIFIED`)**:
  - Moved ordinary application/tooling translations out of `Conversation/` into `Character/Character.json` (`Semantic/Addressing.json`, `34` keys) and `Debug/Debug.json` (`Journal/Events.json`, `PBrainZ/Interface.json`, `Telemetry/Diagnostics.json`, `56` keys), updating `PNC_TranslationBootstrap_Segments.lua` and `PNC_TranslationBootstrap.lua`.
  - Removed caller-zero `Conversation/WorldEvents/Events.json` (`EN`/`TL`).
  - Migrated remaining ConvoEngine semantic/dialogue/availability wording into canonical ConvoEngine sources under `tools/providers/pnc/codebuilder/sources/conversation/dialogue/` and emitted generated runtime translations into `Conversation/Text/convo/SemanticResponses.json` (manifest-registered in `manifests/Conversation.json`) and `ProjectHoomans` `Conversation/UI.json` (`100%` CodeBuilder-generated).
  - Removed all `22` legacy hand-authored translation files from `ProjectHoomans` `Conversation/`.
- **G7C — Compact `generation_recipe.json` & structural mixed-UI ownership (`CODE_VERIFIED`, `TEST_VERIFIED`)**:
  - Emptied `conversation_translations.preserved` (`0` preserved translation files).
  - Removed all `4` one-time historical file/key retirement lists from `generation_recipe.json`, retaining only the `3` compact structural `directory_glob` anti-regression rules.
  - Added `_structural_generated_ui_keys` in `reconcile.py` so `UI_PNC_Conversation_Suggestion_*` / `UI_DT_Conversation_Suggestion_*` keys are structurally owned and pruned without a receipt or recipe edit while `UI_PsychopatzConversation_*` authored keys in `PsychopatzCore` are preserved untouched.
- **G7D — Dynamic future-family cleanup & truthful canonical CLI (`CODE_VERIFIED`, `TEST_VERIFIED`)**:
  - Enabled automatic sibling repository discovery in `build_desired_artifact_ledger` when no explicit repo overrides are passed, making the exact `canonicalCli` command advertised in `generation_recipe.json` succeed across all 3 owners (`PsychopatzCore`, `ProjectHoomans`, `DTCommon`).
  - Added `tools/semantic_harness/tests/test_semantic_generation_lifecycle_g7.py` verifying recipe compaction, receipt-free dynamic family add/delete cleanup, and end-to-end execution of the exact advertised canonical CLI command.
- **G7E — Full verification & deterministic closure (`CODE_VERIFIED`, `TEST_VERIFIED`, `GENERATED_OUTPUT_VERIFIED`)**:
  - `convo_engine_cli.py audit-s6m8 --check-determinism`: `ok=True`, `violationCount=0`, `fileCount=379`, `diffs=[]`.
  - Two consecutive `reconcile.py --apply` passes: pass 2 wrote `0` files and pruned `0` files.
  - Final canonical `reconcile.py --check --format summary`: `clean=true`, `desired=382`, `missing=0`, `drifted=0`, `stale=0`, `retired_present=0`, `ambiguous=0`, `preserved=14` (`11` Core engine Lua + `1` Hoomans `DialogueBlocks.lua` + `2` Core `UI.json` mixed-key catalogs).
