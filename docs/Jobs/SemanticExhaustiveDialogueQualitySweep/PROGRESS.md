# Semantic Exhaustive Dialogue Quality Sweep — current progress

**Parent goal status: IN PROGRESS.**

## Current repository baseline

- ProjectHoomans local main: c6d4b602 before P1 foundation commits.
- Worktree clean before edits.
- Local main is ahead of origin/main by 18 commits (preserved, unpublished).
- No native Project Zomboid, source-save mutation or Workshop publication occurred.

## Phase state

| Phase | State | Current evidence |
| --- | --- | --- |
| P0 — Source audit / contract freeze | **COMPLETE (planning)** | Current Test Subsystem, Observatory, matrix limits, dimension catalogs and trace fields audited at baseline HEAD; gaps recorded in AUDIT.md. |
| P1 — Evidence + dimension inventory | **COMPLETE** | `pnc.semantic-dialogue-quality-evidence.v1` defined in `sweep_evidence.py`; production-backed dimension inventory extracted from `simulation_control_catalog()` and `persona_catalog()` in `sweep_dimensions.py`; 8 tests pass in `test_sweep_p1_foundation.py` (3.3s) including real-worker projection and lazy trace handles. |
| P2 — Buckets + planner | **IN PROGRESS** | Designing semantic bucket policies and deterministic coverage planner (smoke, boundary, pairwise, persona, full-bounded). |
| P3 — Batch/resume | **NOT STARTED** | Requires P2. |
| P4 — Reachability/provenance frontier | **NOT STARTED** | Requires P2/P3. |
| P5 — Quality flags/clusters | **NOT STARTED** | Requires P1–P4. |
| P6 — CLI/review/UI | **NOT STARTED** | Requires P1–P5. |
| P7 — Integrated acceptance | **NOT STARTED** | Requires P1–P6. |

## Preserved accepted foundations

Do not regress or rebuild:

- completed docs/Jobs/SemanticTestSubsystem/ architecture and fixture runner;
- completed docs/Jobs/SemanticObservatoryDialogueQuality/ production observability/source/Simulation contracts;
- LuaSemanticWorker as execution authority;
- existing Conversation Inspector projections;
- existing Simulation control/persona catalogs;
- existing CodeBuilder/Dialogue Content canonical source ownership;
- existing GUI isolation and Simulation-vs-Studio ownership rules.

## Immediate Next Chunk — P2 (Semantic Buckets & Deterministic Coverage Planner)

Implement P2A and P2B in `tools/semantic_harness/testing/`:
1. `sweep_buckets.py`:
   - Bounded semantic bucket policies for numeric/enum dimensions (endpoints, neutral/default, documented production thresholds, just-below/at/just-above neighbor values).
   - Provenance and rationale recorded for each bucket policy (e.g. relationship standing thresholds, survival need urgency thresholds, personality extremes/midpoints).
   - Threshold-neighbor validation proving expected branch/eligibility boundary points.
2. `sweep_planner.py`:
   - Deterministic coverage strategies:
     - Smoke: 1 representative/baseline case per target surface.
     - Boundary: each dimension swept through its bucket values while other dimensions remain at baseline, plus threshold neighbors.
     - Pairwise: deterministic covering array ensuring every valid pair of bucket values across selected dimensions is covered at least once.
     - Persona/relationship: targeted personality/traits/bond/relationship matrix without explosion.
     - Full-bounded: deterministic deduplicated union of declared strategies.
   - Stable deterministic case ID computation (`sweep_id:strategy:surface:hash`).
   - Case count estimation and batch count estimation before execution.
   - Configurable max cases cap and scope filtering.
3. Unit tests in `test_sweep_p2_planner.py`:
   - Verify pairwise property (100% 2-way pair coverage across selected dimensions).
   - Verify deterministic case ID stability across runs.
   - Verify threshold-neighbor generation.
   - Verify cap enforcement and batch estimation.

## Stop rules

Do not report the parent goal complete because:

- P1 passes;
- one 64-case batch runs;
- one bad sentence such as family is detected;
- a quality report is generated;
- CLI works before GUI;
- GUI works before performance/regression gates.

Stop only at complete developer-side acceptance, a genuine blocker after all safe independent work, or an explicitly user-owned native gate after all implementation work is done.
