# Roadmap — A6R5–A6R8 Semantic Test Estate Normalization

**Parent status:** COMPLETE.
**Active phase:** A6R8 (COMPLETE).
**Completion boundary:** A6R5–A6R8 accepted.

## Accepted foundation

The all-in-one tester works and must not be redesigned.

Accepted evidence:

- typed allowlisted fixture operations;
- compiler/IR/Portable Plan/backend/lineage probes;
- provider-aware discovery;
- CLI/GUI domain filtering;
- batch/cancel/resume;
- real production Lua execution;
- 180/180 current canonical semantic fixtures PASS;
- 16/16 Core fixture/authority tests PASS.

## A6R5 — descriptive semantic naming and domain-first layout

Normalize active fixture and retained Python-test identity so names describe what is tested rather than when it was introduced.

### Fixture naming contract

Canonical active layout:

```text
fixtures/v1/<domain>/<semantic-concern>.json

suite:
pnc.<domain>.<semantic-concern>

case ID:
<domain>.<semantic-concern>.<condition>
```

The top-level fixture directory must match the declared fixture domain unless an explicit architecture reason says otherwise.

Active names must not encode migration/history markers such as:

```text
c0a
c1 / c3b / c7a
b3 / h4 / r6 / r9 / e4 / l2 / s3
a1 / a2 / a6r2
phase6
batch1 / batch2
pilot
legacy / compat / old
```

Historical origin belongs in Git history, not active identity.

Rename or semantically split examples such as:

- `beats/interaction_preview_a6r2.json` → behavior-owned descriptive fixture;
- `compiler/a2_compiler_end_to_end.json` → compiler pipeline/linkage fixture;
- `flows/flow_authoring_a6r2.json` → flow catalog/validation/registration/generation fixture;
- `interaction/contextual_conversation_batch1.json` and `...c3_batch2.json` → concern-specific interaction/dialogue fixtures;
- `knowledge/backstory_questions_b3.json` → backstory question recognition;
- `knowledge/commitment_a6r2.json` → commitment authority/reload;
- `knowledge/knowledge_operations_a6r2.json` → bootstrap/discovery/metrics;
- `realization/response_pools_a6r2.json` → response-pool lookup/explain/sampling.

Dissolve history/tool-origin buckets such as `c0a/`, `pilot/`, `operations/`, and `observatory/` into their semantic domains where current behavior is still authoritative.

### Python test naming contract

Retained imperative files should use:

```text
test_<component>_<implementation-contract>.py
```

Rename milestone-coded files when retained. Do not merely spell out the milestone.

Examples:

- `test_contextual_conversation_c2.py` → commitment authority/reload contract;
- `test_grounded_personal_dialogue_h4.py` → knowledge persistence/scaling/filtering contract;
- `test_pragmatic_interaction_r6.py` → interaction preview/contextual resolution contract;
- `test_unified_evidence_e4.py` → grievance evidence roundtrip/repair contract.

### Enforceability

Extend fixture linting/naming checks so new active fixtures cannot reintroduce milestone/batch/history names.

**Gate:** an agent can infer semantic ownership from path/suite/case/test filename without opening the file, and the active fixture path matches the declared domain.

## A6R6 — unify legacy regression and C0A surfaces into one fixture authority

The provider currently declares:

```text
fixtureRoots.semantic   = fixtures/v1
fixtureRoots.regression = fixtures
```

The GUI still loads legacy regression files directly with `kind="regression"`.

Unify behavioral execution around the canonical `semantic.harness-test.v1` authority.

### Regression GUI

Preserve useful UI buttons such as lifecycle/rejection/selection if desired, but make them semantic-fixture presets/filters over the canonical corpus rather than a second fixture format/executor.

Retire direct dependencies on:

- `observatory_lifecycle_en_tl.json`;
- `observatory_permission_rejections_en_tl.json`;
- `observatory_greeting_selection.json`;
- other root-level Observatory regression fixtures after parity is proven.

Remove the separate provider `regression` fixture root if no non-behavioral contract genuinely requires it.

### Historical C0A subsystem

Audit:

