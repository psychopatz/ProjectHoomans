# Portable PSDL / ConvoEngine Portability Closure

**Status:** IN PROGRESS — G8R7 portability closure.

## Parent objective

Finish the remaining portability boundary so ConvoEngine selects backends from target descriptors and proves the same Portable Dialogue Plan behaves equivalently in the reference runtime and generated Project Zomboid Lua runtime.

```text
compact PSDL
→ canonical Semantic Dialogue IR
→ Portable Dialogue Plan
→ descriptor-selected backend
→ generated runtime
→ typed game capability adapter
```

## Accepted baseline

Already verified and no longer active work:
- all 577 production semantic families use compact `psychopatz.psdl.v2`;
- production package/provenance data exists;
- production compilation lowers through `compile_portable_plan()`;
- PZ generated output is rendered from the portable plan;
- profanity recognition is source/generated rather than handwritten registration;
- camp uses a typed capability boundary;
- current PZ owner/output routing is descriptor-driven;
- synthetic adopter routing through the normal generator works;
- isolated committed-vector canonical check, deterministic rebuild, and naming/sharding audit pass.

Git history is the archive for those completed changes.

## Remaining closure

Only four concerns remain:
1. backend selection is still hard-coded to `pz-lua` in the generic compiler path;
2. G8R5 compares the Reference VM with PZ projection tables, not an executed Lua/PZ semantic trace;
3. normalized lineage reports the canonical schema as if it were the authored source schema;
4. final ROADMAP/PROGRESS/HANDOFF committed closure is inconsistent.

## Minimal read order

1. root `AGENTS.md`
2. `PROGRESS.md`
3. `HANDOFF.md`
4. active `ROADMAP.md`
5. `ARCHITECTURE.md` when modifying backend/runtime contracts
6. `HARNESS_ACCEPTANCE.md` before closure
