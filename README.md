# ProjectHoomans

Standalone NPC framework for Project Zomboid Build 42.

This repository starts with a server-authoritative V1 slice:

- companion NPCs with `Follow`, `Guard`, and `Patrol`
- hostile NPCs with shared `Melee` and `Ranged` combat
- live/abstract presence switching with runtime body leases and automatic stale-body cleanup
- inert, lootable NPC corpses with persistent corpse identity and reanimation supervision
- phased zombie-bite recovery that releases the engine bump state on interruption or timeout
- multiplayer-safe authority flow with the same codepath used by singleplayer host
- an admin/debug-only NPC Monitor with lifecycle audits, filters, recovery controls, and overlay states

The framework is split into small subsystem files under `PNC/Core` so future work can extend jobs, behaviors, pathing, combat, and migration adapters without rebuilding the base.

NPC engine bodies are identified only by protected mod-data tags (`PNC_UUID`, body kind, and a runtime lease). Appearance, clothing, nakedness, and persistent outfit IDs are never authoritative identity. Save data uses schema v4 for corpse descriptors; live-body leases deliberately reset every session so bodies left behind by a prior session are quarantined before presence reconciliation.
