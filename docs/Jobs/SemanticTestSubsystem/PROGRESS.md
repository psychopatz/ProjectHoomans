# Progress — Semantic Test Estate Normalization

**Status:** COMPLETE.
**Current phase:** A6R5–A6R8 COMPLETE.
**Next Chunk:** None (parent objective achieved).

## Completed phases

- **A6R5 (Descriptive semantic naming & domain-first layout):** Normalized all 38 `fixtures/v1/<domain>/<semantic-concern>.json` files across the 11 canonical domains (`actions`, `beats`, `behaviors`, `compiler`, `dialogue`, `flows`, `interaction`, `knowledge`, `realization`, `recognition`, `suggestions`), dissolved `c0a/`, `pilot/`, `operations/`, `observatory/`, and `behavior/` buckets, renamed all 42 milestone-coded Python test modules to descriptive contract names, and enforced history-token + domain/path checks in `lint.py`.
- **A6R6 (Unify legacy regression & C0A surfaces):** Retired `fixtureRoots.regression` from `provider.json`, retired the 5 legacy `observatory_*.json` files, routed GUI Regression buttons (`run_regression_lifecycle`, `run_regression_command_rejections`, `run_regression_selection`) through canonical `semantic` fixtures (`ui/regression_controller.py`), and retired the historical C0A subsystem (`c0a_baseline.py`, `test_c0a_baseline.py`, `fixtures/c0a/`, `reports/c0a/`, `test_observatory_fixture_parity.py`, `test_pilot_parity.py`, `test_behavior_fixture_parity.py`).
- **A6R7 (Global duplicate & coverage-quality guard):** Upgraded `lint.py` with global cross-suite exact-duplicate detection and bounded stimulus-overlap reporting; resolved the `ask_back_follow_up` / `suggestions.greeting` duplicate and strengthened `suggestions/contextual_reply_suggestions.json` and `realization/social_reply_outcomes.json` assertions.
- **A6R8 (Final method-level review & closure):** Regenerated `TEST_CLASSIFICATION.json` over all 177 remaining `tools/providers/pnc/tests/test_*.py` modules (745 methods) with concrete implementation-contract justifications.
