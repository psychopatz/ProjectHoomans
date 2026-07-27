# Health

## V1
- `PNC_Health` owns authoritative HP, incapacitation, timeout-to-death, and engine-health buffering
- live NPCs keep engine health as a disposable buffer while custom HP remains the source of truth
- reaching `0` HP enters `incapacitated` instead of immediate death
- incapacitated NPCs stop pathing/combat, keep a live body, and show a pulsing overhead bar until healed or timeout
- incapacitated bodies continuously enforce crawler, on-floor, and fall-on-front state on both the authority and remote clients; generic locomotion cannot overwrite the downed pose

## Body-Part Treatment

- `PNC_NPCWounds` owns authoritative wounds, body-part health, bleeding, bandage state, and Knox infection state.
- NPC bandaging queues a vanilla-style timed action on the treating client. It uses the other-patient `Loot/Mid` first-aid pose, bandage sound, and item progress indicator.
- No state changes when the action is queued. On completion, the host/server revalidates player range, NPC/wound state, debug permission, and the selected item before applying the bandage and consuming it.
- Cancelling, walking, running, losing the item, or leaving range prevents completion.

## Bite Infection Lifecycle

- `NPCZombieBiteChance` still decides whether a successful zombie wound is a bite; combat resolution is unchanged.
- `NPCZombieInfectionChance` is a separate `0-100` roll performed only when a bite wound is created. `0` disables infection while preserving the bite and its damage.
- infection timing uses world age hours and progresses through `incubating`, `queasy`, `nauseous`, `fever`, and `terminal`
- fever temperature and later-stage health loss are derived from infection progress, making updates deterministic across save/load, multiplayer reconnects, and abstract presence
- fatal infection bypasses ordinary incapacitation and creates a vanilla corpse; after `NPCReanimationSeconds` (three real seconds by default), only the host/server calls the vanilla corpse-reanimation routine, which preserves the NPC's appearance and carried/worn items while producing one ordinary, vulnerable zombie
- ordinary and infected deaths retire the full NPC record immediately; only a compact name/location/token death marker remains until the engine corpse disappears or reanimates
- debug menus can force an infected bite, jump to fever/terminal, or trigger infection death; the Health screen and snapshot dump expose infection status, progress, stage, fever, and temperature to authorized debug users

## Client Visuals
- live NPCs render overhead nameplates with name, HP text, and HP bar
- incapacitated NPCs use a pulsing red bar variant
- AI debug overlay can be toggled from the NPC monitor, Project Hoomans settings, or the PsychopatzCore debug hub
- each debug overlay component (presence, AI, job, order, target, combat,
  stamina, block reason, infection, and animation) can be enabled separately
  in Project Hoomans' in-game settings
- infected NPCs receive a separate red debug line with infection stage, fever,
  and temperature; healthy NPCs do not get an infection line

## Corpse Appearance
- before corpse conversion, visual-only outfit entries are materialized as real inventory items and assigned to worn body locations
- the canonical inventory always includes `Base.IDcard`, named `ID Card: <NPC name>` and tagged with the NPC UUID/name for future quest validation
- live clothing visuals are copied to those items so texture and tint survive conversion
- the authoritative corpse finalizes worn slots before its complete item state is transmitted to multiplayer clients

## Next Expansion

- floating damage numbers and richer faction/relation coloring
