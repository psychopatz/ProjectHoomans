# Architecture — Open-Ended Semantic Continuation & Combat Awareness

## Conversation continuation

Generated buttons are an ephemeral frontier over the current discourse state, not a dialogue tree.

```text
typed/clicked semantic act
        |
        v
DialogueContextState (bounded session turns)
        |
        +-- intent / speechAct
        +-- generated strategy / stance when present
        |
        v
AffordanceContinuationPolicy
        |
        v
GeneratedAffordanceProvider
        |
        v
new contextual frontier
```

The recurrence policy suppresses only generated suggestions. It never blocks typed NLU.

A typed reaffirmation such as `I mean it` enters as neutral `REAFFIRM`. DiscourseResolver maps it to `HOSTILE_REMARK` only when bounded conversation history establishes active hostility; otherwise it becomes ordinary acknowledgement. This preserves typed/button parity without making the phrase globally hostile.

Strategy and stance live only in the existing bounded DialogueContextState turn history. They are never persisted.

## Zombie observation

```text
getCell():getZombieList()
        |
        v
PNC_WorldCensus            <- only recurring population-wide traversal
        |
        v
PNC_SpatialIndex
        |
        v
PNC_Perception frame       <- per-NPC, cached
        |
        v
PNC_ZombieObservation      <- two radius counts over same frame
        |
   +----+-----+----------------+
   |          |                |
combat       social         semantics
thresholds   episode hook   SESSION evidence
```

`PNC_ZombieObservation` never calls `getCell()` or `getZombieList()`. It caches runtime observations and is invoked from the already scheduled live-NPC record processing lane.

Descriptive bands are canonical:

- none: 0
- few: 1–2
- several: 3–5
- horde: 6–11
- massive_horde: 12+

Compatibility labels for existing social/world-knowledge presentation are derived from this classifier. Tactical thresholds such as `COMBAT_HORDE_COUNT` remain independent gameplay policy.

## Kill observation

```text
player kill
PsychopatzCore ZombieKillDetector
          |
          +-------------------+
                              v
                       engine:zombie_killed
                              ^
          +-------------------+
          |
NPC CombatResolution -> authoritative killed result
```

Both paths carry actor kind and stable actor/threat identity when available. No routine kill is persisted merely because this event exists.

`SocialEncounterTracker` remains authoritative for encounter aggregation and `killsByParticipant`. Existing meaningful social outcomes such as protection/shared survival remain the persistence boundary.

## Witness performance

Normal player-kill witness discovery:

```text
kill position
    -> SpatialIndex.QueryNPCs(radius)
    -> exact floor/distance
    -> existing bounded visibility checks
    -> social event
```

`Registry.ForEachLive` is retained only as a compatibility fallback when the spatial index is unavailable.

## Persistence boundary

Runtime-only:

- generated strategy recurrence;
- zombie observation snapshot;
- current zombie-pressure evidence;
- routine kill notifications;
- derived relevance.

Existing persistent owners only:

- relationship/conduct memories;
- compact Conversation Memory;
- meaningful WorldKnowledge facts;
- existing social encounter outcomes.

No new ModData root is allowed by this job.
