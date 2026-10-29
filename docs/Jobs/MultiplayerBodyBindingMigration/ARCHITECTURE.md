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

Server-side IsoZombie remains the physical network carrier unless a later proven phase demonstrates this is impossible.

The server must:
- create/configure one body incarnation;
- obtain/refresh its valid online ID;
- publish the current binding;
- invalidate that binding before/when the body is replaced;
- never consider absence from one stream-scoped census sufficient evidence that an attached lease-matched shell is gone;
- let Presence/BodyLifecycle decide true shell loss.

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
