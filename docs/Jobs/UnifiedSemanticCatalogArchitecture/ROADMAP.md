# Unified Semantic Catalog Architecture

## Objective

Create one scalable, mod-agnostic semantic CodeBuilder system owned by
PsychopatzCore. Project Hoomans, Dynamic Trading, and future expansion packs
consume the same typed shard, ownership, identity, and runtime-locale
contracts without split harnesses or permanent compatibility shims.

## Completion gates

- Core is the only semantic harness CodeBuilder authority.
- Every shard has a unique `shardId`, explicit `owner`, typed `kind`, and
  bounded domain scope.
- Source recipes are self-contained: authored locale maps live beside the
  records they describe.
- Phrase identity and runtime translation keys are compiler-derived from the
  semantic template, style, and append-only array order.
- No Core authoring `translations/` directory, catalog hydrator, catalog
  generator, or compatibility shim remains.
- Generated EN/TL and future-locale artifacts remain package-owned under each
  mod's `common/media/translation` tree.
- Bundle recipes carry inline locale text and render to package-owned runtime
  bundle paths.
- Core-only infrastructure, PNC, PNC + Dynamic Trading, DTAbstract,
  DTHoomans, and future expansion compositions compile independently.
- No legacy runtime conversation tree remains after its references reach zero.

## Phases

### P0 — Contract inventory

Freeze record inventories, define the v3 shard contract, and add structural
validation without changing runtime output.

### P1 — Self-contained source recipes

Inline authored locale maps in typed records, derive compiler identities,
migrate bundle text, and remove the authoring catalog seam while preserving
generated runtime output.

### P2 — Semantic shard normalization

Normalize ownership, move repeated provenance into manifest profiles, resolve
naming collisions, and split only at domain boundaries while preserving
runtime identity.

### P3 — Compiler modularization and output health

Keep manifest loading, shard validation, assembly, rendering, discovery,
health, registry serialization, and package routing as focused Core modules.

### P4 — Runtime consumer migration

Migrate Project Hoomans and Dynamic Trading consumers to Core-generated
artifacts and remove duplicated semantic trees.

### P5 — Composition harness

Validate dependency-closed mod compositions, including PNC, PNC + Dynamic
Trading, DTAbstract, and future provider manifests.

### P6 — Self-contained recipe completion

The accepted implementation phase for this job removes the obsolete source
catalog reader/writer/generator, migrates all Core-owned shards and the DT
external pack to v3, keeps the editor's locale-facing view stable, and
verifies actual Core, PNC, DT, and harness execution.
