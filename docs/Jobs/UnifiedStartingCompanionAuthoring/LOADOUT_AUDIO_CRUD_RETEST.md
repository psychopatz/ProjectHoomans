# Loadout, framing, voice and saved records — P5R9/P5R10

P5R10 follow-up: the next native run hit `options.onDelete` on nil during
composer construction. Console `4c35d197`/`E4A983F` confirms the hidden Explorer
was resized before Show. Idle resize now defers until browsing configuration
exists. The new real-host initialization regression passes; current counts are
66/66 focused and 1059/1063 full, with the same four known failures. Start the
native retest by opening both creator hosts in a fresh session.

The P5R8 native retest still showed a wall of slots, including misplaced
forearm/underwear locations, body framing during appearance edits, inaudible
voice playback and no deletion action for saved records. The latest bounded
console session (`c65a4657`, installed PZ42.22.2) reports startup font/fluid errors
without an editor Lua exception for this report.

## Developer result

Loadout now has selectable body-part sections, with metadata classification
separate from tile layout. It uses prefix/whole-word specificity rather than
unrestricted substring matching, so forearms, underwear and utility sockets do
not enter unrelated head/feet sections. Native exclusivity hides empty blocked
slots; clearing an equipped item restores those alternatives. Occupied slots
remain reachable. Unknown mod locations remain in Other equipment.

Carried inventory is a separate list for supplies/currency, with quantity,
pockets/bag destination and Add/Edit/Remove. It uses canonical startingItems and
the existing loaded-game/mod item explorer. Editing a carried item preselects
its type, quantity and destination. Equipment controls stay in equipment views.

Appearance uses the installed CharacterCreationAvatar's exact face settings:
zoom 14 and Y offset -.85. Other tabs use body settings (-3, 0) with separate
remembered zoom preferences. A copied face descriptor omits obscuring clothes;
the underlying NPC, body projection, appearance and saved loadout remain intact.

Installed CharacterCreationMain PLAYDEMOVOICE explicitly sets FMOD music state
InGame before resuming/playing the UI sound. The previous helper omitted that
routing state. The repaired helper follows the native sequence, installs voice
parameters and origin, owns only its handle, and restores MainMenu on stop or
completion. A shared lease prevents one Hoomans preview restoring the menu bus
while another is active. In-game debug playback leaves world music untouched.
Native playback determines success instead of a sound-catalog precheck.

Both preset browsers support Delete then Confirm delete for the selected record.
Changing/filtering away selection cancels stale confirmation. Deletion erases
the saved payload, removes the exact index record, and leaves a small deletion
marker file; it does not physically unlink the file. Both loaders and index
rebuilds reject that marker. Other namespaces, editing buffers, existing NPCs
and world death records survive. Deleted local encounter definitions leave the
future catalog. Remote library deletion independently requires admin access.

## Evidence

- Focused authoring/starter/Unique NPC/inventory/database/library suite:
  **65/65** passed. Full suite: **1058/1062**, with the same four known unrelated
  scene-route, context-scene, population initialization and translation failures.
- New behavioral regressions cover slot grouping/hide/restore, carried edits,
  face/body projection/camera restoration and selection-bound browser deletion.
  Extended database/library/audio tests cover payload erasure, namespace
  isolation, admin rejection, retained death state and native FMOD lifecycle.
- All 28 owned Lua files parse; all 21 production Lua files pass Kahlua error
  checks. Six new EN/TL keys, JSON/parity/placeholder/reference and whitespace
  checks pass. Graph coverage checked with direct changed/new source evidence;
  native Lua and a current Java baseline supplied engine contracts.
- No native game launch/control, audible success, rendered geometry or MP
  transport acceptance is claimed. No push or Workshop publication occurred.

## User-owned fresh-session retest

1. Open both creators at normal/compact resolution and large font scale. Switch
   body-part buttons; check counts, selected styling and scroll bounds. Forearm
   is in Hands, bra in Torso and long johns in Legs. Unknown mod slots stay reachable.
2. Equip an exclusive garment: its blocked empty alternatives should disappear.
   Clear it and verify they return. Equipped items always retain a clear action;
   valid layering slots should remain available. Try loaded mod equipment too.
3. In Carried items, add money, food and a bag. Edit quantity/destination,
   remove one entry, save/reload, and verify unrelated items and equipment survive.
4. Switch Appearance/Bio/Loadout/Attributes/Relationships. Check face framing
   only in Appearance, visible hair without obscuring headgear, body restoration,
   camera controls and unchanged appearance/loadout/preset data.
5. Before world entry, play/replay/stop voices at pitch endpoints and with a
   different selected style/sample. Verify audibility and menu music recovery
   after completion, tab change or close. In-game debug must not change paused
   gameplay/music state. Record exact sample/style and bounded console delta
   for any remaining failure.
