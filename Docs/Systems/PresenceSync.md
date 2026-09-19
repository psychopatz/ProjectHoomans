# Client PresenceSync Architecture

Status: implementation in progress. This document records the current module
contracts and the remaining migration plan for snapshot-to-body synchronization.
The server presence lifecycle and materialization rules remain documented in
[`Presence.md`](Presence.md).

## Runtime Flow

In multiplayer, the server owns the NPC record and live-body lease, then builds
presence deltas from the authoritative record. The client treats those deltas
as input for replica binding and presentation. In singleplayer,
`LocalSnapshots.RefreshAuthority` supplies snapshots for the local authority
through the same presentation path.

Initial roster synchronization and detail requests have separate server paths.
`CMD_FULL_SYNC_REQUEST` builds roster and death-marker projections, then sends
the directory in bounded chunks to the requester. Individual character and
inventory requests check `Network.CanViewCharacter` before sending detailed
payloads.

The client tick in `client/PNC/PresenceSync/PNC_ClientPresenceTick.lua` waits
for a ready world and pumps initial player/world bootstrap requests through
`PNC_ClientRequests_InitialStateTick.lua`. It then requests stale remote
snapshots when connected, refreshes local authority snapshots, refreshes the
body index when due, applies snapshots, then prunes stale remote and
path-controller state. The request coordinator runs inside this single tick
so bootstrap retries share its timestamp and event ordering. The tick composes
these steps; it should not become a second owner of identity resolution or
presentation policy.

## State and Authority

- The server is authoritative for multiplayer presence records, body leases,
  revisions, combat intent, and snapshot contents. The shared
  `Network.BuildPresenceDelta(record)` serializes record state for transport.
- The client owns its loaded-world body index and replica presentation. A
  client-side body match is evidence for applying a snapshot; it does not
  grant authority over the NPC record.
- The native path controller runs only on the multiplayer client that owns
  the local zombie controller. It follows snapshot goals and owns the local
  engine path request, movement lease, and traversal recovery. It does not
  choose server combat intent.
- Singleplayer local snapshots and multiplayer remote snapshots share visual
  application, but their source and cadence remain separate.

## Stable Contracts

Keep the established global namespaces and function signatures while moving
implementation behind them:

- `PNC.ClientPresenceSync.OnTick()` is the client tick entry point.
- `Sync.ResolveBodyForNPC(id, snapshot)` and `Sync.BodyByID`,
  `Sync.BodyByOnlineID`, `Sync.BodyByInstanceID`, and `Sync.BodyByLease` are
  the client body-resolution facade.
- `Internal.ApplySnapshotToBody(snapshot, body, remoteReplica)` is the
  snapshot-to-body adapter used by the tick presenter and focused tests.
- `Internal.UpdateNativePathController(snapshot, body, now)` returns whether
  the native path lane handled the update and a stable reason/state string.
- Snapshot identity uses `id`, `liveBodyLease`, `liveBodyInstanceID`, and
  `liveBodyOnlineID`; presentation consumes `presenceState`, `alive`,
  `visualState`, and optional presentation/debug state. Keep Java body and
  item objects out of replicated or persistent identity data.
- Body indexes reject ambiguous duplicate keys. Resolution prefers the
  snapshot lease, then instance ID, UUID, and online ID, with snapshot identity
  validation before returning a body.

## Module Boundaries

| Area | Owner | Responsibility |
| --- | --- | --- |
| Replication admission and transport | `server/PNC/Networking/Handlers/PNC_ServerCharacterReplicationCommandHandler.lua`, `shared/PNC/Core/Networking/PNC_Network_Server/PNC_Network_Server_Broadcasts.lua`, `_Character.lua` | Build chunked roster syncs and gate individual character or inventory detail requests with `CanViewCharacter`. |
| Body facade | `PNC_ClientPresenceBodies.lua` | Preserve compatibility APIs and decide when to refresh indexes. |
| Body registry | `PNC_ClientPresenceBodies_Registry.lua` | Build unique indexes and resolve snapshots to validated bodies. |
| Body cleanup | `PNC_ClientPresenceBodies_Cleanup.lua` | Remove stale instances and prune duplicate local shells. |
| Tick composition | `PNC_ClientPresenceTick.lua` | Gate world readiness and order local refresh, remote sync, body refresh, apply, and prune. |
| Initial-state request tick | `PNC_ClientRequests_InitialStateTick.lua` | Preserve pending knowledge flushes, order bootstrap/discovery requests, and retain only the latest scalar result, reason, and bootstrap request ID in `Client.Internal.InitialStateRequestDiagnostics`. |
| Snapshot cadence | `PNC_ClientPresenceTick_LocalSnapshots.lua`, `_Remote.lua` | Own local snapshot refresh, remote due checks, stale state, and retry cadence. |
| Snapshot application | `PNC_ClientPresenceTick_Apply.lua` | Resolve each snapshot and order binding, duplicate cleanup, visual apply, and observers. |
| Visual composition | `PresenceVisuals/PNC_ClientPresenceVisuals.lua` | Load visual spokes in dependency order and preserve the apply facade. |
| Visual spokes | `PresenceVisuals/PNC_ClientPresenceVisuals_*.lua` | Own body data, bandages, attacks, treatment, scenes, sound, action priority, locomotion, and application. |
| Native path composition | `ClientNativePathController/PNC_ClientNativePathController.lua` | Load state, goal, passage, binding, request, recovery, update, and lifecycle modules. |
| Passage composition | `ClientNativePathController/PNC_ClientNativePathController_Passage.lua` | Load shared, fence, window, and passage-routing spokes in order. |

