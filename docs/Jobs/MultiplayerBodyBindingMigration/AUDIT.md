# Audit — Multiplayer Body Binding Migration

## Revision

Planning anchor: 2a24bc59d36c845af51097642c55180434680cb7 on existing main.

Repository was clean at planning time.

This audit is based on current Project Hoomans source/tests, the latest user-observed SP/MP failures, installed Project Zomboid 42.22.0 Java runtime inspection, and read-only comparison with installed Project A-Life [ALIFE NPCS].

It does not claim successful native SP/MP acceptance of the migration.

## 1. The failure has outgrown a husk-cleanup bug

Repeated fixes to startup husk reaping, late-stream shell reclamation, census handling and server body-removal broadcasts reduced specific failure modes but did not eliminate the MP symptom.

Current user evidence:
- single-player had previously reached a state where restart husks were eliminated;
- later MP-oriented changes regressed single-player;
- multiplayer still visibly produces ordinary zombies first and NPCs later;
- same-session NPC shell replacement/rematerialization can occur;
- multi-player streaming/census behavior has already invalidated assumptions that worked in SP.

The remaining problem must be treated as an identity/replication architecture issue, not another positional husk matcher.

## 2. Decisive engine fact: MP clients do not receive the server IsoZombie object

Inspection of installed Project Zomboid 42.22.0 shows that multiplayer zombie replication is keyed by the vanilla zombie network ID.

When a client receives an unknown zombie ID, NetworkZombieSimulator creates a new local IsoZombie through the virtual-zombie machinery and associates that local object with the received online ID.

Therefore:

    server IsoZombie A
        PNC ModData / body lease
        onlineId = N
              |
              | vanilla zombie packet
              v
    client IsoZombie B
        onlineId = N
        not the same Java object

Project Hoomans must not assume server-side ModData, Lua object identity, weak references or body handles are transported as identity to the client.

The vanilla zombie packet carries engine zombie state, not Project Hoomans' durable PNC_UUID/body-lease authority.

## 3. Why the recent server-side preclaim cannot solve MP identity

Commit 5dbbadc4 introduced early PreclaimLiveBody behavior in the shared body factory so the newly created server zombie receives PNC ownership/lease state before the spawn window closes.

That can influence the server/local object, but it does not make custom PNC ModData part of the vanilla zombie network packet.

Consequently:
- it cannot guarantee the client-created replica begins life as a recognized PNC NPC;
- it changed the shared SP materialization path despite being motivated by MP;
- the user reports SP regression after the change while MP remains broken.

M0 must isolate/restore the known-good SP materialization behavior before the MP protocol migration proceeds.

Do not blindly revert unrelated later work. The character-scoped companion ownership work in 2a24bc59 is a separate concern and should be preserved unless independent evidence proves it faulty.

## 4. Existing Hoomans architecture already has most required layers

Current reusable foundations include:
- durable PNC Registry records;
- Presence live/abstract decisions;
- BodyLifecycle body creation/release/reanimation/startup handling;
- server network snapshots and roster transport;
- ClientPresenceSync;
- client PresenceVisuals;
- liveBodyOnlineID projection;
- body leases / persisted shell identity;
- health/combat/gameplay authorities separate from presentation;
- existing MP scale/budget tests;
- existing husk/startup/rehydration tests.

The migration should add a precise MP body-binding seam, not replace the whole NPC simulation.

## 5. The missing contract

Hoomans already knows both logical NPC identity and vanilla transport identity. What is missing is treating their relationship as a first-class multiplayer protocol.

Required conceptual tuple:

    npcId
    bodyIncarnationOrLease
    onlineId
    optional presence/protocol epoch

This tuple must be authoritative on the server and explicitly reconciled on every client.

Client-side PNC identity must be established from this binding, not from an assumption that server ModData survived replication.

## 6. Project A-Life is relevant precedent

Read-only reference:

/home/psychopatz/.steam/debian-installation/steamapps/workshop/content/108600/3803984183/mods/ProjectALifeNPCs/42.20/media/lua/

Relevant source:
- server Shells/ALifeShellAdapter.lua;
- server Core/ALifeWatchdog.lua;
- shared Shells/ALifeAIFence.lua;
- shared Shells/ALifeAnimations.lua;
- client Shells/ALifeAnimationClient.lua;
- shared Core/ALifeExecutor.lua.

Verified architectural observations:
- A-Life also uses IsoZombie as the physical shell;
- its durable actor UID/generation is independent from the shell;
- server shell binding is guarded by UID + generation;
- server sends explicit client sync carrying onlineId + uid + generation + presentation;
- client keeps pending messages by online ID;
- client observes vanilla zombie replicas and binds/stamps them when the matching explicit identity message is available;
- either message-first or zombie-first ordering is tolerated;
- stale identity/generation conflicts fail closed;
- shell loss/recovery is expected and bounded by a watchdog;
- actor lifetime is not equated with shell lifetime.

