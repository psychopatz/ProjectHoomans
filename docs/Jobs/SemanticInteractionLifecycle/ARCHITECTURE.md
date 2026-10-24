# Architecture — Semantic Interaction Lifecycle

## 1. Target pipeline

The target is one semantic interaction pipeline with multiple input adapters.

~~~text
Typed / headless text -> NLU --------------------------+
                                                        |
Semantic button ---------------------------------------|
                                                        v
Emote / gesture ------------------------------> Semantic Interaction Act
                                                        ^
Conversation open/close lifecycle ---------------------|
                                                        |
Grounded game event -----------------------------------+
                                                        |
                                                        v
                                              Interaction Lifecycle
                                                        |
                                             resolve thread / active beat
                                                        |
                                        ActorConversationContext + world facts
                                                        |
                                              Response Plan / Flow
                                                        |
                                               Speech Realization
                                                        |
                                                Presentation / TTS
                                                        |
                                         optional contextual reply offers
~~~

Known game actions/events do not run through NLU. Only freeform language needs parsing.

## 2. Semantic interaction envelope

Introduce or adapt one bounded production contract that can represent the meaning of an interaction regardless of input surface.

Conceptual shape:

~~~lua
{
    schemaVersion = 1,

    source = "typed_text" | "semantic_choice" | "emote"
        | "conversation_lifecycle" | "world_event",

    actorID = "...",
    targetID = "...",
    playerUUID = "...",

    act = "GREET" | "FAREWELL" | "THANK" | "REACT" | "...",
    topic = "...",
    gesture = "...",
    eventType = "...",

    factRefs = {...},
    modifiers = {...},

    worldHour = 0,
}
~~~

This is a semantic envelope, not a gameplay authority token.

Authoritative domains still decide whether an inventory action, relationship effect, task, trade, quest change or other gameplay mutation is allowed.

## 3. NPC speech keeps semantic provenance

NPC output must not later be reparsed to determine what the NPC meant.

The selected response already knows:

- semantic act;
- topic;
- source pool/flow;
- response plan;
- grounded fact refs;
- active beat;
- expected reply avenues.

The presentation layer may render localized prose, but the lifecycle records only the compact semantic provenance needed for continuity.

This allows a player reply such as “yes”, a thumbs-up emote, a semantic button or headless typed input to resolve against the same current beat.

## 4. Conversation threads

A thread is compact conversational continuity for one relevant participant pair.

Conceptual thread state:

~~~lua
{
    id = "...",
    playerUUID = "...",
    npcID = "...",

    status = "ACTIVE" | "SUSPENDED" | "ARCHIVED",

    topic = "...",
    topicStack = {...},

    activeBeat = "...",
    openQuestions = {...},
    openCommitments = {...},

    recentTurns = {...},

    residue = {...},

    startedHour = 0,
    lastHour = 0,
    expiresHour = 0,

    revision = 0,
}
~~~

Rendered transcript text is not authoritative thread state.

## 5. Beat lifecycle

A beat is a small semantic interaction unit such as:

- greeting/check-in;
- disagreement about a plan;
- reaction to dangerous combat;
- apology/repair;
- request/answer;
- promise/commitment;
- reveal/knowledge disclosure;
- farewell.

A beat may:

- continue;
- resolve;
- escalate;
- open a follow-up;
- suspend when another topic interrupts;
- resume later;
- expire;
- promote a durable memory/commitment/fact.

The existing flow suspend/resume concepts should be reused rather than replaced by a second state machine where practical.

## 6. Interaction states

~~~text
DORMANT
  -> ACTIVE
  -> SUSPENDED
  -> ACTIVE
  -> ARCHIVED

ACTIVE may also resolve directly to DORMANT when no durable state remains.
~~~

Closing the UI is not equivalent to deleting semantic context.

A short close/retarget/interruption may suspend the thread. A trivial completed interaction may leave no pair state at all.

## 7. Storage temperatures

### Hot — active runtime

Rich state exists only for currently relevant actors:

- recent semantic turns;
- active beat;
- response opportunities;
- context cache;
- realization anti-repeat state;
- diagnostics when enabled.

Hot state is not globally instantiated for every NPC.

### Warm — compact pair capsule

Persist only when needed:

- unresolved topic/beat;
- open commitment;
- meaningful emotional residue;
- small memory/event references;
- last interaction/expiry timestamps.

No full rendered transcript.

### Cold — authoritative shared truth

Use existing owners for:

- relationship scores/bond;
- Knowledge/disclosures;
- quests/commitments when they have a dedicated owner;
- faction/world events;
- identity/personality;
- inventory/tasks/health/etc.

Conversation references this state; it does not duplicate it.

## 8. Memory promotion

Every semantic turn is transient by default.

Possible outcomes:

~~~text
TRIVIAL
  -> discard after active context compaction

