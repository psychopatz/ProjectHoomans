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


---

# P9 UI / conversation-routing audit — 2026-10-22

**User evidence:** Semantic Lab Simulation and Studio screenshots supplied 2026-10-22.  
**Remote source baseline inspected:** ProjectHoomans main at `81f4fb982ff5f65024ec9003d1a0a6f08ea7d1f4`.

## Verdict

P8 persona/bond/provider infrastructure is materially implemented, but the Semantic Lab remains hard to use for actual conversation testing and one authored-category path is semantically redundant.

The P8 READY FOR USER LIVE TEST claim is superseded by P9.

## Verified routing defect

Current semantic recognition correctly maps reviewed What's Up aliases to:

```text
intent     QUESTION
subject    CONVERSATION_TOPIC
topic      whats_up
categoryID projecthoomans:whats_up
route      conversation_category
```

The existing `DialogueInput.SubmitSemanticFrame` category branch already routes this canonical frame to `Composer.RequestCategory`.

However, ordinary typed input does not enter that category route immediately. Current tests explicitly expect a second `conversation.whats_up` suggestion after `worker.input("whats up")`, then click that suggestion to enter the authored block.

This matches the user-visible screenshot:

```text
PLAYER: whatsup
NPC: Let me think about that.
[ Ask what's up ]
```

The nested second step is therefore current intended-by-test behavior, not a screenshot-only rendering artifact.

## Verified authored branch structure

`30_PNC_ConversationWhatsUp.lua` already defines five authored nodes:

- opening
- details
- personal
- followup
- closing

with gated choices, weighted outcomes, relationship effects, and root exits.

The production block projection deliberately exposes only the current node and choices. This is appropriate for normal player-facing semantics but inadequate for developer branch visualization.

## Verified graph reuse opportunity

Studio already contains a capable Tk graph surface through `FlowEditorPane`, `FlowEditorCanvasController`, and the graph-model helpers.

Existing capabilities include:

- zoom;
- pan;
- fit;
- internal/exit edges;
- labels;
- node selection;
- detail/compact/overview rendering;
- scroll region;
- draggable Flow-editor nodes.

The renderer currently consumes normalized semantic Flow definitions, not authored ConversationBlocks.

P9 should refactor/adapt this existing renderer rather than create a parallel graph UI.

## Verified Simulation UX problem

Current Simulation devotes substantial primary space to raw semantic trace JSON while the full authored branch structure is invisible.

The suggestion surface also shows group selection through a combobox even when only one group is relevant. With the current What's Up route this contributes to the visible nested pattern:

```text
What's up group
 -> Ask what's up
```

Branch continuation should become the visually primary surface while a block is active.

## Translation-content finding

Source review also found mixed-language TL strings in existing What's Up authored content. Examples exist in survivor-rumor and supply-pressure bundles.

These are content defects and should be surfaced by P9F diagnostics. They are not the root cause of the semantic routing defect and should not be used to justify another parser or translation backend.

## Corrective direction

The mandatory sequence is now P9A-P9G as documented in `SEMANTIC_LAB_CONVERSATION_VISUALIZATION.md`.

The first user-visible checkpoint is P9B: direct What's Up routing plus a real full branch graph visible in Simulation.


---

# P10 live UI / semantic-hub audit — 2026-10-23

**User evidence:** current Semantic Lab Simulation and Mock runtime screenshots.  
**Source baseline audited:** ProjectHoomans remote `main` implementation at `86cbfb38bb7aa7d87608d9dd2963255c91244f87`.

## Verdict

P9 mechanics are materially implemented, but the product remains incomplete.

The P9 READY FOR USER LIVE TEST conclusion is superseded.

## Verified UI findings

### Raw JSON is intentionally the default inventory editor

`tools/semantic_harness/ui/dialogs/settings.py` constructs two editable `ScrolledText` inventory panes, labels them as complete JSON projections, and parses them through `json.loads()` on Apply.

This is not an accidental debug surface. It is currently the normal editor.

### Known bounded world values still use free text

The same settings implementation sends:

- hunger;
- thirst;
- fatigue;
- stress;
- boredom;
- panic;
- timeOfDay;
- worldAgeHours;
- zombieKills

through the generic text-field helper. The UI text itself acknowledges that the first six are game-style 0–1 values.

