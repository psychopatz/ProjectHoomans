# Skin and reusable-character persistence — P5R8

The user's P5R7 native retest showed a selected skin swatch disagreeing with the
portrait, nearly invisible disabled gender icons, trait-named preset saves and
no route from saved companions into reusable world encounters. Their screenshot
also reports `invalid_appearance:exclusive_slots:base:shorts:base:pants`.
The latest console session (`4d733f13`, installed PZ42.22.2) has startup font/fluid
errors but supplies no editor Lua exception for this action.

## Causes and repaired behavior

Native/materialized clothing could contain mutually exclusive slots, and a
retained preview could add an old garment into a new canonical candidate. Both
could make an unrelated tone/name transaction fail. Captured wear operations
now replace exclusive earlier garments, and pending policies outrank stale
preview garments. Manually authored conflicting choices are still rejected.

A native texture choice could also regain dark RGB from SurvivorFactory, or
retain RGB in a reused runtime record after adapter rebind removed its authoring
flag. The factory and retained-record paths now suppress that fallback. Core's
portrait descriptor sets the matching native index and neutral tint when RGB is
absent, preserving explicit inherited/custom RGB. This is grounded in installed
HumanVisual and vanilla creation APIs. Native setEnable also tints icons to .3;
read-only gender restores icon contrast and keeps native input disabled.

Both hosts now ask for an editable filename, defaulted to the NPC's name. Save
sources are captured before opening the dialog. Single-character saves offer
**Include in world encounters**. Companion templates keep sparse inherited
intent; an independent exact character snapshot is saved in the same data-only
format/namespace as produced Unique NPCs. It captures the reviewed body,
clothing/item state and gear without copying runtime IDs or identity cards.

The authority discovers only produced files into the existing unique pool;
ordinary drafts and starter presets remain authoring data. Existing chance
(0.005), reservations and per-world death state are preserved. User decision:
**permanent death within a world; reusable in other worlds**. Reloading or
updating the file does not resurrect its dead identity in that world. The
library file is retained. Exported encounter characters are independent of the
player-bound relationship template; they carry no relationship grant.

Multiplayer client files are never automatically registered. A remote publish
requires an admin player in the UI and again on the authority. Accepted admin
requests persist a server copy through the existing debug command boundary.
A server may also read its own administrator-controlled definition directory.
No server/client bypass or native game test was performed.

## Verification

- Hoomans focused **62/62**; full **1055/1059**, same four previously recorded
  scene-route/context-scene/population/translation failures.
- Core portrait smoke passes, including native index, neutral default tint and
  explicit custom tint preservation.
- Hoomans 24 owned Lua syntax/17 production Kahlua checks, Core two syntax/one
  Kahlua check, six new EN/TL keys, JSON/key/placeholder/reference parity and
  whitespace checks pass. Coverage checked; dirty/new code read directly.

## User-owned fresh-session retest

1. Restart the installed game so both Hoomans and Core Lua changes load. Select
   Friend and change tone 1/5/2 repeatedly; change tab/NPC and reopen. Verify
   portrait, swatch and saved/reloaded character agree. Repeat with family
   inherited tone, then change the player's tone and verify inheritance.
2. Test generated outfits and loadout dice, including shorts/pants outfits. Edit
   tone/name afterward. Verify no exclusivity rejection from stale clothing;
   intentional manual conflicts still give a controlled validation message.
3. Check fixed-gender icons, green selected backgrounds, locks/tooltips and
   blocked input at compact/large-font sizes.
4. Save a single NPC: verify NPC-name default, type another filename, Cancel,
   Save, reopen browser and load. Save a whole set under a custom name. Verify
   scope and sparse inheritance remain correct on another player character.
5. Include one NPC in world encounters; inspect it through the Unique NPC
   creator and authority registry. Its appearance/gear should match the reviewed
   snapshot. Normal encounter chance is low; use existing admin diagnostics to
   inspect registration rather than expecting immediate normal spawning.
6. Kill a spawned unique character, reload the same world and verify it remains
   dead/unavailable. In a different world, the retained template is eligible.
7. MP: ordinary player cannot enable/publish library characters. Admin can
   produce an accepted server copy; verify server storage/catalog and subsequent
   reload. Confirm a regular player's local produced file is never auto-imported.
8. Continue the prior voice/browser and SP/MP/co-op lifecycle matrix. These
   native outcomes remain unverified by developer harnesses.
