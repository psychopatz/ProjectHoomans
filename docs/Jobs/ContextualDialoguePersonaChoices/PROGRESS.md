# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-23  
**Parent status:** P10A–P10G ACCEPTED — READY FOR USER LIVE TEST; native Project Zomboid SP/MP remains UNTESTED / user-owned.
**Current mandatory phase:** P10G — Final Usability + Regression (accepted).
**Implementation start checkout:** ProjectHoomans `main` at `b7c0d955d45156db9d38cd5b9ce88603ba900337`; the three requested repositories were on existing `main`, tracking upstream, clean, and not ahead/behind at audit time.
**Native Project Zomboid SP/MP:** UNTESTED / user-owned.

## Accepted foundation to preserve

P8/P9 delivered useful infrastructure that must not be discarded:

- production ActorConversationContext;
- friend/family/lover bond classes with detailed relationship kinds;
- production-derived relationship state in the Lab;
- persona-aware speech realization;
- generic DialogueChoiceRegistry/provider discovery;
- Dynamic Trading provider boundary;
- typed semantic click/stale/replay/privacy/authority paths;
- direct semantic-frame routing infrastructure;
- full ConversationBlock developer graph projection;
- shared Flow/Conversation graph canvas primitives;
- graph edge click parity with normal choice frames;
- EN/TL translation integration.

P10 changes the product composition above these foundations.

## 2026-10-23 live UI audit

User screenshots plus source inspection show the current P9 handoff is not product-complete.

### Simulation editing is still developer-internal

Current `tools/semantic_harness/ui/dialogs/settings.py`:

- renders hunger/thirst/fatigue/stress/boredom/panic/time/world age/zombie kills through generic text entries even where range/type is known;
- uses raw editable JSON as the default Player and NPC inventory UI;
- parses those editors with `json.loads()`;
- buries the real Persona sliders inside a modal;
- dynamically discovers only part of the UI schema;
- still has worker-side hard-coded option arrays such as roles.

Raw JSON must remain available, but normal state editing must become structured and catalog-driven.

### What's Up is still the wrong product model

P9 fixed the redundant second click, but current tests and code now intentionally require:

```text
input("whatsup")
 -> CONVERSATION_TOPIC
 -> projecthoomans:whats_up
 -> selected old authored ConversationBlock
 -> opening/detail/personal/followup/closing
```

The current test `test_specific_routes_remain_distinct_from_whats_up` explicitly keeps WELLBEING, ACTIVITY and GOSSIP separate from What's Up.

That conflicts with the approved product direction.

What's Up should be a contextual semantic **hub** exposing eligible avenues such as:

```text
Are you okay?
Do you need anything?
Are you hurt?
What have you been doing?
Heard any gossip?
What's happening nearby?
relationship-specific social avenues
Dynamic Trading-owned avenues
quest/commitment avenues
```

filtered/ranked for the actual character/context.

## Mandatory legacy removal decision

Do not preserve the old authored What's Up implementation as a hidden fallback.

P10 must remove live production use of:

```text
projecthoomans:whats_up
conversation.whats_up
projecthoomans:whats_up_*
```

Known references include category definitions, `30_PNC_ConversationWhatsUp.lua`, SemanticTopicCatalog, dataset/compiler patterns, generated patterns, static suggestion definitions, worker helpers, category translations and tests.

Useful old prose may be re-authored under the correct semantic provider/response owner with new IDs, but the old What's Up namespace and category must not survive as compatibility architecture.

## P10A — Legacy What's Up removal (accepted 2026-10-23)

Removed the authored What's Up category/block family, its 18 EN/TL audience bundles, category translations, topic-catalog authored mapping, static suggestion definition, category-specific suggestion visibility/preflight, and worker hard-coded preflight. Reviewed aliases now compile to `CONVERSATION_TOPIC` with `topic=whats_up`, `route=semantic_hub`, `hubID=whats_up`, and mapping state `WHATS_UP_HUB`; generation no longer emits the removed category route. Explicit WELLBEING, GOSSIP, NPC health, NEEDS, and ACTIVITY subjects remain direct.

Exact evidence:

