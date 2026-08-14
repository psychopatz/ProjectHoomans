# Facility authoring

Facilities are registered in `PNC_FacilityDefinitions.lua`. Give each definition
a catalog `category`, build/reconstruction work values, and one or more levels.
The build catalog currently recognizes `housing`, `food`, `production`,
`technology`, and `utilities`.

Each level declares capabilities and `componentLimits`. Component kinds are:

- `region`: a connected, placeable room/zone inside the facility footprint.
- `anchor`: a physical interaction point inside the footprint. Anchors occupy
  one tile by default; set `fixedTileCount` for special multi-tile objects.
- `abstract`: a non-placeable module. Adding or removing one creates a shared
  reconstruction work order, while NPC interaction still resolves to a physical
  anchor.

Use `requiredTechnology` on the facility definition to gate initial construction,
and on a level to gate that upgrade. Research only unlocks the capability; the
Base tab still queues the construction work that applies the upgrade.

## Water Collector example

`water.spigot` is its physical anchor. `water.tank` and `water.catcher` are
abstract modules whose maximum count is four per facility level. Each tank holds
25 liters and each catcher adds one liter per ten in-game minutes while raining.
The utility service ticks on `EveryTenMinutes` and derives collection from elapsed
world age, so unloaded/off-screen bases do not need per-frame simulation.
