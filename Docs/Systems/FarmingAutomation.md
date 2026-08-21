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
- `SPlantGlobalObject:removeObject()` through `SFarmingSystem:removePlant` when a
  plot is cleared or its selected crop changes.
- `SFarmingSystem:growPlant(plant, nil, true)` for the debug fast-grow action.
- `SFarmingSystem.instance:harvest(plant, liveNpc)` for harvesting and yield.
- The crop catalog is enumerated from `farming_vegetableconf.props`, including modded crops and their `seedTypes`.

The adapter does not dig or create farmland, and it does not replace vanilla
growth, yield, disease, weed, or season logic. Clearing a live plant uses the
vanilla remove-and-plow path so the plot remains a usable furrow. The debug
grow, water, harvest, and clear actions are explicit server-authorized tools;
ordinary automation remains bounded by the existing farming service.

## Plant selection and diagnostics

The plot action opens a dedicated plant selector. It refreshes the native
`farming_vegetableconf.props` catalog each time, counts matching seed types in
the base storage snapshot, and shows only crops with available seeds. Each
card displays the vanilla icon when available, the localized crop name, seed
quantity, growing-season months, growth time, water target, and temperature
metadata. Modded crop entries participate automatically when they register
the same vanilla farming properties; vanilla crops without explicit
temperature bounds show the Build 42 cold-stress rule instead.

The same modal provides `CHANGE SEEDS`, `TOGGLE AUTOMATION`, and `EDIT
RECTANGLE`. In a debug-enabled session it also provides `AUTO GROW`, `FORCE
WATER`, `HARVEST`, and `CLEAR PLANTS` controls. Changing the selected crop
clears existing vanilla plants in the plot before the new configuration is
stored.

## Work and inventory

Farmer task candidates are produced by the `farming` task provider. Plot reservations are exclusive, so two NPCs cannot work the same plot at once. Live work runs through the existing facility travel/scene behavior and executes one bounded vanilla operation per checkpoint.

Seeds and water are first looked up in the canonical/native NPC inventory. If missing, the service may collect one approved material from the colony primary storage through the existing production reservation transaction. Harvest output is captured back into the canonical inventory projection after vanilla harvest completes.

## Known Build 42 behavior

Annual vanilla harvests may remain in a `harvested` plant state instead of
immediately becoming a `plow` furrow. Hoomans leaves that normal automation
state alone; explicit crop changes and `CLEAR PLANTS` use the vanilla removal
and plow path. Replanting occurs once vanilla reports the square as a
plantable furrow; the `autoReplant` policy controls those post-harvest
furrows. This preserves the rule that players create and maintain vanilla
farming ground.

## Diagnostics

Facility snapshots expose a derived `farming` block and per-plot diagnostics such as `WAITING_FOR_WORLD`, `EMPTY_FURROW`, `NEEDS_WATER`, `HARVESTABLE`, and `WAITING_FOR_MATERIALS`. These values are runtime presentation data and are excluded from settlement persistence.
