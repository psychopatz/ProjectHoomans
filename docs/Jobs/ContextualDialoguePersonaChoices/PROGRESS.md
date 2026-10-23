# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-24  
**Parent status:** IN PROGRESS — P10/P11/P11J runtime-parity foundation retained; P12 save-backed offline Semantic Lab is mandatory.
**Current mandatory phase:** P12K — Final safety/parity matrix.
**Current local baseline audited:** ProjectHoomans `main` at `8ac1a18f`; upstream remains unchanged and local `main` is ahead by eleven commits.
**Normal Semantic Lab runtime requirement:** Project Zomboid CLOSED/OFFLINE is supported and expected.  
**Source save mutation:** FORBIDDEN.  
**Optional live profiler:** disabled by default; read-only enrichment only.

## Accepted foundation to preserve

Current source already materially contains:

- production semantic Lua worker;
- production Talk-start projection shared with native conversation;
- contextual What's Up hub;
- semantic Flow / Hub / ConversationBlock runtime graphs;
- actor-centric Player/NPC/Relationship/World workbench;
- generated NPC personality and real trait catalogs;
- directed relationship standing and durable bond services;
- automatic friend promotion;
- proposal policy/service and harness diagnostic proposal operation;
- production recruitment/community authority in the worker;
- structured inventory + Advanced JSON;
- replay/Compare/activity logging;
- deterministic identity/backstory work;
- native Talk parity target catalog/matrix/GUI/CLI;
- current synthetic scenario/configure infrastructure.

Do not discard those systems.

## Architectural pivot

The remaining parity drift is now mostly caused by **state origin**.

Normal Semantic Lab still starts from synthetic scenario data for significant mod-owned state and engine-derived values.

Examples include:

- manually selected NPC profile;
- hand-authored actor relationship fields;
- adapter reconstruction of bond/friend promotion;
- needs;
- time;
- weather;
- world age;
- other scenario-defined runtime facts.

P12 changes the normal product architecture to:

```text
real saved mod state
+ explicit offline engine fixtures
+ optional read-only live profiler snapshot
        ↓
immutable imported source snapshot
        ↓
isolated mutable harness working world
        ↓
production Lua
```

Synthetic scenarios remain for CI/tests/malformed fixtures only.

## Save reader foundation

PsychopatzCore already owns the low-level read-only Build 42.20 parser:

```text
psychopatzCore/tools/profiler/moddata_reader.py
GlobalModDataReader
```

P12 must reuse it.

Do not build another `global_mod_data.bin` decoder.

Known first persisted roots include:

```text
PNC_Core_Global
PNC_npc<ID>
PNC_PlayerCharacters
```

and additional Core/Hoomans/DynamicTrading roots discovered by their state providers.

## Relationship parity finding

The current worker still reconstructs relationship policy in SemanticAdapters.

For example, the harness currently:

- resolves relationship state;
- reconstructs starting bond;
- performs its own 80/50/60 friend-promotion check;
- creates a harness social event;
- caches the result in `Runtime.relationships`.

This is now architectural debt.

P12 must instead import the real relationship record:

```text
npcRecord.social.relationships[playerEntityKey]
```

and run mutations through production relationship services in the isolated working world.

## Engine fixture rule

Project Zomboid does not need to be active.

Engine/transient values may remain editable fixtures when not available from supported offline readers, including:

- needs;
- time;
- weather;
- climate;
- current activity;
- position;
- nearby zombie density;
- other engine-only facts.

These must be explicitly marked:

```text
source = FIXTURE
```

rather than presented as saved truth.

## Optional live profiler rule

Live enrichment is optional.

The game side must be:

- disabled by default;
- enabled by external settings/config text only;
- restart-required;
- not exposed as a normal in-game toggle;
- strictly read-only.

Semantic Lab may consume a live snapshot and copy it into the harness working world.

Semantic Lab must never send gameplay mutations back to the running game.

## Historical P12A checklist (completed)

On the user's actual local checkout:

1. read root `AGENTS.md` and the ContextualDialoguePersonaChoices docs in documented order, including `SAVE_BACKED_OFFLINE_SEMANTIC_RUNTIME.md`;
2. inspect local ProjectHoomans/PsychopatzCore/DynamicTrading branches, HEADs, upstream/divergence, dirty/concurrent work; existing `main` only;
3. audit current scenario ownership:
   - Python `scenario.py`;
   - Lua worker Runtime/scenario;
   - configure/apply/replay paths;
   - workbench draft state;
   - relationship/runtime caches;
   - inventory/knowledge/provider state;
4. define one versioned source snapshot contract containing:
   - immutable imported state;
   - source metadata;
   - provenance;
   - raw provider payloads where needed;
5. define one mutable working-world contract copied from the source snapshot;
6. define provenance classes:
   - SAVE;
   - FIXTURE;
   - LIVE;
   - DERIVED;
   - HARNESS_MUTATION;
   - MISSING;
7. define override/patch semantics so a mutation does not destroy the imported source value;
8. define reset boundaries:
   - reset turn;
   - reset conversation;
   - reset selected actor mutations;
   - reset working world to imported snapshot;
   - reload source from disk;
9. keep current synthetic scenario loading as an explicit Developer/Test source so CI remains deterministic;
10. change normal product abstractions so future P12 save imports target the source/working-world contracts rather than adding more fields directly to the legacy flat scenario;
11. add tests proving:
   - worker mutations cannot alter the immutable source snapshot;
   - reset working world restores imported values;
   - provenance survives configure/mutation/reset;
   - fixture/test mode still works;
12. do NOT implement binary save browsing yet unless a minimal seam is required for the contract;
13. run focused Python/Lua/Tk checks and `git diff --check`;
14. update this ledger with exact evidence and continue automatically to P12B if green.

## Completed Chunk — P12A Snapshot/provenance architecture

Implemented on the existing ProjectHoomans `main` checkout:

- versioned Python `ImportedSourceSnapshot` and mutable `HarnessWorkingWorld` contracts;
- stable `SAVE`, `FIXTURE`, `LIVE`, `DERIVED`, `HARNESS_MUTATION`, and `MISSING` provenance values;
- immutable imported values retained separately from normalized working state;
- patch projections with imported/effective values, mutation provenance, and source baseline;
- Lua `IMPORT_SOURCE`, `RESET_TURN`, `RESET_CONVERSATION`, `RESET_ACTOR_MUTATIONS`, and `RESET_WORLD` boundaries;
- `CONFIG` retained as a working-world edit and `reload_source` reserved for explicit source rereads;
- synthetic scenarios retained as `FIXTURE` / `developer_test` source;
- no save browsing or second binary save decoder added in P12A.

Evidence:

- `tools/semantic_harness/tests/test_save_backed_snapshot_p12a.py`: 2 tests passed;
- source model rejects mutation of imported nested state, while working relationship patches report `HARNESS_MUTATION` over `SAVE`;
- production Lua inventory gift mutation changed only the working projection; the Python source snapshot remained equivalent after conversation reset and working-world reset;
- reset restored the normalized imported baseline without rereading disk;
- focused compatibility validation: 10 existing worker/inventory/runtime/session tests passed;
- `python3 -m py_compile`, `luac5.3 -p`, and `git diff --check` passed;
- the broader legacy `test_harness` module ran 24 tests but retains 2 identity-presentation assertion failures outside P12A.

## Completed Chunk — P12B Core reader reuse + save catalog

Implemented a read-only offline save catalog over the existing Core reader:

- `tools/semantic_harness/runtime/save_catalog.py` loads and reuses Core `GlobalModDataReader` and `ModDataFormatError` directly;
- no second `global_mod_data.bin` decoder was added;
- conventional `Zomboid/Saves` roots and explicit `PZ_SAVE_ROOT` / `ZOMBOID_SAVE_ROOT` roots are discovered without Project Zomboid running;
- compatible saves enumerate `PNC_PlayerCharacters`, `PNC_Core_Global`, every `PNC_npc<ID>` table, file metadata, and source IDs;
- Build 42.20 world version 249 and persisted Project Hoomans schema versions 6/16/16 are validated through Core inspection;
- unsupported world versions, corrupt files, missing required tables, invalid schema versions, and changing files are rejected rather than imported;
- the high-level worker exposes the catalog without sending any command to Project Zomboid.

