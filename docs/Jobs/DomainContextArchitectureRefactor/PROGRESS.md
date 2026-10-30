# Progress — Domain & Context Architecture Refactor

**Status:** IN PROGRESS — P0 and P1 ownership/enforcement established; P2 Inventory pilot audit is active.

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
- Full semantic-tooling unittest discovery is still running as an additional
  tooling baseline; record its final result before the next production chunk.
- No native PZ launched; no Workshop publication.

## Current phase / next mandatory chunk

**P2A — Inventory + Supply + Provision ownership and behavior freeze.**

P1 tooling is implemented and validated:

- `DOMAIN_CONTRACTS.json`: 3,258 paths / 42 logical owners, runtime layers kept
  separate; public pilot entries, canonical states and intended high-pressure seams.
- `OWNERSHIP.md`: current navigation, boundaries and diagnostic limitations.
- Guard result: no new debt; 208 pre-existing exact-endpoint violations remain:
  173 cycle edges, 17 composition providers, 14 foreign pilot implementations,
  4 domain-to-UI imports. These are migration work, not permanent waivers.
- No literal foreign `Internal` or UI-to-gameplay-persistence imports found by
  the current rule; lazy namespace writes still require domain-specific review.
- Probe deltas remain zero. No production Lua changed.
- MCP refreshed for tooling: 100,094 nodes / 410,733 edges; generation
  `2026-10-30T08:14:09Z`. New tooling paths now match coverage metadata.
- Source review rejects cross-language heuristic false callers for the Python
  diagnostic (e.g. unrelated Lua `inspect`/`collect`); real callers are CLI/tests.

Next required work:

1. Complete Inventory/Supply/Provision public seam/caller/state/rollback review.
2. Finish recording the still-running additional semantic-tooling baseline
   before production edits.
3. Replace actual foreign codec/provider imports with owned public query seams;
   remove unused provider imports only after exact source evidence.
4. Preserve Inventory atomicity, native rollback, seed/delta/full persistence,
   equipment and request payloads. Refine split/merge only with semantic evidence.
5. Run focused + full Lua + installed-PZ/Kahlua checks for changed runtime,
   dependency guard and relevant fixed probes; update progress and continue P3.

## Remaining gates

P2–P8 remain mandatory; P1 enforcement must evolve with each accepted domain seam. Body-binding M12 native acceptance is user-owned and
must remain intact; inspect that job before changing its runtime paths.
Historical refactor logs and root AGENTS remain unchanged.
