# Source Audit — Grounded World Knowledge & Gossip

Planning baseline: ProjectHoomans 2bcefd74d3c46df0f707467a7e9b8a6ba42cb185; Core 159df9e2f12cb4a3911f50d6c27dcc1d48a861fc; DynamicTrading 938721fa538a13845684acb22a5468fe0a9dc9e5.

## Confirmed

### Zombie observation is already bounded

docs/01_SYSTEM_MAP.md explicitly assigns population-wide zombie enumeration to PNC_WorldCensus and identifies PNC_Perception/PNC_Perception_Frame as nearby threat-counting/caching layers.

PNC_BehaviorCompanion_FollowHazards.lua:
- reuses PNC.SpatialIndex;
- keeps a short-lived shared candidate cache per follow owner;
- counts zombies after exact distance filtering;
- derives combatCount/count/nearestDistance;
- invokes PNC.SocialEventHooks.ObserveZombieHorde at a configured threshold.

PNC_SocialEventHooks_CombatAdapter_Awareness.lua:
- recognizes coarse count bands (few/several/large);
- dedupes one same-day relationship memory;
- stores source tags such as detected_by_follow/detected_by_combat;
- marks knowledgeSource = experienced;
- uses runtime-only presentation cooldowns;
- does not persist raw zombie lists.

Therefore new gossip code must reuse this family of data. A new getZombieList/global scan would violate current ownership.

### Faction incidents are authoritative and useful

Faction incident code recognizes member_killed and severe attack paths. Faction status vocabulary includes destroyed. Existing faction diagnostics/history and relation state are server-owned.

The new adapter should publish from actual committed incident/status transitions, not read UI text or infer from relationship score changes.

### Gossip semantic seam already exists

The current semantic pipeline:
- routes GOSSIP to GOSSIP_RECEIVED;
- checks context.npcGossip.statements;
- renders semantic.gossip.memory when statements exist;
- otherwise responds with truthful unknown/no-news fallback;
- optional PBrainZ context code reads the same statement projection.

This is the correct downstream seam to preserve while replacing manually/scenario-supplied statements with grounded production queries.

## Not established by this audit

The planning search did not establish one current authoritative Hoomans adapter for each of:
- helicopter active/recent state;
- electricity shutoff;
- water shutoff;
- current season/season transitions.

W0 must inspect the actual Build 42.20-facing code/API usage and Project Zomboid hooks before implementing those adapters. Do not create duplicate utility/season simulation or persist guessed state.

The audit also does not claim every NPC death currently carries a reliable typed killer/cause. W0 must map actual death/health/corpse/faction combat attribution and publish a cause only when authoritative evidence exists.

## Main missing layer

Hoomans has producers and a gossip consumer, but no verified portable pipeline:

authoritative event -> compact Core WorldFact -> legitimate actor acquisition -> bounded relevance projection -> existing gossip conversation.

That missing middle layer is the goal.
