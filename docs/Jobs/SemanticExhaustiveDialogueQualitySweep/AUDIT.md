# Audit — Semantic Exhaustive Dialogue Quality Sweep

## Audited repository state

Audit basis: local ProjectHoomans main at 3b597b97273f91d819127c76f3cd8f29de110719.

At planning time the worktree was clean. After an explicit fetch, local main was **17 commits ahead of origin/main and 0 behind**. This job must preserve that unpublished local history and must not reset/rebase/overwrite it.

No production code, save, native Project Zomboid runtime or Workshop publication was modified during this audit.

## Verified existing foundation

### 1. Canonical Semantic Test Subsystem already exists

tools/semantic_harness/testing/ owns the reusable JSON fixture schema, projection, comparator, loader, executor, CLI and linting. Its completed job records production-worker execution and broad fixture migration. This new goal must extend it rather than create another harness.

The generic matrix schema already supports deterministic expansion and rejects expansion above MAX_MATRIX_EXPANSIONS = 64 for one declared fixture case.

loader.py already supports direct injection of language, weather, arbitrary scenario.* paths, and preserves other matrix values under scenario.matrix.

### 2. Response Observatory already executes real production Lua

tools/semantic_harness/inspection/response_observatory.py runs isolated cases through LuaSemanticWorker and joins the Conversation Inspector. Its current quality-matrix contract is intentionally small:

- MAX_CASES = 8
- MAX_UTTERANCES = 4

It reports final response keys/text, semantic response keys, effects, command/transport outcome, translation fallback evidence and PASS/FAIL/OBSERVED state.

This is a bounded acceptance utility, not yet a broad dialogue-quality exploration engine.

### 3. Input fuzzing exists but solves a different problem

tools/semantic_harness/testing/conversation_fuzz.py is a bounded real-worker input mutation matrix (MAX_CASES = 32) focused on NLU robustness such as compact profanity, typos, punctuation and unsafe item fuzziness.

It does not enumerate response/persona/relationship state space or perform prose-quality review.

### 4. Production-backed context dimensions are already discoverable

The worker Simulation control catalog exposes real controls rather than requiring a new hard-coded test vocabulary. Verified examples include:

- player and NPC hunger, thirst, fatigue, stress, boredom and panic;
- NPC traits and generated-personality override mode;
- production social-style enum and numeric personality dimensions;
- relationship approval, respect, familiarity, identity trust and derived relationship state;
- durable bond kind;
- actor authority flags;
- health/current behavior and other scenario fields already present in the runtime scenario.

The default scenario already carries distinct player/NPC needs, NPC health/body state, active behavior, identity/archetype/traits, relationship state and actor authority.

### 5. Existing inspectors already expose much of the required “why”

conversation_inspector_persona.py already exposes:

- semanticTemplateID
- renderTemplateID
- realizationFamily
- realizationVariant
- fallbackReason
- translationKey
- familyAddress
- durable bond context
- bounded semantic frame
- speech-style and actor conversation context

response_turn_trace.py already exposes:

- final rendered text
- semantic variant ID
- phrase ID
- translation key
- exact selected registered variant when verifiable
- registered variant matches and selection provenance
- bounded translation and effect/authority evidence

The missing work is orchestration and aggregation, not raw observability from scratch.

## Verified gaps

The current system does **not** yet provide:

1. automatic discovery and normalization of all sweep-worthy context dimensions;
2. semantic bucket policies for numeric controls/thresholds;
3. pairwise/boundary/persona/full-bounded coverage planning;
4. automated variant-selection reachability exploration;
5. large-run deterministic batching/resume over the existing <=64 case safety boundary;
6. a compact per-rendered-sentence evidence schema designed for tens of thousands of rows;
7. lazy rerun/full-inspector expansion from a compact row;
8. systematic dialogue-quality flags for fragments, unsupported relationship/family terms, perspective suspicion, placeholder/key leaks, repetition and generic/robotic wording;
9. clustering of many bad executions back to one canonical response/phrase/source defect;
10. LLM-oriented bounded review bundles and affected-case rerun;
11. a single existing-Simulation GUI surface for planning/running/filtering these sweeps.

## Main design risk: combinatorial explosion

A literal Cartesian product of every trait, personality slider, relationship metric, need, health value, language, flow and response is neither useful nor bounded. Numeric sliders alone make an exhaustive product effectively unbounded.

The required interpretation of “all possible combinations” is therefore:

> Systematically cover all **declared semantic buckets, boundaries, registered variants/surfaces and meaningful interactions between dimensions**, using deterministic coverage strategies and bounded restartable batches, while clearly reporting what was and was not covered.

The system must never label a variant globally unreachable merely because it was not selected in a finite tested matrix.

## Quality risk: false mechanical judgments

Natural dialogue cannot be fully judged by string rules. Deterministic checks should identify high-confidence defects or review candidates; subjective properties such as post-apocalyptic enough, bland, robotic, voice mismatch or subtle perspective error remain LLM/human review categories unless production semantics prove them.

The “family” example is especially useful as a target class: the harness should surface a one-word family/intimacy response, show familyAddress/bond/semantic context, and flag unsupported family/relationship use when context does not justify it. It should not hard-code that exact text as the only defect.

## Recommendation

Build one **Dialogue Quality Sweep** orchestration layer on top of the completed Test Subsystem + Observatory:

discover → plan → deterministic batches → production Lua → compact evidence → quality flags → canonical-source clusters → bounded LLM review → affected rerun → regression.

Do not redesign the semantic architecture to accomplish this.
