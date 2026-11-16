# Harness Acceptance — G8R7 Portability Closure

## Backend dispatch

Use the normal production compiler.

Require:
- current PZ target selects `pz-lua` through descriptors;
- a non-PZ test/reference backend selects through the same dispatcher;
- unknown backend fails closed;
- incompatible mixed-backend target sets fail closed;
- adding the test backend requires no conditional in generic conversation compilation.

## Executed trace equivalence

Use real production portable plans and execute both sides.

Reference side: `PortableReferenceVM`.
PZ side: existing Lua ConvoProbe / `simulate_convo_engine_family()` infrastructure, adapted as needed to consume the generated portable-plan-derived PZ runtime plan.

Cover exact recognition, fuzzy recognition, fuzzy mutating confirmation, profanity, beat + behavior, camp result branch, and a deterministic realization case.

Normalize traces before comparison. Projection/table membership is not sufficient.

## Lineage

For compact production source assert:
- authored schema is `psychopatz.psdl.v2`;
- canonical schema/version is separately represented;
- source path points to authored file;
- diagnostics remain source-lineage-aware.

## Final committed-vector acceptance

From an isolated final participant vector:
- canonical check clean before apply;
- focused G8R7 tests pass;
- production G8R suite passes;
- lifecycle tests pass;
- naming/sharding determinism passes;
- generated-output deletion/rebuild recreates all ledger-owned outputs;
- second apply is a no-op;
- final check clean;
- ROADMAP/PROGRESS/HANDOFF all say COMPLETE.

## Evidence rule

Data-driven owner routing does not prove backend portability; backend implementation selection must also be descriptor-driven.

Generated PZ definitions containing matching IDs do not prove runtime equivalence; execute both runtimes.
