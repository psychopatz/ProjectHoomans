# Roadmap — Multiplayer Body Binding Migration

**Status:** M11 fixed command/binding and late-stream admission, but post-M11 hosted MP still exposed zombie-looking bound replicas and loss of restart admission across clean shutdown. M12 is developer-accepted in `e5cd9645` and `bd84bfe4`; renewed user-owned native MP acceptance pending.

**Parent objective:** successfully migrate Project Hoomans from implicit cross-network IsoZombie identity to an explicit, incarnation-safe multiplayer body-binding protocol **and** prevent managed live-human carriers from reaching native zombie virtualization, while preserving SP behavior, durable Registry authority, MP streaming/reconnect, death/reanimation semantics, and exact cleanup.

The full M0-M12 objective is the completion boundary. Phase completion is not goal completion.

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

## M11 — Dedicated late-stream reconciliation and MP replica authority

Native testing after M10 produced a split result: single-player restart behavior succeeded, while dedicated multiplayer still reproduced stale husks and the Spawn Hoomans debug action could produce dialogue/logical state without a visible NPC.

The 2026-10-30 dedicated-server log establishes the owning race:
- startup loaded eight Registry records with zero players/chunks;
- at 11:58:09 startup logged `PNC startup rehydration fallback count=8`;
- cleanup immediately completed with `removed=0 ordinaryUnknown=0 blockedRecords=0`;
- only after a player joined did those NPC areas stream and fresh bodies materialize.

Thus dedicated startup cannot assume absence of a shell when its saved chunk has never been loaded.

### M11A — Authoritative multiplayer debug actions

Required:
- when Build 42 reports client mode, debug mutations use `sendClientCommand` even in hosted/listen configurations where client and server capabilities may coexist;
- direct debug-spawn handler calls have the same network defense;
- SP remains local;
- server `PNC debug spawn variant=...` is the authoritative proof that a multiplayer spawn request arrived.

Gate: MP debug spawn cannot create only local dialogue/logical state.

### M11B — Atomic server body-binding projection and targeted client recovery

Required:
- `bodyBinding.onlineId`, `liveBodyOnlineID`, and `liveBodyLease` come from one verified server projection;
- a freshly assigned engine online ID repairs the record cache before serialization;
- a pure client may perform an exact online-ID lookup only while an authoritative bind is unresolved;
- that lookup is cadence-bounded and stops after binding;
- a WorldCensus miss falls through to the exact engine zombie-list lookup instead of returning nil early;
- duplicate online IDs fail closed;
- normal resolved lookups remain O(1).

Transition diagnostics:
- server: `PNC mp_body_binding_ready npc=<id> lease=<lease> onlineID=<id>`;
- client: `PNC mp_body_binding_bound npc=<id> lease=<lease> onlineID=<id>`.

Gate: a server-visible NPC cannot remain dialogue-only merely because bind and engine-replica observation arrived in the opposite order.

### M11C — Dedicated late-stream restart claims

Required:
- unresolved saved-live claims are not discarded when dedicated startup has no player-interest chunks;
- global startup may still complete; each unresolved record transfers into its own late-stream claim;
- no world-wide scan is added;
- when the saved square first loads, only that NPC gets a bounded 1500 ms settle window;
- exact UUID/token/saved engine identity is preferred;
- the existing current-save anonymous proof remains adoption-only;
- streamed anonymous candidates are humanized/quarantined before vanilla hostile behavior can matter;
- one proven/unique shell is rebound;
- multiple candidates remain ambiguous and block replacement spawning;
- after the loaded-square settle expires with no shell, the claim releases and normal materialization may continue;
- true Knox-reanimated zombies remain protected/excluded.

Expected log progression:
- startup: `PNC startup late-stream rehydration armed count=N`;
- first loaded saved square: `PNC late_stream_rehydrate_window npc=<id> settleMs=1500`;
- successful recovery: `PNC late_stream_rehydrate_rebound npc=<id> ...`;
- true miss after loaded settle: `PNC late_stream_rehydrate_released npc=<id> reason=no_shell_after_loaded_settle`.

Gate: replacement `spawnPrimary` cannot happen before the saved area receives its late-stream reconciliation opportunity.

### M11D — Developer validation

Accepted developer evidence:
- full isolated Lua suite: **975/975**;
- broad restart/husk/body/presence/body-binding/debug-spawn/replica/network/persistence/follow/combat/infection/corpse/reanimation matrix: **228/228**;
- focused MP network/body-binding/presence matrix during implementation: **134/134**;
- installed Project Zomboid Kahlua compiler: **16/16 changed/new runtime Lua files pass**;
- static Kahlua ERROR scan: all changed runtime Lua files clean;
- new late-stream and targeted-recovery modules pass the 2k token-bloat guard after modular split;
- `git diff --check` clean before commits.

