# Harness Acceptance — Semantic Social Conversation Director

## Principle

Acceptance is not "NPCs produced dialogue."

The harness must prove that autonomous social conversation:
1. begins from a grounded opportunity/fact/event;
2. uses bounded participant candidates;
3. opens or joins one canonical Scene Runtime scene;
4. distinguishes speaker, recipient, participant and observer;
5. derives semantic affordances without reparsing rendered text;
6. allows player and NPC responders to consume the same semantic affordance contract;
7. selects NPC responses from personality/relationship/knowledge/context;
8. selects at most one ordinary next speaker;
9. commonly chooses silence/no-scene for low-value repetition;
10. routes consequences through existing owning authorities;
11. remains within explicit performance/persistence bounds.

## D0 baseline

Freeze:
- current generated player-affordance candidate outputs;
- maximum candidate count;
- player-specific trait/context dependencies;
- recurrence/cooldown behavior;
- current response-button projection;
- typed player input independence;
- current Scene Runtime speaker/recipient/observer behavior;
- current production callers/registrations.

Representative semantic contexts must include:
- ANSWER/INFORM;
- AGREE/DISAGREE/ACKNOWLEDGE;
- APOLOGIZE/repair;
- hostility/challenge/de-escalation;
- wellbeing pending question;
- identity pending question;
- contextual/trait-gated suggestions;
- recurrence suppression.

D0 must not create ambient chatter.

## Actor-neutral affordance frontier

Positive cases:
- player responder gets the same expected semantic candidate set through the generalized frontier;
- NPC responder can request the same frontier without player-shaped fields;
- actor-specific traits/relationship/knowledge can constrain eligibility;
- semantic candidate identity is stable independent of UI label language;
- candidate count stays bounded.

Negative cases:
- NPC selection never parses button labels;
- generated-button recurrence policy does not reject typed player NLU;
- unavailable/private knowledge cannot create a disclosure affordance;
- missing/invalid responder fails closed;
- no gameplay mutation occurs while building candidates.

## NPC choice policy

Fixtures must show:

### Personality
Given the same valid frontier and grounded event:
- a cautious/avoidant actor may prefer concern/de-escalation;
- an aggressive/confident actor may prefer challenge/boast;
- a compassionate actor may prefer check/comfort;
- personality affects ranking, not authoritative facts.

### Directed relationship
A->B and B->A may select differently when directed relationship state differs.

### Knowledge
An actor must not select a semantic act that requires a fact/evidence it does not know or cannot disclose.

### Condition/context
Immediate danger, injury, panic/stress or current activity may suppress low-value social actions where the normalized actor context supports it.

### Recurrence
Repeated strategy/topic use is suppressed according to actor-neutral recurrence rules.

### Silence
At least one low-value/low-relevance fixture must intentionally select silence/no-response.

Every selection must expose bounded candidate rows and a deterministic selected/rejected reason.

## Social opportunity/admission

For each opportunity:
- provider/domain provenance visible;
- motive visible;
- grounded fact/event refs visible;
- candidate actors explicit and bounded;
- no all-NPC/full-faction scan;
- opening speaker/recipient explicit;
- admission or rejection reason observable;
- low-value duplicate opportunity suppresses;
- one opportunity does not create pairwise sub-scenes.

## Multi-participant turn matrix

Required:

### Two actors
`A -> B -> A -> end`

### Three actors
Example:
`A -> B, B -> A, C -> A, A -> C -> end`

### Four actors
One Scene with four participants; no six pairwise scenes.

Assert:
- current recipient has ordinary reply priority;
- non-recipient join/interjection requires an explicit eligible motive;
- at most one ordinary next speaker;
- speaker/recipient may change;
- no chorus;
- loop/turn cap/TTL terminate cleanly;
- actor death/leave delegates to existing Scene Runtime behavior.

## Player interoperability

Cases:

### Observer only
NPC A -> NPC B while player observes:
- player may receive presentation;
- player receives zero response affordances/resume authority.

