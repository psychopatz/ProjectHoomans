# Inventory and ModData Scale Stress Plan

## Status

**ACTIVE L6 DEVELOPER WORK.**

L6 now has four mandatory workload families:

1. continuous FollowOwner movement;
2. combat-hit contact spikes;
3. compact abstract/mobile-group travel and materialization handoff;
4. large player inventory + many NPC compact inventories + transfer/persistence/replication pressure.

This workload exists to make inventory/ModData optimization measurable before real saves accumulate many NPCs with durable loot.

## Code-verified architecture

ProjectHoomans and PsychopatzCore separate player-native inventory from durable NPC inventory.

NPC durable personal inventory is owned by PsychopatzCore `ActorInventory`. Its compact payload modes are:

- `SEED_ONLY` for an unchanged deterministic starter inventory;
- `BASELINE_DELTA` for changes relative to the deterministic baseline;
- `FULL` only when a compact baseline/delta representation cannot safely preserve exact inventory.

`PNC_Inventory_ActorBridge` hydrates that compact Core payload into the richer Hoomans logical inventory only while Hoomans gameplay needs it, then captures changes back to the Core actor.

Existing tests prove individual contracts such as actor-inventory bridge compaction, persistence scale, replication coalescing, summary caching, inventory UI refresh caching, transfer rollback, hydration, and round-trip correctness.

The missing workload is system scale:

~~~text
large player native inventory
      |
      | transfers / gifts / supplies
      v
many NPC compact Core inventories
      |
      | mutation + save/reload
      v
ModData / Core actor storage pressure
      |
      | nearby subset materializes
      v
only nearby NPCs hydrate richer/native inventory state
~~~

## Primary invariants

- Distant NPCs with items remain compact Core actors and do not require live/native item objects.
- Adding items to one NPC does not force inventory serialization for unrelated NPCs.
- Many same-tick inventory mutations for one NPC coalesce into one bounded replication/persistence unit where semantics allow.
- A large player inventory is not copied into every NPC query or full character payload.
- Opening/refreshing an inventory UI does not rebuild unchanged player/NPC rows every frame.
- Repeated compact capture does not accumulate historical delta bloat.
- Save/reload preserves exact item identity/state without converting every compact inventory to `FULL`.
- Inventory growth is proportional to actual durable item state, not Hoomans runtime/cache state.

## Required workload scenarios

### `PLAYER_INVENTORY_LARGE`

Populate one simulated player's native inventory with selected sizes such as 100, 500, 1,000, and 2,000 items.

Use a deterministic mix of stackable/common items, unique item IDs, weapons/tools, food/condition state, containers, and representative durable item ModData/state.

Measure native list iterations, UI row builds, cached refreshes, item-description/transfer-resolution calls, full-character payload requests, inventory-only payload requests, and profiler-OFF average/p95/max operation cost.

The player inventory itself is not automatically a ProjectHoomans NPC ModData payload. This scenario isolates the cost of scanning/resolving a very large player inventory before transfer.

### `NPC_INVENTORY_COMPACT_SCALE`

Create compact Core actors with personal inventories while they remain abstract/bodyless.

Selected scale points:

- NPC count: 10 / 50 / 100 / 500
- durable acquired items per NPC: 0 / 20 / 100 / 500

Do not run a wasteful full Cartesian matrix; choose representative combinations that expose scaling.

Require:

- unchanged actors remain `SEED_ONLY`;
- ordinary acquired-item actors prefer `BASELINE_DELTA` when representable;
- `FULL` usage is counted and justified;
- distant actors remain bodyless;
- no proportional Hoomans runtime/native-item hydration merely because inventory exists;
- compact payload bytes grow with actual durable item differences;
- runtime caches/derived weights/summary state are not persisted as duplicate authority.

### `PLAYER_TO_MANY_NPCS`

Give the player a large source inventory, then distribute deterministic batches to 1, 10, 50, and 100 NPCs through the real server transfer / Inventory.AddItems / actor-inventory capture paths.

Measure player item-resolution scans, items transferred, NPC inventory revisions, Core actor inventory mutations, persistence dirty marks, persistence pumps/serialization attempts/writes, GlobalModData saves, inventory delta builds/sends, full snapshots, and maximum same-frame mutation fan-out.

Many transfers must not cause one `GlobalModData.save()` per item or one full NPC snapshot per item.

### `MANY_NPCS_TO_PLAYER`

Reverse the direction: transfer deterministic batches from many NPC inventories back to one player.

Verify exact item identity/count round trip, compact NPC payloads shrink/collapse when possible, removal does not leave historical delta entries, replication/persistence coalesces, and player-native additions are deterministic.

### `NPC_INVENTORY_MUTATION_STORM`

For selected NPCs repeatedly add/remove items, move items between logical containers, equip/unequip, and change representative durable item state inside one short simulated interval.

Verify one NPC mutation storm coalesces to bounded dirty/persistence/network work, unrelated NPCs remain untouched, repeated capture reaches a stable compact payload size instead of growing from history, and summary/cache invalidation occurs only on revision changes.

### `INVENTORY_MATERIALIZE_SUBSET`

Create a large abstract population with durable items, then move players near only a small subset.

