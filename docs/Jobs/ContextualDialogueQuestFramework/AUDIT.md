# Source audit and phase transition — 2026-10-18

**Remote branch source:** `docs/contextual-dialogue-quest-framework-20261018` @ `f0b6e41b90b025d64ccd7578e526d80876de4969` (PR #4 open at inspection). This is GitHub code inspection plus prior recorded test evidence, not new local GUI/worker reexecution or native Project Zomboid acceptance.

## Existing accepted/observed building blocks

- Four manually authored response/state flows (`greeting`, `identity`, `weather_context`, `wellbeing`) plus one compiled `pnc.dialogue.follow.flow` in `PNC_SemanticDialogueFlowCatalog.lua` / generated manifest; the user's screenshot shows five.
- `PNC_SemanticGeneratedDefinitions_Flows_01.lua` defines FOLLOW only as `accepted` terminal node with `responsePool = semantic.authored.follow`. No function binding, permission check or result/denial transition is serialized into that flow.
- `PNC_SemanticDialogueFlowRegistry.lua` `normalizeNode` accepts frames, response, gate, slots and basic transitions. It does **not** accept a typed action node/capability/result outcome. Kernel Preview/Commit owns dialogue state, not gameplay dispatch.
- `PNC_SemanticDialoguePolicy_Decision.lua` `flowResponseEligible` rejects `result.action ~= nil`. Generated FOLLOW action responsePool is therefore not the authority-selected response on the executable path.
- `PNC_SemanticDialogueInput_Actions.lua` handles `COMMAND_ACCEPTED`, gift, inventory and task branches via existing `PNC_SemanticCommandAdapter`, `PNC_SemanticTaskAdapter`, gift lifecycle, and server/domain authority. **These are real production routes to reuse**. Recorded worker tests showed FOLLOW, STAY/WAIT_AT and GIFT requests and results through those adapters with mock authority, and an X11 click-through proved current GUI compilation/generation/restart for one reviewed source. See `HISTORY_20261018.md`.
- `tools/semantic_compiler/semantic_definitions.json` contains exactly one top-level authored FOLLOW definition (two new positive phrases). `compile_semantic_definitions` requires `REQUEST/REQUEST` and emits basic flows. This excludes `OFFER/GIFT` and workflow kinds beyond simple request; action capability reference is validated at top level but is not preserved as an executable flow node.
- `tools/semantic_harness/flow_editor.py` has Add action, but `add_command_trigger` only appends a trigger frame. `Compile source…` and `Generate source…` use an external reviewed file chooser, not "enumerate all capabilities" with coverage and generated flow edits.
- Prior `PROGRESS.md` marked READY FOR USER LIVE TEST for narrow phases, despite `ROADMAP.md` still listing context/memory/quest stages as PLANNED; full suite recorded contextual social reaction failures. These older claims remain available verbatim in history, but cannot satisfy the clarified goal.

## Newly mandatory gaps

1. No registry-backed **automatic inventory of all flow-eligible capabilities**, classification by workflow template or explicit missing-metadata coverage report.
2. No generic **complete production action-flow schema** with named binding, typed slots, outcomes and condition/transitions.
3. No automatic generation for multiple existing registered capabilities from a single template; one hand-authored FOLLOW definition is not procedural population.
4. No producer-agnostic handling of OFFER/GIFT, target-dependent WAIT_AT or future memory/quest dialogue through the same compiler.
5. No coherent source-of-truth/round-trip flow editing where author changes graph and regenerates structured definition and modular source while protecting manual customizations.
6. No all-compatible-capabilities worker acceptance matrix, including negative cases, correct response ownership and idempotent reruns.

## Distinguish evidence

**Code-verified:** named files/limitations above at remote SHA. **Recorded but not rerun:** earlier developer real-worker Follow/Stay/WaitAt/Gift and X11 compiler generation tests. **New goal not done:** automatic broad generation and authoritative flow-level lifecycle. **User-owned/unrun:** native PZ SP/MP or Workshop publication.

Current phase is **G0 — Automatic Flow Generation Foundation**; the Next Chunk in `PROGRESS.md` is ONE generic simple-command template slice (discover all matching registered simple commands, prove multiple generated action flows), not another single hardcoded FOLLOW.

The generator may use explicit supported templates, but it must never infer arbitrary callable function names from action strings or automatically create fictitious NPC game primitives.
