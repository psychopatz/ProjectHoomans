# Architecture — Open-Ended Semantic Continuation & Combat Awareness

## Conversation continuation

Generated buttons are an ephemeral frontier over bounded discourse state, not a dialogue tree.

```text
typed/clicked semantic act
        -> DialogueContextState
        -> AffordanceContinuationPolicy
        -> GeneratedAffordanceProvider
        -> next contextual frontier
```

The recurrence policy suppresses only generated suggestions. Typed NLU remains unrestricted. A typed `I mean it` enters as neutral `REAFFIRM`; DiscourseResolver maps it to hostile reaffirmation only when bounded conversation history establishes active hostility. Strategy and stance remain session-only.

## Zombie observation

```text
getCell():getZombieList()
        -> PNC_WorldCensus          (only recurring population-wide traversal)
        -> PNC_SpatialIndex
        -> PNC_Perception frame     (per-NPC cached)
        -> PNC_ZombieObservation
              |-> combat thresholds
              |-> semantic SESSION evidence
              |-> event/presentation context
```

`PNC_ZombieObservation` performs no `getCell()` or `getZombieList()` traversal. Descriptive semantic bands are `none / few / several / horde / massive_horde`; tactical combat thresholds remain separate gameplay policy.

## Kill authority and retirement boundary

```text
PLAYER KILL
engine hit/death
  -> PsychopatzCore ZombieKillDetector
       |-> pure-client ZombieKillReport / server validation + dedupe
       |-> Hoomans KillBridge
              |-> threat attribution / SocialEncounterTracker
              |     -> durable only when meaningful
              |        (protection, shared danger, etc.)
              |
              -> SemanticCombatReactionService
                    -> ephemeral optional speech only

NPC KILL
CombatResolution authoritative death
  |-> engine:zombie_killed
  |-> SocialEncounterTracker neutralization/protection owner
  -> SemanticCombatReactionService
```

Retired from normal production:
- Hoomans `PNC_ClientZombieKillAudit`;
- `CombatAdapter_Witnesses`;
- `witnessed_player_kill` SocialEvent definition;
- per-routine-kill relationship memory;
- per-routine-kill conduct evidence;
- routine-kill debug controls for that retired event.

PsychopatzCore ZombieKillDetector is **not** retired: it is the reusable authority/MP transport mechanism. Its diagnostic printing is opt-in, so normal weapon hits/deaths do not perform console I/O.

## Routine reaction performance contract

For a player kill:
1. reserve one player reaction window;
2. if within the 5-second window, increment the bounded suppressed-kill count and return before spatial lookup;
3. when eligible, query `SpatialIndex.QueryNPCs` once;
4. exact floor/distance/visibility gate;
5. select at most two speakers;
6. derive a bounded semantic profile;
7. resolve authored semantic text and send presentation only for selected speakers.

Suppressed kills are summarized into the next event fact as `killBurstCount`. Routine kill speech has `memoryEligible=false` and `llmEligible=false`.

NPC self-kills use the same service, with per-speaker cooldown and at most two nearby player listeners.

## Reaction profile and authored content

`PNC_SemanticCombatReactionProfile` reads existing owners only:

```text
relationship + personality + NPCTraitContext
+ panic/stress + health + SpeechStyleContext
+ ZombieObservation
        -> semantic.combat.reaction_profile.v1
        -> role/style/mood/pressure
        -> semantic.combat.kill.<role>.<style>
        -> one of 3 authored variants
```

Styles: `aggressive, supportive, shaken, brave, reserved, cold, practical`.

Two canonical CodeBuilder shards keep the library modular:
- 21 witness families;
- 21 NPC-killer families.

Each style/role pool has three authored EN/TL variants. Selection uses existing bounded response-catalog anti-repeat behavior.

## Grounded follow-ups

Kill event facts may contain `happened/summary`, `quantity`, `health`, and `nextAction`. Existing semantic event-reference handling exposes only grounded offers:

- What happened?
- How many are around?
- Are you okay?
- What now?

Answers are resolved from the same event fact rather than reparsing rendered speech. Unsupported/stale facts retain the existing safe unknown behavior.

## Transient follow-up lifecycle

Routine ambient kill speech records its beat with `transientInteraction=true` and `meaningful=false`. `InteractionLifecycle` keeps that beat in `store.transient`, which is visible to live `Project/Resume` resolution but is deliberately excluded from `Lifecycle.Export` and `sharedEvents`.

Closing or TTL expiry discards the overlay. A subsequent real player semantic turn can promote the overlay into the normal pair/event store, because at that point the conversation itself—not the zombie kill alone—has become meaningful.

This is a reusable semantic presentation contract; it must not be replaced with a kill-specific ModData cache.

## Persistence boundary

Runtime-only:
- generated strategy recurrence;
- current zombie observation;
- routine kill semantic events;
- reaction profile/style;
- coalescing/cooldown counters;
- realized routine kill speech.

Existing persistent owners only:
- relationship/conduct memories for meaningful social events;
- compact Conversation Memory where registered;
- meaningful WorldKnowledge facts;
- SocialEncounterTracker outcomes such as protection/shared survival.

Routine zombie kills are deliberately absent from canonical durable social-event registration.
