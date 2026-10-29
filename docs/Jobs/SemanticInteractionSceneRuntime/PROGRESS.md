# Progress — Semantic Interaction Scene Runtime

**Status:** ACTIVE — S0–S1 accepted; S2 global Scene Runtime/admission is next.

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

## S0 accepted — baseline and authority freeze

S0 evidence is recorded in `S0_BASELINE.md`.

Accepted baseline:
- InteractionScene/Scheduler/Provider foundation remains generic and bounded;
- Scheduler caps are 16 active scenes / 4 participants / 8 turns / 8 recent events, with Scene history capped at 8;
- Scene.New currently owns an isolated one-scene Scheduler, proving the missing global runtime seam;
- player dialogue and InteractionScene share InteractionDirector authority;
- production has no registered Project Hoomans external-actor adapter;
- player lifecycle persistence remains keyed `playerUUID|npcID`;
- NPCSpeech preserves actor/target identity;
- generic non-player stimulus types exist but are mostly dormant in production;
- no transcript persistence, generated-text reparsing, Scene/Scheduler tick hook or Scene ModData store.

Focused acceptance: **4/4 PASS**.

## S1 accepted — production Project Hoomans actor adapter

Accepted implementation:
- `projecthoomans.managed_npc` registers through the existing InteractionProviders adapter seam;
- only the exact live record returned by `PNC.Registry.Get(id)` can adapt;
- disposition maps existing social personality into the generic contract;
- panic/stress/needs/activity/traits come from existing managed NPC state;
- directed personal relationship uses canonical `npc:<id>` relationship keys;
- directed faction relation uses existing faction read authority;
- known fact refs come from existing WorldKnowledge conversation context;
- dead/unmanaged actors fail closed;
- installation is idempotent and state-free.

S1 evidence:
- actor-adapter/Scene/provider/relationship/world-knowledge matrix: **5/5 PASS**;
- changed/untracked Lua through installed Kahlua compiler: **13/13 PASS**;
- `git diff --check`: clean;
- no new persistence/mutation owner.

## ONE current Next Chunk — S2

Implement one production global Scene Runtime/Registry around the accepted Scene/Scheduler.

S2 must:
1. let Scene.New use an injected shared Scheduler while preserving isolated construction for tests;
2. add one default runtime with active-scene map/order, global cap and deterministic IDs;
3. own explicit Open/Get/Close, TTL expiry and bounded runtime metrics;
4. terminate scenes when an actor becomes unavailable/dead/leaves;
5. expose explicit visibility/LOD updates without a polling tick;
6. preserve Scene participant/turn/history caps;
7. provide a bounded explicit admission seam only; generic Opportunity Providers remain S5;
8. add no world scan, ModData or automatic tick loop.

## Remaining mandatory phases

S0 baseline -> S1 production actor adapter -> S2 global Scene Runtime/admission -> S3 semantic continuation -> S4 recipient/observer/player handoff -> S5 opportunity providers -> S6 three production adopters -> S7 Scene Observatory -> S8 extensibility/scale/full acceptance.

## Native status

No new native validation exists for this goal. Native SP/MP timing/readability remains user-owned after S0-S8 developer acceptance.
