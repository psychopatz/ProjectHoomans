# Semantic Test Subsystem — current progress

**Status:** IN PROGRESS (P1 COMPLETE -> EXECUTING P2).
**Source audit reference:** local main HEAD `68068df7` on 2026-11-01, clean worktree. Rechecked before execution.

## Evidence & Baselines Established
- **Lua Smoke Suite Baseline:**
  - 146 `tests/pnc_semantic*_smoke.lua` files, 26,072 LOC, 3,572 assertions. All 146 pass in 3.41s (`python3 tests/run_tests.py pnc_semantic`).
  - Total semantic-named Lua tests: 153 files, all pass in 3.49s (`python3 tests/run_tests.py semantic`).
- **Python Harness Suite Baseline:**
  - 197 test modules in `tools/semantic_harness/tests/`. Verified runners: `python_runner.py` executes isolated processes with serial exclusive lanes for source authoring.
  - Verified baseline passes: `test_worker_session` (0.15s), `test_runner` (0.10s), `test_c0a_baseline` (0.54s), `test_response_observatory_matrix` (96.55s), `test_semantic_test_subsystem` (1.57s).
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
  - Verified with `test_semantic_test_subsystem.py` (all tests pass).

## Phase Status
- **P0 — Inventory/classify:** ACCEPTED. Comprehensive baseline, classification, fixture inventory, runner mapping, and parity strategy established.
- **P1 — Canonical core:** ACCEPTED. Versioned schema, bounded operators, loader with matrix expansion, worker executor, CLI runner, and unit tests implemented.
- **P2 — Behaviour pilot:** IN PROGRESS. Migrating "What's up?", wellbeing, identity/self-state collisions, and EN/TL variants into v1 fixtures with side-by-side legacy verification.
- **P3 — Multi-turn and existing families:** PENDING.
- **P4 — Broad safe migration:** PENDING.
- **P5 — Tooling integration:** PENDING.
- **P6 — Cleanup and efficiency:** PENDING.
- **P7 — End-to-end developer acceptance:** PENDING.

## Next Chunk — P2
Migrate the pilot behavioral families:
1. "What's up?" topic & question answering (from `tests/pnc_semantic_local_response_questions_smoke.lua` and `test_whats_up_semantic_response_p12h.py`).
2. Wellbeing queries and self-state reports ("Are you okay?", "How are you feeling?", "I'm fine", need-driven replies for hunger/thirst/fatigue).
3. Identity/wellbeing collision & interruption controls (from `test_semantic_identity_wellbeing_collision.py` and `tests/pnc_semantic_nlu_smoke.lua`).
4. English/Tagalog (EN/TL) translation variants.
5. Negative controls: unresolved intent, invalid weather fallback, non-promotion of negative desires.
Verify side-by-side old-versus-new parity before retiring any duplicated declarative tests.
