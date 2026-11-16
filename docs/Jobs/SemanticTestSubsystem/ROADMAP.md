# Roadmap — A6R9–A6R12 Final Closure Hardening

**Parent status:** COMPLETE.
**Active phase:** A6R12 (COMPLETE).
**Completion boundary:** A6R9–A6R12 accepted.

## Accepted foundation

A6R5–A6R8 substantially succeeded:

- active fixtures are domain-first and descriptively named;
- all 38 fixture files match their declared semantic domain;
- old C0A files/reports/helper are retired;
- provider `fixtureRoots.regression` is retired;
- old Observatory regression files are retired;
- global exact duplicate detection and bounded overlap reporting exist;
- 180/180 canonical fixture cases pass;
- 17/17 focused Core fixture/authority tests pass.

Do not reopen this architecture without new evidence.

## A6R9 — remove the final parallel regression lane

`tools/semantic_harness/ui/regression_controller.py` still contains two remnants:

1. unused legacy helpers `_resolve_regression_fixture()` and `_fixture_cases()`, including a `kind="regression"` path;
2. active `run_regression()`, which constructs a hard-coded four-case greeting/follow matrix and runs it through `run_quality_matrix` instead of `semantic.harness-test.v1`.

Replace the active behavior with canonical semantic fixture presets/filters using the same fixture executor as the rest of the GUI.

Preserve the user-facing Regression action if useful, but it must delegate to semantic fixtures.

Delete dead legacy resolver helpers and any imports made unnecessary by their removal.

Add a focused regression gate proving:

- no active Core GUI code requests `kind="regression"`;
- no hard-coded behavioral regression matrix bypasses the semantic fixture authority;
- lifecycle/rejection/selection/general Regression buttons all resolve canonical semantic fixtures;
- GUI domain/filter/batch/cancel behavior remains green.

**Gate:** one behavioral execution authority exists in practice, not only in provider metadata.

## A6R10 — assertion fidelity, overlap consolidation, and internal naming hygiene

### Realization assertion fidelity

Review `realization/social_reply_outcomes.json`.

Cases named for a realization outcome must assert that outcome, not merely input recognition or generic `response.exists`.

At minimum inspect:

- `retaliation_mirror`;
- `agreement`;
- `disagreement`;
- `acknowledgement`;
- `apology_deescalation`.

Assert stable evidence such as source pool, template/realization ID, dialogue act, behavioral branch, tone, or other canonical realization fields actually owned by production Lua.

If a stable realization outcome does not exist, rename the case to what it truly proves or move it to the correct domain.

### Response-pool overlap

Compare:

- `realization/response_pool_list_explain_and_sample.json`;
- `realization/response_pool_lookup_explain_and_sampling.json`.

The smaller fixture appears largely subsumed by the larger fixture. Consolidate when exact source evidence confirms redundant behavioral coverage. Keep separate cases only when they prove distinct contracts.

### Internal milestone naming

Current filenames/paths/suites/case IDs are clean, but historical labels remain inside active test metadata.

Audit and remove obsolete milestone labels from:

- Python module docstrings/class names/comments where they describe historical phase rather than current contract;
- fixture `description` fields;
- `TEST_CLASSIFICATION.json` justifications.

Known audit baseline:

- 35 Python test files / 73 matching lines contain milestone-like internal labels;
- 29 classification entries / 115 methods quote old labels;
- 17 fixture descriptions still contain C0/C3/C4-style phase labels.

Do not rewrite legitimate data IDs that are part of an actual protocol/test fixture identity unless they are historical-only.

### Python filename enforcement

The current fixture linter protects fixture path/suite/case names but does not enforce the retained Python filename contract.

Add a lightweight static gate for active semantic Python test filenames:

```text
test_<component>_<implementation-contract>.py
```

Reject historical migration markers while avoiding false positives for meaningful domain terms/numbers.

**Gate:** active human/agent-facing metadata is semantic rather than roadmap-historical, realization cases prove what they claim, and no redundant response-pool fixture remains without justification.

## A6R11 — final behavioral direct-worker migration pass

The latest structural audit found:

- 74 direct-worker modules / 326 methods labeled LOW_LEVEL_RUNTIME_CONTRACT;
- 34 of those modules / 154 methods use only worker calls already supported by the fixture pipeline.

This is a review set, not a deletion target.

Prioritize obviously behavioral suites.

### Mandatory high-value review

Inspect at method level:

- `test_contextual_acceptance_and_safety_gates.py`;
- `test_contextual_compound_and_topic_resumption.py`;
- `test_conversation_intent_routing_and_followups.py`;
- `test_conversation_multi_turn_coherence_contract.py`;
- `test_conversation_proposal_and_clarification_contracts.py`;
- `test_wellbeing_projection.py`;
- `test_unified_authority_event_followup.py`;
- suggestion/contextual choice suites whose purpose is behavioral selection rather than registry/projection mechanics.

Evidence from the audit:

- contextual acceptance/safety: 10/10 literal worker inputs already appear in fixtures;
- proposal/clarification: 7/9 literal inputs already appear in fixtures;
- wellbeing projection: 9/10 literal inputs already appear in fixtures.

For each method:

```text
semantic scenario/outcome
→ fixture authority

protocol envelope / payload validation / exact API error / editor algorithm /
quality analyzer / save/native/performance/static contract
→ imperative test
```

Use side-by-side parity before deleting behavioral methods.

Do not keep a broad Python behavioral scenario merely because it also checks `llmCalls == 0`, no dispatch, or no gameplay effects; those assertions are supported by fixtures.

Regenerate `TEST_CLASSIFICATION.json` after migration with concise, current, nonhistorical justifications.

**Gate:** no clearly behavioral direct-worker scenario remains classified as low-level solely because it runs through `LuaSemanticWorker`.

## A6R12 — exact-vector and durable-document closure

Before completion:

1. run Core fixture/authority tests;
2. run fixture lint with overlap reporting;
3. run full canonical semantic corpus;
4. run focused migrated/retained Python suites;
5. verify no active `kind="regression"` behavioral lane remains;
6. verify no historical fixture/C0A surface remains;
7. verify fixture and Python naming guards;
8. verify active docs are internally consistent.

Reconstruct the exact committed PsychopatzCore + ProjectHoomans vector and rerun the acceptance there.

Closure Git discipline:

- commit PsychopatzCore participant changes first;
- commit ProjectHoomans implementation/provider/job docs last;
- use a committed handoff with participant commit vector;
- preserve unrelated work;
- do not push/publish.

Final HANDOFF should use `checkpoint_mode: committed_handoff`, `phase_commit: self`, and record the accepted participant commit.

**Gate:** exact committed vector passes and every active job document plus durable root policy agrees on COMPLETE.

## Non-goals

- no new fixture schema/tester;
- no mass deletion by counts;
- no migration of genuine compiler/GUI/save/native/performance/quality-analyzer contracts for cosmetic uniformity;
- no weakening assertions;
- no push/publication without explicit authorization.
