# Semantic Test Subsystem — current progress

**Status:** IN PROGRESS (P5 COMPLETE -> EXECUTING P6).
**Source audit reference:** local main HEAD `2fbd97d2` on 2026-11-01, clean worktree. Rechecked before execution.

## Evidence & Baselines Established
- **Lua Smoke Suite Baseline:**
  - 146 `tests/pnc_semantic*_smoke.lua` files, 26,072 LOC, 3,572 assertions. All 146 pass in 3.34s (`python3 tests/run_tests.py pnc_semantic`).
  - Total semantic-named Lua tests: 153 files, all pass in 3.49s (`python3 tests/run_tests.py semantic`).
- **Python Harness Suite Baseline:**
  - 197 test modules in `tools/semantic_harness/tests/`. Verified runners: `python_runner.py` executes isolated processes with serial exclusive lanes for source authoring.
  - Baseline passes verified: `test_worker_session` (0.15s), `test_runner` (0.10s), `test_c0a_baseline` (0.62s), `test_response_observatory` (15.17s), `test_response_observatory_matrix` (92.23s), `test_semantic_test_subsystem` (1.57s), `test_pilot_parity` (51.18s), `test_p3_observatory_c0a_parity` (60.19s), `test_p4_behavior_parity` (44.02s), `test_app` (0.28s), `test_cli_parity_p13f` (29.26s).
- **Existing Fixture Families (9 files):**
  - 5 Observatory fixtures: `observatory_core_en_tl.json`, `observatory_lifecycle_en_tl.json`, `observatory_health_authority_en_tl.json`, `observatory_permission_rejections_en_tl.json`, `observatory_greeting_selection.json`.
  - 4 C0A fixtures: `semantic_corpus.json` (23 cases), `multi_turn_scenarios.json` (5 cases), `suggestion_cases.json` (3 cases), `reply_realization_cases.json` (6 cases).
- **Canonical Core Subsystem Implemented (P1):**
  - `tools/semantic_harness/testing/schema.py`: Schema `pnc.semantic-test.v1`, validator, bounded operator verification.
  - `tools/semantic_harness/testing/projection.py`: Canonical path resolution over real Lua worker observations (`ir.*`, `response.*`, `flow.*`, `messages.*`, `relationship.*`, `context.*`, `lastKey`, `firstSemanticKey`, `conversationClosed`, `fallbackLookups`, `companionCommandTransportCount`).
  - `tools/semantic_harness/testing/comparator.py`: Bounded operators (`equals`, `notEquals`, `exists`, `absent`, `contains`, `notContains`, `prefix`, `oneOf`, `min`, `max`, `count`, `minCount`, `maxCount`, `truthy`, `falsy`).
  - `tools/semantic_harness/testing/loader.py`: Fixture file discovery, JSON validation, deterministic matrix expansion, and unique case ID validation.
  - `tools/semantic_harness/testing/executor.py`: Isolated `LuaSemanticWorker` execution, multi-turn state continuity, streaming conflict detection, and structured diagnostics. Supports `rootChoice` menu interactions.
  - `tools/semantic_harness/testing/cli.py`: CLI entrypoint with suite, case, tag, pattern, and file filtering.
- **Pilot Behavioural Migration (P2) Verified:**
  - 24 cases across 5 fixture files in `tools/semantic_harness/fixtures/v1/pilot/` (`whats_up.json`, `wellbeing.json`, `identity_collision.json`, `language_variants.json`, `negative_controls.json`).
- **Multi-turn and Existing Families Migration (P3) Verified:**
  - 38 cases across 7 fixture files in `tools/semantic_harness/fixtures/v1/` (`c0a/multi_turn.json`, `c0a/suggestions.json`, `c0a/reply_realization.json`, `c0a/semantic_corpus.json`, `observatory/lifecycle.json`, `observatory/health_authority.json`, `observatory/permission_rejections.json`, `observatory/core.json`).
  - Verified with `test_p3_observatory_c0a_parity.py` (60.19s, all tests passed).
- **Broad Safe Behaviour Migration (P4) Verified:**
  - 31 cases across 4 modular fixture files in `tools/semantic_harness/fixtures/v1/behavior/` (`commands.json`, `questions.json`, `social_dialogue.json`, `inventory_dialogue.json`).
  - Verified with `test_p4_behavior_parity.py` (44.02s, 100% pass). Retained low-level imperative Lua contract tests.
- **Tooling Integration (P5) Verified:**
  - Integrated into `tools.semantic_harness.cli` (`--run-semantic-tests`, `--semantic-test-file`, `--semantic-test-suite`, `--semantic-test-filter`).
  - Supports `--jsonl` compact structured output and integrates with `ActivityLog`.
  - Verified with existing CLI parity suite (`test_app.py`, `test_cli_parity_p13f.py`).

## Phase Status
- **P0 — Inventory/classify:** ACCEPTED. Comprehensive baseline, classification, fixture inventory, runner mapping, and parity strategy established.
- **P1 — Canonical core:** ACCEPTED. Versioned schema, bounded operators, loader with matrix expansion, worker executor, CLI runner, and unit tests implemented.
- **P2 — Behaviour pilot:** ACCEPTED. 24 pilot cases across 5 fixture families validated with side-by-side parity against legacy tests.
- **P3 — Multi-turn and existing families:** ACCEPTED. 38 cases across Observatory and C0A families migrated and verified.
- **P4 — Broad safe migration:** ACCEPTED. 31 cases across 4 behavior families migrated; imperative Lua contract tests retained and verified.
- **P5 — Tooling integration:** ACCEPTED. Integrated with agent CLI and existing Semantic Lab tools.
- **P6 — Cleanup and efficiency:** IN PROGRESS. Duplicate-case lint, performance/token efficiency benchmarks, legacy duplicate deduplication.
- **P7 — End-to-end developer acceptance:** PENDING.

## Next Chunk — P6
Cleanup and efficiency:
1. Implement duplicate-case and schema lint across all v1 fixtures.
2. Measure benchmark metrics: test runtime, fixture size, context/retrieval cost, and token efficiency compared to legacy tests.
3. Verify zero regressions across all retained Lua tests, Python tests, and new fixtures.
