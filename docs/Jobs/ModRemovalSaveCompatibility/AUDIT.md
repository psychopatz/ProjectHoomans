# Audit — Reference Save & Capacity Symptom

## Evidence snapshot (read-only, 2026-11-20)

- Repository: ~/Zomboid/Workshop/ProjectHoomans, main, HEAD 8575f20e24d716efc52142376c50a2bd22d706f0 at inspection.
- Save: ~/Zomboid/Saves/Apocalypse/2026-11-20_07-12-33.
- User-selected in-game save screen: Apocalypse, selected timestamp 2026-11-20_07-12-33; UI says 'No mods used', world version 251.
- Save mods.txt: VERSION = 1 with empty mods {} and maps {}.
- Save players.db: SQLite with localPlayers and networkPlayers tables; localPlayers has two entries (ids 1 and 2), both non-dead, with the same displayed character name. Their data BLOBs are 4,371 and 4,321 bytes respectively. The active record, meaning of both rows and their capacity/strength values are NOT yet established.
- Save global_mod_data.bin: 669,819 bytes; raw byte searches find recurring PNC, ProjectHoomans and Psychopatz strings. This proves residue, NOT that these bytes have a running effect or that they are stale or invalid.
- Related saves 2026-11-20_07-50-51 and 2026-11-20_08-34-57 list PsychopatzCore, MarketSense, DTCommon, ProjectHoomans and DTHoomans in mods.txt. These are NOT controlled before/after snapshots of the same character; do not present them as baseline equivalence.
- The 8 weight maximum is reported by the user; it has NOT been independently decoded from the binary player BLOB or reproduced with native Project Zomboid.

## Source investigation already performed

- Scoped searches of ProjectHoomans, psychopatzCore and DynamicTrading Lua found no direct player setMaxWeightBase, setMaxWeightDelta, setUnlimitedCarry or setPerkLevel call in the searched trees.
- Project Hoomans maintains an NPC carry model: PNC_Inventory_State.lua, buildBaseCarryWeight uses its own NPC Strength/Fitness lookup. This is NOT proof the formula reaches the vanilla player.
- ProjectHoomans contains a zombie-specific setGodMod reference in PNC_BodyLifecycle_BodyFactory.lua; that is not evidence of a player debug/cheat toggle.
- Core has a container setCapacity call in PsychopatzPortableItemState.lua; not proof of player carry mutation.
- Search was textual and scoped; other languages, native hooks, generated code, runtime state, deleted historical versions and external mods remain unverified.

## Investigate and distinguish

1. **Capacity display vs true mechanics:** is 8 only the UI's denominator, the actual encumbrance threshold, a debug-mode artifact, or an expected vanilla value for that specific character/condition?
2. **Correct active player record:** explain the two localPlayers rows and determine which blob is loaded. Use PZ's actual serializer/reader or instrumented trusted runtime introspection; do not assign meaning to arbitrary offsets.
3. **Vanilla factors:** current Strength/Fitness, traits, character condition, clothing/containers and debug/admin/unlimited-carry states; compare to a clean character with matched attributes, not an arbitrary default 12.
4. **Persisted ownership:** distinguish player ModData vs global ModData, and namespaced data vs vanilla fields or engine objects. Find concrete write and reload paths across PNC, Core and trading integrations.
5. **Disable/removal behavior:** no mod Lua executes once removed. Pre-uninstall cleanup can be optional, but cannot be required for normal correct player capacity. If a defect is already embedded in the save, design an explicitly opt-in, backup-first repair route only after the exact field and legitimate value can be proven.
6. **External interference:** verify configuration, loaded mods, runtime console symptoms and actual game version. The empty mods.txt concerns the selected save's configured list; it does not by itself prove nothing is globally active.
7. **Removal/reinstall consistency:** raw residual namespaced data must be harmless when unloaded and deterministically recognized or ignored on re-enable without duplication or unexpected player-character state changes.

## Evidence labels / blockers

- SAVE_METADATA_VERIFIED: mods.txt and SQLite schema/row metadata inspected in place without writes.
- CODE_SEARCH_VERIFIED: the limited textual searches summarized above.
- UNVERIFIED: numeric player capacity in BLOB, causal link, debug state, exact serializer content and runtime outcome.
- REPRODUCTION_GAP: no native controlled capture of the bad state was performed in this audit.
- Do not treat prior community anecdotes or hypotheses about debug God Mode as a validated root cause.

## Safety

This save may contain player-only data. Only retain minimal anonymized evidence in documentation; never copy players.db, global_mod_data.bin or character-identifying content to Git, test fixtures or logs. Inspect read-only and test repairs only on disposable copies after backup verification. Treat the two other saves as distinct independent controls, not exchangeable snapshots.
