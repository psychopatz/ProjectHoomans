# Health

## V1
- `PNC_Health` owns authoritative HP, incapacitation, timeout-to-death, and engine-health buffering
- live NPCs keep engine health as a disposable buffer while custom HP remains the source of truth
- reaching `0` HP enters `incapacitated` instead of immediate death
- incapacitated NPCs stop pathing/combat, keep a live body, and show a pulsing overhead bar until healed or timeout
- incapacitated bodies continuously enforce crawler, on-floor, and fall-on-front state on both the authority and remote clients; generic locomotion cannot overwrite the downed pose

## Client Visuals
- live NPCs render overhead nameplates with name, HP text, and HP bar
- incapacitated NPCs use a pulsing red bar variant
- AI debug overlay can be toggled from the right-click `PNC Debug` menu
- debug overlay shows `aiState`, active job, order, and current target type

## Corpse Appearance
- before corpse conversion, visual-only outfit entries are materialized as real inventory items and assigned to worn body locations
- live clothing visuals are copied to those items so texture and tint survive conversion
- the authoritative corpse finalizes worn slots before its complete item state is transmitted to multiplayer clients

## Next Expansion
- teammate/player revive interactions
- floating damage numbers and richer faction/relation coloring
