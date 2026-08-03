# Abstract World Director

Project Hooman's Abstract World Director is the server-authoritative strategic
simulation for persistent offscreen survivor groups. It works only with compact
persistent records, timers, bounded spatial queries, cached combat profiles,
utility scores, and a few aggregate combat rounds. It never pathfinds, moves a
physical NPC, opens a container, swings a weapon, or simulates a bullet.

Zombie hordes, settlement warfare, raids, advanced trade/diplomacy, route
crossings, and a materialization manager remain outside this system.

## Authority and ownership

The authority owns `PNC.AbstractWorldStore.Registry`, persisted in
`PNC_AbstractWorld_v1`. The registry contains groups, locations, bounded
encounter reports, encounter-pair cooldowns, and the next encounter serial.
Clients receive only sanitized, admin-authorized Debug Hub snapshots.

Abstract records reference canonical systems rather than replacing them:

- `factionId` resolves through `PNC.Factions`;
- `homeCommunityId` resolves through `PNC.Communities`;
- `memberIds` resolve through `PNC.Registry`;
- physiological group reserves come from `PNC.GroupNeeds`;
- injuries and death use `PNC.NPCWounds` and `PNC.Health`;
- live/abstract presence remains owned by the existing presence system.

Combat Profile answers what a group can do. Behavior Profile answers what it is
willing to do. Encounter Context describes the current contact. The Intent
Evaluator chooses an action. The Combat Resolver runs only when violence is
actually selected or a hostile interaction escalates.

## Modules

Shared configuration and persistence-safe constructors live in:

- `PNC_DirectorConfig.lua`
- `PNC_AbstractWorldTypes.lua`

Server domain modules are:

- `PNC_AbstractWorldStore.lua` — persistence and local event bus;
- `PNC_AbstractLocationManager.lua` — bounded discovery, spatial buckets, and occupancy;
- `PNC_AbstractGroupManager.lua` — group lifecycle and canonical integrations;
- `PNC_AbstractTraversal.lua` — destination scoring and timer travel;
- `PNC_AbstractResourceNeeds.lua` — normalized resource shortages;
- `PNC_AbstractActionResolver.lua` — registered action lifecycle;
- `PNC_AbstractScavengeResolver.lua` — aggregate scavenging;
- `PNC_AbstractCombatProfile.lua` — cached capability;
- `PNC_AbstractBehaviorProfile.lua` — stable willingness and desperation;
- `PNC_AbstractEncounterDetector.lua` — occupancy collisions, safety, and deduplication;
- `PNC_AbstractEncounterEvaluator.lua` — relationship, threat, and intent utilities;
- `PNC_AbstractEncounterResolver.lua` — bounded queue and encounter outcomes;
- `PNC_AbstractCombatResolver.lua` — bounded aggregate combat;
- `PNC_AbstractCasualtyResolver.lua` — canonical injury/death application;
- `PNC_AbstractRetreatResolver.lua` — morale break and fallback travel;
- `PNC_WorldDirector.lua` — scheduling and orchestration only;
- `PNC_AbstractDirectorDebug.lua` — sanitized snapshots and guarded controls.

## Group lifecycle

The normal survivor loop is:

```text
IDLE / ACTION_COMPLETE
  -> destination selection
  -> TRAVELING
  -> ARRIVED
  -> PERFORMING_ACTION
  -> ACTION_COMPLETE
  -> fresh destination decision
```

Mission and state remain separate. A scavenger at work has mission `SCAVENGE`,
state `PERFORMING_ACTION`, and a persisted action record containing type,
location, start/end times, status, and deterministic seed. `ARRIVED` is only a
transition. Reaching a location starts the registered action for the mission;
finishing an action never silently resumes an old target.

The `AbstractActions` scheduler job advances only groups with active action
timers, through a rotating cursor and configured work budget. Encounters can
interrupt an action through one central API. Interrupted actions award no full
yield. A materializing group also clears its action without applying a result.

## Needs-aware destinations

`PNC_AbstractResourceNeeds.Get` maps the canonical group need state and current
aggregate reserves into shortages from `0` (supplied) to `1` (critical) for:

```text
food, water, ammo, medical, materials
```

