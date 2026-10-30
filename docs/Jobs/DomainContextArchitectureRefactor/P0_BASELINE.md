# Fresh baseline

Source anchor: `15cadee70be11b790ce4c48bfb7bd51badd8233b` (2026-10-30).
No production architecture changed while establishing this baseline.

## Repository and provenance

- Existing `main`, initially clean; fetched origin successfully, still ahead 7 / behind 0.
- One other extant detached worktree (`/tmp/m10g-published.zvTMcr/ProjectHoomans`);
  another registered fixture worktree is already prunable. Neither was changed.
- No concurrent source edits observed through repeated status checks. Process
  inventory alone cannot establish exclusive ownership; recheck before each chunk.
- MCP project `project-hoomans`, Tier 2. Initial graph had 87,463 nodes / 359,988
  edges and only 3,005 runtime files, despite reporting the current HEAD. Forced
  refresh produced 99,748 nodes / 409,550 edges and all 3,260 current runtime files.
- Coverage generation: `2026-10-30T07:52:28Z`; no recorded parse-partial/skipped
  source. The exact 600 composition/cycle evidence paths were checked in five
  batches: all metadata matched, no recorded gaps. Scope pagination completed for
  runtime, tests and tools. Exclusions are graph/analyzer caches, Python caches
  and the semantic tool's virtual environment; these are not maintained sources.
- Clean coverage is best effort, not completeness proof. Statement-form Lua
  `require "..."` is underrepresented in MCP IMPORTS (only five Composition
  edges). Fresh architecture-audit literal-import facts supplement MCP here.
- MCP CALLS resolution is heuristic: e.g. `Registry.Get` in server Inventory
  resolves to a client registry, `Core.Now` to unrelated addon helpers, and `type`
  to declarative dialogue data. Those edges are rejected after direct source
  review, not counted as runtime dependencies. Callback attachment can also
  yield zero inbound callers for a live function. Preserve these limitations in
  every retrieval comparison.

## Source classification

Fresh architecture-audit 2.0.0, `--framework project_zomboid`:

| Category | Files |
|---|---:|
| Analyzer production (all supported source kinds) | 3,387 |
| Tests | 1,265 |
| Tooling | 287 |
| Generated | 174 |
| Current executable runtime Lua, excluding generated catalogs | 3,258 |
| Current generated animation DebugCatalog Lua | 2 |
| Common packaged declarative Lua | 282 |

The 3,258 maintained executable runtime files comprise client 985, server 1,008,
shared 1,265. `common/media/lua` holds 110 analyzer-production declarations and
172 generated catalogs/definitions; it is reported separately, not treated as
110 gameplay services. XML, translations, textures, clothing, animations and
other packaged data are declarative assets outside the executable import graph.
Tests/support and tooling/authoring sources are not gameplay domains.

## Cycle truth

The fresh analyzer reports 285 production findings, including **45 cycle
manifestations over 13 repeated paths** (old snapshot: 246 / 33). These are not
45 independent architecture defects. The literal maintained-runtime graph has
4,172 resolved edges and three folder-level strongly connected groups:

1. `(composition), Composition`: classification artifact joining engine entry
   files and composition providers. No corresponding file-import cycle. P3 must
   preserve bootstrap order, not remove entry files to improve the score.
2. Colony, Communities, Conversation, Knowledge, Perception, Persistence,
   Production, Relationships, Scavenge, Semantics, Settlement, Social, Traits,
   UI, WorldDiscovery: one connected architectural pressure group. Root work
   includes Persistence importing Conversation memory while Conversation's owned
   store uses the reset mechanism; Conversation importing a UI palette while UI
   consumes Conversation; and social/semantic/presentation relationships. These
   are real opposite-direction domain edges, but not circular file loading.
   P4/P5/P6/P7 must inspect ownership and global-table calls before inversion.
3. Networking, PresenceSync: current roster adapters consume the body-binding
   client runtime, which consumes the shared binding protocol under Networking.
   This is a protocol/client-adapter ownership classification issue, not evidence
   that recent body-binding infrastructure is redundant. Consult the M12 job
   before any production change; keep its user-owned native MP gate intact.

Only one literal file-import SCC exists: `NPCPresentationDebug`,
`PNC_AnimationSceneDebugWindow`, and its `_Actions` provider. It is a UI/debug
cycle, not 45 gameplay load cycles. The machine snapshot retains every edge and
line for review; global namespace dependencies remain outside that graph.

## Composition baseline

`leaf` below means no resolved maintained-runtime imports. It does not mean a
module is artificial or should be merged. Domain counts use provisional analyzer
folder labels; P1 replaces these with explicit ownership.

| Root | Requires | Folder domains | Leaf targets |
|---|---:|---:|---:|
| ServerComposition | 125 | 32 | 29 |
| ClientComposition | 118 | 18 | 44 |
| Shared Foundation | 76 | 19 | 47 |
| Shared IdentitySocial | 67 | 14 | 53 |
| Shared InventoryWorld | 44 | 19 | 20 |
| Shared CombatRuntime | 42 | 19 | 27 |

`P0_ARCHITECTURE.json` retains target paths for repeatable domain/leaf review.
`tools/domain_context_audit.py` requires fresh analyzer facts and checks their
source hashes; rerun the architecture scan first to discover added/deleted files.

## Analyzer findings requiring interpretation

- `UI_PERSISTENCE_MIX`, `PNC_ColonyUIComponents.lua:62`: saves user column
  positions using Core Settings. Direct review confirms local UI preferences,
  not authoritative gameplay persistence. Retain the feature; P6 must document
  this permitted presentation ownership rather than move preferences to server.
- `CORE_DOMAIN_DEPENDENCY`, `UI/Shared/PNC_FacilityBuildProvider.lua`: Shared
  means shared presentation helpers here. Both endpoints belong to UI; it is not
  PsychopatzCore importing Hoomans gameplay. Classification false positive.
- Large module/function findings remain triage; generated DebugCatalog size is
  excluded from maintained gameplay responsibility decisions.

## Developer test baseline

- `python3 tests/run_tests.py`: **978/978**, isolated Lua processes, 4 workers,
  8.92 seconds. Runtime versions discovered by the repository runner.
- `python3 -m unittest discover -s tools/unique_npc_manager/tests -q`: **6/6**.
- Full in-process semantic tooling discovery aborted before a summary with
  `Tcl_AsyncDelete: async handler deleted by the wrong thread` after repeated
  Tk Variable cleanup errors, with production source unchanged. Exit 134.
- Retry uses one Python process per module against an immutable P1 archive
  (production identical to P0), not the migrating worktree. It already exposes
  pre-existing assertions counting `SemanticInteractionLifecycle` fact traffic
  as gameplay dispatch, plus stale category/choice fixtures. Record its complete
  result and classify every failure before final acceptance; none are waived.
- No runtime Lua changed in P0; installed-PZ compile is required when runtime
  changes begin. No native game launched or Workshop publication performed.

## Repeat

Run the architecture-audit skill's `scan . --framework project_zomboid`, then
`python3 tools/domain_context_audit.py --output /tmp/hoomans-domain-current.json`.
The P0 JSON remains immutable baseline evidence; later reports use other paths.
Use the fixed probe definitions and recorded MCP traces for P0B and subsequent
comparisons. Whole-file bytes/lines are a durable upper bound for the reviewed
implementation slice; they are not MCP token counts or an import-closure minimum.
