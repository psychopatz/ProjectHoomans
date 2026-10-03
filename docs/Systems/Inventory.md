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
- per-firearm `ammoCount`, persisted and replicated as part of the inventory item
- `inventory.containers`
- template-plus-delta persistence state for recruited and unrecruited NPCs
- stable semantic template keys and generator revision
- identity-seeded starting equipment selection and entry-provided grants
- one canonical `Base.IDcard` per generated NPC, named from the identity and
  carrying the NPC UUID/name as item modData for future kill/identification quests
- derived carry caches such as used and remaining weight
- revision-bound summaries that do not require full inventory hydration
- bounded portable item state with deterministic primitive-only modData

## Public Functions

The canonical `PNC_Inventory.lua` entry also exposes boundary-oriented command
aliases:

- `PNC.Inventory.Commands`: `EnsureRecordInventory`, `ApplyDelta`, `AddItems`,
  `RemoveItems`, and `RebuildCaches`.

These are direct aliases. Existing `PNC.Inventory.*` functions remain the
compatibility surface and have identical behavior.

- `PNC.Inventory.CreateFromTemplate(record)`
- `PNC.Inventory.RegisterEquipmentSpawnPool(poolID, specification)`
- `PNC.Inventory.AddEquipmentSpawnEntry(poolID, category, entry)`
- `PNC.Inventory.GetEquipmentSpawnPool(poolID)`
- `PNC.Inventory.GetDebugEquipmentSpawnMode(variant, requestedMode)`
- `PNC.Inventory.ChooseEquipmentSpawnEntry(poolID, category, seed, salt, validator)`
- `PNC.Inventory.ResolveStartingEquipment(record)`
- `PNC.Inventory.EnsureRecordInventory(record)`
- `PNC.Inventory.ApplyDelta(record, ops, reason)`
- `PNC.Inventory.CanAccept(record, itemSpecs)`
- `PNC.Inventory.AddItems(record, itemSpecs, containerID, reason)`
- `PNC.Inventory.RemoveItems(record, itemIDs, reason)`
- `PNC.Inventory.SetEquipped(record, slot, itemID, reason)`
- `PNC.Inventory.SetWorn(record, itemID, wornSlot, reason)`
- `PNC.Inventory.ClearWorn(record, itemID, reason)`
- `PNC.Inventory.EquipPrimary(record, itemID, reason)`
- `PNC.Inventory.GetWeightState(record)`
- `PNC.Inventory.BuildSummaryPayload(record)`
- `PNC.Inventory.BuildFullPayload(record)`
- `PNC.Inventory.BuildDeltaPayload(record, sinceRevision)`
- `PNC.Inventory.Serialize(record)`
- `PNC.Inventory.Deserialize(record, rawInventory)`

## Module Layout
- `PNC_Inventory.lua` is the stable subsystem facade and load-order entry point.
  It loads internal modules in explicit dependency order and publishes the
  command aliases only after those implementations have loaded. Legacy helpers
  that lazily hydrate or normalize inventory are not mislabeled as read-only
  queries.
- `PNC_Inventory_Model.lua` loads focused model modules for runtime/revision state,
  container membership, and item/carry-cache mechanics.
- `Equipment/PNC_Inventory_EquipmentPools.lua` owns pool normalization,
  registration, and weighted identity-seed selection.
- `Equipment/PNC_Inventory_EquipmentGeneration.lua` owns starting-equipment
  policy, grant routing, and pool integration.
- `common/.../PNC/EquipmentDefinitions/PNC_EquipmentPools.lua` is the editable
  built-in equipment catalog shared by supported game versions.
- `PNC_Inventory_Templates.lua` owns deterministic template generation;
  `PNC_Inventory_TemplateSupplies.lua` builds archetype supply grants.
- `PNC_Inventory_Equipment.lua` loads equipment synchronization and hydration.
  Import normalization and bounded audit formatting are separate equipment
  modules; water item normalization and native water runtime calls have their
  own adapters.
- `PNC_Inventory_Mutations.lua` validates and records inventory operations.
- `InventoryActions/PNC_InventoryActions.lua` is the action load-order entry.
  Its registry/executor and built-in action definitions are separate modules;
  the public `PNC.InventoryActions` registration API remains stable.
