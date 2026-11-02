# Architecture — Core Semantic & Relationship Foundation

## Governing rule

**PsychopatzCore owns reusable mechanisms and shared actor/social truth. Adopters own domain content and gameplay policy.**

The target dependency direction is:

```text
                 PsychopatzCore
       actor + social + semantic runtime
                    ^
                    |
          registration / public APIs
           /                    \
          /                      \
Dynamic Trading              Project Hoomans
commercial/story pack        social/NPC/action packs
```

Core never imports either adopter.

## 1. Canonical actor and relationship authority

One person has one Core actor ID and one base social record.

```text
Core Actor
  id
  identity
  appearance
  personal inventory
  world/provider state
  social
    personality
    relationships[targetKey]
      approval
      respect
      familiarity
      memories
      revision
      extensions
```

Provider/body IDs are bindings to the Core actor, not alternative identities.

## 1A. Canonical player social target identity

Relationship target identity is also Core-owned.

A player character must resolve to the same persistent social target key whether the active adopter set is Core-only, Dynamic Trading, Project Hoomans, or both. Transient online IDs and username-only convenience keys may be lookup aliases, but they must not become competing canonical relationship identities.

Core must provide or own the durable target-key contract and alias/migration mechanism. Project Hoomans may contribute/migrate its existing persistent character UUID data, but Dynamic Trading cannot depend on Hoomans to resolve the key.

Legacy keys converge into the canonical key through an idempotent merge that preserves memories, scores and every adopter extension without double-applying events.

## 1B. Trusted identity adoption across optional adopters

Core-issued player-character identity must be adoptable by a later-installed Project Hoomans without being mistaken for an arbitrary untrusted modData claim.

The trust boundary is explicit:

- an arbitrary `PNC_CharacterUUID` string is not automatically trusted;
- a UUID previously issued/persisted by the canonical Core player-identity authority is eligible for bounded import/adoption into Hoomans' registry;
- adoption validates account/slot ownership and character status, creates the Hoomans registry record once, and preserves the exact canonical UUID;
- malformed, cross-account, dead, duplicate-live-binding, or otherwise conflicting claims remain rejected;
- the real `PNC.PlayerCharacters.EnsureIdentity/GetEntityKey` path must converge with Core/DT, not merely string formatting in tests.

A DT-first save followed by enabling Hoomans must therefore keep the exact same player target key.

## 1C. Authoritative identity issuance proof

Identity adoption trust must come from canonical Core authority, not from values that an arbitrary player modData payload can reproduce.

A deterministic public hash such as `hash(accountKey, uuid)` stored beside the UUID is an integrity marker only; it is not proof that Core actually issued the identity. Hoomans must not treat such a value as an authoritative issuance credential.

The accepted design must use a Core-owned issuance/identity registry or equivalent server-authoritative record that can answer whether a UUID/account pairing was actually issued/adopted by Core. The adoption check must therefore validate against Core authoritative state in addition to the player mirror.

Required properties:

- arbitrary modData cannot manufacture a new authoritative Core-issued identity by computing a public function;
- trusted Core-issued DT-first identities remain adoptable by Hoomans;
- existing Hoomans-first identities can be registered/adopted into the same Core authority without duplication;
- account/slot ownership, dead/retired status, and duplicate-live-binding safeguards remain intact;
- persistence/reload preserves issuance authority and adoption idempotence.

## 1D. Mirrors cannot bootstrap authority

Player modData mirrors are discovery hints only.

Core identity lookup must never convert an unknown `PNC_CharacterUUID` or other adopter mirror into an authoritative issuance record merely because the mirror exists. Otherwise an untrusted mirror can bootstrap itself into Core authority before the adopter validates it.

The allowed directions are:

```text
Core-generated identity
  -> Core authoritative issuance record
  -> player mirror
  -> later Hoomans adoption

validated Hoomans registry identity
  -> explicit Hoomans-to-Core registration/import
  -> Core authoritative issuance record
  -> shared mirrors
```

The forbidden direction is:

```text
unknown player mirror UUID
  -> Core GetCharacterUUID/GetTargetKey
  -> implicit RegisterIssuedIdentity
```

