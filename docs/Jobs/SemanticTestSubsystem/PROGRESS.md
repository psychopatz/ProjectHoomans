# Semantic Test Subsystem — current progress

**Status:** IN PROGRESS (P4 COMPLETE -> EXECUTING P5).
**Source audit reference:** local main HEAD `2063ea61` on 2026-11-01, clean worktree. Rechecked before execution.

## Evidence & Baselines Established
- **Lua Smoke Suite Baseline:**
  - 146 `tests/pnc_semantic*_smoke.lua` files, 26,072 LOC, 3,572 assertions. All 146 pass in 3.34s (`python3 tests/run_tests.py pnc_semantic`).
  - Total semantic-named Lua tests: 153 files, all pass in 3.49s (`python3 tests/run_tests.py semantic`).
- **Python Harness Suite Baseline:**
  - 197 test modules in `tools/semantic_harness/tests/`. Verified runners: `python_runner.py` executes isolated processes with serial exclusive lanes for source authoring.
  - Baseline passes verified: `test_worker_session` (0.15s), `test_runner` (0.10s), `test_c0a_baseline` (0.62s), `test_response_observatory` (15.17s), `test_response_observatory_matrix` (92.23s), `test_semantic_test_subsystem` (1.57s), `test_pilot_parity` (51.18s), `test_p3_observatory_c0a_parity` (60.19s), `test_p4_behavior_parity` (44.02s).
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
  - 31 cases across 4 modular fixture files in `tools/semantic_harness/fixtures/v1/behavior/`:
    - `commands.json` (14 cases: follow, synonym, stop, wait, camp here/place, go home, fetch water/food/medicine/unresolved/compound)
    - `questions.json` (10 cases: location direct/find/embedded, seen present-perfect/polite, activity recent/up-to/now, date, weather)
    - `social_dialogue.json` (6 cases: offer, okay, fine by me, greeting, thanks, apology)
    - `inventory_dialogue.json` (1 case: seafood concept inquiry)
  - Verified with `test_p4_behavior_parity.py` (44.02s, 100% pass).
  - Explicitly retained low-level imperative Lua contract tests for service mocks, cognition boundary hooks, action plan path providers, and internal memory lifecycles.

## Phase Status
- **P0 — Inventory/classify:** ACCEPTED. Comprehensive baseline, classification, fixture inventory, runner mapping, and parity strategy established.
- **P1 — Canonical core:** ACCEPTED. Versioned schema, bounded operators, loader with matrix expansion, worker executor, CLI runner, and unit tests implemented.
- **P2 — Behaviour pilot:** ACCEPTED. 24 pilot cases across 5 fixture families validated with side-by-side parity against legacy tests.
- **P3 — Multi-turn and existing families:** ACCEPTED. 38 cases across Observatory and C0A families migrated and verified.
- **P4 — Broad safe migration:** ACCEPTED. 31 cases across 4 behavior families migrated; imperative Lua contract tests retained and verified.
- **P5 — Tooling integration:** IN PROGRESS. Integrating Semantic Test runner into agent CLI, Observatory, and Semantic Lab Simulation without competing engines or redundant GUI surfaces.
- **P6 — Cleanup and efficiency:** PENDING.
- **P7 — End-to-end developer acceptance:** PENDING.

## Next Chunk — P5
Tooling integration:
1. Wire `testing.cli` options directly into `tools.semantic_harness.cli` (`--run-semantic-tests`, `--semantic-test-filter`, `--semantic-test-suite`, `--semantic-test-file`).
2. Add Observatory / Semantic Lab inspection helpers to load, inspect, and run v1 test fixtures within the existing tools/semantic_harness architecture.
3. Validate that existing CLI operations, Doctor, and Simulation continue to function without disruption.
