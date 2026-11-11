# Unified Semantic Catalog Progress

**Status:** IN_PROGRESS  
**Primary repository:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`  
**Participants:** PsychopatzCore, DynamicTrading  
**Current phase:** P1 — Canonical locale catalogs  
**Accepted slices:** P0A, P0B, P1A — Catalog materialization  
**Next chunk:** Migrate compiler input from inline wording to the canonical locale catalogs, then prove generated-output parity before removing legacy fields.

## Verified baseline

- Core CodeBuilder contains 122 semantic source JSON files plus its manifest.
- Project Hoomans currently generates 30 Conversation translation JSON files per locale.
- Project Hoomans still has runtime references to `media/conversation/...`.
- Dynamic Trading contributes an external trading pack through the shared CodeBuilder graph.
- Existing unrelated dirty work in all three repositories is preserved.

## Accepted P0/P1 slices

- The read-only catalog audit, strict v2 contracts, and compiled-model inventory are committed.
- Core now contains one authoring catalog per discovered locale: `translations/EN.json` and `translations/TL.json`.
- Each locale catalog contains 7,006 deterministic entries and validates with exact EN/TL key parity and placeholder checks.
- Catalog metadata preserves source shard, context, and package-owner information for later migration review.
- CodeBuilder shard discovery excludes `translations/` so locale catalogs cannot be mistaken for semantic shards.
- Focused and full Core semantic-harness tests ran with 76 tests passing.
- The merged Core + Project Hoomans + Dynamic Trading compiler still resolves EN/TL, 123 shards, 157 rendered modules, and context health with 20 warnings and 0 errors.

## Not yet accepted

- The compiler still consumes legacy inline translation maps.
- Inline translation fields have not been removed from semantic shards.
- Runtime output has not yet been switched to read the new source catalogs.
- No compatibility shim is authorized for the final state.
