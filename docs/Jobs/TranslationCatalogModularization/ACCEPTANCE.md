# Translation modularization — test and runtime acceptance

## Required baseline tests and new checks
Project Hoomans repository:
    lua tests/pnc_translation_catalog_smoke.lua
    lua tests/pnc_conversation_translation_fallback_smoke.lua
    lua tests/pz_custom_translation_manager_smoke.lua
    tools/semantic_harness/run_harness.sh --doctor --doctor-json
    python3 -m unittest discover -s tools/semantic_harness/tests -v

PsychopatzCore repository:
    lua tests/psychopatz_custom_core_translation_smoke.lua

Commands are illustrative invocations from repo roots; inspect `tests/run_tests.py`, Lua environment and existing runner instructions before invoking. Record actual executable, Lua version and output. Use the existing real production Lua Semantic Lab worker for EN/TL identity, wellbeing, social and tool replies, and its `Translations.lua` lookup instrumentation; do not replace it with Python dictionary-only tests.

## Core loader acceptance matrix
| Case | Required result |
| --- | --- |
| Legacy `registerSystem` catalog | Identical path, keys, fallback and diagnostics |
| Optional manifest with two shards | Correct key routing; actual `getModFileReader` opens correct paths |
| Identical key in two shards | Deterministic hard failure with both owner paths; no silent last-wins |
| Missing EN shard | Visible error, never silently return unrelated text |
| Missing TL key/shard | EN fallback for only affected key, audit provenance recorded |
| Language switch or forced reload | Cache invalidation correct, no stale EN/TL data |
| Malformed/unsafe manifest | Reject traversal, unknown path, missing entries, excessive file count/size |
| Translation coverage | Counts and per-key state match expected effective catalog |
| Repeated `get` after warmup | No repeated mod file IO/JSON parse for same key/language |

## Hoomans migration matrix
- Pre/post exact union of EN keys, exact union TL, EN/TL shard-path parity, duplicate-key absence.
- Preserve every existing value and placeholder including `%s`, `%1`, `{name}`; no unreviewed translation rewrites or changed response IDs.
- Confirm `PNC.Translation.GetKey`, `Get`, `TrFormat`, Core public handles and `UI_PNC_...` segment routes.
- Run actual production worker dialogue once in EN and TL with matching semantic decision and expected localized reply, plus variants and identity tool reply. Extract lookup trace, translated text and fallback warnings.
- Check actual Trading lookup/routing; do not declare broken purely from missing bootstrap entry without a consumer test.
- Confirm authored `common/media/conversation` and native `Translate` still pass their existing tests.
- Verify source mode never silently merges old+new catalog keys, and rollback works without duplicate editing.

## Game acceptance and evidence
Real PZ Build 42 SP/MP UI and language-switch tests are a separate gate after headless tests. Record: Hoomans SHA, Core SHA, exact manifest, language, worker module list, command, selected response key, actual translated output, lookup/fallback diagnostics, test result, file IO/perf evidence and native status. A green JSON parse, parity script or conflict ledger is **not** proof that the mod displayed the right language.

Avoid publishing a new localized fallback as fully translated if it simply repeats a multi-word English source; preserve accurate same-as-English audit warnings.
