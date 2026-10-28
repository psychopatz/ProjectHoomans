# Audit — Pragmatic Interaction Director Recovery

**Repository baseline before the prototype:** `bd98962a2358ed904a382669b2187c7f20c0fa29`.

**Audit state:** the interaction/director implementation is currently
**uncommitted**. This is intentional and useful: it can be surgically reworked
before becoming repository history.

## What the prototype proved

The experimental implementation established several valuable behavioral facts.

### Keep as acceptance requirements

- typoed hostility such as `fuck ypuuuu` can remain `HOSTILE_REMARK` rather
  than falling into generic clarification;
- the same hostile semantic meaning can yield different reactions from grounded
  NPC state:
  - default → warning;
  - aggressive/confident → verbal retaliation;
  - panicked → de-escalation;
- hostility followed by apology can transition from an argument situation into
  reconciliation;
- low forgiveness can legitimately favor ending the interaction;
- a suspicious-first-contact situation can persist across multiple turns;
- bounded director state can live in existing conversation/session context;
- worker observations can expose candidate situations, predicate failures,
  modifiers, transitions, selected behavior, and resulting presentation lineage;
- a non-mutating draft preview / disposable worker-registration workflow is
  feasible.

These behaviors are useful. The current architecture underneath them is not
accepted.

## Mechanically working does not mean architecturally accepted

The focused prototype verification passed at audit time:

- 20 focused Python tests;
- 3/3 focused Lua tests;
- new Lua syntax checks;
- `git diff --check`.

The recovery work must preserve useful behavioral acceptance while replacing
incorrect ownership boundaries.

## Architectural drift found

### 1. Director became a second response authority

Current prototype logic effectively added:

```text
flow response
    ↓ else
director response
    ↓ else
LocalResponse
```

and `DialogueDirector.ResolveResponse()` chooses director-specific response
pools.

This violates the target architecture.

The director may choose semantic behavior. It must not choose a parallel
response catalog.

### 2. Director-specific wording/content authority appeared

Current prototype source includes director-specific wording pools and generated
`Conversation/Director.json` metadata.

This risks becoming a monolithic catch-all as new situations are added.

Actual dialogue wording belongs in modular Dialogue Content records.

### 3. Generated registry is copied into second production registries

Current prototype:

```text
Generated Conversation Registry
→ DialogueDirectorCatalog
→ DialogueBehaviorRegistry
→ DialogueBeatRegistry
```

This duplicates canonical production identity.

Target:

```text
Generated Conversation Registry / indexes
        ↓
one production registry view
        +
worker-local draft overlay
```

### 4. Runtime director is already too large

The prototype `PNC_SemanticDialogueDirector.lua` is already hundreds of lines
with only three initial situations.

The final architecture must separate:

- context projection;
- shared predicate evaluation;
- situation/beat arbitration;
- behavior arbitration;
- bounded state;
- trace/explanation.

Before extracting new modules, audit existing flow/suggestion predicate logic to
avoid creating multiple predicate engines.

### 5. Beat Studio became a separate authoring universe

The prototype Beat Studio handles structural editing and special canonical
promotion logic, while ordinary Dialogue Content already has a dedicated,
validated harness editing workflow.

Target UI:

```text
Conversation / Interaction Module view
├─ situation/beat structure
├─ behaviors
├─ linked Dialogue Content
└─ Simulation / trace
```

Structural editing must link into the existing Dialogue Content editor for
wording.

Do not create a second wording editor.

### 6. Compiler and authoring service accumulated director special cases

The prototype added dedicated beat/behavior validation/merge/generation paths
and a large director-specific canonical edit service.

Some structural schema support is necessary, but the final design should favor:

- small modular source shards;
- shared schema helpers;
- generic canonical-record authoring where possible;
- deterministic source-root discovery;
- shared generated registry/index infrastructure.

### 7. Missing broader interaction abstraction

The old implementation was still dialogue-centric.

The actual requirement includes:

- player dialogue;
- NPC-to-NPC semantic scenes;
- multi-NPC scenes;
- emotes;
- ambient flavor;
- world-event reactions;
- gossip;
- third-party actors.

The accepted abstraction therefore needs a **Pragmatic Interaction Director**,
not a dialogue-response director.

## Desired normalized input contracts

The interaction layer should consume read-only, bounded provider projections
rather than arbitrary subsystem internals.

Conceptual contracts:

```text
ActorSnapshot
- stable ID
- capabilities
- normalized disposition
- condition/emotion
- current activity
- semantic traits/tags

RelationshipSnapshot
- familiarity
- trust/respect/approval
- faction relation
- other bounded social factors

WorldSnapshot
- danger
- power/water
- weather/season/time
- semantic location
- local zombie pressure
- relevant world events

KnowledgeSnapshot
- actor-known grounded facts/events
- source/provenance where required

SceneContext
- participants/roles
- current topic
- recent bounded semantic acts
- active beat
- cooldowns
- salience
```

Missing information remains unknown. The director must never fabricate it.

## Third-party actor requirement

Third-party NPCs should integrate through an adapter/provider contract rather
than exposing private internals to beats.

Conceptually:

```text
GetStableID()
GetPosition()
GetCapabilities()
ProjectDisposition()
ProjectCondition()
ProjectRelationships(otherActor)
ProjectKnowledge()
ProjectActivity()
CanSpeak()
CanEmote()
SubmitAuthorizedIntent(intent)
```

Exact APIs may differ after codebase audit.

## Performance requirement

Never:

```text
every tick
  every NPC
    every beat
```

Use:

```text
typed stimulus
→ stimulus index
→ small candidate set
→ bounded evaluation
```

Examples of stimuli:

- social hostility;
- greeting;
- apology;
- idle social opportunity;
- actor enters/leaves;
- witnessed death;
- faction event;
- power/water change;
- helicopter event;
- danger changed;
- emote;
- task/world event.

## Persistence requirement

Do not persist rendered transcripts.

If a meaningful interaction creates durable knowledge, persist the compact
semantic fact/event through the system that owns that memory.

Example:

```text
speaker = Bob
fact = formerOccupation(mechanic)
source = witnessed_conversation
```

not the sentence Bob happened to say.
