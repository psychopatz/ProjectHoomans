# Source Audit — Contextual Dialogue Persona & Choices

**Audit date:** 2026-10-22  
**ProjectHoomans remote baseline:** `765bc4076ab82ec2c1eca6ca52cef1c6bf177597`  
**Dynamic Trading remote baseline inspected:** `5b97302e39c482682f4fed0c083ad6764b9eee41`  
**Evidence scope:** remote source/docs through GitHub connector; no claim about the user's local dirty state and no native PZ run.

## Executive finding

The needed data is already present. The product gap is not another personality database or another reply UI. It is a clean **actor conversation context + speech realization boundary** and a more modular **choice registry/provider architecture**.

The existing suggestion system has strong foundations—typed semantic frames, fail-closed predicates/privacy, EN/TL keys, stale/replay protection, Core `choicesPart`, real Lua worker—but its static/capability catalogs and some topic mappings are still centralized inside `PNC_SemanticDialogueSuggestions.lua`. This will become a responsibility/coupling hotspot as social, relationship, trader, gossip, quest, knowledge and future modules add choices.

## Existing authoritative actor data

### Identity

Identity already owns persistent identity data, including the current gender representation used elsewhere for presentation/compatibility. This job must consume public identity projections rather than persist a semantic copy.

### NPC Traits

The NPC trait domain already owns discrete traits and public trait APIs/registries. Harness trait controls should enumerate real registered traits rather than maintain a Python list.

### Social Profile / personality

`docs/Systems/SocialProfiles.md` records the existing NPC personality model:

- orientation
- food preference
- romance style
- jealousy style
- social style
- compassion
- sociability
- forgiveness
- bravery
- materialism
- aggression
- loyalty

Numeric dimensions are persisted authoritative personality state. They should be projected into dialogue and converted to transient speech tendencies; do not persist derived speech dials.

### Relationships

`docs/Systems/Relationships.md` already provides directed:

- approval `[-100,100]`
- respect `[-100,100]`
- familiarity `[0,100]`
- relationship state with hysteresis (`unknown`, `neutral`, `friend`, `rival`, `enemy`)
- bounded memories and relationship revisions

Dialogue must preserve these dimensions rather than collapsing them into one relationship percentage.

### Roles and authority

The current Semantic Lab scenario already contains `actorAuthority.companion/owned/eligible`, health/activity state, traits, and relationship fields. Existing action/capability owners already decide whether companion commands are actually dispatchable.

Trader should be an orthogonal role/capability/context supplied by Dynamic Trading, not a mutually-exclusive `npcType` that replaces companion/relationship/faction state.

## Existing production semantic projection

`PNC_SemanticDialogueInput_ContextProjection.lua` already projects bounded conversation data including:

- NPC ID
- current client relationship projection and relationship state/trust
- player-scoped Knowledge projection
- gossip context
- semantic dialogue/context state
- current topic
- conversation block/root projections
- world context / selected engine facts
- dialogue situation
- semantic entity index

The missing architectural piece is one canonical actor/persona projection that systematically gathers identity, traits, social personality, relationship, roles and relevant situation for both response realization and choice policy.

## Existing choice/suggestion system

`PNC_SemanticDialogueSuggestions.lua` currently combines several responsibilities:

1. fixed semantic choice definitions such as wellbeing, needs, health, identity, time/date/weather;
2. fixed capability definitions for FOLLOW/STAY/WAIT_AT;
3. topic canonicalization/mapping;
4. translation resolution/cache;
5. candidate/source projection;
6. dynamic active-flow and response-plan branch offers;
7. authored Conversation block/root choice adaptation;
8. predicate/eligibility application;
9. frame reconstruction and click validation.

The dynamic flow/response-plan/conversation-root routes are already the strongest scalable pattern: they contribute typed choices and re-enter existing authority. Preserve them.

The static/capability definitions should move behind a registry/provider contract so new domains can register content without editing one central file.

## Existing choice safety and localization

The current system already separates:

- stable candidate IDs;
- typed `semantic_click_frame`;
- label key vs spoken/player utterance key;
- preflight visibility/eligibility vs click-time recheck;
- stale/duplicate receipts;
- private/secret/unknown fail-closed behavior;
- Core-owned native choice presentation.

These are required invariants.

Translation must remain complete-phrase key based. Do not concatenate independently translated word fragments. Dynamic values use typed translation arguments where supported.

## Existing condition infrastructure

Two relevant mechanisms already exist:

- suggestion predicates with typed `all/any/not`, equality/membership/comparison/existence operations and private/unknown handling;
- production ConversationRules condition families for trait, personality, relationship, relationship state, audience, time, history, etc., already reused by semantic flow gating.

Do not create a third condition language. During implementation, audit whether the suggestion predicate surface can safely delegate/converge on the established generic/public condition contract while preserving privacy/reason-code compatibility. If convergence would be riskier than bounded reuse, keep a thin adapter rather than duplicating domain reads.

## Harness state

`tools/semantic_harness/runtime/scenario.py` already has editable scenario fields for:

- actor authority
- traits
- relationship
- health/activity
- world needs/context
- language/runtime profile

Earlier harness work already established that scenario controls are only valuable when they reach the real production Lua projection. This job must extend that same scenario/worker/UI path—never a Python-only persona simulator.

## Dynamic Trading

Dynamic Trading already contains NPC-foundation / portable conversation adapter documentation and trader integration tests. The correct future seam is a Dynamic Trading **choice provider / trader-role context adapter** feeding the common contract, while Dynamic Trading remains owner of trade state and effects.

## Actual product gaps

1. centralized static/capability choice catalog will not scale cleanly;
2. no canonical bounded ActorConversationContext combines identity/personality/traits/relationship/roles/situation;
3. no deterministic derived SpeechStyleContext is shared by response realization and choice presentation/ranking;
4. choice ranking still needs semantic precedence classes so local numeric priorities do not create cross-domain priority wars;
5. realization variants/localization need an explicit family contract rather than multiplying semantic IDs;
6. Semantic Lab needs first-class persona/social controls and inspector output tied to production Lua;
7. Dynamic Trading trader choices need to adopt the same provider contract without duplicating semantics or persistent NPC state.


---

# Corrective audit — 2026-10-22

**Current ProjectHoomans main audited:** 849f1951ed1d3fd4b6f78aedc2525b25368a157e  
**Dynamic Trading provider audited:** 5db64cbcc764f035146f044fdc34e930ce47d7c8

The earlier P0-P7 evidence proves a stable foundation, not completion of the user-visible persona goal.

## What is genuinely implemented

- ActorConversationContext reaches production conversation/semantic projection.
- SpeechStyleContext derives warmth/formality/directness/verbosity/hostility/openness/deference from existing state.
- presentation-only realization preserves semantic response identity.
- EN/TL realization infrastructure exists.
- choice ranking classes exist.
- Dynamic Trading contributes an optional trader provider without copying trade state.
- Semantic Lab exposes persona controls and the real worker.
- the regression suites give strong evidence that these changes did not broadly break existing semantics.

## Product gaps found in current source

### Realization coverage is too narrow

PNC_SpeechRealization currently contains persona variants for greeting-opening template families only. Existing wellbeing, needs, medical, identity, knowledge, social, gossip, quest and trader responses usually calculate SpeechStyleContext but retain their old wording because no realization family exists for them.

The dedicated style test primarily sends hello, so it does not prove broad conversational tailoring.

### Some exposed dials are inert or weak

The current style resolver does not directly consume socialStyle, forgiveness, or bravery. Trait effects are limited to a hand-coded subset of names. The Lab therefore exposes more apparent speech controls than the runtime meaningfully uses.

### Relationship Lab parity is incorrect

The settings UI edits approval/respect/familiarity, but the worker reads relationshipState independently rather than deriving it through PNC.RelationshipStates.ResolveState. This permits impossible ordinary scenarios and violates the documented production-parity acceptance rule.

### Provider discovery is still partly centralized

DialogueChoiceRegistry is real, but PNC_SemanticDialogueSuggestions.Build still manually orchestrates most source families and explicitly calls the Dynamic Trading provider. Registering a new provider alone is not yet sufficient for generic participation.

### Persona-aware ranking is narrow

Context-fit rules currently cover only a small number of topic/situation/persona cases. The ranking architecture exists, but the intended social/relationship/gossip reply ecosystem has not yet been authored.

## Companion bond source found

Starting companion definitions already persist these detailed relationship kinds:

- friend
- lover
- mother
- father
- sister
- brother

The detailed kind is stored through the existing starting-companion generation/relationship path and appears in network startingRelationship projections. This is the correct authoritative source for pre-outbreak companion bond semantics.

The corrective design must derive friend/family/lover speech classes from this existing kind rather than adding another persisted relationship field.

## Corrected conclusion

P0-P7 should be treated as **accepted foundation with incomplete behavioral acceptance**.

The prior READY FOR USER LIVE TEST statement is superseded.

Current mandatory work is Roadmap P8 — Behavioral Completion.