- `PNC_Inventory_Payloads.lua` builds summary, full, and incremental network payloads.
- `PNC_Inventory_Persistence.lua` owns the public serializer/hydrator and delegates
  template-delta encoding, replay, Core item records, and physical item adaptation
  to persistence codecs and adapters.
  Untrusted delta lists and Core state groups are validated before replay; an
  invalid delta falls back to the generated template inventory.
- Item construction keeps script definition state and food profiles in focused
  child modules under `Model/PNC_Inventory_Items`.
- `client/PNC/UI/Inventory/PNC_InventoryWindow.lua` stays the stable window
  loader. Its `InventoryWindow/` modules separate layout, refresh, endpoint
  state, bulk transfers, drag/drop, item actions, presentation, and lifecycle
  while preserving `ISPNCInventoryWindow` and `PNC.InventoryWindow` APIs.
- `client/PNC/UI/Inventory/PNC_InventoryUI_Model.lua`,
  `PNC_InventoryTransferEndpoint.lua`, and `PNC_InventoryUI_List.lua` are stable
  facades over focused provider/row, endpoint, appearance/input/lifecycle
  modules. Keep their public model, endpoint, and list contracts intact.
- `server/PNC/Semantics/Inventory/PNC_SemanticInventoryQueryService.lua`
  remains the server query facade. Candidate scanning and MarketSense
  classification, bounded response shaping, and request authorization/network
  handling load in that order. The selector loads classification and text
  matching before criteria matching and query helpers; MarketSense remains the
  item meaning authority.

Implementation modules communicate through `PNC.Inventory.Internal`; consumers should
continue to call only the public `PNC.Inventory` functions.

## Player Interaction and Multiplayer

- `PNC_InventoryWindow` presents the player and companion containers with
  clearly labeled ownership panes, vanilla-style striped rows, item/category
  columns, selected-container weight, equipped dots, contextual item actions,
  and drag transfer in both directions. Each pane has a vanilla-style icon rail
  on its right edge: the inventory icon selects the root and bag icons select
  accessible backpacks or other item containers.
- `PNC_InventoryTransferEndpoint` supplies the right-hand pane through a small
  endpoint contract (snapshot, rows, containers, weight, revision, transfer).
  The existing window therefore serves player-to-NPC and player-to-storage
  exchanges without duplicating list, grouping, quantity, drag/drop, icon-rail,
  or responsive-layout code. New faction structures can provide another
  endpoint over the same contract.
- The vanilla player inventory pane is bridged to the companion pane, so native
  inventory items can be dropped directly onto the companion window and compact
  NPC items can be dropped into the player's selected inventory or backpack.
- Clients submit only item IDs, destination IDs, and their last inventory
  revision. `PNC_ServerInventory` resolves every ID again against authoritative
  state, enforces companion ownership/range, rejects stale revisions, caps batch
  size, checks NPC carry capacity, and rolls back native items if the compact
  mutation fails.
- Native player/world item creation and removal is delegated to
  `PsychopatzCore.ItemTransfer`, keeping packet synchronization and portable
  item-state conversion standardized across ProjectHoomans, DynamicTrading, and
  future Psychopatz mods.
- compact persistence does not repeat script-derived bag capacity, weight
  reduction, wearable slot, root carry capacity, or cached used weight.
  Acquired items persist only overrides plus their sanitized portable state.
- portable item state accepts the standardized condition, repair, drainable,
  favorite, custom-name, ammunition, fluid, and primitive modData fields.
  Nested tables/userdata/functions are rejected; modData is sorted
  deterministically and bounded to 64 keys with 1,024-character string values.
- runtime inventory operation logs remain capped and are never serialized.
  Save deltas are rebuilt from the current canonical inventory, so mutation
  history cannot grow the save indefinitely.
- successful deltas publish `NPC_INVENTORY_CHANGED` after revision, equipment,
  cache, and registry dirty work completes. Inventory does not depend directly
  on Provision; server Provision may subscribe to this fact.

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

`PNC_Combat_Firearms` derives magazine capacity and ammunition type from the
equipped weapon/script item for every ranged NPC. It writes the loaded count to
that weapon's compact inventory item. With `Companion Ammo Realism` enabled,
recruited companions consume matching grant/loot stacks when a reload finishes;
other NPCs refill the same finite magazine from an infinite reserve. The
original `NPCAmmoConsumption` sandbox key is intentionally retained for
existing saves and presets.

