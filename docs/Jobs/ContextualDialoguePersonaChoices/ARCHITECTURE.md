# Architecture — Contextual Dialogue Persona & Choices

## 1. Invariants

### Authoritative state remains outside this job

```text
Identity ─────────────┐
Traits ───────────────┤
Social Profile ───────┤
Relationship ─────────┤
Roles/Capabilities ───┤
Situation/World ──────┤
                      ▼
              ActorConversationContext
              (bounded read-only projection)
```

No duplicate persistence is introduced.

### Meaning before style

```text
semantic meaning / response plan / click frame
                    │
                    ▼
             realization intent
                    │
         ActorConversationContext
                    │
                    ▼
              SpeechStyleContext
                    │
                    ▼
          localized phrase variant
```

Style may choose wording but cannot change authoritative meaning or effect.

## 2. Canonical ActorConversationContext

Implement a bounded versioned projection, exact API/name determined after local source verification. It should expose only facts needed by dialogue and candidate policy.

Conceptual shape:

```lua
{
  schema = "pnc.actor_conversation_context.v1",
  actor = {
    id = "...",
    identity = { gender = "female" },
    traits = { reserved=true, brave=true },
    personality = {
      socialStyle="withdrawn",
      compassion=.62, sociability=.31, forgiveness=.47,
      bravery=.76, materialism=.18, aggression=.58, loyalty=.83
    },
    roles = {
      companion=true,
      owned=true,
      trader=false
    }
  },
  relationship = {
    approval=67,
    respect=34,
    familiarity=89,
    state="friend",
    revision=...
  },
  situation = {
    healthState="healthy",
    activeBehavior="idle",
    threatState=...,
    topic=...
  },
  revisions = {...}
}
```

Exact fields must use public owners and privacy-safe projections. Omit unavailable fields rather than guessing.

## 3. Derived SpeechStyleContext

Derived, transient, revision/cacheable, and never persisted.

Recommended bounded dimensions:

- warmth
- formality
- directness
- verbosity
- hostility
- openness
- deference
- optional humor/emotionality only if actual realization rules need them

Each normalized to a documented range such as `[0,1]`. Resolver inputs are personality + directed relationship + role + situation. Traits can provide qualitative modifiers. Relationship familiarity is not the same as approval; respect is not the same as warmth.

Gender is not a personality dial.

Resolver output must include a bounded diagnostic trace explaining influential inputs without leaking private facts to player-facing UI.

## 4. Semantic Choice contract

All sources normalize into one candidate contract before eligibility/rank/presentation.

Conceptual contract:

```lua
{
  schema = "semantic.choice.v1",
  id = "social.ask_wellbeing",
  namespace = "projecthoomans.social",
  family = "social",
  group = "social",
  source = {...},

  semantic = {
    intent = "QUESTION",
    speechAct = "QUESTION",
    subject = "WELLBEING",
    action = nil,
    target = ...,
    slots = {...},
    modifiers = {...},
    extensions = {...}
  },

  conditions = {...},

  presentation = {
    labelKey = "choice.social.ask_wellbeing.label",
    utteranceKey = "choice.social.ask_wellbeing.utterance",
    realizationFamily = "question.wellbeing"
  },

  rank = {
    class = "CONTEXTUAL_RESPONSE",
    orderHint = 0
  },

  visibility = "player"
}
```

Stable IDs and semantic fields are language-independent.

## 5. Registry + provider model

### Generic mechanism

A registry owns:

- schema validation;
- stable IDs/namespaces;
- registration/listing;
- bounded provider invocation;
- normalization;
- deterministic dedupe;
- ranking primitives;
- trace contracts.

If the correct reusable home is PsychopatzCore after source audit, move only generic mechanism there. Hoomans must retain gameplay policy/content. Do not move Hoomans-specific relationship/romance/trader rules into Core.

### Providers

Providers contribute potential candidates; they do not execute effects or render UI.

Expected provider families:

