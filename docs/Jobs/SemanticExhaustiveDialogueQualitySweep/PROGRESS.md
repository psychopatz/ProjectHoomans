# Semantic Exhaustive Dialogue Quality Sweep — current progress

**Parent goal status: IN PROGRESS.**

## Current repository baseline

- ProjectHoomans local main: 160db022 after P5 commit.
- Worktree clean before edits.
- Local main is ahead of origin/main by 23 commits (preserved, unpublished).
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
| P6 — CLI/review/UI | **COMPLETE** | `sweep_review.py` generates compact review bundles (`pnc.semantic-dialogue-quality-review-bundle.v1`) and replay plans; `DialogueQualitySweepService` unifies CLI and GUI operations; CLI `--sweep-plan`, `--sweep-run`, `--sweep-status`, `--sweep-report`, `--sweep-replay` added; Quality Sweep tab added to Simulation trace panel; 4 tests pass in `test_sweep_p6_ui.py` (1.2s). |
| P7 — Integrated acceptance | **IN PROGRESS** | End-to-end quality workflow demonstration, performance & storage characterization, full developer acceptance test suite, and clean closeout. |

## Preserved accepted foundations

Do not regress or rebuild:

- completed docs/Jobs/SemanticTestSubsystem/ architecture and fixture runner;
- completed docs/Jobs/SemanticObservatoryDialogueQuality/ production observability/source/Simulation contracts;
- LuaSemanticWorker as execution authority;
- existing Conversation Inspector projections;
- existing Simulation control/persona catalogs;
- existing CodeBuilder/Dialogue Content canonical source ownership;
- existing GUI isolation and Simulation-vs-Studio ownership rules.

## Immediate Next Chunk — P7 (Integrated Performance, Regression & Developer Closeout)

1. Performance & Storage Characterization (`test_sweep_p7_acceptance.py`):
   - Measure planning time across strategies.
   - Measure compact evidence row byte size (< 2 KiB/row).
   - Measure batch overhead and streaming throughput.
   - Prove lazy trace handle avoids loading large inspector dumps into memory.
2. End-to-End Targeted Repair/Replay Workflow:
   - Demonstrate: plan → run batches → detect defect cluster (e.g. unsupported family term) → inspect canonical cause → replay affected cases → verify resolution and non-text invariant preservation.
3. 10 Required Demonstration Scenarios from HARNESS_ACCEPTANCE.md:
   1. Ordinary wellbeing response across multiple persona/relationship buckets.
   2. Known-vs-unknown identity/relationship wording.
   3. Hostile vs friendly response-tone contrast.
   4. Supported family/bond wording and unsupported-family negative control.
   5. One wrong-perspective adversarial case or known-good perspective negative control.
   6. EN and TL.
   7. Anti-repeat history across repeated eligible turns.
   8. Response variant selected under more than one context.
   9. Eligible-but-dominated variant.
   10. At least one cluster where one canonical source explains multiple bad/suspicious rows.
4. Regression gates:
   - Full test run of `test_sweep_*.py`.
   - Existing semantic test subsystem regression.
   - Response observatory matrix regression.
   - Kahlua verifier on any touched Lua.
   - `git diff --check` passes cleanly.

## Stop rules

Do not report the parent goal complete because:

- P1 passes;
- one 64-case batch runs;
- one bad sentence such as family is detected;
- a quality report is generated;
- CLI works before GUI;
- GUI works before performance/regression gates.

Stop only at complete developer-side acceptance, a genuine blocker after all safe independent work, or an explicitly user-owned native gate after all implementation work is done.