Persona/relationship sliders exist, but only inside the modal settings dialog.

### Dynamic catalogs are partial

The worker `PERSONA_CATALOG` exposes traits, relationship kinds, social-style values and numeric personality dimensions, but no general typed scenario-control catalog exists.

The role list is still hard-coded by the worker.

Therefore the current UI is a mixture of production-derived options and Python/manual field definitions, which explains its inconsistent control types and error-prone normal workflow.

## Verified What's Up findings

P9 changed reviewed What's Up aliases from a redundant second-click route into direct entry of the old authored category.

Current tests now explicitly require:

```text
whatsup
 -> projecthoomans:whats_up
 -> old authored ConversationBlock
```

and explicitly assert that WELLBEING, ACTIVITY and GOSSIP remain distinct from What's Up.

This contradicts the current approved product direction.

The semantic system already has separate authoritative semantics/providers/facts for wellbeing, needs/medical, activity, gossip and other contextual domains. What's Up should aggregate eligible **avenues** from those owners instead of owning one obsolete authored category.

## Legacy removal decision

The user explicitly requires removal of the old What's Up implementation to avoid confusing the codebase.

P10 therefore forbids keeping `projecthoomans:whats_up` as a hidden fallback or compatibility category.

Known live integration points include:

- Conversation category registration;
- `30_PNC_ConversationWhatsUp.lua`;
- SemanticTopicCatalog authored-category mapping;
- reviewed pattern/compiler source and generated artifacts;
- `conversation.whats_up` static suggestion definition;
- central suggestion special-cases;
- worker category/preflight fallback;
- category translations;
- authority/conversation/compiler/harness tests using old IDs.

Useful dialogue text can be migrated only under a new correct semantic owner/ID.

## Graph-history finding

P9's graph pane is valid while an authored ConversationBlock is active, but `set_graph(None)` clears the pane after a branch exits to root. This is technically consistent with active runtime state but poor developer UX.

P10F therefore retains the last completed graph snapshot in harness presentation state only.

## Corrective direction

P10 is now the active product phase:

1. remove the legacy What's Up category completely;
2. replace it with a provider-driven semantic hub;
3. add a typed Simulation Control Catalog;
4. make structured editors the default and preserve JSON as Advanced mode;
5. expose high-frequency simulation dials inline;
6. retain completed graph history and show hub-provider diagnostics;
7. validate end-to-end usability before another READY handoff.


---

# P11 post-P10 runtime-parity / UX audit — 2026-10-23

**User evidence:** current Semantic Lab screenshots after P10 completion claim.  
**Source baseline audited:** ProjectHoomans remote `main` at `c412d50c27a423965911e115c0947b65c1eb2b6c`.

## Verdict

P10 implemented real hub/control/inventory infrastructure, but the final READY FOR USER LIVE TEST conclusion is premature.

The remaining product gap is no longer the What's Up hub. It is runtime parity and understandable interaction across the two actors, relationship progression, diagnostics, and graph coverage.

## Verified relationship-state behavior

Current production standing thresholds remain intentionally low-level/hysteretic:

- unfamiliar relationships remain `unknown` below familiarity 5;
- current `friend` standing enters at approval 35 / respect 15 after familiarity threshold;
- rival/enemy have their own entry/exit rules.

Therefore current `relationship.state=friend` cannot be reused as the requested durable "became a true friend" milestone.

P11 must add a separate durable milestone on the existing relationship record, not a new database.

## Verified personality generation

`PNC_SocialProfileGenerator.lua` deterministically generates socialStyle and numeric personality from identity seed/archetype, then existing trait effects/normalization modify it.

The normal harness should present this generated state by default and reserve direct numeric edits for explicit override mode.

## Verified romance foundations

Project Hoomans already owns:

- gender identity;
- player/NPC orientation/social-profile concepts;
- Gay/Bisexual-related player social traits;
- romanceStyle values including neutral/flirty/reserved;
- production gender/orientation compatibility math.

P11 should reuse these instead of adding a new romance compatibility system.

## Verified relationship persistence seam

The existing directed relationship record currently persists:

- approval/respect/familiarity;
- current/previous state;
- memories;
- cooldowns;
- interaction journal;
- revisions.

This is the correct persistence owner for a durable friend/lover/family milestone extension.