Food and water include canonical hunger/hydration plus strategic reserves.
Other shortages compare reserves with bounded per-member targets. Destination
resource value is computed once through this API, then combined with archetype,
mission, tags, danger, distance, depletion, and recent-threat penalties.

A recently avoided hostile location receives a large temporary penalty. Safe
fallback selection is a separate bounded query that avoids the current threat
location and already occupied/dangerous candidates.

## Aggregate scavenging

Scavenging starts only at the action's location and consumes configured world
time. At completion it calculates one aggregate yield from:

- location resource potential;
- remaining factor derived from `scavengedLevel`;
- normalized resource need;
- bounded, diminishing effective scavenger contribution;
- small deterministic variance.

No containers or items are created. Yield is clamped per category, added to the
group's aggregate resources, and used to restore canonical hunger/hydration
through `PNC.GroupNeeds`. Depletion increases only when resources are actually
found. Empty or fully ineffective groups do not deplete a location.

The seed combines group ID, location ID, and action start-time minute bucket.
The same persisted action reproduces the same duration and yield components.
Diagnostics retain potential, need, remaining factor, scavenger factor,
variance, raw yield, final yield, and depletion before/after.

## Behavior and desperation

Behavior Profile is configured per abstract archetype and can blend existing
faction policy values. Stable fields are normalized from `0` to `1`:

```text
aggression, bravery, greed, caution, mercy, discipline, civilianHostility
```

It remains separate from Combat Profile. Encounter-time context adds morale,
condition, mission, normalized shortages, and desperation. Desperation combines
food, water, medical, ammunition, morale, and condition shortages using central
weights. Derived contextual values are rebuilt cheaply for an encounter rather
than treated as permanent character state.

## Collision, context, and intent

Arrival registers occupancy before checking the location. A collision creates
a compact report and a queue entry; it never calls combat directly. Pair,
location, and cooldown data prevent the same occupancy overlap from resolving
every scheduler tick. Cooldown storage and completed history are bounded.

The `AbstractEncounterQueue` scheduler job processes a configured number of
reports per run. Each participant has an `activeEncounterId` lock. A queued
three-group overlap therefore resolves sequentially, and later contacts are
revalidated after earlier outcomes move or alter a group.

Before any mutation, the resolver rechecks the active player radius. If a
player could observe the encounter, the report becomes
`MATERIALIZATION_REQUIRED`; no intent outcome, transfer, combat, casualty,
death, or retreat mutation occurs.

An encounter context contains participant IDs, location, directed faction
relationship, cached combat profiles, behavior contexts, relative strength,
threat details, observation state, and seed. Relationship state comes from
`PNC.Factions.GetRelation`; no second diplomacy system exists.

Every group scores:

```text
IGNORE, AVOID, FLEE, NEGOTIATE, EXTORT, ROB, ATTACK
```

Utilities use archetype behavior, relationship, desperation, morale,
condition, relative strength, and bounded deterministic jitter. Friendly state
strongly suppresses extortion, robbery, and attack. Capability alone does not
make a cautious group aggressive, while an aggressive group still avoids an
overwhelming opponent. Reports retain all scores and component inputs.

## Non-combat outcomes

- `IGNORE` and `NEGOTIATE` record the outcome and let valid actions continue.
- `AVOID` interrupts the current action and selects an alternate location while
  preserving the strategic mission.
- `FLEE` records previous mission context, applies a morale/resource pressure
  penalty, marks the location/group as recently hostile, switches to mission
  `FLEE`, and begins safe fallback travel. Arrival requests a fresh decision.
- `EXTORT` and `ROB` evaluate target compliance from caution, morale, and
  relative strength. Compliance transfers a bounded fraction of food, water,
  ammo, and medical resources without allowing negative reserves. Refusal
  escalates only when the aggressor's utility context justifies attack.
- Compliant robbery interrupts the target's action. Combat and flight always
  interrupt affected actions.

## Aggregate combat

Combat uses the existing cached Combat Profiles. Each configured round derives
effective offense, defense, mobility, and morale from overall power, melee and
ranged contribution, manpower, defense, condition, terrain category, and
bounded variance. Environment metadata is coarse; unknown locations use neutral
modifiers.

