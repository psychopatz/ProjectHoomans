# Harness Acceptance — Semantic Interaction Scene Runtime

## Principle

Acceptance is semantic/runtime behavior, not just visible dialogue.

For every autonomous scene the harness must be able to prove:
1. authoritative stimulus/opportunity;
2. bounded admission;
3. correct participants;
4. correct actor -> recipient;
5. grounded facts/events;
6. shared Director/Pragmatic decision;
7. continuation or termination reason;
8. presentation/LOD;
9. observer vs participant status;
10. no transcript/persistence/LLM side channel.

## S0 baseline

Freeze:
- existing scene smoke;
- Scheduler caps;
- generic stimulus type list;
- current interaction behavior/beat index;
- player conversation Director integration;
- player-pair lifecycle key `playerUUID|npcID`;
- current lack of production adapter/runtime.

Do not rewrite production behavior in the baseline chunk.

## Production actor adapter

Positive:
- live managed NPC projects identity/disposition/condition/activity/traits;
- directed relationship differs A->B vs B->A when authority differs;
- faction relation projected;
- knowledge facts bounded;
- evidence query available;
- speech/emote capability respected.

Negative:
- missing/dead invalid actor fails closed;
- private/unavailable knowledge is not invented;
- adapter does not mutate registry/relationship/knowledge.

## Runtime admission

Assert:
- global active scene cap;
- participant cap <= 4;
- duplicate scene IDs rejected;
- deterministic close;
- TTL expiry;
- actor leave/death handling;
- no per-tick world scan;
- admission metrics bounded;
- scene object does not create an independent global budget.

## Continuation matrix

Required semantic chains:
- `SHARE_MEMORY -> ASK_MEMORY_FOLLOWUP -> ANSWER/ACK`;
- `SHARE_NEWS -> ACK/ASK_DETAIL`;
- `WARN_THREAT -> PROPOSE_* -> ACCEPT/DISAGREE -> ACK`;
- `REQUEST -> ACCEPT/REFUSE -> ACK` when the chosen non-combat adopter supports it.

Assert:
- realized text is never input to Parser/NLU;
- continuation uses semantic plan/metadata;
- target is explicit participant;
- grounded refs preserved;
- loop protection;
- max turn termination;
- TTL termination;
- no-response/silence path.

## Recipient / observer

Cases:
- NPC A -> NPC B, player observes: no player buttons;
- NPC A -> player: eligible buttons may appear;
- NPC A -> NPC B with NPC C participant: C does not become target automatically;
- observer enters range after semantic selection: presentation visibility may change, semantic decision does not rerun;
- observer leaves: scene authority unchanged;
- target dies/leaves: continuation closes/retargets only under explicit policy.

## Player interop

Prove:
- normal player one-on-one conversation remains regression-green;
- player lifecycle storage still owns player-pair response windows;
- player can become a Scene participant without creating duplicate Director state;
- typed/button semantic response can return to the active Scene;
- closing UI does not fabricate/erase autonomous semantic facts.

## Opportunity/provider performance

For each provider:
- event-driven call only;
- explicit/local candidate reuse preferred;
- fallback spatial query <= 1 per admission;
- candidates capped before Director work;
- no full faction member iteration;
- no all-NPC polling;
- repeated low-value opportunities commonly reject/suppress;
- admission reason observable.

## Required production adopters

### Combat
- companion/faction/hostile/neutral/solo cohort eligibility;
- horde/tactical facts grounded;
- real Encounter Intent owns engage/avoid/hold;
- Combat Banter Arbiter remains combat chatter budget;
- NPC squad exchange works without player;
- player observer does not become respondent.

### Social knowledge
- known memory/news can be disclosed;
- unknown fact rejected;
- follow-up personality/relationship sensitive;
- knowledge/privacy rules respected;
- no transcript.

### Non-combat gameplay
- real authoritative event/fact;
- at least one NPC->NPC continuation;
- dialogue cannot directly mutate gameplay outside owning service;
- same SceneRuntime public API.

## Extensibility fixture

A synthetic fourth domain must:
- register/use public opportunity/adopter seams;
- use existing SceneRuntime and Director unchanged;
- use generic continuation unchanged;
- avoid new persistent store;
- pass real Lua worker.

The test must fail if production-specific conditional branches are added to generic runtime for the synthetic domain.

## LOD/performance

Assert:
- perceived scenes can realize speech/emote/flavor;
- nearby-unperceived/distant may be semantic-only;
- semantic-only mode does not generate presentation work;
- no semantic decision per observer;
- active scenes/participants/turns/history stay within hard caps;
- no pairwise sub-scene explosion.

## Persistence

Routine autonomous scenes:
- no new ModData root;
- no rendered transcript;
- no generated button persistence;
- no InteractionPlan persistence;
- no reasoning-trace persistence;
- `llmEligible=false` unless a separately authorized future policy explicitly opts in.

Existing durable authorities may record meaningful gameplay/social events exactly once.

## Content

All new authored content:
- canonical CodeBuilder source;
- deterministic generation;
- EN/TL coverage;
- reusable semantic templates where sensible;
- no internal IDs in prose;
- no feature-specific parser.

## Scene Observatory

A real worker inspection must answer:
- why scene admitted/rejected;
- participants and provider;
- speaker and target;
- player participant/observer state;
- current topic/beat;
- bounded previous semantic acts;
- selected behavior;
- grounded refs;
- continuation/termination;
- LOD/presentation;
- query/fanout metrics.

Read-only and bounded. No transcript dump.

## Final S8 acceptance

Before developer completion:
- S0-S7 gates green;
- full Lua green;
- player semantic regressions green;
- all three production adopters green;
- fourth synthetic adopter green;
- worker/Observatory green;
- deterministic CodeBuilder;
- Kahlua errors = 0;
- static no-scan/no-transcript/no-LLM guards green;
- `git diff --check` clean;
- save/source immutability where used;
- native SP/MP status stated accurately.
