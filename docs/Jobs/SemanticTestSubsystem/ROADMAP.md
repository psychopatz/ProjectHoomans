# Roadmap — A6R16–A6R18 Cross-Repo Closure

**Parent status:** COMPLETE.
**Final phase:** A6R18.
**Completion boundary:** A6R16–A6R18 accepted.

## Accepted summary

- **A6R16 (PsychopatzCore identity):** Normalized all 23 milestone-coded Core semantic-harness test files and 3 implementation/data files (`convo_engine_integrity_audit.py`, `heldout_conversation_eval.py`, `heldout_conversations.json`) by current responsibility; replaced canonical `S6M8` UI/CLI/API/schema identities with `Run ConvoEngine Integrity Audit`, `audit-integrity`, `run_convo_engine_integrity_audit()`, and `psychopatz.convo-engine.integrity-audit.v1` (retaining explicit deprecated aliases where appropriate); added Core-side static naming guard in `test_fixture_authority.py`.
- **A6R17 (Contextual suggestion/hub ownership):** Added generic `candidateID` / `permittedAction` `suggestionClick` resolution in Core `executor.py`; migrated contextual semantic hub, follow-up, and "What's up?" behavioral scenarios into `suggestions/semantic_hub_and_suggestions.json` (15 cases) with side-by-side parity; retired `test_contextual_suggestions_whats_up.py`, `test_contextual_suggestions_followup.py`, and `test_contextual_semantic_hub.py`; retained registry, ranking, privacy, and stale-frame/cache protocol tests; regenerated `TEST_CLASSIFICATION.json` (171 modules / 702 methods).
- **A6R18 (Exact-vector closure):** Committed `PsychopatzCore` participant (`d1d4097ee4ce`) first and `ProjectHoomans` primary last; reconciled all active docs to `COMPLETE`; verified exact committed vector from clean Git worktrees.