- `python3 -m unittest tools.semantic_compiler.tests.test_dialogue_dataset tools.semantic_harness.tests.test_contextual_suggestions_whats_up tools.semantic_harness.tests.test_semantic_lab_npc_profiles tools.semantic_harness.tests.test_contextual_dialogue_persona_choices_p0` — 17 tests passed. Worker cases cover all 11 reviewed aliases, hub activation without a block/graph, and direct explicit semantics.
- `python3 tests/run_tests.py pnc_conversation_smoke pnc_conversation_authority_smoke pnc_server_conversation_command_handler_smoke pnc_relationship_debug_model_smoke --verbose` — 4/4 Lua suites passed. The smoke test emits the existing optional PsychopatzCore conversation-input warning; all assertions pass.
- Changed Python files passed `py_compile`; `luac5.3 -p` passed for changed production/test Lua; `pz-verify --kahlua --severity ERROR` scanned the 42.20 mod (2,968 files) with 0 errors/warnings; translation integration tests passed (2 tests); both remaining category catalogs parse as JSON; `git diff --check` passed.
- Repository search across `Contents`, `tools`, and `tests` returned no live exact references to the removed category/suggestion IDs, block family, or category translation key. The registry-absence test constructs the old category string in pieces. Historical docs retain superseded IDs as evidence.
- A broad full-mod `pz-verify --i18n` scan returned findings in 165 files; P10A introduced no new user-visible strings. Translation integration and registered-bundle checks pass; recheck the broad findings during P10G.

## Historical P10B work plan (completed 2026-10-23)

Continue on the existing `main` checkout. Build atop the registered `DialogueChoiceRegistry` providers and existing `semantic_click_frame`/DialogueInput path; do not add a parser, second suggestion engine, fake ConversationBlock graph, or duplicate addon state.

1. Trace the bounded provider/context contract and production owners for wellbeing, needs, health, activity, gossip, safe local/world context, bond/social depth, and Dynamic Trading. Use each owner's authoritative state and let registered domain providers contribute.
2. Add contextual contributions through existing providers. Gate friendly/private avenues using actor authority, hostility, relationship/bond standing, and disclosure policy. Do not invent gossip or expose secret/private information via candidate presence, labels, order, tooltip, or diagnostics.
3. Apply common eligibility/privacy, dedupe, rank, and localization through the existing candidate projection. Injuries should promote health; severe needs should promote needs; safe gossip should appear only with a safe context. Hostile NPCs must not expose friendly/private avenues.
4. Replace the single check-in-only projection with several appropriate avenues for a neutral survivor and additional owned-companion/family avenues where allowed. Preserve Dynamic Trading and future addon ownership boundaries.
5. Add deterministic worker tests for neutral survivor, owned companion, injured family, healthy/injured ranking changes, needs, safe gossip present/absent, hostile/enemy privacy, and Dynamic Trading enabled/disabled. Preserve direct semantics; no hub candidate may masquerade as an authored block.
6. Run a real worker plus Tk/Xvfb proof: type `What's up?`, show several contextual semantic choices and no legacy block/graph; change to an injured family scenario and show deterministic candidate presence/order changes.
7. After the worker and actual Tk gate pass, update this ledger with exact evidence and continue automatically to P10C.

## P10B — Contextual What's Up hub (accepted 2026-10-23)

The reviewed What's Up aliases still activate `semantic_hub` with no legacy category, ConversationBlock, or fabricated graph. The registered static/social providers now contribute wellbeing, needs, health, activity, safe gossip, weather/world context, and trusted personal check-in avenues; the existing Dynamic Trading provider joins the same selected hub group only when its integration is enabled and the NPC is a trader. Existing semantic click frames and DialogueInput remain the only selection lane. NPC state stays provider-owned; the hub reads bounded ActorConversationContext and the existing player-safe CognitionClient gossip projection. Hostile actors receive only the public weather avenue. Injured health and severe needs deterministically rise to the top; close friend/family/lover avenues require current friend standing and familiarity.

Exact evidence:

