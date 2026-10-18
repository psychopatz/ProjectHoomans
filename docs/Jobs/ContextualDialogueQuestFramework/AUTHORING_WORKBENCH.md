# Semantic Lab — usable semantic authoring workbench

## Current branch reality

`flow_editor.py` at `382e93a3` has visual node CRUD/rename/duplicate/link, drag/zoom/pan, gate editor, action/trigger picker, undo/redo, JSON drafts and production Validate/Register. The source does **not** prove these GUI interactions work reliably, does not persist layout across file save/reopen as canonical editor metadata, and has no compiled-source export or true executable-action node. Existing Simulation and Turn facts tabs are part of the same application; do not create a second tool/UI.

## Proposed coherent editing experience

- **Language** — phrase examples, concepts, recognized intent/action/slots, negation and ambiguity, origin of the Core pattern; generated/tested paraphrases, collision diagnostics.
- **Dialogue** — editable graph of *meaningful states*: listening/clarifying/question/pending choice/condition/response. Semantic gate and transition ports should be labeled, drag/drop, connect/disconnect and structural error recovery. Layout persisted as editor-only metadata. Keep current Tk implementation unless measured UX limitations justify replacement.
- **Actions** — searchable live capability browser showing explicit **recognition route vs dispatch owner vs authorization**; attach registered capability to allowed result edge(s), expose typed parameter fields and multi-stage workflow (gift) distinctly. "Add action" must not merely append a parser trigger without making its limited semantics clear. Unknown/unavailable handlers should be disabled with reason.
- **Simulator** — a first-class central workflow: choose NPC/scenario, type text, preview, commit, inspect chosen IR/pattern, context, flow/gate, bound handler/route, request/authority response, actual reply, side effects. Highlight exact active node/edge; differentiate mock network from native engine. Show why follow or gift did **not** execute.
- **Compiler / Source** — view supported structured source, generated Lua/translation/manifests, collision report, file paths and proposed diff; validate, generate, reload worker and show post-restart behavior. Code editor with syntax highlighting, line numbers, snippets and linked diagnostics (implementation may be incremental).

The UI must be useful even for someone unfamiliar with raw `accepts`, `onMatch`, or translation pool IDs. Keep advanced raw JSON trace available for engineers, but ordinary authoring uses named choices and readable failure explanations.

## Editing correctness contracts

One canonical **typed draft**, two editing affordances (graph + supported text). Applying changes is transactional and undoable. Graph mutations must repair or refuse invalid references; renaming updates initial and all edges; add/duplicate must ensure reachability or immediately show explicit intentional invalid state and recovery action; deleting a terminal does not silently point the initial state elsewhere without user choice. Preserve positions, selection, zoom and dirty state separately from executable definition; include editor layout as metadata in source/document round-trip, never runtime semantics.

Production Lua `Registry.Validate` remains the authority for flow grammar. Editor preflight is for ergonomics only. Unknown syntax must never be dropped or evaluated. A save button should clearly distinguish **Save editing draft**, **Compile sources** and **Register temporary worker draft**. Do not represent worker-only Register as persistent modification.

## Test and UX gates

1. Existing baseline flow graph and weather conditions still render. Verify actual Add node, rename, duplicate, connect, disconnect, delete and undo/redo through a real Tk view where possible. A Python method test is only provisional if no GUI.
2. Picking a FOLLOW capability explains its actual action adapter and whether it is available in the current worker; an author can create a working interaction without manually editing five Lua files.
3. Display an execution/denial trace with selected source pattern, actual response, action request and handler outcome, or explicitly show no flow/handler.
4. Export correct modular files and translation keys into reviewed PZ paths; run a new worker and verify actual behavior survives restart.
5. Readable at typical window size: node graph fits/repositions, long raw fields aren't primary, keyboard controls exist, window remains responsive; no giant empty canvas as only feedback.
6. Keep the same primary UI for agent/human testing. Headless worker tests still cover logic but cannot substitute for authoring usability.

Related source: `CAPABILITY_ACTION_BINDINGS.md`, `PROCEDURAL_NLP_COMPILER.md`, `HARNESS_ACCEPTANCE.md`.
