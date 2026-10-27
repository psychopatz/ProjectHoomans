# Architecture — One Semantic Dialogue Authority

## Ownership model

### Gameplay/world domains own truth

Existing authoritative systems own:

- actor identity/knowledge/disclosure;
- Relationships/bonds;
- Faction/diplomacy/ownership;
- Health/medical state;
- Inventory/resources;
- Tasks/orders/capabilities;
- Quest/ConversationBlock gates/effects;
- world facts/events;
- compatibility-provider facts.

Semantics consumes bounded projections. It must not clone these stores.

### Semantic layer owns conversational meaning

The existing semantic architecture owns:

- semantic act/topic/event interpretation;
- active thread/beat interpretation;
- response pool/variant selection;
- response plan;
- grounded fact refs;
- dialogue continuation/follow-up affordances;
- speech style;
- semantic realization ID/family;
- privacy/disclosure eligibility.

### Dialogue Content owns equivalent wording

Meaning-equivalent phrase variation belongs in the canonical Dialogue Content / localization generation path.

Phrase selection happens only after semantic variant/style selection. It may not change actions, facts, plan, eligibility or authority.

### Presentation owns delivery only

SocialFlavor / SemanticSpeech presentation may own:

- queue/arbitration;
- TTL/cooldown/priority;
- transport dedupe;
- localization/token formatting;
- nameplate/world bubble;
- active Conversation UI insertion;
- TTS;
- compatibility handoff.

If swapping the presentation backend changes which semantic reaction is chosen, the migration is incomplete.

## Standardized event-to-speech path

```text
authoritative event/facts
    ↓
typed semantic event/context
    ↓
explicit semantic pool/flow
    ↓
ResponseCatalog.Select
    ↓
ResponsePlan + realization + fact refs
    ↓
Dialogue Content phrase/style realization
    ↓
SemanticSpeech delivery / presentation queue
```

Known events do not go through NLU. Freeform player text still does.

Each first-party event resolves semantic meaning **once**, before presentation. The queue must never rerun social stance/need/grief/relationship response selection.

## NPC-initiated follow-up path

Do not create a new event conversation database.

Reuse existing `SemanticInteractionLifecycle`:

1. The event producer owns/receives a canonical `eventRef` and fact refs.
2. Semantic response selection yields a response plan. The plan may contain bounded follow-up offers.
3. The selected NPC speech is recorded through `RecordNPCSpeech` with beat/topic/eventRef/factRefs/realization provenance.
4. The existing lifecycle keeps a bounded response window/beat for the relevant Player↔NPC interaction.
5. The existing Suggestions system projects eligible response-plan offers / contextual questions for that NPC when appropriate.
6. Clicking a suggestion enters the ordinary semantic-frame path.
7. Typed text enters the normal NLU path, then `SemanticContextResolver` resolves it against the active/pending contextual beat.
8. The answer reads the authoritative event/fact refs or revalidates volatile current-state facts.
9. On resolution/expiry/interruption, the existing lifecycle compacts/suspends/expires the beat.

### No transcript dependency

The follow-up anchor contains compact semantic state, e.g.:

```text
beat/topic
eventRef
factRefs
responsePlanID
realizationID
offer IDs
opened/expiry turn/time
```

It does not require preserving rendered text.

### Freshness

Historical facts and current-state facts are different:

- “You said there was a horde” may remain a historical event ref.
- “Where are they now?” may require re-observing current world truth.
- stale volatile offers should disappear or answer uncertainty rather than fabricate.

Use existing fact/knowledge providers and response-window expiry rather than a new freshness subsystem.

## Response-plan offers

Use the existing bounded `ResponsePlan.turns[].offers` / branch-offer concepts for event follow-up affordances.

Offers are semantic frames/capabilities, not strings with hidden logic.

Example:

```text
semantic.combat.reaction.horde
  topic: combat
  facts: event:horde:123, threat_band:high, direction:east
  offers:
    ASK_WHAT_HAPPENED
    ASK_WHERE_THREAT
    ASK_THREAT_SCALE
```