SHORT-LIVED
  -> bounded residue / suspended-thread field

SIGNIFICANT EPISODE
  -> compact episodic memory/ref

STRUCTURAL FACT
  -> authoritative Knowledge/domain state

COMMITMENT
  -> authoritative or bounded open commitment
~~~

Promotion candidates include major promises, betrayal, rescue, major injury, important disclosure, relationship milestone, faction/world event, significant threat, quest commitment and comparable high-value events.

Ordinary hello/thanks/small talk does not become permanent memory by default.

## 9. Compaction

Active recent semantic turns have a hard bound.

When the bound is reached:

1. preserve unresolved/open state;
2. merge repeated equivalent acts where safe;
3. derive compact semantic summary fields;
4. retain only the newest bounded turns;
5. discard old rendered text and debug candidates.

A 200-turn conversation must remain bounded rather than growing linearly.

## 10. Sparse pair-state model

Do not pre-create Player × NPC state.

Conceptually:

~~~text
pair key = playerUUID + npcID

no meaningful history
    -> no pair record

meaningful unresolved/durable delta
    -> create/update compact pair record

record becomes empty after compaction/resolution
    -> delete pair record
~~~

Scaling follows meaningful relationships/interactions, not the theoretical pair count.

## 11. Shared world-event references

Grounded world/faction/gossip events should be canonical when a shared event owner exists.

Example:

~~~text
WorldEvent #1842
  FACTION_DESTROYED / Redwood / Day 42

Alice memory -> eventRef 1842 / witnessed
Bob memory   -> eventRef 1842 / heard_from Alice
~~~

Do not store the same prose/event payload independently on every NPC.

This job should integrate with the existing grounded gossip/world-knowledge work rather than create another event history.

## 12. Emotional residue

Residue is compact, directional and lazy.

Example conceptual state:

~~~lua
{
    concern = 72,
    irritation = 31,
    updatedHour = 442.5,
}
~~~

No per-tick decay loop.

When the pair becomes relevant again, derive current values from elapsed world time and update only if necessary.

Major relationship changes still belong to Relationships.

## 13. Lazy expiry and hydration

Suspended threads use timestamps such as expiresHour.

Do not schedule per-thread timers.

On access:

- compare current world hour;
- derive decay/expiry;
- compact/archive if needed;
- hydrate only the bounded state needed for the interaction.

Optional save/load maintenance may clean stale records in bounded batches but must not become the gameplay lifecycle.

## 14. Revisions and cache invalidation

Reuse revision-style context invalidation where available.

Slow-changing fragments such as identity/personality/speech style do not need rebuilding every turn when their owner revision has not changed.

Dynamic fragments such as active thread, current situation, health, needs or immediate event facts are projected when relevant.

## 15. Anti-repetition

Realization history is presentation state, not long-term autobiographical memory.

Keep a bounded recent-variant set per active/relevant realization family and strongly avoid immediate repeats.

Do not persist hundreds of exact prior sentences merely to avoid repetition.

## 16. Multiplayer authority

Server owns:

- durable pair capsules;
- semantic lifecycle commits;
- memory promotion;
- authoritative facts/commitments;
- gameplay mutations;
- shared event refs.

Clients receive only bounded projections relevant to the current interaction:

- rendered NPC/player speech;
- semantic response revision;
- allowed contextual choices;
- required presentation metadata.

Do not broadcast one player's private NPC relationship/knowledge/thread state to unrelated clients.

Preview remains pure. Accepted input commits once.

## 17. Multiple simultaneous players

A single NPC can have distinct sparse pair state with multiple players.

The NPC-global identity/personality/world memories are stored once.

Player-specific state is stored only when required:

- directed relationship already owned by Relationships;
- disclosures already owned by Knowledge;
- pair thread capsule only if meaningful;
- pair-specific residue/commitment refs only if meaningful.

Do not clone NPC-global memory into each pair record.

## 18. Conversation UI

The visible transcript is presentation-only and may be aggressively bounded.

Older visible rows may be discarded without losing semantic continuity.

The UI may show, for example, the latest 20–40 rows while the lifecycle retains only the compact unresolved meaning needed to continue later.

Reopening a conversation is not required to reconstruct every historical sentence.

## 19. ConversationBlocks boundary

ConversationBlocks retain:

- authored branch graph;
- gates;
- weighted outcomes;
- repeat policy;
- authoritative effects.

This job may later route block wording through common speech realization, but must not replace block authority with spontaneous semantic flavor.

## 20. Performance invariant

When nothing meaningful happens:

~~~text
zero semantic lifecycle work
~~~

No global tick loop over all NPCs for dialogue, memory decay, thread expiry or suggestion generation.

Work is triggered by:

- player input;
- semantic choice;
- emote;
- conversation lifecycle transition;
- meaningful grounded game event;
- bounded save/load maintenance.

