# Architecture — Multiplayer Body Binding Migration

## 1. Parent architecture

The permanent actor is the PNC NPC record. A live IsoZombie is a disposable physical carrier.

                        PNC NPC RECORD
                 authoritative gameplay identity
                        /          \
                       /            \
                     SP              MP SERVER
                     |                  |
              local body shell     server body shell
                     |             onlineId + incarnation
                     |                  |
                     |          vanilla zombie replication
                     |                  |
                     |                  v
                     |          MP CLIENT REPLICA
                     |                  |
                     |        PNC binding reconciliation
                     |                  |
                     +----------> presentation view

No gameplay system may treat a client replica as the durable NPC.

## 2. Authority ownership

### Registry / domain authorities own
- durable NPC ID;
- alive/dead state;
- health/wounds/infection;
- faction/relationship;
- tasks/orders;
- inventory/equipment authority;
- combat outcomes;
- persistent world position while abstract;
- character ownership.

### Presence owns
- whether the authoritative NPC should currently have a live physical shell;
- live/abstract transitions;
- materialization/dematerialization policy.

### BodyLifecycle owns
- server/local physical shell creation/removal;
- body incarnation/lease assignment;
- corpse/reanimation transition;
- legacy shell cleanup;
- body-level diagnostics.

### MultiplayerBodyBinding owns
- mapping one current PNC live-body incarnation to one vanilla zombie onlineId;
- binding publication to interested clients;
- client pending/reconciliation state;
- stale-incarnation rejection;
- exact replacement/unbind/removal notices;
- diagnostics for message-first, replica-first and rebind cases.

It does not own NPC gameplay state, movement decisions, combat, routine persistence, or presentation content.

### ClientPresenceSync owns
- projection of the authoritative record to the already-bound client replica;
- visual/animation/equipment presentation;
- local replica lookup supplied by MultiplayerBodyBinding.

It must no longer infer durable identity solely from replicated ModData.

## 3. Identity model

Required identity layers:

    npcId
        durable logical actor

    bodyIncarnation
        one physical live-body lifetime
        preferably reuse existing bodyLease if proven sufficient

    onlineId
        Project Zomboid transport identity for one network zombie replica

Canonical MP relation:

    npcId + bodyIncarnation <-> onlineId

Rules:
- npcId alone does not identify a current shell.
- onlineId alone does not identify a durable NPC.
- a stale incarnation may never reclaim a newer shell.
- reuse of an online ID by PZ must not transfer old PNC identity.
- client ModData is a cache/presentation marker after binding, not authority.

## 4. Binding protocol

Conceptual server message:

    protocol = 1
    npcId = ...
    bodyIncarnation = ...
    onlineId = 123
    operation = bind | unbind | remove

The exact transport should reuse existing bounded PNC network snapshot/roster infrastructure when that preserves ordering, budgets and interest filtering.

Do not introduce a second unrestricted broadcast transport when an existing channel can own the data.

### Message-first

    binding arrives
    onlineId not present locally
        -> store bounded pending binding
        -> observe future zombie replicas
        -> exact onlineId appears
        -> validate incarnation is still current
        -> bind/stamp/present

### Replica-first

    vanilla zombie replica appears
    no trusted PNC identity yet
        -> observe/index exact onlineId only
        -> do not invent NPC identity
    binding arrives
        -> exact onlineId match
        -> validate
        -> bind/stamp/present

### Rebind

    npcId incarnation A -> onlineId 10
    new incarnation B -> onlineId 22
        -> B becomes canonical
        -> A cannot reclaim B
        -> stale A presentation/cache removed

## 5. Pending state bounds

Client pending state must be:
- transient;
- bounded in count;
- TTL-bound;
- keyed by explicit identity/online ID;
- weakly referencing Java objects where useful;
- safe when messages are duplicated or reordered;
- swept without full-registry/per-frame expensive scanning.

Use event-driven observation first. A bounded periodic reconciliation sweep is acceptable if required by PZ event limitations, but it must have explicit cadence and cap.

No persistent ModData root may be introduced for routine client binding state.

## 6. Presentation admission

