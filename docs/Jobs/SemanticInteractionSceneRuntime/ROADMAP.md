# Roadmap — Semantic Interaction Scene Runtime

**Parent objective:** productionize the existing generic Interaction Scene foundation into the canonical event-driven autonomous/multi-actor semantic conversation subsystem, then prove it across combat, grounded social knowledge and a non-combat gameplay domain without creating feature-specific dialogue engines.

All S0-S8 phases are mandatory.

## S0 — Baseline and authority freeze

Mechanically characterize the existing foundation before production changes.

Required baselines:
- current `InteractionScene` smoke behavior;
- Scheduler limits/LOD/metrics;
- Director/PragmaticResolver shared use between player conversation and scenes;
- current generated interaction behavior/beat catalog;
- test-only actor adapter registrations;
- player-pair lifecycle storage shape;
- current NPC speech transport/presentation;
- dormant generic stimulus types;
- no production SceneRuntime owner.

Capture exact test/runtime evidence and identify compatibility expectations for player dialogue.

**Gate:** existing Scene behavior is frozen as accepted foundation; gaps are proven rather than inferred.

## S1 — Production Project Hoomans actor adapter

Register a production adapter through `InteractionProviders`.

Project:
- NPC identity/capabilities;
- personality/disposition;
- panic/stress/needs/activity;
- traits;
- directed relationship;
- faction relation;
- bounded knowledge/fact refs;
- existing evidence query context.

Use current authorities; no new actor/social database.

Add real managed-NPC fixtures and failure-closed cases for missing/dead/invalid actors.

**Gate:** production NPC records can enter an InteractionScene with the same normalized contract as synthetic actors, without duplicating state.

## S2 — Global Scene Runtime and admission

Add a single production Runtime/Registry around Scene/Scheduler.

Own:
- active scene map/order;
- global cap;
- deterministic scene IDs;
- open/get/close;
- TTL/expiry;
- participant add/remove policy where supported;
- actor death/leave termination;
- visibility/LOD updates;
- event dispatch;
- bounded metrics.

Refactor Scene construction only as needed so the global scheduler/caps are meaningful. Preserve isolated testability.

Add a bounded Opportunity/Admission API. No tick polling loop.

**Gate:** multiple simultaneous scenes respect one global budget, expire/close deterministically, and do not scan the world.

## S3 — Semantic continuation

Implement generic continuation from selected InteractionPlan/behavior into a subsequent semantic scene stimulus.

Requirements:
- no rendered-text parsing;
- explicit source/target;
- grounded refs preserved;
- behavior/metadata-driven continuation;
- expected response relation;
- target eligibility;
- loop/anti-repeat protection;
- turn cap/TTL;
- silence/termination common and explainable.

Support external-input waits for player-addressed questions rather than auto-answering for the player.

**Gate:** deterministic multi-turn semantic chains work entirely from semantic acts/plans; max-turn and loop guards proven.

## S4 — Recipient / observer / player handoff

Productionize directed NPC speech.

Requirements:
- speaker != recipient != observer;
- NPC->NPC rendered through existing in-world NPC speech;
- nearby players may observe without becoming participants;
- no player affordances for overheard-only speech;
- NPC->player scenes can expose canonical semantic offers through existing player response surfaces;
- player responses return to the same scene semantic context when participating;
- multiplayer/local observer fanout bounded and non-authoritative.

**Gate:** actor/target identity survives end-to-end; observer-only player gets zero buttons; addressed player gets valid existing affordances.

## S5 — Event-driven Opportunity Providers

Create the public adopter seam for authoritative systems.

Initial provider types should cover existing stimulus families:
- world/danger/combat events;
- faction events;
- task events;
- ambient social opportunities;
- witnessed events;
- actor join/leave.

Admission:
- reuses explicit/event-local candidate sets;
- otherwise at most one bounded spatial query;
- caps before semantic ranking;
- supports domain admission budget hooks;
- never loops all NPCs/faction members each frame.

**Gate:** at least two different event sources open/route scenes through the same Runtime with no feature-owned scheduler.

## S6 — Cross-domain production adopters

Implement at least three real adopter families.

### S6A combat
Implement autonomous combat group conversation as a combat adopter:
- faction/owner/solo cohort participant provider;
- horde warning/tactical proposals;
- engage/avoid/hold expression tied to actual Encounter Intent;
- Combat Banter Arbiter gates chatter/priority;
- neutral and hostile squads can converse without player participation.

No Combat Exchange Director.

### S6B grounded social knowledge
Use real knowledge/evidence:
- memory/news/gossip-like disclosure;
- follow-up/acknowledgement/reaction;
- source cannot disclose unknown fact;
- visibility/privacy respected.

### S6C non-combat gameplay
Choose a real production domain with authoritative facts, preferably task coordination or community excursion/settlement absence if available:
- request/status/news semantic opportunity;
- NPC->NPC follow-up;
- no direct gameplay mutation outside owning authority.

**Gate:** all three adopters use the same SceneRuntime/Continuation/Presentation architecture.

## S7 — Scene Observatory and Semantic Lab support

Expose bounded read-only inspection from production state.

Show:
- runtime active-scene metrics;
- scene participants and roles;
- LOD;
- source/recipient/observers;
- current topic;
- bounded semantic history;
- active beat;
- selected behavior;
- grounded refs;
- continuation decision;
- admission/suppression/termination reason;
- provider/adopter provenance;
- query/fanout counters.

Add real Lua-worker commands/fixtures. No monolithic dump or transcript.

**Gate:** agent can explain why a scene opened, who spoke to whom, why the next NPC responded or stayed silent, and why a player did/did not receive choices.

## S8 — Extensibility, scale and developer acceptance

### Extensibility proof
Add a synthetic fourth domain through public registration/opportunity/content seams.

It must not edit:
- SceneRuntime algorithm;
- InteractionDirector algorithm;
- generic Continuation algorithm;
- Scheduler;
- generic persistence.

### Scale/stress
Prove:
- multiple simultaneous scenes;
- large faction registry with few local participants;
- burst combat/social events;
- participant death/leave;
- player enters/leaves observer range;
- player joins a scene;
- urgent combat interrupts/terminates lower-value social scene where policy says so;
- scene TTL and turn caps;
- distant semantic-only LOD;
- no pairwise scene explosion.

### Final gates
Run:
- full Lua suite;
- focused semantic/player-conversation regressions;
- real Semantic Harness worker suites;
- adopter matrices;
- deterministic CodeBuilder double generation;
- EN/TL/source consistency;
- installed-PZ Kahlua verification;
- static scan/performance guards;
- no-ModData/no-transcript/no-routine-LLM assertions;
- source/save immutability where applicable;
- `git diff --check`.

**Gate:** all developer-side S0-S8 work accepted. Native SP/MP conversational timing/readability remains user-owned.

## Optional/future after S8

Non-mandatory extensions:
- long-form settlement social scenes;
- remote/radio conversations;
- LLM-enhanced rare scenes through explicit opt-in policy;
- durable remembered conversation summaries where a future owning memory system justifies them;
- larger group deliberation/voting;
- cinematic scripted scenes.

Do not implement optional scope to claim parent completion.