### Addressed player
NPC A -> player:
- existing player response frontier/buttons are available where eligible;
- typed response remains valid;
- result returns to the same Scene.

### Mixed group
At least one 3+ actor sequence:
`NPC A -> NPC B -> player -> NPC A -> NPC C`
or equivalent, with one Scene and no duplicated semantic authority.

Closing the normal conversation UI must not fabricate, delete or mutate autonomous Scene facts.

## Chatter budgets and novelty

Assert:
- actor cooldown;
- pair cooldown;
- topic/motive recurrence suppression;
- local/group opening budget;
- scene turn/TTL limits;
- low-value burst commonly chooses silence/reject;
- urgent valid events are not starved by earlier low-value registration order;
- no per-frame/per-NPC conversation poll;
- no full actor registry scan.

A stress fixture should submit at least 20 opportunities and demonstrate bounded admissions/speaker decisions.

## Mandatory production adopters

### Post-combat/social decompression
- uses real combat/encounter facts;
- does not duplicate Combat Banter Arbiter authority;
- can produce a social reaction/acknowledgement after meaningful combat;
- no fabricated weapon/kill/threat fact.

### Task/work coordination
- uses authoritative Tasking/work facts;
- can request/acknowledge/status/complain/coordinate semantically;
- generic conversation layer does not directly assign/complete work.

### Grounded social knowledge / settlement event
- uses real knowledge/news/gossip or community/settlement/excursion facts;
- unknown/private facts rejected;
- at least one NPC->NPC continuation.

At least one production test must use hostile/raider or other non-companion NPCs without a participating player.

## Social consequences

Where a semantic act has a meaningful existing social consequence:
- emit/use the existing social/conduct/relationship event path;
- assert exactly-once handoff where applicable;
- generic Social Director/NPC choice code never writes relationship/faction/task values directly;
- missing authority handler fails safely rather than mutating fallback state.

## Observatory

A real worker inspection must answer:
- which opportunity/provider was considered;
- why it admitted/rejected;
- motive;
- grounded refs;
- candidate participants;
- selected participants;
- speaker candidates;
- selected speaker and recipient;
- affordance frontier strategies;
- NPC choice candidate/rejection reasons;
- silence/no-response reason;
- chatter budget/cooldown state;
- continuation/termination reason;
- player observer/participant/recipient state;
- LOD;
- query/candidate counts.

Bounded and read-only. No transcript dump.

## Persistence

Routine social conversation must add no:
- ModData root;
- rendered transcript persistence;
- generated choice/button persistence;
- InteractionPlan persistence;
- NPC reasoning trace persistence;
- routine LLM context/history store.

Existing durable owners may persist a meaningful social/gameplay fact exactly once.

## Extensibility

A synthetic future social provider/motive must:
- register through public seams;
- use the same Social Director;
- use the same Scene Runtime;
- use the same actor-neutral affordance frontier;
- allow NPC response or silence;
- require no feature-specific conditional in generic algorithms.

The test should fail if generic Social Director/SceneRuntime/NPC choice code contains a synthetic-domain special case.

## Final D8 developer acceptance

Before marking developer-complete:
- D0-D7 gates green;
- full isolated Lua suite green;
- focused semantic/dialogue/player-response regressions green;
- actor-neutral affordance tests green;
- group-turn tests green;
- chatter/stress tests green;
- all three production adopter matrices green;
- hostile/non-companion autonomous conversation case green;
- mixed player/NPC scene green;
- real worker/Observatory green;
- deterministic CodeBuilder double generation if content changed;
- EN/TL/source consistency if content changed;
- installed-PZ Kahlua errors = 0 for changed Lua;
- Python `py_compile` green for changed harness Python;
- static no-scan/no-text-reparse/no-routine-LLM/no-transcript guards green;
- source/save immutability where applicable;
- `git diff --check` clean.

Native Project Zomboid SP/MP timing, readability, social-noise tuning and perceived naturalness remain user-owned after all developer-side gates pass.
