# ProjectHoomans Integration — Compact Survivor World Runtime

Authoritative parent goal: PsychopatzCore `Docs/survivor_world_runtime/`.

ProjectHoomans is an adopter, not the canonical owner.

## Hoomans responsibilities retained

- live body lifecycle;
- physical AI/combat/needs/pathing;
- animations/perception;
- facilities/jobs and Hoomans gameplay policy;
- caravan composition/equipment policy;
- physical inventory/body synchronization;
- physical interaction UI/conversation.

## Migration responsibilities

ProjectHoomans must migrate reusable world mechanisms to the Core contracts defined by the parent job:

- population/faction/community/group registries;
- generic generation;
- group travel state;
- WorldDiscovery;
- generic per-actor map presentation.

Hoomans then hydrates/dehydrates compact Core actors instead of owning a second persistent survivor world.

## Compactness invariant

Do not persist physical runtime into Core merely because a body exists.

On dematerialization, return only explicitly durable deltas. Inventory must compact to the smallest safe Core persistence mode.

## Execution

Read ProjectHoomans root AGENTS.md, then the authoritative Core job README, AUDIT, ARCHITECTURE, COMPACT_PERSISTENCE, ROADMAP, HARNESS_ACCEPTANCE, AGENT_RUNBOOK, and PROGRESS last.

Do not create a parallel Hoomans roadmap for the same parent goal. Record adopter-specific evidence here only if needed; parent phase truth stays in Core.
