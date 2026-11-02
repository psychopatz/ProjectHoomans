# Audit — Current Semantic, Social and Adopter Boundaries

**Planning snapshot:** 2026-11-02. Re-audit current HEAD/status before implementation; this document records the planning evidence, not immutable truth.

## Verified foundation

PsychopatzCore already exposes a reusable semantic facade with IR, provider, dialogue state, normalization, registry, surface recovery, confidence, context, fuzzy/concept/pattern matchers, parser, dialogue router and dialogue turn.

Core's capability catalog already exposes `core.semantics`, `core.conversation`, `core.translation` and `core.actors`.

Core Actors already embeds a Social model. `PsychopatzSocial.lua` supports:

- stable target keys;
- approval, respect and familiarity;
- personality/personality overrides;
- bounded memories and recent event IDs;
- revisioning;
- server-authorized relationship events;
- serialization/validation.

The accepted Core NPC Foundation roadmap already names Core as canonical owner of directional relationships/personality/bounded memories and provider switching.

## Current Hoomans state

Project Hoomans still owns a much richer server-side relationship/social stack, including RelationshipService, social profile/event/encounter services, conduct, romance, personal boundaries, consequences and Hoomans event adapters.

Its relationship context reads and mutates `record.social`, with Hoomans-specific normalization/types/constants and richer memory fields.

Project Hoomans also owns extensive semantic application behavior: dialogue policy/flow, suggestions, action plans, task/inventory/world-target actions, cognition, combat reactions, social consequences and networking handlers.

Those gameplay-specific systems must not be moved wholesale into Core.

## Current Dynamic Trading state

DTCommon already depends on PsychopatzCore and MarketSense. DTAbstract depends on DTCommon/MarketSense and therefore receives Core transitively.

DTHoomans depends on ProjectHoomans for the optional physical/Hoomans adopter.

DTAbstract itself has no direct PNC gameplay dependency in the audited Lua search.

However, `DTHoomans_Conversation.lua` currently integrates with Project Hoomans semantic/conversation registries and APIs for trade/referral choices. That is valid for the optional DTHoomans bridge, but cannot remain the only route to rich trader conversation if DTAbstract is to stand alone.

Dynamic Trading already has a Core-backed provider adapter. It projects/acquires/materializes/dematerializes/releases/switches the same Core actor instead of inventing a separate person.

## Architectural gap

The remaining problem is authority/conversation convergence, not absence of primitives.

Today there are two overlapping social models:

1. Core Actor Social — intended shared authority.
2. Hoomans RelationshipService/social types — richer Hoomans runtime authority.

And the richest semantic content/flow/action runtime is still largely Hoomans-owned.

The job must therefore:

- establish one canonical shared relationship record in Core;
- retain Hoomans-only relationship concepts as Hoomans extensions/policies;
- promote only generic semantic/dialogue mechanisms from Hoomans where Core lacks them;
- convert Hoomans semantic systems into Core-registered adopter packs rather than Core dependencies;
- create Dynamic Trading semantic/content/action packs that work without Project Hoomans;
- preserve actor/social identity across adding/removing either adopter.

## Explicit anti-goals

Do not:

- move NPC follow/attack/camp/task/inventory gameplay actions into Core;
- move Dynamic Trading pricing/stock/budget/market rules into Core;
- duplicate relationship state by keeping independent DT and Hoomans scores;
- require Project Hoomans to get DT trader stories/small talk;
- make Core know trader, settlement, companion, faction or combat policy;
- destructively purge extension data when its owner mod is absent;
- rewrite accepted Core NPC Foundation/provider switching without evidence of a regression.
