# Progress — Semantic Interaction Scene Runtime

**Status:** ACTIVE — S0 accepted; S1 production Project Hoomans actor adapter is next.

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

## ONE current Next Chunk — S1

Implement the production Project Hoomans actor adapter through the existing InteractionProviders registration seam.

S1 must:
1. adapt only real managed Project Hoomans NPC records;
2. project identity/capabilities, disposition/personality, panic/stress/needs/activity and bounded traits from existing record/runtime/context authorities;
3. project directed relationship/faction relation through existing relationship/faction/social authority rather than duplicate state;
4. project bounded known fact refs from existing knowledge/evidence authority;
5. fail closed for missing/dead/invalid actors;
6. register exactly once without breaking third-party adapter ordering;
7. add real managed-NPC Scene fixtures proving asymmetric A->B/B->A context where authority differs;
8. add no persistent storage and perform no mutation.

## Remaining mandatory phases

S0 baseline -> S1 production actor adapter -> S2 global Scene Runtime/admission -> S3 semantic continuation -> S4 recipient/observer/player handoff -> S5 opportunity providers -> S6 three production adopters -> S7 Scene Observatory -> S8 extensibility/scale/full acceptance.

## Native status

No new native validation exists for this goal. Native SP/MP timing/readability remains user-owned after S0-S8 developer acceptance.
