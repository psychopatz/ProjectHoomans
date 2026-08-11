# NPC Needs and Colony Supply

The NPC supply slice is server-authoritative and keeps the permanent invariant:

`colony storage -> NPC inventory -> item use -> need/condition change`

`PNC_NeedSupplyBridge` converts hunger and hydration thresholds into semantic
requests. The existing self-treatment behavior emits a `MEDICAL/BANDAGE`
request only when it has a real treatable wound and no carried bandage.
Requests are runtime-only while fulfillment is instant.

## Request and execution boundary

`PNC_NPCSupplyService.Process(request, options)` accepts `requesterId`,
`resourceKind`, semantic `required` values, optional `treatment`, `priority`,
`sourcePolicy`, and `fulfillment`. `INSTANT` is the only implemented execution
policy. `PHYSICAL` is a recognized boundary and currently returns
`physical_fulfillment_unavailable`; Needs callers do not depend on the policy.

Every operation checks the compact NPC inventory first. Storage is resolved
only for an NPC whose faction and active community own the primary storage and
whose current position is inside that community's home radius.

## Item discovery and selection

`PNC_ItemUtility` caches static utility by PsychopatzCore ItemTypeId. It derives
food, water, and bandage capabilities from native/script item properties and
tags. Mutable age, burnt, poison, rotten, frozen, and drainable state remains in
the compact record and is inspected only for candidates. Unknown items are not
treated as supplies.

`PNC_SupplyIndex` keeps runtime-only per-storage FOOD, HYDRATION, MEDICAL, and
BANDAGE buckets. Deposits invalidate the index. Supply withdrawals update the
cached buckets after removal. Logical stack quantities never become one entry
per unit. Selection evaluates at most 24 indexed records and acquires at most
three units per request. Food scoring rewards useful hunger/thirst and earlier
safe expiry, while penalizing waste, negative thirst, and burnt state. Unsafe
food is rejected before FEFO ordering.

## Reservations and atomicity

All storage acquisitions reserve the selected exact compact record before
withdrawal. The PsychopatzCore reservation token retains its state predicate so
FEFO does not reserve one state and remove another instance of the same type.
All reservations are released on failure. Committed compact records are added
to the NPC inventory; live NPCs are also materialized through the physical
adapter. Destination failure restores storage and removes partial physical
materialization.

Consumption happens afterward. Live food, water, and bandages mutate the native
InventoryItem before the canonical compact mutation. Hydration reduces the
actual usedDelta and preserves the remainder. Treatment consumes a real carried
bandage transactionally and rolls it back if the existing wound treatment API
rejects the action.

## Sparse persistence

Supply mutations use the existing ProjectHoomans inventory delta layer and
PsychopatzCore codecs. Temporary `+Apple` followed by consumption compacts to
the baseline automatically; consuming one baseline Bandage stores a sparse
upsert/removal. Supply never promotes an NPC to FULL. The existing persistence
encoder promotes only when the compact delta cannot be represented safely and
records `inventoryPromotionReason = delta_unrepresentable:<reason>`.

## Scheduling, retry, and diagnostics

Food and hydration evaluation runs in the existing 30-second Needs scheduler.
Stable NPCs perform no storage query. Trigger and target values live in
`PNC_NeedsDefinitions.SUPPLY`. Failed attempts store one retry deadline per
resource kind; urgent priorities retry sooner without creating timer objects.

The Needs debug window shows request state, personal/storage candidate counts,
selection scores, reservation/result state, retry time, inventory mode, sparse
delta count, and FULL promotion reason. It also exposes force-evaluate/resource,
clear-retry, score-dump, profiling, and runtime logging controls. Structured
logging is disabled by default and can also be enabled with the
`NPCSupplyTransactionLogging` sandbox option.

Profiler counters are incremental. They cover requests, personal/storage
outcomes, resource kinds, reservations, acquisitions, bounded candidate work,
suppressed retries, and delta mutations/compactions/promotions.

## Future physical fulfillment

The next step is an execution policy implementing `PHYSICAL`: retain the
reservation, create an acquisition job containing the semantic request and
reservation token, travel to the resolved storage, transfer through the same
inventory adapter, then commit. Needs, selectors, access policy, and item-use
code do not need redesign.
