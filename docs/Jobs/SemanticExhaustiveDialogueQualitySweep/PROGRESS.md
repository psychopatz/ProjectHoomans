# Semantic Exhaustive Dialogue Quality Sweep — current progress

**Parent goal status: IN PROGRESS.**

## Current repository baseline

- ProjectHoomans local main: 9af7cbcf after P2 commit.
- Worktree clean before edits.
- Local main is ahead of origin/main by 20 commits (preserved, unpublished).
- No native Project Zomboid, source-save mutation or Workshop publication occurred.

## Phase state

| Phase | State | Current evidence |
| --- | --- | --- |
| P0 — Source audit / contract freeze | **COMPLETE (planning)** | Current Test Subsystem, Observatory, matrix limits, dimension catalogs and trace fields audited at baseline HEAD; gaps recorded in AUDIT.md. |
| P1 — Evidence + dimension inventory | **COMPLETE** | `pnc.semantic-dialogue-quality-evidence.v1` defined in `sweep_evidence.py`; production-backed dimension inventory extracted from `simulation_control_catalog()` and `persona_catalog()` in `sweep_dimensions.py`; 8 tests pass in `test_sweep_p1_foundation.py` (3.3s) including real-worker projection and lazy trace handles. |
| P2 — Buckets + planner | **COMPLETE** | `sweep_buckets.py` provides bounded policies and production thresholds (PNC_RelationshipConstants, NEED_METER_THRESHOLDS); `sweep_planner.py` implements smoke, boundary, pairwise covering array (100% 2-way pair coverage), persona, and full-bounded union with stable IDs; 7 tests pass in `test_sweep_p2_planner.py` (0.014s). |
| P3 — Batch/resume | **COMPLETE** | `sweep_batch.py` implements `SweepManifest` (`pnc.semantic-dialogue-quality-manifest.v1`), bounded batch execution (<=64 cases), atomic manifest saving, streaming `evidence.jsonl`, cancellation callback, and `StaleFingerprintError` protection; 5 tests pass in `test_sweep_p3_batch.py` (4.2s) including real Lua execution and safe resume. |
| P4 — Reachability/provenance frontier | **IN PROGRESS** | Designing variant reachability analyzer and production provenance join. |
| P5 — Quality flags/clusters | **NOT STARTED** | Requires P4. |
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

## Immediate Next Chunk — P4 (Selection Provenance & Variant Reachability Frontier)

Implement P4A and P4B in `tools/semantic_harness/testing/sweep_reachability.py`:
1. `VariantReachabilityTracker`:
   - Enumerate registered response pools and variants from production worker (`worker.response_pools_list()`, `worker.response_pool_detail()`, or authoring/lineage services).
   - Classify tested state into 5 truthful categories:
     - `UNTESTED`: pool/variant has not been evaluated in tested scenarios.
     - `TESTED_INELIGIBLE`: evaluated in tested context but conditions were not met.
     - `ELIGIBLE_NOT_SELECTED`: eligible under production score/conditions, but another candidate was selected (dominated).
     - `SELECTED`: chosen as the winning response in at least one tested context.
     - `SELECTED_UNDER_SUSPICIOUS_CONTEXT`: selected but with relationship/bond/need mismatch flags.
   - Crucial constraint: Never label finite non-selection as globally impossible or unreachable.
2. Selection provenance join:
   - Deep join with `inspect_response_turn` and `inspect_codebuilder_lineage`.
   - Distinguish exact emitted variant ID vs template candidate matches vs explicit UNKNOWN.
3. Unit tests in `test_sweep_p4_reachability.py`:
   - Categorization of tested vs untested vs dominated variants.
   - No overclaiming of global unreachability.
   - Integration with real Lua worker selection trace.

## Stop rules

Do not report the parent goal complete because:

- P1 passes;
- one 64-case batch runs;
- one bad sentence such as family is detected;
- a quality report is generated;
- CLI works before GUI;
- GUI works before performance/regression gates.

Stop only at complete developer-side acceptance, a genuine blocker after all safe independent work, or an explicitly user-owned native gate after all implementation work is done.
