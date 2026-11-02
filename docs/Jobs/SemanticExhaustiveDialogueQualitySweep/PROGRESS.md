# Semantic Exhaustive Dialogue Quality Sweep — current progress

**Parent goal status: IN PROGRESS.**

## Current repository baseline

- ProjectHoomans local main: b2c75991 after P4 commit.
- Worktree clean before edits.
- Local main is ahead of origin/main by 22 commits (preserved, unpublished).
- No native Project Zomboid, source-save mutation or Workshop publication occurred.

## Phase state

| Phase | State | Current evidence |
| --- | --- | --- |
| P0 — Source audit / contract freeze | **COMPLETE (planning)** | Current Test Subsystem, Observatory, matrix limits, dimension catalogs and trace fields audited at baseline HEAD; gaps recorded in AUDIT.md. |
| P1 — Evidence + dimension inventory | **COMPLETE** | `pnc.semantic-dialogue-quality-evidence.v1` defined in `sweep_evidence.py`; production-backed dimension inventory extracted from `simulation_control_catalog()` and `persona_catalog()` in `sweep_dimensions.py`; 8 tests pass in `test_sweep_p1_foundation.py` (3.3s) including real-worker projection and lazy trace handles. |
| P2 — Buckets + planner | **COMPLETE** | `sweep_buckets.py` provides bounded policies and production thresholds (PNC_RelationshipConstants, NEED_METER_THRESHOLDS); `sweep_planner.py` implements smoke, boundary, pairwise covering array (100% 2-way pair coverage), persona, and full-bounded union with stable IDs; 7 tests pass in `test_sweep_p2_planner.py` (0.014s). |
| P3 — Batch/resume | **COMPLETE** | `sweep_batch.py` implements `SweepManifest` (`pnc.semantic-dialogue-quality-manifest.v1`), bounded batch execution (<=64 cases), atomic manifest saving, streaming `evidence.jsonl`, cancellation callback, and `StaleFingerprintError` protection; 5 tests pass in `test_sweep_p3_batch.py` (4.2s) including real Lua execution and safe resume. |
| P4 — Reachability/provenance frontier | **COMPLETE** | `sweep_reachability.py` provides truthful 5-state variant reachability analysis (`UNTESTED`, `TESTED_INELIGIBLE`, `ELIGIBLE_NOT_SELECTED`, `SELECTED`, `SELECTED_UNDER_SUSPICIOUS_CONTEXT`) without overclaiming global unreachability; 3 tests pass in `test_sweep_p4_reachability.py` (1.4s). |
| P5 — Quality flags/clusters | **COMPLETE** | `sweep_quality.py` implements deterministic quality flags with mandatory positive/negative controls (empty, fragments, leaks, unsupported family terms without bond, intimacy without bond); `sweep_cluster.py` clusters defects by canonical source cause and surfaces representative examples and affected case IDs; 3 tests pass in `test_sweep_p5_quality.py` (0.001s). |
| P6 — CLI/review/UI | **IN PROGRESS** | Designing CLI commands, LLM review bundles, targeted replay, and Simulation Quality Sweep UI tab. |
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

## Immediate Next Chunk — P6 (Agent CLI, Review Bundles, Targeted Replay, and Simulation UI)

Implement P6A, P6B, and P6C:
1. `tools/semantic_harness/testing/sweep_review.py`:
   - LLM review bundles: token-efficient summaries of defective clusters (3-10 representative examples, context ranges, canonical source owners, contrast examples).
   - Targeted affected replay: loads affected case IDs from clusters or filter criteria and replays them into a new targeted batch run.
2. `tools/semantic_harness/testing/sweep_service.py` & CLI integration (`tools/semantic_harness/cli.py`):
   - `sweep plan --strategy <smoke|boundary|pairwise|persona|full> --sweep-id <id>`
   - `sweep run --sweep-id <id> [--resume] [--batch-size 64]`
   - `sweep status --sweep-id <id>`
   - `sweep report --sweep-id <id> [--severity <sev>] [--flag <flag>] [--bundle]`
   - `sweep replay --sweep-id <id> --cluster-id <cid> | --case-id <cid>`
3. Simulation Quality Sweep GUI:
   - Added inside existing Simulation workbench (`tools/semantic_harness/ui/simulation_sweep_panel.py`).
   - Strategy selector, plan estimate, batch progress bar, cluster list with severity badges, compact evidence table, lazy Conversation Inspector link, and targeted replay button.
   - Hermetic UI tests in `test_sweep_p6_ui.py`.

## Stop rules

Do not report the parent goal complete because:

- P1 passes;
- one 64-case batch runs;
- one bad sentence such as family is detected;
- a quality report is generated;
- CLI works before GUI;
- GUI works before performance/regression gates.

Stop only at complete developer-side acceptance, a genuine blocker after all safe independent work, or an explicitly user-owned native gate after all implementation work is done.
