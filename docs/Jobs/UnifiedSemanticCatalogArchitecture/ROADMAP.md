# Unified Semantic Catalog Architecture Roadmap

## Objective

Maintain one scalable, mod-agnostic semantic CodeBuilder system owned by
PsychopatzCore. Project Hoomans, Dynamic Trading, and future expansion packs
consume the same typed source graph, ownership model, identity derivation,
and runtime-locale contracts.

## Completion gates

- Core is the only semantic harness and CodeBuilder authority.
- Every normal shard has a unique `shardId`, explicit owner, typed kind, and
  bounded domain scope.
- Recipes keep locale text beside the authored record; generated translations
  remain package-owned runtime artifacts.
- Runtime identity and translation keys are compiler-derived from semantic
  template IDs, styles, and append-only phrase order.
- No authoring translation catalog, copied harness, or compatibility shim is
  required by any participating mod.
- Bundle recipes are indexed, sharded, owner-validated, and rendered only to
  the package that owns them.
- PNC-only, PNC + Dynamic Trading, DTAbstract, DTHoomans, and future provider
  compositions can be resolved without a second semantic implementation.

## Phases

### P0 — Contract inventory

Freeze record inventories, define the typed shard contract, and add structural
validation without changing runtime output.

### P1 — Self-contained recipes

Inline authored locale maps, derive compiler identities, migrate bundle text,
and remove the authoring catalog seam while preserving generated output.

### P2 — Nested source sharding

Split oversized conversation content by semantic domain and use recursive Core
source roots. Split bundle recipes behind an explicit auxiliary index while
preserving IDs, owners, runtime paths, and locale output.

### P3 — Compiler health

Keep manifest loading, typed validation, assembly, rendering, discovery,
health, registry serialization, and package routing as focused Core modules.

### P4 — Runtime consumer migration

Ensure Project Hoomans and Dynamic Trading consume only Core-generated semantic
artifacts and provider-owned external shards.

### P5 — Composition acceptance

Validate PNC-only, all-enabled, DTAbstract, DTHoomans, and future-provider
manifest compositions with focused tests and real compiler builds.

## Current status

P0 through P2 are implemented for the current Conversation source inventory.
The current handoff records exact commits, test evidence, preserved unrelated
dirty work, and the two known unrelated PNC smoke failures.
