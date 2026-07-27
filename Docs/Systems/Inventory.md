# Inventory

## Purpose
- `PNC_Inventory` owns the player-like NPC inventory tree: hands, worn items, attachments, carried containers, and nested bag contents.
- abstract NPC simulation reads compact carry summaries instead of walking the full container tree every tick.

## Owned Data
- `inventory.revision`
- `inventory.equipped`
- `inventory.worn`
- `inventory.attached`
- `inventory.items`
- `inventory.containers`
- template-plus-delta persistence state for recruited and unrecruited NPCs
- stable semantic template keys and generator revision
- identity-seeded starting equipment selection and entry-provided grants
- derived carry caches such as used and remaining weight
- revision-bound summaries that do not require full inventory hydration

## Public Functions
- `PNC.Inventory.CreateFromTemplate(record)`
- `PNC.Inventory.RegisterEquipmentSpawnPool(poolID, specification)`
- `PNC.Inventory.AddEquipmentSpawnEntry(poolID, category, entry)`
- `PNC.Inventory.GetEquipmentSpawnPool(poolID)`
- `PNC.Inventory.GetDebugEquipmentSpawnMode(variant)`
- `PNC.Inventory.ChooseEquipmentSpawnEntry(poolID, category, seed, salt, validator)`
- `PNC.Inventory.ResolveStartingEquipment(record)`
- `PNC.Inventory.EnsureRecordInventory(record)`
- `PNC.Inventory.ApplyDelta(record, ops, reason)`
- `PNC.Inventory.GetWeightState(record)`
- `PNC.Inventory.BuildSummaryPayload(record)`
- `PNC.Inventory.BuildFullPayload(record)`
- `PNC.Inventory.BuildDeltaPayload(record, sinceRevision)`
- `PNC.Inventory.Serialize(record)`
- `PNC.Inventory.Deserialize(record, rawInventory)`

## Module Layout
- `PNC_Inventory.lua` is the stable subsystem facade and load-order entry point.
- `PNC_Inventory_Model.lua` loads focused model modules for runtime/revision state,
  container membership, and item/carry-cache mechanics.
- `Equipment/PNC_Inventory_EquipmentGeneration.lua` owns generic categorized
  pools, weighted identity-seed selection, validation, and starting-equipment policy.
- `common/.../PNC/EquipmentDefinitions/PNC_EquipmentPools.lua` is the editable
  built-in equipment catalog shared by supported game versions.
- `PNC_Inventory_Templates.lua` owns deterministic template generation.
- `PNC_Inventory_Equipment.lua` loads record hydration and legacy equipment-sync modules.
- `PNC_Inventory_Mutations.lua` validates and records inventory operations.
- `PNC_Inventory_Payloads.lua` builds summary, full, and incremental network payloads.
- `PNC_Inventory_Persistence.lua` owns the public serializer/hydrator and delegates
  template-delta encoding and replay to its delta codec.

Implementation modules communicate through `PNC.Inventory.Internal`; consumers should
continue to call only the public `PNC.Inventory` functions.

## Equipment Generation

Equipment pools are independent of NPC archetypes. The built-in `Default` pool
currently defines `meleeWeapon` and `rangedWeapon` categories. More categories
can be added later for medical supplies, loose ammunition, tools, or other
starting equipment without changing the pool service:

```lua
PNC.Inventory.AddEquipmentSpawnEntry("Default", "medical", {
    type = "Base.Bandage",
    weight = 4,
})
```

Entry grants allow selected equipment to provide related items. The built-in
firearms use grants for matching ammunition:

```lua
PNC.Inventory.AddEquipmentSpawnEntry("Default", "rangedWeapon", {
    type = "Base.Pistol",
    weight = 5,
    grants = {
        {
            key = "ammo_9mm",
            type = "Base.Bullets9mm",
            stack = 24,
            preferredContainer = "bag",
        },
    },
})
```

The melee and ranged weapon chances are independent. Consequently an NPC can
spawn unarmed, melee-only, ranged-only, or with both weapons. The ranged weapon
becomes active when both are generated; the melee weapon remains in inventory
as a reserve. `NPCMeleeWeaponSpawnChance` and `NPCRangedWeaponSpawnChance`
control the rolls from 0–100 in sandbox settings; their defaults are 70% and
20%, respectively.

Selection uses `identitySeed` and stable category salts, so the same identity
receives the same equipment regardless of NPC archetype and across multiplayer,
save/load, and template rebases. Explicit debug melee/ranged variants set a
persistent generation override and bypass the chances; ordinary debug spawns
use the normal chance policy.

For built-in content, edit `PNC/EquipmentDefinitions/PNC_EquipmentPools.lua`;
the generation service should remain free of item lists.

## Forbidden Responsibilities
- does not own persistence schema migration
- does not broadcast packets directly
- does not decide AI jobs
- does not materialize world items on its own

## Load-Order Contract
- skill-derived carry capacity resolves `PNC.Skills` when inventory creation runs, because inventory is loaded before the skills subsystem during shared bootstrap
- do not capture later-loaded collaborators in file-local variables at module load time
- generator updates rebase the current template and replay valid semantic deltas
- generator version 2 moves built-in starting items into generic equipment pools
