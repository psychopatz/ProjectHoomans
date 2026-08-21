# Farming Automation

The first farming vertical slice treats Project Zomboid Build 42.20 as the farming authority. Project Hoomans stores only facility configuration and asks the vanilla farming system to inspect and mutate crops.

## Domain model

- Facility: `farm` / logical type `FARM`.
- Spatial component: `growing.plot` / logical type `GROWING_PLOT`.
- Level 1 provides two plot slots; level 2 provides four.
- Every plot is one connected, single-level rectangle no larger than 4 x 4 tiles.
- A plot is accepted only when at least one selected tile contains a vanilla `SPlantGlobalObject` in state `plow`.
- Persisted plot data is limited to the component id, facility id, rectangle, desired crop, policy, and schema version. Vanilla crop state is never serialized by Hoomans.

## Vanilla authority boundary

`PNC_PZFarmingAdapter` uses the server-side Build 42 APIs:

- `SFarmingSystem.instance:getLuaObjectAt(x, y, z)` for plant lookup.
- `SPlantGlobalObject:seed(typeOfSeed, skill)` for planting.
- `SPlantGlobalObject:water(nil, uses)` for watering.
- `SFarmingSystem.instance:harvest(plant, liveNpc)` for harvesting and yield.
- The crop catalog is enumerated from `farming_vegetableconf.props`, including modded crops and their `seedTypes`.

The adapter does not dig, plow, create farmland, advance growth, calculate yield, or reproduce disease/weed/season logic. If the world or farming object is unavailable, the Farmer remains in `WAITING_FOR_WORLD` and no crop or inventory state is simulated.

## Work and inventory

Farmer task candidates are produced by the `farming` task provider. Plot reservations are exclusive, so two NPCs cannot work the same plot at once. Live work runs through the existing facility travel/scene behavior and executes one bounded vanilla operation per checkpoint.

Seeds and water are first looked up in the canonical/native NPC inventory. If missing, the service may collect one approved material from the colony primary storage through the existing production reservation transaction. Harvest output is captured back into the canonical inventory projection after vanilla harvest completes.

## Known Build 42 behavior

Annual vanilla harvests may remain in a `harvested` plant state instead of immediately becoming a `plow` furrow. Hoomans does not remove or re-plow that object. Replanting occurs once vanilla reports the square as a plantable furrow; the `autoReplant` policy controls those post-harvest furrows. This preserves the rule that players create and maintain vanilla farming ground.

## Diagnostics

Facility snapshots expose a derived `farming` block and per-plot diagnostics such as `WAITING_FOR_WORLD`, `EMPTY_FURROW`, `NEEDS_WATER`, `HARVESTABLE`, and `WAITING_FOR_MATERIALS`. These values are runtime presentation data and are excluded from settlement persistence.