A client replica must not be treated as a PNC human actor until a valid binding is established.

After binding:
- stamp local PNC identity markers for existing client-side consumers;
- apply existing ClientPresenceVisuals;
- suppress native zombie behavior/voice only through the established client managed-body lane;
- keep presentation idempotent.

Before binding:
- do not classify arbitrary zombies as PNC by proximity, outfit alone or position alone;
- investigate whether any vanilla-replicated field can safely provide an early candidate hint to reduce a one-frame zombie precursor, but such a hint must never become durable identity by itself.

The migration must not claim zero visual precursor until a native MP test proves it.

## 7. SP/MP provider boundary

Shared business logic may remain common, but identity mechanics must branch at a narrow provider seam.

    BodyIdentityProvider
        |
        +-- LocalBodyIdentity
        |      direct body lease / object identity
        |
        +-- MultiplayerBodyBinding
               explicit onlineId reconciliation

Forbidden:
- adding MP packet-order workarounds to the generic body constructor;
- making SP wait for MP binding;
- making client replica caches authoritative for server lifecycle;
- scattering new SP/MP identity decisions through unrelated gameplay modules.

## 8. Server shell lifetime

Server-side `IsoZombie` remains the physical network carrier. M9 no longer requires an unsupported detached-network-shell provider; installed 42.22 evidence instead establishes a hard ownership boundary around **virtualization**. A managed live-human shell may use vanilla real-zombie/network registration while loaded, but PNC must retire it before Project Zomboid can hand it to the native virtual population.

The server must:
- create/configure one body incarnation through the existing proven body factory;
- keep every managed live-human shell inside the hard player-owned loaded envelope;
- retire an attached shell before chunk unload/out-of-loaded-area virtualization can issue native `n_addZombie`;
- obtain/refresh its valid online ID;
- publish the current binding;
- invalidate that binding before/when the body is replaced;
- never consider absence from one stream-scoped census sufficient evidence that an attached lease-matched shell is gone;
- let Presence/BodyLifecycle decide true shell loss.

## 8A. Native virtualization boundary (M9)

Installed 42.22 engine and native-library inspection distinguishes three operations:

    create/real admission
        -> ZombiePopulationManager.registerZombie
        -> native n_registerZombie

    engine virtualization
        -> ZombiePopulationManager.virtualizeZombie
        -> or removeChunkFromWorld
        -> native n_addZombie
        -> removeFromWorld/removeFromSquare

    proactive PNC retirement
        -> IsoZombie.removeFromWorld
        -> ZombiePopulationManager.releaseZombie
        -> native n_releaseZombie

The husk-producing path is the middle one: once `n_addZombie` has serialized the carrier into native population state, PNC has already lost reliable Lua identity continuity. Native SP/MP evidence showed this happening to companions retained physically far beyond all players.

A `persistentId == 0` shell was investigated but rejected as the production solution:
- chunk unload still virtualizes any `IsoZombie` found in the unloading square;
- the MP server APIs needed to assign/insert a manually built shell into `ServerMap.zombieMap` are not Lua-exposed;
- adding a javaagent/launcher dependency would be a larger unsupported deployment change.

Target invariant:

    live PNC human:
        durable actor = Registry record
        physical carrier = loaded IsoZombie
        PNC incarnation = runtime.bodyLease
        MP transport identity = onlineId
        must remain inside PNC live-body safety envelope
        must be proactively removed while still attached
        must never reach native n_addZombie virtualization

    true Knox-reanimated NPC:
        human lifecycle ended
        genuine vanilla zombie
        normal native population virtualization allowed

Presence therefore owns a hard carrier-safety envelope above ordinary gameplay requests. `forceLive`, combat targets and follow state are not allowed to bypass it. A bounded live-registry sweep plus the per-record pre-behavior fence provide cadence-independent retirement. MP client deletion remains exact `(npcId, incarnation, onlineId)` admission.

## 9. Client replica lifetime

A client replica is disposable.

Loss of the client object:
- does not kill or abstract the NPC;
- clears only local binding/presentation caches;
- waits for the vanilla replica and/or authoritative binding to reappear.

