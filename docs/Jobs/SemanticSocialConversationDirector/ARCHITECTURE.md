# Architecture — Semantic Social Conversation Director

## 1. Target architecture

```text
Authoritative world/gameplay/social events
                |
                v
      Social Opportunity Providers
                |
                v
      Semantic Social Director
      - motive/admission
      - participant hints
      - social/chatter budget
      - opening speaker/recipient
                |
                v
 Existing SemanticInteractionSceneRuntime
      - scene lifecycle
      - participants
      - TTL/turn caps
      - continuation
                |
                v
 Actor-neutral Semantic Affordance Frontier
        /                       \
       v                         v
 Player response UI        NPC Choice Policy
 existing buttons          personality/relationship/
                           knowledge/context ranking
        \                       /
                semantic act
                    |
                    v
 Existing InteractionDirector / PragmaticResolver
                    |
                    v
 Existing realization / presentation
                    |
                    v
 Existing gameplay/social authorities for effects
```

The new layer is a director of **social opportunities and turn participation**, not a replacement semantic engine.

## 2. Ownership

### Semantic Social Director owns
- social motive/opportunity arbitration;
- generic opening-scene social admission;
- bounded participant/speaker/recipient competition;
- generic social/chatter budgets;
- actor/pair/topic/local-area cooldown/stickiness policy;
- scene-level social purpose metadata;
- explainable rejection/silence reasons.

### Scene Runtime continues to own
- active scene lifecycle;
- global scene capacity;
- participant membership;
- TTL;
- semantic turn limits/history;
- actor loss;
- continuation mechanics;
- LOD and observer semantics.

### Interaction Director continues to own
- beat/behavior arbitration;
- pragmatic interpretation;
- InteractionPlan selection/commit.

### Affordance subsystem owns
- semantic response candidates/frontier;
- candidate eligibility and recurrence rules;
- no execution of gameplay authority.

### NPC Choice Policy owns
- ranking valid semantic affordances for an NPC actor;
- deterministic fixture-friendly decision traces;
- silence/no-response where appropriate.

### Gameplay/social domains continue to own
- movement;
- combat;
- tasking;
- inventory;
- relationships;
- factions;
- knowledge;
- excursions;
- trading;
- other authoritative mutations.

## 3. Actor-neutral affordance frontier

The existing generated player response system is the foundation.

Refactor toward a contract conceptually like:

```lua
AffordanceFrontier.Build({
    actorID = responderID,
    counterpartID = speakerID,
    scene = sceneContext,
    interactionPlan = previousPlan,
    discourseFrame = frame,
    actorContext = normalizedActorContext,
})
```

Result:

```lua
{
    {
        strategy = "AGREE",
        stance = "POSITIVE",
        semanticAct = {...},
        reason = "...",
        eligibility = {...},
        constraints = {...},
    },
    ...
}
```

Requirements:
- semantic only; no rendered button label needed for NPC selection;
- bounded candidate count;
- actor-neutral traits/relationship/context;
- public/player UI adapter can still turn the frontier into buttons;
- typed player NLU remains independent and must not be rejected by button recurrence policy;
- no NPC decision is made by reparsing button text.

Player-button behavior must remain regression-compatible unless a roadmap phase explicitly changes product behavior.

## 4. Social motives

A social opportunity should express **why communication may be useful**, not prewrite dialogue.

Generic motive families may include:
- INFORM;
- WARN;
- REQUEST;
- CHECK;
- ACKNOWLEDGE;
- REACT;
- SOCIALIZE;
- DISPUTE;
- REPAIR;
- COORDINATE;
- SILENCE.

Domains supply grounded facts/events and may narrow allowable motives.

The Social Director must commonly choose no scene/silence for low-value opportunities.

## 5. Grounded opportunities

Preferred sources:
- combat/encounter transitions;
- task state changes;
- relationship/social events;
- knowledge/news/gossip facts;
- community/settlement/excursion events;
- arrivals/departures;
- witnessed player/NPC behavior;
- other authoritative domain events.

A provider supplies bounded candidates and grounded refs. The Social Director never fabricates the underlying event.

## 6. Role-agnostic NPC support