This is strong evidence that IsoZombie can remain the MP carrier only if Hoomans stops treating object/ModData continuity as the cross-network identity mechanism.

Project Hoomans should reproduce the guarantees, not copy A-Life code.

## 7. SP and MP must stop sharing false identity assumptions

SP:

    PNC record
        |
    same-process local body
        |
    direct PNC body identity

MP:

    server PNC record
        |
    server shell + onlineId
        |
    explicit binding protocol
        |
    client local zombie replica
        |
    client reconciled PNC presentation identity

MP-only reconciliation must not mutate the SP body factory merely because both use IsoZombie.

## 8. Body incarnation must distinguish shell replacements

An NPC may legitimately materialize multiple times during one session because of abstraction, recovery, streaming, death/reanimation transitions or body replacement.

An online ID alone is insufficient as durable identity.

Existing runtime.bodyLease may serve as the incarnation token if audit proves it provides:
- uniqueness per live body incarnation;
- stability for one body lifetime;
- change on replacement/recovery;
- stale-message rejection.

Do not create a redundant generation counter unless the lease contract is insufficient.

## 9. Cleanup and husk logic should become downstream consumers

Current HuskLedger/HuskReaper code contains increasingly complex recovery heuristics because it has been compensating for uncertain physical identity.

After explicit MP binding exists:
- binding/replacement state should identify the canonical shell;
- stale client replicas should be removed by exact online ID + incarnation evidence;
- server cleanup should not depend on positional guesses when exact binding evidence exists;
- positional/startup migration heuristics should remain only for legacy save migration or genuinely identity-less historical shells;
- ordinary zombies must never be reclaimed solely because they are near an NPC's old position.

## 10. Immediate implementation implication

The first chunk is not "write the new MP binding module."

It is:
1. freeze the pre-regression SP contract;
2. surgically remove/isolate MP-driven preclaim behavior from the shared SP path;
3. add an engine-grounded MP ordering fixture documenting that a client replica begins without trusted PNC ModData;
4. freeze current server snapshot onlineId projection and client discovery behavior;
5. only then introduce the body-binding protocol behind explicit SP/MP boundaries.

This prevents another migration step from making SP correctness collateral damage.


## 13. Native M0-M8 acceptance failure: managed shells reached native virtualization

User-owned native testing on 2026-10-30 reproduced the old NPC husk in both SP and MP after the M0-M8 implementation. This is stronger evidence than the synthetic green suite and reopens the lifecycle architecture.

Installed Project Zomboid 42.22 Java ground truth:

1. `LuaManager.addZombiesInOutfit(...)` calls `VirtualZombieManager.createRealZombieAlways(...)`.
2. `createRealZombieAlways(...)` adds the `IsoZombie` to live engine lists, assigns server `onlineId`, and calls `ZombiePopulationManager.registerZombie(...)`.
3. The resulting live PNC carrier receives a native non-zero `persistentId`.
4. `IsoZombie.removeFromWorld()` calls `ZombiePopulationManager.releaseZombie(...)`.
5. PZ's real/virtual zombie lifecycle calls native `n_addZombie(...)` before `removeFromWorld()/removeFromSquare()` during chunk unload or explicit virtualization.
6. Native `libPZPopMan64.so` inspection shows `n_registerZombie`, `n_addZombie`, and `n_releaseZombie` are distinct operations/queues. Proactive attached-body `removeFromWorld()` reaches release without first calling the add/virtualization path.
7. A `persistentId == 0` carrier is not sufficient: chunk unload still virtualizes any `IsoZombie` in the unloading square. Pure Lua also cannot complete detached MP network admission because `ServerMap`/`NetworkZombiePacker` are not exposed.

Latest native server logging showed the same logical NPC IDs materialize again far from their earlier shell positions with new carrier IDs. The logical Presence transition therefore occurred, while the former physical zombie carrier survived. That pattern is consistent with the shell being owned by a native zombie-population lifecycle outside the PNC Registry/BodyLifecycle model.

### Architectural conclusion

The previous migration correctly separated:

    durable npcId/bodyLease
        from
    client onlineId replica identity

but failed to separate:

    PNC live-human physical carrier
        from
    native ZombiePopulationManager ownership

The engine-supported target is therefore preventive rather than a new carrier class: keep the proven vanilla real/network shell, but guarantee that Presence proactively removes it while it is still attached and safely inside player-loaded space, before PZ can invoke native `n_addZombie` virtualization. Binding/reconciliation remains necessary and is preserved above this layer.

### Explicit non-solution

Do not respond by widening HuskReaper identity heuristics. Position, outfit, gender, companion ownership and stale online IDs remain insufficient identity evidence and risk deleting ordinary zombies. M9 must prevent normal carriers from reaching native virtualization; the reaper remains bounded fallback/legacy cleanup for shells already lost before the preventive fence.

