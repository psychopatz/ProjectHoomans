# Roadmap — A6R13–A6R15 Final Cleanup

**Parent status:** COMPLETE.
**Final phase:** A6R15.
**Completion boundary:** A6R13–A6R15 accepted.

## Accepted summary

- **A6R13 (Descriptive naming closure):** Fixed `_find_history_tokens()` in `psychopatzCore/tools/semantic_harness/testing/lint.py` to catch milestone families with suffixes (`s10a`, `s10c`, `s10r1`, `s6m5`, `g8r7`, `a6r13`, etc.) without false positives on legitimate protocol/data IDs (`v1`, `i18n`, `l10n`, `e2e`, `utf8`). Renamed/split the four milestone-coded PNC test files and removed roadmap provenance from active test class names, docstrings, and `TEST_CLASSIFICATION.json`.
- **A6R14 (Behavioral fixture ownership):** Migrated behavioral recognition/safety, proposal/clarification, multi-turn discourse/referent/beat, and wellbeing projection scenarios into canonical fixtures (`semantic_safety_and_fuzzy_controls.json`, `multi_turn_topic_and_hostility.json`, `wellbeing_inquiries_and_reports.json`) with side-by-side parity, retained imperative contracts with specific justifications, and regenerated `TEST_CLASSIFICATION.json` (174 modules, 715 methods).
- **A6R15 (Durable closure):** Committed goal-owned durable policies in both root `AGENTS.md` files, committed `PsychopatzCore` participant (`3dfdf0dc15b4`) first and `ProjectHoomans` primary last, reconciled all job docs to `COMPLETE`, and verified the exact committed vector.
