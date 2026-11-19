# Roadmap

## Objective

Guarantee one canonical survivor-world generation and presence path across
PsychopatzCore, Project Hoomans, and Dynamic Trading. Core owns generated
factions, communities, groups, actors, generation provenance, persistence, and
the shared presence-debug coordinator. Hoomans and Dynamic Trading project
those actors through provider-specific compatibility/physical lifecycle views.

## Gates

1. Core server composition wires an idempotent startup bootstrap.
2. Core exposes reusable community/group generation commit seams.
3. Hoomans hydrates Core SurvivorWorld actors into PNC records before monitor
   and lifecycle consumers inspect the roster.
4. Hoomans population commits use Core seams whenever the Core cutover is
   active; the legacy PNC generator remains only as a compatibility fallback.
5. Dynamic Trading abstract and Hoomans provider handoff preserves one Core
   actor identity and does not duplicate generation.
6. Core owns one centrally persisted, access-controlled presence-debug gate,
   session rollback ledger, and map override action; providers expose only
   physical lifecycle callbacks.
7. New-save and restart validation proves map hover, NPC monitor, physical
   materialization, debug release rollback, and provider hotswap behavior in
   the live game.

## Superseded implementation detail — eager Hoomans hydration

Gate 3 recorded the transition-era requirement that Hoomans could project Core actors before Hoomans consumers inspected them. It must **not** be interpreted as a permanent requirement to bulk-create one full PNC record for every Core actor. The accepted Compact Survivor World contract is newer and authoritative: abstract Core actors stay compact, while Hoomans rich runtime is promoted lazily when physical/gameplay responsibility requires it. The active remediation is documented in [Lightweight NPC Runtime](../LightweightNPCRuntime/README.md).

Do not preserve `HydrateCoreActors()` startup/full-registry behavior merely to satisfy this historical gate. Preserve actor identity/provider parity while replacing eager hydration with lazy projection/promotion.

## Current phase

Source implementation and focused harness tests are complete. The remaining
phase is live new-save/restart/provider-handoff validation. After live
evidence, narrow or remove the compatibility fallback.
