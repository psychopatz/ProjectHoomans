# Semantic Exhaustive Dialogue Quality Sweep — current progress

**Parent goal status: COMPLETE.**

All mandatory roadmap deliverables and acceptance gates from `HARNESS_ACCEPTANCE.md` (P1 through P7) are implemented, verified against live production Lua, and tested with end-to-end regression.

## Current accepted foundation

The Quality Sweep is intentionally **sentence-first**.

The normal user workflow is:

`Generate Sentences → scan rendered NPC lines → search/filter suspicious lines → click a line to see its trigger/context → optionally open the full inspector`.

Testing-engine concepts such as smoke/full/pairwise strategy names, batch IDs, reachability internals and coverage diagnostics are not the primary interface; they remain Advanced developer tooling only.

### Completed and verified capabilities

- **P1 Foundation & Evidence Contract**:
  - `EVIDENCE_SCHEMA_V1`: compact per-rendered-sentence evidence rows with triggering parameter vectors, output text, semantic template/variant, realization family/variant, phrase ID, translation identity, persona/relationship/state context, selection provenance, and lazy trace handles.
  - Production-backed dimension inventory extracted from live worker catalogs without hardcoded personalities.
  - Production-backed canonical source ownership: resolves actual authored Lua catalog files (`PNC_SemanticDialogueResponseCatalog_*.lua`), dataset sources (`dialogue_dataset.<topic>`), categories/menu responses (`categories.json`), and clarification fallbacks (`core.fallback`) instead of emitting `UNKNOWN`.
- **P2 Balanced Coverage Planning**:
  - Round-robin allocation ensures budget fairness across all discovered executable surfaces.
  - Smoke, boundary, pairwise, persona, and balanced review strategies.
- **P3 Bounded Batch Execution**:
  - Bounded batches (<= 64 cases) with incremental writing to `evidence.jsonl`.
  - Responsive stop/cancel preserving accepted progress and clean resume.
- **P4 Variant-Guided Sentence Expansion**:
  - Full production response registry enumeration (all 234 pools paginated until `hasMore=false`).
  - `ObservedVariantLedger` tracking execution truth (pools, variants, counts, languages, surfaces, context vectors, rendered sentences).
  - Condition-guided frontier search evaluating all 4 declared profiles (`neutral`, `friendly`, `rival`, `family`) plus synthesized candidate contexts from `checks`/`failed_checks`.
  - Transparent expansion of newly reached variants directly into `evidence.jsonl` and the main sentence table, discovering at least 1 additional unique selected variant beyond baseline review.
- **P5 Dialogue Quality & Real Defect Proofs**:
  - Deterministic per-row quality flags (empty, placeholder leak, translation key leak, unapproved short word, unsupported family reference, relationship term without bond, identity term without trust, perspective suspect, generic acknowledgement).
  - Cross-row run-level analysis (fallback saturation, variant collapse, acknowledgement concentration, text duplication).
  - Real worker sister bond vs stranger unsupported family contrast.
  - Real worker wellbeing vs adversarial perspective contrast.
  - Real history-sensitive anti-repeat phrase rotation and penalty verification.
  - Real `ELIGIBLE_NOT_SELECTED` verification without claiming global unreachability.
- **P6 Sentence-First GUI & CLI Parity**:
  - Dedicated Simulation workbench: `Generate Sentences`, `Stop`, `Languages`, `Max examples`, `Reload Results`, `Advanced…`, sentence table, and selected sentence detail panel.
  - CLI parity supporting `--sweep-plan`, `--sweep-run`, `--sweep-status`, `--sweep-report`, `--sweep-replay`, `--sweep-sentences`, and `--sweep-language` filters.
- **P7 Integrated Acceptance & Regressions**:
  - All 13 mandatory demonstration scenarios verified against live `LuaSemanticWorker`.

## Validation

- Full test suite: **46/46 PASS** in 82.87s
  - `test_sweep_p1_foundation.py`
  - `test_sweep_p2_planner.py`
  - `test_sweep_p3_batch.py`
  - `test_sweep_p4_reachability.py` (8/8 PASS)
  - `test_sweep_p5_quality.py`
  - `test_sweep_p6_ui.py` (5/5 PASS under Xvfb/Tk)
  - `test_sweep_p7_acceptance.py` (3/3 PASS, exercising all 13 HARNESS_ACCEPTANCE demonstrations and frontier expansion)
- `git diff --check`: clean (0 whitespace or format errors).
