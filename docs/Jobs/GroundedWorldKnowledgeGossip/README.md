# Project Hoomans Adoption — Grounded World Knowledge & Gossip

Status: PLANNED / implementation not yet accepted.
Canonical cross-repository goal: PsychopatzCore Docs/world_knowledge_gossip/.
Project Hoomans role: authoritative Hoomans/PZ world-fact producers, dissemination policy, semantic realization and Semantic Lab acceptance.

This job does not create a second knowledge system. Core owns reusable WorldFact/actor-knowledge mechanism. Hoomans owns the meaning and authority of Hoomans facts.

## Verified reusable seams at planning baseline 2bcefd74d3c46df0f707467a7e9b8a6ba42cb185

- docs/01_SYSTEM_MAP.md states PNC_WorldCensus owns population-wide loaded-zombie enumeration; PNC_SpatialIndex and PNC_Perception_Frame reuse it for bounded nearby threat counting.
- PNC_BehaviorCompanion_FollowHazards.lua performs short-lived cached zombie-density sensing and calls PNC.SocialEventHooks.ObserveZombieHorde.
- PNC_SocialEventHooks_CombatAdapter_Awareness.lua already records compact experienced zombie_horde_encounter memories, coarse count bands and bounded runtime cooldowns.
- FactionIncidentService already handles incidents including member_killed and severe attacks; faction status includes destroyed and diplomacy history/relations are authoritative Hoomans state.
- Relationship/social systems already store bounded event memories.
- Semantics already recognizes GOSSIP, uses GOSSIP_RECEIVED and renders supplied context.npcGossip.statements, capped to a small number.
- PNC_PBrainZ_ContextPayload_DialogueFacts.lua already consumes the same npcGossip statement projection.
- Existing Semantic Lab production Lua worker and GUI are the mandatory test surface.

## Product outcome

NPCs should be able to discuss real nearby/world/faction events they legitimately know: faction loss/destruction, who/what killed a member when authority can prove it, zombie pressure, helicopter activity, power/water shutoff, season and later adopter-provided facts. Unknown or undiscovered truth remains unavailable.

No randomized baseless gossip is an acceptance path.

## Read order

1. root AGENTS.md
2. PsychopatzCore Docs/world_knowledge_gossip/AGENT_RUNBOOK.md
3. PsychopatzCore Docs/world_knowledge_gossip/PROGRESS.md
4. this README
5. AUDIT.md
6. ADOPTION.md
7. Core ARCHITECTURE/ROADMAP/HARNESS_ACCEPTANCE
8. existing ContextualDialogueQuestFramework and ContextualSemanticSuggestions docs where their shared conversation/Semantic Lab contracts are touched

Do not commit a GOAL_PROMPT.md. The executable /goal is chat-only.
