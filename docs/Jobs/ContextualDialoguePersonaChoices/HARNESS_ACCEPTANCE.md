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


## P9 acceptance — live conversation graph and direct semantic routing

### Typed category parity

For a reviewed authored-category utterance such as `whatsup`:

- semantic recognition must preserve the canonical `CONVERSATION_TOPIC` frame;
- `route=conversation_category` must enter the existing category authority/composer path directly;
- no generic unknown-fact response may be inserted first;
- no redundant candidate for the exact same already-entered category may be shown;
- the root `Ask what's up` option remains valid before the category is entered.

The root button and typed utterance must converge on the same authoritative category path.

### Runtime conversation graph

Simulation must render the full selected authored ConversationBlock through a developer-only read projection while the normal current-choice projection remains bounded.

The graph must expose at least:

- all authored nodes;
- current node;
- visited nodes when available;
- localized NPC node text;
- localized player choice text;
- choice eligibility/lock state;
- possible outcomes and targets;
- root exits;
- canonical IDs available through inspector/tooltips.

The graph must not persist into NPC ModData.

### Shared renderer acceptance

Studio Flow Graph and Simulation Dialogue Graph must reuse common graph canvas/model rendering primitives.

Do not accept a second copy of node/edge drawing logic solely for conversation blocks.

### Live interaction acceptance

Currently valid graph branches may be interactive only by reusing the same current semantic click frame as the normal button.

Required equivalence:

```text
normal current-choice click
and
live graph branch click
```

must reach the same worker/DialogInput/Composer path and produce equivalent transport/results.

No UI code may directly mutate conversation node state.

### UI hierarchy

At normal Simulation use:

1. conversation transcript / NPC response;
2. live dialogue graph;
3. current player choices;
4. player input;
5. scenario/persona controls;
6. semantic inspectors;
7. raw worker JSON.

Raw JSON must remain available but must not occupy the most prominent default space at the expense of branch testing.

If there is only one semantic group, hide the group selector. If multiple groups exist, branch continuation must remain visually primary while a conversation block is active.

### Early user-test milestone

P9B is an explicit early usability checkpoint.

Before P9C-P9G polish is complete, the user must already be able to:

```text
launch Semantic Lab
type "what's up"
see the actual NPC opening
see the complete branch graph
see current choices match outgoing graph branches
click a normal current choice
watch current-node highlighting advance
```

Do not postpone this usable UI until the final P9 milestone.

### Conversation-content diagnostics

Graph node/edge inspection should expose source/translation keys and resolved values. Suspicious mixed-language or unresolved values should be visible as authoring diagnostics.

Content diagnostics must not alter semantic routing automatically.


## P10 acceptance — structured simulation UX and contextual What's Up hub

### No legacy What's Up runtime

P10 acceptance requires the old authored What's Up route to be gone from live production behavior.

The following must not be runtime dependencies:

```text
projecthoomans:whats_up
conversation.whats_up
projecthoomans:whats_up_*
```

Historical documentation may mention them as superseded evidence.

Reviewed What's Up input must activate a semantic hub and must not create/select a legacy ConversationBlock.

### Contextual hub behavior

The What's Up hub must be provider-driven and context-sensitive.

Required matrix examples include:

- neutral survivor;
- owned companion;
- family bond;
- lover bond;
- hostile/enemy context;
- injured NPC;
- severe needs;
- trader with Dynamic Trading present;
- Dynamic Trading absent;
- safe gossip available;
- gossip unavailable/private;
- quest/provider available vs unavailable.

The hub must expose only safe eligible avenues, rank them deterministically, and show bounded diagnostics for hidden/ineligible candidates.

Explicit semantic questions remain direct:

```text
Are you okay?     -> WELLBEING
Any gossip?       -> GOSSIP
Are you hurt?     -> medical/health
Need anything?    -> NEEDS
```

They must not require entering the What's Up hub first.

### Typed simulation controls

Normal editing must use appropriate control types:

- game-style 0–1 needs -> sliders;
- approval/respect/familiarity/personality -> sliders;
- integer values -> spin/integer controls;
- finite enums -> readonly comboboxes;
- booleans -> checkboxes/toggles;
- multi-values -> multi-select;
- derived state -> read-only labels;
- catalog objects -> searchable structured editors.

Validation remains owned by the existing scenario/configure path.

Normal use must not require manually typing JSON or remembering internal enum strings.

### Advanced JSON preservation

Raw JSON must remain available as explicit Advanced mode for:

- malformed fixture testing;
- unsupported future fields;
- exact scenario authoring;
- debugging.

Structured and Advanced JSON views must round-trip supported state without silent data loss.

### Inventory acceptance

