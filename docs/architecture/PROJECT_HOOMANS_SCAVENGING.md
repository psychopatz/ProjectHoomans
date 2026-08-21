# Scavenging implementation contract

This note records the Chunk 0 audit for the live-follower scavenging feature.
It fixes subsystem ownership and reuse boundaries before production behavior is
added.

## Ownership boundary

PsychopatzCore will own a generic `WorldLoot` service. It will discover bounded
nearby world sources, resolve ephemeral source and item tokens, normalize item
descriptors, and adapt containers, corpses, and floor items to the existing Core
inventory transaction API. It must not know about companions, scavenging tasks,
player orders, colonies, auto-grab rules, Go Home, or scavenging UI.

Project Hoomans will own search and collection sessions, follower authority,
Tasking integration, physical travel, source preferences, exact-FullType
auto-grab policy, capacity rules, networking, snapshots, presentation, and
scavenging diagnostics. Active manifests and queues are runtime-only.

## Current runtime map

The live nearby-container feature has one authority path:

1. `PNC_ScavengeController` owns the selected team and sends a player action.
2. `PNC_ServerGameplayRequestCommandHandler` authorizes and routes that action.
3. `PNC_ScavengeService` creates the bounded session and asks Core `WorldLoot`
   for source tokens. It owns progress, the manifest, queue, snapshots, and
   cancellation.
4. `PNC_ScavengeExecutor` is the sole live worker. Its Tasking provider claims
   one source per NPC, requests movement through `BehaviorCommon.MoveRecord`,
   inspects on arrival, and performs collection through `WorldLoot.Transfer`.
5. `PNC_PathService` consumes the movement intent and owns native/direct path
   execution. The ordinary companion idle/follow behaviors do not own movement
   while the registered `Scavenge` job is active.
6. `PNC_ScavengeWindow` renders only authority snapshots. Live Debug requests
   a bounded diagnostic snapshot containing each worker's current source,
   next sources, lease/worker phase, path lane, move intent, retry state,
   validity, and distance.

The two public server entry points are intentionally thin load-order hubs.
`ScavengeService/` separates runtime ownership/lifecycle, snapshots,
diagnostics, discovery, queuing, and lifecycle commands. `ScavengeExecutor/`
separates path/runtime adapters, claims, transfers, session-state transitions,
approach recovery, worker ticking, and Tasking provider registration. Public
callers continue to use `PNC.ScavengeService` and `PNC.ScavengeExecutor`.

`PNC_AbstractScavengeResolver` is a separate off-screen Director simulation.
It never discovers or transfers nearby physical container loot and must not be
used as a second implementation of the live command.

The explicit nearby-scavenge command uses `FORCED_ORDER` precedence. Hard
emergencies and critical needs may preempt it; ordinary needs, facility work,
follow, and idle may not. Combat interruption is based only on a current target,
attack, combat hold, unexpired recent threat, or fresh zombie observation.
Expired observation records are diagnostic history and do not block a worker.

## Existing contracts to reuse

- Core item movement already has physical and virtual inventory adapters,
  item-record codecs, server-authority checks, transactional transfer with
  destination rollback and source restoration, and virtual-inventory
  reservations. `WorldLoot` must wrap world sources for these APIs instead of
  implementing a second inventory framework.
- Core corpse support already owns authority-safe corpse inventory insertion and
  native replication. The corpse source adapter will reuse corpse inventory
  resolution and the generic physical adapter; it will not add another corpse
  mutation path.
- Core floor-item support currently covers creation through
  `ItemTransfer.DropToSquare`, but floor removal has a different engine
  lifecycle from ordinary container removal. The floor adapter must isolate the
  native world-item removal/rollback and replication behavior.
- `PNC.CompanionCommands` already owns command registration, player ownership,
  live/range eligibility, closest/group target resolution, and authority-side
  execution. `Scavenge Nearby` will register there and use a custom authority
  callback; the client adapters will continue enumerating the registry.
- `PNC.Tasking` already owns forced-order precedence, leases, preemption, and the
  short `ATOMIC_COMMIT` non-interruptible phase. Scavenge search and collect will
  be separate provider/executor intents and will use `PNC.PathService` for only
  the active destination.
