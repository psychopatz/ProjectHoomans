# ProjectHoomans

Standalone NPC framework for Project Zomboid Build 42.

This repository starts with a server-authoritative V1 slice:

- colonist NPCs with `Follow`, `Guard`, and `Patrol`
- hostile NPCs with shared `Melee` and `Ranged` combat
- live/abstract presence switching with runtime body leases and automatic stale-body cleanup
- inert, lootable NPC corpses with persistent corpse identity and reanimation supervision
- phased zombie-bite recovery that releases the engine bump state on interruption or timeout
- body-part wounds with vanilla-style timed bandaging and server-side item consumption
- configurable bite infection, staged fever and health decline, infection death, and corpse reanimation
- multiplayer-safe authority flow with the same codepath used by singleplayer host
- an admin/debug-only NPC Monitor with lifecycle audits, filters, recovery controls, and overlay states

The framework is split into small subsystem files under `PNC/Core` so future work can extend jobs, behaviors, pathing, combat, and migration adapters without rebuilding the base.

NPC engine bodies are identified only by protected mod-data tags (`PNC_UUID`, body kind, and a runtime lease). Appearance, clothing, nakedness, and persistent outfit IDs are never authoritative identity. Save data uses schema v5 with persistent corpse descriptors; live-body leases deliberately reset every session so bodies left behind by a prior session are quarantined before presence reconciliation.

The `NPC Bite Infection Chance (%)` sandbox option is evaluated only after a
zombie attack has already produced a bite. Setting it to `0` disables Knox
infection without altering combat, bite frequency, or the resulting bite wound.
Infection mortality and reanimation delay remain separately configurable.
