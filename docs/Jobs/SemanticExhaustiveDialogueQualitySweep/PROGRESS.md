# Semantic Exhaustive Dialogue Quality Sweep — current progress

**Parent goal status: IN PROGRESS.**

## Current repository baseline

- ProjectHoomans local main: 25ef210b after P3 commit.
- Worktree clean before edits.
- Local main is ahead of origin/main by 21 commits (preserved, unpublished).
- No native Project Zomboid, source-save mutation or Workshop publication occurred.

## Phase state

| Phase | State | Current evidence |
| --- | --- | --- |
| P0 — Source audit / contract freeze | **COMPLETE (planning)** | Current Test Subsystem, Observatory, matrix limits, dimension catalogs and trace fields audited at baseline HEAD; gaps recorded in AUDIT.md. |
| P1 — Evidence + dimension inventory | **COMPLETE** | `pnc.semantic-dialogue-quality-evidence.v1` defined in `sweep_evidence.py`; production-backed dimension inventory extracted from `simulation_control_catalog()` and `persona_catalog()` in `sweep_dimensions.py`; 8 tests pass in `test_sweep_p1_foundation.py` (3.3s) including real-worker projection and lazy trace handles. |
| P2 — Buckets + planner | **COMPLETE** | `sweep_buckets.py` provides bounded policies and production thresholds (PNC_RelationshipConstants, NEED_METER_THRESHOLDS); `sweep_planner.py` implements smoke, boundary, pairwise covering array (100% 2-way pair coverage), persona, and full-bounded union with stable IDs; 7 tests pass in `test_sweep_p2_planner.py` (0.014s). |
| P3 — Batch/resume | **COMPLETE** | `sweep_batch.py` implements `SweepManifest` (`pnc.semantic-dialogue-quality-manifest.v1`), bounded batch execution (<=64 cases), atomic manifest saving, streaming `evidence.jsonl`, cancellation callback, and `StaleFingerprintError` protection; 5 tests pass in `test_sweep_p3_batch.py` (4.2s) including real Lua execution and safe resume. |
| P4 — Reachability/provenance frontier | **COMPLETE** | `sweep_reachability.py` provides truthful 5-state variant reachability analysis (`UNTESTED`, `TESTED_INELIGIBLE`, `ELIGIBLE_NOT_SELECTED`, `SELECTED`, `SELECTED_UNDER_SUSPICIOUS_CONTEXT`) without overclaiming global unreachability; 3 tests pass in `test_sweep_p4_reachability.py` (1.4s). |
| P5 — Quality flags/clusters | **IN PROGRESS** | Designing deterministic dialogue quality analyzer, known defect classes (`family` term without bond), and canonical-source clustering. |
| P6 — CLI/review/UI | **NOT STARTED** | Requires P5. |
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

## Immediate Next Chunk — P5 (Dialogue Quality Analyzer & Canonical-Source Clustering)

Implement P5A, P5B, and P5C in `tools/semantic_harness/testing/sweep_quality.py` and `sweep_cluster.py`:
1. `QualityAnalyzer`:
   - High-confidence deterministic flags with severity (`CRITICAL`, `HIGH`, `MEDIUM`, `LOW`, `INFO`) and confidence (`DEFINITE`, `SUSPECT`, `REVIEW`):
     - `EMPTY_RESPONSE`
     - `ONE_WORD_RESPONSE`
     - `VERY_SHORT_FRAGMENT`
     - `EXCESSIVE_LENGTH`
     - `PLACEHOLDER_LEAK` (e.g. `{0}`, `%s`, `<var>`, `NaN`, `nil`)
     - `TRANSLATION_KEY_LEAK` (e.g. strings starting with `IGUI_` or `UI_`)
     - `MISSING_REQUIRED_ARGUMENT`
     - `DUPLICATE_RENDERED_TEXT`
     - `REPEATED_RECENT_TEXT`
     - `UNSUPPORTED_FAMILY_REFERENCE` (e.g. "family", "sister", "brother", "mother", "father" when bond context is not a family bond!)
     - `RELATIONSHIP_TERM_WITHOUT_BOND` (intimacy/romantic terms when bond is not lover)
     - `IDENTITY_TERM_WITHOUT_KNOWLEDGE` (private name usage when familiarity < 5 or identityTrust < 50)
     - `PERSPECTIVE_SUSPECT` (uses semantic subject/referent information)
     - `GENERIC_ACKNOWLEDGEMENT_SUSPECT`
   - Mandatory negative controls:
     - Short valid words ("Yeah.", "No.", "Right.") are NOT flagged as fragments if intentional.
     - Family terms ("family", "sister", "brother") are NOT flagged when supported by valid family bond context!
2. Canonical-source Clustering (`sweep_cluster.py`):
   - Clusters rows by root cause:
     - `canonicalSourceOwner + phraseID / semanticVariantID`
     - `responsePool + realizationFamily`
     - `qualityFlagSignature`
   - Surfaces representative examples, affected context ranges, affected case IDs, and suggested remedy.
3. User-observed defect demonstration:
   - Prove the one-word "family" defect class: when rendered text is "family" (or contains family address) but bond is None or not family, it is flagged as `UNSUPPORTED_FAMILY_REFERENCE` (CRITICAL / DEFINITE). When bond is "sister" or "family", it passes cleanly as supported.

## Stop rules

Do not report the parent goal complete because:

- P1 passes;
- one 64-case batch runs;
- one bad sentence such as family is detected;
- a quality report is generated;
- CLI works before GUI;
- GUI works before performance/regression gates.

Stop only at complete developer-side acceptance, a genuine blocker after all safe independent work, or an explicitly user-owned native gate after all implementation work is done.
