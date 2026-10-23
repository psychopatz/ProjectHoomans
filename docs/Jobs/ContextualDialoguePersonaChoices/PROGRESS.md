# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-24  
**Parent status:** REOPENED — P12 save-backed runtime/backend foundation retained; P13A/P13B/P13C/P13D/P13E/P13F/P13G complete.
**Current mandatory phase:** P13G — Operational acceptance — COMPLETE.
**Current remote baseline audited:** ProjectHoomans `main` at `b3dcd2b1` before the P13G implementation commit.
**Normal Semantic Lab runtime requirement:** Project Zomboid may remain CLOSED/OFFLINE.  
**Source save mutation:** FORBIDDEN.  
**Optional live profiler:** read-only enrichment only.

## Accepted foundation to preserve

P12 materially implemented and verified:

- immutable imported source snapshots;
- detached mutable working worlds;
- SAVE/FIXTURE/LIVE/DERIVED/HARNESS_MUTATION/MISSING provenance;
- read-only Core `GlobalModDataReader` reuse;
- save discovery/catalog;
- saved Player/NPC selection;
- exact saved directed relationship import;
- Project Hoomans/Core/DynamicTrading state providers;
- factions/communities/provider actor projections;
- explicit offline engine fixture provider;
- optional read-only profiler provider;
- production relationship proposal path;
- production recruitment/community path;
- save-backed Talk/semantic/graph/replay paths;
- source-save immutability and reset/reload boundaries.

Do not replay P12A-P12K unless a regression is demonstrated.

## P12 completion correction

The prior ledger stated:

```text
P12 status: COMPLETE
```

That is accepted only as **save-backed backend/runtime foundation complete**.

The user-facing product is not operationally complete.

Current screenshot + source audit show:

- save discovery works and reports eight validated saves;
- the save selector is compressed into the one-row `Saved world · read-only source` strip and is practically unusable at the normal left-pane width;
- P12 UI tests mostly assert widget existence, not successful human interaction through the full save-selection path;
- `SavedWorldBrowser` projects factions and actors separately but only builds flat actor categories such as All NPCs / Companions / Colonists / Followers / Neutral / Hostile / Known Traders;
- no first-class faction/community actor tree exists;
- Player/NPC workbench parity is incomplete;
- Player inventory may be `MISSING` because `PNC_PlayerCharacters` is not the native PZ physical-inventory authority;
- gift testing lacks a first-class side-by-side inventory/result workbench;
- the normal UI still exposes synthetic `NPC profile`, `Load scenario`, and `Save scenario` concepts prominently despite save-backed mode.

Therefore P13 is mandatory.

## P13A — Operational World Browser UX — COMPLETE

Implemented on existing `main`:

- replaced the compressed Simulation save row with a dedicated full-width `World Browser` tab inside Semantic Lab;
- kept save discovery, inspection, and import on the existing `SaveCatalog`, `SavedWorldBrowser`, `SaveBackedImporter`, and worker path;
- added a backend-owned `semantic.save_world_hierarchy.v1` projection containing persisted faction/community groups plus explicit unaffiliated, hostile, and trader/provider overlays;
- rendered that projection with a Tk `ttk.Treeview` with group expansion, NPC selection/double-click loading, and bounded search filtering;
- automatically inspects the first discovered save and re-inspects when the save selector changes;
- demoted synthetic `Load scenario`, `Save scenario`, and NPC profile controls into `Developer / Test fixtures`, hiding them after a real save import;
- shortened save labels to save name + mode so the selector remains usable at minimum geometry.

Exact evidence:

