# Abstract World Director Foundation

This document describes the first implementation pass of Project Hooman's
server-authoritative strategic simulation. It intentionally stops before
abstract combat resolution, hordes, raids, settlement warfare, or advanced
faction strategy.

## Ownership and integration

The server owns `PNC.AbstractWorldStore.Registry`, containing persistent
`groupsByID`, `locationsByID`, and bounded encounter reports. Clients never run
strategic decisions. Authorized clients receive sanitized snapshots only when
the Abstract World Director inspector requests them.

An abstract group does not replace existing records:

- `factionId` points to `PNC.Factions`.
- `homeCommunityId` points to `PNC.Communities` when applicable.
- `memberIds` point to canonical `PNC.Registry` NPC records.
- needs are read through `PNC.GroupNeeds` for legacy mobile factions instead of
  being duplicated.
- the group's strategic combat profile is separate from each NPC's live combat
  settings.

The existing `PNC_MobileGroupDirector` remains the generator for legacy mobile
factions. Once generated, the faction is imported as one persistent abstract
group and the World Director owns its offscreen movement. This removes the old
periodic whole-group teleport from the normal pump path.

## Modules and public APIs

### Shared

`PNC_DirectorConfig.lua`

- owns scheduler intervals, spatial/query limits, travel speed, active radius,
  archetype destination weights, and combat-profile weights;
- contains no authority or persistence logic.

`PNC_AbstractWorldTypes.lua`

- `NormalizeGroup(value, id)`
- `NormalizeLocation(value, id)`
- `NormalizeLocationRef(value)`
- `NormalizeCombatProfile(value)`
- `NormalizeRegistry(value)`
- `NewRegistry()`

All constructors accept missing older-save fields and provide bounded defaults.
Unknown/invalid records are skipped rather than crashing world load.

`PNC_Scheduler.lua`

The existing per-NPC timing wheel is preserved. The following independent job
API was added:

- `RegisterJob(name, interval, callback, options)`
- `UnregisterJob(name)`
- `SetJobEnabled(name, enabled)`
- `PumpJobs(worldHours)`
- `GetJobs()`

Intervals are explicit world hours for Director jobs. Callbacks receive a work
budget so large populations can be processed through rotating cursors.

### Server

`PNC_AbstractWorldStore.lua`

- owns the `PNC_AbstractWorld_v1` ModData boundary;
- exposes `Load`, `Save`, `EnsureLoaded`, `Touch`, `RegisterListener`, and
  `Emit`;
- limits persisted encounter history through configuration.

`PNC_AbstractLocationManager.lua`

- `Register(spec)` and `RegisterSite(site, spec)` lazily create locations;
- `DiscoverLoadedNear` examines only loaded buildings and has a hard candidate
  cap; it never scans the full meta-grid;
- `GetNearby` touches only coarse spatial buckets and then applies an exact
  radius check;
- `Arrive`, `Depart`, and `GetGroupOccupants` own location occupancy.

`PNC_AbstractGroupManager.lua`

- `Create`, `Get`, `List`, `Remove`
- `ImportMobileFaction`, `FindByFactionID`, `ReconcileMembers`
- `SetMission`, `SetState`
- `GetNeeds`
- `MarkCombatProfileDirty`, `MarkMemberChanged`
- `HasLiveMembers`, `RefreshLOD`
- `SynchronizeMembersAtLocation`

`PNC_AbstractTraversal.lua`

- `ScoreDestination` exposes the complete score component breakdown;
- `ChooseDestination` evaluates a bounded candidate set;
- `CalculateTravelHours`, `Begin`, `Arrive`, `ForceArrival` implement logical
  timer-based travel;
- `AdvanceTravelBatch` and `DecideBatch` use independent rotating cursors.

`PNC_AbstractEncounterDetector.lua`

- detects only shared-location overlapping occupancy in this phase;
- stores deterministic compact reports;
- marks reports `MATERIALIZATION_REQUIRED` when any player is within the active
  radius;
- never resolves combat.

`PNC_AbstractCombatProfile.lua`

- `Get(group, force)` returns a cached profile or rebuilds it;
- `Build(group)` aggregates canonical member state;
- `InvalidateForMember(npcId, reason)` provides an integration hook for future
  inventory, injury, death, and equipment events.

