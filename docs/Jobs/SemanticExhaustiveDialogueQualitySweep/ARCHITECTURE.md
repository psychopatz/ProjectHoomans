# Architecture — Semantic Exhaustive Dialogue Quality Sweep

## Ownership

### Existing authoritative owners

- **PsychopatzCore NLU / ProjectHoomans semantic Lua** own interpretation, policy, flow state and semantic decisions.
- **ResponseCatalog / SpeechRealization / Dialogue Content** own semantic response identity, style realization and phrase wording according to their existing contracts.
- **Semantic Test Subsystem** owns fixture execution, scenario isolation, assertions and bounded matrix mechanics.
- **Response Observatory / Conversation Inspector** own read-only runtime evidence and provenance projection.
- **Simulation control/persona catalogs** expose production-backed editable context dimensions.
- **CodeBuilder / source-lineage infrastructure** owns canonical generated-content mapping and safe authoring boundaries.
- **Simulation GUI** is the sole GUI execution/testing/context workbench.

### New responsibilities

The new quality-sweep layer may own only:

- discovering sweepable dimensions from existing production-backed catalogs;
- assigning bounded semantic buckets to those dimensions;
- planning deterministic coverage sets;
- batching/resume bookkeeping;
- compact evidence-row aggregation;
- deterministic quality flags;
- grouping/clustering and review bundles;
- affected-case replay selection.

It must **not** decide semantic meaning, choose response variants, mutate relationship/gameplay authority, create translations, or replace existing content ownership.

## Core flow

~~~text
production catalogs + response catalog
              |
              v
       Dimension Discovery
              |
              v
       Coverage Planner
   smoke / boundary / pairwise
  reachability / persona / full
              |
              v
       Batch Manifest
       <=64 case chunks
              |
              v
       Semantic Test Executor
              |
              v
        production Lua
              |
              v
      Observatory / Inspector
              |
              v
      Compact Evidence Rows
              |
      +-------+---------+
      |                 |
      v                 v
 Quality Analyzer     Lazy full trace
      |
      v
 Canonical-source clusters
      |
      v
 JSONL / CLI / Simulation UI / LLM review
~~~

## Dimension discovery contract

Do not maintain a second manually curated list of personality/relationship controls when the worker already exposes one.

The planner should consume a bounded control inventory containing, where available:

- stable control ID;
- scenario path;
- control/value type;
- enum options and source;
- numeric min/max/step;
- read-only vs editable status;
- conditional requirements such as personality override;
- actor/section/group metadata;
- production source identifier/revision.

Only controls that can be safely projected into an isolated fixture scenario are sweepable. Read-only derived values may be recorded as output context but must not be invented as input mutations.

Some scenario dimensions may need explicit adapters when no generic control exists, such as selected health-state fixtures or conversation interaction entry points. Those adapters must remain small and source-backed.

## Semantic buckets

Numeric dimensions are not enumerated at every representable value.

Each sweepable numeric dimension receives a bounded bucket policy such as:

- endpoints;
- neutral/default;
- documented production thresholds plus just-below/at/just-above values where behavior changes;
- optional low/high representative values.

Example personality control:

0.00, 0.25, 0.50, 0.75, 1.00

Example relationship metrics should prefer actual production relationship thresholds when available rather than arbitrary values.

Example needs should sample normal/not-relevant, noticeable, urgent and extreme ranges using production semantics when known.

Bucket policies must record their source/reason. A sweep report must distinguish **semantic boundary coverage** from literal mathematical exhaustiveness.

## Coverage strategies

### Smoke

One representative/default scenario per discoverable interaction/response surface.

### Boundary

Each dimension varied through its bucket values while other dimensions remain at controlled baseline, plus threshold-neighbor cases.

### Pairwise

Deterministic covering-array/pairwise generation so every pair of approved bucket values across selected dimensions occurs at least once where constraints permit.

Do not require a third-party combinator library if a small deterministic implementation suffices, but test reproducibility and constraint handling.

### Variant reachability

Start from registered response pools/variants and use production selector traces to search bounded context candidates for eligibility/selection. Track:

- never tested;
- tested but ineligible;
- eligible but not selected/dominated in tested contexts;
- selected;
- selected only under suspicious/rare context.

Never call finite non-selection globally unreachable.

### Persona/relationship sweep

Focus on personality dimensions, traits, social style, bond kinds, relationship metrics/state, identity trust and authority-relevant context while holding unrelated world state bounded.

### Full bounded

Union/deduplicated composition of the approved strategies, executed batch-by-batch. Full means full coverage of the planner's declared semantic bucket/strategy contract at the recorded catalog revision, not every floating-point/world possibility.

## Deterministic case identity

Every planned execution needs a stable case ID derived from:

- sweep schema/version;
- coverage strategy;
- interaction/utterance/root-choice identity;
- normalized parameter vector;
- language;
- deterministic salt/history policy;
- production catalog revision/fingerprint.

Case identity must be stable across reruns at the same inputs and must make changed catalog revisions visible rather than silently reusing stale results.

## Batch and resume contract

Preserve the existing per-case matrix safety boundary. Large sweeps are composed from bounded batches, normally <=64 cases.

A manifest records at minimum:

- sweep ID/schema;
- repository/Core revisions and relevant fingerprints;
- planner version;
- selected scope/strategies;
- total planned case count;
- batch IDs/ranges;
- completed/failed/incomplete state;
- timestamps/durations as diagnostics;
- compact artifact locations;
- truncation/cap information.