- NPC physical inventory and encumbrance remain owned by `PNC.Inventory`.
  Collection will use its live inventory/container bridge and
  `GetEncumbranceState`; it will not introduce a second capacity model.
- `PNC.HomeDutyService.SendHome` and the colony storage courier pipeline already
  implement physical return-to-base and authoritative bulk deposit. Bring Back
  will enter that pipeline rather than copy its travel or deposit logic.
- Gameplay requests already route through the server command router and return
  owner-scoped snapshots. Scavenging requests will add a dedicated handler and
  reject unknown session, revision, source, and entry tokens on the authority.
- Performance counters already use `PNC.PerformanceScalingDiagnostics`, while
  the optional detailed profiler is registered through
  `PNC_PsychopatzNPCProfiler`. Scavenging will extend those mechanisms and will
  install no idle world-scan callback.

## Search and collection lifecycle

`SCAVENGE_SEARCH` creates one authority-owned, bounded runtime session at the
order origin. Core performs one source-mask traversal for enabled adapters.
Project Hoomans then visits candidates in squared-distance order, asks the
existing path service to reach one candidate at a time, inspects it on arrival,
and builds a lightweight manifest. Invalid and unreachable candidates count as
processed so progress can reach 100 percent.

`SCAVENGE_COLLECT` accepts server-issued manifest entry IDs, groups selected
entries by source token, and visits one source group at a time. On arrival it
revalidates the source and exact item token, enters a short atomic phase, and
uses Core's transaction API to move the physical item into the NPC inventory.
Stale items become `UNAVAILABLE`; they never become client-authored item grants.

## UI reuse contract

The scavenging window will reuse the current colony stockpile visual language
and inventory-list primitives instead of introducing a separate list style.
In particular it will reuse `ISPNCInventoryList`, the existing tree textures,
striped rows, item icons, search box, standard buttons, section titles, pane
headers, responsive layout helpers, and snapshot-driven rebuild behavior.

The main loot table uses the current collapsible row contract:

- A parent row has `groupHeader`, `groupKey`, and `expanded`. It represents one
  grouped manifest item by FullType, such as `Bandage (4)`, and shows aggregate
  quantity plus aggregate collection status.
- Its child rows have `groupChild` and the same `groupKey`. They represent the
  source breakdown needed to retrieve the group, such as `Bathroom cabinet
  (2)` and `Corpse (2)`, including source type, quantity, distance, auto-grab,
  selection, and per-source outcome.
- Expanding and collapsing changes presentation state only. It never changes
  the authority-owned queue or manifest.

A second pane/table, matching the stockpile tab's `RECENT ACTIVITY` pane, shows
collection status. It is revision-driven and contains concise rows such as
`QUEUED`, `TRAVELING`, `COLLECTED`, `UNAVAILABLE`, `SKIPPED`, `FAILED`, and
`PAUSED - CAPACITY`, with item/source context and time where available. This
keeps authoritative outcomes visible without overloading the loot hierarchy.

Source toggles are shown before search. Search progress and source counts remain
above the main table. The two tables rebuild only when session revision,
progress, filters, selection, queue, outcome, or carry state changes; neither is
rebuilt every frame.

The shared inventory widget may receive small backward-compatible extension
hooks for row selection/status cells, but scavenging-specific behavior and
labels remain in a scavenging view model/window. Existing storage and inventory
screens must retain their current behavior.

## Persistence and authority

Only the compact source preferences and exact-FullType auto-grab set persist,
on the smallest existing player/faction-owned settings record that is shared by
eligible companions. Sessions, source tokens, manifests, progress, selections,
queues, and raw engine references do not persist.

Singleplayer, hosted multiplayer, and dedicated servers use the same logical
authority path. The client may submit an NPC ID, session/revision, entry IDs,
quantities, source preferences, and action. The authority independently checks
player identity, follower ownership, session ownership, task eligibility,
source bounds, entry membership, item availability, quantity, and destination
capacity before mutation. Manifest snapshots are sent only to their owner.

## Implemented runtime contract

`Scavenge Nearby` is a personalized companion command. It opens the setup
window on the client; the window then sends `ScavengeRequest` through the
existing command router. The authority creates at most 48 Hoomans sessions and
Core creates at most 64 token registries. A replacement run releases the prior
Core session. No world query or per-NPC scavenging poll exists while unused.

