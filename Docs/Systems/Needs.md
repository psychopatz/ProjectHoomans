# Needs

## Purpose

Needs use the same normalized direction and bounds as Build 42 `CharacterStat`:
`0` is satisfied and `1` is the maximum hunger, thirst, or fatigue deficit.
Higher is always worse. Food and fluid effects retain their native values, so
an item with `HungerChange = -0.15` removes `0.15` NPC hunger.

The initial Need types are `hunger`, `hydration` (vanilla thirst), and
`fatigue`.

## Fidelity models

### Individual Needs

Player-owned or recruited NPC records lazily receive:

```lua
record.needs = {
    version = 2,
    hunger = 0,
    hydration = 0,
    fatigue = 0,
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
    version = 2,
    hunger = 0,
    hydration = 0,
    fatigue = 0,
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

Older saves with no Need state remain valid. Version 1 reserve values migrate
with `deficit = 1 - reserve / 100`; the conversion is performed once when the
state is normalized. Runtime debug histories and profiler data are not saved.

## Simulation contract

`PNC.NeedsScheduler` runs at a 30-second real-time cadence and advances each
owner analytically from `lastUpdateWorldAge` to current world age. It does not
perform per-second updates, world searches, pathfinding, container scans,
inventory iteration, or individual group-member simulation.

Needs and Provision are two related supply lanes, not a single linear pipeline.
Needs requests immediate personal consumption through `NeedSupplyBridge`, while
Provision evaluates target carry stock and may acquire deficits from accessible
colony storage. Both use the authoritative `NPCSupplyService` and canonical
Inventory mutation boundary.

At the standard 60-minute day, the installed Build 42 constants are expressed
as world-hour rates of `0.0432` base awake hunger, `0.03456` thirst, and
`0.044712` fatigue. Hunger follows the player's remaining-appetite factor
`(1 - hunger)`; running, fighting, and sleeping select their corresponding
vanilla hunger rate. Item effects are never rescaled: `HungerChange = -0.20`
removes `0.20` hunger and `ThirstChange = -0.15` removes `0.15` thirst.

Group accumulation is calculated from centralized base rates, group-size modifier,
abstract activity modifier, and elapsed world hours. Supported Phase 1
activities are `idle`, `traveling`, `scavenging`, `fighting`, `resting`, and
`at_home`. Resting slows awake fatigue accumulation, as vanilla does. The current implementation
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
such as `passive_increase`, `debug_simulate_time`, or
`debug_abstract_scavenge`.

## Condition hooks

Levels use the installed Build 42 moodle thresholds. Hunger transitions at
`0.15/0.25/0.45/0.70`, thirst at `0.12/0.25/0.70/0.84`, and fatigue at
`0.60/0.70/0.80/0.90`. A group callback runs only when a level changes:

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
`PNC_PlayerNeedsModel`.

## Vanilla physiological traits

NPC physiological traits are stored in `record.vanillaTraits` as a boolean map
and persisted with the NPC. Spawn definitions may provide `vanillaTraits` or
the legacy alias `physiologicalTraits`. `PNC.PlayerNeedsModel.SetTraits` is the
authoritative mutation API.

When a spawn definition does not author a trait set, the canonical NPC record
receives a deterministic selection based on its permanent `identitySeed` and
archetype. The generator independently considers thirst, appetite, sleep need,
sleep quality, and body-weight groups. Neutral outcomes remain most common and
the Build 42 mutual exclusions are enforced. Generated traits are versioned and
saved, so they never reroll on materialization or reload. Supplying an explicit
empty `vanillaTraits = {}` intentionally creates a traitless NPC. Legacy NPCs
without trait metadata receive the same deterministic initialization during
load or their next individual-Needs update.

The Build 42 multipliers are preserved: High Thirst `2.0`, Low Thirst `0.5`,
Hearty Appetite `1.5`, Light Eater `0.75`, Wakeful/Needs Less Sleep `0.7`
awake fatigue, and Sleepyhead/Needs More Sleep `1.3`. Insomniac halves sleep
recovery and Night Owl multiplies it by `1.4`. Weight traits are retained in
the same trait map but do not directly modify hunger or thirst, matching the
base game; they belong to the nutrition, weight, endurance, and movement model.
The NPC Character window displays the assigned vanilla trait names using the
base game's own translated trait labels.

## Project Hoomans dynamic traits and secondary stats

`PNC.ConditionStats` adds player-like secondary condition values without
duplicating the relationship system's existing morale:

- `stress`: native-style `0..1`, higher is worse;
- `boredom`: native-style `0..100`, higher is worse;
- `panic`: native-style `0..100`, higher is worse;
- `record.social.morale`: existing `-100..100` social morale, displayed by the
  same reusable meter UI.

Stress reacts to unmet primary needs and negative social morale. Idle/resting
time raises boredom while purposeful activity reduces it. Fighting raises
panic; safe time recovers it. All updates remain elapsed-world-hour based and
run in the existing Needs scheduler rather than adding a second timer.

NPCs also receive one deterministic outcome from each custom trait group:

- **Iron Nerves / Frayed Nerves** alter stress and panic gain/recovery;
- **Busy Hands / Restless Soul** alter boredom gain/recovery;
- **Hardy Constitution / Delicate Constitution** alter hunger and thirst gain;
- **Second Wind / Heavy Sleeper** alter fatigue behavior and sleep recovery.

The custom set is stored separately at `record.dynamicTraits`, persists without
rerolling, and supports authored `dynamicTraits` (or `pncTraits`) spawn values.
An explicit empty table disables generated custom traits for that NPC.

## Colony Management

`PNC.ColonyManagement` builds an on-demand, server-authoritative presentation
for the current player's existing owned/recruited companions. It does not add
a second colony record or aggregate canonical Need pool. The summary derives:

- companion roster, role, activity/job, health state, and individual deficits;
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

The client shell uses `PNC.ColonyManagementClient`, published by the canonical
`PNC_ColonyManagement.lua` entry, as its only snapshot/request boundary. The
gateway projects the replicated snapshot, revision, and receive time and sends
the existing colony-management snapshot request. The controller owns selection,
tab binding, and snapshot-to-row coordination; the window owns interaction,
layout delegation, rendering, and refresh timing. Neither controller nor window
reads raw `PNC.Network.ClientState` or calls `PNC.Client` directly. Server
snapshot construction and all colony/settlement/storage policy remain unchanged.

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
- full calorie/macronutrient body-weight simulation and thermoregulation;
- individual Need records for every autonomous group member.

## Load-Order Contract

Server Needs loading remains deliberately interleaved: Individual Needs loads
before Facility Jobs, which consumes it, while the scheduler loads later after
Director dependencies. Do not collapse this sequence or rely on alphabetical
filenames. Any future canonical Needs entry must preserve that runtime timing
and pass SP, hosted-MP, and dedicated-server startup validation.
