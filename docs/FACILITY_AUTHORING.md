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

## Hydration note

Hydration is not authored as a settlement facility. NPCs first use a valid
drinkable fluid item in their inventory, then fall back to a clean valid world
source such as a sink or well. World-source discovery is wider than the final
interaction range so NPCs can path to an adjacent tile; the server validates
the source and consumes the water only at the interaction step.
