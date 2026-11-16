# Roadmap — All-in-One PSDL Semantic Tester

**Parent status:** COMPLETE.
**Active phase:** A6 (COMPLETE).
**Completion boundary:** A1–A6 accepted.

## A1 — typed fixture operation registry

Extend the existing `action + payload` fixture seam instead of creating another schema or runner.

Current defect:
- schema accepts arbitrary `action` + `payload`;
- executor implements only `action == preview`;
- all other worker operations are inaccessible declaratively.

Create one allowlisted operation registry:

```text
fixture action id
→ payload validator
→ bounded production worker operation
→ normalized result envelope
```

Initial operation families should cover the production worker APIs needed by behavioural acceptance:
- beat: catalog / validate / register / preview;
- behavior: validate / register;
- knowledge: bootstrap / metrics / inspect / propagate / discover;
- backstory / backstory fact;
- commitment;
- response lookup / list / detail / explain / sample;
- flow validate / register / generate / coverage;
- typed interaction preview where useful.

Keep existing text/preview/root-choice/suggestion-click syntax backward compatible.

Do not expose arbitrary worker method names from JSON.

Normalize operation results so the existing comparator can assert ordinary bounded paths such as `result.*`, `observation.*`, transport, flow and messages.

**Gate:** declarative fixtures can reproduce representative beat, knowledge, behavior, response-selection and flow acceptance using real production worker operations without new semantic logic in Python.

## A2 — declarative PSDL/compiler probe operations

Make the same fixture system capable of testing the authored language/toolchain before runtime.

Use existing canonical compiler APIs; do not reimplement PSDL semantics.

Support bounded operations equivalent to:
- PSDL validate/inspect;
- canonical IR inspection;
- Portable Dialogue Plan inspection;
- backend projection inspection;
- source/lineage lookup.

Fixtures should be able to assert stable semantic IDs, kind/domain/domainPath, package/owner, capabilities, outcomes, beat/behavior linkage, realization identity and generated target lineage.

Compiler probes and runtime turns may coexist in one case when that improves end-to-end acceptance.

**Gate:** one fixture can trace a representative semantic family from authored PSDL → canonical IR/portable plan → runtime behaviour.

## A3 — fixture domain model + all-in-one CLI/GUI UX

Add provider-neutral fixture metadata/tags for semantic domains without hard-coding PNC-specific categories.

Expected useful domains include:
- dialogue/recognition;
- knowledge;
- beats;
- behaviors;
- realization/response selection;
- flows/actions/suggestions;
- interaction/multi-turn;
- compiler/PSDL.

CLI and GUI should support compact filtering by domain, suite, case, tags and semantic ID/source where available.

Do not create a separate UI. Extend the existing Semantic Test / regression surface and reuse the same fixture resolver/executor/batch model.

Keep progressive disclosure: listing/filtering must not require dumping every fixture or worker trace.

**Gate:** a user/agent can run e.g. `Knowledge`, `Beats`, or one semantic ID from the same tester and receive bounded results.

## A4 — migrate high-value behavioural acceptance

Migrate behavioural tests in controlled families, preserving parity before deleting redundant imperative acceptance.

Priority migration families:
1. beat/behavior authoring + selection;
2. knowledge gossip/discovery/backstory/commitment;
3. response realization/selection matrices;
4. coherent/contextual conversation matrices;
5. suggestions/actions/wording/paraphrase behavioural acceptance.

Migration rule:

```text
question = given semantic state/input, what behaviour/outcome occurs?
→ fixture authority candidate

question = does a parser/compiler/GUI/save/native/protocol primitive work?
→ imperative contract test candidate
```

Do not mass-delete by filename. For every migrated family:
- establish fixture parity first;
- keep only minimal imperative API/contract coverage;
- remove redundant orchestration after parity;
- preserve production-Lua ownership.

**Gate:** migrated families use fixtures as the behavioural authority with no duplicate imperative acceptance for the same behaviour.

## A5 — exhaustive remaining-test classification and pruning

Audit every remaining semantic-related Python/Lua test and classify it as one of:

```text
FIXTURE_AUTHORITY
LOW_LEVEL_RUNTIME_CONTRACT
COMPILER_CONTRACT
GUI_CONTRACT
SAVE_PERSISTENCE
NATIVE_INTEGRATION
PERFORMANCE_RESOURCE
STATIC_ARCHITECTURE
```

Any behavioural semantic test left outside fixtures must have a concrete reason why declarative fixtures cannot or should not own it.

Use the current audit as baseline, not a deletion target:
- ~200 ProjectHoomans Python test modules;
- ~820 test methods;
- 148 direct-worker modules / ~617 methods;
- ~98 modules / ~400 methods conservatively identified as migration candidates.

Counts may change as the codebase evolves; exact current evidence is authoritative.

Do not migrate compiler determinism, package/import, reconciliation, GUI widget, save serialization, native/network, performance or protocol tests merely for uniformity.

**Gate:** no unexplained parallel behavioural testing system remains.

## A6 — final all-in-one acceptance and closure

Final acceptance must prove:
1. original 116-case corpus remains green;
2. new operation-registry fixtures pass against production Lua;
3. compiler/portable-plan fixtures pass;
4. beat/behavior/knowledge/realization/flow/domain fixtures pass;
5. CLI/GUI domain filtering and batch/resume pass;
6. migrated behavioural families have fixture parity before imperative pruning;
7. remaining imperative tests are explicitly classified and justified;
8. no duplicate fixture runner/schema/comparator is introduced;
9. full focused regressions and existing low-level contract suites remain green;
10. exact committed Core + ProjectHoomans vector is reconstructed and rerun;
11. docs agree on COMPLETE.

Commit accepted participant Core phases first and ProjectHoomans/job docs last.

## Non-goals

- do not make JSON fixtures executable semantic policy;
- do not expose arbitrary Python/Lua calls from fixtures;
- do not replace low-level compiler/GUI/save/native/performance tests;
- do not add a second fixture schema or second semantic tester;
- do not weaken safety assertions for migration convenience;
- do not claim native SP/MP acceptance.
