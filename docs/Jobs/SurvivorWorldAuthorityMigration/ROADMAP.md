# Roadmap

## Objective

Guarantee one canonical survivor-world generation path across PsychopatzCore,
Project Hoomans, and Dynamic Trading. Core owns generated factions,
communities, groups, actors, generation provenance, and persistence. Hoomans
projects those actors into its compatibility/physical lifecycle views.

## Gates

1. Core server composition wires an idempotent startup bootstrap.
2. Core exposes reusable community and group generation commit seams.
3. Hoomans hydrates Core SurvivorWorld actors into PNC records before monitor
   and lifecycle consumers inspect the roster.
4. Hoomans population commits use Core seams whenever the Core cutover is
   active; the legacy PNC generator remains only as a compatibility fallback.
5. Dynamic Trading abstract and Hoomans provider handoff preserves one Core
   actor identity and does not duplicate generation.
6. New-save and restart validation proves map hover, NPC monitor, physical
   materialization, and provider hotswap behavior in the live game.

## Current phase

Phase 1 is complete in source and focused harness tests. Phase 2 is the live
new-save/restart/provider-handoff validation. Phase 3 can remove or narrow the
compatibility fallback after downstream consumers have been observed on the
Core path.
