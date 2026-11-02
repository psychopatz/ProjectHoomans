# Semantic Exhaustive Dialogue Quality Sweep

## Parent objective

Make the existing Semantic Harness systematically exercise the production semantic/dialogue system across meaningful combinations of response surfaces and runtime context, in deterministic bounded batches, and produce compact evidence that lets a human or LLM identify bad, bland, robotic, repetitive, ungrounded, relationship-inappropriate, or wrong-perspective sentences and trace each problem back to the exact production semantic/realization/source path that produced it.

This job extends the existing **Semantic Test Subsystem** and **Semantic Observatory & Dialogue Quality Harness**. It must not create a second semantic runner, selector, registry, scenario engine, GUI application, or authoring database.

The full developer-side system is the completion boundary. A batch, phase, quality report, or one repaired line does not complete the parent goal.

## Desired end-state

A developer or agent can:

1. discover the current production response/flow/context dimensions from the live worker contracts;
2. choose a bounded coverage strategy such as smoke, boundary, pairwise, variant reachability, persona/relationship, or full-bounded;
3. plan deterministic cases and execute them in restartable batches through actual production Lua;
4. inspect one compact evidence row for every rendered NPC sentence, including the parameters that triggered it;
5. see exact semantic template/variant, realization family/variant, phrase/translation identity, selection provenance, relationship/persona context, and canonical source lineage where verified;
6. filter and cluster likely defects such as one-word fragments, unsupported family/intimacy terms, wrong perspective, placeholder leaks, repetitive/generic wording, and tone/voice mismatches;
7. export bounded JSONL/cluster bundles suitable for LLM review without dumping full inspector traces;
8. rerun only affected clusters/cases after a content fix, then run broader regression;
9. use the same services from headless CLI and the existing Semantic Lab **Simulation** surface.

## Existing systems to reuse

- tools/semantic_harness/testing/ for fixture schema, deterministic matrix expansion, execution and assertions.
- tools/semantic_harness/runtime/worker.py plus production Lua worker for authoritative runtime behavior.
- tools/semantic_harness/inspection/response_observatory.py and related response/source/turn inspection.
- Simulation control/persona catalogs exposed by the worker for production-backed context dimensions.
- Conversation Inspector for semantic, persona, authority, response and effect joins.
- Existing CodeBuilder/Dialogue Content/source-lineage contracts for canonical ownership.
- Existing Simulation GUI as the only execution/testing workbench.

## Documents

Read in this order after root AGENTS.md:

1. AGENT_RUNBOOK.md
2. ARCHITECTURE.md
3. QUALITY_RUBRIC.md
4. HARNESS_ACCEPTANCE.md
5. ROADMAP.md
6. AUDIT.md
7. PROGRESS.md **last**

PROGRESS.md is current execution truth. ROADMAP.md defines the full mandatory developer-side objective.

## Non-goals

- No runtime cloud/LLM dependency in Project Zomboid.
- No Python reimplementation of semantic selection, dialogue policy, relationship authority or realization.
- No brute-force unbounded Cartesian product.
- No giant committed full-trace snapshots.
- No duplicate Studio Test Lab/Coverage runner.
- No automatic gameplay-authority change merely because an LLM dislikes wording.
- No requirement that every survivor swear or use exaggerated apocalypse slang.
- No native PZ launch, source-save mutation, or Workshop publication for developer-side acceptance.