`PNC_WorldDirector.lua`

- imports existing communities/mobile factions;
- registers traversal, decision, and reconciliation jobs;
- exposes `Initialize`, `Pump`, `ForceUpdate`, `SetPaused`, and `GetMetrics`;
- delegates all actual domain work to the modules above.

`PNC_AbstractDirectorDebug.lua`

- builds sanitized snapshots;
- guards force update, force arrival, profile rebuild, and pause/resume actions.

### Client

`PNC_DirectorDebugModel.lua` converts snapshots into group, location, and detail
rows. `PNC_DirectorDebugWindow.lua` displays those rows and sends only approved
debug requests/actions.

## Traversal lifecycle

1. The decision job runs every configured 10 in-game minutes.
2. It queries nearby location buckets and scores at most the configured
   candidate count.
3. `group.mission` remains unchanged while `group.state` becomes `TRAVELING`.
4. Travel duration is straight-line distance divided by aggregate speed, with
   a small fatigue modifier and configured bounds.
5. The traversal job checks timers every configured 2 in-game minutes.
6. Arrival changes the logical location, synchronizes abstract NPC record
   coordinates, registers occupancy, and checks existing occupants.
7. No engine path request, physical movement, or individual action is created.

If any member becomes live, `RefreshLOD` changes the group to `ACTIVE`, removes
its abstract occupancy, and prevents strategic traversal. When all members are
abstract again, occupancy is restored and strategic processing can resume.

## Destination scoring

Scores are composed from aggregate resource potential, mission relevance,
archetype tag preferences, unvisited bonus, danger, distance, and scavenged
level. Every component is retained in transient diagnostics and exposed in the
inspector. Tuning lives in `PNC_DirectorConfig.lua`.

Locations are registered only when already relevant: existing community sites,
mobile-group staging sites, explicit API calls, or bounded discovery among
currently loaded buildings.

## Combat-profile cache

The profile represents capability, not willingness or encounter intent. It
tracks effective manpower, melee/ranged power, defense, mobility, morale,
experience, medical support, ammunition, condition, member count, combatant
count, and a convenient overall score.

Member role factors keep civilians/dependents from counting as full combatants.
Effective manpower uses a configurable exponent for diminishing returns.
Weapons are normalized into abstract categories, and ranged power is multiplied
by aggregate ammunition availability.

A persisted signature covers membership, role, health condition, weapons, and
group ammunition. `Get` returns the cached profile while that signature is
unchanged. Meaningful integration events can invalidate it explicitly. No
Director scheduler job rebuilds combat profiles continuously.

## Persistence

The strategic registry uses `PNC_AbstractWorld_v1`. Normalizers restore safe
defaults for missing mission/state, resources, simulation LOD, dirty flags,
occupants, combat profiles, and diagnostics. Existing NPC/faction/community
ModData keys are untouched. The store participates in the existing persistence
coordinator and also registers the normal save hook.

## Debug inspector

Open PsychopatzCore's Debug Hub and choose **Abstract World Director**. The tool
is available in local debug mode or to multiplayer admins.

The inspector provides:

- Director counts and persistence revision;
- all abstract groups and locations;
- mission/state and traversal timestamps;
- needs/resources;
- occupancy;
- cached combat profile and cache state;
- full destination score components;
- scheduled job intervals, run counts, and errors;
- recent encounter reports;
- force update, force arrival, rebuild profile, and pause/resume controls.

## Intentionally deferred

- encounter intent/relationship resolution beyond collision reporting;
- abstract casualties, injuries, morale checks, retreat, loot, and combat;
- zombie hordes;
- raids, extortion, trade execution, and player-search behavior;
- settlement generation, defense profiles, and warfare;
- abstract scavenging resource transfer;
- route-crossing encounters;
- a world-map overlay and full group materialization manager.

The existing community site resolver's legacy `FindRandomHouse` method scans the
meta-grid. The new Director does not call it; its own location discovery is
loaded-area-only and bounded.

## Validation

`tests/pnc_abstract_world_foundation_smoke.lua` covers destination selection,
travel timers, arrival, occupancy, player observation safety, encounter
detection, non-combatants, ammo scaling, cache invalidation, scheduler budgets,
and persistence round trips.
