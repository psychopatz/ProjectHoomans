# Unified Semantic Catalog Architecture

## Objective

Create one scalable, mod-agnostic semantic CodeBuilder system owned by
PsychopatzCore. Project Hoomans, Dynamic Trading, and future expansion packs
must consume the same typed shard, ownership, identity, and locale-catalog
contracts without split harnesses or permanent compatibility shims.

## Completion gates

- Core is the only semantic harness and CodeBuilder authority.
- Every shard has a unique `shardId`, explicit `owner`, typed `kind`, and
  bounded domain scope.
- Semantic sources contain stable identities and no inline locale maps.
- CodeBuilder has exactly one authoring catalog per locale (`EN.json`,
  `TL.json`, and future locale files).
- Locale catalogs pass deterministic key, placeholder, fallback, and duplicate
  key checks.
- Generated source and translation artifacts remain within context budgets.
- Core-only, PNC-only, PNC + Dynamic Trading, DTAbstract, DTHoomans, and
  expansion-pack compositions compile independently.
- All runtime consumers migrate from the old PNC conversation tree; the legacy
  tree is removed only after references reach zero.
- No permanent compatibility shim remains.

## Phases

### P0 — Contract inventory

Freeze record and translation-key inventories, define v2 contracts, and add
structural validation without changing runtime output.

### P1 — Canonical locale catalogs

Create one CodeBuilder catalog per locale, migrate inline wording using stable
keys, validate locale parity and placeholders, and preserve fallback behavior.

### P2 — Semantic shard normalization

Normalize envelopes and ownership, move repeated provenance to manifest
profiles, resolve naming collisions, and split only where domain boundaries
require it while preserving runtime identity.

### P3 — Compiler modularization and output health

Separate manifest loading, schema validation, catalog hydration, merge/index
construction, output routing, rendering, and health checks. Add generated
manifest and translation-size parity checks.

### P4 — Runtime migration and legacy removal

Update PNC runtime consumers to load the unified generated outputs, then remove
the old `common/media/conversation` tree after all call sites are migrated.

### P5 — Cross-mod acceptance

Regenerate and test every supported mod composition, update documentation, and
close the goal only after deterministic output and focused/full test gates pass.