Resume may continue only when source/fingerprint compatibility is proven. Stale manifests must fail safely or require a new sweep; never mix results from incompatible semantic catalogs into one apparently coherent report.

Generated sweep artifacts belong in a gitignored harness artifact/cache location outside PZ watched media and outside user saves. Do not commit giant result snapshots.

## Compact evidence-row contract

One compact row represents one rendered NPC sentence/response occurrence, not an entire giant Conversation Inspector object.

It should contain bounded fields such as:

### Identity

- sweep/case/batch ID;
- strategy;
- input/root-choice identity;
- turn index;
- language;
- deterministic salt/history mode.

### Trigger parameters

- normalized changed parameter vector;
- relevant derived context summary;
- actor/speaker/listener IDs or roles without private unbounded records;
- relationship/bond/persona summary;
- needs/health/activity fields relevant to the case.

### Semantic path

- intent/speech act/action/subject where available;
- flow/policy branch;
- response pool/template/semantic variant ID;
- render template;
- realization family/variant;
- phrase ID;
- translation key.

### Output

- final rendered text;
- fallback reason;
- bounded recent-response identity where needed for anti-repeat evidence.

### Selection/source

- selected variant provenance;
- concise candidate/rejection reason IDs or summary;
- verified canonical source/content owner when available, otherwise UNKNOWN;
- repository/Core/catalog fingerprints.

### Authority/effects

- action/transport/authority summary needed to prove wording review did not alter gameplay semantics.

### Quality

- deterministic flags plus severity/confidence;
- cluster key(s);
- LLM/human review state kept separate from deterministic evidence.

Full trace is retrieved/replayed lazily by case ID. The compact artifact must not duplicate all raw actor state or every candidate detail for every row.

## Quality analyzer contract

Deterministic flags may include high-confidence categories such as:

- EMPTY_RESPONSE
- ONE_WORD_RESPONSE
- VERY_SHORT_FRAGMENT
- EXCESSIVE_LENGTH
- PLACEHOLDER_LEAK
- TRANSLATION_KEY_LEAK
- MISSING_REQUIRED_ARGUMENT
- DUPLICATE_RENDERED_TEXT
- REPEATED_RECENT_TEXT
- UNSUPPORTED_FAMILY_REFERENCE
- RELATIONSHIP_TERM_WITHOUT_BOND
- IDENTITY_TERM_WITHOUT_KNOWLEDGE
- PERSPECTIVE_SUSPECT
- PUNCTUATION_OR_FRAGMENT_SUSPECT
- GENERIC_ACKNOWLEDGEMENT_SUSPECT

Flags must be labeled as definite, suspect, or review according to evidentiary strength. A heuristic must never silently become gameplay truth.

## Perspective checks

Use semantic actor/referent/subject information when available. Do not infer perspective only from pronoun regexes.

A perspective candidate should capture:

- speaker;
- listener/target;
- semantic subject/possessor;
- rendered pronouns/reference terms;
- reason for suspicion.

If the semantic frame does not provide enough evidence, mark review-needed rather than asserting an error.

## Relationship/family checks

The phrase family is not inherently invalid. It becomes suspicious when:

- a family/intimacy address or relationship term appears;
- the bounded bond/relationship context does not support it;
- the semantic variant/phrase does not otherwise justify it.

The analyzer should expose familyAddress, bond kind/class and semantic source so the defect can be fixed at the right layer.

## Dialogue-quality review rubric

Deterministic execution evidence and subjective prose review are separate.

LLM/human review may score or label:

- naturalness;
- grammatical completeness;
- specificity vs canned/generic wording;
- character/persona fit;
- relationship fit;
- situational grounding;
- post-apocalyptic/survival-world fit;
- melodrama/profanity excess;
- wrong perspective or agency;
- repetition across equivalent contexts.

The runtime must not require an LLM. See QUALITY_RUBRIC.md.

## Clustering

Cluster rows by canonical cause rather than only visible text. Useful keys include:

- canonical content owner + semantic variant/phrase;
- response pool + realization family;
- quality flag signature;
- normalized parameter region;
- identical rendered text across many semantic variants.

Cluster output must include representative examples and affected counts/context ranges. A single canonical content defect should be repairable once rather than prompting dozens of independent edits.

## LLM review bundles

A review bundle should be bounded and token-efficient:

- cluster summary;
- canonical source IDs;
- 3–10 representative bad outputs;
- parameter/context deltas;
- exact semantic/realization path;
- quality flags;
- nearby contrasting good examples where useful;
- affected row/case IDs for targeted replay.

Do not send thousands of full traces to the model.

## GUI ownership

Add Quality Sweep to existing **Simulation**. It may provide:

- scope/strategy selection;
- plan estimate;
- batch progress;
- filters/severity/cluster views;
- compact evidence detail;
- open full Conversation Inspector;
- open/locate canonical content source when verified;
- rerun selected/affected cases.

Studio remains source/content/review authoring according to the existing Observatory architecture. Do not recreate a Studio Test Lab or Coverage runner.

## Safety and performance

- Production Lua always decides semantic behavior.
- Preview/planning is side-effect-free.
- Sweep execution uses disposable fixture workers and never source saves unless a separately explicit read-only source-backed acceptance case requires it.
- No per-frame or runtime NPC scanning.
- No unbounded catalog/startup payload.
- No committed giant snapshots.
- No native PZ or runtime LLM requirement.
