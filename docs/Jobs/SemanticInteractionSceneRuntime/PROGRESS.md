# Progress — Semantic Interaction Scene Runtime

**Status:** ACTIVE — S0–S7 accepted; S8 extensibility, scale and final developer acceptance are next.

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

## S2 accepted — global Scene Runtime/admission

Accepted implementation:
- Scene.New accepts an injected Scheduler while preserving isolated construction for existing tests/callers;
- Scheduler stores a bounded per-scene maxTurns value, so one shared Scheduler can safely host scenes with different turn budgets;
- one lazy default SceneRuntime owns global scene registry/order, deterministic generated IDs, admission metrics and the shared Scheduler;
- Runtime Open/Get/Close/Sweep/UpdateVisibility/ActorUnavailable are explicit caller-driven operations;
- TTL expiry and actor-unavailable termination are bounded and observable;
- actor object identity is preserved through admission so production adapters see canonical managed records;
- no tick hook, world/zombie scan or ModData store was added.

S2 evidence:
- runtime/adapter/scene/scheduler/provider matrix: **5/5 PASS**;
- S2 Lua through installed Kahlua compiler: **4/4 PASS**;
- focused `git diff --check`: clean.

## S3 accepted — semantic continuation

Accepted implementation:
- behavior definitions now have a validated optional `continuation` contract shared by CodeBuilder and runtime catalog;
- supported generic modes are `emit / wait / terminate`, with bounded target/intent/speechAct/expected-response metadata;
- selected behavior continuation survives InteractionArbitration into InteractionPlan;
- Scene computes continuation from semantic plan metadata only and exposes explicit `Continue` / bounded `RunContinuations` APIs;
- responder becomes the next semantic source and target policy can address the prior source;
- grounded fact/event refs are inherited without reparsing realized speech;
- scene-local disclosed facts/events allow follow-up about what was just disclosed without mutating durable knowledge;
- player targets become `wait:player_input_required`; the runtime never invents a player reply;
- explicit terminate closes the scene; undeclared continuation remains external/no-op rather than forcing closure;
- bounded repeat history suppresses continuation loops.

S3 evidence:
- continuation/Scene/Scheduler/Provider/Director Lua matrix: **5/5 PASS**;
- CodeBuilder continuation compiler contract: **4/4 PASS**;
- full `pnc_semantic` selection: **127/127 PASS**;
- deterministic CodeBuilder double generation: **188 files / 482 phrase families**, byte-identical;
- changed Lua through installed Kahlua compiler: **6/6 PASS**;
- Python compilation and `git diff --check`: clean.

## S4 accepted — recipient/observer/player handoff

Accepted implementation:
- one resolved Scene turn is projected through a bounded `InteractionSceneTransport`; audience fanout never reruns Director/catalog/realization;
- speaker and semantic recipient are derived from Scene history while participant and listener roles remain separate;
- observer packets carry the already-selected speech but no interaction capsule, response plan, offers or Scene resume token;
- addressed participating players receive the existing InteractionLifecycle envelope plus the selected Scene ResponsePlan and a turn-bound resume token;
- client delivery reuses the canonical SemanticSpeechPresentation queue/nameplate/TTS path;
- observer-only delivery is explicitly barred from synthesizing a player interaction;
- the existing suggestion builder/generated-affordance provider can consume an addressed Scene ResponsePlan;
- semantic-click responses are converted through the existing `Suggestions.FrameToIR` + predicate checks and bypass local duplicate NPC resolution;
- the server resumes only the exact waiting player/turn, rejects stale/wrong/action-bearing responses, and routes the meaning through the same Scene/Director;
- multiplayer/local fanout is capped at 8 listeners.

S4 evidence:
- focused audience/runtime/constants matrix: **6/6 PASS**;
- full `pnc_semantic` selection: **128/128 PASS**;
- changed S4 Lua through installed Kahlua compiler: **16/16 PASS**;
- `git diff --check`: clean.

## S5 accepted — event-driven Opportunity Providers

Accepted implementation:
- public `InteractionOpportunity` registry supports bounded provider registration with deterministic order;
- providers receive only caller-supplied canonical event/context and return declarative proposals;
- proposals are normalized/capped to 4 participants, 8 audience listeners, bounded fact/event refs, TTL/turn budgets and canonical stimulus types before Runtime admission;
- Scene now exposes one generic `EmitStimulus` entry for existing stimulus families while preserving actor knowledge checks;
- one Opportunity manager owns active-key dedupe, bounded cooldowns, admission metrics, first-stimulus dispatch and optional semantic continuation;
- accepted opportunities always open through the same global SceneRuntime/Scheduler;
- presentation fanout reuses the S4 transport and is capped before delivery;
- core Opportunity code performs no world/player/NPC scan and owns no tick or persistence.

S5 evidence:
- opportunity/runtime/scene focused matrix: **5/5 PASS**;
- two unrelated event sources (`FACTION_EVENT`, `TASK_EVENT`) admitted through the same Runtime;
- full `pnc_semantic` selection: **129/129 PASS**;
- changed S5 Lua through installed Kahlua compiler: **3/3 PASS**;
- `git diff --check`: clean.

## S6 accepted — cross-domain production adopters

