# Architecture — Pragmatic Dialogue Beat Director

## Core separation

```text
Core NLU candidates
        ↓
Pragmatic Resolver
        ↓
Conversation Context / references / obligations / salience
        ↓
Flow Kernel ───────────────┐
                           │
Beat Registry + Director ──┤
                           ▼
                  Behavior Arbitration
                           ↓
                    ResponsePlan
                           ↓
              Dialogue Content / Catalog
                           ↓
                       Speech

Authoritative gameplay effects remain on their existing domain/action paths.
```

## Flow vs Beat vs Behavior

### Flow

A **Flow** owns a bounded conversational obligation or protocol.

Examples:

- awaiting a name;
- awaiting wellbeing status;
- a multi-stage gift;
- a parameterized task request.

Flows can suspend/resume/complete/cancel and may capture slots.

### Beat

A **Beat** describes a higher-level social/dramatic situation spanning one or
more turns.

Examples:

- suspicious first contact;
- argument escalation;
- reconciliation;
- reacting to danger;
- help request pressure.

A beat does not own final prose and does not directly mutate gameplay state.

### Behavior

A **Behavior** is a reusable conversational intention available to a director.

Examples:

- WARN;
- RETALIATE_VERBALLY;
- DEESCALATE;
- CHALLENGE;
- ASK_FOLLOWUP;
- END_CONVERSATION;
- RETURN_TO_TOPIC.

The same behavior may be eligible in more than one beat.

### ResponsePlan

The existing `ResponsePlan` owns the grounded communication plan that will be
realized through Dialogue Content. Beats/behaviors select intentions and
metadata; wording remains separate.

## Production beat contract

Exact field names may be adapted to existing Lua conventions, but the contract
must support:

```text
BeatDefinition
- id / version / owner
- entry predicates
- maintain predicates
- exit predicates
- candidate behavior IDs
- bounded relevance/weight metadata
- cooldown / minimum / maximum turn policy
- optional mutual-exclusion or priority group
- provenance
```

Predicates must use typed/bounded existing context/fact paths rather than
arbitrary Lua expressions.

## Director contract

Per relevant conversation turn:

1. consume real semantic candidates/selected IR and current dialogue context;
2. update bounded pragmatic context (topic/reference/obligation/salience where
   needed);
3. evaluate beat entry/maintain/exit predicates;
4. preserve active beat state and explain transitions;
5. rank eligible behavior candidates;
6. apply bounded contextual modifiers from personality, relationship,
   world/needs/danger, flow state, and recent conversational events;
7. choose one deterministic/explainable behavior or an explicit no-behavior;
8. produce/augment the existing ResponsePlan;
9. let existing response/translation/presentation layers realize wording;
10. dispatch gameplay effects only through existing authority paths.

A high-confidence social understanding may result in a conversational reply
without granting authority for an ambiguous gameplay mutation.

## Pragmatic context

Keep context bounded and event-driven. Candidate fields include:

- current/recent topic;
- pending questions/offers/requests;
- recent dialogue acts;
- recent social events;
- recent referenced entities;
- active/suspended flows;
- active/recent beats;
- compact topic salience;
- commitments;
- cooldown state.

Do not persist full transcripts or unbounded beat histories in NPC ModData.

## Arbitration

Do not turn the system into one unbounded giant score.

Use staged arbitration:

```text
eligibility
    ↓
beat group/precedence
    ↓
beat relevance + contextual modifiers
    ↓
active-beat stickiness / cooldown
    ↓
behavior eligibility
    ↓
behavior relevance + contextual modifiers
    ↓
deterministic tie-break
```

Every failed predicate and applied modifier needed to explain the winner must be
available to the harness.

## Initial reference beats

The architecture must be generic. Initial content exists only to prove it:

- `suspicious_first_contact`;
- `argument_escalation`;
- `reconciliation`.

Do not hardwire these IDs into the director.

## Canonical authoring and compiler ownership

Target canonical source model:

```text
tools/semantic_harness/codebuilder/sources/conversation/
├─ manifest.json
├─ content/
├─ patterns/
├─ flows/
├─ beats/          # if schema extension is selected
├─ behaviors/      # if schema extension is selected
└─ ui/
        ↓
one Conversation compiler
        ↓
validated/generated production Lua registries/shards
generated translation keys and locale bundles
generated manifests/indexes/fingerprints
audit/provenance projections
```

Physical folders are not runtime identity. A different cohesive shard layout is
acceptable if it preserves one manifest/compiler and stable canonical IDs.

### String rule

Beat-related first-party semantic/domain strings are compiler-owned:

- NPC response variants;
- player suggestions/utterances;
- beat/behavior labels displayed by the mod;
- localized descriptions or player-facing status text;
- response-pool text associated with beat behaviors.

Canonical source uses generic `translations` maps. CodeBuilder derives
translation keys and writes locale bundles. EN is required fallback. New locales
must not require Python/Lua whitelist edits.

Generic developer-tool chrome is not semantic content and may remain ordinary
UI code.

## Semantic Lab authoring lifecycle

Three visible states:

```text
DRAFT
    editable harness definition

WORKER REGISTERED
    validated definition executing in the disposable real Lua worker

CANONICAL
    compiler-owned production source, generated and reloaded
```

A draft based on canonical production must be labeled as such.

### Draft operations

The worker should expose bounded equivalents of the current Flow Editor:

- beat catalog;
- validate beat;
- preview beat;
- register beat;
- behavior catalog;
- explain director arbitration.

Registration is worker-local and must not write packaged source.

### Promotion

Canonical promotion must delegate to the existing CodeBuilder authoring service:

```text
draft
→ validate
→ diff
→ canonical source edit
→ compiler preview
→ explicit validated write
→ regenerate
→ restart worker
→ replay acceptance
```

No direct generated-Lua or translation edit.

## Observation contract

Extend the existing worker observation with a bounded director projection,
conceptually:

```text
observation.director
- pragmatic interpretation
- beat candidates
- predicate trace
- activeBefore / activeAfter
- entered / exited
- behavior candidates
- applied modifiers
- selectedBehavior
- responsePlan lineage
- override status
```

CLI, GUI, tests, and agents consume this same observation. Python must not infer
a second decision.

## Harness override semantics

For focused tests, support:

- Natural;
- Force eligible;
- Force active;
- Disable.

Forced states must be visibly marked `HARNESS_OVERRIDE` and must never count
as proof that natural production arbitration works.

## Performance

- evaluate beats on conversation-relevant events/turns, never every NPC tick;
- bound registered beats, predicates, candidate behaviors, trace size, salience,
  cooldown history, and timeline;
- compile indexes where useful;
- avoid whole-catalog scans in ordinary turns;
- no new save database.

## Optional PBrainZ

PBrainZ may receive the same selected grounded ResponsePlan and realize it more
flexibly. Offline authored/compositional realization and PBrainZ must share:

- semantic meaning;
- beat selection;
- behavior selection;
- facts;
- authority;
- side effects.

The LLM is never the director of authoritative gameplay state.
