---
handoff_schema: 3
checkpoint_mode: committed_handoff
target_repo: /home/psychopatz/Zomboid/Workshop/ProjectHoomans
branch: main
phase: Standardized self-contained Conversation recipes
retrieval_tier: COMPLETE
primary_phase_commit: 3c926573
participant_commits:
  psychopatzCore: 9f34a15
  DynamicTrading: 77d29f8a
state: COMMITTED_UNRELATED_DIRTY_PRESERVED
updated_at: 2026-11-12T00:00:00+08:00
---

# Unified Semantic Catalog Handoff

## Contract delivered

PsychopatzCore is the only semantic harness and CodeBuilder authority. Core
Conversation sources now use self-contained locale maps for content, UI
suggestions, UI text records, and realization constructions. Generated runtime
keys and locale-specific realization IDs remain compiler output. Dynamic Trading
has a provider-local source manifest and optional UI shard mounted by the Core
manifest; it does not carry a second harness.

The PNC direct composition contains Core + Project Hoomans UI only. The
all-enabled composition also emits Dynamic Trading UI under DTCommon. Deleted
PNC `Conversation/Semantic/Suggestions.json` files and locale-split realization
sources are intentional removals, not compatibility shims.

## Verified gates

- Core: 85/85 Python tests.
- Dynamic Trading: 88/88 tests.
- PNC focused semantic/ownership/realization tests: 28/28.
- Core and DT source audits: no legacy authoring fields, no locale-split files,
  and no hard-size violations.
- Builds verified for PNC-only and all-enabled compositions.

The full PNC runner still reports two known unrelated runtime failures:
`pnc_population_director_smoke.lua` and the custom translation-manager smoke
assertion. They remain unmodified and are recorded in `PROGRESS.md`.

## Next chunk

Split the three preferred-size content shards by semantic domain, preserving
record IDs, ownership, locale output, and runtime fingerprints where the
contract permits. Then re-run the full PNC runner and update this handoff with
the primary commit hash.
