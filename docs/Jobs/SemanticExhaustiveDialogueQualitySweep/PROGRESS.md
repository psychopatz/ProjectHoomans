# Semantic Exhaustive Dialogue Quality Sweep — current progress

**Parent goal status: IN PROGRESS.**

## Current repository baseline

- ProjectHoomans local main: e7941c97 after P1 foundation commit.
- Worktree clean before edits.
- Local main is ahead of origin/main by 19 commits (preserved, unpublished).
- No native Project Zomboid, source-save mutation or Workshop publication occurred.

## Phase state

| Phase | State | Current evidence |
| --- | --- | --- |
| P0 — Source audit / contract freeze | **COMPLETE (planning)** | Current Test Subsystem, Observatory, matrix limits, dimension catalogs and trace fields audited at baseline HEAD; gaps recorded in AUDIT.md. |
| P1 — Evidence + dimension inventory | **COMPLETE** | `pnc.semantic-dialogue-quality-evidence.v1` defined in `sweep_evidence.py`; production-backed dimension inventory extracted from `simulation_control_catalog()` and `persona_catalog()` in `sweep_dimensions.py`; 8 tests pass in `test_sweep_p1_foundation.py` (3.3s) including real-worker projection and lazy trace handles. |
| P2 — Buckets + planner | **COMPLETE** | `sweep_buckets.py` provides bounded policies and production thresholds (PNC_RelationshipConstants, NEED_METER_THRESHOLDS); `sweep_planner.py` implements smoke, boundary, pairwise covering array (100% 2-way pair coverage), persona, and full-bounded union with stable IDs; 7 tests pass in `test_sweep_p2_planner.py` (0.014s). |
| P3 — Batch/resume | **IN PROGRESS** | Designing bounded batch executor (<=64 cases per batch), manifest tracking, JSONL artifact storage, and stale-fingerprint rejection. |
| P4 — Reachability/provenance frontier | **NOT STARTED** | Requires P3. |
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

## Immediate Next Chunk — P3 (Bounded Batch Execution, Artifacts & Resume)

Implement P3A and P3B in `tools/semantic_harness/testing/sweep_batch.py`:
1. `SweepBatch`:
   - Grouping of planned cases into bounded chunks (default <=64).
   - Batch status: PENDING, RUNNING, COMPLETED, FAILED, CANCELLED.
   - Batch results containing compact evidence rows and timing diagnostics.
2. `SweepManifest`:
   - Schema: `pnc.semantic-dialogue-quality-manifest.v1`.
   - Records sweep ID, plan digest, strategy, catalog/source fingerprints, total cases, batch list, completed/failed/incomplete counts, output artifact paths, timestamp.
   - Safe resume logic: verifies catalog/fingerprint match. Rejects stale fingerprints with explicit error.
3. `BatchExecutor`:
   - Runs batches sequentially through `LuaSemanticWorker` (isolated workers per case or session).
   - Converts `PlannedCase` into executable declarative turn requests.
   - Collects compact evidence rows and streams them to a JSONL file in a gitignored cache directory (e.g., `tools/semantic_harness/reports/sweeps/{sweep_id}/evidence.jsonl`).
   - Ensures no files are created inside watched Project Zomboid `media/` trees or player saves.
   - Cancellation and partial progress safety.
4. Unit tests in `test_sweep_p3_batch.py`:
   - Batch creation and <=64 case boundary.
   - Manifest serialization and deserialization.
   - Safe resume skipping completed batches.
   - Stale catalog fingerprint rejection.
   - Real-worker batch execution emitting compact JSONL evidence rows.

## Stop rules

Do not report the parent goal complete because:

- P1 passes;
- one 64-case batch runs;
- one bad sentence such as family is detected;
- a quality report is generated;
- CLI works before GUI;
- GUI works before performance/regression gates.

Stop only at complete developer-side acceptance, a genuine blocker after all safe independent work, or an explicitly user-owned native gate after all implementation work is done.
