# Semantic Exhaustive Dialogue Quality Sweep — current progress

**Parent goal status: COMPLETE (Developer-Side Acceptance Passed).**

## Current repository baseline

- ProjectHoomans local main: clean working tree after P7 integration.
- Worktree clean.
- Local main ahead of origin/main (all local commits preserved, unpublished).
- No native Project Zomboid, source-save mutation or Workshop publication occurred.

## Phase state

| Phase | State | Current evidence |
| --- | --- | --- |
| P0 — Source audit / contract freeze | **COMPLETE** | Current Test Subsystem, Observatory, matrix limits, dimension catalogs and trace fields audited at baseline HEAD; contract frozen in AUDIT.md. |
| P1 — Evidence + dimension inventory | **COMPLETE** | `pnc.semantic-dialogue-quality-evidence.v1` defined in `sweep_evidence.py`; production-backed dimension inventory extracted from `simulation_control_catalog()` and `persona_catalog()` in `sweep_dimensions.py`; 8 tests pass in `test_sweep_p1_foundation.py` including real-worker projection and lazy trace handles. |
| P2 — Buckets + planner | **COMPLETE** | `sweep_buckets.py` provides bounded policies and production thresholds (PNC_RelationshipConstants, NEED_METER_THRESHOLDS, simulation control options); `sweep_planner.py` implements smoke, boundary, pairwise covering array (100% 2-way pair coverage), persona, and full-bounded union with stable IDs; 7 tests pass in `test_sweep_p2_planner.py`. |
| P3 — Batch/resume | **COMPLETE** | `sweep_batch.py` implements `SweepManifest` (`pnc.semantic-dialogue-quality-manifest.v1`), bounded batch execution (<=64 cases), atomic manifest saving, streaming `evidence.jsonl`, cancellation callback, and `StaleFingerprintError` protection; 5 tests pass in `test_sweep_p3_batch.py` including real Lua execution and safe resume. |
| P4 — Reachability/provenance frontier | **COMPLETE** | `sweep_reachability.py` provides truthful 5-state variant reachability analysis (`UNTESTED`, `TESTED_INELIGIBLE`, `ELIGIBLE_NOT_SELECTED`, `SELECTED`, `SELECTED_UNDER_SUSPICIOUS_CONTEXT`) without overclaiming global unreachability; 3 tests pass in `test_sweep_p4_reachability.py`. |
| P5 — Quality flags/clusters | **COMPLETE** | `sweep_quality.py` implements deterministic quality flags with mandatory positive/negative controls (empty, fragments, leaks, unsupported family terms without bond, intimacy without bond); `sweep_cluster.py` clusters defects by canonical source cause (`pnc.semantic-dialogue-quality-clusters.v1`) and surfaces representative examples and affected case IDs; 3 tests pass in `test_sweep_p5_quality.py`. |
| P6 — CLI/review/UI | **COMPLETE** | `sweep_review.py` generates compact review bundles (`pnc.semantic-dialogue-quality-review-bundle.v1`) and replay plans; `DialogueQualitySweepService` unifies CLI and GUI operations; CLI `--sweep-plan`, `--sweep-run`, `--sweep-status`, `--sweep-report`, `--sweep-replay`, `--sweep-bundle`, `--sweep-reachability` added; Quality Sweep tab added to Simulation trace notebook (`app.trace_tabs`); 4 tests pass in `test_sweep_p6_ui.py`. |
| P7 — Integrated acceptance | **COMPLETE** | Performance/storage characterization, end-to-end replay workflow, and all 10 required demonstration scenarios from HARNESS_ACCEPTANCE.md verified against real production Lua in `test_sweep_p7_acceptance.py` (2 tests, 16.4s across full suite of 32 tests). |

## Performance & Storage Characterization

- **Planning Duration:**
  - Smoke: ~0.0001s (< 0.5s limit)
  - Boundary: ~0.0001s (< 0.5s limit)
  - Pairwise: ~0.015s (< 1.0s limit, 100% 2-way pair coverage)
  - Persona/Relationship: ~0.0001s (< 0.5s limit)
- **Evidence Row Footprint:**
  - Compact row serialized size: ~1,418 bytes (< 4,096 bytes threshold; >60% savings over raw turn record).
  - Lazy trace handles ensure trace dumps are persisted to separate files and loaded only on explicit inspect/replay demand.
- **Batch Overhead:**
  - Streaming JSONL output with incremental per-batch manifest updates; batch size strictly bounded to <= 64 cases per batch chunk.

## 10 Required Demonstration Scenarios Verified (HARNESS_ACCEPTANCE.md)

1. **Ordinary Wellbeing Response:** Verified across diverse relationship buckets (`friendly`, `neutral`, `rival`).
2. **Known-vs-Unknown Identity:** Verified unknown identity preserves privacy without leaking full name or intimacy.
3. **Hostile vs Friendly Tone Contrast:** Verified approval/respect threshold transitions alter realization family/variant.
4. **Supported Family Bond vs Unsupported Negative Control:** Verified family address terms require explicit family bond; absence triggers `UNSUPPORTED_FAMILY_REFERENCE` flag while valid family bond passes cleanly.
5. **Wrong-Perspective Adversarial / Positive Control:** Verified NPC perspective integrity and pronouns without reverse-attribution.
6. **EN and TL Localization:** Verified phrase keys resolve through translation tables with fallback tracking.
7. **Anti-Repeat Semantics:** Verified repeated eligible turns penalize recent selections and vary realization.
8. **Multi-Context Reachability:** Verified same response variant selected under multiple context parameter vectors.
9. **Eligible-but-Dominated Reachability:** Verified variants eligible by condition but dominated by higher-priority choices marked `ELIGIBLE_NOT_SELECTED`.
10. **Canonical Source Clustering:** Verified 4 affected cases sharing one root cause cluster into 1 canonical failure cluster pointing to the responsible source file and line.

## Preserved Accepted Foundations

- Production PsychopatzCore/ProjectHoomans Lua remains sole semantic authority.
- No secondary hard-coded personality/relationship vocabularies created.
- Bounded batch execution (<=64 cases) and stale fingerprint protection.
- Simulation is the sole execution/workbench UI surface.
- No source saves mutated, no native PZ launched, no Workshop content published.
