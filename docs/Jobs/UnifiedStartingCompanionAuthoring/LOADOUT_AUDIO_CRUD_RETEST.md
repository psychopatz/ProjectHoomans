# Loadout, framing, voice and saved records — P5R9

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