### A-Life comparison correction

A-Life's `ShellSimulation.retire()` is useful for explicit MP client replica cleanup, but its server cleanup still ultimately calls `removeFromWorld()/removeFromSquare()`. It is therefore not proof of permanent PopMan detachment and must not be copied as the SP/native-population fix.


## M10 restart-shell failure audit

The 2026-10-30 09:44/09:46 native restart log disproved the remaining M9 assumption that runtime pre-virtualization retirement alone was sufficient. Startup saw anonymous restored live `IsoZombie` carriers, reported `ordinaryUnknown` plus blocked records, removed zero shells, and later materialized replacement NPC bodies.

Repository history isolated the direct regression to `df315d65`, which hard-disabled the anonymous current-save rehydration function. The safe repair is not broad positional cleanup. M10 splits proof into three lanes:

- exact identity: UUID/engine identity or the new lifecycle-only live-shell token;
- bounded current-save adoption: saved live lease, prior nonzero engine identity, tight position, sex when available, real-frame settle, and one-to-one ownership;
- ambiguity: fail closed, preserve bodies, block replacement materialization.

Anonymous evidence is adoption-only and can never authorize duplicate deletion. True Knox-reanimated zombies remain outside this restart-reclaim path.

Installed Build 42.22 server evidence also shows dedicated saves call `ZombiePopulationManager.updateRealZombies()` immediately before native population save, while Lua exposes no safe server-authority detach/re-admit seam that preserves PopMan and `ServerMap` identity. Therefore:
- local/SP uses canonical pre-save carrier retirement before PNC persistence;
- dedicated/MP uses startup reclaim as the supported restart contract;
- runtime distance fencing remains the normal anti-virtualization guard during play.

Developer validation for the M10 implementation in `ada48d24`: 972/972 full tests, 231/231 broad lifecycle tests, 163/163 focused restart/persistence tests, 14/14 installed-PZ compiler passes, 14/14 static Kahlua-error clean.

Native acceptance remains mandatory. Success requires a `PNC startup_rehydrate_rebound` line before any replacement `spawnPrimary` for the same NPC, with no hostile old live shell remaining.


## 15. M11 dedicated late-stream and replica audit

The 11:56 dedicated-server session explains the SP/MP split. At 11:58:09, with no player-interest chunks loaded, startup converted all eight unresolved saved-live claims into misses and immediately completed reconciliation. This is invalid on a dedicated server: absence from the currently loaded cell is not evidence that the PopMan shell does not exist.

The correct ownership boundary is per record:
- global server startup may complete;
- each unresolved saved-live record keeps a late-stream claim;
- the claim begins its timer only when the saved square becomes loaded;
- replacement materialization is blocked during that bounded loaded-square settle;
- a streamed candidate is quarantined and rebound when uniquely proven;
- ambiguity never authorizes deletion or replacement spawning.

The debug-spawn symptom exposed a separate authority bug: client debug dispatch used `Core.IsClientOnly()`, allowing hosted/listen configurations to fall into local execution instead of `sendClientCommand`. Multiplayer debug mutations now key from Build 42's actual `isClient()` transport role.

The invisible-dialogue symptom also exposed an MP binding consistency gap. Previous snapshots could combine a current body `onlineId` inside `bodyBinding` with a stale cached `liveBodyOnlineID`. Pure clients correctly rejected that inconsistent tuple. M11 builds all binding fields from one projection and adds a narrowly scoped exact-ID recovery when bind arrives before `OnZombieUpdate` observation. A WorldCensus miss no longer suppresses the exact engine-list fallback.

No generic recurring zombie scan was reintroduced.


## 16. M12 post-M11 hosted-MP audit

The post-M11 screenshot is not a body-binding failure: the client console shows successful `mp_body_binding_bound` transitions for the visible NPCs. The defect is downstream presentation ownership.

`PNC_Visuals.ApplyHumanVisuals` previously used a generic networked-runtime predicate. On a multiplayer server that predicate is true, so the authoritative carrier took the client replica path and skipped full resolved survivor appearance. Because the client correctly does not own server clothing, a bound vanilla IsoZombie carrier could retain/reacquire zombie HumanVisual state. M12 changes the branch to `Core.IsAuthority()` and adds a throttled identity-only replica integrity repair.

The restart failure is a different persistence boundary. During clean hosted shutdown, a live NPC may detach before global save. The old detach helper stored carrier ids/lease/position but omitted the semantic fact that the body had been live. Serialization then saw an abstract record and persisted `wasLive=false`. The next startup therefore skipped M11 for exactly those records. M12 moves this fact into a dedicated detached-hint policy and provides a strong-identity-only migration for saves already written by the bug.

The user's referenced hosted session was a reused world (`isNewGame=false`), not a newly initialized PZ world. This distinction is recorded so population persistence and starting-companion creation are not conflated.