- pre-change real-worker reproduction: at `1080x700`, 8 real saves were discovered but the old save row requested `1355px` while only `630px` was available; its save combobox rendered at `1px`; the same left-pane compression persisted at `1320x860`;
- `P13_STATE=$(mktemp -d); XDG_STATE_HOME="$P13_STATE" xvfb-run -a -s '-screen 0 1440x1000x24' python3 -m unittest tools.semantic_harness.tests.test_operational_world_browser_p13a tools.semantic_harness.tests.test_save_browser_p12d`: `3/3` passed;
- the real-worker Tk acceptance exercised both `1080x700` and `1280x800`: discovered multiple real saves, selected a non-first save and Player, searched/expanded the hierarchy, selected an NPC, loaded the Player/NPC pair through `SaveBackedImporter`, started production Talk, and verified the source hash was unchanged;
- focused save-backed Python regression set (`test_save_catalog_p12b`, `test_save_import_p12c`, `test_save_browser_p12d`, `test_operational_world_browser_p13a`, `test_save_backed_conversation_p12j`): `11/11` passed;
- real production Lua worker checks: `pnc_semantic_dialogue_input_smoke` `1/1`, `pnc_semantic_gift` `5/5`, `pnc_semantic_task` `5/5` passed;
- `python3 -m py_compile` for changed Python files and `git diff --check` passed; no production Lua files changed, so no new Kahlua surface was introduced;
- the broader legacy `test_contextual_suggestions_s4` remains at its current `3` unrelated semantic-expectation failures (greeting realization, identity response wording, and hub back-navigation ordering); P13A did not change semantic/runtime Lua owners.

## Current Exact Next Chunk — P13B

Work on the user's existing local `main`.

1. Read root `AGENTS.md` and the ContextualDialoguePersonaChoices docs in order, including `OPERATIONAL_SEMANTIC_TEST_WORKBENCH.md`.
2. Inspect branch/HEAD/upstream/divergence and preserve concurrent work.
3. Reproduce the screenshot-level usability defect at realistic geometry:
   - discover multiple saves;
   - observe compressed/hidden save selector;
   - verify current inspect/import ritual.
4. Audit current owners:
   - `tools/semantic_harness/runtime/save_catalog.py`;
   - `save_browser.py`;
   - `state_providers.py`;
   - `save_import.py`;
   - existing `shell.py` save-browser controls;
   - Tk tests.
5. Reuse the P12 backend; do not create another save browser service.
6. Extend the backend projection only as needed to provide a real hierarchy:
   - faction;
   - community;
   - unaffiliated;
   - hostile;
   - trader/provider overlay.
7. Replace the compressed one-row save controls with a dedicated usable World Browser surface inside the existing Semantic Lab.
8. Prefer a hierarchical Tk control such as `ttk.Treeview`.
9. Include:
   - save selector;
   - reload/discover action;
   - saved Player selector;
   - search/filter;
   - faction/community/NPC hierarchy;
   - readable actor labels and basic relationship/role metadata where available.
10. Selecting/double-clicking an NPC must call the existing save-backed importer and set the current Talk target.
11. In save-backed mode, hide or clearly demote the synthetic NPC profile selector and legacy scenario controls to Developer/Test/Advanced.
12. Preserve Developer/Test fixture mode for CI.
13. Add real GUI interaction tests at minimum and desktop geometry. Do not accept `hasattr(widget)` as the primary usability proof.
14. The Xvfb test must actually:
   - discover saves;
   - select one;
   - select a Player;
   - expand/select a faction/group/NPC;
   - import the pair;
   - verify workbench target changed;
   - Start Talk.
15. Keep source save read-only and verify hash/source immutability.
16. Run focused Python/Tk/Lua checks and `git diff --check`.
17. Update this ledger with exact evidence and continue automatically to P13C when green.

## P13A acceptance

A user at realistic Semantic Lab geometry can visibly and interactively:

```text
choose save
 -> choose Player
 -> browse world hierarchy
 -> choose NPC
 -> load target
 -> Start Talk
```

without:

- raw JSON;
- hidden/collapsed comboboxes;
- manually declaring the NPC profile;
- loading a synthetic scenario.

The UI test must perform this workflow, not merely confirm controls exist.

## Ordered remaining P13 milestones

- **P13B:** read-only offline Player engine-state provider, Player inventory first — complete;
- **P13C:** symmetric Player/NPC actor inspectors — complete;
- **P13D:** faction/community workbench — complete;
- **P13E:** inventory/gift verification workbench;
- **P13F:** agent-grade CLI parity;
- **P13G:** real-save operational acceptance.

