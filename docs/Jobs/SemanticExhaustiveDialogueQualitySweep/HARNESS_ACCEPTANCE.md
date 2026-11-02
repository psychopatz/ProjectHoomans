# Acceptance — Semantic Exhaustive Dialogue Quality Sweep

No phase passes on a planner-only JSON file or mocked Python selector. Newly implemented behavior must be exercised through the existing production Lua worker and current Semantic Test/Observatory contracts.

## A. Baseline and reuse

- Record exact ProjectHoomans/Core revisions and relevant worker/catalog fingerprints.
- Existing Semantic Test Subsystem, Observatory, Conversation Inspector and Simulation remain authoritative; no second harness/selector/registry/GUI application is introduced.
- Existing focused test families remain green before claiming new acceptance.

## B. Dimension discovery

- Planner discovers sweepable controls from the worker's current control/persona catalogs and records their production source.
- Enum/multi-select/numeric/boolean controls are normalized correctly.
- Read-only derived fields are never mutated as inputs.
- Conditional controls such as generated personality override respect their prerequisites.
- Unknown/unsupported controls fail explicitly rather than silently disappearing.
- At least player/NPC needs, NPC personality, traits, relationship metrics/bond/identity trust/authority and selected health/activity context are proven through real worker projections.

## C. Semantic bucket correctness

- Numeric bucket policies are bounded and reproducible.
- Production thresholds are used where available and provenance/reason is recorded.
- Threshold neighbors prove expected branch/eligibility changes for at least one relationship/need/personality-sensitive response.
- The report describes coverage as semantic bucket coverage, never literal infinite/numeric exhaustiveness.

## D. Planning strategies

- Smoke produces one bounded representative set.
- Boundary covers every selected dimension bucket against controlled baseline.
- Pairwise proves every permitted selected value-pair is represented or explains a constraint exclusion.
- Persona/relationship preset covers the approved trait/style/bond/relationship matrix without unrelated-world explosion.
- Full-bounded is the deterministic deduplicated union of declared strategies.
- Same inputs/catalog revision produce identical planned case IDs/order.
- Planner can estimate total cases/batches before execution and enforce configured caps.

## E. Batch execution and resume

- Each execution batch respects the existing safe bounded case limit, normally <=64.
- Cases run through actual LuaSemanticWorker; no Python semantic oracle.
- Each case is isolated unless an explicitly declared multi-turn history requires continuity.
- Interrupted sweep can resume completed compatible batches without rerunning everything.
- Changed/stale catalog/source fingerprint refuses unsafe result mixing.
- Failed cases remain visible; failure is never silently treated as skipped/clean.
- No source save bytes, loaded media assets or user UI persistence are mutated.

## F. Compact evidence row

For representative conversation/input and root-choice cases, every rendered NPC line exposes, when available:

- case/batch/strategy/turn/language identity;
- triggering parameter vector;
- bounded persona/relationship/needs/health/activity summary;
- semantic IR/flow/policy identity;
- response pool/template/semantic variant;
- render template/realization family/realization variant;
- phrase/translation identity;
- final text/fallback;
- selection provenance and source owner or explicit UNKNOWN;
- action/transport/authority summary;
- repository/Core/catalog fingerprints.

A compact row must remain substantially smaller than a full Conversation Inspector dump. Full detail is accessible by lazy replay/inspection from case ID.

## G. Variant reachability

- Coverage starts from actual registered response pools/variants.
- Report distinguishes untested, tested-ineligible, eligible-not-selected, selected and selected-under-suspicious-context.
- Selector explanation comes from production observability, not a reconstructed Python evaluator.
- Equal-score/tie/history behavior remains production-faithful.
- Finite non-selection is never labeled globally impossible/unreachable.

## H. Deterministic quality flags

Prove positive and negative controls for at least:

- empty/one-word/very-short fragment;
- placeholder or translation-key leak;
- duplicate/repeated rendered text;
- unsupported family/relationship term;
- identity/private-name misuse where evidence exists;
- perspective-suspect case using semantic actor/referent evidence;
- generic acknowledgement suspect.

False-positive controls are mandatory: legitimate No./Yeah. or supported family wording must not be automatically classified as definite failure solely because they are short/contain a relationship word.

The user-observed family defect class must be representable: the evidence view shows final text plus family/bond/semantic path, and unsupported context receives a high-severity review flag.

## I. Clustering and affected replay

- Many rows caused by the same canonical phrase/variant/source can be grouped into one cluster.
- Cluster includes count, affected context ranges/flags, representative examples and verified source identity or UNKNOWN.
- Same visible text from different semantic sources does not get incorrectly collapsed when causes differ.
- Agent can rerun selected cluster/case IDs after a content change.
- Targeted rerun preserves source revision/fingerprint evidence and broader regression can follow.

## J. LLM/agent output

- CLI can emit compact JSONL rows and bounded cluster/review bundles.
- Filtering by severity/flag/pool/source/variant/phrase/strategy/case is supported.
- A review bundle is bounded; it does not dump tens of thousands of full traces.
- LLM review remains advisory and separate from deterministic flags.
- No LLM is required in the game runtime.
- Suggested content changes cannot alter non-text semantic/authority metadata unless a separately explicit goal authorizes that behavior change.

## K. Simulation GUI parity

- Quality Sweep lives in the existing Simulation testing/execution surface.
- GUI uses the same planner/executor/report services as CLI.
- User can choose scope/strategy, see estimated cases/batches, run/cancel/resume, filter results/clusters and inspect compact evidence.
- Open full inspector reaches existing Conversation Inspector evidence rather than recreating it.
- No duplicate Studio Test Lab/Coverage runner is added.
- GUI tests use hermetic UI state and do not touch the user's remembered save selection.

## L. Performance and storage

Measure and report:

- planning time;
- worker startup/reuse policy;
- cases/second for representative sweep;
- batch overhead;
- compact bytes/row;
- total artifact size for at least a multi-thousand-case synthetic/real-worker plan where practical;
- lazy full-trace cost;
- memory peak or bounded proxy used by the harness.

Acceptance requires bounded output and explicit caps/truncation, not a specific hardcoded machine-independent speed target.

No giant generated snapshot is committed to Git. Result/cache artifacts are gitignored and outside watched media.

## M. Regression and developer closeout

Before developer-side completion:

- relevant new Python unit/integration tests pass;
- Semantic Test Subsystem parity tests pass;
- Response Observatory tests pass;
- relevant full headless Python suite passes according to current repository practice;
- production Lua semantic smoke/regression passes;
- Kahlua verification passes for touched Lua;
- CodeBuilder/content idempotence passes if canonical dialogue assets are touched;
- git diff --check passes;
- unrelated user work is preserved.

Native Project Zomboid SP/MP remains user-owned unless separately requested. This goal should be developer-complete without requiring a Workshop publication.

## Required demonstration scenarios

At minimum produce evidence for:

1. ordinary wellbeing response across multiple persona/relationship buckets;
2. known-vs-unknown identity/relationship wording;
3. hostile vs friendly response-tone contrast;
4. supported family/bond wording and unsupported-family negative control;
5. one wrong-perspective adversarial case or known-good perspective negative control;
6. EN and TL;
7. anti-repeat history across repeated eligible turns;
8. response variant selected under more than one context;
9. eligible-but-dominated variant;
10. at least one cluster where one canonical source explains multiple bad/suspicious rows.