The 2026-09-20 static architecture scan rates PresenceSync at 92.8/100 health
with 11.5/100 refactor pressure. It still reports four large functions:
`applySnapshotToBody`, `applySnapshots`, `applyActionMotion`, and
`Internal.UpdateNativePathController`. Source review shows each coordinates a
different ordered contract: body maintenance before action and locomotion,
per-snapshot binding and presentation cadence, action priority, and native
controller ownership before path or passage work. Keep those decisions
together until a helper can own a state lifecycle, test boundary, or measured
hot-path benefit. The scan has 78.5% coverage and 62.7% confidence; its
observability and state-integrity categories remain unknown, so the score is a
triage signal rather than proof of completeness.

## Migration Order

1. Preserve the public facade and load order while separating body registry
   and cleanup responsibilities. **Implemented.**
2. Separate local snapshot refresh, remote cadence, and apply orchestration;
   prune stale per-NPC state. **Implemented.**
3. Separate native path goal, request, recovery, and passage behavior while
   preserving client ownership and traversal priority. **Implemented.**
4. Separate visual spokes while preserving the action-priority order and
   client-side rendering contract. **Implemented.**
5. Gate animation tracing on explicit debug state or the force switch, then
   cap retained trace history and auto-dump keys. **Implemented; focused tests
   pass.**
6. Keep extracting only source-confirmed seams. `startFenceClimb` now delegates
   traversal preflight to a local `prepareFenceClimb` descriptor builder before
   taking path or movement ownership. The production passage smoke covers low
   and tall success, blocked approach and landing, and verifies that preflight
   failures do not clear paths, reset movement, suppress zombie state, hold the
   body, or start an animation. **Implemented.**

## Compatibility and Load Order

- Keep the existing `PNC` namespaces, public facade methods, snapshot field
  meanings, and return values. Compatibility glue belongs in the facade
  modules, not throughout implementation spokes.
- Composition files load providers before consumers and wire the public entry
  point last. Preserve their explicit `require` order.
- Target Project Zomboid's Kahlua/Lua 5.1 runtime. Avoid unsupported language
  features and sandbox libraries. Use explicit guards for missing dependencies;
  do not use protected calls as normal control flow or engine-bug handling.
- No PresenceSync persistent schema or wire format migration is part of this
  refactor. Any future snapshot contract change needs an explicit compatibility
  and multiplayer rollout plan.

## Tests and Acceptance

Run focused groups after each slice, then the complete suite:

```bash
python3 tests/run_tests.py pnc_network_server_presence_boundary pnc_network_scale
python3 tests/run_tests.py pnc_mp_presence_authority pnc_sp_local_snapshot
python3 tests/run_tests.py pnc_client_bootstrap_tick pnc_client_initial_state_retry pnc_sp_local_snapshot_dirty_budget
python3 tests/run_tests.py pnc_client_body_cleanup pnc_mp_snapshot_budget
python3 tests/run_tests.py native_fence_passage native_path_recovery window_break_traversal pnc_split_fence_traversal pnc_engine_path_planner native_passage_cache
python3 tests/run_tests.py action_props mp_replica_visual_ownership bandage_visuals
python3 tests/run_tests.py pnc_animation_trace pnc_animation_debug_snapshot_gate
python3 tests/run_tests.py
```

Run `pz_verify --kahlua` over every changed runtime Lua directory and
`git diff --check`. Acceptance requires stable snapshot/body contracts, no
authority widening, a pure client that never scans/builds local authoritative
snapshots, no stale duplicate body application, correct local and
remote cadence, preserved fence/window action priority and recovery, bounded
caches and diagnostics, and no new full-suite failures beyond the recorded
baseline.

The latest full-suite baseline has three failures outside the PresenceSync
slice: a constants key-count expectation mismatch and two inventory smoke
fixtures that lack `RegisterServerCommand`. Re-run the full suite before
attributing any of these failures to a PresenceSync change.

## Performance and Memory Bounds

- Body resolution uses per-scan indexes for lease, instance ID, UUID, and
  online ID. The body scan uses the configured normal interval (750 ms
  fallback) and a faster unresolved interval (200 ms fallback), rather than
  rebuilding on every snapshot.
