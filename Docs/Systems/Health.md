# Health

## V1
- `PNC_Health` owns authoritative HP, incapacitation, timeout-to-death, and engine-health buffering
- live NPCs keep engine health as a disposable buffer while custom HP remains the source of truth
- reaching `0` HP enters `incapacitated` instead of immediate death
- incapacitated NPCs stop pathing/combat, keep a live body, and show a pulsing overhead bar until healed or timeout

## Client Visuals
- live NPCs render overhead nameplates with name, HP text, and HP bar
- incapacitated NPCs use a pulsing red bar variant
- AI debug overlay can be toggled from the right-click `PNC Debug` menu
- debug overlay shows `aiState`, active job, order, and current target type

## Next Expansion
- teammate/player revive interactions
- incapacitated-specific pose/crawl presentation
- floating damage numbers and richer faction/relation coloring