An adopter-first import must originate from that adopter's authoritative registry/service after its own validation, not from mirrored player fields.



## 2. Base relationship versus adopter extensions

Core owns shared values that must survive across mods:

- approval;
- respect;
- familiarity;
- bounded generic memories/events;
- stable target identity and revisions.

Adopters may add namespaced extensions:

```text
relationship.extensions.ProjectHoomans
  bond
  romance
  personal-boundary state
  Hoomans-only social interpretation

relationship.extensions.DynamicTrading
  commercial reliability
  fair-trade history
  credit/trade-specific trust metadata
```

An extension is owned and interpreted only by its mod. Core persists it without requiring that mod to be active.

Common social facts must not be duplicated inside extensions.

## 3. Semantic runtime versus semantic packs

Core owns generic runtime:

- semantic IR and normalization;
- concept/speech-act/pattern registration;
- candidate parsing/arbitration contracts;
- dialogue state/flow runtime;
- conversation lifecycle/context contracts;
- generic response-plan/realization extension seams;
- semantic pack/provider registration;
- diagnostics/manifest ownership metadata;
- generic relationship-aware context projection.

Adopters register packs.

### Dynamic Trading packs

May contain:

- trader/guard greetings and farewells;
- caravan history and journey stories;
- settlement/commercial facts;
- trader small talk and rumors;
- radio conversation;
- trade questions;
- relationship-aware commercial dialogue;
- trade/referral actions and eligibility;
- Dynamic Trading-specific context providers.

### Project Hoomans packs

May contain:

- richer social conversation;
- companion/NPC dialogue;
- identity/wellbeing/social content;
- Hoomans memories/knowledge;
- companion commands;
- task/inventory/camp/follow/stay actions;
- combat/cognition/faction/settlement actions;
- Hoomans-specific response/context providers.

## 4. Capability-gated actions

Shared semantic parsing must never imply shared gameplay capability.

An actor/session exposes capabilities such as:

```text
core.conversation
core.relationships

dynamictrading.trade
dynamictrading.radio
dynamictrading.commercial_info

projecthoomans.follow
projecthoomans.wait
projecthoomans.attack
projecthoomans.inventory
```

Only registered and eligible action providers may become executable choices.

With DT only, Hoomans commands must be absent, not merely disabled after selection.

## 4A. Semantic pack lifecycle

A pack is an ownership/lifecycle unit, not only a grouping label.

Core tracks every semantic registration owned by a pack: concepts, speech acts, patterns, context resolvers/flavors, dialogue blocks and action providers. Deactivation/unregistration must remove or disable the complete owned surface without leaving parser or dialogue residue.

Pack capability/activation requirements apply to all relevant semantic surfaces, not only executable actions. Inactive adopter content must not win parser arbitration or dialogue selection.

## 4B. Conversation capability propagation

Capability isolation must survive orchestration.

`PsychopatzActorConversationService` derives an effective conversation context and must propagate that context's capabilities into the parser/turn options used for semantic candidate selection. It is not sufficient for registry-level direct `Semantics.Parse` tests to gate correctly.

If a conversation has only Dynamic Trading capabilities, globally registered Hoomans grammar must not parse `follow me`, recruit, camp, or other Hoomans-only utterances. The same rule applies symmetrically to every adopter.

## 5. Hot-plug and removal model

### DT first, Hoomans added later

```text
Core+DT save
  actor A + relationship R
      |
install Hoomans
      v
same actor A + same relationship R
+ Hoomans extension/capabilities
```

No duplicate actor, rerolled identity or copied relationship.

### Hoomans removed later

Core keeps actor/base social state and opaque Hoomans extension payload. Dynamic Trading continues using the shared actor/relationship. Hoomans capabilities disappear because their provider is not registered.

Re-enabling Hoomans reactivates its owned extension after schema validation/migration.

The reverse installation order must behave symmetrically.

## 6. Migration contract

Legacy Hoomans/DT data is imported through explicit versioned migrators.

Each import stores:

- source owner;
- source schema/version;
- migration version;
- canonical actor target;
- migration marker/provenance;
- conflict/result status.

Rules:

- import once;
- retry safely after interrupted migration;
- never overwrite newer canonical state blindly;
- quarantine/retain unknown incompatible payloads;
- preserve inactive adopter extensions;
- fail visibly rather than reset.

## 7. Relationship event contract

Adopters submit authorized domain events to Core relationship authority.

Example:

```text
DynamicTrading fair trade
  -> DT determines commercial meaning
  -> Core relationship event (bounded shared deltas/memory)
  -> optional DT extension update

Hoomans rescue event
  -> Hoomans determines gameplay/social meaning
  -> Core relationship event
  -> optional Hoomans bond/memory extension update
```

Core never invents the domain meaning of a trade, rescue, insult or faction action.

## 7A. Core-first mutation rule

Adopters never replace the complete Core Social snapshot from an adopter-local cache.

Every shared relationship mutation operates against the latest canonical Core actor/social record through bounded event/patch APIs with revision/conflict handling. Adopter-local representations such as Hoomans `record.social` are projections or compatibility caches.

A Hoomans write may update shared fields through Core and its own `ProjectHoomans` extension, but it must preserve `DynamicTrading` data and unrelated memories. Dynamic Trading has the symmetric restriction.

Best-effort mirroring that can silently lose newer Core state is not an accepted authority boundary.

## 8. Persistence ownership

Core persists canonical actors/base social state and adopter extension envelopes.

Dynamic Trading persists merchant stock/budget/market state separately.

Hoomans persists Hoomans-owned world/gameplay state separately.

No cross-mod save routine directly edits another owner's internal schema.

## 9. Performance

Registration happens at bootstrap/capability activation.

Conversation work is request/event driven. Relationship reconciliation happens on explicit migration/import or actor load boundaries. There is no global per-tick semantic/relationship convergence pass.

## 9A. Evidence-grounded adopter dialogue

Adopter-owned story/whereabouts responses distinguish authored flavor from factual world claims.

Dynamic Trading may use authored flavor for greetings and generic atmosphere, but location, destination, route, settlement, trader whereabouts, origin, and current road-news claims must be derived from actual Dynamic Trading/Core world-knowledge evidence when presented as facts.

When evidence is unavailable, the response must be uncertain/unknown rather than inventing a named or implied route such as a fictional outpost or market. Parser coverage and response grounding are separate acceptance gates.

## 9B. Production evidence must originate upstream of TalkService

A factual answer is not considered end-to-end grounded merely because a test passes `destination`, `origin`, `settlement`, `npcGossip`, or `worldKnowledge` directly into `TalkService.Submit`.

Production state must first exist in a canonical Dynamic Trading/Core owner such as:

- trader policy/current route state;
- typed Core/DT WorldKnowledge facts with provenance;
- an authoritative settlement/route/trader-location service.

TalkService then projects that already-existing state into conversation context.

Tests for factual destination/origin/settlement/route/news must create the fact through the same upstream production API/path used by gameplay and then ask the question without injecting the expected answer directly into Submit options.

## 9C. Canonical place identity versus dialogue presentation

Dynamic Trading policy stores stable place identity, not presentation text.

A Hoomans community or other settlement may have a machine-stable ID such as `community_<...>` and a separate human-facing name. Conversation must not concatenate canonical IDs directly into player-facing factual text.

Use a bounded presentation resolver/knowledge projection:

```text
canonical settlement/community ID
  -> owning settlement/community/world-knowledge resolver
  -> human-facing known name
  -> dialogue realization
```

The resolver must preserve standalone DT operation. Project Hoomans may register/provide presentation for its community IDs when installed, but DTCommon must not import Hoomans internals.

If a stable ID is known but no safe presentation is available, dialogue should use bounded uncertainty or a generic description rather than expose an internal machine key.

## 9D. Travel lifecycle owns destination/origin transitions

Canonical factual route state must be updated by the actual gameplay lifecycle that knows the trip, not only by tests calling policy setters.

For Hoomans resident excursions, PREPARING/OUTBOUND/VISITING/RETURNING_HOME/AT_HOME transitions should maintain origin, destination and current settlement coherently. Standalone DT travel/excursion owners follow the same principle.

Persistence acceptance must serialize/reload the same canonical trader record/world-knowledge state used by gameplay before re-querying dialogue.