Do not create a separate bond table.

## Verified UI findings

The current Simulation still exposes primary controls whose code purpose is diagnostic/experimental:

- Preview;
- Snapshot;
- World Knowledge refresh;
- Restart worker;
- Persona Matrix;
- Capture baseline;
- Sweep.

`Sweep` is only an input to Persona Matrix's three-scenario comparison and is not self-explanatory.

The current graph projection is centered on ConversationBlocks, which explains blank/irrelevant graph behavior for semantic Flow interactions such as greeting.

## Corrective direction

P11 is now the active product phase.

Core corrections:

1. actor-centric Player/NPC/Relationship/World workbench;
2. first-class Player and NPC needs;
3. production trait catalogs for both actors;
4. generated NPC personality by default;
5. durable automatic friendship milestone around high relationship values;
6. romance eligibility from existing gender/orientation/traits;
7. explicit player proposal and server-authoritative NPC acceptance -> lover;
8. no hypothetical normal relationship kinds;
9. replace Sweep/Persona Matrix with Compare;
10. unified Flow/Hub/ConversationBlock runtime graph;
11. keep speech realization modular as content grows.


---

# P12 state-origin / save-backed harness audit — 2026-10-24

**User evidence:** native Project Zomboid conversation screenshot plus current Semantic Lab screenshot.  
**Source baseline:** ProjectHoomans remote `main` at `73e1ac5d0e49045a4660f447296a4b99544b4f0f`.

## Verdict

Conversation routing and production-Lua reuse are now close to parity, but the normal Semantic Lab still begins from a synthetic state model.

The dominant remaining mismatch is **state origin**, especially relationship/social state and engine-derived values.

## Verified relationship mismatch

Current `SemanticAdapters_Identity.lua` reconstructs relationship behavior from scenario data:

- resolves state;
- reconstructs starting bond;
- performs the friend promotion gate;
- creates a harness social event;
- caches the result in `Runtime.relationships`.

The real mod persists a fuller directed relationship record including baselines, memories, cooldowns, interaction history, revisions and durable bond.

P12 therefore replaces relationship reconstruction with import of the actual saved relationship into an isolated production-normalized worker record.

## Verified save-reader foundation

PsychopatzCore already provides a read-only Build 42.20 `global_mod_data.bin` parser through `tools/profiler/moddata_reader.py`.

Known Project Hoomans persisted roots include:

- `PNC_Core_Global`;
- isolated `PNC_npc<ID>`;
- `PNC_PlayerCharacters`.

This is sufficient to begin save-backed actor/relationship discovery without launching Project Zomboid.

## Engine-state decision

Project Zomboid does not need to remain active.

Current engine-derived harness values such as needs/time/weather may remain explicit offline fixtures until a proven offline reader exists.

Optional live profiler integration is useful only as read-only enrichment and must not become a runtime dependency.

## Safety decision

Save/live sources are immutable inputs.

All semantic/gameplay mutations occur only in a detached working copy.

This includes:

- relationship changes;
- friend/lover transitions;
- recruitment;
- factions/communities;
- knowledge;
- inventory;
- quest/tool effects.

No harness mutation may write back to the save or running game.

## Product direction

P12 — Save-Backed Offline Semantic Runtime — is now the primary Semantic Lab architecture.

Synthetic scenarios remain test/developer fixtures, not the normal product model.


---

# P13 operational usability audit — 2026-10-24

**User evidence:** current Semantic Lab screenshot after P12 completion.  
**Implementation baseline audited:** ProjectHoomans remote `main` at `dbfd9099a0b687bc2f6505f58e81e32ea6dc5966`.

## Verdict

P12 save-backed runtime/backend work is materially implemented, but the normal GUI is not yet an operational primary testing surface.

The prior P12 product-complete conclusion is therefore narrowed to backend/runtime foundation complete.

## Verified save-browser defect

`tools/semantic_harness/ui/shell.py` renders the complete save workflow in a single horizontal `Saved world · read-only source` row:

- Save combobox;
- Discover saves;
- Player combobox;
- NPC group combobox;
- NPC combobox;
- Inspect;
- Import target.

The normal left-pane geometry compresses these controls so severely that the save selector can be effectively unusable even after discovery succeeds.

The user screenshot shows the status:

