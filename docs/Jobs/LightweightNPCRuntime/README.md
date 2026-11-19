# Lightweight NPC Runtime

## Objective

Make Project Hoomans lightweight during ordinary gameplay without sacrificing server authority, multiplayer robustness, deterministic NPC identity, physical NPC fidelity, or the already accepted NPC replication protocol.

The runtime must scale with **currently relevant physical Hoomans work**, not with the total number of compact PsychopatzCore SurvivorWorld actors.

The key correction is architectural:

- PsychopatzCore remains the canonical durable actor/world authority.
- A compact abstract Core actor is **not** automatically a full Hoomans record.
- Project Hoomans promotes an actor into rich physical runtime only when a Hoomans-owned gameplay responsibility actually needs it.
- Project Hoomans persists only Hoomans-owned durable extension state for Core-backed actors. It must not duplicate Core identity, appearance, inventory, social/persona, world, or provider authority.
- Logical gameplay commits mark/coalesce dirty state; they do not synchronously scan every NPC and flush all GlobalModData during ordinary mutations.
- Full network snapshots are repair/detail tools, not the default response to every mutation event.
- Profiling is observational and bounded. Deep hot-path wrapping must never be a normal-play tax.

## Why this goal exists

A native new-save audit on 2026-11-20 found approximately 32 Core/Hoomans NPC records, only 6 live Hoomans bodies, about 63 loaded ordinary zombies, and roughly 18 FPS while PsychopatzProfiler performance capture was active.

The audit found four high-confidence architectural problems:

1. server startup and generated-view refresh call `HydrateCoreActors()`, which promotes every Core survivor into a full `PNC.Types.NewRecord` and `PNC.Registry.AddRecord`, even when the actor remains abstract;
2. Core-backed records receive Core's canonical appearance envelope, while the old Hoomans record serializer still requires the Hoomans appearance-policy schema, causing `SerializeRecord()` to return nil and leave records dirty;
3. `PersistenceCoordinator.Commit()` synchronously reaches `Registry.FlushDirty()` and `GlobalModData.save()`, while `FlushDirty()` scans persistent records for save-snapshot changes; ordinary logical commits can therefore become broad persistence work;
4. most non-`tick` replication events still fall through to a full NPC snapshot even when only one domain changed.

Detailed performance capture also installed more than one hundred Project Hoomans timer wrappers and recorded tens of thousands of wrapped calls. That capture is useful evidence, but it is not a clean normal-play baseline.

See [AUDIT.md](AUDIT.md), [ARCHITECTURE.md](ARCHITECTURE.md), [ROADMAP.md](ROADMAP.md), [AGENT_RUNBOOK.md](AGENT_RUNBOOK.md), [PROGRESS.md](PROGRESS.md), and [HANDOFF.md](HANDOFF.md).

## Scope

Primary repository:

`/home/psychopatz/Zomboid/Workshop/ProjectHoomans`

Required participant repository when shared profiler/Core contracts change:

`/home/psychopatz/Zomboid/Workshop/psychopatzCore`

DynamicTrading is not an automatic edit target. Verify it only when a changed Core provider/actor contract could affect provider handoff or abstract-world consumers.

## Non-goals

- Do not reopen or replace accepted NPCReplicationScaling P1-P4 portrait work.
- Do not lower NPC population as the solution.
- Do not add compatibility shims, permanent dual writes, legacy serializers, or a second actor/world authority.
- Do not move Hoomans physical AI/combat/pathing into Core.
- Do not make far abstract actors run Hoomans needs/combat/pathing merely to keep their map/portrait representation available.
- Do not micro-optimize FollowOwner, stamina, or individual AI helpers from a profiler-contaminated capture before a clean profiler-OFF baseline exists.
- Do not launch native Project Zomboid unless the user explicitly assigns live acceptance; complete every developer-side gate first.
