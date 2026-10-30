# Roadmap — Multiplayer Body Binding Migration

**Status:** M9 native restart acceptance failed; M10 restart-shell recovery is developer-accepted in ada48d24; renewed user-owned native SP/MP restart acceptance pending.

**Parent objective:** successfully migrate Project Hoomans from implicit cross-network IsoZombie identity to an explicit, incarnation-safe multiplayer body-binding protocol **and** prevent managed live-human carriers from reaching native zombie virtualization, while preserving SP behavior, durable Registry authority, MP streaming/reconnect, death/reanimation semantics, and exact cleanup.

The full M0-M10 objective is the completion boundary. Phase completion is not goal completion.

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

## M9 — Native-population virtualization prevention

Native SP/MP acceptance after M8 reproduced persistent old NPC husks. Installed 42.22 Java and native-library inspection refined the cause: the husk is created when a live managed `IsoZombie` reaches Project Zomboid's native **virtualization** path (`n_addZombie`) during chunk unload or out-of-loaded-area pathing. Registration of a currently loaded real zombie and creation of a persistent virtual population record are distinct native operations.

The accepted M9 design is therefore an engine-proven equivalent to a fully detached shell: **PNC must retire every managed live-human carrier while it is still attached and loaded, before PZ can call `n_addZombie`.** This preserves the already-working vanilla MP zombie transport and avoids an unsupported Java-agent/classpath dependency.

### M9A — Prove the native lifecycle boundary

Required:
- verify current factories and `IsoZombie.removeFromWorld()` against installed 42.22 Java source;
- verify chunk unload and out-of-loaded-area movement call native virtualization before ordinary removal;
- verify the native library exposes separate `n_registerZombie`, `n_addZombie`, and `n_releaseZombie` operations;
- establish that proactive attached-body PNC removal follows the release path without first invoking the virtualization/add path;
- audit the proposed `persistentId == 0` factory alternative and reject it if it cannot satisfy vanilla MP network admission or still remains vulnerable to chunk virtualization.

Gate: the implementation mechanism must prevent `n_addZombie` for managed live humans without adding an unsupported launcher/agent dependency.

### M9B — Hard embodiment safety envelope

Required:
- `forceLive` may request a body only while a player owns the materialization radius;
- force-live, stale combat targets, follow state, debug/director requests and incapacitation may not bypass the hard live-body retirement envelope;
- no-player live shells must retire;
- MP retirement distance must remain inside the server's minimum loaded-cell envelope;
- SP/splitscreen must additionally respect actual local `IsoChunkMap` bounds with a conservative chunk margin;
- companion, neutral, hostile/raider, faction-owned and restored NPCs use the same Presence rule.

Gate: policy tests prove no gameplay flag can keep or create a managed shell outside player-owned loaded world space.

### M9C — Cadence-independent pre-virtualization retirement

Required:
- run a bounded global safety sweep independent of per-NPC behavior/presence cadence;
- inspect only the capped live-body registry, never the complete world-zombie population;
- refresh the body-backed position before checking the envelope;
- collect retirements before mutating the live registry;
- apply the same cheap fence in per-record processing before behavior/pathing can issue a new native route;
- retire through the existing exact lease/body lifecycle so successful attached removal does not arm the husk ledger;
- preserve exact MP bind/unbind/remove ordering and incarnation guards.

Gate: even an idle NPC or fast-moving player's follower is retired before its carrier can enter an unloading chunk or engine out-of-loaded-area virtualization path.

### M9D — Death, corpse and true-zombie transition

Required:
- existing live-human death/corpse conversion continues to invalidate the current PNC incarnation exactly once;
- corpse inventory/clothing/health authority remains unchanged;
- Knox reanimation may intentionally become a true vanilla zombie and thereafter use normal native population virtualization;
- stale M1-M8 binding proof can never repaint that true zombie as a human.

Gate: all existing infected/non-infected death, corpse and reanimation regressions remain green after the preventive lifecycle change.

### M9E — Legacy/already-virtualized recovery

Older saves or a rare engine race may already contain a pre-M9 virtualized PNC carrier.

Required:
- keep HuskLedger/HuskReaper only for already-lost or historical strong-provenance shells;
- successful proactive attached-body retirement must not arm the ledger;
- preserve the fail-closed rule for genuinely anonymous zombies;
- never restore position/outfit/gender/companion-ownership heuristics as identity;
- exact legacy cleanup must not delete an ordinary zombie.

Gate: current-session normal lifecycle is preventive; reaping is fallback/migration only.

### M9F — Re-audit and native handoff

