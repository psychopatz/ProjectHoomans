# ProjectHoomans Master Plan

## Current V1 Slice
- server-authoritative NPC registry and persistence
- live and abstract presence states
- body removal on abstraction to prevent zombie husks
- colonist `Follow`, `Guard`, `Patrol`
- hostile `Hunt` and `Roam`
- shared melee and ranged combat with atomic combat files
- zombie aggro bridge so zombies can acquire embodied NPCs
- custom HP, body-part wounds, bandage-driven incapacitation recovery, and stamina
- seeded identity, archetype registry, and compact inventory persistence
- v14 compact health/inventory/stamina/social/affiliation persistence with save-time dirty
  snapshots and a 100-NPC/4,000-acquired-item scale gate
- sparse, directed NPC-to-NPC and NPC-to-player-character relationship records
  with deterministic memories, decay, and hysteresis-aware social states
- centralized Phase 2 health/combat social events with bounded dedupe,
  cooldown/saturation controls, verified rescue attribution, and runtime-only
  encounter aggregation
- Phase 3A server-authoritative player-character UUID registry with persistent
  survivor mirrors, reconnect/death/new-survivor separation, claim validation,
  and centralized social entity-key resolution
- Phase 3B UUID-owned player social profiles, Build 42 character-creation
  traits, deterministic NPC personalities, and observer-only modifiers for new
  instances of the five existing social events
- Phase 4 actor-owned player/NPC conduct with seven objective dimensions,
  deterministic decaying evidence, accepted-event integration, and
  admin/debug inspector presentation
- Phase 5A persistent organizational faction registry, data-only settler,
  looter, trader, and refugee archetypes, NPC affiliation/role/rank,
  leadership, archival, and guarded faction inspection
- Phase 5B stable player-owned factions, directed opinion/incident records,
  deterministic archetype policy, symmetric official treaties, policy-aware
  escalation/intent, and a centralized bridge to legacy companion/combat
  behavior
- shared world census, numeric spatial cells, budgeted active-zombie aggro,
  cached perception frames, and staggered LOD scheduling
- right-click debug spawning, NPC selection hub, and character window

## Immediate Next Steps
- execute the documented SP, hosted, and dedicated player-identity, trait,
  profile, conduct, relationship, faction, and inspector validation matrices
  before expanding social attribution
- smoother live motion and tighter SP/MP parity for chase and follow
- richer animation bindings and better weapon-specific timing
- better ranged aim, muzzle/projectile treatment, and combat diagnostics
- more complete obstacle handling for windows, doors, and future fence traversal
- migration adapter layer for DynamicTrading
- deeper medical/body-part gameplay plugged into the NPC character window shell
- profile real 25-live and 100-NPC multiplayer sessions using the new
  debug-only counters before tuning the conservative default budgets
