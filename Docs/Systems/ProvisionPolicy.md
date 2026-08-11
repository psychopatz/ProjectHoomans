# Provision Policy System

Provision policy answers what a colonist should normally carry. It only acquires
inventory through the existing NPC supply service; it never changes hunger,
hydration, wounds, or health. Needs and Treatment remain the only consumers.

## Architecture

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
debug actions mark rules dirty. The scheduler processes at most two rules per
one-second slice. Policy changes enqueue members but never synchronously query
their stockpiles. Successful and partial acquisitions are re-evaluated; failures
reuse the supply lane's retry deadline. A recent higher-priority Need request for
the same NPC/resource suppresses routine provisioning briefly.

The existing inventory mutation path is unchanged, so LIVE inventory mirroring,
FULL persistence, SEED_ONLY to BASELINE_DELTA overlays, and delta compaction all
continue through `PNC.Inventory.AddItems` / `ApplyDelta`.

## Settings and authority

Colony Management opens a separate scrollable Provision Settings window. The
window iterates registry categories and rule UI descriptors; it has no food,
hydration, or bandage-specific widget creation. Edits live in
`PNC_ProvisionSettingsModel` until Apply. Reset Defaults also changes only the
working copy.

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
satisfied/deficient rules, request outcomes, Need/incoming suppression, scheduler
throughput, and storage shortages. The Needs debug snapshot includes each rule's
on-hand, incoming, threshold, target, status, policy source, last evaluation,
dirty rules, last request, and failure. Debug actions can force evaluation, mark
rules dirty, clear retry deadlines, and dump the effective policy.
