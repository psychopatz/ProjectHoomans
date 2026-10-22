# P10 — Semantic Simulation UX & Contextual Conversation Hub

**Status:** ACTIVE / mandatory corrective product phase  
**Opened:** 2026-10-23  
**Audit baseline:** ProjectHoomans remote `main` at `86cbfb38bb7aa7d87608d9dd2963255c91244f87`.  
**Native Project Zomboid SP/MP:** user-owned and not required for developer-side P10 acceptance.

## Why P10 exists

P9 fixed the literal second-click defect and added reusable ConversationBlock graph tooling, but the current user-facing Semantic Lab still fails the intended product in two important ways:

1. the Simulation state editor is developer-internal and error-prone:
   - known bounded numeric values such as hunger/thirst/fatigue/stress/boredom/panic are plain text entries;
   - inventory editing uses raw JSON as the default editor;
   - Persona sliders exist but are buried inside a modal;
   - only part of the UI is dynamically catalog-driven;
2. `What's up` is still modeled as the old authored `projecthoomans:whats_up` Conversation category instead of a contextual semantic hub that presents appropriate avenues such as wellbeing, needs, medical, gossip, activity, world/event information, relationship-specific talk, trader talk, quests, and other provider-owned choices.

P10 corrects the product model. It is not another parser or conversation engine.

## Mandatory legacy removal decision

The old authored What's Up category is **removed**, not retained as a hidden fallback, compatibility category, renamed category, or secondary route.

Legacy identifiers to eliminate from production behavior include:

```text
projecthoomans:whats_up
conversation.whats_up
topic/category route whose destination is projecthoomans:whats_up
projecthoomans:whats_up_* authored block IDs
```

The old `30_PNC_ConversationWhatsUp.lua` authored block family must no longer register production blocks.

Known legacy integration points that must be audited and removed/migrated include at least:

- `common/.../Conversation/Definitions/10_PNC_ConversationCategories.lua`;
- `common/.../Conversation/Definitions/30_PNC_ConversationWhatsUp.lua`;
- `PNC_SemanticTopicCatalog.AUTHORED_CATEGORY_TOPICS`;
- reviewed What's Up patterns and generated dialogue artifacts that emit `conversation_category/projecthoomans:whats_up`;
- `PNC_SemanticDialogueSuggestions_StaticProvider.lua` definition `conversation.whats_up`;
- central suggestion special-cases for `conversation.whats_up`;
- worker `Conversation.lua` What's Up category/preflight helpers;
- category translations such as `category.whats_up` when no longer used;
- tests that require `projecthoomans:whats_up`, `conversation.whats_up`, or old block IDs;
- old progress/architecture assumptions that claim specific WELLBEING/ACTIVITY/GOSSIP routes must remain separate from What's Up.

Do not preserve these identifiers merely so old tests stay green. Replace those tests with the new hub contract.

If useful authored text from the old local-activity/supply-pressure/survivor-rumor blocks remains valuable, migrate/re-author it under the correct semantic provider/response owner with **new IDs and ownership**. Do not retain the old What's Up category/block namespace as a compatibility shell.

## New What's Up meaning

`What's up?`, reviewed aliases, and the root What's Up navigation choice become one semantic **hub activation**, not an NPC-authored ConversationBlock.

Conceptual canonical frame:

```lua
{
    intent = "QUESTION",
    speechAct = "QUESTION",
    subject = "CONVERSATION_TOPIC",
    extensions = {
        topic = "whats_up",
        route = "semantic_hub",
        hubID = "whats_up",
    },
}
```

Exact field names may be adjusted after implementation audit, but the contract must remain:

```text
What's Up
 -> activate contextual hub
 -> collect provider-owned semantic avenues
 -> rank/filter from authoritative current context
 -> player selects one real semantic choice
 -> selected choice enters its existing semantic / authored / addon-owned route
```

Hub activation is a presentation/navigation boundary. It does not own gameplay effects, gossip facts, trade state, quest state, relationship mutation, or authored branch state.

## Contextual hub examples

A neutral survivor may expose:

```text
How are you doing?
What have you been up to?
Heard anything lately?
What's happening around here?
```

An owned companion may additionally expose:

```text
Do you need anything?
Are you hurt?
Anything bothering you?
```

A family member or lover may expose deeper relationship-appropriate social avenues when current standing and disclosure rules allow them.

An injured NPC should strongly rank `Are you hurt?`.

An NPC with severe needs may strongly rank `Do you need anything?`.

An NPC with safe player-visible gossip context may expose `Heard any gossip?` or a more specific reviewed topic.

A Dynamic Trading merchant may contribute trader-owned avenues such as `How's business?` without Project Hoomans copying trade state.

A quest-capable context may expose a quest-owned conversational avenue through the same hub provider contract.

