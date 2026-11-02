# Progress — Core Semantic & Relationship Foundation

**State:** COMPLETE — READY FOR USER LIVE TEST.

## Final Repository Snapshot

- `psychopatzCore`: `main @ c62262c`, clean.
- `DynamicTrading`: `main @ 89c349ce`, with the preserved tracked modification in `Contents/mods/DTHoomans/42.20/media/lua/shared/DTHoomans/DTHoomans_Conversation.lua`.
- `ProjectHoomans`: `main @ 4787c4a1`, clean.

## Completed Phases

- **P0-P7:** Core NPC Foundation, Actor models, and initial Semantics / Conversation layers.
- **P8:** Cross-adopter canonical player target identity and non-destructive relationship merging.
- **P9:** Semantic pack ownership, unregister, and re-register lifecycle (residue-free).
- **P10:** Repaired Hoomans semantic schema, grammar, and capability gating.
- **P11-P12:** Initial cross-adopter matrix and documentation.
- **P13-P15:** Standalone DT parser completion, bounded uncertainty, and real WorldKnowledge fact grounding with evidence IDs.
- **P16:** Persistent Core issuance registry, account binding, save/load API, and normal DT-first adoption flow.
- **P17:** Canonical DT home/current/origin/destination policy fields/setters and TalkService policy consumption.
- **P18:** Prevented mirror-to-authority identity bootstrapping. Removed implicit issuance registration from `PsychopatzPlayerIdentity.GetCharacterUUID`. Core lookup checks `IsIssuedIdentity(pncUUID, accountKey)`: unknown mirrors are rejected, and Core-first resolution cannot bootstrap authority.
- **P19:** Live travel-derived factual dialogue, presentation seam, and persistence:
  - **P19A:** Excursion travel lifecycle (`PREPARING`, `OUTBOUND`, `VISITING`, `RETURNING_HOME`, `AT_HOME`, `FAILED`) mapped in `DTHoomans_ResidentExcursion.lua` to canonical Policy and TraderService state.
  - **P19B:** Decoupled `DTCommon.PlacePresentation` registry and resolver seam converts canonical machine IDs to human display names. Unresolvable machine IDs yield bounded uncertainty and never leak into player-facing dialogue.
  - **P19C:** Real DT storage persistence and reload verified across complete runtime wipes.
  - **P19D:** Cross-adopter matrix (`tests/pnc_real_cross_adopter_hotplug_matrix_smoke.lua`) upgraded to cover P18 order-of-call identity tests, real excursion transitions, place presentation, and storage reload across all 6 sequences.

## Test Validation Results

- `DynamicTrading` test runner: `PASS 43/43`.
- `ProjectHoomans` test runner: `PASS 982/987` (only the 5 pre-existing baseline failures).
- `ProjectHoomans` hotplug matrix (`tests/pnc_real_cross_adopter_hotplug_matrix_smoke.lua`): `PASS 6/6 sequences`.
- `psychopatzCore` smoke suites: all identity, social, capability, and WorldKnowledge tests `PASS`.
- Lua syntax: all changed files passed `luac5.3 -p`.
- Repository diffs: all repositories passed `git diff --check`.

## Parent Goal Status

**COMPLETE — READY FOR USER LIVE TEST.**

Developer validation boundary is fully closed. Handing off to native Project Zomboid live testing.