At most `MAX_ABSTRACT_COMBAT_ROUNDS` execute. Each side creates aggregate
casualty pressure against the other. Pressure converts into bounded counts of
minor, serious, critical, and dead casualties; there is no per-member attack or
target loop. Randomness is seeded from encounter/location/participant/time data
and cannot dominate large capability differences.

Ranged contribution consumes aggregate ammunition every round. Serious and
critical casualties can consume aggregate medical resources. Both mutations
are clamped and included in the encounter result.

## Morale, retreat, and casualties

Morale falls from received pressure and casualties. Low morale, severe strength
disadvantage, and recent losses trigger a retreat check influenced by mobility,
caution, and discipline. Successful retreat ends combat and begins `FLEE`
travel. A failed attempt lowers morale and may allow another bounded round.
Ordinary groups therefore tend to withdraw rather than fight to extinction.

After aggregate severity counts are known, the casualty adapter selects actual
persistent members deterministically. Combat roles and existing condition
influence exposure; one member receives at most one result in an application.
Injuries use `PNC.NPCWounds.ApplyCombatDamage`. Death uses `PNC.Health.Kill`,
which remains the canonical death/faction/community/persistence boundary.
Membership is immediately reconciled against surviving canonical records and
Combat Profile is marked dirty.

Results distinguish victory, stalemate, withdrawal, and destruction and retain
round pressure, effective values, morale changes, retreat checks, injuries,
deaths, ammunition/medical use, winner, reason ended, and seed.

## Events

The Abstract World Store's local event bus emits action start/completion/
interruption, scavenging completion, encounter evaluation/resolution,
extortion/robbery, combat start/round/resolution, retreat/avoidance, and member
injury/death events. Relationship memories and future rumor systems subscribe at
this boundary; encounter formulas do not mutate relationship memory directly.

## Persistence and compatibility

The registry remains `PNC_AbstractWorld_v1`. Added fields are optional and
normalized safely: action, previous mission, morale, behavior profile, encounter
lock/recent encounter, recent avoided locations/groups, and pair cooldowns.
Malformed performing-action state without a valid action returns to `ARRIVED`.
Stale encounter locks are cleared when the Director initializes. Persisted
queued reports are re-enqueued after load. Queue entries are transient; reports
and seeds are persistence-safe.

Combat Profile signatures continue to cover membership, role, health,
equipment, weapons, and aggregate ammunition. Casualties and resource changes
invalidate through the existing dirty APIs; dynamic intent modifiers are not
part of the signature.

## Debugging and metrics

Open PsychopatzCore's Debug Hub and select **Abstract World Director**. Local
debug/admin users can inspect:

- mission, state, current action, timing, location, and target;
- canonical needs, normalized shortages, resources, and morale;
- Combat Profile, signature/dirty reason, Behavior Profile, and desperation;
- destination and scavenging score components;
- active/recent encounter IDs, all intent utilities, and encounter reports;
- combat rounds, pressure, casualties, morale, retreat, and resource use;
- scheduler jobs and queue/action/combat/retreat/casualty metrics.

Guarded controls support force update/arrival, profile or behavior rebuild,
start/complete scavenging, encounter evaluation, and pause/resume. They use the
existing authorized debug transport and never expose strategic mutation to
ordinary clients.

## Intentional deferrals

This phase does not implement zombie hordes, group-vs-horde combat, settlement
warfare, settlement defense, territory conquest, full raids, advanced trade or
dialogue, route-crossing encounters, player hunting, a world-map overlay,
item-by-item battlefield recovery, or a new materialization framework.

## Validation

`tests/pnc_abstract_world_foundation_smoke.lua` retains the Phase 1 traversal,
occupancy, observation, cache, scheduler, and persistence coverage with the new
queued/action transitions. `tests/pnc_abstract_world_phase2_smoke.lua` covers
needs-aware destinations, action persistence, scavenging/depletion/
determinism, behavior and desperation, relationship-aware intent, extortion,
combat strength/ammunition/bounds, canonical casualties, observation safety,
deduplication, reentrancy locks, and save/load compatibility.
