# Architecture — Unified Semantic Evidence

## One pipeline

    human text / NPC semantic act / gameplay event
                     |
                     v
           existing semantic/event authority
                     |
                     v
          normalized evidence providers
                     |
           +---------+---------+
           v         v         v
        SESSION     TODAY    DURABLE
        context     compact   owning
        runtime     memory    domains
           +---------+---------+
                     v
            Evidence Query/Projection
                     v
           InteractionProviders.evidence
                     v
             InteractionContext
                     v
             Pragmatic Resolver
                     v
            Interaction Director
              +------+------+
              v             v
        player choices   NPC behavior
              +------+------+
                     v
               UtterancePlan

No stage replaces PsychopatzCore NLU, Dialogue Content, Response Channel, Interaction Director, relationship/conduct authority or gameplay command authority.

## Canonical runtime evidence descriptor

Evidence is a bounded read model, not persisted state. A normalized row should expose only fields justified by the provider:

- stable sourceRef / event or fact identity;
- providerID and sourceTier: SESSION / TODAY / DURABLE;
- actor/target/entity references;
- bounded semantic classes such as grievance, hostility, assistance, commitment, offer, question;
- bounded semantic relations such as opens, addresses, resolves, contradicts, elaborates;
- retention salience (0-255) when defined;
- truth/interpretation confidence when meaningful;
- effectiveStrength from owning durable systems when meaningful;
- observed/occurred time or bounded age;
- semantic tags;
- necessary visibility/shareability;
- provenance.

Never copy raw transcripts, realized dialogue, arbitrary ModData tables or unrestricted event context into the normalized descriptor.

## Ranking vocabulary

Keep these separate:

- confidence: certainty that interpretation/evidence is correct;
- retention salience: importance for bounded memory retention;
- effective strength: current effect of durable memory/evidence after decay;
- recency: age of evidence;
- contextual relevance: derived runtime fit for the current semantic act/relation;
- priority: deterministic policy/order tie-break owned by a catalog.

Contextual relevance is derived and ephemeral. It may consider relation compatibility, actor/target match, recency, current topic/beat, pending interaction, confidence, effective strength and retention salience. It is never persisted.

## Memory lifetime contract

### SESSION

Use existing DialogueContextState, Director state, pending agenda/flows and recent turns. Same-conversation evidence should normally require zero ModData writes.

### TODAY

Reuse record.memory.s/t. No new root/table. Short events remain compact numeric triples. When full, retention policy should use canonical retention salience with deterministic recency tie-breaking rather than pure FIFO, while preserving the hard limit.

A successfully authoritative social/game event may project into TODAY memory even when a larger relationship memory was pruned/dropped. Compact episodic projection and detailed durable retention are separate outcomes.

### DURABLE

New Relationship memories carry an optional owner-stamped `eventSequence` for
causal ordering when world time is equal (including paused conversations).
It derives from the existing relationship revision and at most 20 retained
memory sequences. It adds no counter/root, does not change occurrence time,
and is distinct from retention salience, relevance and priority. Legacy
memories remain readable without the field.

Do not centralize durable truth into a new semantic store. Query the owning relationship, conduct, knowledge or other domain through bounded provider APIs. Existing record.memory.l may remain a lightweight recall/gossip/routing projection, but cannot override authoritative domain truth.

## Generic semantic relations

Do not encode rules such as “if APOLOGIZE then search INSULT.”

Both evidence and semantic acts participate in registered relations. Example:

    INSULT evidence: classes grievance, hostility; opens repair
    APOLOGIZE act: addresses repair

    RESCUE evidence: classes assistance; opens gratitude
    THANK act: addresses gratitude

    OFFER: opens response
    ACCEPT / REFUSE: addresses response

    PROMISE: opens commitment
    FULFILL / BREACH: resolves / violates commitment

The generic resolver matches relations, targets, actors and lifetime evidence. Domain policy still decides whether a relation produces an effect.

## Canonical metadata ownership

Avoid current dual authoring.

For authoritative first-party social events, semantic/memory metadata should live with the owning social event definition, or one canonical declarative source that generates it. Conversation Memory derives compact registration from that metadata.

Other domains remain authoritative for their own events/facts and expose them through evidence adapters. Do not move every domain into one god registry.

A domain may explicitly declare no semantic retention. Dynamic hash fallback remains a compatibility path, not preferred first-party authoring.

## Provider architecture

Extend existing PNC_SemanticInteractionProviders with bounded evidence projection and evidence adapters. External/adopter systems register providers/adapters instead of patching PragmaticResolver.

Provider queries must be selective and bounded: ask for relevant classes/relations/target rather than dump all relationship memories, conduct records or journals into every turn.

## Persistence rules

Forbidden:

- new semanticMemory ModData root;
- transcript persistence;
- persistent InteractionPlans/UtterancePlans/generated choices;
- duplicated grievance/repair/offer/promise databases;
- interactionJournal as semantic truth;
- persisted derived relevance;
- unbounded tags/classes/relations.

Allowed:

- existing bounded session state;
- existing compact day tuples/topic masks;
- existing owning-domain durable state;
- compact relation/event markers through the same existing memory/event path when cross-conversation context genuinely requires them.

## Extension test

The architecture is not generic until a test-only future mechanic can register event/evidence metadata and semantic relations, participate in configured session/today/durable context, and drive the existing pragmatic/director pipeline without modifying generic resolver implementation.
