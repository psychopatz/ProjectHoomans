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


## 12. Companion bond is a separate conversational axis

Directed relationship standing and pre-outbreak companion bond are different concepts and must remain independent.

Conceptual actor projection:

~~~lua
actorConversationContext = {
    relationship = {
        approval = 70,
        respect = 60,
        familiarity = 100,
        state = "friend",
    },

    bond = {
        class = "family",
        kind = "mother",
        source = "starting_companion_trait",
        term = {
            referenceKey = "...",
            addressKey = "...",
        },
    },
}
~~~

### Bond classes

Only three coarse speech classes are required:

- friend
- family
- lover

Detailed kinds remain canonical data:

- friend
- lover / partner / spouse
- mother / father / sister / brother
- future cousin / aunt / uncle / grandmother / grandfather / other registered kinship

Do not persist bond.class separately. Derive it from the canonical relationship-kind registry.

### Why both axes matter

Examples:

~~~text
bond=family:mother + standing=friend
    warm family vocabulary

bond=family:mother + standing=enemy
    hostile/guarded tone, but still mother-specific vocabulary

bond=lover + standing=rival
    intimate history with competitive/strained present tone

no special bond + companion role + standing=friend
    ordinary friendly companion speech
~~~

Bond never forces approval/respect/state.

## 13. Relationship-kind vocabulary registry

Use a bounded declarative registry/metadata contract for speech-facing relationship kinds.

Each entry should describe at least:

~~~lua
{
    kind = "mother",
    class = "family",
    termKeys = {
        reference = "...",
        address = "...",
    },
}
~~~

Existing Starting Companion definitions must register or reference their relationship kind through this metadata. Adding cousin/grandmother/etc. later should require one registry row plus translations, not edits to the speech resolver.

The registry is metadata only. It does not own NPC persistence, relationship scores, recruitment, or starting-companion spawning.

## 14. Family term substitution

Family subtype variation belongs in localized terms rather than semantic IDs.

The speech realization layer may select a family realization family and bind:

~~~text
familyTerm
familyAddress
~~~

after resolving the detailed kind's translation term.

Sentence grammar remains a complete translated phrase. Do not concatenate translated sentence fragments.

If a language requires additional morphology, add a term form such as reference/address/possessive rather than multiplying semantic intent IDs.

## 15. Realization coverage contract

SpeechStyleContext is not accepted merely because it calculates numbers.

Maintain a coverage inventory from semantic response family -> supported bond/style variants.

A response family may declare:

~~~text
neutral only
neutral + warm
neutral + warm + terse + guarded
friend/family/lover variants
family term substitution
~~~

Unknown combinations fall back deterministically to the closest semantic-equivalent base phrase.

Acceptance requires representative normal conversation families beyond greeting, as defined in BEHAVIORAL_COMPLETION.md.

## 16. Provider registry as the discovery boundary

The target state is:

~~~text
Registry.List/Collect registered providers
    -> normalized candidates
    -> common eligibility/privacy
    -> dedupe
    -> common ranking
    -> common presentation/click frame
~~~

The central suggestions module may adapt legacy/root/flow sources, but must not need provider-specific calls for each addon/domain.

Dynamic Trading becomes the reference optional provider rather than a hard-coded special case.


## 17. Contextual semantic hubs are navigation, not authored categories

A semantic hub is a bounded contextual candidate-aggregation surface.

It is distinct from an authored Conversation category.

For What's Up:

```text
reviewed What's Up utterance/root navigation
 -> canonical semantic hub activation
 -> registered providers contribute safe candidate avenues
 -> common eligibility/dedupe/ranking/presentation
 -> selected candidate enters its existing semantic or authored route
```

The hub does not generate or own a ConversationBlock by itself.

The obsolete `projecthoomans:whats_up` authored category must not remain as a fallback.

Specific direct user intent remains specific. For example, `Any gossip?` routes directly to GOSSIP semantics rather than activating the general hub.