Evidence:

- `tools/semantic_harness/tests/test_save_catalog_p12b.py`: 4 tests passed;
- PsychopatzCore `tools/profiler/tests/test_moddata_reader.py`: 7 tests passed;
- P12A plus P12B focused suite: 6 tests passed;
- no source-save writes are performed by the catalog.

## Completed Chunk — P12C Real actor + relationship import

Implemented real saved Player/NPC selection and isolated relationship import:

- `tools/semantic_harness/runtime/save_import.py` reuses the P12B catalog/Core reader, selects a saved player and `PNC_npc<ID>`, derives the production entity key, and imports the full persisted relationship under `npcRecord.social.relationships[playerEntityKey]`;
- saved player social profiles and NPC social/personality payloads remain provider-owned source data; needs/world values remain explicit `FIXTURE` values;
- `SAVE` source worlds delegate relationship reads, conversation effects, proposal evaluation, and proposal mutation to the production social-profile/relationship services;
- relationship policy was removed from `SemanticAdapters_Identity`; the old synthetic relationship policy is isolated in the explicit Developer/Test provider so P8/P11 fixture tests remain compatible;
- the worker exposes `import_saved_selection(...)` without requiring Project Zomboid to run.

Evidence:

- `tools/semantic_harness/tests/test_save_import_p12c.py`: 2 tests passed, including saved entity/relationship/profile provenance and source immutability across mutation/reset;
- focused P12C plus P8A compatibility suite: 8 tests passed;
- P11D/P11E proposal compatibility suite: 11 tests passed;
- local real-save smoke test imported `player:sp_slot_0:char_1791957489838_240087` and `npcAdamBloom_48G5`, exposed the persisted relationship/memories, reached production proposal policy, applied a gift mutation only to the working world, and reset to the imported baseline;
- Python compilation, `luac5.3 -p`, and `git diff --check` passed; no save or live-game writes were performed.

## Completed Chunk — P12D Save-backed World Browser

Implemented a bounded, read-only browser over a validated save:

- `tools/semantic_harness/runtime/save_browser.py` reuses `GlobalModDataReader` through the P12B catalog seam and projects saved Players, NPC categories, factions, derived community references, and Dynamic Trading provider actors;
- saved actor rows retain persisted identity, affiliation, hostility, order, generation, faction/community IDs, and `source = SAVE`; community references explicitly report `source = DERIVED` with `baseSource = SAVE`;
- `LuaSemanticWorker.save_browser(...)` exposes the browser and the GUI provides Discover saves, Inspect, category/actor selection, and Import target controls;
- normal target import calls the existing save-backed importer, so selecting a browser NPC changes the production conversation target without authoring a synthetic profile.

Evidence:

- `tools/semantic_harness/tests/test_save_browser_p12d.py`: backend source-immutability/category test and Xvfb UI-control smoke test passed;
- local real-save browser smoke: 1 Player, 111 NPCs, 43 factions, 5 community references, 2 followers/companions, and 9 known Dynamic Trading actors;
- P12C saved-import tests remained green; Python compilation, Xvfb startup, and `git diff --check` passed.

## Completed Chunk — P12E Dynamic mod-state providers

Introduced the save-state interpretation boundary:

- `tools/semantic_harness/runtime/state_providers.py` defines the bounded `SaveStateProvider` contract, `ProviderContext`, and `SemanticStateCatalog`;
- `CoreStateProvider`, `ProjectHoomansStateProvider`, and `DynamicTradingStateProvider` own their respective schema projections while all binary decoding remains in PsychopatzCore `GlobalModDataReader`;
- `RawSaveInspector` keeps validated raw-save/catalog metadata separate from the semantic provider projections;
- persisted `PNC_Communities` records are used when present; only absent community tables fall back to explicit `DERIVED` references from saved actor affiliations;
- provider absence is represented as `available = false`, `source = MISSING`, and a bounded reason rather than invented state.