```text
8 validated save(s); choose one and Inspect.
```

while the save selector is not practically browsable.

## Verified backend state

The backend itself is real:

- `SaveCatalog` discovers compatible saves;
- `SemanticStateCatalog` projects Core/Hoomans/DynamicTrading state;
- `SavedWorldBrowser` returns Players, actors, factions, communities and provider actors;
- `SaveBackedImporter` imports selected Player/NPC state into the isolated worker.

Do not replace these owners.

## Verified actor grouping limitation

`SavedWorldBrowser` currently constructs flat categories:

- All NPCs;
- Companions;
- Colonists;
- Followers;
- Neutral NPCs;
- Hostile NPCs;
- Known Traders.

Factions and communities are returned separately.

There is no faction/community -> member actor hierarchy for the UI to navigate.

## Verified UI-test limitation

Current P12D GUI coverage primarily checks that save-browser controls and Provenance tabs exist.

This does not prove that the user can:

- choose a save;
- choose a Player;
- browse a faction;
- choose an NPC;
- import the pair;
- start Talk

at realistic geometry.

P13 requires interaction acceptance.

## Verified Player inventory limitation

`SaveBackedImporter` reads `player_record.inventory` only when such a supported dict exists.

`PNC_PlayerCharacters` is primarily the persistent Player identity/social registry, not the authoritative Project Zomboid physical Player inventory store.

Therefore a normal save-backed Player inventory can legitimately report:

```text
source = MISSING
```

P13 must audit and add a separate read-only engine Player-state provider rather than invent saved inventory.

## Product direction

P13 — Operational Semantic Test Workbench — is now mandatory.

First visible chunk: P13A World Browser UX.

Later P13 chunks add:

- offline Player inventory/state provider;
- symmetric Player/NPC inspectors;
- faction/community workbench;
- production gift verification;
- agent-grade CLI parity;
- real operational acceptance.

The goal is to make Semantic Lab the normal semantic/conversation verification environment for humans and coding agents while leaving native PZ as user-owned final live acceptance.


---

# P14 production rehydration audit — 2026-10-24

**User evidence:** real save-backed Semantic Lab screenshots using a hostile raider/faction target.  
**Source baseline audited:** ProjectHoomans remote `main` at `d3c6c2018b4a074bdf6178b7f060f18832ed2344`.

## Verdict

P13 made Semantic Lab operational, but a remaining parity defect exists below the UI:

> the harness still interprets portions of Project Hoomans persisted gameplay state in Python rather than executing the production Lua persistence/runtime owners.

This can make the harness operationally convenient while still diverging from the real mod whenever the persisted schema changes or uses compact production representations.

## Verified hostile-raider behavior

The hostile Talk choices are correctly driven by tactical hostility.

A hostile NPC does not necessarily have a persisted personal NPC→Player relationship.

Therefore:

```text
personal relationship = unknown/MISSING
tactical hostility = hostile
conversation audience = hostile
```

may be valid.

Do not auto-create a personal enemy relationship.

## Verified false NPC-inventory MISSING

Project Hoomans inventory persistence supports compact modes including `SEED_ONLY`, `BASELINE_DELTA`, and `FULL`.

The current Python importer only recognizes an already-expanded inventory/items shape.

A valid compact persisted NPC inventory can therefore be falsely exposed as MISSING.

This should be fixed by invoking production Lua inventory/persistence rehydration, not by reimplementing deltas in Python.

## Verified faction-context omission

The save-backed provider imports useful faction identity/membership but does not yet preserve enough production diplomacy state to resolve the selected Player's faction/provisional diplomacy relationship against the NPC faction.

This can produce MISSING faction standing even when the save contains directed diplomacy data.

## Architecture conclusion

The harness should behave as:

```text
Python
    transport/isolate/present
        ↓
production Lua
    deserialize/normalize/derive/mutate
```

Only Project Zomboid engine-owned boundaries should be fixtures.

This becomes the P14 governing invariant:

> **Fixture the engine, never fixture the mod.**

## Future object semantics

The user's future plan to build a world-object/item dataset for commands such as "stand near the garbage bin" is compatible with this architecture but is explicitly out of P14 scope.

That future dataset should enter through an engine/world provider boundary and feed the same production semantic/action code, not become another parallel behavior implementation.