Default Player/NPC inventory editing must be structured and searchable.

Minimum workflow:

1. search/select an available item/fullType;
2. add/remove;
3. edit stack/quantity;
4. edit condition/state where applicable;
5. edit container/equipment fields where supported;
6. inspect derived metadata;
7. switch to Advanced JSON and back without losing supported state.

### Inline tuning acceptance

High-frequency semantic dials must be reachable from Simulation without repeated modal reopen cycles.

Required interactive proof:

1. enter one test utterance;
2. change relationship/persona/world state;
3. Apply + Replay;
4. observe changed hub candidate set/order or realization;
5. repeat without leaving the primary Simulation workflow.

### Hub and graph diagnostics

When the active surface is the What's Up hub, diagnostics must show provider/candidate source, eligibility, rank, hidden reason and final semantic frame.

When a selected hub child enters a real authored flow/block, the shared graph renderer remains available.

After the authored branch returns to root, the last completed graph remains inspectable in harness presentation state until reset/replacement.

No hub/graph-history data may be written to NPC ModData.

### P10 final user-facing gate

A real Tk/Xvfb run at minimum and normal desktop sizes must prove that a non-programmer can:

```text
configure common NPC/world state using structured controls
 -> type What's up?
 -> see context-appropriate semantic avenues
 -> select a real avenue
 -> inspect resulting conversation/graph
 -> change a dial
 -> Apply + Replay
 -> observe deterministic contextual differences
```

A passing backend/provider test without this actual UI proof is insufficient.


## P11 acceptance — actor symmetry, relationship progression, and usable diagnostics

### Actor-centric primary workbench

Simulation must expose:

```text
NPC Target | Player | Relationship | World
```

with actor sub-surfaces:

```text
Overview | Needs | Personality & Traits
```

Both Player and NPC Target must be testable without opening unrelated modal tabs.

### First-class needs

Player and NPC need controls use actor-owned scenario state.

Required common controls:

- hunger;
- thirst;
- fatigue;
- stress;
- boredom;
- panic.

Normal new scenarios must not rely on `world.hunger/thirst/fatigue` as the owner of NPC or player needs.

Historical fixture compatibility may remain.

### Production traits and personality

Normal trait lists must come from production registries.

Player traits must feed the actual player social-profile resolver.

NPC traits must feed the actual NPC generated-personality pipeline.

Normal NPC personality values are read-only generated results until explicit override mode is enabled.

### Truthful relationship kinds

Normal UI must show only current production-supported authored family kinds and actual durable bond state.

Future/synthetic kinds belong in diagnostics/tests only.

### Dynamic friend acceptance

Test at least:

- below threshold remains no durable friend bond;
- crossing configured approval/respect/familiarity gate promotes to friend;
- promotion is server-authoritative;
- event/memory/revisions update;
- persistence round-trip;
- falling slightly below threshold does not erase friend;
- friend bond may coexist with rival/enemy standing later.

### Lover proposal acceptance

Test at least:

- orientation/gender compatible pair;
- incompatible pair;
- player Gay trait same-gender compatibility;
- player Bisexual trait compatibility;
- family exclusion;
- below relationship threshold proposal hidden;
- eligible friend proposal visible;
- Flirty vs Reserved affects acceptance policy;
- accept -> lover;
- reject -> friend + cooldown;
- repeated proposal during cooldown blocked;
- starting lover remains lover;
- server-authoritative deterministic/seeded acceptance evidence.

### Live relationship UX

While relationship sliders move, the UI must show production-derived preview standing and a concise reason when important thresholds dominate.

Show friend-promotion progress and romance/proposal eligibility.

Applied worker value and preview value must not be silently confused.

### Compare surface

Replace the user-facing Sweep/Persona Matrix/Baseline workflow with one understandable comparison surface.

A user must be able to choose an utterance and comparison dimension, define/accept comparison values, run the real worker, and see side-by-side outputs.

### Runtime graph

Required real examples:

- `hello` -> semantic Flow graph;
- `What's up?` -> semantic Hub graph;
- authored branch -> ConversationBlock graph.

All use the shared renderer/model family.

### Final human-style UX gate

A fresh user must be able to:

1. select Player traits;
2. select NPC traits;
3. inspect generated NPC personality;
4. adjust Player and NPC needs;
5. change approval/respect/familiarity and understand the preview standing;
6. see friend promotion;
7. inspect romance compatibility;
8. simulate a proposal when eligible;
9. type `hello` and see its Flow graph;
10. type `What's up?` and see the Hub graph/choices;
11. use Compare without knowing what Sweep means.

A passing backend suite without this real Tk/Xvfb interaction proof is insufficient.
