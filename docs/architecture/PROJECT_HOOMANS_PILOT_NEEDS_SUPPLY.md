# Needs → Provision → Supply → Inventory Pilot

## Observed Runtime Flow

The source supports two related authoritative flows rather than one linear
pipeline:

```text
NeedsScheduler → NeedSupplyBridge → NPCSupplyService
ProvisionScheduler → ProvisionEvaluator → NPCSupplyService
NPCSupplyService → SupplyInventory query/command boundary → Inventory
```

Needs requests immediate use of already-issued personal food, water, or
medical supplies. Provision evaluates target stock and acquires deficits from
accessible colony storage. `NPCSupplyService` owns request validation,
authority, retries, selection orchestration, acquisition, and need effects.

## Ownership and Contracts

- **Needs owns:** persisted individual/group need values, activity-derived
  rates, threshold transitions, health consequences, and its bounded scheduler.
- **Provision owns:** faction provision policy, target/threshold evaluation,
  dirty-rule queue, retry scheduling, and the two-items-per-second work budget.
- **Supply owns:** validated supply requests, candidate description/ranking,
  storage access, reservations/acquisition orchestration, retry state, and
  supply metrics. Runtime supply/provision state remains non-canonical runtime
  coordination attached to NPC records.
- **Inventory owns:** canonical compact NPC inventory state, validation,
  revisioned mutation, equipment reconciliation, persistence mode, dirty
  marking, and the post-mutation inventory-changed fact.
- **Colony Storage owns:** authoritative storage inventory, reservations,
  revision, persistence dirty state, and withdrawal activity events.

Supply initializes personal inventory through
`SupplyInventory.Commands.EnsurePersonalInventory`, reads the initialized state
through `SupplyInventory.Queries.FindPersonal`, and requests mutations through
`SupplyInventory.Commands`. The query returns item IDs, stack counts,
descriptors, and scores without exposing mutable inventory records. Inventory mutation delegates to
`Inventory.Commands`; legacy hydration-aware helpers remain direct compatibility
methods rather than being mislabeled as read-only queries.

After a successful inventory delta, Inventory publishes
`NPC_INVENTORY_CHANGED`. Provision subscribes from its canonical server entry
and marks affected rules dirty. This replaces the previous reverse dependency
where shared Inventory called `ProvisionScheduler` directly.

## Authority, Persistence, and Performance

Both flows remain authority-only and retain the same `NPCSupplyService.Process`
gate. No network command or payload changes are introduced. Needs and inventory
continue to persist through the canonical NPC record; faction provision policy
and colony storage retain their current repositories and save timing.

Cadence and bounds remain unchanged: Needs keeps its configured scheduler
interval; Provision keeps a 1000 ms slice, maximum two evaluations per slice,
and 10000 ms audit interval. The new command/query tables are direct function
aliases and add no per-tick event or collection scan.

## Load-Order Constraint

Supply and Provision now have canonical server entry files that reproduce their
previous contiguous require order. Needs server loading remains explicitly
interleaved with Facility Jobs because Facility Jobs consumes
`IndividualNeeds`; changing that timing requires separate startup evidence.
The shared, server, and client `00_*Init.lua` anchors remain unchanged.
