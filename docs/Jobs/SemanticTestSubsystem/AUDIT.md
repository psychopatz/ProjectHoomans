# Audit — baseline and migration hazards

Source inspected on local ProjectHoomans main at HEAD **507fca06** (2026-11-01); worktree was clean during initial audit. Counts are limited to files matching tests/pnc_semantic*_smoke.lua, **not** all semantic-related test files.

- **146** matching Lua smoke tests, approximately **26,072** lines.
- All 146 require tests/support/test; 115 explicitly invoke T.addPackagePaths(); 145 contain T.finish(); 33 reset PsychopatzCore and 56 reset PNC.
- tests/pnc_semantic_local_response_questions_smoke.lua independently constructs semantic IR/context and checks "What's up?", wellbeing, world time/date/weather, and responses; tests/pnc_semantic_nlu_smoke.lua separately boots parser/catalog/policy and asserts conversational and self-state inputs.
- Existing fixtures include **nine JSON files** under tools/semantic_harness/fixtures, split between observatory_* and fixtures/c0a (semantic_corpus, multi_turn_scenarios, suggestion_cases, reply_realization_cases). Existing formats must be inventoried before conversion.
- c0a_baseline.py is a substantial production-worker-backed characterization tool. It must not be removed before proving all unique coverage and outputs are preserved.
- LuaSemanticWorker at tools/semantic_harness/runtime/worker.py imports disposable scenario state into a persistent production-Lua process. Its existing session/worker is the primary execution seam.
- Existing Observatory/Simulation and Python tests have already established authority, read-only and user-save protection contracts; this job must not undo them.
- Classification must distinguish declarative behaviour cases, mixed suites, imperative unit contracts and engine-native acceptance. A test filename or line count alone is not proof that the test can be safely converted.
- Native SP/MP acceptance has not been performed by this documentation-only audit. No new baseline test runs were performed here.

Risks: hidden assertion coverage loss; Python duplicating policy; scenario projection not matching real gameplay; expected values overfitted to fixed prose; fixture-expansion explosion; slow startup per case; saves/real source mutation; breaking existing CLI/GUI; removing exceptional negative cases.