- `python3 -m unittest -q tools.semantic_harness.tests.test_contextual_semantic_hub_p10b tools.semantic_harness.tests.test_contextual_suggestions_whats_up tools.semantic_harness.tests.test_contextual_dynamic_trading_p5 tools.semantic_harness.tests.test_contextual_choice_provider_p8c tools.semantic_harness.tests.test_semantic_translation_integration` — 19 tests passed. Covers neutral/owned NPCs, friend/family/lover and guarded standing, enemy filtering, injury/needs rank, player-safe gossip absent/present, EN/TL label and utterance localization, provider-click semantics, and Dynamic Trading enabled/disabled plus a real trade block click.
- `xvfb-run -a python3 -m unittest -q tools.semantic_harness.tests.test_contextual_suggestions_s4` — 5 Tk/Xvfb tests passed. The hub gate types What's Up, verifies multiple semantic choices/no graph, reconfigures the real worker to an injured mother/family scenario, re-submits the same utterance through Tk, and verifies deterministic candidate ordering. Apply + Replay is deferred to P10E.
- `python3 /home/psychopatz/Desktop/Projects/Zomboid-devSkills/.agents/skills/pz-verify/scripts/pz_verify.py --kahlua --severity ERROR --no-snippets --mod-dir Contents/mods/ProjectHoomans/42.20` — exit 0; 2,968 files scanned with no ERROR-level Kahlua findings. The changed Dynamic Trading 42.20 mod scan also exited 0.
- `luac5.3 -p` on changed ProjectHoomans and Dynamic Trading Lua files, EN/TL suggestion JSON parsing, `test_semantic_translation_integration`, and `git diff --check` passed.
- The Dynamic Trading graph intentionally excludes `Contents/mods/DTHoomans/42.20/media`; its provider source was read directly. ProjectHoomans graph coverage had no recorded gaps on the touched indexed Lua/test paths; the new Tk/worker tests were verified directly.

## P10C — Typed Simulation Control Catalog (accepted 2026-10-23)

Semantic Lab now renders a bounded `semantic.simulation.control.catalog.v1` returned by the real Lua worker. Common world, player/NPC, persona, relationship, bond, role, health/activity, language, and integration fields use catalog-driven sliders, readonly comboboxes, numeric spinboxes, booleans, text controls, and multi-select traits. Needs/personality dimensions use visible numeric values; relationship standing and personality limits/steps are validated from metadata; derived relationship state is read-only. Role options come from `PNC.FactionConstants.ROLES`, while traits, bond kinds, social styles, and personality dimensions come from their existing production registries/constants. Harness-only enum values are provided by the worker UI catalog where no production option registry exists. Raw inventory and uncommon worker seams remain labeled Advanced JSON for P10D. Scenario validation and the existing worker configure path remain the state authority.

Exact evidence:

- `python3 -m unittest -q tools.semantic_harness.tests.test_semantic_simulation_ux_p10c tools.semantic_harness.tests.test_contextual_semantic_hub_p10b tools.semantic_harness.tests.test_contextual_suggestions_whats_up tools.semantic_harness.tests.test_contextual_dynamic_trading_p5 tools.semantic_harness.tests.test_contextual_choice_provider_p8c tools.semantic_harness.tests.test_semantic_translation_integration tools.semantic_harness.tests.test_app tools.semantic_harness.tests.test_contextual_bonds_p8a tools.semantic_harness.tests.test_contextual_semantic_lab_persona_p8d` — 40 tests passed. Covers bounded worker catalog, registry-owned options, typed/range/step validation, source-preserving unknown current traits, contextual hub regression, bond/persona behavior, and settings collection.
- `xvfb-run -a python3 -m unittest -q tools.semantic_harness.tests.test_semantic_simulation_ux_p10c tools.semantic_harness.tests.test_contextual_suggestions_s4` — 8 Tk/Xvfb tests passed. The P10C test manipulates real sliders, readonly comboboxes, spinboxes, and a multi-select in the settings dialog, applies through the existing Lua worker, then submits “What's up?” and verifies the worker’s injured-health choice ranks first.
- `python3 -m py_compile tools/semantic_harness/runtime/worker.py tools/semantic_harness/ui/dialogs/settings.py tools/semantic_harness/ui/shell.py tools/semantic_harness/tests/test_semantic_simulation_ux_p10c.py`, `luac5.3 -p tools/semantic_harness/lua/worker/CommandRouter.lua`, and `git diff --check` — passed.

## P10D — Structured Inventory Editor + Advanced JSON (accepted 2026-10-23)

Player and NPC inventory surfaces now default to a structured editor with a searchable read-only item catalog sourced from the installed Project Zomboid `media/scripts` definitions. The bounded worker search returns fullType/display-name results; Semantic Lab contains no copied item-definition list. Add/remove, stack quantity, condition, container/location, equipped/favorite/equipment-slot controls edit the same inventory draft as that surface's Advanced JSON tab. Unknown inventory-level and item-level fields survive Structured ↔ Advanced JSON round trips. Existing item-carried MarketSense/classification metadata is displayed read-only when available; the editor does not duplicate or invent add-on classification state. The ordinary simulation still applies through the existing Lua worker/configure path.

Exact evidence:

