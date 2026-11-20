# Abstract Travel, Mobile-Group Handoff, and Materialization Plan

## Status

**ACTIVE L6 DEVELOPER WORK.**

L6 now has three required workload families:

1. continuous FollowOwner movement;
2. combat-hit contact spikes;
3. compact abstract/mobile-group travel with deterministic nearby materialization and safe return to abstraction.

The third workload covers NPCs that are not following a player and should not run rich physical simulation while far away. Their route must progress from elapsed world time and compact Core journey state; ProjectHoomans should materialize rich physical actors only when a player becomes relevant to the projected route position.

## Code-verified architecture

ProjectHoomans mobile/abstract traversal already uses Core journey authority.

`PNC_AbstractTraversal_Travel.lua` delegates group travel to `PNC_CoreGroupTraversalBridge`. The bridge delegates canonical time/projection semantics to PsychopatzCore `GroupJourney` / SurvivorWorld traversal.

Core `GroupJourney.Advance`:

- advances from elapsed world time, not per-frame physical simulation;
- supports planned, en-route, waiting, paused, arrived, cancelled, and blocked states;
- can cross route segments and waits in one large time step;
- projects x/y/z and deterministic progress from the canonical route;
- preserves journey identity/revision and ETA.

Core `ProjectMemberPosition` projects an actor from its actor-specific journey when one exists, otherwise from its group's projected journey position.

ProjectHoomans `AbstractTraversal.Advance` first refreshes group LOD. If any member is live, the group uses active simulation instead of abstract advancement. If fully abstract and traveling, Core journey advancement continues.

ProjectHoomans Presence decides materialization by the record's current projected position and player distance. Travel `OnMaterialized` advances the journey to current world time, then syncs the fresh live body; `OnAbstracted` syncs the last live body position back into route progress and returns the journey controller to abstract.

This is the architecture the integrated simulator must exercise end-to-end.

## Primary invariant

A mobile/travelling actor has **one continuing journey** across representation changes:

~~~text
Core compact actor/group + canonical journey
       |
       | elapsed world time
       v
projected abstract position
       |
       | player becomes relevant
       v
Hoomans promotion/materialization
       |
       | same journey, live controller
       v
physical route movement
       |
       | player leaves relevance
       v
capture live progress + remove body
       |
       | same journey, abstract controller
       v
elapsed-time projection resumes
       |
       v
arrival exactly once
~~~

Materialization is a representation transition, not a new trip.

## Required simulator workload

Extend the existing Lightweight NPC Runtime simulator. Do not create a second mobile-group simulator.

Use deterministic world-hour advancement and deterministic player trajectories.

### `ABSTRACT_ROUTE_FAR`

Create a compact group at point A with a canonical route to point B and no player near any member.

Advance simulated world time through multiple steps.

Verify:

- journey ID remains stable;
- progress/x/y/z match canonical Core projection;
- member projection follows group projection unless an actor journey overrides it;
- no live body is created;
- no unnecessary Hoomans rich record is promoted solely because time advances or map/debug projection is queried;
- abstract position refresh does not emit per-step full snapshots;
- persistence only marks/coalesces actual changed travel state as designed;
- work scales with active abstract journeys, not with per-frame physical AI.

### `ABSTRACT_ROUTE_TIME_LEAP`

Advance a journey with a large world-time jump representing sleep, accelerated time, or a server/session gap.

The implementation must not replay every intermediate frame/tick.

Verify one bounded advancement can correctly:

- cross multiple route segments;
- consume waits;
- arrive if enough time elapsed;
- update ETA/progress deterministically;
- trigger arrival exactly once.

Compare a large jump against many smaller deterministic steps and require equivalent canonical final journey state.

### `ABSTRACT_ROUTE_PLAYER_INTERCEPT`

A player begins far from the projected route, then moves so the current projected group/member position enters the materialization radius.

Verify:

1. the actor stays abstract while outside interest;
2. materialization eligibility uses the **current projected position**, not the original departure point or stale staging site;
3. promotion/materialization is bounded by existing admission/materialization budgets;
4. the actor appears at a safe deterministic position corresponding to its current route progress;
5. `OnMaterialized` preserves journey identity and does not rewind distance travelled;
6. controller changes to live;
7. live target is the current/next route waypoint;
8. no duplicate actor/body/provider lease is created.

Exercise 1/3/6/12-member groups.

### `ABSTRACT_ROUTE_PLAYER_EXIT`

After materialization, move the player outside the live envelope.

Verify:

- the live body is safely abstracted;
- live body x/y/z are projected back into journey progress without moving the journey backwards;
- route/path state owned by the live body is released;
- controller becomes abstract;
- the actor resumes elapsed-time projection from the captured route progress;
- no duplicate or ghost body remains;
- later rematerialization uses the same actor and journey.

