# Persistence and Scaling Contract

## Objective

Support multiple players, hundreds of NPCs and multi-day conversational continuity without linear transcript growth or Player × NPC preallocation.

## 1. Sparse by default

A theoretical player/NPC pair has no conversation record.

Create pair state only when compaction produces a meaningful durable delta such as:

- unresolved thread/beat;
- open commitment;
- meaningful short-lived residue;
- compact significant memory/event refs not already owned elsewhere.

If the compacted record becomes empty, remove it.

## 2. Never persist ordinary rendered transcript

Rendered dialogue is presentation output.

Normal authoritative persistence must not contain full chat transcripts, parser candidate traces, response-candidate lists, button snapshots, localization traces or debug explanations.

Persist semantic meaning only when necessary.

## 3. Storage ownership

### NPC-global, stored once

- identity/personality/traits through existing owners;
- NPC-global important memory refs where the memory system requires them;
- world-event references/knowledge where authoritative owners support them.

### Pair-specific, sparse

- unresolved thread capsule;
- pair-specific short residue;
- open pair commitment refs;
- pair-specific episode refs only when not represented by another canonical domain.

### Existing domains, not Conversation

- approval/respect/familiarity/bond;
- Knowledge/disclosures;
- inventory;
- faction diplomacy;
- tasks/jobs;
- health;
- quest state;
- trade state.

## 4. Initial bounded budgets

These are initial engineering defaults to prove bounded behavior, not immutable game-balance values. P7/P8 stress evidence may tune them while preserving the same upper-bound contracts.

| State | Initial design bound |
| --- | ---: |
| visible client transcript rows | 30 |
| recent semantic turns per active thread | 12 |
| active/suspended beat stack | 4 |
| suspended unresolved threads per pair | 3 |
| open conversation commitments per pair | 8 |
| compact pair episode/event refs | 16 |
| significant NPC episodic refs | 32 |
| recent realization IDs per family | 8 |
| contextual reply candidates per revision | existing bounded suggestion contract; do not unbound it |

When a limit is reached, use semantic merge/compaction/promotion/eviction rules. Never silently grow the collection.

## 5. Compaction order

When recent-turn budget is reached:

1. keep current active beat and unresolved slots;
2. keep newest turns needed to resolve current references;
3. merge repeated equivalent low-value semantic acts where safe;
4. promote structural facts/commitments to their authoritative owner;
5. promote high-value episodes/event refs if eligible;
6. discard trivial resolved turns;
7. update thread revision.

Rendered strings are not required for compaction.

## 6. Lazy time

Store world-hour timestamps.

Do not tick every pair/NPC to:

- decay emotion;
- expire threads;
- age memories;
- clear response windows.

Derive elapsed time when state is accessed.

A bounded maintenance sweep during save/load is allowed only as cleanup and must not become required gameplay simulation.

## 7. Shared event dedupe

Prefer one canonical world/gossip event record plus compact references.

Do not duplicate a large event payload per witness/per player.

If an existing grounded world-knowledge/gossip service already owns the event, use its stable reference rather than create a second journal.

## 8. Repeated-pattern aggregation

Repeated low-level events should collapse into an impression/aggregate where an existing owner or accepted semantic memory contract supports it.

Examples:

- hundreds of routine zombie kills should not become hundreds of permanent episodes;
- repeated minor insults may become a bounded repeated-disrespect aggregate plus at most a few major episodes;
- frequent generic greetings should not be remembered.

## 9. Network bounds

Server sends only the current interaction projection needed by the relevant client.

Do not replicate:

- full NPC memory;
- unrelated player-pair state;
- private Knowledge;
- historical parser/debug traces;
- every dormant suspended thread.

Debug payloads are opt-in and bounded.

## 10. Working-memory bounds

Only active/recently relevant interactions hydrate rich runtime structures.

Dormant NPCs retain compact state only.

Context building is on-demand and revision-aware.

No “all NPC conversation context cache” is allowed.

## 11. Persistence diagnostics

Semantic Lab must expose at least:

- number of materialized pair records;
- active/suspended/archived thread counts;
- recent-turn counts vs limits;
- commitment/memory/event-ref counts vs limits;
- trivial turns discarded;
- compaction count;
- promotion count;
- pair records deleted after becoming empty;
- approximate serialized size where practical;
- hydration/compaction timing;
- network projection size where practical.

These are diagnostics, not new gameplay state.

## 12. Required scaling acceptance

The developer acceptance suite must demonstrate:

1. hundreds of NPC identities do not create conversation pair records by themselves;
2. multiple players do not allocate the full cross-product;
3. thousands of trivial exchanges do not produce unbounded ModData;
4. a 200-turn active conversation remains within turn/thread bounds;
5. multi-day suspended context resumes appropriately after compaction;
6. unrelated players do not receive another player's private pair context;
7. shared event knowledge uses references rather than repeated large payloads;
8. dormant NPCs incur no semantic per-tick work;
9. save-backed source remains immutable in the Semantic Lab isolated runtime.