The Tasking provider uses `FORCED_ORDER` precedence and `LIVE` execution. Its
domain-owned executor handles only the current search or collection target.
Tasking's normal critical-need and emergency bands can preempt travel and
inspection. Only the call to `WorldLoot.Transfer` is marked `ATOMIC_COMMIT`;
cancellation requested there is applied immediately after the transaction.

Snapshots contain only scalar descriptors, entry/source tokens, compact queue
summaries, carry state, and activity rows. They are revision checked by the
client and sent only to the owning player. Requests accept only server-issued
entry IDs; exact source/item tokens stay in the authority-owned manifest.

The scavenging UI uses `ISPNCInventoryList`. FullTypes are always parent rows;
expanding a parent reveals the exact container/floor/corpse source entries.
Selection operates on entry IDs, while `Take Selected` groups those entries by
source before task execution. A second status list shows authoritative outcome
events. Right-clicking a parent or child toggles the owner-level exact-FullType
Auto Grab policy. Auto entries remain review-only until `Take Auto Grab`.

At a carry ratio of 1.25 the executor enters `PAUSED_CAPACITY` before another
pickup and releases current reservations. `Bring Back` invokes the existing
`return_home` command, which delegates to the existing colony courier/deposit
pipeline. It does not implement a second home route or storage mutation path.

The debug-only `Dump Diagnostics` control returns the owner-authorized session,
task phase, current source, queue position, counters, timings, and Core
WorldLoot metrics. The normal UI never receives global diagnostics.

## Live validation checklist

No live game was launched during implementation. Validate these cases in the
game before treating runtime behavior as field-proven.

### Singleplayer

1. Place distinct loot in a container, on one floor square, and on a corpse.
2. Run each source toggle alone, then all three together. Confirm Bob walks to
   each location and progress reaches 100% when a location is unreachable.
3. Expand a grouped item and confirm every source child and quantity is shown.
4. Queue several items from the same source and confirm only one visit occurs.
5. Take one queued item manually before Bob arrives; confirm `UNAVAILABLE`, no
   duplicate, and continued collection.
6. Enable Auto Grab for a modded FullType, start a new run with another owned
   follower, and confirm it is marked automatically but not picked up during
   search.
7. Load Bob to the heavy threshold and confirm `PAUSED_CAPACITY` before the next
   pickup. Use `Bring Back`; confirm the established courier reaches home and
   deposits into colony storage.
8. Cancel during search, travel, collection, and immediately around a pickup.
   Confirm reservations clear and any committed pickup remains in inventory.
9. Save/reload. Confirm source preferences and Auto Grab persist while active
   manifests safely disappear.

### Hosted multiplayer

Repeat the source, stale-item, capacity, cancel, and deposit cases with two
players. Player B must be unable to start/cancel Player A's session, request its
snapshot, queue its entries, or forge an entry/revision. Player B must not
receive Player A's manifest traffic.

### Dedicated server

Repeat the hosted authority cases with a dedicated server. Inspect server logs
and the debug diagnostics for source/transfer failures. Confirm native
container add/remove replication, floor removal, corpse inventory removal,
rollback on a rejected NPC destination, and no host-only UI/object assumption.

## Automated verification boundaries

- Core smoke coverage exercises all three masks/adapters, opaque descriptors,
  exact reservations, stale items, direct removal, physical transfer,
  destination rollback, MP replication, modded FullTypes, and caps.
- Hoomans service coverage exercises owner rejection, masks, runtime-only
  manifests, revision/entry forgery, source grouping, shared Auto Grab, and
  cancellation cleanup.
- Hoomans executor coverage exercises unreachable completion, capacity pause,
  stale continuation, physical inventory capture, replication notification,
  and cancel-after-atomic behavior.
- The UI model coverage proves grouped FullTypes preserve every source entry and
  that manual/Auto Grab selection emits only server-issued entry IDs.

The verifier reports no Kahlua/Lua 5.1 errors. Every server-side scavenging
module is below the generic 2,000-token advisory threshold. The client window
remains a separate presentation concern and is outside the server service and
executor refactor boundary.