Run repeated enter/exit cycles to expose boundary thrash.

### `ABSTRACT_ROUTE_ARRIVAL`

Let a group finish its route while fully abstract and while temporarily materialized near its destination.

Both lanes must converge to the same canonical arrival:

- journey state = arrived;
- final location is the destination;
- group state/location is reconciled;
- member projection/location is synchronized correctly;
- mobile travel/activity state is cleared or transitioned according to production lifecycle;
- encounters/visit/arrival action execute at most once;
- subsequent pumps do not re-run arrival or restart the journey.

### `ABSTRACT_ROUTE_LIVE_STALL_HANDOFF`

Materialize one travelling actor and inject a live movement stall.

Exercise the existing live travel recovery/escalation contract.

Verify:

- bounded native recovery attempts;
- fallback/replan is bounded;
- persistent journey is not discarded by one path failure;
- when live travel can no longer be served and the player is outside the required live range, the presence lane can hand back to abstract progression;
- one stalled member does not corrupt other group members' route state;
- terminal failure occurs only after the documented escalation limit.

### `ABSTRACT_ROUTE_MP_INTEREST`

Use two simulated players whose interest regions overlap the same travelling group.

Verify:

- one authoritative actor/journey;
- one live body per actor;
- materialization candidate discovery deduplicates overlapping players;
- one player leaving does not abstract the actor while another player still owns the live envelope;
- no double promotion, double materialization, or duplicate arrival.

## Required scale matrix

At minimum run:

- group size: 1 / 3 / 6 / 12;
- simultaneous travelling groups: 1 / 10 / 50 / 100;
- far-only abstract case;
- one player intercepting one group;
- player crossing a stream of several groups;
- several groups becoming relevant in a short interval.

The point is not to make 100 groups live. The test should prove that 100 distant compact journeys remain cheap while only the nearby relevant subset consumes Hoomans live-body work.

## Required counters

Expose bounded operation counters for:

### Compact/Core journey
- journey advances;
- projected-position queries;
- route segment transitions;
- waits entered/completed;
- arrivals;
- arrival handler attempts/successes;
- Core group commits caused by travel;
- travel persistence marks/writes.

### Hoomans representation
- Core actor promotions;
- Hoomans runtime records created;
- materialization candidates;
- materialization attempts/success/failure/defer;
- live bodies;
- abstractions;
- demotions;
- duplicate/blocked promotion attempts.

### Live travel
- live travel ticks;
- move intents/path requests;
- live progress syncs;
- live stalls;
- recoveries;
- forced handoffs;
- route failures.

### Shared hot paths
- spatial-index updates;
- materialization interest scans;
- network presence/domain deltas;
- full snapshots;
- persistence pump work;
- maximum promotion/materialization work in one simulated frame;
- profiler-OFF average/p95/max simulator tick CPU.

## Determinism gate

For fixed actor/group IDs, route, departure world hour, speed, wait durations, player trajectory, and world-time sequence, repeated runs must produce equivalent canonical journey state and materialization decision ordering.

Representation changes must not alter the final abstract route outcome.

The following should converge to equivalent canonical position/progress when compared at the same world hour:

1. remain abstract for the entire trip;
2. materialize once in the middle then abstract;
3. materialize/abstract multiple times;
4. save/reload mid-route then continue.

## Save/reload gate

Persist during:

- ordinary abstract travel;
- immediately before materialization;
- while live mid-route;
- immediately after abstraction;
- during a route wait;
- shortly before arrival.

After reload require:

- same canonical actor/group identity;
- same journey ID;
- equivalent route/progress/revision;
- no duplicate body;
- no restart from A;
- no instant teleport to B unless elapsed world time legitimately reaches B;
- no duplicated arrival action.

## Performance rules

Do not solve this workload by keeping travellers permanently live.

Do not make every abstract traveller a full Hoomans persistent record.

Do not iterate every route for every server frame when elapsed-time projection can be performed at an appropriate bounded cadence or on demand.

Map/debug/portrait/discovery projections must not promote actors.

Do not send a network packet for every tiny abstract coordinate change. Use the existing compact/revision/projection model and interest-based correction where appropriate.

Do not materialize an entire distant group merely because one projection was queried.

Materialization should remain proximity/interest driven and budgeted.

## L6 abstract-travel acceptance

This workload passes only when:

