# Semantic Lab — integrated reusable Semantic Studio workspace

**Current acceptance note:** at `71162cb4f78cc4cd408a4a145486d5ebadc943c1`, code provides Flow Editor graph, 23-ish registered flow entries, action/fact gates and generation buttons, Conversation State Inspector, reviewed dataset preview and source approval; prior X11 and Lua worker gates recorded. **Still missing:** in-app searchable dataset library, shared semantic block palette, synchronized structured source editing and one canonical codebuilder/writer service. Do not repeat old claims of only 5 loaded flows.

## Target single-app work areas

1. **Dataset Library:** discover canonical reviewed `common_interactions`, `semantic_definitions`, WordNet concepts, licensed source metadata and approved/rejected mappings, with counts, search, EN/TL status and linked generated flow/source. Existing data must be visible without a file picker. Review/approve/reject with versioned provenance, collision report and no automatic gameplay execution.
2. **Block Library:** typed reusable modular language/pattern, context/agenda, world fact, condition, response-plan, memory, registered action and quest blocks. Blocks are declared reusable fragments with stable IDs, typed ports, source owner, version and dependency graph; composing a block does not duplicate Lua implementation or invent native handlers.
3. **Conversation Composer:** searchable tree/graph with nested subflow references, add/rename/remove/duplicate/connect/auto-layout/pan/zoom, result edges, contextual and game-state inspection. One **canonical typed definition** shared by graph and code view; editor layout metadata not runtime semantics.
4. **Code/Source Builder:** real syntax-aware supported declarative editing (codeblock-style with snippets/validation/diagnostics), visual/code two-way synchronization, review exactly affected modular Lua/EN+TL/manifests, safe output paths, preview vs approved write clearly separated. Unsupported handwritten Lua must be kept unmodified and safely marked non-round-trippable, not eval'd.
5. **Simulation & Trace:** real Core + Hoomans Lua worker, chat history, selected IR/pattern, current topic/reference/agenda/knowledge/response plan, generated flow result, actual approved action/authority trace and rendered NPC text, with direct links back to originating dataset and blocks.

All five areas are views into **one Semantic Lab process and one headless authoring/build service**, not separate apps with their own source files or semantic engines.

## UX acceptance sequence

- **S0A:** preserving current interface/runtime, make compiler an embedded library and unify imports; no extra UX controls required yet. Behavior/artifact parity mandatory.
- **S0B:** centralize preview/compile/write/worker-reload service shared by buttons and CLI, eliminate independent file/path policies.
- **S1:** browse and edit actual existing patterns/response pools *within* UI, preview source diff and trace; no manual JSON selection for ordinary workflow.
- **S2–S3:** share typed block registry and canonical spec between visual graph and supported code editor. Reuse a Fact+Context block in two different graphs without duplicate code or invalid edge type.
- **S4–S5:** import reviewed large dataset candidates; generate Lua through same codebuilder; allow visual edits and deterministic regeneration, with exact diff approval and fresh-worker behavioral test.
- **S6:** human/agent authors and verifies one multi-turn contextual dialogue entirely in Semantic Lab, with low-latency UI and no separate compiler invocation.

No Tk-to-Electron rewrite by default. Inspect actual user click-through and performance before changing UI framework. Avoid giant raw JSON fields as the main authoring experience. Headless Python-only tests can't prove real UI editability; real X11/Tk testing can cover it where available. Native Project Zomboid remains user-owned.
