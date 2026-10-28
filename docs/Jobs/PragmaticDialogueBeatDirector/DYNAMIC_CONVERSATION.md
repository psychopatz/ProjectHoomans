# Dynamic Conversation — Affordances & Utterance Realization

Read this file when implementing C6/C7 or modifying dynamic player choices, semantic-click realization, UtterancePlan composition or SpeechRealization integration. It is intentionally not part of the default job read order.

## Dynamic player affordances

The existing DialogueSuggestions pipeline remains the one player-choice authority.

Generated choices are semantic affordances, not free-form strings.

Keep independent fields:

- origin: AUTHORED | GENERATED;
- stance: POSITIVE | NEGATIVE | NEUTRAL;
- strategy: AGREE, DISAGREE, APOLOGIZE, DEESCALATE, CHALLENGE, RETALIATE, DISMISS, ASK_WHY, ASK_FOLLOWUP, CHANGE_TOPIC, OFFER_HELP, CALL_BLUFF, etc.;
- contextual provenance: trait, relationship, topic, beat, world state and capability evidence.

The UI may present four practical lanes:

1. authored/static;
2. positive-leading;
3. negative-leading;
4. contextual/neutral/trait-induced.

Trait-driven is a presentation/source category, not a mutually exclusive sentiment class. A brave trait may produce a negative CALL_BLUFF while empathy may produce a positive COMFORT.

Do not force one candidate from every lane. Rank all eligible candidates, enforce semantic diversity, deduplicate near-equivalents and backfill from the best remaining candidates.

### Native surface priority

Current-turn direct responses must become the selected semantic group after a conversational turn. A generated `conversation_branch` / DIRECT_RESPONSE group must not exist only in diagnostics while Core's native choice surface remains on the root landing group.

Priority contract:

1. explicit user-selected semantic navigation/group remains selected while valid;
2. otherwise an eligible current-turn direct-response group becomes current;
3. otherwise active flow/response-plan groups may become current;
4. otherwise fall back to the root landing group.

Root/static actions remain reachable through the existing Back/navigation model. Do not create a second renderer or duplicate response strip.

A generated candidate should carry bounded semantic data such as:

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

Clicking a generated button sends its typed semantic frame through the existing semantic-click path. The displayed sentence is presentation only and is never reparsed through NLU.

Typed input and generated-button input should converge on the same DiscourseFrame/pragmatic meaning when they express the same semantic act.

## Compositional runtime utterance realization

Do not require a complete authored sentence for every semantic combination.

Extend the existing SpeechRealization authority with a bounded UtterancePlan/microplanning mode.

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

The realizer composes from compiler-owned locale constructions and canonical lexemes. It must not concatenate arbitrary raw player text.

Example:

```text
PLAYER raw: "fuckyouuu!!!"
Core recovery: INSULT
canonical payload: PROFANITY_FUCK + RECIPIENT
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

Reusable construction strategies may include MIRROR, COUNTER, WARN, CHALLENGE, CLAIM_JOKE, DOUBLE_DOWN, DISMISS, AGREE, DISAGREE, ACKNOWLEDGE, QUALIFY, DENY, APOLOGIZE, ESCALATE, DEESCALATE, DEFLECT, ASK_BACK, CHANGE_TOPIC and FOLLOW_UP.

Common Director behaviors such as WARN / BOUNDARY_WARNING must have compositional mappings; composition must not be reserved for rare RETALIATE/MIRROR cases. Multiple bounded constructions may exist per strategy, selected deterministically from semantic/style/relationship context and a stable turn salt.

Locale-specific construction rules are compiler-owned. Do not construct English and machine-translate it at runtime.

If required lexemes/constructions are unavailable, ambiguous, unsafe or grammatically unsupported, fall back to ordinary Dialogue Content.

Authored Dialogue Content remains useful for signature lines, story-specific wording, high-risk text and graceful fallback.

Optional PBrainZ may realize the same UtterancePlan more freely but cannot change semantic intent, grounded facts or gameplay authority.

## Storage interaction

All affordance/construction/lexicon sources obey C5 `STORAGE_TOPOLOGY.md`.

Do not pre-expand combinations such as personality × relationship × lexeme × strategy × intensity.

Generated candidates and UtterancePlans are ephemeral.

## C6/C7 acceptance summary

Dynamic choices must prove authored preservation, positive/negative/contextual generation, grounded trait/context provenance, semantic diversity, direct semantic-click execution and typed/button parity.

Compositional realization must prove stable semantic intent before wording, canonical lexical payloads, deterministic locale-aware construction, multiple realizations from reusable pieces, authored fallback, no raw-input injection and no new monolithic phrase catalog.
