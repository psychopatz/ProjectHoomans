# Semantic Lab Acceptance — Persona & Choices

The existing Semantic Lab is a first-class acceptance surface for this goal. Unit tests and generated JSON are necessary but insufficient.

## Production parity rule

Every editable Persona/Choice control must flow:

```text
Tk control
 -> existing scenario model
 -> existing worker protocol
 -> production Hoomans/Core Lua
 -> canonical ActorConversationContext
 -> production response/choice pipeline
 -> inspector/UI result
```

No independent Python evaluator may decide production relationship state, speech style semantics, candidate eligibility, translation or action authority.

## Required scenario controls

### Identity / roles

- identity/gender selector backed by supported authoritative representation;
- companion/owned/eligible controls mapped to existing actor authority;
- trader role/provider availability through the actual DT adapter once P5 exists;
- hostile/busy/dead/incapacitated situations through existing safe scenario projections.

### Traits

- multi-select from actual registered/canonical NPC trait set;
- unsupported/unknown trait cases remain testable;
- no static Tk-only duplicate trait catalog.

### Personality

Expose the existing Social Profile dimensions appropriate for runtime simulation:

- social style
- romance/jealousy/orientation only where required to test relevant eligibility/privacy;
- compassion
- sociability
- forgiveness
- bravery
- materialism
- aggression
- loyalty

Numeric controls should use the canonical runtime ranges.

### Relationship

Editable:

- approval
- respect
- familiarity

Read-only normal mode:

- derived relationship state from production state/hysteresis logic.

A dedicated advanced diagnostic may intentionally force malformed/inconsistent data only if clearly labeled and isolated from normal parity scenarios.

### Language

At minimum EN/TL using the existing translation manager and registrations.

## Required inspector

For each turn/click show bounded safe projections of:

1. input / latest NPC semantic act;
2. ActorConversationContext;
3. SpeechStyleContext and contributing reason codes;
4. all considered candidate providers;
5. candidate ID/family/group/source;
6. predicate/visibility/eligibility result;
7. rank class, local ordering and stable tie-break;
8. selected realization family/variant;
9. label key, utterance key, resolved label and utterance;
10. canonical semantic frame;
11. stale/replay receipt state;
12. resulting dialogue flow/response plan;
13. gameplay transport/action/result if any.

Private values must remain redacted.

## Mandatory scenario matrix

Preserve named fixtures and add bounded combinations covering at least:

- relationship: unknown/neutral/friend/rival/enemy or representative boundary values producing them;
- social/personality style: friendly/neutral/withdrawn or equivalent existing categories;
- role: companion vs non-companion, trader when provider available, hostile/non-hostile;
- traits: relevant positive case, absent case, unknown case;
- language: EN/TL;
- response: same semantic fact with materially different realization;
- choices: direct branch continuation must outrank generic topics;
- privacy: secret/orientation/backstory-sensitive facts do not leak;
- stale and duplicate semantic clicks;
- provider absent/disabled behavior;
- no-choice/unknown-context safe fallback.

Do not persist the full Cartesian product. Generate bounded diagnostic matrices and retain only useful fixtures/evidence.

## A/B comparison

The GUI should make it easy to hold the same utterance/semantic result constant while changing one or more actor-context dials. At minimum the acceptance suite must prove:

- friend vs enemy changes wording/choice ordering where authored policy says it should;
- friendly vs withdrawn personality can alter style without changing fact truth;
- changing gender alone does not arbitrarily alter warmth/aggression;
- trader role adds trade choices without erasing companion or relationship context.

## Localization acceptance

For every new realization/choice family:

- semantic IDs remain language-independent;
- label and utterance keys are distinct when their grammar differs;
- EN/TL resolve through existing registered catalogs;
- whole phrases are translated;
- typed placeholders are used for dynamic names/items;
- missing style variant falls back to the neutral/base key with a diagnostic;
- language switch does not change candidate semantic ID or action frame.

## Performance acceptance

Measure a bounded representative conversation loop. Verify:

- no semantic/personalization work per render frame;
- no all-NPC scan per conversational turn;
- provider counts/candidate counts/trace lengths are bounded;
- repeated unchanged context can reuse revision-aware projections where appropriate;
- no derived speech dials or candidate lists are serialized into NPC ModData.

## Final GUI proof

Use the existing application under Xvfb for developer evidence. Show at least one real scenario where moving a relationship/personality control changes the worker's derived context and final localized realization/candidate ordering, then click a candidate through the production path.

This does not substitute for user-owned native Project Zomboid SP/MP acceptance.


## Corrective P8 acceptance — companion bonds and real parity

### Relationship standing must be production-derived

Normal mode must edit only approval, respect and familiarity. The displayed state must be produced by PNC.RelationshipStates.ResolveState using the same current/previous-state semantics needed for hysteresis.

An independently editable relationship state is allowed only in a clearly separate malformed-data diagnostic mode.

### Companion bond controls

The Lab must query the production bond-kind metadata/catalog rather than own a Python list.

Required current kinds:

- friend
- lover
- mother
- father
- sister
- brother

Required derived classes:

- friend
- family
- lover

The UI should display:

~~~text
Bond kind
Bond class (read-only)
Localized reference term
Localized address term
~~~

Adding a future cousin or grandmother registry entry must make it available without adding Tk-specific code.

### Bond/standing matrix

Required cases include:

- friend bond + friend standing
- friend bond + rival/enemy standing
- mother family bond + friend standing
- mother family bond + enemy standing
- father family bond using the same family realization family
- at least one synthetic future kinship registration such as cousin or grandmother using the same generic family mechanism
- lover bond + warm standing
- lover bond + strained/rival standing
- ordinary companion with no special pre-outbreak bond

The matrix must prove bond remains stable while standing changes.

### Realization coverage view

The Lab inspector should report:

- semantic response family
- whether a persona realization family exists
- selected style variant
- selected bond class
- detailed bond kind
- localized term keys and values when used
- fallback reason when a family/style/bond combination is not authored

The authoring surface should make missing coverage obvious rather than silently looking complete.

### Interactive A/B workflow

The user must be able to compare the current utterance, not only a hard-coded hello.

Minimum workflow:

1. enter or reuse an utterance;
2. capture baseline;
3. clone to one or more comparison rows;
4. modify selected dials/bond/standing;
5. run all rows through the same Lua worker;
6. inspect final localized wording and candidate ordering.

Slider controls should show numeric values while editing.