See `OPERATIONAL_SEMANTIC_TEST_WORKBENCH.md`.

## P13 product outcome

Normal development verification should become:

```text
real save
 -> real Player
 -> faction/community browser
 -> real NPC
 -> actor/inventory/relationship inspection
 -> production Talk/semantic/gift/recruit/proposal
 -> inspect working-world diff
 -> reset
 -> source save unchanged
```

This does not replace final user-owned native Project Zomboid acceptance. It makes native game startup unnecessary for ordinary semantic/conversation development verification.

## Handoff rule

Do not report **READY FOR USER LIVE TEST** merely because backend save import or fixture tests pass.

P13G operational acceptance must pass first.

## P13B — Offline Player Engine-State Provider — COMPLETE

Implemented on existing `main` without changing production Lua or the shared
Core ModData decoder.

- Audited the Build 42.20 engine baseline: `IsoWorld.WorldVersion = 249`,
  `PlayerDB` stores local Players in read-only SQLite `players.db`, and
  `localPlayers.data` contains the versioned `IsoPlayer` blob.
- Added `OfflinePlayerEngineStateProvider` in
  `tools/semantic_harness/runtime/player_engine_state.py`.
- The provider is bounded, read-only, version-gated to world version `249`,
  detects a source file changing during the read, resolves item registry IDs
  through that save's `WorldDictionaryReadable.lua`, and fails closed with
  `source = MISSING` for unsupported/corrupt/missing native state.
- The projection imports native Player inventory groups with `source = SAVE`;
  worn/equipped state remains explicitly `MISSING` until the remaining native
  serializer tail has an independently verified projection.
- `SaveBackedImporter` now uses native Player inventory when `players.db` is
  present, keeps PNC inventory fallback only for synthetic/developer fixtures
  without `players.db`, and publishes the native provider payload and
  provenance under `ProjectZomboid`.

Evidence on 2026-10-24:

- `python3 -m unittest tools.semantic_harness.tests.test_player_engine_state_p13b`:
  `3/3` passed, including real-save inventory and unsupported-version
  fail-closed cases.
- Real save `/home/psychopatz/Zomboid/Saves/Apocalypse/2026-10-14_13-57-03`
  exposed `19` native Player inventory groups; the real Lua worker imported
  them, ran production Talk with route `full_conversation`, and the
  `players.db` SHA-256 was unchanged.
- `P13_STATE=$(mktemp -d); XDG_STATE_HOME="$P13_STATE" timeout 180s
  xvfb-run -a -s '-screen 0 1440x1000x24' python3 -m unittest
  tools.semantic_harness.tests.test_save_catalog_p12b
  tools.semantic_harness.tests.test_save_import_p12c
  tools.semantic_harness.tests.test_save_browser_p12d
  tools.semantic_harness.tests.test_operational_world_browser_p13a
  tools.semantic_harness.tests.test_player_engine_state_p13b
  tools.semantic_harness.tests.test_save_backed_conversation_p12j`:
  `14/14` passed.
- `python3 -m py_compile tools/semantic_harness/runtime/*.py
  tools/semantic_harness/tests/test_player_engine_state_p13b.py` and
  `git diff --check` passed.
- Existing production Lua smoke/gift/task checks remained green; no Lua files
  changed in P13B.

## P13C — Symmetric Player/NPC Actor Inspectors — COMPLETE

Implemented on existing `main` using the existing Simulation workbench,
`SaveBackedImporter`, worker, and provider projections:

- Added matching Player and NPC Target surfaces for `Overview`, `Needs`,
  `Personality & Traits`, and `Inventory`.
- Added one shared, bounded, read-only `ActorInventoryView` presentation for
  both actors. It shows item, stack, origin, authority table, and explicit
  unavailable/empty state; it has no direct inventory mutation path.
