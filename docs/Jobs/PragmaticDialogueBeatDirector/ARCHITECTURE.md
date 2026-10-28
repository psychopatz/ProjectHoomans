# Architecture — Pragmatic Interaction Director

## Design principle

The system is a reusable semantic interaction layer, not a dialogue-only
subsystem.

```text
                INPUT / STIMULUS SOURCES

 human text      engine/world       NPC semantic act      emote/task
     │               │                    │                  │
     ▼               │                    │                  │
 PsychopatzCore NLU  │                    │                  │
     └───────────────┴────────────────────┴──────────────────┘
                              │
                              ▼
                        Typed Stimulus
                              │
                              ▼
                    Context Projection Hub
          actor / relationship / world / knowledge / scene
                              │
                              ▼
                     Pragmatic Interpretation
                              │
                              ▼
                     Behavior Arbitration
                              │
                    ┌─────────┴─────────┐
                    │                   │
              one-shot behavior   optional Beat State
                    │                   │
                    └─────────┬─────────┘
                              ▼
                       InteractionPlan
              ┌───────────────┼──────────────┐
              ▼               ▼              ▼
          ResponsePlan     EmotePlan      GameplayIntent
              │               │              │
      Dialogue Content     presentation   existing domain
              │                            authority
        presentation /
        optional PBrainZ
```

## Authority boundaries

### PsychopatzCore

Owns human free-form NLU and candidate semantic interpretations.

Do not reparse NPC-generated text internally.

### Context providers/adapters

Own projection of authoritative subsystem state into bounded semantic snapshots.

They do not transfer authority to the director.

### Pragmatic resolver

Resolves what a semantic act means **in the current interaction**.

Inputs may include:

- pending questions/offers/requests;
- active/suspended flows;
- current/recent topic;
- referenced actors/entities;
- recent semantic acts;
- participant roles;
- salient grounded events.

This is where context-sensitive meaning belongs.

### Behavior arbiter

Chooses a semantic actor intention.

Examples:

- WARN;
- RETALIATE_VERBALLY;
- DEESCALATE;
- ACKNOWLEDGE;
- ASK_FOLLOWUP;
- SHARE_MEMORY;
- SHARE_NEWS;
- CHALLENGE;
- RECONCILE;
- EMOTE_GLARE;
- END_INTERACTION.

A behavior may be a one-shot reaction.

### Beat state

A beat exists only when a temporary situation needs multi-interaction state.

Examples:

- argument escalation;
- reconciliation;
- suspicious first contact;
- grief discussion;
- help-request pressure.

A beat changes behavior relevance over multiple interactions.

It does not own final prose or gameplay effects.

### InteractionPlan

The director output is a semantic plan, not wording.

Conceptually:

```text
InteractionPlan
- actor
- targets
- selected behavior
- topic
- grounded fact/event references
- tone/style hints
- optional emote intents
- optional gameplay intents
- explanation/provenance
```

### ResponsePlan / Dialogue Content

Existing ResponsePlan and Dialogue Content remain the single speech planning and
realization authority.

The director must not own response pools.

### Gameplay authority

Gameplay mutation remains in existing domain/action services.

The director may submit an intent only where the target system allows it.

## Actor/world agnosticism

The director must not depend directly on Project Hoomans private NPC fields.

Use bounded semantic provider contracts.

### Actor snapshot

Conceptual normalized fields:

```text
actor.id
actor.capabilities

disposition.aggression
disposition.confidence
disposition.forgiveness
disposition.sociability
disposition.empathy
disposition.riskTolerance

condition.panic
condition.injury
condition.hunger
condition.fatigue

activity.currentTask
activity.idle

traits/tags (only where semantically meaningful)
```

Project Hoomans may derive these values from its own traits. A third-party mod
may derive them differently.

### Relationship snapshot

Conceptually:

```text
familiarity
approval
trust
respect
factionRelation
relationshipTags
```

### World snapshot

Conceptually:

```text
immediateDanger
powerStatus
waterStatus
weather
season
timeOfDay
locationTags
zombiePressure
recentWorldEvents
recentFactionEvents
```

### Knowledge snapshot

Only grounded actor-known facts/events.

Unknown remains unknown.

## Typed stimuli

Stimuli are semantic events that wake only relevant interaction logic.

Examples:

```text
PLAYER_UTTERANCE
SOCIAL_HOSTILITY
APOLOGY
GREETING
EMOTE_RECEIVED
AMBIENT_SOCIAL_OPPORTUNITY
WITNESSED_DEATH
ACTOR_JOINED
ACTOR_LEFT
DANGER_CHANGED
WORLD_EVENT
FACTION_EVENT
TASK_EVENT
```

The exact taxonomy should reuse existing event contracts where possible.

## Indexed arbitration

Never scan every definition on every tick.

Target:

