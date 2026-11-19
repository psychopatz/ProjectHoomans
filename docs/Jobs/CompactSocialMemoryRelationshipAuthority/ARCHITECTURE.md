# Architecture — Project Hoomans Portable Social State Adoption

> Canonical generic ownership is defined by PsychopatzCore Docs/portable_social_state/. This document specifies only Project Hoomans adoption, domain boundaries and migration constraints. If this document appears to make PNC the generic social-state owner, the Core parent contract wins.

## 0. Ownership boundary

| Concern | Owner |
| --- | --- |
| stable actor identity, generic personality/social state, sparse directed relationship, bounded generic memory, retention/consolidation, generic social projections | PsychopatzCore |
| portable Social Policy IR/compiler/runtime mechanism | PsychopatzCore CodeBuilder |
| physical NPC state, Hoomans SocialEvents, Conduct, faction rules, Hoomans Knowledge, companion/romance/colony-specific policy | Project Hoomans |
| conversation opportunity/turn selection | accepted Semantic Social Conversation Director consumer |
| semantic evidence projection | accepted Unified Semantic Evidence consumer/provider layer |
| merchant economy/trader commercial authority | DynamicTrading, not Hoomans |

There must not be two writable generic relationship histories. During migration, current Hoomans relationship/event stores are audited field-by-field and either retained as Hoomans-specific authority, adapted to Core, or removed after caller-zero proof.

## 1. Core model

Social state is deliberately separated into different authorities:

    authoritative semantic/game/social event
                    |
                    v
            shared event identity
                    |
           +--------+---------+----------------+
           |                  |                |
           v                  v                v
     actor memory refs   relationship edge   knowledge facts
     what happened       how actor feels     what actor knows
           |                  |                |
           +------------------+----------------+
                              |
                              v
                     bounded projections
                              |
               +--------------+-------------+
               v                            v
     Unified Semantic Evidence     Social Conversation Director

Active threat/hostility and faction stance are operational inputs layered over this state; they are not aliases for relationship sentiment.

## 2. Social state categories

### Memory

Memory is bounded evidence of an event from one actor's perspective. It can explain why a relationship or belief exists, but it does not replace those durable authorities.

Retention classes:

- SCENE — ephemeral interaction-only evidence; never persisted;
- SHORT — hours/current-day class; compact and bounded;
- LONG — multi-day/important episodic evidence; bounded;
- ANCHOR — rare effectively permanent identity-defining memories with a very small cap.

Retention class is semantic policy, not an excuse for unbounded timestamps or history.

### Relationship

Relationships are sparse directed edges, created only when meaningful state exists.

Conceptual directed dimensions may include the existing authoritative equivalents of familiarity, affinity, trust, respect, fear, grievance/bond or other accepted current dimensions.

A-to-B and B-to-A are independent. No dense actor matrix is allowed.

### Knowledge

Stable facts such as a known person's name, known settlement affiliation, learned world fact or other semantic knowledge belong to the existing Knowledge authority. They must not consume permanent episodic memory merely because the fact was once learned through an event.

### Threat / hostility

Operational hostility is derived from current facts, for example:

    active aggression / threat
    + faction stance/policy
    + personal grievance/relationship
    + current orders/context
    = current hostility decision

Do not collapse this into one persistent hostile boolean relationship flag.

### Faction/social standing

Faction-level standing/reputation remains separate from personal directed relationships. A faction may know or enforce something an individual NPC has not personally witnessed.

## 3. Shared event identity

The target design should avoid copying full event payloads into every observer memory.

A canonical event identity/reference may be reused by:

- direct target memory;
- witness memory;
- hearsay/gossip memory;
- relationship/conduct consequences;
- knowledge projection;
- semantic evidence.

The implementation must first audit the current SocialEvent/Relationship/Conduct/Knowledge storage and reuse existing identity/sequence fields where possible. Do not introduce a permanent global event ledger merely because the conceptual model uses shared event identity.

If an explicit event store is truly required after audit, it must be compact, bounded/collectable, server-owned and demonstrably smaller than duplicated payload storage. Existing owner state remains preferred.

## 4. Memory reference shape

Persist compact data, not verbose Lua objects or prose.

A memory row should contain only fields justified by behavior, such as:

- event/source identity;
- event type/class code;
- subject/target actor refs where not recoverable;
- occurred/observed time or bounded age;
- retention/salience class;
- source mode: direct, witnessed, hearsay;
- confidence/strength only when semantically distinct and necessary;
- small flags.

