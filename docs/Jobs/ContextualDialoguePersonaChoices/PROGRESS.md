# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-24  
**Parent status:** REOPENED — P12 save-backed runtime/backend foundation retained; P13A complete; P13 operational usability remains mandatory.
**Current mandatory phase:** P13B — Offline Player Engine-State Provider.
**Current remote baseline audited:** ProjectHoomans `main` at `dbfd9099a0b687bc2f6505f58e81e32ea6dc5966`.  
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
17. Update this ledger with exact evidence and continue automatically to P13B when green.

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

- **P13B:** read-only offline Player engine-state provider, Player inventory first;
- **P13C:** symmetric Player/NPC actor inspectors;
- **P13D:** faction/community workbench;
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
