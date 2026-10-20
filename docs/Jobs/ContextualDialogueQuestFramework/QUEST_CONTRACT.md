# Quests — proposed authoritative domain contract

**Status:** Design target, not a claim of existing implementation. An initial repository search found quest-giver labels/markers but not enough evidence for an owned quest journal/registration/objective/reward lifecycle. The first Quest-phase chunk must audit existing game state and adapters to avoid duplication.

## Domain ownership and stable identities

A quest definition has namespaced immutable ID, schema version, owner mod, giver/actor eligibility, visibility and prerequisites, repeat policy, allowed instance scope, objective descriptors, transitions, translated response/catalog keys and reward/penalty descriptors. Content should be data-only and version-agnostic under common/media when practical; the B42.20 server application/engine/event adapter stays under versioned media/lua.

A quest instance has compact identity (world/save, quest ID, scope owner ID, optional giver NPC ID), state, revision, objective progress identifiers, acceptedAt, optional expiry and rewardClaimed/dedupe evidence. Avoid embedding full NPC, inventory, transcript or native Java objects in ModData. Save/migration behavior and missing/deleted mod definitions must be explicit.

## Minimum state machine

LOCKED is computed eligibility, not necessarily an allocated persistent instance.
AVAILABLE is a query result.
OFFERED may be bounded temporary dialogue state.
ACCEPTED/ACTIVE is persisted when server admits the quest.
READY_TO_TURN_IN follows validated objectives.
COMPLETED means completion committed.
REWARDED means reward transaction committed exactly once.
FAILED, EXPIRED, ABANDONED are terminal or explicitly policy-defined retryable.
Changing NPC dialogue or resetting a worker must NOT transition quest state by itself.

Transition table, minimum:

- AVAILABLE -> OFFERED: dialogue-only, no reward/inventory mutation.
- OFFERED -> ACTIVE: authoritative AcceptQuest with revalidated gates, identity and scope.
- ACTIVE -> READY_TO_TURN_IN: objective evidence verified, no client-side claims.
- READY_TO_TURN_IN -> COMPLETED -> REWARDED: server commit with atomic/compensating transaction design and idempotent award record.
- ACTIVE -> FAILED/EXPIRED/ABANDONED: documented policy and authoritative transition; no silent data loss.
- REWARDED + repeated completion packet: no second grant, stable prior result.

## Core commands, queries, events (target shapes)

Commands: OfferQuest (where server needs an offer lease), AcceptQuest, AbandonQuest, SubmitTurnIn, ApplyObjectiveEvent, CompleteQuest. Each validates session/ownership/permissions and returns a reasoned bounded result. Server may collapse internal steps safely while preserving idempotency.

Queries: GetAvailableFor(npcId, characterUUID), GetInstance(scope, questId), GetDialogueStatus, GetObjectiveSummary, CanAccept/CanTurnIn, GetRevision. Client display reads snapshots; no direct writes.

Events: QuestAccepted, ObjectiveProgressed, QuestReady, QuestCompleted, QuestRewarded, QuestFailed. These are facts after authoritative commits, not requests disguised as events.

Objective providers must subscribe to **verified owned events** (e.g. Inventory.ItemTransferred to specific authorized NPC/stockpile), not a free-text NLP claim "I found the medicine." If a delivery uses real PZ items, consume/remit those items through the established inventory transaction/reservation domain to prevent double-credit. Keep event callbacks indexed and bounded by active quests.

## Quest ↔ dialogue wiring

"Can you help me?" => semantic intent + contextual eligibility check => truthful offer/locked explanation.
"Yes, I'll do it" => pending offer with matching player, giver, quest, current revision => authoritative AcceptQuest => response from result.
"Have I finished?" => Quest query => actual progress answer.
"I've got the medicine" => may start validated inventory handoff or turn-in request but never commits solely from the utterance.
"Do you remember our agreement?" => retrieve matching quest/commitment by participant, not fictional dialogue memory.
NPC personality affects willing/reluctant dialogue, possible authored willingness gate/weight, not server truth or forced quest status.

## SP/MP, integrity and restarts

Server owns quest state for both SP and MP; client can preview/offline-test with mock authority results but must never claim real MP success. Scope must prevent two players or two nearby NPCs from swapping commitments. Use request IDs/revisions/committed reward IDs to make retry and reconnect safe. On reload, compare installed definition version, repair/migrate supported compact records and quarantine unsupported states with a clear diagnostic rather than improvising rewards.

## First realistic representative quest

**Clinic Supplies**: NPC is missing bandages, becomes eligible when known state/relationship/quest prerequisites pass; player accepts through NLP or menu; player retrieves and transfers required bandage items using the authoritative inventory system; Quest domain tracks validated delivery; NPC acknowledges progress and grants one authored reward after turn-in. This is a vertical test fixture and optional initial game content, not evidence that arbitrary quest generation is supported.

No massive procedural quest generator, generic scripting VM, economy implementation, new inventory system, GUI quest journal, or PBrainZ dependency in the first quest slice.
