# Unified Semantic Catalog Architecture

## Objective

Create one scalable, mod-agnostic semantic CodeBuilder system owned by
PsychopatzCore. Semantic shards remain typed and domain-oriented, every shard
has explicit ownership and stable identity, and CodeBuilder translations are
stored as one complete JSON catalog per locale. Project Hoomans, Dynamic
Trading, and future expansion packs use the same compiler and contracts.

## Completion gates

- Core is the only semantic harness and CodeBuilder authority.
- Every semantic shard has a unique `shardId`, explicit `owner`, typed `kind`,
  and bounded domain scope.
- Semantic shards contain stable translation keys rather than inline locale
  maps.
- CodeBuilder has exactly one authoring catalog per locale (`EN.json`,
  `TL.json`, and future locale files).
- Locale catalogs have deterministic key, placeholder, and fallback checks.
- Source and generated shard budgets include translation outputs.
- Core-only, Project Hoomans, Project Hoomans + Dynamic Trading, DTAbstract,
  DTHoomans, and expansion-pack compositions compile independently.
- All runtime consumers are updated and the old PNC conversation tree is
  removed only after its references reach zero. No permanent compatibility
  shim remains.

## Phases

### P0 — Contract and inventory

Freeze the current record and translation-key inventory, define the v2 shard
and locale schemas, and add structural validation without changing runtime
output.

### P1 — Canonical locale catalogs

Create one CodeBuilder locale catalog per language, migrate inline translations
to stable keys, preserve key identity, and validate locale parity,
placeholders, duplicates, and fallback behavior.

### P2 — Semantic shard normalization

Split oversized or cross-domain shards, remove duplicate source metadata,
resolve naming collisions, normalize kind/path terminology, and require
explicit ownership in the manifest.

### P3 — Compiler modularization and output health

Separate manifest loading, schema validation, merge/index construction,
translation catalogs, output routing, rendering, and health checks. Add
translation-size and generated-manifest parity checks.

### P4 — Runtime migration and legacy removal

Update PNC runtime consumers and migrate the old `common/media/conversation`
assets. Remove the legacy tree and any temporary conversion-only reader after
all call sites are updated.

### P5 — Cross-mod acceptance

Regenerate and test all supported mod compositions, update documentation, and
close the goal only after deterministic output and focused/full test gates
pass.
