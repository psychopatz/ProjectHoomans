# S0 Baseline — Semantic Interaction Scene Runtime

**Revision characterized:** ProjectHoomans `37b97906`.
**Scope:** production-grounded authority/boundary characterization only.

## Existing foundation

The existing Scene stack is already generic rather than combat-specific.

`PNC_SemanticInteractionScene`:
- supports explicit 2–4 participant scenes;
- accepts direct NPC semantic acts and grounded world events;
- projects responder actor/relationship/knowledge through InteractionProviders;
- uses InteractionScheduler -> InteractionDirector;
- stores bounded semantic history only;
- realizes through InteractionPresentation;
- reports `transcriptStored=false`;
- never reparses generated dialogue.

`PNC_SemanticInteractionScheduler` is explicitly event-driven and has no tick hook.

Current hard ceilings:
- active scenes: 16 at Scheduler level;
- participants: 4;
- turns: 8;
- recent events: 8;
- Scene semantic history: 8;
- nearby distance: 60.

LOD:
- `player_full` and `nearby_perceived`: speech/emote/flavor permitted;
- `nearby_unperceived` and `distant`: semantic-only.

## Current production gaps frozen by S0

### Per-scene scheduler construction

`Scene.New()` currently constructs a private Scheduler with `maxActiveScenes=1`.

Therefore Scheduler's 16-scene ceiling is not yet a real production-global budget.

### Actor adapter

`InteractionProviders.RegisterActorAdapter` is public and tested.

At the audit revision, production source contains no Project Hoomans adapter registration. Registrations exist only in tests.

### Shared Director authority

Normal player dialogue:
- previews through `InteractionDirector.Preview`;
- commits through `InteractionDirector.Commit`.

InteractionScene reaches the same Director through `scheduler:HandleStimulus`.

Therefore Scene productionization must reuse this authority rather than add an NPC resolver.

### Player lifecycle storage remains pair-shaped

Persistent Interaction Lifecycle state is keyed:

```text
playerUUID|npcID
```

and owns player-facing continuity including open questions/commitments.

This is not the correct storage model for autonomous NPC scenes. Scene state remains bounded/transient and shares the semantic core instead of expanding this player-pair store into a transcript database.

### NPCSpeech already carries directed identity

`InteractionLifecycle.Envelope.NPCSpeech` preserves:
- `actorID`;
- `targetID`.

Production presentation remains mostly player-centric; the directed semantic carrier itself does not need replacement.

### Generic stimuli are already defined

The canonical stimulus contract includes:
- HUMAN_UTTERANCE;
- NPC_SEMANTIC_ACT;
- EMOTE;
- AMBIENT_SOCIAL_OPPORTUNITY;
- WORLD_EVENT;
- FACTION_EVENT;
- TASK_EVENT;
- DANGER_CHANGED;
- ACTOR_JOINED;
- ACTOR_LEFT;
- WITNESSED_DEATH.

Outside the stimulus module, the opportunity/faction/actor-join/actor-left semantic types are not currently wired as production SceneRuntime event sources.

## Safety invariants frozen by S0

Future phases must preserve:
- no generated-text reparsing;
- no Scene/Scheduler tick loop;
- no autonomous-scene ModData transcript;
- bounded participants/turns/history;
- shared InteractionDirector;
- player-pair lifecycle remains a player frontend unless a later explicit migration is separately justified.

## S0 verification

```text
python3 tests/run_tests.py   pnc_semantic_interaction_scene_smoke   pnc_semantic_interaction_scheduler_smoke   pnc_semantic_interaction_provider_smoke   pnc_semantic_scene_runtime_s0_contract_smoke --jobs 4
```

S0 acceptance requires this matrix green before S1 production actor-adapter work.