- Added actor identity/tactical/faction/community summaries and provenance
  labels. Native Player identity and inventory show `SAVE` when the proven
  Build 42.20 provider is available; unsupported needs, traits, worn/equipped
  state remain explicit `MISSING` or `FIXTURE` rather than being invented.
- Added persisted Player/NPC identity, traits, and NPC personality provenance
  paths in the save importer.
- Preserved provider projections across the Python worker response boundary so
  the UI does not reread or reinterpret source saves.

Exact evidence on 2026-10-24:

- `xvfb-run -a python3 -m unittest
  tools.semantic_harness.tests.test_actor_inspectors_p13c`: `1/1` passed against
  real save `2026-10-14_13-57-03`, including native Player inventory rows,
  Player UUID, NPC target, shared columns, and unchanged source hash.
- Combined focused Tk/Python regression suite for P13C, P13A, P13B, P12C,
  P10E, and P11A: `15/15` passed at Xvfb minimum geometry; P13A continues to
  exercise both `1080x700` and `1280x800` real-save workflows.
- `python3 -m py_compile` passed for changed Python files and `git diff --check`
  passed. No production Lua files changed in P13C.
- Existing real-worker Lua smoke/gift/task checks remain the P12/P13B evidence;
  this chunk only extends the read-only actor presentation and transport seam.

## P13D — Faction/Community Workbench — COMPLETE

Implemented on existing `main` by extending the backend-owned `SavedWorldBrowser`
projection and the existing Semantic Lab World Browser:

- Preserved persisted faction/community rows, IDs, member IDs, leader, owner,
  status, archetype, roles, standing/diplomacy, and provider overlay fields
  when those fields exist in the adopter-owned projection.
- Added a read-only `Faction / Community context` inspector beside the existing
  hierarchy. It reports group source and membership source, identifiers,
  leader/owner, membership count, roles/standing/diplomacy, provider overlay,
  and bounded member labels.
- Kept member clicks and double-clicks on the existing Treeview selection path;
  selecting a member updates the current NPC target and loading it continues
  through `SaveBackedImporter` into the isolated workbench.
- No faction/community state is duplicated in the UI; the panel renders the
  existing save/provider projection and never infers ownership from labels.

Exact evidence on 2026-10-24:

- `xvfb-run -a python3 -m unittest
  tools.semantic_harness.tests.test_faction_community_workbench_p13d`: `1/1`
  passed against the real Apocalypse save, proving faction, community, and
  Dynamic Trading provider-overlay groups, persisted ID/member context, member
  target selection/import, and unchanged source hash.
- Focused save-backed regression set (`P13D`, actor inspectors, P13A browser,
  P12 save browser/import, P13B provider): `10/10` passed under Xvfb.
- `python3 -m py_compile` and `git diff --check` passed. No production Lua
  files changed in P13D.

## P13E — Inventory / Gift Verification Workbench — COMPLETE

Implemented on existing `main` using the shared actor inventory presentation and
the existing production semantic gift route:

- Added side-by-side read-only Player/NPC inventory panels with selected item,
  bounded quantity, `Give selected →`, reset, provenance/source labels, and a
  bounded result report.
- UI gift execution invokes the existing semantic `GIFT` path through
  `PNC.Client.SendInventoryTransfer`; it does not mutate inventory tables.
- Added bounded Lua worker `INSPECT_ACTOR_STATE` readback so large saved
  relationship journals do not exceed the JSON-lines transport limit. It returns
  bounded inventories and relationship scalars/bond only.
- Result evidence shows production status, Player/NPC inventory deltas, NPC
  response, relationship before/after, and `Source save: UNCHANGED`.
- `Reset Working World` reuses the existing imported-snapshot reset boundary;
  it restores Player/NPC inventories and relationship while avoiding a disk
  reread.

Exact evidence on 2026-10-24:

- Real Tk/Xvfb acceptance at `1080x700` selected a compatible real save, Player,
  persisted faction member `npcAdamBloom_48G5`, and native `Base.Bandage`; the
  production gift route changed isolated Player inventory and relationship,
  displayed the full evidence report, reset to the imported baseline, and kept
  the source save SHA-256 unchanged.
