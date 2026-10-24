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



## 21. Native Conversation presentation parity

The Semantic Lab has two different responsibilities and must keep them separate.

### Player-facing Conversation mirror

The primary Conversation surface must consume a production-Lua presentation projection derived from the same Conversation definition/session path used by native Core.

It must not flatten the broader semantic candidate projection.

Canonical ownership:

~~~text
Conversation.BuildDefinition
    -> choicePresentation
    -> DialogueInput.Internal.PresentSemanticChoices
    -> buildCoreChoices
    -> Session:setPresentedChoices
    -> production presented rows
         |                    |
         v                    v
     native Core UI       Semantic Lab mirror
~~~

For the same production state, the two surfaces must agree on semantic row identity/frame, group/revision, ordering and enabled/disabled state.

### Debug sidecar

The Semantic Lab may separately expose:

- all safe candidates;
- groups/providers;
- hidden/eligibility diagnostics;
- response plans;
- lifecycle/thread/memory state;
- persistence/scaling metrics.

These diagnostics are not player-presented choices.

### No Python presentation policy

Python/Tk may render and transport the production presentation projection.

Python must not recreate:

- selected semantic group policy;
- Core choice eligibility;
- conversation busy/pending validity;
- stale/duplicate semantic frame authority;
- opening/lifecycle state;
- relationship presentation meaning.

### Load versus Open

Loading/rehydrating a saved NPC is state selection.

Opening a conversation is a lifecycle action.

The harness must not treat a generic capability/suggestion snapshot after import/configure as proof of the native opened Conversation state.

### Layout is not authority

The Semantic Lab may use a desktop-efficient layout rather than visually reproducing Project Zomboid's skin.

Behavioral parity is mandatory; pixel/theme parity is not.


## 22. Single conversational-intelligence authority

The semantic lifecycle is not complete if an old flavor module chooses the response and semantics merely records it afterward.

Forbidden:

~~~text
legacy role/tier/need/grief classifier
    -> legacy reply/flavor ID
    -> semantic envelope attached afterward
~~~

Required:

~~~text
authoritative facts
    -> semantic act/topic/active beat
    -> ActorConversationContext + semantic providers
    -> ResponsePlan / flow
    -> realization family + realization ID
    -> content/localization
    -> delivery/TTS/UI
~~~

Retained Flavor/SocialFlavor may store authored content, format exact tokens, choose meaning-equivalent wording inside an already-selected semantic realization, and deliver bounded speech. It may not infer relationship role/audience/need/grief to choose a response family, choose act/topic/plan/eligibility, or override thread/beat meaning.

Useful old pure classifiers may survive only after being moved/refactored into neutral semantic/context providers with explicit authoritative inputs.

Existing authored SocialFlavor/CompanionCommand/VanillaEmote/Combat/Medical/LeaderDeath lines are migration assets. Do not multiply semantic intents for every wording variant.

Compatibility modules may translate external facts and supply provider-specific authored wording, but must feed the common semantic realization authority rather than create another planner.


## 25. Semantic capability standardization

A semantic capability is the canonical conversational representation of an action that an existing authoritative owner can perform.

It is not a duplicate gameplay implementation.

Conceptual contract:

~~~lua
{
    capabilityID = "companion.camp",
    groupID = "companion_orders",
    act = "REQUEST",
    action = "CAMP",

    eligibility = {...},
    requiredSlots = {...},
    presentation = {...},

    executor = {
        owner = "PNC.CompanionCommands",
        commandID = "camp",
    },

    lifecycle = {
        close = false,
        next = "...",
    },
}
~~~

The exact implementation should reuse existing capability/adapter/choice contracts where possible.

### Capability source adapters

Existing authored/gameplay systems may expose semantic capability descriptors:

- Core/Conversation authored root choices;
- CompanionCommands registry;
- ConversationBlocks when representing an eligible authored action;
- recruitment/departure/trade/quest services;
- Camp/world-target providers.

They remain authoritative for effects.

### No recursive choice execution

A semantic presentation row for an authored choice must not execute the authored choice by recursively invoking `Session:selectChoice(original)` from a synthetic selected choice.

Instead the standardized capability/choice bridge must preserve or delegate the original action contract once.

The semantic layer may decorate a choice with provenance, grouping and alternate natural-language realizations, but it must not create a nested Core session transition.

## 26. Semantic realization standard

A semantic realization is selected only after meaning/action/context are known.

It may use:

- semantic act/topic;
- active beat/thread;
- response plan;
- persona;
- relationship;
- situation;
- language;
- bounded anti-repeat history.

It produces a realization family/ID plus localized content.

Authored legacy lines are content assets and may be migrated/addressed through this contract.

Resolved semantic speech then crosses one delivery boundary. Delivery must not reinterpret meaning.

## 27. Semantic address standard

Actor reference in speech is semantic realization, not raw identity transport.

Required layers:

~~~text
authoritative identity / disclosure state
        |
        v
address eligibility/context
        |
        +-- known name/title/role when allowed
        +-- unknown-address family
        |
        v
constrained address realization
~~~

Internal/debug placeholders such as `Unknown survivor` are not conversational address forms.

Unknown-address realization may consider authoritative/appropriate sex/gender information, familiarity, relationship, persona, tone, language and recent address-form history.

Seed English forms may include:

- stranger;
- mate;
- pal;
- bro — male + very casual style;
- mister — male + formal/neutral style;
- miss — female + formal/neutral style.

If sex/gender is unavailable or unsuitable, use gender-neutral forms.

Do not randomly alternate incompatible registers. Address selection uses semantic/style constraints and bounded repetition avoidance.

Do not invent names, titles or personal facts.

## 28. Companion Orders semantic navigation

Root Conversation should not permanently expose contradictory movement capabilities.

Use one semantic navigation hub:

~~~text
I need you to do something...
    -> Follow me OR Wait here
    -> Let's camp...
    -> Go home.
    -> Back
~~~

The Follow/Wait row derives from authoritative current movement/order state.

Destination-specific WAIT_AT remains a semantic capability for natural-language/world-target requests but is not a permanent generic menu row.

After a command mutates state, capability projection must refresh from authoritative truth.

## 29. Dynamic Camp capability projection

Camp destinations are dynamic semantic capability slots over existing production CampSite infrastructure.

Client may enumerate bounded valid-looking loaded rooms/campfires for presentation.

Each row carries a primitive stable target/hint, never retained Java engine objects.

Server independently re-resolves/revalidates the requested target before committing `CompanionCommands.camp`.

The capability list should:

- include only valid discovered sites;
- use semantic room labels;
- bound duplicate room types/results;
- provide generic safe-site fallback only when production resolution supports it;
- reject stale/invalid targets safely.

## 30. End-effect acceptance

For action capabilities, semantic acceptance is not `accepted=true`.

Required chain:

~~~text
presentation
-> semantic capability/frame
-> authoritative executor
-> real gameplay/lifecycle mutation
-> semantic acknowledgement realization
-> visible delivery
-> capability/session reprojection
~~~

Tests and Semantic Lab diagnostics must be able to distinguish each stage.