The melee and ranged weapon chances are independent. Consequently an NPC can
spawn unarmed, melee-only, ranged-only, or with both weapons. The ranged weapon
becomes active when both are generated; the melee weapon remains in inventory
as a reserve. If a finite-reserve ranged NPC exhausts all ammunition, combat
uses `EquipPrimary` to atomically switch to that reserve; the operation updates
the legacy equipment view, compact persistence state, inventory revision, and
incremental client delta together. With no usable melee item it clears primary
equipment so the unarmed shove lane becomes the last resort.
`NPCMeleeWeaponSpawnChance` and `NPCRangedWeaponSpawnChance` control the rolls
from 0–100 in sandbox settings; their defaults are 70% and 20%, respectively.

Selection uses `identitySeed` and stable category salts, so the same identity
receives the same equipment regardless of NPC archetype and across multiplayer,
save/load, and template rebases. Explicit debug melee/ranged variants set a
persistent generation override and bypass the chances; ordinary debug spawns
use the normal chance policy.

The world debug menu nests equipment choices under Companion, Neutral, and
Hostile. Each faction can use sandbox chances or explicitly force melee,
ranged, or both weapon categories. Forced choices bypass chance rolls but still
select concrete items deterministically from the identity-seeded equipment
pool.

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
- generator version 3 adds the stable named identity-card template and rebases
  older inventories without duplicating cards
- persistence schema version 8 removes duplicated derived weights and writes
  minimal per-field template changes and minimal acquired-item payloads
- death conversion re-validates the identity card against the final
  `IsoDeadBody` container, so legacy records and engine fallback conversions
  still receive exactly one card

## Maintenance Plan

### Current architecture and responsibilities

- `PNC.Inventory` is the shared compatibility facade and load-order entry point.
  Focused model, equipment, generation, template, action, payload, persistence,
  and water modules implement the domain behind it. Cross-module calls use
  `PNC.Inventory.Internal`; external consumers keep using the public facade.
- Compact NPC inventory records are the domain representation. Templates provide
  deterministic identity-seeded starting state; semantic deltas describe changes
  to that state; portable acquired-item records store only bounded overrides and
  supported primitive item state. Persistence schema version 8 keeps derived
  script data and runtime-only caches out of saved records.
- `PNC.InventoryActions` is the stable action registry and executor contract.
  Action definitions are loaded separately from registry mechanics.
- The existing `PNC.PerformanceScalingDiagnostics` API loads Inventory audit
  formatting from `PNC_PerformanceScalingDiagnostics_InventoryAudit.lua`, keeping
  bounded event text at a focused diagnostic boundary.
- `PNC_ServerInventory` owns multiplayer authorization, current-revision checks,
  authoritative item-ID resolution, capacity checks, and rollback around native
  item transfer and compact inventory mutation.
- Client Inventory UI facades preserve the window, model, endpoint, and list
  contracts. The endpoint owns snapshots, rows, containers, weight, revision, and
  transfer operations. UI requests carry identifiers and revisions; the server
  remains authoritative for NPC state. PsychopatzCore's item-transfer adapter
  owns native player/world item materialization and removal.
- Server semantic inventory requests pass through request authorization, bounded
  response shaping, candidate scanning, and item selection. MarketSense remains
  the classification authority; the semantic selector only applies request
  criteria and text matching to classified items.
- A successful compact mutation updates revision, equipment and lookup caches,
  marks persistence state dirty, then publishes one inventory-changed event.
  Provision and other consumers subscribe to that event instead of becoming
  direct Inventory dependencies.

### Stable contracts and state ownership

- Preserve public `PNC.Inventory` and `PNC.InventoryActions` tables, their
  documented methods, inventory window/model/endpoint/list facades, and template,
  full-save, delta-save, and network payload shapes unless a separately reviewed
  schema migration explicitly changes them.
- Keep item IDs, template keys, container IDs, equipped-item references, and
  inventory revisions as the stable identifiers crossing persistence, UI, and
  network boundaries. Do not pass native engine objects through those contracts.