## 18. Hub membership belongs to providers

Providers should be able to declare or compute participation in a hub without adding provider-specific branches to the central collector.

Conceptually:

```lua
{
    id = "projecthoomans.gossip",
    hubs = { whats_up = true },
    collect = function(context) ... end,
}
```

The existing common registry still owns normalization/order/bounds.

Hub activation supplies the relevant hub ID/current context to collection; it does not copy provider state.

## 19. Simulation control metadata is a UI contract

The Semantic Lab should consume a bounded worker-provided control catalog describing normal editable scenario fields.

This metadata defines:

- control type;
- value type;
- range/step;
- option provider;
- section/group;
- label/help;
- read-only/advanced status.

It does not replace scenario validation or production gameplay state ownership.

Tk renders controls; the existing scenario/configure boundary remains authoritative for harness state.

## 20. Structured and Advanced views share one draft

Structured editors and Advanced JSON must edit one scenario draft.

There must not be separate structured-vs-JSON scenario owners.

The conversion contract is:

```text
scenario draft
  -> structured controls
  -> Advanced JSON view
  -> validation
  -> existing worker CONFIG/configure boundary
```

Unsupported/unknown fields must be preserved when round-tripping whenever safely possible rather than silently deleted by the structured editor.

## 21. Harness history is presentation-only

Completed graph retention and hub inspection history exist only to improve debugging.

They are not NPC memory, conversation memory, ModData, or semantic facts.

Reset/replacement may clear them without gameplay consequences.


## 22. Runtime-parity actor model

Semantic Lab Simulation treats Player and NPC Target as symmetric first-class actors.

Each actor owns, where production supports it:

- identity/gender;
- needs/conditions;
- traits;
- social profile/personality;
- role/capability state relevant to dialogue.

Shared conversation context owns:

- directed relationship;
- world/event context;
- active semantic flow/block/hub state.

Do not use `world.*` as the normal owner of actor-specific needs. Historical fixture compatibility may read old fields, but new scenario editing must author actor-owned needs.

## 23. Generated personality versus explicit override

NPC personality normally comes from the production path:

```text
identity seed
+ archetype
+ registered NPC traits
 -> SocialProfileGenerator
 -> trait effects
 -> normalized personality
```

Normal Semantic Lab presentation should therefore show generated personality as derived/read-only.

Manual personality sliders are an explicit override/debug mode and must use the same production normalization/override contract rather than bypass it.

Player social profile is likewise derived from actual player traits through the existing social-trait resolver wherever production does so.

## 24. Standing and durable bond are separate

Directed relationship standing remains:

```text
unknown / neutral / friend / rival / enemy
```

and is recalculated from approval/respect/familiarity using the existing state resolver.

Durable bond is persisted social history on the existing directed relationship record:

```text
none / friend / lover / family
```

Standing can change without automatically erasing durable bond.

Examples:

```text
bond=friend + standing=enemy
bond=lover + standing=rival
bond=family:mother + standing=enemy
```

This permits estranged/history-aware dialogue.

## 25. Family, friend, and lover authority

### Family

Family is authored/pre-existing and uses only kinds actually produced by the current game/mod.

Normal catalogs must not expose hypothetical future kinds merely because the registry can support them.

### Friend

Friend bond is an automatic relationship milestone derived from the existing directed relationship scores.

Initial tunable entry gate:

```text
approval >= 80
respect >= 50
familiarity >= 60
standing not rival/enemy
```

Crossing the gate creates a server-authoritative bond event/memory and updates the existing relationship record.

Friend bond does not oscillate with small score changes.

### Lover

Lover is an explicit relationship transition, never a passive score threshold.

Required layers:

```text
friend bond
+ relationship proposal thresholds
+ gender/orientation compatibility
+ player proposal
+ server-authoritative NPC acceptance
 -> lover bond
```

Existing gender/orientation/social-profile compatibility APIs are authoritative.

