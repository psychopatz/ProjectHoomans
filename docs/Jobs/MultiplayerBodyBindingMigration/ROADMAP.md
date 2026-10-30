# Roadmap — Multiplayer Body Binding Migration

**Status:** REOPENED after native SP/MP failure. M0-M8 remain implemented prerequisites; M9 is mandatory. DEVELOPER_ACCEPTANCE.md is historical evidence, not current completion.

**Parent objective:** successfully migrate Project Hoomans from implicit cross-network IsoZombie identity to an explicit, incarnation-safe multiplayer body-binding protocol **and** from native PopMan-owned live-human carriers to PNC-owned population-detached transient shells, while preserving SP behavior, durable Registry authority, MP streaming/reconnect, death/reanimation semantics, and exact cleanup.

The full M0-M9 objective is the completion boundary. Phase completion is not goal completion.

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

## M9 — Population-detached live-human shell migration

Native SP/MP acceptance after M8 reproduced persistent old NPC husks. Installed 42.22 Java ground truth shows the current factory (`addZombiesInOutfit` / `VirtualZombieManager.createRealZombieAlways`) registers every live PNC carrier with `ZombiePopulationManager`. That is now treated as an invalid ownership boundary for a disposable human carrier.

### M9A — Prove a transient shell factory

Required:
- use installed 42.22 Java ground truth to enumerate the minimum safe admission steps around `IsoZombie.new(getCell())` (or the smallest equivalent factory);
- create a focused prototype/fixture that yields a usable live `IsoZombie` without `ZombiePopulationManager.registerZombie()`;
- preserve PNC visual/human initialization, health, movement, combat and managed-body stamping requirements;
- prove the resulting live human carrier has `persistentId == 0`;
- prove SP world/square/cell membership is correct and exact removal leaves no object behind;
- on MP server, prove how online ID allocation, `ServerMap.zombieMap`, emitter/list membership and NetworkZombieManager/NetworkZombiePacker participation are established without PopMan registration;
- if those members cannot be safely manipulated from Lua, introduce the smallest isolated bridge/provider rather than copying a native population factory.

Gate: a transient carrier can exist and be retired without entering PopMan ownership. No production factory swap before this gate passes.

### M9B — Production materialization migration

Required:
- route normal live-human materialization through the proven transient factory;
- keep `runtime.bodyLease` and `PNC_MultiplayerBodyBinding` as the canonical logical/MP incarnation identity;
- make `persistentId == 0` a runtime invariant for every managed live human shell;
- fail closed and emit bounded diagnostics when a newly materialized managed human violates that invariant;
- ensure companion, neutral, hostile/raider, faction-owned and restored live NPCs all use the same carrier path;
- preserve existing SP direct-object semantics and MP explicit binding semantics;
- remove no gameplay authority from Registry/Presence/BodyLifecycle.

Gate: focused SP/MP fixtures prove every newly created live human shell is population-detached and all M1-M8 identity tests still pass.

### M9C — Exact transient retirement and client cleanup

Required:
- retire the server/SP transient shell without PopMan release semantics becoming a persistence source;
- preserve exact MP bind/unbind/removal ordering and incarnation guards;
- where Build 42 server networking requires the vanilla `ZombieDeleteOnClient` notification, use the exact online ID/current incarnation path only;
- never delete an unbound ordinary zombie from online ID, position, outfit, gender or proximity alone;
- verify abstraction/rematerialization creates one new transient shell and the prior physical shell cannot return as an ordinary zombie.

Gate: repeated same-session materialize -> abstract -> rematerialize cycles converge to one current shell with no old zombie at previous locations.

### M9D — Death, corpse and true-zombie transition

Required:
- ordinary live-human death/corpse conversion still invalidates the live transient shell exactly once;
- corpse behavior/inventory/clothing remains correct;
- Knox reanimation deliberately crosses the boundary from transient human carrier to a **real vanilla zombie** and may then use normal native population semantics;
- stale M1-M8 binding proof can never repaint that true zombie as a human;
- uninfected death must not accidentally register a living zombie carrier.

Gate: infected/non-infected death/reanimation matrix passes with an explicit assertion that only a true reanimated zombie may enter the normal zombie-population lifecycle.

### M9E — Legacy registered-shell migration

Existing saves may already contain PNC-originated PopMan records from pre-M9 factories.

Required:
- classify exact strong provenance that can safely identify an old registered PNC shell/population record;
- use UUID/lease/population/carrier evidence only when it is truly identifying;
- retain bounded HuskLedger/HuskReaper behavior only as a migration cleaner for those historical records;
- preserve the existing fail-closed rule for genuinely anonymous historical zombies;
- do not restore position/outfit/gender/companion-ownership heuristics as identity;
- ensure legacy cleanup cannot delete an ordinary zombie.

Gate: migration fixtures distinguish strong old-PNC provenance from ordinary coincident zombies and clean only the former.

### M9F — Re-audit and native handoff

Required developer-side evidence:
- all M0-M8 regressions remain green;
- new transient-factory/population-invariant tests pass;
- full isolated Lua suite passes;
- focused body/presence/husk/restart/replica/network/player-damage/movement/combat/infection/corpse/reanimation/follow suite passes;
- installed-PZ Kahlua compilation/static verification passes for every changed runtime Lua file;
- engine-grounded checks document any Java bridge/API used;
- no new per-frame global scans, unbounded tables or routine persistent client cache;
- `git diff --check` clean and intended work committed on existing main.

Gate: developer implementation may hand back to native testing only when the code proves new live humans are not PopMan-owned.

### Native user acceptance handoff

After all developer-side M0-M9 gates pass, user-owned native acceptance should verify:
1. SP restart/materialization behavior is restored and no former SP husk regression returns.
2. Fresh MP materialization does not leave an ordinary zombie precursor or stale zombie after reconciliation.
3. Two players in the same area see the same one NPC.
4. Players entering/leaving independently do not duplicate the NPC.
5. Chunk unload/reload and client reconnect reconstruct the same logical NPC.
6. Server restart rehydrates one canonical NPC without husks.
7. Legitimate abstraction/rematerialization does not produce persistent old shells, and the managed live human shell reports `persistentId == 0` before abstraction.
8. Companions, neutrals and hostiles all behave consistently.
9. Death/infection/reanimation remain correct.

Do not mark the parent goal complete from synthetic evidence alone. Native SP and MP must each prove that repeated abstraction/rematerialization and restart/reconnect leave no old husk, while true Knox reanimation remains a genuine vanilla zombie.