- Focused Tk regression set (`P13E`, P13C actor inspectors, P13D faction /
  community workbench, P13A browser, P10E workbench): `5/5` passed.
- Real Lua worker gift/lifecycle and save-backed conversation regressions:
  `5/5` passed; Python compile, `luac5.3 -p` for the worker router, and
  `git diff --check` passed.
- Full worker snapshot was intentionally not used for post-gift UI readback;
  the bounded command is the transport-safe evidence path for imported saves
  with large relationship memory state.

## P13F — Agent-grade CLI Parity — COMPLETE

Extended the existing `tools.semantic_harness` CLI and app routing to use the
same `SaveCatalog`, `SavedWorldBrowser`, `SaveBackedImporter`, Lua worker, and
production action routes as Semantic Lab:

- Added bounded machine-readable save discovery/inspection, Player/faction/
  community listing, and NPC search operations.
- Added save-backed pair loading by save path, Player UUID, and NPC ID, plus
  Player/NPC/inventory/relationship inspection from bounded production actor
  state.
- Added CLI Talk startup, semantic input, gift, recruitment, and relationship
  proposal dispatch without a CLI-only gameplay implementation.
- Added bounded working-world diff output with imported/effective values,
  `HARNESS_MUTATION`, and base source provenance; reset-world, turn,
  conversation, actor, and explicit reload-save operations are available.
- Kept discovery, raw save validation, and world projections read-only; the
  CLI never writes the source save.

Exact evidence on 2026-10-24:

- Real CLI acceptance against `/home/psychopatz/Zomboid/Saves/Apocalypse/2026-10-14_13-57-03`:
  discovered compatible/rejected saves, listed real Players/factions/
  communities, searched a real NPC, loaded a real Player/NPC pair, inspected
  inventories, routed a production gift, observed a changed working-world
  diff, reset it to zero diff, and verified the source SHA-256 was unchanged.
- The same CLI acceptance exercised Talk startup, proposal, recruitment, and
  explicit reload-save commands: `3/3` tests passed.
- Combined non-Tk CLI/save/gift/conversation regressions passed; Tk/Xvfb
  P13A/P13C/P13D/P13E/P10E suite passed with real worker interaction.
- Production worker smoke/gift/task suite: `11/11` passed. Python compile,
  worker-router `luac5.3 -p`, and `git diff --check` passed.

## P13G — Operational Acceptance — COMPLETE

Implemented and verified the complete real-save operational workflow on existing
`main` without changing source saves or requiring Project Zomboid to run:

- tightened production Talk parity transport to omit only oversized diagnostic
  relationship/knowledge payloads from worker responses while preserving the
  full isolated working-world state and real target entry ID;
- added `test_operational_acceptance_p13g.py` covering the real saved
  companion/follower, neutral, hostile, and trader/provider overlays;
- real worker matrix passed production routes for all available categories:
  follower/neutral/trader `full_conversation`, hostile
  `hostile_full_conversation`, and trader overlay enabled;
- real CLI JSONL workflow passed Talk → gift → changed working-world diff,
  then gift → Reset World → zero diff; source save SHA-256 remained unchanged;
- real Tk workflow passed at `1080x700` and `1280x800`: discover save, choose
  Player, expand persisted faction membership, choose NPC, import pair, Start
  Talk, gift `Base.Bandage`, inspect NPC response/inventory/relationship delta,
  reset imported baseline, and verify source save unchanged;
- validation evidence on 2026-10-24: `11/11` Tk/Xvfb interaction tests,
  `24` focused non-Tk worker/CLI/production tests (`OK`, two GUI cases skipped
  only in the display-free rerun), worker smoke/gift/task `11/11`,
  `luac5.3 -p`, and `pz_verify --kahlua --severity ERROR` clean;
- `git diff --check` and Python compilation clean.

## Current Exact Next Chunk — none documented after P13G

`ROADMAP.md` currently ends at P13G. No later phase is being invented or
started by this handoff.