- `tools/providers/pnc/c0a_baseline.py`;
- `tests/test_c0a_baseline.py`;
- `fixtures/c0a/*`;
- `reports/c0a/*`.

Migrate any uniquely valuable **current** implementation contract to descriptive canonical tests/fixtures.

Historical snapshots are not current behavioral authority. Once no current contract depends on them, remove the active historical subsystem and rely on Git history.

Do not preserve historical C0A files merely because older audit documents mention them.

**Gate:** one provider behavioral fixture authority remains; no live GUI/test path depends on a parallel historical fixture format.

## A6R7 — global duplicate and coverage-quality guards

Strengthen the fixture linter beyond same-suite duplicate input detection.

### Exact duplicate detection

Normalize at least:

```text
scenario
turn/action sequence
payloads
expectations
matrix semantics
```

Fail globally when two active cases are behaviorally identical, regardless of suite.

The current known exact duplicate must be resolved:

- `c0a.realization.ask_back_follow_up`
- `c0a.suggestions.greeting`

Both currently only assert greeting recognition + response existence.

### Semantic overlap reporting

Report likely overlap when multiple cases share the same scenario/input/action sequence but assert different concerns. This is not always an error; cross-domain coverage can be legitimate. The report must make review cheap.

### Name-to-assertion integrity

A fixture whose name/domain claims a behavior must assert that behavior.

Examples:

- a `suggestions` case must assert suggestion output/selection, not only `response.exists`;
- a realization case named `ask_back_follow_up` must assert the realization/follow-up evidence it names;
- operation/domain smoke cases should move to the owning domain once dedicated coverage exists.

Do not infer semantic correctness from filename alone; inspect exact expected evidence before merging.

**Gate:** lint catches global exact duplicates, produces bounded overlap diagnostics, and the active corpus contains no knowingly misleading case names.

## A6R8 — final method-level migration audit and committed-vector closure

Re-audit the remaining imperative estate after naming/unification.

Current structural candidate evidence:

- 36 LOW_LEVEL direct-worker files / 165 methods have detected worker calls already supported by fixture operations.

This is a review set, not a deletion target.

For each mixed/remaining file decide at **method responsibility**:

```text
behavioral scenario/outcome
→ fixture authority

payload validation / protocol envelope / error contract
→ LOW_LEVEL_RUNTIME_CONTRACT

compiler/generation determinism
→ COMPILER_CONTRACT

GUI lifecycle/layout
→ GUI_CONTRACT

save/native/network/performance/static
→ corresponding imperative category
```

Examples requiring method-level split:

- commitment happy path may live in fixture while unknown-evidence/wrong-owner errors remain Python;
- response selection behavior may migrate while API limit/error contracts remain Python;
- knowledge discovery behavior may migrate while large-scale storage bounds remain performance tests;
- interaction preview behavior may migrate while exact schema/output API contracts remain imperative.

Regenerate `TEST_CLASSIFICATION.json` with concrete justifications and descriptive module names.

### Final acceptance

1. canonical fixture corpus PASS;
2. Core fixture/authority tests PASS;
3. fixture paths match semantic domains;
4. no active milestone/batch/history naming violations;
5. no parallel provider regression fixture authority;
6. C0A historical surface retired or reduced only to explicitly justified nonhistorical contracts;
7. global exact-duplicate lint PASS;
8. overlap report reviewed and bounded;
9. misleading name-to-assertion cases corrected;
10. remaining imperative tests classified at real responsibility;
11. CLI/GUI semantic-fixture presets/filters PASS;
12. exact committed Core + ProjectHoomans vector reconstructed and rerun;
13. all active docs agree on COMPLETE.

Commit PsychopatzCore participant phases first and ProjectHoomans/provider/job docs last.

## Non-goals

- do not redesign the working fixture execution architecture;
- do not rename only cosmetically while preserving opaque milestone identity;
- do not retain duplicate behavioral surfaces for compatibility convenience;
- do not delete genuine low-level/compiler/GUI/save/native/performance contracts merely to reduce counts;
- do not weaken assertions during consolidation;
- do not push/publish without authorization.