1. compact journeys progress deterministically from world time;
2. large time jumps do not require replaying intermediate frames;
3. distant travelling groups stay compact/bodyless;
4. nearby projected actors materialize deterministically and under budget;
5. materialization preserves journey progress and identity;
6. live -> abstract handoff preserves or advances progress, never rewinds it;
7. repeated range crossings do not duplicate bodies/actors or thrash unboundedly;
8. arrival executes once and converges between abstract/live lanes;
9. save/reload preserves mid-route continuity;
10. multiplayer overlapping interest does not duplicate authority;
11. 10/50/100 distant groups scale primarily as compact journey work while Hoomans live work scales with the nearby subset;
12. existing Core journey, mobile-group, presence, lazy promotion/demotion, travel, persistence, and replication tests remain accepted.

The parent L6 phase is not complete until follow-walk, combat-hit, abstract-travel/materialization, inventory/ModData scale, and the mandatory cross-system composition gates all pass.

## Required cross-system stress scenarios

These are **mandatory L6 acceptance scenarios**, not optional follow-ups. The three isolated workload families establish attribution and clean baselines; these combined scenarios prove that accepted fixes still compose correctly when lifecycle, travel, combat, persistence, networking, and observation overlap.

### `COMBINED_SAVE_RELOAD_PRESSURE` — save/reload under live pressure

A player with followers is moving while a nearby mobile group is materialized and combat is active; save/reload must converge without duplicate bodies, stale routes, or lost faction/owner state.

### `COMBINED_MATERIALIZE_COMBAT` — materialization + immediate combat

A travelling hostile group enters player range and begins combat shortly after materialization. Verify promotion/materialization, aggro, attack, damage, and later abstraction do not double-register social/faction/network state.

### `TRAVEL_MEMBER_DEATH_HANDOFF` — death/removal mid-journey

Kill or permanently remove one group member while the group is abstract, live, and during handoff. The dead actor must not rematerialize, remain in active group membership incorrectly, or create dangling persistence/provider data.

### `TRAVEL_ARRIVAL_STORM` — arrival storm

Several compact groups reach destinations in the same world-time window. Verify arrival actions, encounters, mobile visits, persistence, and notifications remain bounded and execute once.

### `OBSERVATION_PROJECTION_LOAD` — map/debug observation load

Continuously query map/mobile-group/debug projections for many distant travelling actors. Observation must remain side-effect-free: no promotion, no materialization, no extra persistence authority, and no full snapshot storm.

### `PLAYER_FAST_INTEREST_JUMP` — player teleport / fast interest jump

Move the player from far away directly onto a later point of a route. The next interest pass must use current projected positions and bounded materialization rather than stale origins or replaying travel.

### `PROVIDER_HANDOFF_TRAVEL` — provider handoff / mod-agnostic traveller

Exercise a Core actor/group journey owned or initiated by another compatible provider, then temporarily materialize through Hoomans. Core remains canonical and Hoomans must not steal durable journey authority.

### `LONG_WORLD_ENDURANCE` — long-world endurance

Advance many simulated days with repeated departures, arrivals, visits, deaths, recruitment, and group changes. Track object/table counts, dirty queues, tombstones, extension sizes, and runtime indexes to detect leaks or monotonically growing transient state.

## Cross-system acceptance rules

The combined scenarios may reuse the same deterministic fixtures and counters as the four primary workload families. Do not duplicate production logic in test-only implementations.

Required assertions include:

- no duplicate Core actor, Hoomans runtime record, provider lease, or live body during compound transitions;
- no journey rewind/restart when materialization, combat, save/reload, death, or provider handoff overlaps travel;
- no full-snapshot or synchronous persistence storm merely because several domains changed in one short interval;
- death/removal cleanup prevents later rematerialization and clears only the dead actor's valid memberships/references;
- arrival, kill, visit, social/faction, and semantic transition hooks remain idempotent;
- map/debug observation remains read-only even while the world is changing;
- player teleport/fast travel uses current projected state and bounded admission rather than stale positions;
- another provider may retain Core journey authority while Hoomans temporarily owns only physical representation;
- long-world endurance shows bounded dirty queues, runtime indexes, tombstones, transient diagnostics, and extension state rather than monotonic leakage.

The fast smoke should include `COMBINED_MATERIALIZE_COMBAT` and a short `PLAYER_FAST_INTEREST_JUMP` case because they directly exercise visible gameplay spikes. The heavier benchmark/endurance lane should own the remaining compound scenarios and multi-day leak checks.

## Inventory composition additions

The mandatory cross-system matrix also includes the inventory-pressure scenarios defined in [INVENTORY_MODDATA_STRESS.md](INVENTORY_MODDATA_STRESS.md):

- `COMBINED_INVENTORY_FOLLOW`
- `COMBINED_INVENTORY_COMBAT`
- `COMBINED_INVENTORY_MATERIALIZATION`
- `COMBINED_INVENTORY_SAVE_RELOAD`

These ensure large inventories do not silently reintroduce follow, hit-contact, materialization, or persistence spikes.