Implementation commits:
- `fc932e1d fix: restore multiplayer npc replica binding`
- `5c10a95b fix: defer mp npc spawn for late restart shells`

## M12 — MP human presentation authority and restart-proof durability

Post-M11 hosted multiplayer acceptance on 2026-10-30 failed in two new, independently evidenced ways.

The screenshot/session is post-M11 and contains successful `mp_body_binding_bound` events, proving the physical client replicas exist. However several bound NPCs render with zombie complexion/presentation. The matching server log shows every body initially created as a vanilla `Male/Female Zed, Dressed in PNCShellCarrier`.

The same session also disproved M11 restart durability. A clean hosted shutdown persisted six newly created starting companions, but the next host start loaded 11 Registry records while arming late-stream rehydration for only 5.

### M12A — authoritative human visual ownership

Root cause:
- `PNC_Visuals.ApplyHumanVisuals()` classified both server and client runtimes as network replicas;
- authoritative MP servers therefore called `ApplyReplicaAppearance()` instead of `ApplyResolvedAppearance()`;
- remote client replicas correctly refused to own clothing, leaving the underlying zombie carrier able to render zombie HumanVisual state;
- after bind, native zombie replication could overwrite skin/hair/beard again while the client visual key prevented a second full appearance pass.

Required:
- `Core.IsAuthority()` decides resolved-vs-replica appearance ownership;
- SP/server/host authority uses full resolved human appearance;
- pure clients never clear/rebuild server-owned worn or attached items;
- pure clients perform a bounded 250 ms identity-visual integrity check only;
- the check compares gender/skin/hair/beard and does nothing when current;
- on drift, it reapplies only human identity fields and refreshes the model;
- clothing/equipment/inventory remain server-owned.

Engine verification:
- `IsoZombie.dressInNamedOutfit()` rebuilds HumanVisual/ItemVisuals but does not change `persistentOutfitId`;
- therefore authoritative human dressing does not destroy the `PNCShellCarrier` fingerprint.

Implementation: `e5cd9645 fix: preserve human visuals on mp replicas`.

### M12B — durable live-detach restart proof

Root cause:
- clean host shutdown can detach/abstract a live NPC before `SaveAll`;
- `CaptureDetachedBodyHint` retained instance/population/lease/position but omitted `wasLive=true`;
- after the record became abstract, serialization emitted `bodyHint.wasLive=false`;
- on the next boot, deserialization correctly did not set `startupRehydrateExpected`;
- observed evidence: prior session created six live Weller/Foss starting companions; next session loaded 11 records but only 5 late-stream claims were armed.

Required:
- live, non-corpse detach records `wasLive=true` before clearing the body lease;
- a corpse/death detach explicitly cannot inherit an older live-restart flag;
- a late-stream claim may be held from `wasLive + lease + saved position` even if engine IDs are absent;
- existing M11-affected saves receive a bounded backward migration only when an old `wasLive=false` hint still has lease + coordinates + exact saved engine carrier identity;
- that legacy migration does not enable anonymous position-only adoption;
- anonymous adoption continues to require the stricter current-save uniqueness/radius/sex proof.

Implementation: `bd84bfe4 fix: persist mp restart body ownership`.

### M12C — evidence clarification

The reported “new save” hosted session is not a new world according to Project Zomboid:
- PZ logs `isNewGame = false`;
- it loads `Saves/Multiplayer/NPCEngine/global_mod_data.bin`;
- PNC loads 5 pre-existing records before the joining character's 6 starting companions are created.

This does not invalidate the zombie-presentation defect. It matters only for restart provenance: future audits must distinguish reused-world records from newly created starting companions.

### M12D — developer validation

Accepted developer evidence:
- complete repository suite: **978/978**;
- focused restart/husk/body/presence/visual/replica/network/persistence/appearance/human/corpse/reanimation matrix: **189/189**;
- focused new M12 regressions cover authoritative visual ownership, post-bind zombie-skin repair, live-detach restart proof, corpse exclusion, M11 legacy strong-carrier migration, late-stream reconciliation, and existing replica visual ownership;
- installed Project Zomboid Kahlua compiler: **7/7 changed/new runtime files pass**;
- static Kahlua ERROR scan: all changed runtime files clean;
- new `PNC_Visuals_ReplicaIntegrity.lua`, `PNC_BodyLifecycle_DetachedHint.lua`, and late-stream candidate policy remain below the 2k token-bloat threshold;
- `git diff --check` clean.

### Native user acceptance handoff

After all developer-side M0-M12 gates pass, user-owned native acceptance should verify:
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
