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

## W0 evidence freeze (2026-10-22)

The actual local Hoomans worktree is `9d9dc454c6b39c4b0a6c7e6bcb4008a1f3da4fe4`, seven commits ahead of `origin/main` `26cab0dc41864d73dc8db8b386b183c081a373e8`, and has pre-existing staged/unstaged PNC changes. This audit did not touch those changes. Core runtime media and DT runtime media are intentionally excluded from the graph index; exact source was read directly after graph discovery.

The current user-visible lightweight zombie value is not Director “Resolved density”. It is the combat-debug/nameplate projection: `PNC_CombatTactics_ThreatAssessment.AssessThreat` consumes the cached perception/spatial result, `PNC_NetworkSnapshots_CombatDebugState_TacticalPayload` carries visible/nearby/pressure/horde counts, and `PNC_NameplateRenderer_DebugText` renders `THREAT ... horde=visible/total` and `VIEW zombies=visible/nearby`. `PNC_WorldCensus.Refresh` is the single cadence-bounded `getCell():getZombieList()` source; `PNC_SpatialIndex`, `PNC_Perception_Frame`, follower hazards, and combat all consume its cache. No WKG producer may enumerate zombies again.

Faction truth is committed in `FactionIncidentService.AddIncident`, `FactionService_Lifecycle.Destroy`/`OnNPCDeath`, and `FactionService_TreatyCommands` (`war_declared`, `peace_made`, `truce_started`, `alliance_formed`, `alliance_broken`). NPC death is committed by `PNC.Health.Kill`; `PNC_Health_Damage` and zombie wound code carry `attackerKind`/ID. Player and NPC attackers can be attributed through corpse awareness; zombie damage is authoritative at the damage event, but infection death currently loses the original event. WKG must publish `cause=unknown` when the owner cannot prove the cause.

The local Java baseline is Build `42.21`, so it is not accepted as exact Build 42.20 API proof. It found candidate owners `IsoWorld.helicopter:isActive()`, `IsoWorld:isHydroPowerOn()`, `ClimateManager:getSeasonName()`/season ID, and square-local `IsoGridSquare:haveElectricity()`. Current Hoomans has only a client environment season read and no authoritative fact adapters for helicopter, global power, water shutoff, or seasonal transitions. These remain W3 adapter work; no guessed hook was added.

The normal production path is `CognitionService.BuildForConversation` → `_memoryGossip` transport → client `CognitionClient.GetGossipContext` → bounded `npcGossip.statements` → `GOSSIP_RECEIVED`. The existing worker acceptance test and live `LuaSemanticWorker` before-state show supplied memory in EN/TL and truthful no-news with zero LLM calls. This evidence is explicitly pre-WKG and does not establish grounded facts.

Codebase-memory coverage generation `2026-10-07T23:10:40Z` had no recorded issue on the indexed authority paths, but marked current semantic/environment paths missing or metadata-changed; those were read from disk. Coverage is a best-effort signal and not an exhaustive proof.
