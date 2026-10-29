# Architecture — Semantic Interaction Scene Runtime

## 1. Stable ownership

The semantic system has one shared reasoning substrate and multiple frontends.

```text
                    SEMANTIC INTERACTION CORE
 ┌────────────────────────────────────────────────────────────┐
 │ InteractionStimulus                                        │
 │ InteractionProviders / Evidence                            │
 │ InteractionContext                                         │
 │ PragmaticResolver                                          │
 │ InteractionDirector                                        │
 │ InteractionCatalog                                         │
 │ InteractionPlan                                            │
 │ InteractionPresentation / Dialogue Content                 │
 └────────────────────────────────────────────────────────────┘
                     ▲                         ▲
                     │                         │
         Player Conversation Session    Interaction Scene Runtime
         typed/buttons/UI               autonomous/multi-actor
         player-pair lifecycle          bounded/transient scenes
```

The player frontend is not replaced by this job.

## 2. Scene Runtime

Introduce one production runtime owner around the existing scene object.

Conceptual responsibility:

```text
SemanticInteractionSceneRuntime
  activeScenes
  admission
  global caps
  scene TTL
  participant membership
  actor leave/death handling
  visibility / LOD
  event dispatch
  semantic continuation
  bounded metrics
  observatory snapshot
```

A Scene remains the local semantic state object.

The Runtime must not become:
- a world scanner;
- a faction database;
- a dialogue content registry;
- a gameplay AI;
- a durable memory system.

## 3. Production actor adapter

Register a canonical Project Hoomans adapter through the existing `InteractionProviders.RegisterActorAdapter` API.

It composes current authorities:
- managed NPC registry/state;
- ActorConversationContext/personality/traits;
- directed relationship;
- faction relation;
- condition/activity;
- knowledge/fact refs;
- evidence providers;
- speech/emote/movement capabilities.

The adapter is a bounded projection only. It owns no state.

## 4. Opportunity provider contract

Features should submit semantic opportunities, not run dialogue.

Conceptually:

```lua
{
  providerID = "combat.horde",
  stimulusType = "WORLD_EVENT",
  topic = "combat",
  actorHints = {...},
  targetHints = {...},
  candidateActorIDs = {...}, -- bounded if already known
  factRefs = {...},
  eventRefs = {...},
  urgency = ...,
  scenePolicy = {
    maxParticipants = ...,
    maxTurns = ...,
    ttl = ...,
  }
}
```

The exact schema must stay bounded and domain-agnostic.

Providers may come from:
- combat/perception;
- faction events;
- tasks;
- social events;
- gossip/news;
- community excursions;
- settlement activities.

The Runtime owns admission and scene mechanics.

## 5. Participant discovery

Preferred order:
1. use explicit participants/candidates from the authoritative triggering system;
2. reuse an existing local spatial/perception query result;
3. only if necessary, perform one bounded spatial query at scene admission.

No query once per semantic turn.

No iteration of full faction membership to discover local speakers.

Participants are explicit, capped and may be player or NPC actors.

## 6. Semantic continuation

A realized response is never reparsed.

A selected InteractionPlan may project an outward semantic act:

```text
previous stimulus
    ↓
selected behavior
    ↓
InteractionPlan
    ↓
ContinuationPolicy
    ├─ terminate
    ├─ remain open / wait for external input
    └─ emit bounded semantic act
             actor = responder
             target = selected participant
             act = behaviorAct / declared continuationAct
             topic/subject
             grounded fact/event refs
```

Continuation eligibility must be explicit and data-driven where possible.

Not every speech behavior continues a scene. Silence/termination is common.

Hard requirements:
- max turns;
- TTL;
- target must be a live scene participant;
- no self-target unless explicitly supported later;
- grounded refs retained;
- no rendered text used as meaning;
- loop/strategy anti-repeat bounded.

## 7. Speaker / recipient / observer

These are distinct roles.

```text
speaker       semantic actor
recipient     semantic target/addressee
participant   actor eligible for scene turns
observer      client/player/NPC allowed to perceive presentation
```

A player observer does not automatically become a semantic participant.

Player response affordances require the player to be a current semantic addressee/eligible participant and still pass existing response-authority checks.

## 8. Presentation and LOD

Reuse existing InteractionPresentation, SpeechRealization and NPC in-world speech.

Scene Runtime decides semantic work; presentation uses Scheduler LOD:
- player/full or perceived nearby: speech/emote/flavor allowed by policy/capability;
- nearby-unperceived/distant: semantic-only or suppressed flavor as already defined.

Do not generate one semantic decision per observer.

Network transport should fan out the already-selected presentation only to legitimate observers.

## 9. Player conversation interop

Existing player conversation remains a frontend over the shared semantic core.

Do not migrate its player-pair persistence merely to claim unification.

Required interoperability:
- an autonomous scene may include a player participant;
- an autonomous NPC may address a nearby player and hand off response affordances to existing player response/lifecycle surfaces;
- player input may become a scene stimulus when the player is participating;
- leaving/closing the normal conversation UI does not corrupt an autonomous scene;
- ordinary one-on-one player conversations continue using their accepted lifecycle.

## 10. Persistence and memory

Scene Runtime is transient by default.

Never persist:
- rendered transcript;
- generated dialogue;
- generated buttons;
- InteractionPlans;
- reasoning traces;
- complete scene state.

If a meaningful social/gameplay event should have durable consequences, it goes through existing:
- relationship;
- conduct;
- knowledge;
- faction;
- conversation-memory/evidence;
- gameplay authorities.

The scene may reference those facts but does not duplicate them.

## 11. Adopter boundary

An adopter may supply:
- opportunity/stimulus;
- bounded participant candidates;
- authoritative facts/events;
- domain-specific semantic relations/behaviors/content;
- gameplay-intent adapter where authorized;
- optional admission/chatter budget signal.

An adopter must not own:
- a second scene scheduler;
- semantic turn history;
- text reparsing;
- its own generic follow-up engine;
- separate recipient/observer semantics.

## 12. Required production adopters

S0-S8 acceptance requires at least three different production families:

### Combat
Use existing Combat Moment/Cohort/Encounter Intent/Banter Arbiter as domain inputs/gates. Prove NPC squad semantic exchanges.

### Grounded social knowledge
Use memory/news/gossip-like facts to prove non-combat NPC->NPC semantic follow-up.

### Non-combat gameplay domain
Use a real domain such as task coordination or community excursion/settlement absence. It must prove the Runtime is not secretly combat-specific.

A fourth synthetic future-domain fixture must register through public seams without editing SceneRuntime/Director/Continuation algorithms.

## 13. Performance bounds

Keep hard caps. Initial ceiling:
- active scenes: <= existing Scheduler global maximum unless measured lower;
- participants per scene: <= 4;
- turns per scene: <= 8 in generic infrastructure, with adopters usually lower;
- semantic history: <= 8;
- event/fact refs bounded by existing contracts;
- no per-frame semantic regeneration;
- no routine LLM;
- no persistent transcript.

A high cap is not a target for chatter frequency. Admission/arbitration should commonly choose silence/no scene.

## 14. Observatory

Generic Scene Observatory exposes bounded read-only state:
- runtime metrics;
- scene ID/status/LOD;
- participant IDs/roles;
- source/responder;
- topic;
- semantic history IDs/acts only;
- grounded fact/event refs;
- active beat;
- last selected behavior;
- continuation decision;
- termination/suppression reason;
- observer/recipient policy;
- query/admission counters.

No raw transcript or full-store dump.
