# Verified branch audit — 2026-10-18

**Inspected ref:** `docs/contextual-dialogue-quest-framework-20261018` commit `382e93a342f1d6ee13fc2007a7fbbdf66a7afa7c`; main remains `a3eb2e4db553f9c03b7f66a6ff6717878e1668e0` at audit time. The branch is 4 commits ahead of main, and PR #4 remains open. **Evidence:** remote code read and screenshot supplied by user. No new checkout-local tests, GUI click-through or native PZ run performed for this documentation update.

## Source-confirmed, not necessarily accepted

| Component | What the current branch implements | Remaining distinction |
| --- | --- | --- |
| `tools/semantic_harness/flow_editor.py` (about 1322 lines) | Graph visualization; add/duplicate/rename/delete/connect nodes; drag, pan, zoom, undo/redo; add trigger/action frame; gate fields; register/validate; JSON draft open/save | Does not compile source; node edits can leave invalid unreachable/empty accepts; layout and history are not fully round-tripped; action button is trigger-only |
| `gui.py`; `lua/worker/FlowEditor.lua` | Simulation and Flow Editor tabs; live worker registry, action/trigger/fact/event/catalog discovery, production Validate/Register | No committed action-result node type or source generator; worker registration ephemeral |
| `PNC_SemanticCapabilityCatalog.lua` | Introspects policy actions, command/task adapters, context constraints and Core registered patterns. Rows expose sources/transports/recognized/dispatchable fields | Discovery is not executability: a policy action or NLU pattern can be recognized yet have a separate multi-stage or unavailable dispatcher. No verified handler execution just from catalog listing |
| `PNC_SemanticEngineFacts.lua`; `PNC_SemanticEngineEvents.lua` | Typed facts and bounded recent event bus; server zombie-kill producer via Core detector | Fact/event names are not executable actions; an event catalog is not itself a quest objective engine or event-triggered dialogue |
| `PNC_SemanticDialogueFlowRegistry.lua`; `FlowKernel.lua` | Gate field and PASS/FAIL/UNKNOWN transitions on real flow nodes, existing active/suspended sessions | V1 schema lacks a typed action-result binding, compiler/source export and general quest/memory behavior |
| `PNC_ConversationRules_Conditions/Evaluation.lua` | Shared gate status reused by flows; weather pilot | Preserve existing Blocks behavior and non-action preview purity |
| `PNC_SemanticDialogueFlow_Weather.lua` and test `test_contextual_weather_gate.py` | Response-only rain/clear/unknown contextual flow | Not evidence that Follow/Gift/Wait functionality can be authored end-to-end |
| `PNC_SemanticDialoguePolicy_Core/IntentBranch.lua` | Static action classification and branch selection (including FOLLOW, STAY, WAIT_AT, GIVE/FETCH etc.) | Hardcoded dispatch semantics are not derived automatically from new flow graphs |
| `PNC_SemanticDialogueInput_Actions.lua` | Explicit approved branches dispatch gifts, inventory, command then task | Flow editor has no exposed authoritative result binding; do not route directly around this safety layer |
| `PNC_SemanticCommandAdapter.lua` | FOLLOW→follow, STAY/STOP→stay, GO HOME→return_home, CAMP→camp via SendCompanionCommand | Requires existing command permission and transport; not arbitrary node function invocation |
| `PNC_SemanticTaskAdapter.lua`; server `PNC_SemanticTaskRequestService.lua` | WAIT_AT, GIVE/FETCH, consumption etc. via registered handlers and server admission | No direct action execution in FlowKernel |
| `PNC_SemanticDialogueInput_Gifts.lua` | Gift offer/consent/selection/transfer path | Multi-stage; cannot safely be modeled as an unconditional GIFT command |
| `tools/semantic_compiler/build.py`; README; generated Lua shards | Compiles narrow reviewed WordNet verbs and common-dialogue seed into Lua patterns, forms and responses | No unified graph/flow/action/gate compilation or Semantic Lab source round-trip |

## Observed usability and correctness gaps

1. **User-visible mismatch:** screenshot shows four loaded flows and a huge sparse canvas, manual JSON triggers/accepts, low-level gate fields and Add action. User cannot author an actual command/result interaction from that UI.
2. **Trigger ≠ binding:** `FlowEditorPane.add_command_trigger` appends a parser frame to `draft.triggers`, not an executable `actionBinding`. The flow registry stores responses/transitions/gates only.
3. **Misleading catalog semantics:** `CapabilityCatalog.addAction` sets `recognized=true` for discovered policy/adapter rows; that does not prove an input phrase matches or the route dispatches in this worker/session. Separate **recognized/eligible/dispatchable/authorized/admitted/completed**.
4. **Graph structural safety:** `add_node` can make selected terminal node nonterminal without required accepts, duplicate can make unreachable state, delete removes incoming edges; validator diagnoses later but UI does not prevent/recover transactionally. Drag layout is held separately from serialized definition.
5. **Generator gap:** save draft writes JSON and Register only changes this Lua worker; no checked-in modular Lua + translation + require/manifest export, no restart proof.
6. **Test coverage gap:** branch tests prove recognition catalog, weather gate validation and some Lua flow behavior; do not prove GUI editing, source compiles/loads, real action acceptance/rejection, gift consent or multiplayer server authority.
7. **Ledger drift:** `PROGRESS.md` and `GOAL_PROMPT.md` on branch still say Phase 1 not implemented and start at 0A, although `382e93a3` contains Phase 1 code and engine fact catalog additions.

## Evidence level and safe interpretation

- Weather gate: **recorded developer acceptance** in older `PROGRESS.md` at `1a754dc8`: real worker rain true/false/unknown, no side effects; 108 unittests documented **at that earlier checkpoint**, not rerun at `382e93a3`.
- Graph CRUD: **source-present but acceptance incomplete**; do not claim no implementation, or "all passed".
- Capability catalog and EngineFacts/Events: **source-present, unverified on newest branch**.
- Action-binding, unified procedural compiler/source export, full durable contextual memory and quests: **not yet implemented/accepted**.
- GitHub had **no workflow runs** returned for newest `382e93a3` at the prior audit. Actual local dirty state unknown.
- PZ SP/MP and Workshop: **user-owned, not executed**, not development blockers.

## Ownership pointers

For action lifecycle inspect: `PNC_SemanticDialoguePolicy_Flow.lua`, `PNC_SemanticDialoguePolicy_Decision.lua`, `PNC_SemanticDialogueInput_Actions.lua`, `PNC_SemanticCommandAdapter.lua`, `PNC_SemanticTaskAdapter.lua`, `PNC_SemanticDialogueInput_Gifts.lua`, `PNC_SemanticTaskRequestService.lua` and command/Inventory registry. Avoid changing five services when one small binding/trace hook works.

For compiler review inspect `tools/semantic_compiler`, `PNC_SemanticCatalog.lua`, `PNC_SemanticGeneratedDialogue.lua`, flow catalog require order and translation manifest. Verify these actual paths in local checkout before generating files.
