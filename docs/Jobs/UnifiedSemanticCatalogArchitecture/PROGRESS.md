# Unified Semantic Catalog Progress

**Status:** IN_PROGRESS  
**Primary repository:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`  
**Participants:** PsychopatzCore, DynamicTrading  
**Current phase:** P2 — Semantic shard normalization  
**Accepted slices:** P0A, P0B, P1A, P1B, P1C, P2A  
**Next chunk:** P2B — resolve duplicate stems, naming collisions, repeated metadata, and bounded domain splits without changing runtime identity.

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
- The one-shot migration is dry-run safe and has a real no-write test; it does not act as a runtime compatibility shim.
- Strict shard validation reports zero diagnostics across the 122 Core shards and DT pack.
- Core + DT composition compiles to 123 shards, 703 records, and 157 modules; context health passes with 0 hard errors and 20 advisory warnings.
- A reconstructed pre-migration Git tree produces the same model fingerprint and byte-identical runtime plan.
- Core semantic-harness tests pass: 84 tests.

## Not yet accepted

- Duplicate filename stems and broad cross-domain shards still need naming and bounded-split work in P2B.
- The compiler remains a large module; its modularization is P3.
- PNC runtime consumers still reference the legacy conversation tree; removal is P4 after call-site migration.
- Core-only, PNC-only, DTAbstract, DTHoomans, and expansion-pack matrix acceptance is P5.
- No permanent compatibility shim is authorized in the final architecture.