Accepted production architecture:
- one server-side `PNC_SemanticInteractionSceneAdopters` hub owns one Opportunity manager over the global Scene Runtime;
- no adopter owns a scheduler, scene history, continuation engine, parser, persistence store or polling hook;
- event-triggered continuation supports declarative `target="other"` for the first deterministic eligible scene peer;
- one-shot arbitration applies its bounded output cap after semantic eligibility, preventing catalog growth from starving valid later providers;
- `SpatialIndex.QueryActors` discovers local NPC participants and nearby player observers in one bounded spatial-cell walk;
- observer players hear the already-selected exchange but receive no response authority.

### S6A combat
- authoritative horde episode start is the only combat Scene trigger;
- Encounter Intent remains engage/avoid/hold gameplay authority and Combat Banter Arbiter remains chatter-budget authority;
- same-owner/same-faction local NPCs are selected from one bounded actor query, capped at four;
- generated brave/cautious/steady teammate replies express engage/avoid/hold semantics with trait-appropriate wording;
- nearby players can overhear the exchange through S4 observer transport;
- no global zombie/NPC scan or combat-only conversation engine was added.

### S6B grounded social knowledge
- authoritative WorldKnowledge death publication notifies the adopter after fact commit/acquisition;
- a local speaker/listener pair is selected with one combined actor query;
- `WorldKnowledge.Explain` must confirm the speaker knows the exact fact;
- requested fact refs are projected through the existing actor adapter without mutating durable knowledge;
- sociable listeners can ask a semantic follow-up and the knowledgeable speaker answers with the same grounded fact;
- unknown facts fail before disclosure;
- authored news prose stays generic unless the semantic fact supports a more specific claim.

### S6C community excursion
- the existing `CommunityExcursionService.RegisterListener` supplies real phase-change events;
- participant IDs come from the authoritative excursion record, not faction/world scanning;
- PREPARING / OUTBOUND / RETURNING_HOME / AT_HOME / FAILED map to semantic status turns;
- another NPC acknowledges through generic continuation;
- Scene dialogue does not mutate excursion state.

S6 evidence:
- focused S3–S6 plus arbitration-capacity matrix: **5/5 PASS**;
- combat/world-knowledge/excursion/spatial regressions: **5/5 PASS**;
- full `pnc_semantic` selection: **133/133 PASS**;
- continuation compiler contract: **5/5 PASS**;
- deterministic CodeBuilder double generation: **190 files / 493 phrase families / 54 patterns / 10 UI definitions**, byte-identical;
- all changed/untracked S6 Lua, including generated artifacts, through installed Kahlua compiler: **21/21 PASS**;
- `git diff --check`: clean.

## S7 accepted — Scene Observatory and Semantic Lab worker support

Accepted implementation:
- `PNC_SemanticInteractionSceneObservatory` composes read-only bounded projections from the live Scene Runtime and optional Opportunity manager;
- inspection exposes runtime/admission metrics, active Scene IDs/status/LOD, participant IDs/roles, topic, current semantic speaker/recipient, bounded history acts/behavior IDs, grounding refs, Director beat state and continuation decision;
- Opportunity provenance includes provider/proposal identity, admission/rejection reason, audience count and delivered fanout;
- optional adopter metrics expose bounded actor-query/event counters without a new telemetry store;
- Scheduler keeps only the last eight compact closure rows so termination reasons remain explainable after Scene removal;
- observer response eligibility is explicit: observers never receive response authority; only an addressed player waiting on `player_input_required` can be eligible;
- no actor records, world blobs, raw/rendered text, transcript, ModData or polling state are projected.

Semantic Harness support:
- `SCENE_OBSERVATORY_FIXTURE` creates a disposable production-Lua Scene fixture;
- `SCENE_OBSERVATORY_INSPECT` reads the same production Runtime/Opportunity/Observatory state without mutation;
- Python worker exposes bounded `scene_observatory_fixture` and `scene_observatory_inspect` APIs;
- repeated inspection is stable/read-only and bounded to 1–8 scenes/history rows.

S7 evidence:
- production Observatory/runtime Lua matrix: **3/3 PASS**;
- generic Scene + existing Combat Observatory real-worker tests: **5/5 PASS**;
- full `pnc_semantic` selection: **134/134 PASS**;
- all changed/untracked S7 Lua through installed Kahlua compiler: **7/7 PASS**;
- Python compilation and `git diff --check`: clean.

## ONE current Next Chunk — S8

Complete extensibility, scale/stress and final developer acceptance.

S8 must:
1. add a synthetic fourth domain using only public Opportunity/content/provider seams, with no SceneRuntime/InteractionDirector/Scheduler/generic-continuation algorithm changes;
2. stress simultaneous scenes, burst events, large registries with few local actors, TTL/turn caps, participant death/leave and distant semantic-only LOD;
3. prove no pairwise scene explosion and bounded audience/participant/history/provider state;
4. prove urgent/high-priority opportunities coexist with or suppress lower-value opportunities according to existing admission policy without a new scheduler;
5. run full Lua + semantic/player-conversation regressions, real worker/Observatory suites, deterministic CodeBuilder, EN/TL/source consistency, installed-PZ Kahlua verification, static no-scan/no-transcript/no-routine-LLM guards and `git diff --check`;
6. record exact final evidence and hand native SP/MP timing/readability to the user without launching the game.

## Remaining mandatory phases

S0 baseline -> S1 production actor adapter -> S2 global Scene Runtime/admission -> S3 semantic continuation -> S4 recipient/observer/player handoff -> S5 opportunity providers -> S6 three production adopters -> S7 Scene Observatory -> S8 extensibility/scale/full acceptance.

## Native status

No new native validation exists for this goal. Native SP/MP timing/readability remains user-owned after S0-S8 developer acceptance.
