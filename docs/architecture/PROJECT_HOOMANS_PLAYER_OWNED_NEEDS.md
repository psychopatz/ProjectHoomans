# Player-Owned NPC Needs and Nutrition

## Scope and authority

Detailed needs exist only for recruited or otherwise player-owned NPCs. Mobile
factions retain their lightweight strategic group needs. The server is the sole
authority for simulation, consumption, health consequences, and persistence;
clients receive scoped colony and diagnostics snapshots only.

The canonical meters are `hunger`, `thirst`, and `fatigue`. All use pressure
semantics: `0` is fully satisfied and `1` is maximum pressure. Severity is
derived as `NORMAL`, `MINOR`, `MODERATE`, `SEVERE`, or `CRITICAL`.

## Runtime ownership

`PNC_IndividualNeeds` owns need and nutrition commands and queries.
`PNC_NeedsRepository` owns the separate player-owned state store and dirty
flag. `PNC_NeedsScheduler` evaluates at most 100 owned NPCs per 30-second pump;
each record advances analytically from its transient last-evaluated time, with
a 168-game-hour catch-up bound. No per-frame NPC update is used.

Traits are resolved by `PNC_PlayerNeedsModel.GetRateModifiers` through the
single contract `{ hungerRate, thirstRate, fatigueRate, calorieBurnRate }`.

## Nutrition and consumption

Nutrition is `{ calories, weight }` and is independent from hunger. Food can
add calories even when hunger is already at maximum fullness. Inventory and
provisioning own acquisition and consumption, then call `ApplyFood` or
`ApplyDrink` with effects derived from Project Zomboid item properties. This
keeps vanilla and modded food compatible without item-name tables.

## Persistence

The only accepted persistence format is compact v1:

```lua
{ v = 1, at = worldHour, n = {
    [npcId] = { hungerPermille, thirstPermille, fatiguePermille,
        caloriesInteger, weightDecikg },
} }
```

`at` is one shared persisted timestamp. Per-NPC evaluation timestamps are
runtime-only. There is intentionally no legacy needs migration. Permanent NPC
removal also removes its repository entry.

## Consequences and tuning

Critical hunger and thirst accrue elapsed damage only for time spent above the
critical threshold. `Player-Owned NPC Need Mortality` defaults to OFF; in that
mode need damage cannot reduce health below the configured safe floor. When ON,
prolonged critical pressure can eventually kill. Maximum pressure itself is not
an instant-death trigger.

Central rates, thresholds, scheduler size, catch-up bound, nutrition bounds,
and the safe floor live in `PNC_NeedsDefinitions`.

## Extension checklist

1. Add new tuning to `PNC_NeedsDefinitions`, not a consumer.
2. Extend the central rate-modifier contract when adding physiological traits.
3. Keep acquisition/consumption inside Inventory or Provisioning and pass an
   effect into Needs.
4. Change the compact codec only with an explicit new schema version.
5. Add targeted authority, persistence, mortality, and 1000-record scale tests.