Verify only the nearby/promoted subset hydrates Hoomans logical/native inventory state; distant actors retain compact Core payloads; materialization does not duplicate items; abstraction captures changed live inventory back to Core and releases rich/native state; repeated materialize/abstract cycles preserve exact item IDs without payload growth when unchanged.

### `INVENTORY_SAVE_RELOAD_SCALE`

Save/reconstruct at representative inventory scale.

Report:

- total Core actor inventory bytes;
- bytes per actor distribution;
- `SEED_ONLY` / `BASELINE_DELTA` / `FULL` counts;
- logical item counts;
- serialization attempts/writes;
- load/decode operations;
- reconstructed equality;
- legacy Hoomans inventory authority count for Core-backed actors, which must remain zero.

The benchmark must report size numbers rather than pass/fail only.

### `INVENTORY_REPLICATION_SCALE`

With multiple clients/interest profiles, mutate inventories across multiple NPCs.

Measure delta builds, recipient fan-out, payload entry/byte counts where available, full-snapshot fallbacks, same-tick coalescing, and stale-revision/repair behavior.

An inventory mutation must not rebuild unrelated health/social/presentation domains.

## Item complexity tiers

Use at least three deterministic tiers:

- Tier A — compact/common items with minimal state;
- Tier B — stateful food/condition/weapon/tool metadata;
- Tier C — containers/bags, equipment slots, nested relationships, and representative supported custom ModData.

Do not use arbitrary huge item ModData blobs merely to inflate byte counts unless testing an explicit codec boundary.

## Required counters and size metrics

Report player item count, native list iterations, item-resolution scans, UI row rebuilds/cache hits, transfer IDs resolved, player add/remove operations, Core actors with inventory, logical item count, compact mode counts, encoded bytes total and p50/p95/max per actor, hydrate/capture/decode counts, compact payload rewrites, repeated-capture byte delta, dirty inventory actors/domains, persistence pumps, serialization attempts, physical writes, GlobalModData saves, estimated/actual bytes where available, dirty backlog high-water mark, inventory delta builds/sends, recipient fan-out, full-snapshot fallbacks, repair payloads, promoted Hoomans records, hydrated logical inventories, native item materializations, abstractions/captures, and distant compact-only actors.

## ModData/size acceptance

Do not invent one universal byte ceiling before measuring the baseline.

1. record pre-fix bytes and operation counts;
2. identify fields/modes dominating growth;
3. optimize redundant/derived/duplicated representation only;
4. preserve exact durable state;
5. set regression ceilings from the accepted compact architecture and measured evidence.

The goal is for storage to grow approximately with **actual durable inventory differences**, not duplicate runtime state, derived caches, full-record snapshots, or historical deltas.

## Combined inventory pressure scenarios

### `COMBINED_INVENTORY_FOLLOW`

One player carries a large inventory while 6/12 companions follow and several companions also carry durable items.

Inventory size must not make FollowOwner hot-path work proportional to carried item count.

### `COMBINED_INVENTORY_COMBAT`

Several NPCs with nontrivial inventories fight zombies/NPCs/players.

Attack impact must not serialize or rebuild entire inventories unless the hit actually changes inventory/equipment.

### `COMBINED_INVENTORY_MATERIALIZATION`

A travelling group whose members have compact inventories enters player range and materializes.

Only the relevant subset may hydrate, with no synchronous all-group/all-world inventory serialization storm.

### `COMBINED_INVENTORY_SAVE_RELOAD`

Save/reload with a large player inventory, many abstract NPC inventories, a small live subset, and pending/coalesced inventory mutations.

Require exact convergence without duplicates, missing IDs, legacy shadow payloads, or permanent dirty retry.

## Optimization rules

Potential evidence-backed improvements include stronger baseline-delta compaction, skipping serialization of unchanged inventories, same-tick mutation coalescing, sparse dirty-domain persistence, inventory-only replication, cached inventory presentation, indexed lookup for large transfer requests, avoiding native hydration for distant NPCs, and collapsing back to `SEED_ONLY` when exact baseline state is restored.

Do not discard unique item state, replace exact durable inventory with count-only summaries, hydrate every NPC inventory at startup, persist UI/runtime caches, introduce a second inventory authority, perform one global save per transferred item, send full NPC snapshots for each inventory mutation, or reduce supported inventory size merely to make the benchmark pass.

## L6 inventory acceptance

This workload passes only when:

1. large player inventories remain usable without per-frame full rescans;
2. many abstract NPC inventories remain compact/Core-owned and bodyless;
3. 10/50/100/500-NPC inventory scale is measurable;
4. player -> many NPC and many NPC -> player transfer stress is deterministic and exact;
5. mutation storms coalesce persistence/network work;
6. only nearby/live NPC inventories hydrate rich/native state;
7. save/reload preserves exact items and compact modes;
8. repeated captures do not accumulate delta history;
9. ModData/encoded-byte reporting exists for future optimization;
10. inventory changes do not trigger unrelated full-record persistence/network snapshots;
11. the combined follow/combat/materialization/save-reload inventory cases pass;
12. existing inventory bridge, persistence, transfer, replication, UI-cache, presence-boundary, Core actor inventory, and L0-L6 regressions remain accepted.

The parent L6 phase is not complete until follow-walk, combat-hit, abstract-travel/materialization, inventory/ModData scale, and the mandatory cross-system stress matrix all pass.
