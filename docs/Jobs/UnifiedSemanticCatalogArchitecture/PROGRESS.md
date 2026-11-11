# Unified Semantic Catalog Progress

**Status:** IN_PROGRESS  
**Primary repository:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`  
**Participants:** PsychopatzCore, DynamicTrading  
**Current phase:** P1 — Canonical locale catalogs  
**Accepted slices:** P0A, P0B, P1A — Catalog materialization, P1B — Catalog-backed source migration  
**Next chunk:** Make canonical source compilation catalog-only, remove remaining inline-translation acceptance paths, and add strict source-contract checks.

## Verified baseline

- Core CodeBuilder contains 122 semantic source JSON files plus its manifest.
- Project Hoomans currently generates 30 Conversation translation JSON files per locale.
- Project Hoomans still has runtime references to `media/conversation/...`.
- Dynamic Trading contributes an external trading pack through the shared CodeBuilder graph.
- Existing unrelated dirty work in all three repositories is preserved.

## Accepted P1B

- Added catalog-backed compiler hydration for content, player choices, UI suggestions, dialogue responses, and semantic-flow responses.
- Added a one-shot migration tool and removed 6,946 inline locale fields from 91 Core semantic source files.
- The canonical source tree now has zero inline `translations`, `labelTranslations`, or `choiceTranslations` fields outside the locale catalogs.
- The Git-baseline parity check reports equal model fingerprints and byte-identical rendered runtime plans: 157 modules before and after migration.
- Focused and full Core semantic-harness tests ran with 80 tests passing.
- Current compilation resolves EN/TL, 123 shards, 157 rendered modules, and context health passes with 20 warnings and 0 errors.

## Not yet accepted

- The compiler still contains transitional acceptance of inline wording for unconverted external/fixture sources.
- The PNC legacy `common/media/conversation` tree has not yet been migrated or removed.
- Shard ownership, repeated metadata, naming collisions, and oversized domain shards remain P2 work.
- No compatibility shim is authorized for the final state.