- The server registry owns canonical NPC inventory and revisions. A client may
  hold a presentation snapshot, but every mutation is revalidated against the
  authoritative record. The local player inventory remains an engine-owned
  container and crosses into NPC inventory through the Core adapter and server
  transaction boundary.
- The item-state codec accepts only the documented portable fields and bounded
  primitive modData. Diagnostics and mutation history stay bounded and are never
  serialized. MarketSense owns item meaning; Inventory owns item identity,
  membership, equipment, and mutation rules.

### Module boundaries and migration order

The implementation has been split along these boundaries while retaining the
existing entry points:

1. Preserve public facades, save schemas, and load-order behavior.
2. Separate compact model state, deterministic templates and equipment
   generation, mutation/action rules, and payload construction.
3. Split persistence codecs and runtime adapters; validate imported Core state
   and deltas before replay, then fall back safely to template state on invalid
   persisted input.
4. Keep server authorization and transaction rollback at the request boundary;
   keep native inventory operations behind PsychopatzCore adapters.
5. Split the Inventory window, UI model, transfer endpoint, and list behind their
   stable loaders. Split semantic query candidate scanning, response shaping,
   request handling, and selector matching behind server facades.
6. Verify save compatibility, shared/client/server loading, and the end-to-end
   multiplayer mutation path before considering a schema or API change.

The model, equipment, template, action, persistence, water, UI, and semantic
query slices above are implemented in focused child modules. Future changes
should remain within these ownership boundaries and keep compatibility wrappers
small and explicitly named.

### Compatibility and load order

- Keep each public facade as the single supported load entry and require children
  in dependency order. Do not capture collaborators at module load when shared
  bootstrap loads them later; resolve those collaborators when the operation runs.
- Preserve generator rebasing and replay of valid semantic deltas. Version 2
  equipment migration, version 3 identity-card migration, and schema version 8
  persistence remain covered by the current format contract.
- Keep old sandbox option names and save records readable. Invalid external
  state must fail closed to the generated template rather than partially applying
  a malformed delta.
- Keep Kahlua compatibility and use protected calls only at documented external
  callback or serializer boundaries where recovery is required.

### Test and verification strategy

- Compare focused smoke tests and the full `tests/run_tests.py` suite with the
  established repository baseline. Relevant contracts include template/delta
  round trips, malformed state fallback, equipment synchronization and
  hydration, water-container normalization, physical item capture/materialization,
  UI request behavior, semantic inventory filtering, duplicate requests,
  multiplayer stale-revision rejection, and native/compact rollback after
  partial transfer failure.
- Run `pz_verify` on the complete shared Inventory tree and the changed UI/server
  scopes. Confirm no new Kahlua findings and no Inventory file above the token
  threshold. Treat findings outside those scopes as baseline unless separately
  investigated.
- The default `pz_verify` i18n scan flags the existing action labels and
  selector whitespace patterns, plus UI translation keys passed through
  `Helpers.tr`; the helper resolves keys through `PNC.Translation.GetKey`, and
  the clean baseline contains the same labels and patterns. No localization
  changes were made. Its single-file scan of the host-side transaction smoke
  also reports test-only `package.preload` use and an over-threshold estimate;
  the baseline test already exceeded that threshold.
- Use `git diff --check` after edits and inspect the final facade-to-adapter call
  path, not only isolated smoke tests.
- A clean archive of baseline `HEAD` (`a0bde193`) passes `tests/run_tests.py`
  712/712; the current worktree passes 717/717. Scoped `pz_verify` reports zero
  Kahlua issues and zero over-threshold Inventory files.
- The shared performance-diagnostics facade remains above the general token
  threshold: its clean-HEAD estimate is 10,570 tokens and the current estimate is
  10,382. Extracting Inventory audit formatting reduced that facade and put the
  bounded logger in a child module below the threshold; a broader diagnostics
  split remains cross-system maintenance work.
- The architecture scan still flags the shared diagnostics facade as a large
  module at 1,007 code lines, down from 1,025 at baseline. The Inventory-specific
  formatter is isolated; the remaining cross-system responsibilities are outside
  this Inventory migration slice.
  The latest available `console.txt` was modified at 2026-09-19 00:23 +08:00,
  before this verification pass. Searches found no `PNC_Inventory` or
  `inventory_audit` entries; its recent general errors and warnings are engine,
  map, translation, or unrelated initialization messages. A live multiplayer
  session was not available for this verification pass.

