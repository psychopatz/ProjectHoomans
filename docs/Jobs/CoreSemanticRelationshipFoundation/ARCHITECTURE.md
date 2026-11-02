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

## 8. Persistence ownership

Core persists canonical actors/base social state and adopter extension envelopes.

Dynamic Trading persists merchant stock/budget/market state separately.

Hoomans persists Hoomans-owned world/gameplay state separately.

No cross-mod save routine directly edits another owner's internal schema.

## 9. Performance

Registration happens at bootstrap/capability activation.

Conversation work is request/event driven. Relationship reconciliation happens on explicit migration/import or actor load boundaries. There is no global per-tick semantic/relationship convergence pass.