Evidence:

- P12D browser tests now assert all three provider IDs, Dynamic Trading provider ownership, and source-save immutability;
- local real-save provider smoke exposed Core schema 16, persisted communities as `SAVE`, and 9 Dynamic Trading provider actors;
- P12B/P12C/P12D suite: 8 tests passed; Xvfb worker/UI regression: 3 tests passed; Python compilation and `git diff --check` passed.

## Completed Chunk — P12F Offline engine fixture provider

Added `tools/semantic_harness/runtime/fixture_provider.py` with a versioned offline engine-fixture contract:

- player/NPC needs and engine-derived world values (time, weather, temperature, season, activity, position, nearby density, zombie kills) are cataloged as editable `FIXTURE` fields;
- fixture values are carried in the immutable source snapshot under `offline_engine_fixtures`; saved ProjectHoomans/Core/DynamicTrading payloads remain separate;
- fixture provenance is installed during configure/import and survives mutation/reset; working edits report `HARNESS_MUTATION` over the fixture baseline;
- missing transient fields are explicit `MISSING`, not silently filled with saved mod-owned state; Project Zomboid remains optional.

Evidence:

- `tools/semantic_harness/tests/test_fixture_provider_p12f.py`: 2 tests passed;
- P12A–P12D focused suites remained green; Python compilation and `git diff --check` passed.

## Completed Chunk — P12G Optional read-only live profiler provider

Audited the existing PsychopatzCore/Hoomans profiler lifecycle and added an explicit Semantic Lab read-only provider:

- the existing Core `PsychopatzCore_Profiler.txt` contract remains the only game-side gate: missing/invalid configuration resolves to `OFF`, configuration is read at bootstrap, and the runtime snapshot includes a version/fingerprint/capture manifest;
- `tools/semantic_harness/runtime/live_profiler_provider.py` reuses Core's existing `profiler_cli.read_snapshot`, `capture_manifest`, `snapshot_npc_data`, and `profiler_config.read_capture_config` helpers rather than adding a snapshot decoder;
- the provider is disabled by default, requires explicit opt-in plus a non-`OFF` external config, reports `LIVE` only for bounded copied projections, and reports `MISSING` with a reason when PZ/snapshot/config data is unavailable;
- the contract exposes only `GET_SNAPSHOT`, `GET_PLAYER`, `GET_NPC`, `GET_WORLD`, and `GET_FACTIONS`; mutation command names are explicitly forbidden and no command transport exists;
- `LuaSemanticWorker.live_profiler_catalog(...)` exposes the provider without changing the normal offline path; `enrich_from_live_profiler(...)` is an explicit copy operation limited to engine-fixture-shaped paths, records `LIVE` provenance, and keeps the snapshot file untouched;
- live data can enrich the detached source/working snapshot while PZ is closed; no data or gameplay command is sent to the running game.

Evidence:

- `tools/semantic_harness/tests/test_live_profiler_provider_p12g.py`: default-disabled, forbidden-operation, bounded-projection, explicit-enrichment, reset, and snapshot-immutability tests passed;
- P12A–P12F focused tests remained green; Python compilation, `luac5.3 -p`, and `git diff --check` passed;
- the existing Core profiler CLI reported the saved runtime identity but no connected Project Zomboid process; no profiler setting was changed.

## Completed Chunk — P12H Production mutations in isolated world

Completed the remaining normal semantic proposal route and kept the existing production mutation owners in the isolated worker:

- `PNC_SemanticDialogueSuggestions_SocialProvider` advertises a typed relationship-proposal choice only when the production relationship service is present and `EvaluateProposal(...)` reports eligibility;
- the choice frame carries `RELATIONSHIP_PROPOSAL`, the production dialogue policy recognizes it as an executable action, and the action boundary calls `PNC.Relationships.Propose(...)` rather than mutating a harness relationship directly;
- the result reports the production relationship-service route and retains the production acceptance/rejection memory, bond, cooldown, and revision effects in the detached working world;
- existing production recruitment/faction/community assignment, supported inventory/tool effects, knowledge, and quest replay paths remain loaded through their service owners; no second harness gameplay policy was introduced.