- `python3 -m unittest -q tools.semantic_harness.tests.test_semantic_simulation_ux_p10c tools.semantic_harness.tests.test_structured_inventory_p10d tools.semantic_harness.tests.test_contextual_semantic_hub_p10b tools.semantic_harness.tests.test_contextual_suggestions_whats_up tools.semantic_harness.tests.test_contextual_dynamic_trading_p5 tools.semantic_harness.tests.test_contextual_choice_provider_p8c tools.semantic_harness.tests.test_semantic_translation_integration tools.semantic_harness.tests.test_app tools.semantic_harness.tests.test_contextual_bonds_p8a tools.semantic_harness.tests.test_contextual_semantic_lab_persona_p8d` — 43 tests passed.
- `xvfb-run -a python3 -m unittest -q tools.semantic_harness.tests.test_semantic_simulation_ux_p10c tools.semantic_harness.tests.test_structured_inventory_p10d tools.semantic_harness.tests.test_contextual_suggestions_s4` — 11 real Tk/Xvfb tests passed. The P10D interaction searches the installed item scripts for `Base.Bandage`, adds it, edits quantity/condition/container/location/equipment fields, edits unknown item and inventory fields in Advanced JSON, switches back and forth without loss, removes a second selected item, and applies the draft through the Lua worker.
- `python3 tests/run_tests.py pnc_semantic_inventory_query_smoke pnc_semantic_inventory_service_smoke pnc_semantic_marketsense_consumption_smoke pnc_semantic_gift_context_smoke --verbose` — 4/4 embedded Lua inventory/gift/MarketSense suites passed.
- `python3 -m py_compile tools/semantic_harness/runtime/item_catalog.py tools/semantic_harness/runtime/worker.py tools/semantic_harness/ui/dialogs/inventory_editor.py tools/semantic_harness/ui/dialogs/settings.py tools/semantic_harness/ui/shell.py tools/semantic_harness/tests/test_semantic_simulation_ux_p10c.py tools/semantic_harness/tests/test_structured_inventory_p10d.py`, `luac5.3 -p tools/semantic_harness/lua/worker/CommandRouter.lua`, and `git diff --check` — passed.

## P10E — Inline Simulation Workbench + Apply & Replay (accepted 2026-10-23)

The Simulation tab now has a compact/collapsible inline workbench backed by the same Lua-worker control catalog and the same typed field renderer as the full settings dialog. It exposes the NPC profile preset plus catalog-declared role, bond, standing, derived relationship state, social style/personality, health/activity, common needs, language, and Dynamic Trading toggle. Profile selection is staged in the shared scenario draft until Apply. Optional unset fields remain untouched unless edited, so applying one dial does not silently author unrelated defaults. **Apply** sends the full draft through the existing Lua worker configure path; **Apply + replay** configures that worker and replays current input or the latest submitted utterance through its normal `worker.input`/DialogueInput lane. The real Tk/Xvfb gate changes a healthy neutral-standing companion to injured with a mother/family bond and approval 80, replays the same “What's up?” utterance, and verifies `question.health` rises to first place; no Python semantic simulation is used.

Exact evidence:

- `python3 -m unittest -q tools.semantic_harness.tests.test_semantic_simulation_ux_p10c tools.semantic_harness.tests.test_simulation_workbench_p10e` — 5 worker/catalog tests passed (the display-only test skips without Xvfb).
- `xvfb-run -a python3 -m unittest -q tools.semantic_harness.tests.test_semantic_simulation_ux_p10c tools.semantic_harness.tests.test_structured_inventory_p10d tools.semantic_harness.tests.test_simulation_workbench_p10e tools.semantic_harness.tests.test_contextual_suggestions_s4 tools.semantic_harness.tests.test_contextual_semantic_lab_persona_p8d` — 16 real Tk/Xvfb tests passed, including inline Apply + Replay and regression of the full settings/inventory dialog surfaces.
- `python3 -m py_compile` on the changed Semantic Lab UI and test modules, `luac5.3 -p tools/semantic_harness/lua/worker/CommandRouter.lua`, and `git diff --check` — passed.

## P10F — Hub Diagnostics + Completed Graph History (accepted 2026-10-23)

Semantic Lab now shows bounded diagnostics for the active What's Up hub using only player-visible provider candidates: candidate/provider/semantic owner/rank class/eligibility, allowlisted hidden/context reasons, translation keys, resolved labels, semantic destination, and the clickable frame. Diagnostics fail closed unless the provider privacy contract confirms the player-visible projection; private candidates and raw traces are excluded. The shared graph pane retains its last ConversationBlock projection after returning to a root response, until a new projection replaces it, Reset runs, or Clear graph is selected. This remains UI presentation state and adds no ModData persistence.