### Performance and memory constraints

- Preserve identity-seeded compact templates, indexed item/container lookups,
  bounded portable-state fields, and capped runtime operation logs. Do not retain
  Java/Lua engine objects in serialized data or long-lived audit records.
- Inventory audit is disabled by default and retains no event history. When
  enabled, the logger caps event names at 64 bytes, accepts at most 16
  fields of 256 bytes each, strips control characters, and renders
  non-primitive values as type labels without calling arbitrary stringifiers.
- Authoritative transfer, action, and semantic-transfer results include the
  normalized route and selection, NPC/request/item identifiers, authority
  decision, adapter result, failure reason, and inventory revisions before and
  after the request. These fields are constructed only while the audit is on.
- Keep deterministic local classification and item selection ahead of optional
  external services. The semantic inventory path must remain server-bounded and
  must not require an LLM or network lookup for ordinary filtering.
- Source inspection found that `refreshInventory(false)` runs from every
  `prerender` and rebuilds player rows to compute its change signature before its
  early return. A changed signature now reuses those rows when the selected native
  container is still the same; it rebuilds after the fresh container list only
  when that native container changed. The per-frame row scan remains because it
  detects stack, favorite, equipped, and item-state changes even when item counts
  and NPC revisions stay the same. Profile an open window with representative
  container sizes before changing that invalidation contract further.

### Risks, rollback, and acceptance

Primary risks are require order, template/save compatibility, stale client state,
and partial failure while transferring native items. Keep each structural change
small enough to roll back by restoring the prior `require` target while leaving
the public facade and persisted payload contract intact. Do not roll back or
overwrite unrelated worktree changes.

Automated acceptance requires the baseline and current smoke suites to pass, no
new Inventory Kahlua findings or over-threshold files, and clean diff checks.
Release acceptance also requires loading an existing save, checking generated
and reloaded equipment, exercising a live server with two clients, and observing
the stale-revision rejection and resync behavior described below.

#### Manual server and two-client gate

On the server, enable the bounded audit and inject a missing item ID into a
record's compact inventory, then hydrate it again to exercise normalization:

```lua
PNC.PerformanceScalingDiagnostics.SetInventoryAuditEnabled(true)
local record = PNC.Registry.Get("<npcId>")
local inv = PNC.Inventory.EnsureRecordInventory(record)
table.insert(inv.containers.root.items, "inventory_audit_probe_missing")
PNC.Inventory.EnsureRecordInventory(record)
PNC.API.DebugCommand("<npcId>", "set_equipment_slot", {
    slotKind = "worn", slotName = "Torso1",
    fullType = "Base.Tshirt_DefaultTEXTURE_TINT",
})
```

With two clients, have client A retain revision N, let client B commit a valid
inventory action at N+1, then submit an action from A using N. To preserve the
old revision even after A receives B's update, run this on client A before B's
commit:

```lua
local npcId = "<npcId>"
local itemID = "<existing item ID>"
local cached = PNC.Network.ClientState.characterPayloads[npcId]
PNC.__inventoryAuditProbe = {
    id = npcId,
    itemID = itemID,
    revision = cached.inventory.summary.revision,
}
```

After client B commits, run this on client A:

```lua
local probe = PNC.__inventoryAuditProbe
PNC.Client.SendInventoryAction({
    id = probe.id,
    actionID = "equip_primary",
    itemID = probe.itemID,
    inventoryRevision = probe.revision,
})
PNC.__inventoryAuditProbe = nil
```

Confirm that the server rejects the stale action and sends the current
inventory state to A. Disable the audit after collecting the output. Expected
signatures are:

```text
inventory_audit event=enabled
inventory_audit event=record_hydrated ... membership_changed=true ... dirty_reason=inventory_structure_normalized
inventory_audit event=equipment_sync ... reason=debug_equipment_slot result=complete ... revision_before=... revision_after=...
[PNC][INVENTORY] revision conflict ... expected=N current=N+1 ...
inventory_audit event=server_action stage=stale_revision ... route=action:equip_primary ... authority=allowed ... adapter_result=not_run result=false reason=revision_conflict ... revision_expected=N revision_before=N+1 revision_after=N+1
```
