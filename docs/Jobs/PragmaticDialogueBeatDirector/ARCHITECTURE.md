# Architecture — Coherent Semantic Conversation

## Principle

Conversation meaning is layered. No single subsystem should try to solve every problem from raw text to gameplay effect.

```text
RAW HUMAN TEXT
      ↓
Surface understanding                PsychopatzCore
      ↓
Semantic candidates                  PsychopatzCore
      ↓
Contextual discourse interpretation  Project Hoomans
      ↓
Pragmatic interaction frame          Project Hoomans
      ↓
Behavior / beat arbitration          Project Hoomans
      ↓
InteractionPlan
   ┌──┼────────────┐
   ↓  ↓            ↓
speech emote   gameplay intent
   ↓              ↓
Dialogue       existing domain
Content        authority
```

NPC-generated semantic acts bypass human-text NLU and enter at the semantic-stimulus layer.

## 1. Surface understanding — PsychopatzCore

Core remains the sole generic NLU owner.

Ordinary exact normalization stays the first path. Recovery is additive and bounded; it never destroys the original input.

Preferred recovery order:

1. exact normalized text;
2. registry-derived compact/no-space alias recovery;
3. conservative repeated-character / common contraction recovery;
4. bounded segmentation only when a single unknown token plausibly maps to registered vocabulary;
5. existing fuzzy concept matching.

Examples that should be recoverable without manually authoring every malformed spelling:

- `fuckyou` → `fuck you`;
- `shutthefuckup` → `shut the fuck up`;
- `youidiot` → `you idiot`;
- `youreuseless` → `you're useless`;
- `illkillyou` → `i'll kill you`;
- `youuuu` → `you` as a bounded elongation alternative.

Each transformation must expose provenance, confidence cost and ambiguity. Ambiguous recoveries remain candidates rather than silently rewriting the text.

Recovery must be registry-driven where possible so new registered phrases inherit it automatically.

## 2. Semantic candidates — PsychopatzCore

`ParseCandidates()` is the bridge to contextual understanding.

Do not collapse useful alternatives before Project Hoomans can evaluate conversation context.

Candidate evidence should remain bounded and include:

- pattern/concept identity;
- exact/fuzzy/recovery pass;
- normalized/recovered surface;
- confidence and recovery cost;
- typed captures;
- unmatched/unresolved material;
- provenance.

Core should recognize generic semantic structure; it should not know Project Hoomans relationships, beats, pending conversation obligations or NPC personalities.

## 3. Intermediate social/pragmatic features

A conversational turn may carry multiple features without those features becoming the final intent.

Useful bounded features include:

- valence;
- hostility;
- affiliation;
- threat;
- contempt;
- distress;
- intensity;
- directedness: SELF / RECIPIENT / THIRD_PARTY / WORLD;
- negation;
- intensification;
- target/referent hints.

These features support interpretation; they are not a standalone sentiment authority.

Examples:

- `fuck you` → directed insult + hostility;
- `I hope you die` → directed hostile/malicious wish, not automatically the same as a threat;
- `I'll kill you` → threat;
- `this fucking rain` → complaint/profanity toward WORLD, not the NPC;
- `I'm fucking starving` → self-state hunger with intensification;
- `you're not bad` → negation must suppress naive negative scoring.

Specific/compositional meanings should suppress misleading lower-level cues.

## 4. Contextual Discourse Resolver — Project Hoomans

This is the active missing layer.

It consumes semantic candidates plus bounded interaction context. It must not tokenize or reparse raw text.

Relevant context may include:

- current and recent topic;
- previous NPC/player semantic act;
- pending question/offer/request;
- active/suspended flow;
- reply-to / adjacency relationship;
- referenced actor/entity;
- recent bounded semantic acts;
- current beat/scene;
- actor roles;
- relationship;
- actor disposition/condition;
- grounded world/social events;
- actor-known facts.

Output is a `DiscourseFrame` or equivalent projection containing the selected/combined semantic meaning, contextual subject/topic/reply-to, social features, confidence/evidence and provenance.

Example:

```text
NPC: Do you trust me?
PLAYER: not really

surface: DISAGREE
context: replyTo=TRUST question
result: DISAGREE subject=TRUST
```

## 5. Confidence policy

Do not use one global confidence cliff for all semantic acts.

Acceptance must reflect risk:

- conversational/social acts may proceed at moderate confidence when contextual support is strong and alternatives are non-dangerous;
- read-only questions may use moderate thresholds;
- ambiguous references may request clarification;
- mutating gameplay actions remain strict and require high/exact confidence or explicit confirmation;
- fuzzy/recovered text must never silently authorize dangerous or inventory/world mutation.

A recognized conversational act must not become `ASK_CLARIFICATION` solely because it is slightly below a gameplay-grade threshold.

## 6. Pragmatic Resolver and Interaction Director

These accepted layers remain downstream.

The DiscourseFrame feeds the existing pragmatic resolver, which resolves current interaction meaning. The Interaction Director then chooses behavior/beat relevance from typed stimuli and bounded projections.

The director does not parse text and does not own wording.

## 7. Social effects and durable memory

Understanding, immediate reaction, relationship effect and durable conduct persistence are separate outcomes.

A full conduct ledger must not turn an understood social act into a rejected conversation.

Required separation:

```text
understood                 true/false
interaction reaction       selected/no-op
relationship effect        applied/clamped/none
durable conduct evidence   persisted/coalesced/pruned
```

Repeated low-value social evidence should be coalesced/compacted where possible rather than stored as unbounded near-duplicates.

No full transcript persistence.

## 8. Observability

Simulation → Interactions/Inspect must make the chain inspectable without giant dumps:

```text
raw
→ normalized/recovered surfaces
→ semantic candidates
→ contextual adjustments
→ selected DiscourseFrame
→ pragmatic frame
→ beat/behavior candidates
→ InteractionPlan
→ response/content lineage
→ authoritative effects
→ durable-memory outcome
```

The harness may display this chain but must not implement a duplicate evaluator.

## Non-goals

- no Façade content/script recreation;
- no authoritative runtime LLM;
- no keyword-only profanity detector as the final solution;
- no unrestricted substring matching;
- no second ProjectHoomans tokenizer/parser;
- no lowering gameplay-action safety to improve conversation recall;
- no transcript database;
- no reopening accepted interaction infrastructure without evidence.