6. In each saved-record browser, select/Delete/Confirm delete. Verify immediate
   disappearance and absence after restart. Arm Delete, change selection/filter,
   and ensure it cannot delete the old record. Cancel by dismissing the browser.
7. Confirm deleting a companion preset preserves NPC definitions and vice versa.
   Delete/recreate an encounter template and verify existing world death stays
   permanent. MP: ordinary clients cannot delete server-library records; an
   administrator can request deletion. Existing actors remain alive and intact.
8. Continue prior skin/save/library and SP/MP/co-op lifecycle acceptance matrices.


## P5R11 backpack-color regression

Developer-side continuity preserves captured bag tint/texture/decal across
inventory/body rebuilds, matching the same logical item and full type. Explicit
new visuals, different items and fresh generations still win; carried nonvisual
state is preserved. Focused **67/67**, full **1060/1064** (same four known failures).
The new regression fails at a carried-item edit when continuity is disabled.
Native rendering is unverified.

In both creators, note an existing backpack's color, then edit name, skin/hair,
voice pitch, carried contents and gender where allowed. Switch pages between
edits. The same backpack must retain its exact tint and texture. Deliberately
replace it, select a captured custom visual, and reroll Loadout: these actions
must still apply the requested/new visual. Save/reload and continue prior tests.


## P5R12 save-dialog and scope regression

Console session 65ae9e31/EDF66F8 confirmed SaveDialog.Open line 29 calls the absent
ISTickBox.setEnable. Native disableOption now governs the encounter checkbox;
submit independently rechecks current authority. Filename validation keeps bad
names correctable and Cancel dismissible. Focused 68/68 including catalogs;
full 1060/1064, same four known failures. Native interaction remains unverified.

1. Select a companion and choose Save NPC preset. The filename starts with its
   name; all tabs/loadout belong to the same preset. Rename, save, load and delete
   it. Try an invalid name, correct it, and separately Cancel without a write.
2. Finish editing through primary Done. Reopen and verify current companion
   edits remain even without saving a reusable preset. Invalid pending input
   must keep the editor open for correction.
3. Open Presets, then Save roster preset. This action must be absent from the
   editing toolbar and present even when there are no saved presets. Save with
   a custom filename, confirm the refreshed browser lists it, then load/delete.
4. Loadout uses Equip item / Add carried item / Update carried item, with hints
   explaining that these edit the current NPC. Save NPC preset saves the whole
   character, including its loadout, for reuse.
5. In SP the encounter checkbox is available; non-admin MP cannot select it.
   Admin MP may select it, with publication still enforced by the authority.
   Verify both local preset-only and authorized encounter export paths.
6. Repeat Presets at compact resolution/large fonts; the roster-save row must
   not overlap search/results or leak into item/outfit browsers. Debug Save NPC
   preset and Save encounter NPC use the same repaired filename dialog.


## P5R13 preset portraits, body map and weapons

Developer checks: 71/71 focused; full 1062/1066 with the same four known failures.
Native rendering/input/combat is unverified; test in a fresh game session.

1. Select saved single-NPC presets in both creators. The side portrait must show
   the saved NPC rather than the currently edited one. Try different skins,
   genders, clothing and exact weapons. Browsing and Cancel must not change the
   current companion, saved data or world registry.
2. Select a roster preset and cycle previous/next portraits and captions. Verify
   all members, current-player surname/skin/gender inheritance and stable looks
   on reselecting. Filter away/delete the selection: no old NPC should remain
   visible. Confirm side portrait/navigation at compact sizes and large fonts.
3. In Loadout click head, neck, torso, arms/hands, groin/waist, legs and feet.
   Appropriate grouped slots must appear. Equipped regions are green; clearing
   updates the map. Check both NPC genders, scaled/letterboxed clicks, scroll
   bounds, native exclusive-slot hide/restore and unknown mod equipment.
4. Bags and Inventory use the native open-box icon and open separate slot/list
   views. Add/change/remove a backpack and carried money/food. Verify capacity,
   destinations, exact colors and preset round trips.
5. Weapons opens primary/off-hand/attachments. Search vanilla and loaded mod
   weapons, equip and clear them, and verify saved/reloaded native item state.
   A two-handed primary must reject a conflicting off hand. Companion creation
   must not show melee/ranged generation buttons; debug retains labeled fallback.
6. With suitable ammunition, spawn an authored firearm NPC with random equipment
   disabled and verify ranged combat behavior; test a melee choice and clearing.
   Generated NPC pool/chance behavior and configured mixed firearm policy should
   remain intact. Continue MP admin/library and world-death acceptance separately.
