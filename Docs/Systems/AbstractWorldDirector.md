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

## Population Director

`PNC.PopulationDirector` is the server-only population layer beneath
`PNC.WorldDirector`. It decides whether relevant parts of the world have a
population deficit and delegates creation; it does not own factions,
communities, NPC records, abstract groups, or materialization. Its supporting
modules are under `server/PNC/Director/Population/`:

- `PNC_PopulationSandbox` resolves every population Sandbox option once;
- `PNC_PopulationLog` emits and retains a bounded structured trace;
- `PNC_PopulationSectorManager` owns coarse indexes and persisted cooldowns;
- `PNC_PopulationBudget` calculates soft targets, healthy bands, and pressure;
- `PNC_GenerationQueue` bounds and deduplicates transient requests;
- the group and settlement plan/generator pairs validate before committing;
- `PNC_SettlementCandidateManager` discovers, scores, and reserves sites;
- `PNC_StarterPopulation` ensures an empty new world receives one canonical
  starter settlement before normal trickle generation;
- `PNC_PopulationReconciler` converts deficits into small queued requests;
- `PNC_CommunityGroupFormation` forms one supported scavenging party from
  existing, unassigned community members without creating new NPCs.

### Population sectors and targets

Population sectors are 1,000-tile strategic cells, intentionally coarser than
Abstract Location buckets. A compact spatial index maps sectors to abstract
group and canonical community IDs. Counts are updated on creation, removal,
and destruction and repaired by a bounded scheduled job. Derived indexes and
player positions are transient; they are rebuilt after load.

Players activate their sector and its immediate neighbors. Previously explored
sectors and sectors containing persistent groups or settlements remain
relevant. Candidate discovery first uses registered Abstract Locations and a
bounded slice of the currently loaded building list. When a requested sector
still has no usable site, group and settlement planning may query only the meta
buildings intersecting that one 1,000-tile sector. The one-time starter may try
at most four relevant sectors, preferring the outer player footprint so sites
can pass the anti-pop-in distance. Every meta query inspects only a seed-rotated
capped slice of the result and never walks the global building list.

Each relevant sector receives desired group and settlement counts. Targets
combine the resolved Sandbox density, relevance, world age, diminishing player
count growth, and distinct active-sector footprint. They are advisory. A target
has a lower healthy threshold and a separate fill-until value; generation starts
only below the lower threshold and stops before oscillating around an exact
ratio. Lowering a Sandbox target suppresses future creation and never removes
existing entities.

Pressure is `current / desired`. Neighbor pressure is a cheap average of the
eight adjacent sectors and only influences queue priority. Roaming population
counts exclude community-owned parties, so forming a settlement scavenging
party does not satisfy or inflate the world roaming-group target.

### Sandbox configuration

The Project Hoomans page exposes enum controls for NPC Population, Settlement
Density, Roaming Group Density, Population Regeneration, Settlement
Regeneration, Multiplayer Population Scaling, and Generation Distance From
Players. Density and recovery options resolve from Disabled through Very High.
Detailed rates, intervals, world-age weights, composition weights, distances,
and all hard caps remain centralized in `PNC_DirectorConfig.Population`.

Disabled population, group, or settlement settings stop the corresponding
automatic creation. Disabled recovery prevents a sector that previously held
that entity type from magically recovering, while initial population of a new
relevant sector remains a separate decision.

### Safety bands and rate limits

Every commit rechecks all server-known player positions. The minimum exclusion
radius is invalid, the restricted band is penalized for settlements, and the
preferred ring receives normal scoring. Plans therefore fail safely if a player
moves near the selected location after planning. Clients provide no coordinates,
factions, member IDs, counts, or normal generation commands.

Hard caps limit total groups and settlements, per-sector counts, queue length,
per-pump group and settlement commits, and NPC records created per population
pump. Queues expire, deduplicate by sector/type, and have bounded retry counts.
Population jobs use separate cadences for player refresh, group reconciliation,
settlement reconciliation, queue work, community-party formation, and index
repair. Startup applies a grace period and one dry reconciliation before any
deficit can create entities.

### Roaming group generation

A group deficit selects an underrepresented supported archetype using configured
composition pressure, world-age weights, and a deterministic weighted roll.
Site choice receives a smaller seeded variation after safety and distance
scoring. The plan contains a stable generation ID, deterministic seed, sector,
archetype, canonical faction archetype, member count, mission, and registered
location. Validation rechecks
the deficit, hard caps, cooldown, sector relevance, faction template, site, and
player exclusion.

The Project Zomboid `WorldGenParams` seed string is hashed once into persisted
population state. Group archetypes, settlement faction archetypes, candidate
tie-breaking, member counts, and community-party seeds all derive from that
world seed plus generation type, sector, and serial. Weighted choices are
therefore varied between worlds but repeatable inside the same save.

Commit creates a canonically named/tagged mobile faction and delegates NPC
creation to `PNC.MobileGroupDirector` with an explicit bounded site and `auto`
presence, then imports the result through `PNC.AbstractGroups`. An unloaded site
starts abstract, but its members remain eligible for the normal range-enter
materialization pipeline when a player visits. The
legacy mobile Director remains a relocation/helper layer; it is not a second
automatic population generator. Failed canonical creation rolls back members
and a newly created faction. Successful groups enter the existing traversal,
action, encounter, and combat loop.

