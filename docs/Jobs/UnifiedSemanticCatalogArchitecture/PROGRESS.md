# Unified Semantic Catalog Progress

**Status:** IN_PROGRESS  
**Primary repository:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`  
**Participants:** PsychopatzCore, DynamicTrading  
**Current phase:** P2 — Semantic shard normalization  
**Accepted slices:** P0A, P0B, P1A, P1B, P1C — Catalog-only source contract  
**Next chunk:** Normalize shard envelopes, explicit ownership, naming, repeated metadata, and bounded domain splits without changing runtime identity.

## Verified baseline

- Core CodeBuilder contains 122 semantic source JSON files plus its manifest.
- Project Hoomans currently generates 30 Conversation translation JSON files per locale.
- Project Hoomans still has runtime references to `media/conversation/...`.
- Dynamic Trading contributes an external trading pack through the shared CodeBuilder graph.
- Existing unrelated dirty work in all three repositories is preserved.

## Accepted P1C

- The compiler rejects inline `translations`, `labelTranslations`, `choiceTranslations`, `fallback`, `labelFallback`, and `utteranceFallback` fields in canonical source shards.
- Catalog hydration supplies the typed compiler with wording and EN fallbacks after source fields are removed.
- The one-shot migration removed the remaining 74 fallback fields from six source files.
- Canonical semantic source scans now find zero locale-specific wording fields outside `translations/*.json`.
- Locale catalogs contain 7,033 entries each; 27 TL entries are explicitly marked `status: fallback` pending translation.
- The committed-source parity check reports equal model fingerprints and byte-identical runtime plans after fallback removal.
- Focused and full Core semantic-harness tests ran with 80 tests passing.
- Current compilation resolves EN/TL, 123 shards, 157 rendered modules, and context health passes with 20 warnings and 0 errors.

## Not yet accepted

- Semantic shards still use the legacy `pnc.conversation.shard.v1` envelope and repeated `source` metadata.
- Many shards still have implicit manifest ownership, duplicate filename stems, or broad domain scope.
- Generated translation output is still split by owner/domain for runtime packaging; authoring catalogs are now correctly one file per locale.
- The PNC legacy `common/media/conversation` tree has not yet been migrated or removed.
- No compatibility shim is authorized for the final state.
