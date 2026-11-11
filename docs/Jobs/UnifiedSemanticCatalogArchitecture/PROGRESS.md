# Unified Semantic Catalog Progress

**Status:** IN_PROGRESS  
**Primary repository:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`  
**Participants:** PsychopatzCore, DynamicTrading  
**Current phase:** P3 — Compiler modularization  
**Accepted slices:** P0A, P0B, P1A, P1B, P1C, P2A, P2B, P3A, P3B, P3C, P3D, P3E  
**Next chunk:** P4 — migrate runtime consumers from the legacy conversation tree to Core-generated semantic artifacts.

## Verified baseline

- Core CodeBuilder contains 122 canonical semantic source shards plus its manifest.
- Project Hoomans still has the legacy runtime `media/conversation/...` tree; that is a later P4 migration.
- Dynamic Trading contributes an external trading pack through the shared Core CodeBuilder graph.
- Existing unrelated dirty work in all three repositories is preserved.

## Accepted P1C — catalog-only source contract

- Canonical shards reject inline `translations`, `labelTranslations`, `choiceTranslations`, `fallback`, `labelFallback`, and `utteranceFallback` fields.
- Compiler hydration supplies wording from the complete locale catalogs.
- EN and TL catalogs contain 7,033 entries each; 27 TL entries are explicitly marked as English fallback pending translation.
- The committed-source fallback-removal parity check produced an equal model fingerprint and byte-identical 157-module runtime plan.
- Core semantic-harness tests passed: 80 tests.

## Accepted P2A — explicit shard envelope and provenance

- All 122 Core source shards and the DT external pack use `psychopatz.semantic.shard.v2`.
- Every shard has a deterministic `shardId`, explicit `owner`, and `sourceProfile`.
- Repeated source/license metadata moved into 23 manifest-owned `sourceProfiles`; it is reconstructed only in compiler memory for existing domain validators.
- Manifest explicit shards and source roots declare ownership; external mounts declare shard and profile identities.
- The one-shot migration is dry-run safe, has a real no-write test, and is not a runtime compatibility shim.
- Strict shard validation reports zero diagnostics across the Core shards and DT pack.
- Core + DT compiles to 123 shards, 703 records, and 157 modules; context health passes with 0 hard errors and 20 advisory warnings.
- A reconstructed pre-migration Git tree produces the same model fingerprint and byte-identical runtime plan.
- Core semantic-harness tests passed: 84 tests.

## Accepted P2B — normalized paths and generated names

- Duplicate filename stems were removed with descriptive, domain-oriented names.
- Response shards moved from `flows/` into `responses/`; semantic flow shards remain under `flows/`.
- `responses` is a first-class source root for generated module naming, so it does not produce `Responses/Responses/...` paths.
- Translation `sourceShard` metadata resolves through stable shard IDs, so physical path renames do not change semantic catalog identity.
- The catalog audit reports zero issues across 122 shards: no inline wording, repeated source metadata, duplicate stems, path-kind mismatches, or budget violations.
- Runtime artifacts were regenerated; stale generated names are gone and new registry references resolve.
- The focused Core semantic-harness suite passed: 87 tests.

## Accepted P3A — manifest, validation, and catalog boundaries

- Manifest parsing, path safety, source-root discovery, and external-pack mounting now live in `conversation_manifest.py`.
- Shard-local validation and director/realization merge rules now live in `conversation_validation.py`.
- Locale-key hydration and inline-translation rejection now live in `conversation_catalog.py`.
- The compiler remains the orchestration/public API hub; no compatibility shim or duplicate loader was added.
- Core tests passed: 89 tests; the real Core → Project Hoomans → Dynamic Trading build remained at 205 generated files, 505 phrase families, 56 patterns, and 13 UI definitions.

## Accepted P3B–P3E — bounded compiler modules

- Rendering/chunking, discovery/indexing, shared contracts/limits, health checks, registry serialization, and shard assembly now have dedicated modules.
- `conversation_compiler.py` remains the public orchestration hub and is reduced to 814 lines; existing service/build/inspection imports continue through direct module ownership.
- No generated Lua artifacts changed during the refactor; every real build produced 205 generated files, 505 phrase families, 56 patterns, and 13 UI definitions.
- Core semantic-harness tests passed: 89 tests after each extraction gate.

## Not yet accepted

- PNC runtime consumers still reference the legacy conversation tree; removal is P4 after call-site migration.
- Core-only, PNC-only, DTAbstract, DTHoomans, and expansion-pack matrix acceptance is P5.
- No permanent compatibility shim is authorized in the final architecture.
