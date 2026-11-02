# Architecture — Semantic Exhaustive Dialogue Quality Sweep

## Product contract

The Quality Sweep is a **sentence generation and review pipeline** backed by production Lua.

~~~text
production surfaces + response registry + context controls
                        |
                        v
                Coverage / Variant Planner
                        |
                        v
               bounded production-Lua cases
                        |
                        v
                 rendered NPC sentences
                        |
                        v
          compact trigger/context/provenance rows
                        |
              +---------+----------+
              |                    |
              v                    v
       quality analysis       lazy deep inspection
              |                    |
              +---------+----------+
                        v
               Sentence Review GUI
~~~

The human-facing goal is not to expose every internal planner object. It is to make produced sentences easy to inspect.

## Authority

### Production Lua

Owns:

- semantic interpretation;
- response eligibility;
- response selection;
- flow behavior;
- relationship/gameplay authority;
- speech realization;
- final rendered response behavior.

Python must not reproduce these decisions.

### Sweep services

May own:

- production surface discovery;
- context/dimension normalization;
- bounded coverage planning;
- variant-frontier targeting;
- batch/resume mechanics;
- compact evidence projection;
- quality heuristics;
- clustering and review bundles.

### Quality Sweep GUI

Owns presentation of:

- rendered NPC sentences;
- human-readable trigger;
- compact context;
- quality flags;
- selected-line details.

Coverage/reachability mechanics remain secondary developer information.

## Sentence evidence contract

One evidence row corresponds to one rendered NPC sentence.

It should contain:

### User-visible core

- final rendered sentence;
- human-readable player/menu trigger;
- language;
- compact relationship/bond summary;
- compact persona/style/trait summary;
- relevant needs/health/behavior summary;
- quality flags;
- canonical source owner when known.

### Deep evidence

- planned and reached surface;
- semantic intent/subject/speech act;
- semantic template/variant;
- realization family/variant;
- phrase ID;
- translation key;
- selection provenance;
- authority/effect summary;
- deterministic case ID;
- source/catalog/repository fingerprints where available.

The GUI should show the first group by default and reveal the deep group only on selection or Advanced inspection.

## Surface discovery

The service must prefer live production discovery when no explicit surface scope is supplied.

Normal review excludes expected fallback probes unless explicitly requested.

Surface discovery may include:

- root/menu/landing choices;
- companion-order affordances;
- canonical typed utterance probes;
- later, active-flow/generated response affordances where safely enumerable.

Hard-coded surface adapters may exist only when backed by tests and must not silently replace production discovery.

## Balanced sentence generation

A bounded review cannot execute every possible combination.

The planner should therefore maximize **useful sentence diversity** rather than raw case count.

Requirements:

1. seed every selected surface;
2. distribute context variation across all selected surfaces;
3. avoid consuming the case cap on early surfaces;
4. include relationship/persona/need boundary variation;
5. include pairwise/context interactions where useful;
6. progressively target unobserved response variants.

The planner must report honest truncation and uncovered frontier state.

## Variant frontier

The response registry is the long-term guide for “all possible sentences.”

The system should:

1. enumerate the full paginated response pool/variant registry;
2. mark which variants have been observed in real executions;
3. use production explain evidence for unobserved variants;
4. identify relevant context dimensions/buckets;
5. generate bounded targeted cases;
6. rerun production Lua;
7. stop when selected, proven ineligible under tested contexts, or bounded search budget is exhausted.

Python may choose candidate contexts, but production explain/selection remains authority.

## Quality analysis

Two levels:

### Per-row

- empty/fragment;
- one-word suspect;
- placeholder/translation leak;
- unsupported family/intimacy term;
- identity/privacy misuse;
- perspective suspicion;
- generic acknowledgement.

### Cross-row

- duplicate rendered text;
- repeated response;
- variant collapse;
- fallback saturation;
- generic-response concentration.

Quality heuristics must never prevent rows from being displayed. Analyzer failure must not blank the sentence table.

## Full Inspector

Deep inspection must replay the **exact selected sentence**:

- original `identity.input`;
- language;
- scenario parameter vector;
- compatible production context/fingerprint.

A wellbeing sentence must not reopen as a greeting or unrelated turn.

## GUI architecture

The default Quality Sweep page is sentence-first.

Primary controls:

- Generate Sentences
- Stop
- Languages
- Max examples
- Reload Results
- Advanced…

Primary table:

- NPC Sentence
- Trigger
- Context
- Lang
- Quality / Problem
- Source

Advanced developer controls may expose strategy, sweep ID, batch size, registry/reachability diagnostics and exports.

Do not restore coverage/batch/reachability tabs as the default user experience.

## Threading

Sentence generation and advanced reachability work must execute off the Tk event thread.

The background worker must not mutate widgets.

Use queue/event marshaling back to Tk via `after()`.

Evidence should become visible as batches complete.

## Safety

- no source-save mutation;
- no native PZ dependency for developer acceptance;
- no giant committed outputs;
- no runtime LLM requirement;
- no semantics rewritten in Python;
- no automatic gameplay behavior changes from prose-quality judgments.
