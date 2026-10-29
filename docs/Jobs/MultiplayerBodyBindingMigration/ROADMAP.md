# Roadmap — Multiplayer Body Binding Migration

**Status:** PLANNED — implementation not started.

**Parent objective:** successfully migrate Project Hoomans from implicit cross-network IsoZombie identity to an explicit, incarnation-safe multiplayer body-binding protocol, while restoring and preserving single-player behavior, keeping the durable PNC record authoritative, making MP shell replacement/reconnect/multi-client streaming robust, and retiring obsolete husk/identity assumptions superseded by the new protocol.

The full M0-M8 objective is the completion boundary. Phase completion is not goal completion.

## M0 — Restore/freeze single-player baseline and engine truth

Required:
- characterize the user-reported SP regression introduced after the latest MP body-factory changes;
- compare current shared materialization against pre-5dbbadc4 behavior;
- surgically remove/isolate MP-driven preclaim behavior from SP where it altered the proven local lifecycle;
- preserve unrelated character-UUID ownership work unless independent evidence proves it faulty;
- add regression coverage for SP materialize -> abstract -> rematerialize -> restart;
- add an engine-grounded fixture/contract that MP client replicas are distinct local IsoZombie objects and cannot be assumed to inherit server PNC ModData;
- freeze current liveBodyOnlineID, body lease and network snapshot behavior.

Gate: SP developer-side behavior is back on the known-good local identity path, and tests make the SP-vs-MP identity distinction explicit.

## M1 — Define one body-incarnation contract

Audit whether existing runtime.bodyLease is sufficient as the body incarnation token.

Required properties:
- unique per live physical incarnation;
- stable for one shell lifetime;
- changes when shell is replaced/recovered;
- available to server networking;
- invalidated on death/reanimation transition;
- safe across save/load semantics.

If sufficient, standardize it as the protocol incarnation and do not invent a parallel generation field.

If insufficient, introduce the smallest explicit body-generation authority and migration path.

Gate: one documented/tested incarnation token exists and all body replacement paths obey it.

## M2 — Server MultiplayerBodyBinding authority

Introduce a dedicated server/shared binding service at the existing networking/presence seam.

Required:
- register current (npcId, incarnation, onlineId) only for a valid live body;
- publish bind/unbind/remove through bounded existing PNC transport;
- integrate with roster/presence interest so joining/late clients receive current bindings;
- reconstruct bindings after reconnect without respawning NPC bodies;
- reject invalid/negative/missing online IDs;
- body replacement invalidates the prior binding before the new one becomes canonical;
- diagnostics expose binding reason/source without per-tick spam;
- no client becomes authoritative for durable binding state.

Gate: synthetic server tests prove one current binding per live incarnation and deterministic replacement/unbind semantics.

## M3 — Client pending/reconciliation layer

Introduce the client half of MultiplayerBodyBinding.

Required:
- observe vanilla zombie replicas by exact onlineId;
- maintain bounded pending bindings for message-first ordering;
- maintain bounded observed replica index for replica-first ordering;
- reconcile when both sides exist;
- stamp local PNC identity only after authoritative binding;
- reject stale incarnation / conflicting identity;
- expire pending state;
- clear weak caches when replica disappears;
- idempotently handle duplicate bind messages;
- no full unrestricted zombie scan every frame.

Gate: deterministic tests cover message-first, replica-first, duplicate, stale, reordered, expired and online-ID-reuse cases.

## M4 — Route ClientPresenceSync through canonical binding

Required:
- ClientPresenceSync obtains the current local replica from MultiplayerBodyBinding;
- presentation/animation/equipment/body state apply only to the current bound incarnation;
- client ModData becomes a post-bind cache/compatibility marker, never cross-network authority;
- existing online-ID roster projection is reused rather than duplicated;
- stale replica cannot receive a newer NPC's presentation;
- MP cleanup operates from exact binding identity;
- SP local snapshots remain unchanged.

Gate: existing MP replica transport/visual tests plus new stale-incarnation tests pass without changing SP snapshot semantics.

## M5 — Presence, shell loss and husk migration

Required:
- server Presence/BodyLifecycle remains authoritative for live/abstract shell lifetime;
- stream-scoped census absence never detaches an otherwise valid attached canonical body;
- legitimate abstraction/rematerialization produces a new incarnation/binding cleanly;
- stale MP replicas are removed through exact binding/removal messages;
- HuskLedger/HuskReaper consume explicit identity where available;
- classify existing positional/anonymous recovery paths as current, legacy-migration-only or removable;
- retire heuristics made obsolete by binding evidence;
- ordinary zombies remain protected from position-only reclamation.

Gate: same-session rematerialization, chunk unload/reload, server restart, late stream and stale-shell cases converge to one logical NPC / one current server shell / one bound replica per interested client.

## M6 — Multi-client authority and movement/combat interoperability

Required developer-side fixtures:
- two+ clients observing the same NPC;
- clients entering/leaving interest range independently;
- one client receives binding before replica, another replica before binding;
- movement/pathing presentation remains attached to the correct incarnation;
- player hit / NPC combat targets resolve the correct canonical server NPC;
- companion following does not create identity churn;
- hostile/neutral/companion NPC types all use the same binding protocol;
- client authority transfer / isRemoteZombie changes cannot transfer PNC logical ownership;
- no per-role body-binding implementation.

Gate: MP identity remains invariant across client count, role and vanilla zombie simulation-owner changes.

## M7 — Death, corpse, infection and reanimation integration

Required:
- live binding invalidates exactly once on NPC death;
- corpse lifecycle does not get rebound as a live human;
- Knox infection/reanimation still produces the intended true zombie;
- stale live-binding messages cannot repaint a reanimated zombie as an NPC;
- joining clients receive correct dead/corpse/reanimated state;
- restart preserves correct result;
- current health/wound/corpse inventory behavior remains compatible.

Gate: infected and non-infected death matrices pass across SP and synthetic MP ordering.

## M8 — Final migration cleanup and acceptance

Required:
- remove/deprecate obsolete MP assumptions that server ModData/body object identity crosses to clients;
- remove superseded temporary preclaim/repair paths;
- preserve only justified legacy-save migration helpers;
- static audit shows one canonical MP body-binding authority;
- update job docs with exact accepted evidence;
- full isolated Lua suite passes;
- focused SP/MP body/presence/husk/reanimation/network suites pass;
- installed-PZ Kahlua verification passes for changed Lua;
- git diff --check clean;
- no new performance-hot global scans or unbounded pending tables;
- no new routine persistent client binding state.

### Native user acceptance handoff

After all developer-side M0-M8 gates pass, user-owned native acceptance should verify:
1. SP restart/materialization behavior is restored and no former SP husk regression returns.
2. Fresh MP materialization does not leave an ordinary zombie precursor or stale zombie after reconciliation.
3. Two players in the same area see the same one NPC.
4. Players entering/leaving independently do not duplicate the NPC.
5. Chunk unload/reload and client reconnect reconstruct the same logical NPC.
6. Server restart rehydrates one canonical NPC without husks.
7. Legitimate abstraction/rematerialization does not produce persistent old shells.
8. Companions, neutrals and hostiles all behave consistently.
9. Death/infection/reanimation remain correct.

Do not mark the parent goal complete from synthetic evidence alone if native evidence still contradicts a migration invariant.
