# Harness Acceptance — Multiplayer Body Binding Migration

## Purpose

This matrix proves identity, ordering, lifecycle and regression contracts without pretending a Lua harness can fully reproduce Project Zomboid's native network runtime.

Native SP/MP remains the final user acceptance layer.

## 1. SP baseline

Required:
- local body materialization produces one managed body;
- local body carries expected PNC UUID/lease;
- abstraction releases the body once;
- rematerialization creates one new valid incarnation;
- restart rehydrates without an extra husk;
- body factory does not require MP client-binding state;
- SP local snapshot path is unchanged by the MP protocol.

## 2. Incarnation invariants

Required:
- one live body incarnation has one stable token;
- replacement creates a different token;
- old token cannot bind a new body;
- death invalidates live incarnation;
- reload preserves only intentionally persistent semantics;
- no two live canonical bodies share the same (npcId, incarnation).

## 3. Server binding

Required:
- valid body + valid onlineId -> bind;
- no/invalid onlineId -> no published bind;
- duplicate same bind -> idempotent;
- new incarnation -> prior binding invalidated;
- same NPC new onlineId -> old binding stale;
- roster/interest join returns current binding;
- reconnect reconstructs binding without materializing duplicate body;
- body removal publishes exact unbind/remove.

## 4. Client ordering matrix

Binding first:

    bind(npcA, gen2, online=50)
    replica 50 appears later
    => bind succeeds exactly once

Replica first:

    replica 50 appears
    bind(npcA, gen2, online=50) later
    => bind succeeds exactly once

Duplicate:
- repeated identical bind messages do not restamp/rebuild expensive presentation.

Stale incarnation:

    npcA gen3 -> online 60 current
    late npcA gen2 -> online 50
    => gen2 rejected

Online-ID reuse:

    old npcA gen2 used online 50
    old replica disappears
    PZ later exposes online 50 for unrelated zombie/new shell
    => old binding cannot transfer

Identity conflict:
- one live replica may not be claimed simultaneously by two NPC identities/incarnations.

TTL:
- pending message with no matching replica expires and cannot claim a much later unrelated object.

## 5. Client presentation

Required:
- before authoritative binding, ordinary zombie is not classified as a PNC NPC;
- after binding, local identity stamp is present for compatibility consumers;
- visual/equipment/animation apply to current bound replica only;
- stale replica does not receive new-incarnation presentation;
- losing client replica clears local cache without mutating server NPC state;
- reappearing replica can bind again.

## 6. Multi-client matrix

At least synthetic clients A/B/C:
- A receives message-first;
- B receives replica-first;
- C enters interest later;
- all converge on same npcId + incarnation;
- one client's replica loss does not unbind other clients or server;
- server replacement publishes new incarnation to all interested clients;
- stale client data cannot revive old incarnation.

## 7. Presence/rematerialization

Required:
- canonical attached server body missing from one stream-scoped census is retained;
- genuine detached body can enter normal loss lane;
- abstraction -> rematerialization changes incarnation;
- client stale old incarnation is removed/unbound;
- no positional ordinary-zombie deletion;
- late-stream legacy startup shell handling remains bounded.

## 8. NPC role matrix

The same protocol must cover:
- companion;
- neutral;
- hostile/raider;
- recruited/unrecruited;
- faction-owned where applicable.

No role-specific binding algorithm.

## 9. Combat and movement

Required:
- server combat target remains logical/canonical NPC;
- player hit resolves to current bound server incarnation;
- companion follow/pathing never creates a second logical NPC;
- body replacement cannot leave movement control attached to stale incarnation;
- isRemoteZombie / vanilla simulation-owner change does not change PNC logical owner.

## 10. Death and reanimation

Required:
- ordinary death invalidates live binding;
- corpse is not presented as live NPC;
- infected NPC may reanimate according to existing rules;
- reanimated true zombie is not rebound by stale live packet;
- restart/reconnect preserve death outcome.

## 11. Performance/static guards

Assert:
- pending tables capped;
- TTL sweep bounded;
- no full zombie-list scan every frame;
- no Registry.ForEach per client frame for binding;
- no new ModData persistence root for client binding cache;
- no routine network broadcast to uninterested clients if existing interest routing can be used;
- protocol payload stays within existing network-budget expectations.

## 12. Reference comparison

Project A-Life may be cited as external architectural evidence, but Project Hoomans tests must not import or require A-Life.

The migration is accepted only if Project Hoomans works with A-Life absent.
