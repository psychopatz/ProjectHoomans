# Architecture — Portable PSDL / ConvoEngine

## Production authority

```text
compact PSDL
→ canonical Semantic Dialogue IR
→ Portable Dialogue Plan
→ descriptor-selected backend
→ generated runtime
→ typed game capability adapter
```

There is one portable semantic-plan authority and one backend-dispatch authority.

## Backend contract

Generic compiler code may compile/link portable plans and resolve target descriptors, but must not hard-code a backend renderer.

Backends are selected by descriptor identity:

```text
backend ID
→ registered backend implementation
→ validate target context
→ render portable plan
```

Unknown backends and incompatible mixed-backend targets fail closed.

`pz-lua` remains the production PZ backend. Future backends plug into the same dispatch contract.

## Trace conformance contract

Reference and target runtimes are compared through a normalized semantic trace, not implementation data structures.

Stable trace semantics include recognition identity/mode/confidence class, confirmation requirement, selected beat/behavior/dialogue, action/result outcome, reply branch, and realization/template identity where deterministic.

Lua ConvoProbe is the preferred PZ-side developer acceptance runtime because it executes generated Lua without requiring native game launch.

## Source lineage

Lineage distinguishes authored representation from normalized/canonical representation.

Compact records expose authored schema/path and canonical IR schema/version separately. Do not label canonical schema as authored source schema.

## Logic ownership

```text
portable declaration → PSDL source
portable reusable algorithm → versioned standard runtime
game/engine implementation → typed capability adapter
backend rendering → descriptor-selected backend
```

## Naming/sharding invariants

Preserve stable semantic IDs/realization handles, named outcomes, coherent family sharding, lowercase semantic source names, deterministic source-lineage-aware generated chunking, valid desired hash shards, `catalog_naming.py` as naming authority, and no manual generated-file moves.

Do not introduce arbitrary `PartNN`, phrase-per-file/migration-history trees, or revive `psdl.*`, `pnc.psdl.*`, or `Conversation/Text/psdl/` runtime identities.

## Rebuild invariant

Given only toolchain + compact packages + standard runtime + target/backend descriptors + capability adapters, a clean output directory recreates all reusable dialogue runtime artifacts deterministically.
