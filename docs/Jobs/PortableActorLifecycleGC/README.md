# Portable Actor Lifecycle & GC — Project Hoomans Adoption

**Status:** PLANNED participant work.
**Parent:** PsychopatzCore Docs/portable_actor_lifecycle_gc/.
**Role:** bridge Hoomans death/corpse/bond/faction/semantic state to Core lifecycle/GC without creating another generic tombstone or GC authority.

## Objective

Keep the existing rich Hoomans death experience while ensuring dead/permanently retired NPCs do not leave full PNC/Core actor state forever.

Current PNC DeathMarkers remain Hoomans-owned lightweight corpse/colony/reanimation records. They do not become a general social-history database.

On death, Hoomans must:

1. perform authoritative health/corpse/social consequences;
2. retire the canonical Core actor/ref;
3. remove the full PNC live NPC record;
4. retain only Hoomans domain state that genuinely needs to survive;
5. expose bounded GC roots for corpse/bond/quest/faction/memorial identity;
6. let Core collect historical identity when those roots and meaningful survivor social refs disappear.

A survivor remembering a dead NPC does not require the dead NPC's full record. Survivor memories/relationships remain in Core social state. The dead NPC becomes at most a tiny Core tombstone plus separately justified PNC corpse/death-marker state.

## Preserve

- PNC Health.Kill ordering;
- CorpseAwareness/death social events;
- corpse inventory/worn-item/reanimation behavior;
- colony-visible DeathMarkers;
- Hoomans-specific bonds/romance/conduct/factions/quests;
- Core Portable Social State;
- semantic evidence/conversation consumers.

Do not make ordinary unowned deaths permanent cemetery entries.
