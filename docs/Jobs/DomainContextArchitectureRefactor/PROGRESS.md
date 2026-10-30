# Progress — Domain & Context Architecture Refactor

**Status:** IN PROGRESS — P0 source/Lua baseline and fixed retrieval probes established; P1 ownership/enforcement is next.

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
- New cycle-group diagnostic regression tests: **3/3**.
- Probe rerun against P0: zero source/hop deltas.
- `git diff --check`: clean. Runtime Lua unchanged, so no new runtime compile gate.
- Full semantic-tooling unittest discovery is still running as an additional
  tooling baseline; record its final result before the next production chunk.
- No native PZ launched; no Workshop publication.

## Current phase / next mandatory chunk

**P1A — Explicit domain inventory and canonical ownership.**

1. Map current runtime paths to logical owners and runtime layers; replace
   misleading analyzer folder ownership (notably ServerInventory and binding).
2. Record public entries, canonical state, foreign deep imports and real cycle
   edges for high-pressure domains. Preserve useful internal decomposition.
3. P1B: add focused dependency regression guards with explicit existing debt;
   no blanket suppression or arbitrary size limits.
4. P1C: extend the bounded diagnostic as needed for enforceable ownership and
   before/after retrieval comparisons.
5. Continue automatically to P2 Inventory + Supply + Provision pilot.

## Remaining gates

P1–P8 remain mandatory. Body-binding M12 native acceptance is user-owned and
must remain intact; inspect that job before changing its runtime paths.
Historical refactor logs and root AGENTS remain unchanged.