```text
stimulus type
    ↓
generated/indexed candidate IDs
    ↓
eligibility predicates
    ↓
situation/beat precedence
    ↓
behavior eligibility
    ↓
context modifiers
    ↓
deterministic winner / explicit no-op
```

## Simulation level of detail

### Player interaction

- full pragmatic evaluation;
- full behavior/beat trace;
- speech/emote realization;
- complete harness explanation.

### Nearby/audible NPC scene

- bounded semantic scene;
- speech/emote realization because the player can perceive it;
- low participant/turn caps.

### Nearby but not perceived

- semantic acts/outcomes only;
- skip wording realization unless required.

### Distant actors

- no turn-by-turn flavor conversation;
- retain only meaningful semantic outcomes if another authoritative system needs
  them.

## NPC-to-NPC interaction

NPC-generated interactions remain semantic internally.

```text
NPC A behavior: SHARE_MEMORY
topic: FORMER_JOB
fact: occupation=mechanic

        ↓ semantic event

NPC B receives:
DISCLOSURE_RECEIVED
topic: FORMER_JOB
speaker: A

        ↓

ACKNOWLEDGE / ASK_FOLLOWUP / SHARE_RELATED_MEMORY / DISMISS
```

Only perceived presentation is realized into text/emote.

Do not generate text and feed it back through NLU.

## Multi-participant scenes

A scene must support 2+ actors without assuming a player participant.

Bounded scene state may include:

- participants;
- roles/speaker;
- active topic;
- active beat;
- recent semantic acts ring;
- turn count;
- cooldowns;
- salient grounded facts;
- deterministic seed.

Do not persist full transcripts.

## Emote and flavor reuse

One behavior may have multiple presentation adapters.

Example:

```text
behavior: REACT_TO_INSULT

speech:
  ResponsePlan → Dialogue Content

emote:
  GLARE_AT speaker

ambient flavor:
  "X shoots Y an irritated look."

PBrainZ:
  realize the same grounded plan naturally
```

The semantic decision remains shared.

## Third-party adapters

Third-party NPCs integrate by implementing supported actor/context interfaces.

The director should query capabilities before selecting behaviors.

Examples:

- speech unavailable → speech-only behavior ineligible;
- emote unavailable → use another presentation or no-op;
- relationship unavailable → value is unknown, not fabricated.

## Source architecture

Canonical source should remain modular.

Target shape:

```text
sources/conversation/
├─ content/
│  └─ social/
│     ├─ argument/
│     ├─ reconciliation/
│     └─ first_contact/
├─ beats/
│  └─ social/
│     ├─ argument_escalation.json
│     ├─ reconciliation.json
│     └─ suspicious_first_contact.json
├─ behaviors/
│  └─ social/
│     ├─ warn.json
│     ├─ retaliate_verbal.json
│     ├─ deescalate.json
│     └─ ...
├─ flows/
├─ patterns/
├─ ui/
└─ manifest.json
```

Avoid giant `social.json` catch-all files.

## Source discovery

Prefer deterministic compiler-side recursive discovery of approved source roots
over manually appending every new shard to one growing manifest.

Project Zomboid runtime still receives explicit generated modules/indexes.

Authoring discovery and runtime loading are separate concerns.

## Runtime registry

Target one canonical Conversation Registry/index authority.

Temporary Semantic Lab changes use a worker-local overlay.

Do not copy generated definitions into separate production registries.

## Shared predicate engine

Before adding a new condition evaluator, audit and reconcile existing:

- flow predicates;
- suggestion eligibility;
- semantic/context constraints;
- prototype beat predicates.

The final interaction layer should use one typed/bounded predicate contract where
practical.

## Runtime modularity

The final interaction director should be a small composition root over focused
providers such as:

```text
InteractionDirector/
├─ Context.lua
├─ Predicate.lua
├─ Pragmatics.lua
├─ SituationArbitration.lua
├─ BehaviorArbitration.lua
├─ BeatState.lua
├─ StimulusIndex.lua
└─ Trace.lua
```

Exact filenames depend on existing conventions.

Do not create these blindly if an existing module already owns the concern.

## Harness architecture

Use one integrated interaction/conversation authoring workflow.

Structural view:

- beat/situation predicates;
- behaviors;
- stimulus bindings;
- capability requirements;
- contextual modifiers.

Content view:

- links to existing Dialogue Content records;
- existing Dialogue Content editor remains the wording editor.

Simulation:

- natural arbitration;
- active flows;
- active beat;
- behavior candidates;
- actor/world snapshots;
- trace/timeline;
- speech/emote/flavor output.

## Optional PBrainZ

PBrainZ receives the same grounded InteractionPlan/ResponsePlan.

It does not become:

- NLU authority for offline behavior;
- beat authority;
- fact authority;
- gameplay authority;
- relationship/task/inventory authority.