- Remote presentation applies on snapshot/body changes, presentation changes,
  or the next due time. Stale per-NPC cadence and prune state must be removed
  when snapshots disappear.
- The static PresenceSync audit found no `linear_scan_in_loop` or
  `alloc_in_loop` candidates in its bounded hot-path query. This is static
  evidence only; use the in-game profiler before claiming runtime gains.
- Animation tracing is optional. Its sample history is capped at 48 samples
  per trace, retained traces at 64, and auto-dump dedupe keys at 256. Evicting
  a trace also removes its body lookup. With diagnostics off, ordinary combat
  snapshots must not start a trace merely because `combatDebugState` exists.

## Runtime Log Review

The newest available `console.txt` was modified 2026-09-19. Its full 1,505-line
scan contained no Lua exception or PresenceSync stack trace. Animation trace
`#46` reported `bump_cleared_after_set` at `setter_before` 153 ms after attack
start. This matches the one-time dropped-bump recovery, which clears the
selector before requesting it again; the match is an inference from the trace
and current rearm timing. Intentional resets are now marked
`expectedRearmSelectorClear=true` and excluded from failure classification. A
later unexpected clear remains a failure; verify the marker in the next live
diagnostic run.

The same console reports a singleplayer PathService window traversal with
`crossed=true`, `finished=false`, and `timedOut=true`, followed by
`route_failed reason=traversal_hard_timeout`. These events come from the shared
PathService traversal lane rather than the multiplayer client PresenceSync
controller. The path call chain confirms that a crossed traversal reaches its
landing and releases its scripted action at the bounded deadline, then
invalidates the timed-out engine route for replanning. The `route_failed` line
records that route repair; it does not mean the NPC failed to cross. The
`pnc_split_fence_traversal` integration smoke now checks normal completion,
crossed timeout completion, the route invalidation handoff, and both diagnostic
results. The `pnc_engine_path_planner` smoke continues through the production
passage recovery and planner: a full request budget yields `native_budget_deferred`,
then the planner issues a new Behavior2 request when the 100 ms budget window
expires.

The initial-state request tick retains only its latest scalar outcomes in
`PNC.Client.Internal.InitialStateRequestDiagnostics`. A transport failure logs
once per service and reason, with the retry identity when a bootstrap was
attempted; expected `throttled` and `current` outcomes do not warn. For example:
`[PNC][WARN] initial_state_request service=playerBootstrap result=deferred reason=player_unavailable requestID=bootstrap:<time>:<serial> forcedByKnowledge=true`.
Successful dispatch clears that service's warning dedupe state. The diagnostic
record retains no request payload or Java runtime object.

## Risks and Rollback

- Splitting action arbitration can change which subsystem owns the engine
  animation or path in a frame. Keep the existing ordering unless a focused
  test demonstrates the same owner transition after extraction.
- Identity and body-index changes can bind a duplicate or stale Java body.
  Retain lease/instance validation and test ambiguous IDs, body replacement,
  and duplicate-shell pruning.
- Passage changes can leave a native ActionContext, path request, or movement
  lease active. Test both success and every explicit failure/retry path.
- Diagnostics now discard the oldest entries at their caps. This affects
  optional history only; it does not change saved state or network messages.
- Each migration slice is reversible by restoring its facade/load-order file
  and removing that slice's modules and tests. No save migration is required.

## Manual Runtime Check

1. In singleplayer, let a local NPC change movement and attack state. Confirm
   snapshot refresh and body presentation continue without duplicate bodies.
2. On a multiplayer server with two clients, observe an NPC from the client
   that does not own the server record. Exercise movement, an attack, a fence
   crossing, and a window interaction. Confirm the replica follows the server
   snapshot, only one local body is canonical, and failed path requests recover
   without leaving a passage action or movement lease behind.
3. With animation tracing disabled, repeat an attack while combat snapshots
   are present. Expect no `[PNC][ANIMTRACE]` output. For a diagnostic run, use
   the existing client Lua console to call
   `PNC.AnimationTrace.SetEnabled(true)`, perform one attack, then call
   `PNC.AnimationTrace.DumpNPC("<snapshot id>")`. Expect a bounded trace header
   such as `[PNC][ANIMTRACE] #<sequence> npc=<id>` followed by scalar sample
   lines. An intentional attack rearm may include
   `event=setter_before ... expectedRearmSelectorClear=true`, followed by the
   requested selector in `setter_after`; a later unexpected clear should still
   report `failure=bump_cleared_after_set failureEvent=<event>`. Disable it with
   `PNC.AnimationTrace.SetEnabled(false)`.
4. If a duplicate shell is intentionally reproduced, expect a bounded warning
   beginning `PNC client duplicate shells pruned npc=`. If an orphaned native
   passage context is recovered, expect
   `[PNC][PATH] orphaned_passage_context_recovered`.

The automated smoke suite remains the acceptance gate when an in-game
multiplayer session is unavailable; record manual runtime results separately.
