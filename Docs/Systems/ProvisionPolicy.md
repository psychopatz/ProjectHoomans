# Provision Policy System

Provision policy answers what a colonist should normally carry. It only acquires
inventory through the existing NPC supply service; it never changes hunger,
hydration, wounds, or health. Needs and Treatment remain the only consumers.

## Architecture

`PNC_Provision.lua` is the canonical server entry. It explicitly loads the
resolver, evaluator, scheduler, and policy service in their established order,
then exposes named evaluator, scheduler, and policy access through
`PNC.Provision`. Existing direct domain tables remain compatible; the evaluator
is not labeled a query because evaluation can initialize inventory and request
authoritative supply work.

After those modules load, the entry subscribes to Inventory's
`NPC_INVENTORY_CHANGED` fact and delegates invalidation to the scheduler. This
keeps Inventory independent from Provision while preserving the existing dirty
rule timing after successful inventory mutation.

The shared `PNC_ProvisionRuleRegistry` owns semantic rule definitions, defaults,
validation ranges, categories, and UI field descriptors. The initial rules are:

| Rule | Selector | Measure | Refill / target |
|---|---|---|---|
| `food` | `FOOD` | `HUNGER_UTILITY` | 0.30 / 0.80 |
| `hydration` | `HYDRATION` | `THIRST_UTILITY` | 0.25 / 0.70 |
| `bandage` | `BANDAGE` via `MEDICAL` | usable `COUNT` | 1 / 3 |

These defaults use native Build 42 item utility values. Food sums the absolute
`HungerChange`; hydration sums `ThirstChange` across real remaining
drainable uses. Bandages use the same semantic recognition as treatment and the
supply selector.

Faction persistence stores one canonical policy:

```lua
provision = {
    schemaVersion = 2,
    revision = 8,
    policies = {
        default = {
            parentPolicyId = nil,
            food = { enabled = true, refillBelow = 0.30, target = 0.80 },
            hydration = { enabled = true, refillBelow = 0.25, target = 0.70 },
            bandage = { enabled = true, refillBelow = 1, target = 3 },
        },
    },
}
```

Schema 1 food and hydration policy values migrate by dividing by 100.

No policy is copied to NPC records. `PNC_ProvisionResolver` currently resolves
the faction default. Its overlay order is already faction default, optional
`role:<role>` sparse policy, then optional sparse NPC override. The initial UI
only edits `default` and does not create role or NPC overrides.

## Evaluation and scheduling

`THRESHOLD_TARGET` uses a strict comparison: refill begins only when
`onHand + incoming < refillBelow`. A runtime refill latch remains active until
the target is reached. This means a partial acquisition that crosses the
threshold still continues toward the original target when supply becomes
available.

The evaluator only scans the NPC's compact/personal inventory. It never scans
colony storage. A deficit becomes a normal `SupplyRequest` with
`purpose = "PROVISION"`; `PNC_NPCSupplyService` then performs the existing
access-policy, index, bounded scoring, reservation, transaction, and inventory
adapter flow. `acquireOnly` prevents consumption and `ignorePersonal` tells the
service the evaluator has already accounted for personal inventory.

Inventory changes, faction joins, role changes, policy changes, and explicit
debug actions mark rules dirty. A successful colony-storage deposit also wakes
every provision rule in the owning faction immediately, clearing a stale
shortage deadline when new supplies arrive. The scheduler processes at most two rules per
one-second slice. Policy changes enqueue members but never synchronously query
their stockpiles. Successful and partial acquisitions are re-evaluated; failures
reuse the supply lane's retry deadline. A bounded ten-second audit re-enqueues
faction members so an inventory change from an integration that missed the
normal dirty hook cannot leave reserves stale indefinitely.

Provisioning and need consumption are deliberately separate. Provision requests
may acquire from the current base and stop once the item is in the colonist's
inventory. Hunger and thirst requests use `personalOnly`; they can consume a
carried allocation but cannot fetch from colony storage. Provision requests also
bypass a need-consumption retry cooldown, so an earlier attempt to eat an empty
reserve cannot prevent that reserve from being replenished.

`PNC_Supply.lua` is the canonical server entry for request validation, metrics,
item utility/indexing/selection, storage access, inventory adaptation, and the
authoritative NPC supply service. Its implementation order is explicit rather
than dependent on alphabetical filenames. Supply reads personal inventory
through `SupplyInventory.Queries` and mutates it through
`SupplyInventory.Commands`. The query operates on explicitly initialized state
and returns item IDs, stack counts, descriptors, and scores rather than mutable
inventory items. Supply commands delegate canonical mutations to Inventory commands.

The existing inventory mutation path is unchanged, so LIVE inventory mirroring,
FULL persistence, SEED_ONLY to BASELINE_DELTA overlays, and delta compaction all
continue through `PNC.Inventory.AddItems` / `ApplyDelta`.

## Settings and authority

