# Contextual Semantic Intelligence — Phase 1B selector-boundary audit

**Updated:** 2026-10-17  
**Status:** Accepted for the deterministic Semantic Lab gate. Native SP/MP remains open.  
**Implementation revision:** 2a74683a  
**Regression revision:** 287c7db8

## Audit question

Phase 1B asks whether Phase 1A needs a new behavior-level reaction selector, or whether the existing local-response/catalog boundary already owns the decision. The audit is bounded to the QUESTION/WELLBEING path and the same recognized utterance, "Are you okay?".

## Decision: no new selector required

The existing boundary is sufficient because the change is a fact-grounded wording variant for an unsupported snapshot, not a new gameplay behavior:

1. resolveWellbeing checks whether health is unknown and there is no highest need or emotion. Only that truly unsupported case uses the semantic.question.wellbeing.unknown pool.
2. If a stronger need or emotion fact exists, the resolver calls the existing semantic.question.wellbeing pool and passes the current need type.
3. Catalog.Select performs the existing condition matching and scores candidates as priority * 100 + specificity. This keeps precedence in one existing catalog owner: panic priority 4, stress/thirst priority 3, and injured/hunger/fatigue priority 2.

The codebase-memory graph located resolveWellbeing, Catalog.Select and conditionContext; coverage reported no recorded gaps for the cited production files, with metadata freshness marked changed after the branch edits. Exact source was read directly for those files, so the graph was used as structural evidence rather than as a completeness claim.

## Regression evidence

The focused real-worker regression covers unknown health with stronger evidence:

| State | Expected existing catalog result |
| --- | --- |
| unknown health + urgent thirst | semantic.question.wellbeing.thirst |
| unknown health + panic | semantic.question.wellbeing.panic |
| unknown health + urgent thirst + panic | semantic.question.wellbeing.panic |

All three cases preserve absent routed health, use the deterministic worker, and produce no PBrainZ calls, transport events, tool calls or gameplay effects.

## Verification and limits

- python3 -m unittest tools.semantic_harness.tests.test_wellbeing_projection -v: PASS 7/7.
- python3 -m unittest discover -s tools/semantic_harness/tests -q: PASS 57/57.
- tools/semantic_harness/run_harness.sh --test pnc_semantic: PASS 66/66.
- python3 tests/run_tests.py pnc_semantic --harness-report /tmp/contextual-semantic-suite-phase1b.json: PASS 66/66; 198 events, empty conflict ledger and no audit truncation. These are protocol/replay observations, not semantic proof.
- Native Project Zomboid SP: NOT TESTED. Native MP: NOT TESTED. No UI, server, lease or authoritative-task evidence is claimed.

Phase 2 is the next bounded chunk: multi-turn wellbeing follow-up and commitment context. It must preserve this selector boundary and wait for its own gate.
