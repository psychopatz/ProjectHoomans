# Health

## V1
- `PNC_Health` owns authoritative HP, incapacitation, wound-healing recovery, and engine-health buffering
- live NPCs keep engine health as a disposable buffer while custom HP remains the source of truth
- reaching `0` HP enters `incapacitated` instead of immediate death
- incapacitated NPCs keep a live body and show a pulsing overhead bar; there is no separate instant-revive state
- bandaged wounds restore HP gradually and the NPC returns to normal locomotion when authoritative HP reaches `INCAPACITATED_RECOVERY_HP` (5 by default)
- incapacitated bodies continuously enforce crawler, on-floor, and fall-on-front state on both the authority and remote clients; generic locomotion cannot overwrite the downed pose

## Body-Part Treatment

- `PNC_NPCWounds` owns authoritative wounds, body-part health, bleeding, bandage state, and Knox infection state.
- NPC bandaging queues a vanilla `Bandage` timed action on the treating client, including `EventBandage`, the first-aid sound, and the item progress indicator.
- Live NPC self-treatment uses the same `FirstAidApplyBandage` sound. Its treatment snapshot lets each remote client play that sound once, while a per-body transient key prevents duplicate playback on the authority client.
- Every successful authoritative bandage publishes a short-lived completion
  revision. Interested clients play the framework-owned
  `PNC_BandageComplete` 3D cue once from the treated NPC and deduplicate it by
  revision, timestamp, and body part. The audio is a vendored, renamed copy of
  Dynamic Trading's healing-completion cue, so Dynamic Trading is not a
  runtime dependency.
- No state changes when the action is queued. On completion, the host/server revalidates player range, NPC/wound state, debug permission, and the selected item before applying the bandage and consuming it.
- Player-to-NPC treatment uses the mid-height interaction pose (`Loot` /
  `LootPosition=Mid`) instead of the self-bandage animation. Range is checked
  before queueing, throughout the timed action, immediately before completion,
  and again by the authority.
- Treatment height follows the vanilla `LootPosition` action variable:
  incapacitated/on-floor patients and leg/groin/foot wounds use `Low`,
  head/neck wounds use `High`, and remaining standing-patient wounds use
  `Mid`.
- Cancelling, walking, running, losing the item, or leaving range prevents completion.
- Every wound stores its applied item type/name, healer First Aid level, gradual heal rate, dirty-bandage deadline, initial damage, and healed-point total. Better First Aid and better materials heal faster; dirty bandages pause healing until replaced.
- Authorized Health/debug menus show the remaining world-hour dirty timer, healed/initial/remaining points, and current heal rate. `Make Bandage Almost Dirty` moves the authoritative deadline to 0.02 world hours in the future so the normal transition can be tested without bypassing it.
- The old bulk revive command is a compatibility alias for bandaging every treatable wound. It consumes one accepted material per wound and never grants HP or changes incapacitation directly.

## NPC Self-Treatment

- `PNC_Behavior_Treatment` runs before combat/jobs whenever an NPC has an open wound or dirty bandage.
- A live NPC with a nearby enemy retreats first. It starts treatment only after the area is clear and immediately cancels the action, without consuming an item, if a threat closes inside the interruption radius.
- Live self-treatment uses the injured body part to choose `BandageHead`, left/right arm, upper/lower body, or left/right leg animation nodes.
- Recruited/player-owned companions consume accepted bandage or rag items from their canonical PNC inventory. Neutral and hostile NPCs have a virtual unlimited supply of ordinary ripped sheets.
- NPC First Aid is identity-seeded and progresses through the normal skill system; doctors receive an archetype bias. Skill level shortens the application action and improves gradual healing.
- Abstract NPCs use the same wound and inventory mutations on a coarse cadence without live pathing or animation. Recent combat postpones abstract treatment.
- Treatment phase, body part, and material are replicated in snapshots. Nameplates show active treatment/retreat status and the clean or dirty material currently on a wound.

## Bite Infection Lifecycle

- `NPCZombieBiteChance` still decides whether a successful zombie wound is a bite; combat resolution is unchanged.
- `NPCZombieInfectionChance` is a separate `0-100` roll performed only when a bite wound is created. `0` disables infection while preserving the bite and its damage.
- infection timing uses world age hours and progresses through `incubating`, `queasy`, `nauseous`, `fever`, and `terminal`
- fever temperature and later-stage health loss are derived from infection progress, making updates deterministic across save/load, multiplayer reconnects, and abstract presence
- fatal infection bypasses ordinary incapacitation and creates a vanilla corpse; after `NPCReanimationSeconds` (three real seconds by default), only the host/server calls the vanilla corpse-reanimation routine, which preserves the NPC's appearance and carried/worn items while producing one ordinary, vulnerable zombie
- ordinary and infected deaths retire the full NPC record immediately; only a compact name/location/token death marker remains until the engine corpse disappears or reanimates
- `PNC.API.ClearKnoxInfection(npcId, source)` is the authority-only cure integration seam. It removes the infection lifecycle but deliberately preserves the bite and all physical wound damage for normal treatment.
- debug menus can force an infected bite, jump to fever/terminal, trigger infection death, or clear Knox infection; the Health screen and snapshot dump expose infection status, progress, stage, fever, and temperature to authorized debug users

## Client Visuals
- live NPCs render overhead nameplates with their name and HP bar; exact HP numbers are intentionally hidden from both the nameplate and Health panel
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