A reconnecting/new client reconstructs all live NPC bindings from authoritative server state.

## 10. Death, corpse and Knox reanimation

The migration must preserve existing physical semantics:

    live NPC incarnation
       -> authoritative death
       -> corpse/death body lifecycle
       -> optional Knox reanimation
       -> true zombie when appropriate

A dead/reanimated NPC must not be rebound as a live human presentation because an old online ID or stale packet survives.

Death/reanimation invalidates the live-body incarnation.

## 11. Husk cleanup after migration

After M9, normal current-session lifecycle must be preventive: attached managed shells retire before native virtualization. Husk cleanup becomes fallback/legacy recovery for shells that were already lost or virtualized before the preventive fence could act.

Husk cleanup hierarchy:
1. exact current binding / exact stale incarnation evidence;
2. durable legacy body identity where still valid;
3. persisted startup migration evidence;
4. tightly bounded legacy positional fallback only where unavoidable.

Never:
- delete ordinary zombies because they are close to an NPC;
- use persistent outfit ID as unique actor identity;
- let one client decide server body authority.

## 12. Project A-Life reference boundary

Allowed:
- compare invariants;
- compare race handling;
- independently reproduce pending-by-online-ID, generation guarding and watchdog concepts;
- use it as feasibility evidence.

Forbidden:
- editing Workshop files;
- introducing a runtime dependency on A-Life;
- copying source verbatim;
- matching its module structure merely for similarity.

Project Hoomans' Registry, Presence, BodyLifecycle, NetworkSnapshots and ClientPresenceSync remain the owning architecture.

## Implemented lease issuance contract (M1)

`runtime.bodyLease` remains the sole physical incarnation token. On an MP
server, BodyLifecycle keeps weak, process-local shell receipts. The first
stamp of a physical shell allocates a lease even if a restored save or optional
Core provider supplied an old lease. Repeated stamps of the same shell keep
the receipt lease. Clearing the runtime lease releases it; stamping a recycled
object then allocates a new lease. A process-local serial suffix prevents
same-clock/random collisions during issuance. Receipts are not persisted.

SP retains pre-5dbbadc4 allocation/restoration behavior. Core provider leases
remain provider ownership contracts; their identity does not establish an MP
physical shell incarnation.

Opaque lease strings must never be lexically ordered. Network reconciliation
must pair lease equality with the existing replicaSequence/presenceRevision
ordering and a server-session boundary. This ordering is transport freshness,
not a parallel physical generation authority. Death invalidation, ordering and
reconnect integration remain mandatory in later phases.

## Binding transport freshness and client bounds

Each authoritative descriptor publication receives a strictly increasing
revision within one server session, including unchanged relations. This lets
clients expire old proof and safely accept a later server reaffirmation without
changing body incarnation or rebuilding presentation. Duplicate delivery of the
same revision does not extend its TTL. Lease equality identifies the shell;
revision only orders messages.

The client reconciler is constructed by `MultiplayerBodyBinding.NewClient`.
Its default bounds are 512 actor entries, 512 weak observed replica references,
and 10 seconds TTL. The integration must sweep at a bounded cadence and reset
on connection lifecycle. Expired entries advance a scalar retirement watermark,
so evicting a tombstone cannot let an older packet reclaim a recycled online ID.
A fresh authoritative publication can recover from expiration. ID reuse on a
different local object requires fresh proof after the previous observation.

This reconciler never mutates Registry or deletes an engine object. Admission,
cache stamping/clearing and local body validity are supplied by the client
presence integration, which must remain the only runtime consumer adapter.

## Exact removal admission

`remove` descriptors carry the same session/revision/npcId/incarnation/onlineId
proof as bindings. A removal for an old incarnation cannot retire a different
current incarnation, even if the removal publication itself is newer. Physical
client deletion requires a currently bound, still-valid exact tuple. An
unobserved/expired/anonymous shell is never deleted using online ID alone.
Server removal routing stays within existing NPC interest sets. Legacy startup
and husk hints may still inform server save-migration cleanup, but cannot create
client identity or authorize anonymous replica deletion.
