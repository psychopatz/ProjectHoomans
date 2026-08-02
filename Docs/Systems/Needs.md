# Needs

## Purpose

Phase 1 establishes low-cost survival-condition state without attempting to
simulate vanilla survival mechanics for every NPC. Need values are reserves:
`100` is healthy/supplied and `0` is depleted. Lower is always worse.

The initial Need types are `hunger`, `hydration`, and `fatigue`. Fatigue is a
rest reserve in this model: a higher fatigue value means a better-rested owner.

## Fidelity models

### Individual Needs

Player-owned or recruited NPC records lazily receive:

```lua
record.needs = {
    version = 1,
    hunger = 100,
    hydration = 100,
    fatigue = 100,
    lastUpdateWorldAge = 0,
}
```

Eligibility is the existing companion ownership state: `recruited == true`,
`ownerUsername`, or `ownerOnlineID`. Autonomous NPCs do not receive this table
merely because they belong to a faction.

### Group Needs

An active mobile faction stores one aggregate state at `faction.needs`:

```lua
faction.needs = {
    version = 1,
    hunger = 100,
    hydration = 100,
    fatigue = 100,
    lastUpdateWorldAge = 0,
}
```

This state represents the group's overall food, water, and rest condition; it
does not assign a survival value or exact inventory to each member. Stationary
communities are not automatically treated as mobile groups.

## Authority, persistence, and migration

All mutations occur on the server. NPC Needs are serialized through
`PNC.Persistence`; group Needs are part of the existing normalized faction
record and therefore use the existing `PNC_Factions` persistence lifecycle.

Older saves with no Need state remain valid. State is initialized lazily and
uses `version = 1` for future Need-specific migrations. Runtime debug histories
and profiler data are never serialized.

## Simulation contract

`PNC.NeedsScheduler` runs at a 30-second real-time cadence and advances each
owner analytically from `lastUpdateWorldAge` to current world age. It does not
perform per-second updates, world searches, pathfinding, container scans,
inventory iteration, or individual group-member simulation.

Group depletion is calculated from centralized base rates, group-size modifier,
abstract activity modifier, and elapsed world hours. Supported Phase 1
activities are `idle`, `traveling`, `scavenging`, `fighting`, `resting`, and
`at_home`. Resting recovers the fatigue/rest reserve. The current implementation
only provides a persisted debug activity override; it does not alter existing
mobile-group AI.

## Public APIs

Individual API (`PNC.IndividualNeeds`):

- `Ensure(record)`, `Get(record, needType)`, `Set(...)`, `Modify(...)`
- `GetLevel(record, needType)`, `Update(record, elapsedHours)`,
  `UpdateToNow(record)`, `Reset(record)`
- `InitializeFromGroup(record, groupNeeds)` is the transition foundation for a
  future group-member-to-companion conversion.
- `GetActivity(record)`, `SetActivityOverride(record, activity)`, and
  `GetRates(record)` centralize companion activity effects.
- `GetPriority(record, needType)` and `GetHighestPriority(record)` expose
  survival pressure to AI without allowing Needs to choose navigation/actions.

Group API (`PNC.GroupNeeds`):

- `Ensure(faction)`, `Get(faction, needType)`, `Set(...)`, `Modify(...)`,
  `Restore(...)`
- `GetLevel(faction, needType)`, `GetRates(faction)`, `Update(...)`,
  `UpdateToNow(...)`, `Reset(...)`
- `SetDebugActivity(...)` and `DebugAbstractScavenge(...)` are test tools only.

Every mutation clamps to the definition bounds and accepts an optional reason,
such as `passive_decay`, `debug_simulate_time`, or
`debug_abstract_scavenge`.

## Condition hooks

Levels are centralized as `GOOD` (75–100), `STABLE` (50–74), `LOW` (25–49),
`CRITICAL` (10–24), and `EMERGENCY` (0–9). A group callback runs only when a
level changes:

```lua
PNC.GroupNeeds.RegisterListener("level_changed", function(
    factionID, needType, oldLevel, newLevel, reason
)
    -- Future survival-pressure AI belongs here.
end)
```

Do not call Project Zomboid's `triggerEvent` for this hook. Engine events must
be declared by the game, so Needs uses its own guarded listener registry.
`UnregisterListener(eventName, listener)` removes a callback.

Companion level transitions use the same guarded listener pattern through
`PNC.IndividualNeeds.RegisterListener("level_changed", function(record,
needType, oldLevel, newLevel, reason) ... end)`. The current activity set is
`idle`, `walking`, `running`, `fighting`, `working`, `traveling`, `resting`,
and `sleeping`; their rate modifiers are centralized in
`PNC_NeedsDefinitions`.

## Colony Management

`PNC.ColonyManagement` builds an on-demand, server-authoritative presentation
for the current player's existing owned/recruited companions. It does not add
a second colony record or aggregate canonical Need pool. The summary derives:

- companion roster, role, activity/job, health state, and individual reserves;
- per-Need condition-level counts;
- ordered LOW/CRITICAL/EMERGENCY attention entries;
- the first active existing Community belonging to the player's faction, when
  that data exists.

`PNC_ColonyManagementWindow` provides `OVERVIEW`, `PEOPLE`, and `NEEDS` pages.
It is opened from the vanilla in-game radio window. The single visible action
is labelled `Colony Management`; when other mods register radio actions, the
same core button becomes a `Mod Services` menu instead of crowding the radio
screen. Community resource numbers are deliberately absent unless a future
cached/indexed resource source is introduced.

## Debugging

`NPC Needs Debug` is registered in the PsychopatzCore debug hub. It requests
server-owned snapshots and offers group and individual modes, condition/rate
details, a 40-entry runtime-only history, Need selection, clamped set/modify
controls, reset, simulated elapsed time, group activity override, and debug
abstract scavenging. The profiler is opt-in so normal simulation does not time
or count updates.

Debug networking is request/action based. Need values are not continuously
broadcast to clients.

## Explicitly out of scope

- destination selection or autonomous scavenging AI;
- food/water searches, container scans, and exact group inventories;
- NPC eating, drinking, sleeping, moodles, relationships, or personality
  effects;
- individual Need records for every autonomous group member.
