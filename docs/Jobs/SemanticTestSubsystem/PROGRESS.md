# Semantic Test Subsystem — current progress

**Status:** IN PROGRESS (P2 COMPLETE -> EXECUTING P3).
**Source audit reference:** local main HEAD `0f2d4741` on 2026-11-01, clean worktree. Rechecked before execution.

## Evidence & Baselines Established
- **Lua Smoke Suite Baseline:**
  - 146 `tests/pnc_semantic*_smoke.lua` files, 26,072 LOC, 3,572 assertions. All 146 pass in 3.41s (`python3 tests/run_tests.py pnc_semantic`).
  - Total semantic-named Lua tests: 153 files, all pass in 3.49s (`python3 tests/run_tests.py semantic`).
- **Python Harness Suite Baseline:**
  - 197 test modules in `tools/semantic_harness/tests/`. Verified runners: `python_runner.py` executes isolated processes with serial exclusive lanes for source authoring.
  - Baseline passes verified: `test_worker_session` (0.15s), `test_runner` (0.10s), `test_c0a_baseline` (0.54s), `test_response_observatory_matrix` (96.55s), `test_semantic_test_subsystem` (1.57s), `test_pilot_parity` (51.18s).
- **Existing Fixture Families (9 files):**
  - 5 Observatory fixtures: `observatory_core_en_tl.json`, `observatory_lifecycle_en_tl.json`, `observatory_health_authority_en_tl.json`, `observatory_permission_rejections_en_tl.json`, `observatory_greeting_selection.json`.
  - 4 C0A fixtures: `semantic_corpus.json` (23 cases), `multi_turn_scenarios.json` (5 cases), `suggestion_cases.json` (3 cases), `reply_realization_cases.json` (6 cases).
- **Canonical Core Subsystem Implemented:**
  - `tools/semantic_harness/testing/schema.py`: Schema `pnc.semantic-test.v1`, validator, bounded operator verification.
  - `tools/semantic_harness/testing/projection.py`: Canonical path resolution over real Lua worker observations (`ir.*`, `response.*`, `flow.*`, `messages.*`, `relationship.*`, `context.*`).
  - `tools/semantic_harness/testing/comparator.py`: Bounded operators (`equals`, `notEquals`, `exists`, `absent`, `contains`, `notContains`, `prefix`, `oneOf`, `min`, `max`, `count`, `minCount`, `maxCount`, `truthy`, `falsy`).
  - `tools/semantic_harness/testing/loader.py`: Fixture file discovery, JSON validation, deterministic matrix expansion, and unique case ID validation.
  - `tools/semantic_harness/testing/executor.py`: Isolated `LuaSemanticWorker` execution, multi-turn state continuity, streaming conflict detection, and structured diagnostics.
  - `tools/semantic_harness/testing/cli.py`: CLI entrypoint with suite, case, tag, pattern, and file filtering.
- **Pilot Behavioural Migration (P2) Verified:**
  - 24 cases across 5 fixture files in `tools/semantic_harness/fixtures/v1/pilot/`:
    - `whats_up.json` (4 cases: basic, rain weather variant, time context, date context)
    - `wellbeing.json` (6 cases: direct inquiries, self-state reports for wellbeing, thirst, fatigue)
    - `identity_collision.json` (4 multi-turn cases: pending exchange preservation across reports and interruptions)
    - `language_variants.json` (4 matrix-expanded cases: EN & TL greetings in clear & rain weather)
    - `negative_controls.json` (6 cases: negated wellbeing, double negation, negative desires, unknown language, embedded statements, preview safety)
  - All 24 cases pass via CLI runner (39.42s). Side-by-side legacy verification in `test_pilot_parity.py` confirmed 100% parity with existing tests.

## Phase Status
- **P0 — Inventory/classify:** ACCEPTED. Comprehensive baseline, classification, fixture inventory, runner mapping, and parity strategy established.
- **P1 — Canonical core:** ACCEPTED. Versioned schema, bounded operators, loader with matrix expansion, worker executor, CLI runner, and unit tests implemented.
- **P2 — Behaviour pilot:** ACCEPTED. 24 pilot cases across 5 fixture families validated with side-by-side parity against legacy tests.
- **P3 — Multi-turn and existing families:** IN PROGRESS. Migrating/adapting Observatory and C0A case families into v1 fixtures, preserving characterization and observability outputs.
- **P4 — Broad safe migration:** PENDING.
- **P5 — Tooling integration:** PENDING.
- **P6 — Cleanup and efficiency:** PENDING.
- **P7 — End-to-end developer acceptance:** PENDING.

## Next Chunk — P3
Migrate and integrate existing fixture families:
1. Observatory case families:
   - `observatory_core_en_tl.json` (core EN/TL greetings, unknown identity)
   - `observatory_lifecycle_en_tl.json` (farewell, interruption, resumption)
   - `observatory_health_authority_en_tl.json` (pain, injury, medical treatment checks)
   - `observatory_permission_rejections_en_tl.json` (command rejection authority)
   - `observatory_greeting_selection.json` (weather/time pool selection)
2. C0A case families:
   - `semantic_corpus.json` (compact insults, hostility, threat inputs, non-mutation safety)
   - `multi_turn_scenarios.json` (hostility then apology, continued challenge, topic changes)
   - `suggestion_cases.json` (greeting, time click, hostility click availability)
   - `reply_realization_cases.json` (retaliation, agreement, disagreement, apology)
3. Ensure all existing characterization projections in `c0a_baseline.py` and `response_observatory.py` remain valid and supported.
