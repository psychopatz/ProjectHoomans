# Unified Semantic Catalog Progress

**Status:** IN_PROGRESS  
**Primary repository:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`  
**Participants:** PsychopatzCore, DynamicTrading  
**Current phase:** P0 — Contract and inventory  
**Accepted slice:** P0A — Read-only catalog audit seam  
**Next chunk:** Freeze the current record and translation-key inventory, then
add strict v2 shard and locale-catalog validation without rewriting existing
files.

## Verified baseline

- Core CodeBuilder contains 122 conversation source JSON files plus its
  manifest.
- The largest source shards exceed the preferred 64 KiB budget.
- Project Hoomans currently generates 30 Conversation translation JSON files
  per locale, including files above the current generated-size budget.
- Project Hoomans still has runtime references to `media/conversation/...`.
- Dynamic Trading contributes an external trading pack through the shared
  CodeBuilder graph.
- Existing unrelated dirty work in all three repositories is preserved.

## Accepted P0A

- Added Core `catalog_audit.py`, a deterministic read-only audit for semantic
  source trees.
- Added focused tests and exported the audit through the Core CodeBuilder
  package.
- The audit ran against Core, the Dynamic Trading external pack, and the
  Project Hoomans legacy conversation tree without writing to any of them.
- Core audit result: 122 source JSON files, 91 with inline translations, 122
  with repeated source metadata, 3 over the preferred source budget, and no
  locale catalog directory.
- The existing Core semantic-harness suite ran with 69 tests passing.
- The merged Core + Project Hoomans + Dynamic Trading compiler still produced
  EN/TL output and passed context health with 20 warnings and 0 errors.

## Not yet accepted

- Strict v2 shard and locale-catalog validation has not been implemented yet.
- No source or runtime files have been migrated.
- No compatibility shim is authorized for the final state.