### Settlement candidates and generation

Candidate pools contain only registered or boundedly discovered locations in a
relevant sector. An empty or wholly ineligible pool can invoke the same
sector-local meta-building fallback used by group planning. Cheap filters reject
missing canonical sites, player claims,
occupied sites, another generation reservation, destroyed-site cooldowns,
player exclusion, and hard settlement spacing. Eligible sites score aggregate
food, water, shelter/defensibility, danger, preferred spacing, player distance,
site history, tags, and data-driven faction preferences. No detailed building
geometry, pathfinding, or fortification analysis runs.

Reservations are transient, generation-scoped, expiring, and always released on
success or failure. A settlement plan selects an underrepresented reusable
non-player, non-mobile faction when possible; otherwise it creates one canonical
faction from an existing archetype. Commit revalidates the plan, delegates
community/site/member/leader ownership to `PNC.CommunityDirector`, promotes the
existing Abstract Location to `SETTLEMENT`, updates indexes and provenance, and
emits the population event. Initial members are small canonical NPC records
using the same generated faction/community names, tags, equipment, affiliation,
and `auto` presence rules as guarded debug creation. A startup migration clears
the obsolete `forceAbstract` runtime override from population-generated records
in existing saves. Patrol/scavenge groups are not created in that transaction.

Community-party reconciliation later forms at most the configured supported
party budget. The initial implementation forms a scavenging party only when a
community has enough living unassigned members. It never creates NPCs to fill a
party budget and leaves richer patrol/trade/raid budgeting to later behavior
work.

On an empty new world, the first authority tick with an available player queues
a priority-100 starter settlement and a priority-90 seeded roaming group using
bounded meta-building candidates. This starter package is the only population
work allowed to bypass the normal startup grace; both entries still use the
normal plan/validate/commit queues and a separate one-time NPC-record budget.
Single-player therefore receives the package as soon as the world/player are
ready, while a dedicated server waits for its first connected player. The first
successful canonical community is persisted as the starter settlement. A
throttled runtime probe and bounded hourly retry remain active until success;
normal regeneration, density budgets, cooldowns, and seeded generation continue
afterward behind the dry/grace pass.

### Regeneration and persistence

Destroyed roaming groups start a sector group cooldown. Destroyed communities
start a much longer sector settlement cooldown and write bounded site history
with an additional same-site block. Recovery multipliers shorten or lengthen
these configured cooldowns without bypassing hard rates. The system does not
continuously refill dead settlement members and does not simulate births or
recruitment.

The existing `PNC_AbstractWorld_v1` registry remains the save boundary. It now
optionally normalizes a `population` section containing sector discovery and
cooldowns, generation sequence, bounded committed-generation IDs, entity
provenance, bootstrap state, and destroyed-site history. Abstract groups and
locations normalize optional provenance/history fields. Canonical NPC
persistence retains generation provenance. Queues, plans, candidate pools,
reservations, counts, indexes, player positions, and debug history are transient
and safely recomputed after restart.

### Population debugging

The existing Abstract World Director Debug Hub now displays global desired,
current, deficit, and pending counts; player footprint; resolved Sandbox
multipliers and safety distances; per-sector pressure, cooldown/suppression
reasons; queue high-water marks; generation outcomes; candidate scoring or
rejection details; and bounded recent history. Suppression reasons include no
deficit, irrelevant sector, cooldown, player proximity, hard cap, missing site,
spacing, queue pressure, and NPC rate limits.

Admin-authorized controls exercise the real pipeline: reconcile population,
queue an automatic group or settlement request for the selected sector, clear
cooldowns, rebuild the index, and pause/resume population generation. Population
events remain server-internal and are not broadcast as generation history to
joining clients.

The hub includes a selectable Population Sectors column and exposes the engine
world seed/population seed, starter status and attempts, per-sector candidate
pools, meta-query match/inspection counts, candidate rejection details,
pending queue records and their provenance/expiry, transient site reservations,
cooldown time remaining, suppression reasons, persistence dirty state, and the
latest bounded Population Director log. Guarded controls can retry the starter,
discover sites for the selected sector, process one population queue pump, and
clear the transient population log without bypassing generation validation.

The authorized world-map `NPC WORLD` control is enabled by default and renders
canonical settlement geometry plus current abstract refugee, looter, scavenger,
and wanderer group markers. The Faction Inspector's NPC World Overlay toggle
controls the same map visibility. Both layers refresh their guarded server
snapshots in single-player and multiplayer; they do not expose strategic state
to unauthorized multiplayer clients.

The Director also writes bounded, structured server log entries with the
searchable `[PopulationDirector]` prefix. Startup/grace transitions, resolved
Sandbox settings, player-footprint changes, queue decisions, suppression
reasons, deterministic generation IDs/seeds, commit failures, successful
commits, cooldown changes, and destruction are included. The latest entries
are mirrored in the authorized Population debug section; the in-memory trail
is capped and is rebuilt after restart.

Startup uses two bounded bootstrap passes. At the end of the 30-minute
in-game grace period the first pass is dry and records deficits without
creating anything. Fifteen in-game minutes later, the second pass may enqueue
real work through the normal validated generation pipeline. Normal group and
settlement reconciliation then continues at its slower configured cadence.

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