The player-visible label/utterance is content/localization; the semantic frame remains stable.

## Persistence and multiplayer

Default event follow-up context is transient/bounded lifecycle state.

- No new per-NPC ModData event transcript.
- No Player×NPC preallocation.
- Create pair/thread state only for an actual interaction/event listener when existing lifecycle policy requires it.
- Shared events remain deduplicated by canonical event ref.
- Private knowledge/follow-up context remains player-specific.
- Existing significance/compaction policy decides whether a meaningful event becomes durable memory; the follow-up mechanism itself does not force persistence.

## Compatibility boundary

PsychopatzCore may continue supporting generic SocialFlavor registrations for other adopters.

Project Hoomans first-party semantic-owned speech must always enqueue already-selected text/realization. Add diagnostics/guards so a PNC semantic-owned event cannot silently fall back to `ResolveDetailed()`.

Compatibility mods should adapt their authoritative event facts into Project Hoomans semantic context; provider gameplay truth remains external.

## Modularization standard

Prefer narrow reusable modules by responsibility:

- EventContextProvider — facts only;
- SemanticReactionProvider / pool registration — meaning only;
- ResponsePlan offers — follow-up affordances only;
- Dialogue Content — wording only;
- SemanticInteractionLifecycle — thread/beat/window only;
- Suggestions provider — player affordance projection only;
- SemanticSpeech delivery — delivery only.

Do not make a “UnifiedDialogueManager” god object.

## Failure behavior

If semantic selection fails:

- emit a bounded diagnostic;
- use an explicit semantic fallback variant if the pool defines one;
- do **not** fall through to a hidden first-party legacy prose selector.

Presentation failure may suppress/delay delivery according to existing queue policy but must not choose a different meaning.


## P10 steady-state repository architecture

The authority model must also be visible in file/schema structure.

### One first-party content registry

Project Hoomans steady state has exactly one first-party dialogue wording
registry: Dialogue Content.

There is no separate:

- SocialFlavor definition registry;
- ToolReply literal catalog;
- CompanionCommandFlavor wording registry;
- compatibility-mod PNC wording registry.

Player/NPC command/emote/greeting text is content like every other semantic
realization and must pass through the same content seam.

### No legacy namespace as architecture

Useful semantic code must use semantic names.

`FlavorText` cannot remain the public namespace for a semantic context provider.
`FlavorAddress` cannot remain a parallel addressing namespace when the function
is semantic conversational addressing.

Do not preserve internal Project Hoomans aliases after their callers have been
migrated.

### Compact content identity

The semantic template/realization identity is the canonical join between
ResponseCatalog and Dialogue Content.

Do not create three or four permanent identities for the same concept merely to
preserve migration history.

Mechanical phrase IDs and translation keys may be generated deterministically
where no external stability contract requires explicit authoring.

### Canonical source versus generated observability

Canonical Dialogue Content owns only wording/authoring structure and the
minimum stable identity required to join semantics.

Generated/read-only tooling may enrich that with:

- response pool;
- variant;
- plan;
- follow-up offers;
- fact refs;
- semantic authority;
- source provenance;
- fingerprints.

That enriched view is **derived** and must not be copied back into every
canonical phrase record.

### Semantic Lab hierarchy

Studio hierarchy is a projection, not data authority.

Both Responses and Dialogue Content derive their branch tree from canonical
semantic IDs and content joins. Humanized labels are UI-only; exact canonical
IDs remain available in details/search.

This keeps organization scalable without introducing a second taxonomy store.

### External compatibility boundary

Generic PsychopatzCore APIs may remain available to external adopters when
outside this repository's ownership, but Project Hoomans must not route its
first-party wording through a legacy generic selector.

Compatibility adapters provide facts/events. Project Hoomans semantics chooses
meaning and Dialogue Content chooses PNC wording.
