# Semantic Lab Acceptance — Interaction Lifecycle

The existing Semantic Lab and its production Lua worker are the primary development/debug surface for this job.

P14's rule remains mandatory:

> **Fixture the engine, never fixture the mod.**

Python may discover, transport, isolate, drive and present state. Production Lua must own Project Hoomans semantic lifecycle, compaction, persistence, memory promotion, context derivation and gameplay-facing decisions.

## Required observable inspectors

The harness must be able to show, where relevant:

- input source: typed/button/emote/lifecycle/event;
- canonical semantic act/frame;
- actor and target;
- active thread ID/status;
- active/suspended beat;
- current topic/topic stack;
- open question/commitment refs;
- recent semantic turns;
- compaction result;
- residue and lazy-decay provenance;
- promoted memory/fact/event refs;
- ActorConversationContext;
- selected response pool/plan/realization;
- recent-variant exclusion;
- contextual reply offers;
- actual production action/transport side effects;
- pair-state/persistence budget counters.

Do not persist these diagnostic traces into normal game ModData.

## Mandatory scenarios

### A. Multi-input contextual reply

NPC emits one semantically tagged line.

Respond separately through:

- typed Talk;
- a semantically equivalent choice button;
- an appropriate emote;
- headless text input.

Where the meanings are equivalent, the same active beat/semantic outcome should be selected without duplicate gameplay effects.

### B. UI transcript independence

Run more turns than the visible transcript limit.

Discard old displayed rows.

Verify the current thread/beat can still resolve a correct reply using compact semantic state, not hidden UI text.

### C. Interrupted topic

Start topic A, interrupt with topic B, resolve B, then resume A.

Verify bounded suspend/resume and no unrelated identity/relationship side effects.

### D. Multi-day resume

Start an unresolved meaningful topic.

Suspend/compact it.

Advance world time by hours/days using the existing harness world-time fixture.

Rehydrate/resume and verify context-sensitive continuation.

Trivial old turns must not be required.

### E. Forget trivial interaction

Run ordinary greeting/thanks/small talk with no meaningful delta.

After compaction, verify no unnecessary pair record remains.

### F. Promote significant interaction

Exercise a safe representative significant event/commitment/fact.

Verify the lifecycle promotes only the compact authoritative representation and can later reference it without restoring the old transcript.

### G. Long conversation bound

Run at least 200 semantic turns through the production worker.

Verify:

- recent-turn bound holds;
- compaction occurs;
- open state remains correct;
- serialized pair capsule remains bounded;
- no linear retained transcript/debug growth.

### H. Multiplayer sparse pair stress

Use production Lua state with a representative stress model equivalent to multiple players and hundreds of NPCs.

Minimum product question to answer:

> Do possible pairs remain absent until meaningful interaction, and does durable state scale with meaningful activity rather than Player × NPC?

Verify:

- no preallocation cross-product;
- independent pair context for simultaneous players;
- no private pair context leak;
- bounded pair counts after many trivial exchanges;
- empty pair-state garbage collection.

### I. Shared event dedupe

Create one canonical shared world/faction/gossip event known by several actors.

Verify memory/knowledge uses refs or the existing canonical event owner rather than duplicating large payload/prose.

### J. Dormant cost

Demonstrate that creating/loading hundreds of dormant NPCs does not start semantic per-tick lifecycle work.

Instrument event/hydration counts or equivalent bounded diagnostics.

## Performance/persistence evidence

Record at least:

- turn resolution time distribution for representative semantic interactions;
- hydration and compaction timing;
- materialized pair-record count;
- approximate serialized lifecycle size where practical;
- long-thread retained-state size before/after compaction;
- network projection size where practical;
- number of trivial turns discarded;
- number of promoted memories/facts;
- zero per-tick full-NPC semantic scans.

Do not optimize toward a fake Python benchmark that bypasses production Lua.

## Save-backed acceptance

Where real-save actor state matters:

- source save remains byte-for-byte immutable;
- isolated working world may mutate;
- production Lua owns record deserialization and semantic context;
- Reset restores the imported baseline;
- no Python reinterpretation of Project Hoomans ModData.

## GUI availability

A missing attached desktop is not a project blocker.

Use the existing worker/CLI/Xvfb routes for developer evidence when necessary, but do not claim unrun visual behavior.

Final native Project Zomboid SP/MP remains user-owned after all developer gates are complete.

