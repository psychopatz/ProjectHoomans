# Semantic Social Conversation Director

## Parent objective

Build an agnostic, performant social-conversation director that lets multiple Project Hoomans NPCs converse emergently by reusing the existing semantic interaction, affordance/choice, Scene Runtime, personality, relationship, knowledge and gameplay-authority systems.

The new layer decides **whether a socially meaningful conversation should happen, who should participate, who should speak next, what semantic motive is appropriate, and when silence is better**. It does not create a second conversation engine and it does not make dialogue authoritative over gameplay.

## Accepted foundation

Planning anchor: ProjectHoomans `56b77cf4eeae680cffac277fc416fe6591f95a82`.

The predecessor `SemanticInteractionSceneRuntime` job is developer-complete and already provides:
- one canonical autonomous/multi-actor Scene Runtime;
- explicit speaker/recipient/participant/observer roles;
- bounded semantic continuation without rendered-text reparsing;
- production actor projection;
- player observer/participant handoff;
- event-driven Opportunity admission;
- combat, grounded-social and non-combat adopters;
- bounded Scene Observatory diagnostics;
- hard scene/participant/turn/history limits.

This job extends that foundation. It must not replace it.

## Product outcome

When complete:
- companions, neutral survivors, settlement members, hostile/raider teams and other valid NPC actors use the same social-conversation machinery;
- multiple NPCs can participate in one coherent scene without pairwise scene explosion or chorus replies;
- NPCs reuse the same semantic affordance vocabulary that currently drives generated player response buttons;
- NPC semantic choices are ranked from grounded context such as personality, relationship, knowledge, condition, faction/team relation, recent events and current scene state;
- low-value situations commonly select silence;
- meaningful world/gameplay events can seed conversations without random fabricated facts;
- player observers can overhear without receiving choices, while directly addressed players continue using the existing semantic response surfaces;
- conversation effects route through existing relationship/knowledge/task/faction/gameplay authorities rather than mutating those domains directly;
- runtime remains event-driven, bounded, transient and free of routine LLM dependence.

## Documents

Read:
1. root `AGENTS.md`;
2. this `README.md`;
3. `ARCHITECTURE.md`;
4. `AGENT_RUNBOOK.md`;
5. `ROADMAP.md`;
6. `AUDIT.md` when establishing revision-specific evidence;
7. `HARNESS_ACCEPTANCE.md` for mandatory acceptance;
8. `PROGRESS.md` last.

Do not reread predecessor histories wholesale. Consult `docs/Jobs/SemanticInteractionSceneRuntime/` only for inherited contracts or disputed evidence.

## Completion boundary

D0-D8 in `ROADMAP.md` are mandatory developer-side work.

A phase/chunk completing is not parent-goal completion. After each accepted chunk, update `PROGRESS.md` and continue automatically to the next mandatory work.

Native Project Zomboid SP/MP conversational readability/timing remains user-owned after every developer-implementable gate is complete.
