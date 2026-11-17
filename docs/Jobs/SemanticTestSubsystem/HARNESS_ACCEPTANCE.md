# Harness Acceptance — A6R23–A6R26

**Status:** COMPLETE.

## A6R23 — PNC broad-suite lifecycle

- Full PNC unittest discovery exits 0 within 900s (`255.800s`, 648 tests, `OK (skipped=27)`).
- No monotonically accumulating long-lived worker population across unrelated tests.
- Zero new test-owned Lua workers remain afterward.
- No Tk cleanup/unraisable errors (`xvfb-run` GUI journeys 15/15 OK).
- Full Core discovery remains green (`284/284 PASS in 47.650s`).
- Deterministic lifecycle regressions pass in `test_worker_session.py`.

## A6R24 — behavioral authority

- All 66 prior `LOW_LEVEL_RUNTIME_CONTRACT` direct-worker modules reviewed method-by-method (now 58 modules / 220 methods).
- Every direct-worker method has a concrete, method-specific mechanism reason in `TEST_CLASSIFICATION.json`.
- Stale-click no-suppression semantic outcome is fixture-owned in `suggestions/semantic_hub_and_suggestions.json`.
- `test_classification_guard.py` rejects missing or generic reasons.
- `test_lint.py` and the full 47-file / 282-case semantic corpus pass (`282/282 PASS in 21.13s`).

## A6R25 — identity + reproducibility

- Current module/API/error/dataset descriptions are descriptive (0 active milestone codes).
- Historical archives remain untouched.
- Broad tests derive live repository paths from the reconstructed workspace; 0 hardcoded live workspace paths remain (guarded by `test_catalog_naming.py` and `test_classification_guard.py`).
- Final acceptance vector includes `DynamicTrading` read-only commit `e21387081776e3c8c8e2ba34d419a83441be801f`.

## A6R26 — exact closure

In a clean reconstructed sibling workspace containing the exact recorded commits:

- Full Core discovery PASS (`284/284 in 47.650s`).
- Full PNC discovery PASS within 900s (`648 tests in 255.800s`, `OK (skipped=27)`).
- Worker/Tk baseline restored after each suite.
- Naming/import/classification/reproducibility guards PASS.
- Fixture lint PASS.
- Full semantic fixture corpus PASS (`282/282 in 21.13s`).
- Held-out evaluator PASS.
- All active docs report the same commits, counts, and `COMPLETE` status.
- Final Hoomans committed handoff is the last goal-owned primary commit (`phase_commit: self`).