Not every NPC receives every choice.

## Hub provider architecture

Reuse the existing DialogueChoiceRegistry/provider architecture.

Target conceptual providers include:

- wellbeing / check-in;
- needs;
- medical;
- activity;
- gossip;
- local/world-event context;
- relationship/bond social depth;
- Dynamic Trading;
- quests/commitments;
- other registered addon/domain providers.

Do not create one giant `if hub == whats_up then ...` table.

Providers should contribute canonical candidates with:

- stable ID;
- label/utterance translation keys;
- typed semantic frame;
- semantic/rank class;
- visibility/eligibility result;
- safe reason/trace metadata;
- optional hub membership metadata such as `hubs = { whats_up = true }`.

The hub collector must use current `ActorConversationContext`, safe semantic context, world/event facts, current relationship/bond/personality, health/needs, and addon availability. It must not scan or persist unrelated world state solely for menu generation.

## Simulation Control Catalog

P10 also replaces field-by-field Python UI ownership with a typed worker-provided simulation-control schema.

The worker should expose a bounded catalog describing editable scenario fields.

Conceptual entries:

```lua
{
    id = "world.hunger",
    section = "Needs",
    label = "Hunger",
    control = "slider",
    valueType = "number",
    min = 0,
    max = 1,
    step = 0.05,
}
```

```lua
{
    id = "npc.healthState",
    section = "NPC",
    label = "Health",
    control = "combobox",
    valueType = "enum",
    options = { ...production-backed values... },
}
```

```lua
{
    id = "persona.traits",
    section = "Persona",
    control = "multi_select",
    optionsProvider = "npc_traits",
}
```

Supported control kinds should remain small and generic:

```text
slider
integer / spinbox
combobox
boolean
text
multi_select
searchable_catalog
structured_collection
read_only
advanced_json
```

The catalog is a UI metadata contract over the existing scenario/configure boundary. It is not a second source of gameplay truth.

## Structured-first, raw-JSON-preserved editing

Raw JSON remains supported as an explicit advanced/debugging surface.

Default mode must be structured.

For data currently edited as complete JSON, use:

```text
[ Structured ] [ Advanced JSON ]
```

Both views edit the same scenario draft.

Advanced JSON remains useful for malformed-data tests, unsupported future fields, exact fixtures, and debugging, but normal users must not need to know internal JSON shape to simulate ordinary state.

## Inventory editor contract

The current Player/NPC inventory raw JSON editors are not accepted as the normal UX.

Add a worker-backed bounded item/catalog projection appropriate for harness simulation.

Normal inventory workflow should support:

- search/select a registered/fullType item;
- add/remove item;
- quantity/stack;
- condition where applicable;
- container/location where supported;
- equipment flags where supported;
- important custom state where supported;
- read-only derived MarketSense/metadata where available;
- optional advanced per-item fields;
- Advanced JSON fallback for the whole projection.

Do not make Tk duplicate Project Zomboid item-definition policy. The worker/runtime catalog owns available item identity and default metadata.

## Inline Simulation workbench

The most frequently changed semantic dials must be reachable without reopening a modal for every comparison.

Simulation should gain a compact/collapsible workbench for at least:

- NPC profile/role;
- bond kind/class;
- approval/respect/familiarity + derived state;
- social style;
- key personality dimensions;
- health/activity;
- common needs;
- language;
- relevant integration toggles.

Support an `Apply + Replay` workflow against the current/recent test utterance.

The full settings dialog remains for uncommon and advanced fields.

## Conversation graph history

P9 currently clears the live ConversationBlock graph when a branch returns to root because no active graph is projected.

For developer testing, retain the last completed graph snapshot in Semantic Lab presentation state until:

- a new graph replaces it;
- the scenario resets;
- the user explicitly clears history.

This history is harness-only and must not be written to NPC ModData.

The completed graph should visibly preserve visited path and completion/root exit.

The new What's Up hub is not itself a ConversationBlock graph. The Lab should instead expose hub/provider diagnostics showing which candidates were offered/hidden and why. Once a selected hub candidate enters a real authored flow/block, the existing shared graph renderer may display that branch.

## Milestones

### P10A — Remove legacy What's Up category and establish hub contract

Required:

- source-audit every `projecthoomans:whats_up`, `conversation.whats_up`, old block ID, category translation, compiler constraint, worker helper, and test;
- delete/retire `30_PNC_ConversationWhatsUp.lua` production registration and the old category row;
- remove old topic-catalog/category routing;
- change reviewed What's Up patterns/compiler source to emit semantic-hub activation, not `conversation_category`;
- remove static `conversation.whats_up` candidate and central special-cases;
- remove worker hard-coded What's Up category/preflight helpers;
- delete/update tests that codify the legacy category;
- remove orphaned translations/assets after reference audit;
- add a stable hub frame/activation contract and tests;
- keep direct specific intents such as explicit `Are you okay?` and `Any gossip?` working independently.