No separate romance matrix or gender-specific semantic action IDs.

Family is never romance-compatible.

## 26. Proposal acceptance policy

Proposal eligibility and acceptance are different.

Eligibility answers whether the proposal action may appear.

Acceptance is evaluated by the server using bounded production-owned inputs such as:

- approval/respect/familiarity surplus;
- romanceStyle;
- actual relevant traits such as Flirty/Reserved;
- current standing;
- proposal cooldown.

The acceptance implementation may use deterministic seeded probability, but never client-only uncontrolled randomness.

Acceptance promotes the existing relationship record from friend to lover and records a social event.

Rejection keeps friend and adds cooldown.

## 27. Relationship milestone persistence

Do not create a second bond database.

Extend/normalize the existing directed relationship record and persistence schema as needed.

Migration/versioning rules must be explicit.

Starting authored relationships may seed the milestone:

```text
starting friend -> friend
starting lover  -> lover
mother/father/sister/brother -> family + detailed kind
```

Relationship milestone mutations go through existing server relationship service/commit/revision boundaries.

## 28. Runtime dialogue graph adapters

Simulation graph uses one shared renderer over one generic view model with adapters for:

```text
semantic_flow
conversation_block
semantic_hub
```

The adapter reads real runtime state and never mutates semantic state directly.

Graph actions continue through normal semantic frames/click paths.

Hub graphs represent provider/candidate decisions, not invented ConversationBlocks.

## 29. Realization content packs

The speech-realization registry/resolver remains singular.

Built-in content should be registered from a small number of cohesive domain packs rather than accumulated indefinitely in the core resolver module.

The modularity boundary is content ownership, not one-file-per-string fragmentation.


## 30. Native Talk parity boundary

Talk classification and route selection are production concerns.

The canonical architecture is:

```text
native NPC entry + player
        ↓
production Talk-start projection
        ↓
target type / audience / safety / route
        ↓
conversation definition / opening state
```

Semantic Lab may construct a canonical entry from a scenario fixture, but once the entry exists it must enter the same production Talk-start projection.

Do not maintain a second harness-owned route/classification policy.

Normal production Talk target types are `colonist`, `follower`, `neutral`, and `hostile`.

Follower is derived from colonist ownership plus follow order.

`enemy` is a display alias only.

Trader is a capability/provider overlay and never a tactical Talk type.

Hostile inline behavior depends on the real integration availability. A headless harness must report missing inline support and exercise the production full-conversation fallback rather than inventing availability.


## 31. Save-backed state ownership

Semantic Lab now distinguishes:

```text
source snapshot
    immutable imported truth

working world
    detached mutable copy used by production Lua
```

Save files and live runtime snapshots are never mutation targets.

The working world may mutate freely through production services.

## 32. State provenance

Conversation-relevant state carries one source classification:

```text
SAVE
FIXTURE
LIVE
DERIVED
HARNESS_MUTATION
MISSING
```

Derived production values should be recomputed rather than copied when authoritative inputs exist.

## 33. Offline engine fixture boundary

Engine/transient state is not automatically equivalent to persisted mod state.

If no supported offline reader exists, Semantic Lab uses explicit fixtures for values such as needs/time/weather.

This does not make the fixture the gameplay authority; it is an engine stand-in.

## 34. Save-state provider boundary

Core owns low-level save decoding.

Each mod owns interpretation/projection of its persisted schema.

Expected providers include Core, Project Hoomans and Dynamic Trading.

Central Python must not become a registry of every adopter-owned field.

## 35. Optional live profiler boundary

Live profiler integration is a one-way observation channel.

It may enrich a copied snapshot with transient engine values, but it may not accept mutation requests from Semantic Lab.

## 36. Relationship parity

The harness must install the real saved directed relationship record into the isolated NPC/social record and use production relationship services for mutations.

SemanticAdapters must not duplicate friend-promotion, bond, proposal or relationship-state policy once P12C replaces the fixture path.