Colony Management opens a separate scrollable Provision Settings window. The
window iterates registry categories and rule UI descriptors; it has no food,
hydration, or bandage-specific widget creation. Edits live in
`PNC_ProvisionSettingsModel` until Apply. Reset Defaults also changes only the
working copy.

The client feature has an explicit four-part boundary:

- `ProvisionSettingsClient`, defined with the model, adapts the existing colony
  snapshot state and `RequestColonyManagement` / `provision_set` requests;
- `ProvisionSettingsModel` owns the editable copy and shared pre-validation;
- `ProvisionRulePanel` translates widgets to model operations without writing
  model fields directly; and
- `ProvisionSettingsWindow` owns layout, status text, refresh timing, and user
  interaction while consuming only the client boundary and model.

The window is the canonical client entry and deterministically loads the model,
rule panel, and scroll panel. No new protocol or client authority is introduced.
Client validation is convenience feedback only; the server policy service still
re-resolves ownership, checks the expected revision and schema, validates every
rule, applies the mutation, and persists it.

Apply uses the existing colony action request. The server resolves the player's
own faction, requires its owner identity, validates schema, policy ID, every rule
and field, numeric ranges, and target consistency, checks the expected revision,
then increments the revision once and saves the faction registry. Unknown rules
or fields fail closed.

## Registering a rule

A future rule is a shared registration module loaded after the registry and
before `PNC_ProvisionPolicy`. For example, primary ammunition can register:

```lua
PNC.ProvisionRuleRegistry.Register({
    id = "primary_ammo",
    category = "combat",
    mode = "THRESHOLD_TARGET",
    selector = "PRIMARY_AMMO",
    measure = "ROUND_COUNT",
    priority = 30,
    defaults = { enabled = false, refillBelow = 30, target = 90 },
    ui = {
        labelKey = "UI_PNC_Provision_PrimaryAmmo",
        descriptionKey = "UI_PNC_Provision_PrimaryAmmo_Description",
        measureKey = "UI_PNC_Provision_Rounds",
        fields = {
            { id = "refillBelow", type = "number", min = 0,
                max = 1000, step = 10,
                labelKey = "UI_PNC_Provision_RefillBelow" },
            { id = "target", type = "number", min = 0,
                max = 1000, step = 10,
                labelKey = "UI_PNC_Provision_TargetCarry" },
        },
    },
})
```

The supply stack must then gain generic semantic support for that selector in
`PNC_ItemUtility` / `PNC_SupplyIndex`; the Provision UI and scheduler need no
special cases. A weapon-change integration calls
`PNC.ProvisionScheduler.MarkDirty(record, "primary_ammo")`.

Currency follows the same pattern with a semantic `CURRENCY` selector and a
`THRESHOLD_TARGET` measure such as `CURRENCY_VALUE`. A radio can use `EXACT`
with target 1. Tools or mission equipment can use `CUSTOM` after providing a
rule evaluation callback. The registry supports `THRESHOLD_TARGET`, `EXACT`,
`MAXIMUM`, and `CUSTOM`; only numeric fields used by the initial rules are
currently rendered.

## Diagnostics

Supply metrics include policy revision, dirty NPC and queue gauges, evaluations,
satisfied/deficient rules, request outcomes, audit counts, scheduler throughput,
and storage shortages. The Needs debug snapshot includes each rule's
on-hand, incoming, threshold, target, status, policy source, last evaluation,
dirty rules, last request, and failure. Debug actions can force evaluation, mark
rules dirty, clear retry deadlines, and dump the effective policy.

`Provision Diagnostics` is available from both Colony Management's Debug tab
and the debug NPC Monitor. It requests one selected NPC on demand rather than
including every diagnostic in routine snapshots. The modal reports personal
food/hydration/medicine measurements, threshold and target values, scheduler
queue state, storage access (including `storage_not_at_base`), recognized
storage candidates, selected items, and the last supply failure/retry state.
The storage summary reports food in vanilla hunger utility and total calories,
plus hydration utility and usable bandage count.

`Force Grab Provisions` clears supply retry deadlines, immediately evaluates
all registered provision rules, and reports one result per rule. A result says
whether acquisition was actually attempted and gives the authoritative reason
(`acquired`, `satisfied`, `no_supply`, `storage_not_at_base`, and so on); the
button never substitutes a generic success for a failed or blocked evaluation.

Old saves can contain an owned companion record that predates canonical faction
or community membership. Colony Management reconciles those owned records
before resolving the snapshot and before every debug provision action. Repair
uses the normal recruitment membership transaction, preserves the colonist's
current order, persists all registries, and immediately marks provision rules
dirty.

Colony storage currently uses the centralized `VIRTUAL_COLONY` access mode
because physical bases do not exist yet. Valid community members can therefore
acquire provisions from their virtual colony storage from any world position.
The access policy retains a `PHYSICAL_HOME` mode that applies the existing home
radius check; enabling that one policy when bases arrive does not require
changes to provision scheduling, selection, or inventory transfer.
