# Semantic Interaction Scene Runtime

This job productionizes the existing generic semantic interaction-scene foundation so NPCs, players, world events and future gameplay systems can participate in one bounded semantic conversation framework.

## Parent objective

Make autonomous and multi-actor conversation a first-class subsystem of the existing semantic architecture rather than a collection of combat-, faction-, settlement-, gossip-, trading- or task-specific dialogue systems.

The subsystem must support:
- NPC -> NPC;
- NPC -> player;
- player -> NPC;
- multi-NPC scenes;
- world/faction/task/social event stimuli;
- observer-only nearby players;
- bounded semantic continuation across turns;
- shared Interaction Director / Pragmatic Resolver / Dialogue Content;
- event-driven admission and LOD;
- transient-by-default NPC scene state with no rendered transcript persistence.

Combat squad talk is a required production adopter, not the definition of the subsystem.

## Audit conclusion

The core is **not missing**. Project Hoomans already contains a tested generic foundation:

- `PNC_SemanticInteractionStimulus`;
- `PNC_SemanticInteractionProviders`;
- `PNC_SemanticInteractionContext`;
- `PNC_SemanticPragmaticResolver`;
- `PNC_SemanticInteractionDirector`;
- `PNC_SemanticInteractionPlan`;
- `PNC_SemanticInteractionPresentation`;
- `PNC_SemanticInteractionScene`;
- `PNC_SemanticInteractionScheduler`;
- `PNC_SemanticInteractionCatalog`.

`PNC_SemanticInteractionScene.lua` is already explicitly a bounded semantic scene for NPC-to-NPC and multi-NPC interaction. Existing tests prove grounded memory/news sharing, personality-sensitive follow-ups, world-event interruption, targeted multi-NPC turns, bounded semantic history and semantic-only LOD.

The missing work is **productionization and unification**:
- no production Project Hoomans actor adapter is registered for scenes;
- there is no global production scene runtime/registry;
- selected NPC behavior does not yet generically become the next semantic scene turn;
- actor/recipient/observer transport is not a first-class production contract;
- the useful generic stimulus types are mostly unused outside tests;
- current player conversation and autonomous scenes share the semantic Director but use different session frontends;
- combat/faction/team use cases still need adopter adapters rather than their own conversation engine;
- no Scene Observatory exists for live production state.

## Core architecture rule

**One semantic reasoning substrate, multiple bounded frontends.**

The existing player conversation session remains the mature player-facing frontend for typed input, buttons, response windows and durable player/NPC continuity.

The Interaction Scene Runtime becomes the autonomous/multi-actor frontend for bounded NPC/NPC and event-driven scenes.

Both reuse the same semantic:
- stimuli and envelopes;
- providers/evidence;
- pragmatic relations;
- Interaction Director;
- behavior/beat catalog;
- InteractionPlan;
- Dialogue Content / realization;
- gameplay authority boundaries.

Do not rewrite the player conversation UI merely for architectural symmetry.

## Product consequences

A future feature should not implement “NPC dialogue logic.” It should normally register or expose:
1. a grounded semantic opportunity/event/fact;
2. eligible actors/targets or a bounded participant source;
3. semantic behaviors/beats/content if existing ones are insufficient;
4. optional authorized gameplay intent integration.

Examples:
- combat: horde warning / tactical proposal / acknowledgement;
- gossip: grounded news / follow-up / reaction;
- community excursion: member-away news / return question;
- task coordination: request / accept / decline / acknowledgement;
- faction event: warning / challenge / reconciliation;
- settlement social scene: memory disclosure / follow-up.

The generic runtime owns scene lifecycle, turn limits, targeting, continuation, LOD, suppression and observability.

## Planning base

ProjectHoomans `47aaad69`, existing `main`.

The earlier combat-shaped successor plan was replaced by this broader goal before production work began; there is no competing active NPC-group-conversation job.

The completed `SemanticCombatBanterTacticalIntent` job remains accepted foundation and later becomes a combat adopter of this runtime; B0-B9 must not be reopened.

Read:
- `AUDIT.md` for verified current code;
- `ARCHITECTURE.md` for stable ownership;
- `ROADMAP.md` for mandatory S0-S8 implementation;
- `HARNESS_ACCEPTANCE.md` for developer acceptance;
- `AGENT_RUNBOOK.md` for execution rules;
- `PROGRESS.md` last for the current exact chunk.
