# Semantic Lab — Graph + Definition + Test workbench

## Current reality

tools/semantic_harness/flow_editor.py already provides a Tk canvas graph, selected-node fields, JSON triggers/accepts, save/load JSON drafts and production worker validate/register. It does NOT yet let users add/remove/rename/drag/link nodes visually or edit a synchronized Lua definition source. Register is worker-local and lost on restart.

## Target authoring experience

Use the **existing Tk Semantic Lab**, existing worker session, registry and side-effect-free preview. Three synchronized panes/tabs:

1. **Graph:** flow picker, search and filter, fit-to-view/zoom/pan, readable directional edges labeled next/onMatch/onRefuse/onUnrelated; add, duplicate, rename, delete, drag and connect/disconnect nodes; undo/redo and dirty-state warning. Right-click/context menu and accessible equivalent toolbar actions. Special targets cancel/resume/suspend are labeled exits, NOT fake ordinary nodes.
2. **Definition:** syntax-aware, line-numbered declarative Lua or supported structured flow source, snippets/autocomplete for intent/frame/gate IDs, validation error mapping. Code and graph edit one canonical typed draft. A Lua source outside supported declarative grammar is preserved unmodified, with graph edits disabled and a precise explanation, never silently rewritten or executed for parsing.
3. **Test/Inspector:** select a scenario, mock NPC/player/world/personality/relationships/quest snapshots; preview through production Lua; commit a real isolated worker turn; see IR candidates/selection, gate PASS/FAIL/UNKNOWN + reasons, selected flow/node/transition, response pool and EN/TL rendered response, context before/after, tools/transport and quest stub/result. Highlight actual taken path, distinguish preview from committed turn.

## Model contract

The canonical draft is a data-only, versioned flow/quest/condition definition compatible with production registry normalization. Graph layout coordinates are **editor metadata** separate from gameplay data and never influence runtime execution. Node mutations are transactional in the in-memory draft. Removing a referenced node requires safe retargeting or refusal; renaming updates all references and initial state. Validate against actual production registry, not independent Python semantics.

Round-trip loop: production definition -> normalized editable draft -> graph and definition editors -> production Validate -> isolated Register -> production turn trace -> source export diff -> safe reviewed write -> worker restart -> production re-load trace. Worker registrations are never equated with durable source writes.

Production definition/export format must respect repository AGENTS.md common vs 42.20 layout and translation shards. Use deterministic formatting/stable ordering; never rewrite unrelated handwritten Lua; fail closed on unsupported syntax; never eval arbitrary content in Tk Python or the worker. Prefer templated declarative registration modules and explicit require manifest changes over runtime walking/loading arbitrary draft JSON directories. Imported external mods must remain owned by their own packages; do not write outside an authorized repository.

## Authoring tasks and acceptance

- **First graphical slice:** add, rename, delete and link existing flow nodes; incoming references remain correct; graph redraw uses positions to avoid fixed two-column limitations; real worker rejects unreachable/dangling branches.
- **Code-view slice:** build a valid new definition by adding supported fields, validate, inspect graph parity, edit visually and round-trip without semantic changes. Syntax/validation errors point to the offending field/node; unknown grammar is not destroyed.
- **Durable export slice:** write a source-safe new flow module with clear review/diff, required manifest/translation keys and load it in a *new worker process*. Show the exact played response after restart.
- **Quest/gate slice:** authored conditions and quest-state checks must be displayed with explanation, not hidden as untyped JSON magic. A flow route denied for an unknown quest fact must not produce quest commands.

## Non-goals and UX reliability

Do not replace the desktop stack with Electron/browser solely to make a diagram look attractive. Do not create a fake Python dialogue engine or only generate screenshots. Do not claim interactive GUI acceptance from unit tests on flow_graph_model alone. If no accessible desktop, accept source-level GUI tests + real Lua worker evidence provisionally and leave actual click-through open. Keep UI event handling off the worker request thread, use the existing async session/queue, preserve selection and pan/zoom while editing, and never freeze the interface on a long Lua worker response.
