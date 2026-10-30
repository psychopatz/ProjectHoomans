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