Use stable numeric codes/flat arrays where compatible with current ModData conventions. Human-readable debug symbols belong in diagnostics, not persistence.

## 5. Retention, decay and forgetting

No per-tick decay.

Store immutable/rarely-mutated retention inputs and derive effective strength lazily on:

- targeted query;
- actor activation;
- save/maintenance checkpoint;
- day transition;
- bounded explicit maintenance.

Expired rows are removed opportunistically.

Retention salience, truth confidence, current effective strength, recency, contextual relevance and deterministic priority remain distinct concepts, consistent with Unified Semantic Evidence.

## 6. Consolidation

Repeated semantically equivalent low/medium-value episodes should coalesce.

Conceptual consolidation key:

    event/semantic class
    source actor
    target actor
    relation/grievance family

A repeated sequence may preserve count, first occurrence, last occurrence, aggregate/bounded severity and a representative event reference instead of N separate memories.

Highly salient individual events may remain independently retained.

Older episodic evidence may promote into an existing durable relationship/grievance/knowledge summary without requiring the original event row forever.

## 7. Anchor/permanent memories

ANCHOR is rare and tightly capped.

Examples may include life-saving rescue, severe betrayal, death of a deeply related actor, or other event types explicitly declared by policy. Ordinary conversation must never freely promote events to anchor status.

When the anchor budget is full, deterministic salience/relevance/consolidation policy chooses whether to reject, merge, replace or summarize. Pure FIFO is not sufficient.

## 8. Personality and configuration

One semantic event policy may be modulated by:

1. server/sandbox configuration;
2. event-type memory/relationship policy;
3. actor profile/personality modifiers.

Example:

    INSULT
    base: SHORT, medium salience

    actor low forgiveness
    -> longer effective retention / stronger grievance tendency

    actor high forgiveness
    -> faster decay / lower promotion tendency

Personality modifies bounded policy parameters; it must not create per-personality memory implementations.

Configuration must expose safe ranges and preserve hard upper bounds.

## 9. Canonical event metadata and CodeBuilder

First-party social/semantic events should declare memory and relationship semantics once in canonical source, extending current CodeBuilder/event metadata rather than creating another registry.

Conceptual metadata:

    memory:
      retentionClass
      retentionSalience
      merge/consolidation family
      anchor eligibility
      observer/hearsay policy

    relationship:
      affected dimensions/effect class
      target direction
      personality modulation policy

    knowledge:
      optional fact projection

Generated runtime tables may use compact numeric IDs and prevalidated policy plans.

The compiler should detect unknown memory classes, unbounded retention budgets, invalid relationship effects, incompatible persistence policy, duplicate authority, unbounded observer/gossip fan-out, and anchor-eligible types without explicit salience/limit policy.

Generated files remain downstream output and are never hand-edited.

## 10. Multiplayer authority

The server owns:

- social event validation/commit;
- relationship mutation;
- memory insertion/consolidation/expiry;
- knowledge consequences;
- faction standing;
- authoritative revisions.

Clients submit actions/inputs, not social outcomes.

Clients normally receive only bounded presentation projections or deltas, for example actor attitude/disposition, current hostility/threat presentation, relationship revision, and conversation-relevant result/context.

Clients do not receive an NPC's complete memory store or social graph merely because the NPC is nearby.

## 11. Actor model across NPCs and players

Use stable generic actor references for events/relationship endpoints.

Supported authoritative cases:

- NPC-to-NPC directed relationship and memory;
- NPC-to-player directed relationship and memory;
- NPC witnessing player-to-player behavior;
- faction-to-actor standing/policy where already supported.

Do not infer human player emotions. Player-to-NPC and Player-to-Player persistent state should contain only explicit gameplay/social facts such as faction, ally/party/permission/declared standing, reputation or user-authored stance if the product later supports it.

## 12. Gossip / hearsay

Hearsay must preserve provenance.

A recipient should be able to distinguish direct target, direct witness, and heard-from-actor-X evidence.

Confidence/shareability may attenuate through policy. Gossip should reuse event/evidence identity where practical instead of copying verbose descriptions.

The semantic layer may realize "I saw it", "Alice told me", or "I heard that..." from provenance, but realized prose is never persisted.

## 13. Revisions and caches