Evidence:

- `tools/semantic_harness/tests/test_production_mutations_p12h.py`: normal semantic proposal choice reached `PNC.Relationships.Propose(...)`, changed only the working relationship revision/memory, and left the immutable source snapshot unchanged;
- retained Talk/recruitment production suite: 14 tests passed, including shortcut and typed recruitment assignment through the production authority;
- P12A–P12G focused suite remained green; `luac5.3 -p`, `git diff --check`, and `pz-verify` Kahlua checks for all three changed Lua files passed with zero issues;
- no save file or live Project Zomboid object was written.

## Completed Chunk — P12I Source-aware UI + relationship parity

Implemented source-aware normal UI and production relationship projection:

- Semantic Lab now shows source kind, immutable-source status, working-world override count, imported/effective values, base source, and provider for important relationship/world/actor/inventory fields in a dedicated Provenance inspector;
- the relationship inspector exposes the complete imported directed record, including baselines, approval/respect/familiarity, current and previous standing, bond, memories, cooldowns, interaction journal/revision, and relationship revision;
- the Lua projection now calls the production `PNC.RelationshipPresentation` and `PNC.RelationshipGraph` modules and labels their record/graph/presentation output as the authority; Python only bounds display size;
- the existing synthetic path remains explicitly Developer/Test-backed and the source snapshot remains read-only.

Evidence:

- `tools/semantic_harness/tests/test_save_import_p12c.py`: 2 saved-import tests passed, including production Graph/Presentation projections and source immutability;
- `tools/semantic_harness/tests/test_save_browser_p12d.py`: 2 tests passed under Xvfb, including the Provenance tab;
- P12A–P12H plus P11J regression set: 28 tests passed;
- `python3 -m py_compile`, `luac5.3 -p`, and `git diff --check` passed; `pz-verify` found zero Kahlua issues in the changed ScenarioSession file, while the unchanged legacy loader findings in ProductionModules remain pre-existing.

## Completed Chunk — P12J Save-backed conversation parity

Completed save-backed conversation parity against a selected persisted Player/NPC pair without requiring a hand-authored synthetic NPC during normal workflow:

- imported saved actor identity, tactical/affiliation/hostility/order projection, personality, supported inventory, and DynamicTrading provider state with explicit `SAVE`/`MISSING` provenance;
- kept unsupported native inventory blobs explicit rather than inventing a saved inventory projection;
- exercised Talk, identity, relationship, inventory, Flow/Hub/ConversationBlock graph, Replay, Compare, knowledge, normal production relationship proposal, recruitment, and Dynamic Trading overlay paths;
- compacted Talk transport copies so large raw provider payloads do not exceed the worker response limit while the complete immutable source remains available through snapshot/import responses;
- removed the worker relationship-presentation override so production `RelationshipPresentation` remains authoritative; fixed saved male-player `isFemale() == false` handling so production romance eligibility is evaluated correctly.

Evidence:

- `tools/semantic_harness/tests/test_save_backed_conversation_p12j.py`: 2 tests passed;
- retained P12A–P12H/P11J/P12J regression set: 30 tests passed;
- offline real-save smoke using `2026-10-14_13-57-03`, player `char_1791957489838_240087`, NPC `npcAdamBloom_48G5`: source `SAVE`, Talk `full_conversation`, identity/inventory/graph/replay/knowledge paths exercised, source snapshot and save hash unchanged;
- changed Python compiled, changed Lua parsed with `luac5.3`, `git diff --check` passed; `pz-verify` reported zero Kahlua issues in changed production Lua and the existing worker `io.*` finding only in `RuntimeEnvironment.lua`.

## Completed Chunk — P12K Final safety/parity matrix

Completed the final bounded save-backed safety/parity matrix and closed P12:

- cataloged 8 accepted real saves and 6 fail-closed saves from `/home/psychopatz/Zomboid/Saves`; accepted records include multiple saved Player entity keys, large NPC worlds, compact companion worlds, factions, communities, neutral NPCs, hostile NPCs, followers, and known traders;
- exercised six real saved imports across three saves/players, including neutral, hostile, owned-follower, and known-trader targets; production Talk routes, detached reset, source-snapshot immutability, and on-disk save hashes all passed;
- verified actual provider presence/absence: Core and ProjectHoomans `SAVE` projections remain available, while DynamicTrading is `SAVE` in trader-bearing saves and explicit `MISSING` in saves without its tables;
- rejected actual unsupported world versions and missing required tables; retained synthetic corrupt/unsupported/invalid-schema coverage from P12B; offline fixture and optional live-profiler default-disabled/read-only coverage remained green;
- verified explicit source reload rereads changed disk content and Reset World restores the already-imported baseline; no source save or live Project Zomboid state was written;
- added the bounded worker transport projection required for large saved actor/provider records and restored compatibility with legacy test loaders; production relationship, Talk, and semantic behavior remains authoritative.

Final evidence:

- retained P12A–P12H/P11J/P12J Python regression set: 30 tests passed;
- P12D/P11J Xvfb UI/worker set: 15 tests passed;
- full Lua regression: 871/871 passed; focused catalog/translation set: 4/4 passed;
- harness doctor: all required checks passed, including Tk/display, paired Core, worker syntax, and READY/PING/CAPABILITIES;
- changed Python compiled, changed Lua parsed with `luac5.3`, production/worker Kahlua checks passed except the pre-existing worker-only `RuntimeEnvironment.lua` `io.*` finding, and `git diff --check` passed;
- the unbounded full Python discovery command was stopped after 22 minutes in an idle poll state with no result; no failure from that run is being claimed, and bounded P12 evidence above is the acceptance evidence.

**P12 status:** COMPLETE. The normal Semantic Lab workflow now loads real saved state read-only, applies explicit fixtures/provider projections, runs production semantic/conversation Lua offline, mutates only detached harness state, resets/reloads safely, and proves source immutability.

## P12A acceptance

Developer evidence must prove:

```text
SOURCE SNAPSHOT
immutable
        │ copy
        ▼
WORKING WORLD
mutable through production Lua
```

A relationship/recruitment/inventory test mutation against the working world must not alter the source snapshot object or serialized source representation.

Resetting the working world must reproduce the original imported values exactly.

## Ordered remaining P12 milestones

After P12A continue automatically:

- **P12B:** reuse Core reader + save catalog;
- **P12C:** real Player/NPC/relationship import;
- **P12D:** save-backed World Browser;
- **P12E:** dynamic mod-state providers;
- **P12F:** explicit offline engine fixture provider;
- **P12G:** optional read-only live profiler provider;
- **P12H:** production mutations in isolated world, including outstanding normal proposal-route completion;
- **P12I:** source-aware UI + full relationship parity;
- **P12J:** save-backed Talk/semantic/replay parity;
- **P12K:** final parity/safety matrix.

See `SAVE_BACKED_OFFLINE_SEMANTIC_RUNTIME.md`.

## P11J / P11M disposition

P11J Talk parity infrastructure is retained as completed foundation.

Do not replay old P11J2 instructions.

The outstanding P11M normal production proposal-action requirement remains mandatory, but is folded into **P12H** so it is proven against the same isolated save-backed runtime instead of a separate fixture-only path.

## Handoff condition

Do not report **READY FOR USER LIVE TEST** from fixture-only acceptance.

P12 is complete only when the normal Semantic Lab workflow can:

```text
load real saved world
 -> select real saved Player/NPC
 -> import real mod-owned state read-only
 -> run production semantic/conversation services offline
 -> mutate only isolated harness state
 -> reset safely
 -> prove source save unchanged
```

Optional profiler enrichment is not required for P12 completion unless its specific P12G gate is being tested.
