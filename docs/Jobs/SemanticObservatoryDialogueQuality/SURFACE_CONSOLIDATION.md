# Semantic Lab surface consolidation

**Status: IN PROGRESS.** Core Simulation/Studio redundancy consolidation is implemented in the current worktree; the newly approved Dialogue Content primary surface and Developer Tools demotion remain required by P3/P7. This document replaces the earlier assumption that Studio should independently expose Catalog + Test Lab + Coverage + Review. The running Semantic Lab already has a mature Simulation workbench; duplicate user-facing runtime tools are consolidated rather than preserved.

## Product rule: one job, one home

The top-level Semantic Lab surfaces have distinct responsibilities:

| Surface | Sole user-facing responsibility |
| --- | --- |
| **Simulation** | Execute and replay conversations against fixture/save-backed context; show Response Channel, runtime state, selection/authority/effects, comparisons/regressions and diagnostics. |
| **Studio** | Discover what semantic content exists, edit **content-only** EN/TL phrase families/player-choice wording, and review proposed canonical changes. Structural authoring is Developer Tools. It is **not** a second simulator. |
| **World Browser** | Find/select saves, players, NPCs, factions, communities and other persisted targets. Simulation may link/open it but must not duplicate its browser. |
| **Log** | Shared GUI/CLI activity timeline and operational history. Other surfaces show concise status only; they do not duplicate the log. |

Headless CLI remains the agent-facing parity surface over the same worker/services. Consolidating GUI tabs must not delete or fork the shared query/test services.

## Current redundancy to remove

### Studio Observatory Test Lab

Current behavior runs a typed utterance through the real Lua worker. **Simulation already owns this** through Conversation + input + Preview/Send + Response Channel + saved/fixture context + trace.

**Disposition:** remove the Studio Test Lab user-facing tab. Reuse its underlying inspection helpers from Simulation where useful; do not preserve a second conversation runner.

### Studio Observatory Coverage

Current buttons run EN/TL greeting/follow, lifecycle/Goodbye, rejection and selection-coverage fixtures. Simulation already owns contextual comparisons and runtime testing.

**Disposition:** move/consolidate human-facing regression actions into Simulation `Compare / Regression` (or equivalent). Keep bounded matrices/headless CLI as shared services/tests; do not duplicate them under Studio.

### Studio context-specific Explain Selection

Catalog browsing legitimately belongs in Studio, but asking “why did this variant win in this NPC/context?” is runtime inspection.

**Disposition:** Studio Explore may show static variant conditions/ranks/source metadata. Context-specific explanation for the active scenario belongs in Simulation `Inspect`, backed by the same production selector explanation service.

### Observatory Catalog + Interaction Explorer + Dataset/source browsing

These currently answer overlapping discovery questions across separate primary tabs.

**Disposition:** merge their read-only discovery roles into **Studio → Explore** with searchable kinds such as Responses, Interactions, Flows, Sources and All. Preserve verified source type/provenance (`AUTHORED_LUA`, CodeBuilder/canonical source, translation, generated, `UNKNOWN`). Editing canonical JSON is not part of Explore.

### Dataset Library editor, Flow Graph, Block Palette, Interaction Composer, Build Workflow

These are authoring/maintenance tools rather than everyday inspection.

**Disposition:** remove them from the primary Studio tab row and expose only through **Developer Tools…** when still needed. Prefer read-only/default-safe modes. Split Dataset Library’s useful source browser into Explore; raw JSON editing belongs in Developer Tools. Keep Flow Graph primarily as visualization until explicit edit action. Block Palette and Interaction Composer are specialist developer tools. Build Workflow is a **legacy/retirement candidate**: hide under Developer Tools/Legacy, prove no unique user-facing capability or dependency remains, then remove duplicate UI wiring if safe while preserving shared CodeBuilder/authoring services.

## Target top-level UI

```text
Project Hoomans Semantic Lab

Simulation
  Conversation + Response Channel
  Context / target
  Diagnostics
    Inspect
    Graph
    Compare / Regression
    World
    Debug

Studio
  Explore
  Dialogue Content
  Review
  Developer Tools…
    Flow editor / visualization
    Raw canonical source editor
    Block contracts
    Interaction composer
    Legacy build workflow (temporary, retirement candidate)

World Browser
Log
```

Names may vary slightly if existing widget/test conventions require it, but ownership must not drift.

## Simulation diagnostic consolidation

The current Simulation trace notebook exposes many low-level tabs. Consolidate presentation without losing diagnostics:

- **Inspect** — Conversation understanding + selected response/selection reason + Command authority + Effects + Suggestions/predicates + Provenance for the current turn.
- **Graph** — Dialogue graph as primary view; Hub and Dialogue diagnostics become secondary/expandable details rather than peer top-level tabs.
- **Compare / Regression** — current context comparisons/persona matrix + Talk parity + moved Observatory coverage/regression actions.
- **World** — World Knowledge and runtime actor/world context that is relevant to the active simulation.
- **Debug** — Raw worker record + Snapshot/Restart/maintenance diagnostics.

Do not create a second implementation of any inspector. Compose/reuse existing widgets/controllers/services and preserve the same worker request queue.

## Studio target

### Explore

One read-only searchable browser answers:

- what response pools/variants are actually registered;
- what interactions/flows/actions exist and their execution route;
- which canonical/generated/translation source owns an item when verified;
- EN/TL coverage/source metadata;
- static conditions/priority/plan summary.

Explore does **not** execute a conversation or own active scenario controls. A result may offer “Open in Simulation” / “Test this” navigation that transfers the relevant ID/query/context to the sole Simulation workbench.

### Dialogue Content

The normal human editing surface follows [DIALOGUE_CONTENT_REGISTRY.md](DIALOGUE_CONTENT_REGISTRY.md). It edits verified content-only phrase families and player landing/choice wording while displaying semantic conditions/priority/plan/route metadata as locked context. It validates paired EN/TL, phrase IDs, placeholders, duplicates/repetition and canonical-source freshness, then previews in Simulation and sends the diff to Review. It does not mutate flow graphs, conditions, authority or gameplay actions.

### Review

Review owns candidate-source review, not general conversation testing. It should evolve from “select a JSON and read technical output” toward a human-readable before/after review:

- exact response family/source owner;
- current EN/TL vs proposed EN/TL;
- preserved conditions/priority/plan/authority metadata;
- isolated real-Lua replay result;
- gameplay/effect parity;
- stale-source/fingerprint state;
- explicit approve/reject decision when authorized.

Under the hood it may use the same disposable worker/matrix services as Simulation/CLI. That does not make it a second simulator.

### Developer Tools

Structural/manual authoring tools are maintenance surfaces, not a primary Studio tab. Expose them through a bounded Developer Tools entry/menu/toggle when still required. Do not expose Build Workflow, Block Palette, Interaction Composer, raw source JSON editing or Flow mutation as peer everyday Studio tabs after the Dialogue Content workflow exists. Flow visualization may remain reachable read-only from Explore.

## Migration rules

1. **Move UI ownership, not semantic authority.** Production Lua/Core, worker protocol, CodeBuilder and canonical sources do not change merely to reorganize tabs.
2. **Reuse existing callbacks/services.** No second runner, matrix engine, selector, browser, source catalog or worker session.
3. **Preserve agent CLI.** GUI consolidation must not remove bounded headless catalog/detail/explain/matrix/coverage/review operations.
4. **No destructive deletion first.** Hide/move duplicate UI, prove parity and no unique capability, then delete dead UI wiring/modules only when tests/callers show it is safe.
5. **Keep saved/fixture semantics explicit.** Simulation remains the single place that applies active test context. World Browser only selects save-backed targets.
6. **Preserve UI state safely.** Migrate/ignore obsolete tab/splitter keys without crashes or resurrecting removed duplicate panes.
7. **Human-first wording.** Default surfaces answer “what exists?”, “what happens?”, “why?”, “what changed?” rather than requiring users to understand internal `InteractionSpec`, block or CodeBuilder terminology.

## Acceptance

P3 surface consolidation is accepted only when all are true:

- Studio has no independent Test Lab/conversation runner and no separate scenario-context selector.
- Studio coverage/regression execution is removed or navigates to the single Simulation regression surface.
- Studio default workflow is Explore + Dialogue Content + Review; structural/manual authoring tools are under Developer Tools rather than a peer everyday tab.
- Explore unifies response/interaction/source discovery without creating a parallel source database.
- Dialogue Content edits only verified canonical content, keeps structural semantic/gameplay fields locked, compiles through existing CodeBuilder ownership, and previews through Simulation.
- Simulation remains the sole GUI execution/context workbench and can reach all moved regression/selection-inspection functions.
- Simulation diagnostics are consolidated enough that the same current-turn information is not exposed as multiple peer tabs without a clear reason.
- World Browser remains the sole save/target browser; Log remains the sole full activity timeline.
- Existing underlying functionality is preserved or deliberately retired only after proving it is redundant.
- GUI tests exercise navigation and moved functions against the real worker; headless CLI remains parity-compatible.
- No semantic/gameplay behavior, canonical source ownership, save data or Workshop state changes solely because of UI consolidation.