Use bounded revision counters from existing authorities where possible, such as relationship revision, memory/evidence revision if required, and knowledge revision.

Runtime caches are ephemeral and invalidated by revisions. Save data must not persist indexes that can be rebuilt cheaply.

A Director/LLM DecisionFrame containing stale relevant revisions must be revalidated before commit.

## 14. Performance invariants

The final implementation must preserve:

- no global actor-pair matrix;
- no full memory scan across all actors for one conversation;
- no per-tick memory aging;
- no transcript persistence;
- bounded per-actor memories;
- bounded relationship edges per actual meaningful contacts, not total population;
- targeted provider queries;
- lazy projection for conversation/AI;
- no routine LLM work for retention or relationship updates;
- no client replication of private social databases.

## 15. Interaction with accepted semantic systems

UnifiedSemanticEvidenceArchitecture remains the read/projection layer. This job may improve the owning durable/episodic state beneath it, but must keep the SESSION/TODAY/DURABLE provider contract intact or migrate it deliberately with regression coverage.

SemanticSocialConversationDirector remains a consumer. It may use relationship/memory/knowledge/threat projections to rank/realize conversation, but it never becomes the persistence owner.

## 16. Future emergent-autonomy integration contract

This social-state authority is intended to complement a future non-LLM Event/Opportunity Director and Sims-like advertisement/autonomy architecture.

The ownership split is strict:

    Event / Opportunity Director
    - observes bounded World Signals;
    - manages pacing/pressure/opportunity;
    - may introduce legitimate external incidents;
    - does not command individual NPC actions.

    Advertisement / Affordance layer
    - objects, actors, locations, tasks and events expose possible actions;
    - describes requirements, benefits, costs and grounded context;
    - does not execute the action.

    NPC Autonomy Resolver
    - combines actor desires/needs with available advertisements;
    - applies hard eligibility first;
    - applies semantic precedence before utility scoring;
    - uses hysteresis/stickiness and bounded reproducible variation;
    - may choose silence/no action;
    - does not mutate authoritative domains directly.

    Task / Action authorities
    - reserve/claim scarce work where needed;
    - execute validated actions;
    - emit authoritative outcomes/events.

    This social-state job
    - records/query-projects compact consequences;
    - supplies memory, directed relationship, knowledge, grievance, provenance and threat inputs;
    - never becomes the world director or autonomy planner.

### Behavior-driving projections

Future consumers should request bounded projections rather than raw stores. Useful projections may include:

- directed relationship summary toward a candidate actor;
- relevant unresolved grievance/assistance/commitment evidence;
- familiarity and recent interaction;
- direct-witness versus hearsay provenance;
- current threat/hostility projection;
- faction standing relevant to the current actor/target;
- stable knowledge facts;
- revision/version markers for cache and decision revalidation.

The query API must support a bounded candidate-oriented use case such as evaluating one advertised TALK, AVOID, HELP, TRADE, CONFRONT or ATTACK opportunity without scanning an actor's entire social history.

### Memory creates motives, not commands

A remembered betrayal may increase the viability of AVOID, CONFRONT, REPORT or RETALIATE opportunities, but memory must never directly force one action.

Relationship and memory are decision features. Personality, current needs, domain policy, capability, danger, task priority and context remain separate inputs.

This is required for emergent differentiation: two actors can remember the same event and choose different valid responses.

### Director feedback

Future world pacing may consume aggregated, privacy-safe signals derived from authoritative domains, for example settlement social tension or recent-loss pressure. The Event Director must not inspect or copy every private NPC memory to decide pacing.

If aggregate social signals are added later, they must be derived/read models with bounded cost and clear owner provenance, not a second social truth store.

### LLM independence

The complete loop must function without an LLM:

    grounded event
      -> compact social consequence
      -> future motive/context
      -> advertised opportunity
      -> deterministic/bounded autonomy choice
      -> validated action
      -> new grounded event

An optional LLM may later rephrase an already selected semantic speech act, but it must not be required to determine what an NPC knows, remembers, feels, chooses or is allowed to do.

## 17. Failure behavior

Unknown/unsupported event types fail closed for durable memory/relationship mutation unless an existing compatibility path explicitly defines safe fallback.

Corrupt or stale actor/event references should be skipped/cleaned through bounded maintenance, never crash the global social loop or silently fabricate actors.

Server/client revision mismatch triggers refresh/requery, not client-side repair of authoritative data.