- static/common conversation
- active dialogue flow
- response plan / branch offers
- authored Conversation registry/root
- capability/companion
- social/relationship
- knowledge/gossip
- quest
- Dynamic Trading trader provider

A provider returns declarative candidate specs or normalized candidates through the registry contract.

## 6. Conditions, privacy, eligibility

Preserve the existing distinctions:

1. discovery
2. eligibility
3. visibility
4. ranking
5. presentation
6. click-time authority/admission
7. authoritative completion/result

Visibility never proves authorization.

Unknown/private/secret/undiscovered facts fail closed and must not leak through disabled labels, tooltips, traces, or ordering.

Audit convergence between suggestion predicates and existing ConversationRules conditions. Do not create a third evaluator.

## 7. Ranking

Use semantic precedence classes before local score/order hints:

1. `BRANCH_CONTINUATION` — required/current flow continuation or direct answer
2. `DIRECT_RESPONSE` — directly responds to the latest NPC act
3. `CONTEXTUAL_SOCIAL` — contextually relevant social/relationship reply
4. `ACTIVE_TOPIC` — relevant questions/continuations for current topic
5. `GAMEPLAY_ACTION` — companion/trader/quest/action choices relevant now
6. `GENERAL_TOPIC` — broad optional conversation topics
7. `UTILITY` — leave/back/system utilities

Within a class, rank deterministically by provider relevance, context fit, authored order and stable ID tie-break. Avoid global priority-number wars.

## 8. Localization and realization

### Stable semantic ID

Never translated:

`social.ask_wellbeing`

### Label

UI description, translated separately:

`choice.social.ask_wellbeing.label`

### Utterance

Natural spoken/player text, translated separately:

`choice.social.ask_wellbeing.utterance`

### Realization families

A semantic choice/response may reference a small realization family:

```text
question.wellbeing
  neutral
  warm
  terse
  guarded
```

Variant selection is driven by SpeechStyleContext, but all variants preserve the same semantic frame.

Each language owns whole phrases. Do not build grammar by concatenating translated lexical fragments. Dynamic names/items use typed arguments/placeholders through the existing translation manager.

If a requested style variant is absent in the current language, fall back deterministically to the family's neutral/base key and record a diagnostic fallback; never change semantic meaning.

## 9. Existing click/action path

Keep:

```text
candidate
  -> localized presentation in Core choicesPart
  -> semantic_click_frame
  -> DialogueInput.SubmitSemanticFrame
  -> existing router/policy
  -> existing server/gameplay owner
```

No direct provider callback execution.

## 10. Dynamic Trading adoption

Trader is an orthogonal role/capability, not a mutually-exclusive NPC type.

Dynamic Trading should contribute:

- trader-role/read-only trade context;
- trader-specific choice definitions/providers;
- trade-specific click frames/routes that still enter existing approved authority;
- translation keys under its own namespace/catalog where appropriate.

Hoomans/Core must not persist a copy of Dynamic Trading trade state.

## 11. Semantic Lab

The existing Semantic Lab is the only harness.

Required Persona/Choice simulator controls should be generated/adapted from production registries where possible:

- identity/gender combobox where authoritative/public;
- role toggles/comboboxes (companion, owned, trader, etc.) mapped to real adapters;
- trait multi-select from real trait registry;
- personality enum controls + numeric sliders;
- relationship approval/respect/familiarity sliders;
- derived relationship state shown read-only using production logic;
- health/activity/situation controls using existing scenario fields;
- EN/TL language switching.

Inspector must show:

- canonical ActorConversationContext;
- derived SpeechStyleContext + safe trace;
- candidate source/provider;
- conditions/visibility/eligibility;
- ranking class and tie-break;
- selected realization family/variant;
- label + utterance translation keys and resolved strings;
- canonical semantic frame;
- click receipt and existing dialogue/action result.

Add bounded A/B comparison and/or context-matrix execution against the real Lua worker. Matrix generation is diagnostic, not persisted per-NPC state.
