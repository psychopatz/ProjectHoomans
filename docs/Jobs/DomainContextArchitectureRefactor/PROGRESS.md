# Progress — Domain & Context Architecture Refactor

**Status:** IN PROGRESS — P2 Inventory capsule pilot developer-validated; P3 composition seams are next.

## Parent objective

Complete P0–P8 in `ROADMAP.md` and every developer gate in `ACCEPTANCE.md`.
P0 completion does not complete this goal. No production architecture changed yet.

## Verified current state

- Existing `main`, source baseline `15cadee70be11b790ce4c48bfb7bd51badd8233b`.
- Initially clean; origin fetched; ahead 7 / behind 0. No concurrent edits observed.
- MCP `project-hoomans` explicitly refreshed: 99,748 nodes / 409,550 edges;
  3,260 current runtime Lua files. Matching HEAD had hidden stale graph contents.
- Tier 2 coverage: 600 composition/cycle paths plus 53 probe/test paths checked;
  no recorded gaps, metadata matched. Excluded caches/venv classified separately.
- Fresh analyzer: 285 findings, 45 cycle manifestations / 13 paths; three folder
  SCC groups and one UI/debug file-import SCC. See `P0_BASELINE.md` and
  `P0_ARCHITECTURE.json`; these are not 45 independent architectural defects.
- Maintained executable runtime: 3,258 files; generated runtime catalogs: 2;
  common Lua declarations/catalogs: 282, reported separately from runtime policy.
- Seven fixed probes: 37 unique source files / 5,530 lines / 209,522 bytes.
  Definitions, affected tests, foreign interactions, reviewed hops and cycle
  interpretation: `RETRIEVAL.md`, `RETRIEVAL_PROBES.json`, `P0_RETRIEVAL.json`.
  Saved both-direction MCP traces: `P0_MCP_TRACES.json`.
- Known MCP heuristic alias errors and incomplete statement-form IMPORTS are
  explicitly documented. Source/literal-import evidence supplements graph data.

## Validation

- Full isolated Lua baseline: **978/978**, 4 workers, 8.92 seconds.
- NPC tooling baseline: **6/6** Python tests.
- Architecture ownership/cycle/debt regression tests: **11/11**.
- Probe rerun against P0: zero source/hop deltas.
- `git diff --check`: clean. Runtime Lua unchanged, so no new runtime compile gate.
- Full in-process semantic-tooling baseline aborted with a pre-existing Tk
  cleanup/thread failure (exit 134), before any production changes. An isolated
  per-module retry runs against an immutable P1 archive; current baseline failures
  are being collected and remain unaccepted final gates.
- No native PZ launched; no Workshop publication.

## Current phase / next mandatory chunk

**P3 — Composition roots depend on domain registration seams.**

P2 accepted evidence (`INVENTORY_PILOT.md`, `P2_VALIDATION.json`):

- Inventory owns snapshot restoration and public item-state interop; foreign
  codec imports removed (four real users migrated; eight unused bindings removed).
- Equipment/Inventory/Supply queries and commands replace foreign private table
  accesses in combat, authoring, scavenge, production, refill and compatibility.
- Generic transfer owns gift replay; medical sharing stays independent. Deleted
  the obsolete handler/handoff; both public command bodies match P0 exactly.
- Full Lua **978/978**; focused **109/109**; diagnostics **13/13**;
  installed PZ Kahlua **36/36**, static Kahlua **zero errors**, diff check clean.
- Guard: zero new debt, fifteen resolved import/composition issues. Declared
  foreign pilot private-root accesses: zero. Namespace alias coverage remains
  bounded; source/MCP review is still required for arbitrary dynamic data flow.
- Fixed probes now 36 unique files / 5,269 lines / 198,850 bytes: **-10,672 bytes**
  versus P0. Transfer probe: 5 -> 4 files, 3 -> 2 handoffs, -10,976 bytes.
- Small hub increases are explained in the pilot document; file count was not
  used as a standalone acceptance target.
- Existing semantic-tooling baseline is immutable at P1; isolated retry has
  exposed pre-existing fact-transport/legacy-fixture failures. Complete/classify
  its report and close those gates during Semantics/final acceptance.

Next required work:

1. Establish small registration entries for coherent ordered domain segments.
2. Preserve exact expanded bootstrap order and partial SP/MP loader behavior;
   do not collect interleaved providers early or add service-locator indirection.
3. Migrate composition away from leaf knowledge using the proven pilot rules.
4. Run composition/bootstrap, relevant focused tests, dependency/context guards
   and changed-runtime installed-PZ/Kahlua checks, then continue P4 automatically.
5. Before Presence/binding-related composition edits, preserve the inspected M12
   identity/incarnation, loaded-envelope, restart and visual-authority contracts.

## Remaining gates

P3–P8 remain mandatory; enforcement evolves with each accepted domain seam. Body-binding M12 native acceptance is user-owned and
must remain intact; inspect that job before changing its runtime paths.
Historical refactor logs and root AGENTS remain unchanged.