Generic code must not branch on "companion conversation", "neutral conversation" or "raider conversation".

Actors are described through normalized context:
- identity;
- team/faction;
- directed relationship;
- personality/traits;
- condition/activity;
- knowledge/evidence;
- capabilities;
- current scene role.

Companion, neutral, hostile and faction behavior emerges from those facts plus domain policies.

A domain may restrict participation for legitimate gameplay reasons, but no second generic engine is allowed.

## 7. NPC semantic choice policy

For one responder, the flow is:

```text
previous semantic act
      |
      v
actor-neutral affordance frontier
      |
      v
hard eligibility
- knowledge
- capability
- target validity
- semantic constraints
      |
      v
contextual ranking
- personality
- directed relationship
- disposition
- current condition/mood
- social motive
- recent strategy/act
- topic novelty
- group context
      |
      v
stickiness / recurrence suppression
      |
      +----> SILENCE / terminate
      |
      v
selected semantic affordance
```

Numeric scoring may be used inside one bounded class, but hard semantic/authority constraints must not be overcome by additive weights.

Decision traces must be inspectable.

## 8. Group turn arbitration

Do not allow every participant to respond independently.

At a continuation point:
1. establish the explicit current recipient;
2. allow the recipient the strongest normal reply opportunity;
3. optionally consider other scene participants for join/interjection motives;
4. rank bounded speaker candidates;
5. select at most one semantic speaker for the next ordinary turn;
6. urgent domain-owned interruptions may override through explicit priority policy;
7. terminate if no worthwhile candidate exists.

The scene may change topology:

```text
A -> B
B -> A
C -> A
A -> C
B -> C
end
```

but remains one Scene, not pairwise sub-scenes.

## 9. Chatter budgets

Use layered bounded budgets:
- actor cooldown;
- directed pair cooldown;
- topic/motive cooldown;
- local group/area chatter budget;
- scene turn/TTL limits;
- existing global Scene Runtime capacity.

Urgent warnings may have higher domain priority, but routine ambient chatter must not crowd out gameplay or become constant noise.

Silence is a successful outcome.

## 10. Player interoperability

Player observer:
- may receive presentation if visible;
- receives no response affordance merely by overhearing.

Player addressee/participant:
- receives the existing semantic response frontier/buttons;
- typed input remains supported;
- response returns to the same Scene semantic context.

NPC addressee:
- receives the actor-neutral affordance frontier;
- NPC Choice Policy selects a semantic act;
- no fake UI/button click is simulated.

A scene may naturally transition NPC->NPC -> NPC->player -> player->NPC -> NPC->NPC.

## 11. Social consequences

Conversation may emit existing semantic/social events, but generic dialogue code does not directly mutate relationship/faction/task/etc.

Example:

```text
INSULT semantic act
    |
    v
existing social/conduct/relationship event path
    |
    v
Relationship authority decides consequence
```

This keeps emergent conversation consequential without making the dialogue director the game simulation.

## 12. Persistence

Runtime-only by default:
- social opportunity;
- motive ranking;
- chatter budget state/cooldowns where safe to rebuild;
- NPC affordance candidates;
- NPC semantic choice trace;
- speaker competition;
- scene social-purpose metadata.

Do not persist:
- transcript;
- rendered speech;
- generated button lists;
- InteractionPlans;
- reasoning traces;
- routine social scenes.

Existing durable authorities may record meaningful facts/events exactly once.

## 13. Performance

Mandatory:
- no per-NPC "should I talk?" tick;
- no per-frame affordance generation;
- no full actor/faction scans;
- event-provided/local bounded candidates;
- participant ceiling inherited from Scene Runtime (currently <=4);
- generic turn ceiling inherited from Scene Runtime (currently <=8; ordinary ambient target should usually be lower);
- no pairwise scene explosion;
- no routine LLM;
- one semantic decision per turn, not per observer.

## 14. Extensibility test

A synthetic future social motive/provider must be able to:
- submit an opportunity through public seams;
- produce a bounded actor-neutral frontier;
- allow an NPC response or silence;
- run through existing SceneRuntime/InteractionDirector unchanged.

It must not require a domain conditional in generic Social Director, Scene Runtime or affordance-selection algorithms.
