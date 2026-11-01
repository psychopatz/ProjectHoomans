# Semantic Test Subsystem — current progress

**Status:** IN PROGRESS (P0 COMPLETE -> EXECUTING P1).
**Source audit reference:** local main HEAD `c7bfd491` on 2026-11-01, clean worktree. Rechecked before execution.

## Evidence & Baselines Established
- **Lua Smoke Suite Baseline:**
  - 146 `tests/pnc_semantic*_smoke.lua` files, 26,072 LOC, 3,572 assertions. All 146 pass in 3.41s (`python3 tests/run_tests.py pnc_semantic`).
  - Total semantic-named Lua tests: 153 files, all pass in 3.49s (`python3 tests/run_tests.py semantic`).
- **Python Harness Suite Baseline:**
  - 197 test modules in `tools/semantic_harness/tests/`. Verified runners: `python_runner.py` executes isolated processes with serial exclusive lanes for source authoring.
  - Verified baseline passes: `test_worker_session` (0.15s), `test_runner` (0.10s), `test_c0a_baseline` (0.54s), `test_response_observatory_matrix` (96.55s).
- **Existing Fixture Families (9 files):**
  - 5 Observatory fixtures: `observatory_core_en_tl.json`, `observatory_lifecycle_en_tl.json`, `observatory_health_authority_en_tl.json`, `observatory_permission_rejections_en_tl.json`, `observatory_greeting_selection.json`.
  - 4 C0A fixtures: `semantic_corpus.json` (23 cases), `multi_turn_scenarios.json` (5 cases), `suggestion_cases.json` (3 cases), `reply_realization_cases.json` (6 cases).
- **Test Classification & Deduplication Map:**
  - *Declarative Behavioural (migration candidates):* Pure utterance -> IR / policy decision / response / action assertion tests (e.g., `local_response_questions`, `nlu`, dialogue greeting/farewell, wellbeing claims, identity exchange).
  - *Mixed:* Conversational flow with scenario/actor context (e.g. inventory dialogue, social reaction).
  - *Imperative Contracts (strictly retained):* Low-level registration semantics, service mocks, internal memory lifecycle, action plan path providers, and engine presence boundaries.
- **Old-vs-New Parity Strategy:**
  - Both legacy Lua smoke test and new declarative fixture must run against real production Lua and demonstrate assertion parity before any legacy test is retired. Negative controls (unsupported language, unknown intent, permission rejections) are preserved.

## Phase Status
- **P0 — Inventory/classify:** ACCEPTED. Comprehensive baseline, classification, fixture inventory, runner mapping, and parity strategy established.
- **P1 — Canonical core:** IN PROGRESS. Implementing schema validator, loader with controlled expansion, real-worker execution adapter, bounded observation paths, assertion comparator, and CLI runner.
- **P2 — Behaviour pilot:** PENDING.
- **P3 — Multi-turn and existing families:** PENDING.
- **P4 — Broad safe migration:** PENDING.
- **P5 — Tooling integration:** PENDING.
- **P6 — Cleanup and efficiency:** PENDING.
- **P7 — End-to-end developer acceptance:** PENDING.

## Next Chunk — P1
Implement the canonical core test subsystem under `tools/semantic_harness/testing/`:
1. Versioned schema definition (`pnc.semantic-test.v1`) and validator.
2. Bounded assertion comparator with operators (`equals`, `notEquals`, `exists`, `absent`, `contains`, `notContains`, `prefix`, `oneOf`, `min`, `max`, `count`, `minCount`, `maxCount`, `truthy`, `falsy`).
3. Fixture loader with bounded matrix/language expansion and ID collision prevention.
4. Execution coordinator driving isolated `LuaSemanticWorker` turns and evaluating expectations against canonical observations.
5. CLI entrypoint supporting suite, case, tag, and path filtering.
6. Full unit tests validating schema enforcement, operator correctness, isolation, and error diagnostics.
