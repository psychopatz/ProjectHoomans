# Progress — Semantic Interaction Scene Runtime

**Status:** PLANNED / NOT IMPLEMENTED — S0 baseline and productionization contracts are next.

**Planning base:** ProjectHoomans `47aaad69`, existing `main`.

## Accepted foundation

Do not rebuild these:
- generic `InteractionStimulus`;
- `InteractionProviders` and semantic evidence;
- `PragmaticResolver`;
- `InteractionDirector`;
- generated `InteractionCatalog`;
- `InteractionPlan`;
- `InteractionPresentation`;
- `InteractionScene`;
- `InteractionScheduler`;
- player semantic conversation/lifecycle;
- completed combat-banter B0-B9.

The current scene smoke already proves NPC-to-NPC semantic interaction in isolation.

## Current verified gaps

- production Project Hoomans NPC actor adapter is not registered;
- InteractionScene usage is test-only/not wired as a production runtime;
- each Scene currently constructs an isolated scheduler, so there is no global active-scene budget;
- generic semantic continuation across NPC turns is absent;
- recipient vs observer is not a complete production transport contract;
- generic opportunity stimulus types are mostly dormant;
- player conversation and scenes share Director logic but lack formal runtime interop;
- no generic Scene Observatory exists;
- combat group conversation should be an adopter, not a separate exchange engine.

## ONE current Next Chunk — S0A

Establish production-grounded baselines without changing production semantics.

S0A must:
1. run and capture existing InteractionScene/Scheduler/Provider/Director-focused Lua baselines;
2. capture current Scheduler constants, LOD policy and per-scene scheduler construction;
3. prove normal player DialoguePolicy uses the same InteractionDirector as scenes;
4. enumerate current canonical InteractionCatalog beats/behaviors and stimulus indexes;
5. prove actor adapters are test-only;
6. capture player-pair lifecycle key/storage shape and why it must not become NPC transcript storage;
7. trace current NPCSpeech actor/target envelope through server/client presentation and identify where player audience is assumed;
8. mechanically show dormant `AMBIENT_SOCIAL_OPPORTUNITY / FACTION_EVENT / TASK_EVENT / ACTOR_JOINED / ACTOR_LEFT` production usage;
9. add static tests/contracts preventing generated-text reparsing, per-NPC polling and transcript persistence;
10. record exact evidence in this file and then continue to S1 automatically.

No production behavior change should occur in S0A except minimal observability/test seams needed to prove current contracts.

## Remaining mandatory phases

S0 baseline -> S1 production actor adapter -> S2 global Scene Runtime/admission -> S3 semantic continuation -> S4 recipient/observer/player handoff -> S5 opportunity providers -> S6 three production adopters -> S7 Scene Observatory -> S8 extensibility/scale/full acceptance.

## Native status

No new native validation exists for this goal. Native SP/MP timing/readability remains user-owned after S0-S8 developer acceptance.