**Gate:** repository search finds no live production use of `projecthoomans:whats_up`, `conversation.whats_up`, or old `projecthoomans:whats_up_*` block IDs; reviewed What's Up input activates `hubID=whats_up` and does not enter a ConversationBlock.

### P10B — Contextual What's Up hub MVP

Required:

- generic hub collection through the existing provider registry;
- at least wellbeing, needs, medical, activity, gossip, and safe general/world-context avenues where authoritative data exists;
- existing provider-owned trade/quest avenues may participate when installed/eligible;
- deterministic rank classes and dedupe;
- character/persona/relationship/health/needs/context-aware visibility and ordering;
- safe absence when data/provider is unavailable;
- no invented gossip/world facts;
- hub diagnostics in worker and Semantic Lab.

**Early user-test gate:** typing `What's up?` shows several appropriate semantic choices for a normal companion instead of opening an old authored block.

### P10C — Typed Simulation Control Catalog + dynamic world/persona controls

Required:

- add worker/catalog command for typed editable scenario controls;
- render known 0–1 needs as sliders with numeric values;
- render approval/respect/familiarity/personality as sliders from catalog metadata;
- render enum fields from catalog options;
- use integer/spin controls for integer fields such as zombie kills;
- use bounded time control for time of day;
- preserve validation through the existing scenario/configure path;
- no free-text normal editing for fields with known finite/ranged types.

**Early usability gate:** user can configure common world/persona/relationship state without typing numeric JSON/text values.

### P10D — Structured inventory editor + Advanced JSON

Required:

- worker-backed item/catalog projection;
- default structured Player and NPC inventory editors;
- searchable add/remove/edit workflow;
- typed quantity/condition/container/equipment controls where applicable;
- derived metadata displayed without requiring manual authoring;
- explicit `Advanced JSON` mode preserving the current full projection editing capability;
- round-trip structured <-> JSON without losing supported fields.

**Gate:** ordinary Bandage/food/inventory scenarios can be created without hand-editing JSON; advanced JSON fixtures still work.

### P10E — Inline simulation workbench + Apply & Replay

Required:

- compact/collapsible high-frequency controls in Simulation;
- no repeated modal open/apply/close cycle for persona tuning;
- `Apply` and `Apply + Replay` against the current/recent utterance;
- clear reset/preset behavior;
- production-derived relationship state updates visibly;
- hub choices refresh immediately after relevant context changes.

**Gate:** user can switch neutral companion -> injured family member -> trader-like context and replay the same What's Up input with visibly different hub choices/ranks without editing JSON.

### P10F — Hub/graph inspection history

Required:

- retain last completed ConversationBlock graph;
- display visited/completed path after return to root;
- hub diagnostics show provider candidate source, eligibility, rank, hidden reason, and final frame;
- selected hub child authored flows/blocks continue using shared graph renderer;
- no persisted game-state history.

**Gate:** after completing a branch the graph remains inspectable; a subsequent What's Up hub activation shows why each contextual option is present/absent.

### P10G — Final usability/regression gate

Required:

- repository-wide legacy What's Up ID absence checks;
- reviewed What's Up aliases -> semantic hub;
- explicit WELLBEING/GOSSIP/ACTIVITY/etc. parsing remains correct;
- neutral/companion/family/lover/enemy/trader matrices;
- health/needs ranking matrices;
- no private/secret candidate leaks;
- Dynamic Trading absent/present regression;
- quest/provider regression;
- structured editor and Advanced JSON round-trip tests;
- Tk/Xvfb real UI interaction at minimum + normal desktop sizes;
- graph history;
- EN/TL hub labels and semantic responses;
- Python, Lua, Kahlua, doctor, catalog validation, diff checks;
- no new ModData persistence for UI/hub state.

Only after P10A-P10G pass may the parent job return to **READY FOR USER LIVE TEST**.

## Hard invariants

Preserve:

- one semantic parser;
- one DialogueInput/click path;
- one DialogueChoiceRegistry/provider family;
- one translation backend;
- one Conversation Registry for actual authored blocks;
- one scenario/configure state owner in the harness;
- one shared graph renderer family;
- existing gameplay/addon authority boundaries.

Do not:

- retain the legacy What's Up category as a hidden compatibility route;
- create a second hub-specific parser;
- create random/baseless gossip;
- copy Dynamic Trading/quest/world state into Hoomans;
- let UI catalogs become gameplay authority;
- require raw JSON for ordinary simulation;
- remove Advanced JSON capability;
- persist Semantic Lab-only hub/graph history to game ModData.