Exact evidence:

- `python3 -m unittest -q tools.semantic_harness.tests.test_hub_diagnostics_graph_history_p10f tools.semantic_harness.tests.test_simulation_workbench_p10e` — 4 worker/catalog tests passed; the Tk case is skipped without a display.
- `xvfb-run -a python3 -m unittest -q tools.semantic_harness.tests.test_semantic_simulation_ux_p10c tools.semantic_harness.tests.test_structured_inventory_p10d tools.semantic_harness.tests.test_simulation_workbench_p10e tools.semantic_harness.tests.test_hub_diagnostics_graph_history_p10f tools.semantic_harness.tests.test_contextual_suggestions_s4 tools.semantic_harness.tests.test_contextual_semantic_lab_persona_p8d` — 18 Tk/Xvfb tests passed, including separate hub diagnostics, retained graph presentation, graph replacement, explicit clear, and Reset behavior.
- The graph-history renderer test uses a ConversationBlock-shaped UI fixture to exercise presentation retention. Native client-composer graph creation was not launched or claimed; native Project Zomboid remains user-owned and untested.
- `python3 -m py_compile` on changed P10F UI/tests, `luac5.3 -p tools/semantic_harness/lua/worker/CommandRouter.lua`, and `git diff --check` — passed.

## P10G — Final Usability + Regression (accepted 2026-10-23)

The final Semantic Lab acceptance gates pass. The final UI covers typed worker-catalog controls, structured and Advanced JSON inventory editing, real-worker Apply + Replay, safe hub diagnostics, and graph-presentation retention. Legacy P3 tests that tried to author derived `relationshipState` directly were updated to the current production-owned relationship and speech-realization contract; no game logic was changed for those test repairs.

Exact evidence:

- `set -o pipefail; python3 -u -m unittest discover -s tools/semantic_harness/tests -t . --failfast -v 2>&1 | rg '^(FAIL:|ERROR:|Ran [0-9]+|FAILED \(|OK$)'` — 383 Python tests passed in 488.951 seconds.
- `xvfb-run -a python3 -m unittest -q tools.semantic_harness.tests.test_semantic_simulation_ux_p10c tools.semantic_harness.tests.test_structured_inventory_p10d tools.semantic_harness.tests.test_simulation_workbench_p10e tools.semantic_harness.tests.test_hub_diagnostics_graph_history_p10f tools.semantic_harness.tests.test_contextual_suggestions_s4 tools.semantic_harness.tests.test_contextual_semantic_lab_persona_p8d` — 19 real Tk/Xvfb tests passed, including 1080×700 minimum-size and 1280×800 desktop-size What's Up interactions.
- `python3 tests/run_tests.py --jobs 4` — embedded Lua suite passed 868/868.
- `xvfb-run -a bash tools/semantic_harness/run_harness.sh --doctor --doctor-json` — exit 0; Python/venv, repo, Tk/display, Core, Lua 5.3, worker syntax, READY/PING/CAPABILITIES all true.
- `python3 -m unittest -q tools.semantic_compiler.tests.test_dialogue_dataset tools.semantic_harness.tests.test_semantic_translation_integration tools.semantic_harness.tests.test_contextual_suggestions_whats_up tools.semantic_harness.tests.test_contextual_semantic_hub_p10b tools.semantic_harness.tests.test_contextual_dynamic_trading_p5 tools.semantic_harness.tests.test_quest_flow_binding` — 29 alias/compiler, hub, provider, translation, Dynamic Trading and direct quest-flow tests passed. EN/TL hub labels and utterances resolve through the same translation catalog. Changed JSON catalogs also parse with `python3 -m json.tool`.
- `luac5.3 -p` over changed Lua files in ProjectHoomans and the changed Dynamic Trading provider — passed. Full-mod `pz-verify --kahlua --severity ERROR --no-snippets` exits 0; all 12 changed production/worker Lua files pass single-file Kahlua verification. The warning-level full-mod scan still reports three pre-existing advisories in two untouched files: two idiomatic `string.len()` notices in `PNC_BodyLifecycle_CorpseItems_Identity.lua` and one `load(string)` signature notice in `PNC_SemanticCapabilityHandshake.lua`.
- Repository-wide source/test/generated-content search found no live `projecthoomans:whats_up`, `conversation.whats_up`, `projecthoomans:whats_up_*`, or `category.whats_up` references. The diff adds no UI/hub/graph ModData persistence; `git diff --check` passes.
- Branch audit: ProjectHoomans remains `main` at `b7c0d955d45156db9d38cd5b9ce88603ba900337`, upstream `origin/main`, 0 ahead / 0 behind. DynamicTrading and psychopatzCore remain on their existing `main` branches; no commit, push, branch creation, Workshop action, or native-game launch occurred.

