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

## 7. Dynamic player affordances

The existing DialogueSuggestions pipeline remains the one player-choice authority.

Generated choices are **semantic affordances**, not free-form strings. Keep two internal axes:

- `origin = AUTHORED | GENERATED`;
- `stance = POSITIVE | NEGATIVE | NEUTRAL`.

A third field, `strategy`, carries the actual conversational move such as:

- AGREE;
- DISAGREE;
- APOLOGIZE;
- DEESCALATE;
- CHALLENGE;
- RETALIATE;
- DISMISS;
- ASK_WHY;
- ASK_FOLLOWUP;
- CHANGE_TOPIC;
- OFFER_HELP;
- CALL_BLUFF.

Traits, relationship, active beat, topic, world state and capabilities are **modifiers/providers**, not a fourth mutually exclusive semantic class. A brave trait may surface a negative `CALL_BLUFF`; empathy may surface a positive `COMFORT`; suspicious state may surface a neutral `PRESS_FOR_DETAILS`.

For presentation, the UI may expose four useful lanes:

1. authored/static;
2. positive-leading;
3. negative-leading;
4. contextual/neutral/trait-induced.

Do not force one candidate from every lane. Rank all eligible semantic candidates, enforce diversity where useful, and backfill from the best remaining candidates.

A generated candidate should carry roughly:

```text
candidateID
origin
stance
strategy
semantic frame
topic / subject / replyTo
target
source evidence
eligibility/provenance
utterance plan
```

Clicking a generated button sends its typed semantic frame through the existing semantic-click path. The displayed sentence is presentation only and must never be reparsed by NLU.

Typed input and button input should converge on the same DiscourseFrame / pragmatic semantics wherever they mean the same thing.

## 8. Compositional runtime utterance realization

Do not require a complete authored sentence for every semantic combination.

Extend the existing SpeechRealization authority with a bounded `UtterancePlan` / microplanning mode.

Conceptually:

```text
UtterancePlan
- speaker
- target
- dialogueAct
- strategy
- stance
- topic / subject
- canonical lexical concepts
- intensity
- relationship/style hints
- optional discourse marker
- locale
- fallbackContentTemplateID
```

The runtime realizer composes from compiler-owned locale constructions and canonical lexemes. It must not concatenate arbitrary raw player text.

Example:

```text
PLAYER raw: "fuckyouuu!!!"
Core recovery: INSULT
canonical lexical payload: PROFANITY_FUCK + RECIPIENT
DiscourseFrame: directed hostility, high intensity

NPC behavior:
  RETALIATE_VERBALLY

UtterancePlan:
  strategy = MIRROR
  dialogueAct = RETORT
  lexical payload = PROFANITY_FUCK + RECIPIENT
  counter = TOO

EN realization:
  "Fuck you too."
```

The full sentence does not need its own response definition. Only the semantic strategy, canonical lexeme and locale construction are authored.

Useful reusable construction strategies include:

- MIRROR;
- COUNTER;
- AGREE;
- DISAGREE;
- ACKNOWLEDGE;
- QUALIFY;
- DENY;
- APOLOGIZE;
- ESCALATE;
- DEESCALATE;
- DEFLECT;
- ASK_BACK;
- FOLLOW_UP.

Locale-specific construction rules are compiler-owned; do not build an English sentence and machine-translate it at runtime.

If required lexemes/constructions are unavailable, ambiguous, unsafe or grammatically unsupported, fall back to ordinary Dialogue Content. Existing authored phrase families remain valuable for signature dialogue, high-risk wording and graceful fallback.

Optional PBrainZ may realize the same UtterancePlan more freely when enabled, but it cannot change semantic intent, grounded facts or gameplay authority.

## 9. Social effects and durable memory

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

## 10. Observability

Simulation → Interactions/Inspect must make the chain inspectable without giant dumps:

```text
raw
→ normalized/recovered surfaces
→ semantic candidates
→ contextual adjustments
→ selected DiscourseFrame
→ pragmatic frame
→ generated/authored player affordances
→ selected semantic click / player UtterancePlan
→ beat/behavior candidates
→ InteractionPlan
→ NPC/player UtterancePlan or Dialogue Content fallback
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
