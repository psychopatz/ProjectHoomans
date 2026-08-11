# Colony storage and research foundation

NPC Needs withdrawals use the supply policy documented in `docs/npc-supply.md`.
They are server-authoritative, exact-record reserved, and currently fulfilled
instantly into the NPC inventory before any use effect. Runtime semantic indexes
are derived from storage contents and are never persisted.

## Faction storage

Each authoritative faction owns a primary storage with the stable ID
`storage:<faction-id>:primary`. The record stores the owning faction ID, the
current settlement ID (when one exists), storage type, tier, storage revision,
and a PsychopatzCore `VirtualInventory`. Faction and community creation eagerly
initialize/update it; lookup also creates missing development-save state lazily.

Tier and contents are independent. `PNC_ColonyStorageDefinitions` is the sole
capacity authority: tier 1 is 200 weight and every additional tier adds 50, up
to the configured maximum. A capacity decrease never deletes contents; an
over-capacity store rejects deposits until enough weight is removed.

`PNC_ColonyStorageRepository` persists:

```text
schemaVersion
storageId
ownerFactionId
settlementId
storageType
tier
revision
inventorySnapshot  (PsychopatzCore serializer payload)
activityJournal    (version + at most 10 compact event tuples)
```

Capacity, used weight, indexes, display rows, filters, and other derived state
are not persisted. Capacity is recalculated from the tier after load.

## Server authority and logistics boundary

UI code submits intent through `RequestColonyAction`; it never mutates storage.
The server resolves the requesting player's current faction and requested
owned storage (defaulting to the primary colony stockpile), rejects foreign
storage IDs, validates source identity and
revision, preflights capacity, and executes a PsychopatzCore inventory
transaction. Successful operations increment both inventory and storage
revisions. Request IDs are retained in a bounded per-player cache to prevent a
repeated packet or double click from applying twice.

`requestDeposit` currently executes immediately. This is deliberately the
execution policy behind the intent boundary. A later warehouse/hauling system
can turn the same request into a hauling job without changing either inventory
UI or Colony Management UI callers.

Player and live-NPC transfers use `PhysicalInventoryAdapter` against real item
containers. Ambient/abstract NPC transfers use a small source adapter over the
existing ProjectHoomans inventory projection and emit PsychopatzCore records.
Both use the same transaction destination and rollback semantics. Equipped,
worn, attached, locked, and player-favorite items are rejected rather than
leaving stale equipment references.

For live NPCs, lookup prefers an exact encoded-state match and then accepts a
loose item with the same full type. If a body predates inventory
materialization and its physical mirror is missing, the source adapter supplies
the missing quantity directly from the authoritative compact record. It does
not depend on `InventoryItemFactory` reconstruction. Existing physical matches
are still removed, and rollback restores both those objects and the compact
inventory state.

## NPC baseline/delta interaction

NPC persistence retains three modes:

- `SEED_ONLY`: the deterministic archetype/template inventory is unchanged.
- `BASELINE_DELTA`: sparse removals and upserts are layered over that baseline.
- `FULL`: explicit fallback for records without a stable baseline, or records
  deliberately marked for full persistence.

Delta upserts contain PsychopatzCore compact ItemRecords plus only the
ProjectHoomans placement/equipment metadata needed to reconstruct the NPC
projection. For example, taking one item from a baseline `Bandage x2` creates a
changed baseline upsert with quantity one. It does not snapshot the whole NPC
inventory and does not promote the NPC to `FULL`.

## Colony Management UI

The existing window now owns five tabs: Overview, People, Needs, Storage, and
Research. Storage shows the general stockpile tier, used/max/free weight,
over-capacity state and logical quantity. It reuses the inventory icon-list
renderer, with localized item metadata and collapsible category groups. Search
and name/quantity/weight sorting operate on presentation rows, not raw codec
fields. Rows rebuild only after snapshot revision receipt or a filter/sort
change; the render loop does not scan inventory records. Development controls
and storage diagnostics live in a collapsed debug drawer.

The Storage tab also contains a Recent Activity pane. The server keeps only
the latest ten successful interactions. Newest entries render first; rejected
or rolled-back transactions are never recorded.

Activity is persisted as structured data rather than translated sentences.
Each tuple contains exactly six fields: operation code, world minute, actor
label, numeric item type ID, quantity, and an optional reason token. The client
resolves item names and translation templates at render time. This bounds
memory and save growth while allowing future reasons such as `lumber`,
`fishing`, or `scavenging` to add only a translation key.

Server systems can record a successful external interaction through:

```lua
PNC.ColonyStorageService.RecordActivity(storage, {
    operation = "STORE", -- or "TAKE"
    actor = npc.name,
    fullType = "Base.Log",
    quantity = 4,
    reason = "lumber", -- optional translation token
})
```

The optional reason key is `UI_PNC_Storage_Reason_<token>`. Inventory mutation
must succeed before this API is called; it records the event and marks
repository persistence dirty but does not mutate inventory itself.

`Manage Inventory` opens the same responsive two-pane exchange window used for
player-to-NPC transfers. Its right side is supplied by a storage endpoint, so
icons, category collapsing, quantity selection, bag selection, drag/drop, and
bulk actions remain shared. Deposits and exact-record withdrawals are normal
faction-owner operations; debug authorization is required only for destructive
test controls. Withdrawals reserve selected records before the atomic
PsychopatzCore transfer and release/restore them on failure.

Research is definition-driven and currently exposes only Storage Capacity. Its
clearly labelled debug upgrade is server-authoritative, changes tier/capacity,
and leaves the inventory snapshot untouched.

## Development controls

Owned NPC/player inventory context menus may deposit into Colony Storage. When
debug access is authorized, the Storage tab additionally exposes Add Test Item (100
`Base.Nails`), Remove Selected, Clear Storage, Fill Test Storage, Validate,
Compact, and Recalculate Weight. These controls are hidden and inert when debug
authorization is absent.

`Options > Mods > Project Hoomans > Logging` contains **Log colony storage
transactions**. It defaults off. When enabled, each storage request writes one
structured `[PNC][STORAGE_TX]` line with action, commit/reject outcome, reason,
request/source identifiers, quantity, and live-mirror shortfall count when
applicable. Disabled mode does not format or emit transaction messages.

Profiler sampling, when enabled, reports storage count, logical items, records,
used weight, capacity, deposits, withdrawals, transfer failures, and capacity
rejections. Validation/compaction counters are also included in storage
snapshots for the development diagnostics.

## Deferred work

This foundation does not create warehouse world objects, construction,
hauling/courier jobs, routes, animations, or physical crates. The next vertical
slice should bind a storage ID to a warehouse `IsoObject`, then replace the
instant request executor with a hauling job while preserving this repository,
transaction, persistence, snapshot, and UI contract.
