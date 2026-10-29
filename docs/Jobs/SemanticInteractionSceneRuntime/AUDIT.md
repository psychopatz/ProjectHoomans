# Audit — Semantic Interaction Scene Runtime

**Audit base:** ProjectHoomans `47aaad69`, existing `main`.

## Verdict

The correct generic NPC conversation framework already exists in partial/tested form. The job should productionize it instead of creating a new combat exchange subsystem.

## Existing generic semantic core

### Interaction Scene

`PNC_SemanticInteractionScene.lua` already owns a bounded scene object with:
- explicit participants;
- actor -> responder targeting;
- bounded semantic history;
- topic and scene-local Director state;
- known world-event refs;
- grounded fact checks;
- `EmitSemanticAct`;
- `EmitWorldEvent`;
- visibility/LOD update;
- bounded snapshot;
- no transcript storage.

Its file-level contract already says it is for “NPC-to-NPC and multi-NPC interaction.”

### Existing scene acceptance

`tests/pnc_semantic_interaction_scene_smoke.lua` already proves:
- NPC A can disclose a fact to NPC B without generated text in the stimulus;
- unknown/fabricated facts are rejected;
- sociable vs empathic responders can select different grounded behaviors;
- speech-disabled actors can still use emote/flavor;
- grounded news sharing;
- three explicit participants without pairwise scene explosion;
- direct A->B then B->C targeting;
- world danger interrupting an active argument beat;
- unknown world events rejected;
- nearby unperceived scene still runs semantic arbitration while suppressing speech/emote/flavor;
- semantic history contains semantic identifiers, not rendered prose.

Focused interaction-scene/provider/scheduler smoke is currently green.

### Interaction Scheduler

`PNC_SemanticInteractionScheduler.lua` is already event-driven and explicitly has no tick hook.

It defines hard caps:
- `MAX_ACTIVE_SCENES = 16`;
- `MAX_PARTICIPANTS = 4`;
- `MAX_TURNS_PER_SCENE = 8`;
- `MAX_RECENT_EVENTS = 8`.

It already has LOD classes:
- player participant;
- nearby perceived;
- nearby unperceived;
- distant.

Distant/nearby-unperceived scenes can run semantic-only policy.

### Interaction Stimulus

`PNC_SemanticInteractionStimulus.lua` already supports:
- `HUMAN_UTTERANCE`;
- `NPC_SEMANTIC_ACT`;
- `EMOTE`;
- `AMBIENT_SOCIAL_OPPORTUNITY`;
- `WORLD_EVENT`;
- `FACTION_EVENT`;
- `TASK_EVENT`;
- `DANGER_CHANGED`;
- `ACTOR_JOINED`;
- `ACTOR_LEFT`;
- `WITNESSED_DEATH`.

Most non-player event types are currently dormant/test-only. This is an intended generic seam worth promoting.

### Shared Interaction Director

Normal player semantic dialogue already uses `InteractionDirector.Preview` / `Commit`.

`InteractionScene` uses the same Director through the Scheduler.

Therefore player dialogue and autonomous scenes already share the intended semantic reasoning authority:
- InteractionContext;
- evidence/provider projection;
- PragmaticResolver;
- beats/behaviors;
- InteractionPlan.

Do not create an NPC-specific resolver.

### Interaction Catalog and Dialogue Content

Production interaction beats/behaviors are derived from the generated Conversation Registry.

Existing generic social behaviors include:
- acknowledge memory/news/repair/reply/thanks;
- ask memory follow-up;
- challenge;
- clarify context;
- deescalate;
- reconcile;
- retaliate verbally;
- warn;
- world-event warning.

Existing beats include argument escalation, reconciliation and suspicious first contact.

This is already broader than combat.

## Production gaps

### 1. No production actor adapter

`InteractionProviders.RegisterActorAdapter` exists, but current registrations are test-only.

A production scene therefore lacks a canonical adapter from a managed Project Hoomans NPC into:
- actor disposition/condition/activity/capabilities;
- directed relationship/faction relation;
- knowledge/fact refs;
- evidence context.

Existing ActorConversationContext, relationship/faction services, NPC state and knowledge authorities should be composed; no duplicate actor model is needed.

### 2. No global scene runtime

Each `Scene.New` currently creates its own scheduler with `maxActiveScenes = 1`.

That is correct for isolated scene objects/tests but means scheduler-wide caps/metrics are not a real global production budget.

Production needs one runtime owner for:
- active scene registry;
- global admission/caps;
- scene identity;
- participant overlap policy;
- TTL/expiry;
- actor leave/death;
- visibility/LOD changes;
- event dispatch;
- metrics;
- inspection.

### 3. No generic semantic continuation

A scene can resolve B's response to A, but the selected behavior does not generically emit the next semantic turn.

Example desired chain:

```text
A SHARE_MEMORY
  -> B behavior ASK_MEMORY_FOLLOWUP
  -> semantic continuation B -> A ASK_MEMORY_FOLLOWUP
  -> A response
```

The continuation must use `InteractionPlan.behaviorAct`, topic, subject, grounded fact/event refs and explicit target policy.

Never parse B's realized EN/TL sentence.

### 4. Recipient and observer are not production-first concepts

The envelope already carries `actorID` and `targetID`, but NPC speech production transport remains mostly player-facing.

The runtime must distinguish:
- speaker/actor;
- semantic addressee/recipient;
- scene participants;
- nearby observers.

A player who overhears NPC A talking to NPC B must not receive semantic buttons merely because the line was visible.

### 5. Player lifecycle storage is intentionally player-pair shaped

The persistent Interaction Lifecycle state is keyed by `playerUUID | npcID` and owns player-facing continuity such as open questions/commitments and response windows.

Do not turn it into a generic NPC transcript database.

Autonomous Scene Runtime remains bounded/transient by default and shares the semantic core, not necessarily player-pair persistence.

### 6. No production opportunity/admission API

Features currently tend to call their own reaction/presentation paths.

We need a bounded provider contract where combat, gossip, faction, task, excursion and settlement systems can submit grounded semantic opportunities without owning a dialogue loop.

### 7. No Scene Observatory

Current Combat Observatory is adopter-specific.

The generic scene runtime needs bounded inspection of:
- scene admission;
- participants;
- actor->target;
- known facts/events;
- selected beat/behavior;
- continuation;
- LOD/presentation;
- suppression/termination;
- observer/recipient distinction.

## Architecture correction from the superseded combat-group plan

Do not build:
- `Combat Exchange Director` as a second semantic scene owner;
- combat-only participant/continuation machinery;
- faction-only conversation runtime.

Instead:
- Combat Cohort becomes an adopter/provider of scene participants and tactical facts;
- Combat Banter Arbiter remains combat chatter-budget authority and can gate combat opportunities/turn presentation;
- generic Scene Runtime owns multi-turn semantic scene mechanics.

## Performance conclusion

The existing Scheduler already points in the correct direction: event-driven, capped participants/turns, LOD-aware, no tick hook.

Productionization must preserve this:
- no per-NPC conversation polling;
- no all-faction scan;
- no all-world scene scan each frame;
- no generated-text reparsing;
- no transcript persistence;
- no routine LLM;
- candidate discovery reuses event-local sets or one bounded spatial query at admission only.
