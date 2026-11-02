# Semantic Exhaustive Dialogue Quality Sweep

## Parent objective

Make the Semantic Harness generate a broad, production-faithful set of NPC sentences across meaningful semantic triggers and runtime contexts, then present those sentences in a simple review workflow so a human or LLM can quickly find awkward, robotic, repetitive, contextually wrong, relationship-inappropriate, or wrong-perspective dialogue and trace each line back to what produced it.

The primary product is the **sentence review experience**, not a coverage dashboard.

The harness should answer three questions clearly:

1. **What sentence did the NPC say?**
2. **What player/menu trigger and context caused it?**
3. **Which semantic/realization/source path produced it?**

This job extends the existing Semantic Test Subsystem and Semantic Observatory. It must not create a second semantic runner, selector, registry, scenario engine, GUI application, or authoring database.

## Current user workflow

Normal Quality Sweep usage should be:

`Generate Sentences → scan NPC lines → filter suspicious/repeated lines → click a line → inspect trigger/context/semantic path`.

The user should not need to understand smoke/full/pairwise/reachability/batch mechanics for ordinary dialogue review.

Engine/testing mechanics belong under **Advanced…**.

## Desired end-state

A developer or agent can:

1. discover current production interaction surfaces, response pools, variants, persona/relationship controls and other meaningful dialogue context dimensions;
2. generate bounded but broad sentence coverage across those surfaces and contexts;
3. progressively target response variants that have not yet been observed;
4. show one row for every rendered NPC sentence;
5. display the human-readable trigger that caused each sentence;
6. display compact relationship/persona/state context for each sentence;
7. show quality flags such as fragments, unsupported intimacy/family language, perspective errors, generic acknowledgements, duplicates and repeated/fallback saturation;
8. open deeper semantic/realization/source provenance only when needed;
9. rerun affected cases after a dialogue fix;
10. export bounded evidence/review bundles for LLM-assisted dialogue improvement.

## UX ownership

- **Simulation** — one live scenario/conversation and immediate debugging.
- **Quality Sweep** — broad sentence generation and dialogue-quality review.
- **Studio** — canonical dialogue/source authoring.

Quality Sweep is a first-class harness page, but it remains a client of the same production Lua worker and sweep services.

## Existing systems to reuse

- `tools/semantic_harness/testing/` for execution, matrix and sweep services.
- `tools/semantic_harness/runtime/worker.py` for authoritative production Lua behavior.
- Response Observatory and Conversation Inspector for runtime evidence/provenance.
- Simulation/persona control catalogs for production-backed context dimensions.
- Response-pool and variant inspection APIs for frontier coverage.
- CodeBuilder / Dialogue Content / source-lineage infrastructure for canonical ownership.

## Documents

Read after root `AGENTS.md` in this order:

1. `AGENT_RUNBOOK.md`
2. `ARCHITECTURE.md`
3. `GUI_WORKBENCH.md`
4. `QUALITY_RUBRIC.md`
5. `HARNESS_ACCEPTANCE.md`
6. `ROADMAP.md`
7. `AUDIT.md`
8. `PROGRESS.md` **last**

`PROGRESS.md` is current truth and defines the immediate Next Chunk.

## Non-goals

- No runtime cloud/LLM dependency in Project Zomboid.
- No Python reimplementation of semantic selection, policy or realization.
- No mathematically unbounded Cartesian product.
- No giant committed trace snapshots.
- No duplicate Studio testing/coverage application.
- No requirement that dialogue becomes profanity-heavy or melodramatic to sound post-apocalyptic.
- No automatic gameplay-authority changes merely because wording is judged poor.
- No native PZ launch, save mutation or Workshop publication for developer-side acceptance.
