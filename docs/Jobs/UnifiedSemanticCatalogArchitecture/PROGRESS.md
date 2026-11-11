# Unified Semantic Catalog Progress

**Status:** implemented in participant repositories; primary handoff pending

**Primary repository:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`

**Participants:** PsychopatzCore, DynamicTrading

## Completed in this phase

- Core remains the only semantic CodeBuilder authority.
- Conversation authoring records keep their locale text beside the recipe.
- UI suggestions use inline `display` maps; label and utterance keys are
  compiler-derived from the namespace and authored ID.
- UI text-only suggestions migrated from the deleted PNC runtime catalog into
  Core-owned self-contained shards.
- Realization constructions now use one `construction.social.*` source record
  with a locale `translations` map. The compiler still emits the established
  `construction.en.*` and `construction.tl.*` runtime IDs.
- Locale-split realization filenames and the PNC `Suggestions.json` runtime
  catalog were removed; no compatibility bridge was added.
- Dynamic Trading now owns an optional UI shard and a provider-local manifest,
  while Core composes it into the same graph for all-enabled builds.
- PNC direct UI output is filtered to Core + Project Hoomans owners, so DT
  suggestions are not loaded into a PNC-only runtime.
- The affected ownership/provenance tests were updated to the manifest/profile
  ownership contract rather than the removed inline `source` envelope.

## Verification

- Core CodeBuilder tests: **85/85 passed**.
- Dynamic Trading tests: **88/88 passed**.
- PNC focused semantic, ownership, and realization tests: **28/28 passed**.
- PNC full runner: **2/1018 failures**, both existing runtime smoke failures
  outside this source migration (`pnc_population_director_smoke.lua` and the
  custom translation-manager smoke assertion).
- PNC-only build: **290 generated files**, 505 phrase families, 56 patterns,
  13 UI definitions.
- All-enabled build: **302 generated files**, 505 phrase families, 56 patterns,
  21 UI definitions.
- Source audit: zero legacy authoring fields, zero locale-split filenames,
  zero hard-size violations, with three existing preferred-size warnings for
  large content shards.

## Remaining work

- Split the three preferred-size content shards by semantic domain without
  changing runtime IDs or translation output.
- Re-run the full PNC suite after the unrelated smoke failures are separately
  resolved.
- Keep future expansion packs on the provider-local manifest plus Core
  external-shard contract; do not add another harness or runtime catalog.