Boundaries and remaining ownership:

- Existing quest offer/status/turn-in semantics remain on the authoritative direct flow and pass their tests. No quest/commitment `DialogueChoiceProvider` is currently registered for the hub, so Semantic Lab exposes no synthetic quest choice and copies no quest state; a future owner can contribute through the existing generic provider registry.
- The completed-graph UI retention check uses a ConversationBlock-shaped projection fixture. It verifies the shared renderer’s presentation lifecycle, not live client-composer graph generation. Native Project Zomboid SP/MP remains UNTESTED / user-owned.

## Handoff

**READY FOR USER LIVE TEST.** Native Project Zomboid SP/MP acceptance remains **UNTESTED / user-owned**.

## Historical P10A task plan (completed)

On the user's actual local checkout:

1. read root `AGENTS.md` and all current ContextualDialoguePersonaChoices docs in documented order, including `SEMANTIC_SIMULATION_UX_AND_CONTEXTUAL_HUB.md`;
2. inspect local branch/HEAD/upstream/divergence/dirty/concurrent work in ProjectHoomans and relevant sibling repos; existing `main` only;
3. inventory every live source/test/generated/content reference to:
   - `projecthoomans:whats_up`;
   - `conversation.whats_up`;
   - `projecthoomans:whats_up_*`;
   - `category.whats_up`;
   - legacy What's Up compiler/category routing;
4. define the smallest canonical semantic-hub activation contract using the existing parser/IR/click/provider infrastructure;
5. change reviewed What's Up aliases so they emit hub activation rather than `conversation_category`;
6. remove old authored category registration and old What's Up block registration;
7. remove the static `conversation.whats_up` definition and central category-specific suggestion logic;
8. remove worker hard-coded category/preflight fallback code;
9. remove/update compiler constraints and generated sources so regeneration cannot recreate the legacy category;
10. remove orphaned legacy category translations after exact reference audit;
11. replace tests that require the old category/block IDs with hub-contract tests;
12. preserve explicit direct semantics:
    - explicit wellbeing questions still parse as WELLBEING;
    - explicit gossip questions still parse as GOSSIP;
    - explicit activity/medical/needs questions remain their own semantics;
13. prove What's Up now activates a hub without selecting any ConversationBlock;
14. run focused source/reference absence checks, parser/compiler tests, worker tests, Lua syntax/Kahlua where affected, and `git diff --check`;
15. update this ledger with exact evidence and continue automatically to P10B if the gate passes.

## P10A accepted semantic activation contract

The real worker must prove:

```text
PLAYER: what's up?
 -> reviewed semantic recognition
 -> route = semantic_hub
 -> hubID = whats_up
 -> NO projecthoomans:whats_up category
 -> NO old ConversationBlock
 -> hub-ready suggestion/provider projection
```

Repository/source checks must prove there is no live production registration or runtime dependency on the removed legacy identifiers.

Historical docs may mention those identifiers as superseded evidence; production/codegen/runtime/test acceptance must not depend on them.

## Ordered remaining P10 milestones

P10A, P10B, P10C, P10D, and P10E are accepted. Continue autonomously from P10F:

- **P10E:** inline Simulation workbench and Apply + Replay;
- **P10F:** hub diagnostics and completed graph history;
- **P10G:** final usability/regression gate.

See `SEMANTIC_SIMULATION_UX_AND_CONTEXTUAL_HUB.md` for the full contracts.

## Early user-test checkpoint

Do not wait until P10G to make the interface useful.

After P10C, the user should already be able to:

```text
launch Semantic Lab
 -> adjust common world/persona/relationship values with typed controls
 -> type "What's up?"
 -> see several character/context-appropriate hub choices
 -> change a relevant dial
 -> Apply and rerun the same utterance
 -> observe candidate set/order changes
```

P10E adds the one-step Apply + Replay action and compact inline workbench.

P10D then removes raw JSON from the ordinary inventory workflow while preserving Advanced JSON.

## Handoff condition

Do not report **READY FOR USER LIVE TEST** again until P10A-P10G pass.

Native Project Zomboid SP/MP remains user-owned and must remain UNTESTED unless the user provides evidence.
