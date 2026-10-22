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