Required developer-side evidence:
- all M0-M8 regressions remain green;
- hard-envelope, no-player, force-live, combat-target, local chunk-map, global-sweep and pre-path retirement regressions pass;
- full isolated Lua suite passes;
- focused body/presence/husk/restart/replica/network/player-damage/movement/combat/infection/corpse/reanimation/follow suite passes;
- installed-PZ Kahlua compilation/static verification passes for every changed runtime Lua file;
- no new per-frame global world scan, unbounded table or persistent client cache;
- `git diff --check` clean and intended work committed on existing main.

Gate: developer implementation may hand back to native testing only when source/runtime evidence proves managed live humans are proactively retired before native virtualization.


## M10 — Restart shell identity recovery after M9 native failure

Native restart logs on 2026-10-30 disproved the remaining M9 assumption that runtime pre-virtualization retirement alone was sufficient. Startup reported ordinaryUnknown=6 blockedRecords=5 and later ordinaryUnknown=4 blockedRecords=4, removed zero shells, then spawned replacement NPC bodies while the anonymous old IsoZombie carriers remained.

### M10A — Safe current-save rehydration

Required:
- the durable Registry record remains restart authority;
- zero-identity restored bodies may be adopted only when the current save proves a live leased shell with a prior real engine identity;
- require tight saved position, matching sex when available, a real-frame settle window, and one-to-one record/body ownership;
- keep the lane role-agnostic across companion, neutral, hostile and faction NPCs;
- anonymous evidence may authorize adoption only, never duplicate deletion;
- multiple anonymous bodies or anonymous plus exact proof are ambiguous and delete nothing.

Gate: the ordinaryUnknown plus blockedRecords restart shape holds startup open, quarantines the shell, and rebinds the unique restored body before Presence can spawn a replacement.

### M10B — Exact live-shell identity token

Required:
- stamp live shells with one lifecycle-only engine-saved item carrying the durable NPC id;
- exclude the token from logical inventory and strip it before corpse conversion;
- startup treats a surviving token as strong identity;
- conflicting token/ModData identity fails closed;
- normal materialization and restored-body rebind both ensure the token.

### M10C — SP pre-save retirement

Required:
- use the real Events.OnSave ordering before local world and PopMan persistence;
- retire bounded live PNC carriers through canonical Presence/BodyLifecycle before the PNC registry commit;
- persist abstract logical state so the subsequent PZ save has no live PNC IsoZombie to serialize;
- surface removal deferrals instead of claiming success.

### M10D — Dedicated/MP restart contract

Installed 42.22 server save code calls ZombiePopulationManager.updateRealZombies immediately before native n_save and exposes no safe Lua authority pre-save detach/re-admit seam that preserves ServerMap/online-id membership. MP restart recovery is therefore an explicit startup-rebind contract.

Required:
- startup gate remains open through settle/rebind;
- recovered body is humanized/quarantined before adoption;
- successful rebind emits one PNC startup_rehydrate_rebound log line;
- failure or ambiguity never falls through to replacement materialization beside an unresolved shell;
- true Knox-reanimated zombies remain outside this path.

### M10E — Developer validation

Accepted developer evidence for ada48d24:
- full isolated Lua suite: 972/972;
- broad lifecycle/network/persistence/combat/death matrix: 231/231;
- focused restart/husk/body/presence/reanimation/infection/network/replica/persistence matrix: 163/163;
- installed Project Zomboid Kahlua compiler: 14/14 changed/new runtime Lua files pass;
- static Kahlua ERROR scan: 14/14 clean;
- Startup_Batch is smaller than the pre-M10 baseline after extracting the anonymous-rehydrate helper;
- git diff --check clean before commit.

### Native user acceptance handoff

After all developer-side M0-M10 gates pass, user-owned native acceptance should verify:
1. SP restart/materialization behavior is restored and no former SP husk regression returns.
2. Fresh MP materialization does not leave an ordinary zombie precursor or stale zombie after reconciliation.
3. Two players in the same area see the same one NPC.
4. Players entering/leaving independently do not duplicate the NPC.
5. Chunk unload/reload and client reconnect reconstruct the same logical NPC.
6. Server restart rehydrates one canonical NPC without husks.
7. Legitimate abstraction/rematerialization does not produce persistent old shells; managed live humans retire while still inside the safe loaded envelope, before native virtualization can run.
8. Companions, neutrals and hostiles all behave consistently.
9. Death/infection/reanimation remain correct.

Do not mark the parent goal complete from synthetic evidence alone. Native SP and MP must each prove that repeated abstraction/rematerialization and restart/reconnect leave no old husk, while true Knox reanimation remains a genuine vanilla zombie.
