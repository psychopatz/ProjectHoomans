# Progress — Domain & Context Architecture Refactor

**Status:** IN PROGRESS — P0–P3 developer-validated; P4 persistence ownership is next.

## Parent objective

Complete P0–P8 in `ROADMAP.md` and every developer gate in `ACCEPTANCE.md`.
A phase completion does not complete this parent goal. Continue automatically.

## Current repository and architecture

- Existing `main` only; planning baseline `15cadee70be11b790ce4c48bfb7bd51badd8233b`.
  Initially clean, origin fetched, ahead 7 / behind 0. No concurrent edits found.
- Accepted commits before current P3 chunk: P0 `4205a1d7`, P1 `24d61abc`,
  Inventory pilot `b4535421`, tooling-baseline evidence `19749cef`.
- MCP project `project-hoomans`; explicitly refreshed against actual source.
  Matching Git HEAD alone had hidden stale content. Statement-form IMPORTS and
  heuristic alias resolution need the documented literal-import/source fallback.
- P0 maintained runtime: 3,258 executable Lua files, 2 generated runtime catalogs;
  282 common declarations/catalogs separately classified. P3 adds 47 policy-free
  registrations; no provider moves or provider body changes in that phase.
- P0 analyzer: 45 cycle manifestations / 13 paths, not 45 independent defects.
  Existing three-file UI/debug import SCC remains. Explicit ownership currently
  has one broad logical SCC; its real edges require P4–P7 review/inversion.
- Boundary debt: zero new; P2 resolved fifteen, P3 resolved four; 189 remain.
  The original debt list is unchanged, never an acceptance waiver.

## Accepted evidence and current validation

- P0: `P0_BASELINE.md`, `P0_ARCHITECTURE.json`, `RETRIEVAL.md` and fixed probe
  definitions. Original seven probes: 37 files / 5,530 lines / 209,522 bytes.
- P1: `OWNERSHIP.md`, compact `DOMAIN_CONTRACTS.json`, dependency/context guards.
- P2: `INVENTORY_PILOT.md`, `P2_VALIDATION.json`. Public item-state/rollback and
  Equipment/Supply seams; obsolete transfer handler removed with command bodies
  preserved. Transfer probe: 5 → 4 files, 3 → 2 handoffs, -10,976 bytes.
- P3: `COMPOSITION_SEAMS.md`, `REGISTRATIONS.json`, `P3_VALIDATION.json`.
  Ordered domain entries reduce root knowledge: 488 → 270 direct imports,
  25,390 → 14,011 bytes. Expanded import/code-barrier trace is identical.
  Registrations add an assembly hop; their domain-local startup surfaces are
  smaller. Complete expanded source/file count is not claimed to shrink.
- Current fixed probes: **36 files / 5,269 lines / 198,850 bytes**; -10,672 bytes
  versus P0, unchanged by P3. Source increases in two P2 hubs are documented.
- Latest full isolated Lua: **978/978**, 4 workers, 9.03 seconds.
  Diagnostic Python: **20/20**. NPC tooling P0 baseline: **6/6**.
- Changed-runtime installed PZ Kahlua: P2 **36/36**, P3 **54/54**;
  static Kahlua zero errors; `git diff --check` clean.
- Immutable P1 semantic-tooling baseline: 194 modules, 124 pass, 65 fail,
  5 GUI-related timeouts; 764 reported tests, 2 skips. In-process discovery
  previously aborted in Tk cleanup (exit 134). These pre-existing failures
  remain unaccepted final gates, bounded in `P0_TOOLING_BASELINE.json`.
  Many assertions count lifecycle fact transport as gameplay dispatch; P5 must
  preserve actual facts and distinguish observability before repairing assertions.
- No native Project Zomboid launched; no Workshop publication.

## Next mandatory chunk

**P4 — Persistence ownership and cycle inversion.**

1. Graph/source map coordinator/lifecycle, domain schemas and repositories,
   migrations, UI/debug consumers and Conversation/Knowledge/WorldDiscovery edges.
2. Record pre-change callers/dependencies/tests and persistence retrieval evidence.
3. Move schema meaning behind owning repositories; keep save/load timing in
   Persistence. Remove deserialization-driven UI/conversation callbacks through
   owned state commits and normal later application paths; preserve behavior.
4. Eliminate real persistence-driven cycles or prove a required composition
   relation. Do not duplicate canonical state to remove imports.
5. Run focused persistence/restart/roundtrip tests, full guards, installed Kahlua,
   fixed probes and diff checks; update this file and continue P5 automatically.

## Remaining gates

P4–P8 and all final developer gates remain mandatory, including semantic-tooling
failures/timeouts. M12 body-binding native acceptance remains user-owned; its
identity/lease, loaded-envelope, restart and visual-authority contracts must be
preserved. Historical refactor logs and root `AGENTS.md` remain unchanged.
