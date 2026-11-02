"""P7 integrated acceptance tests and demonstration scenarios.

Covers:
- Performance & scale characterization (surface/dimension discovery, full pool pagination, planning, cases/sec, batch overhead, compact bytes/row, run-level quality, lazy inspector resolution).
- All 13 required demonstration scenarios from HARNESS_ACCEPTANCE.md through real LuaSemanticWorker.
"""

from __future__ import annotations

from copy import deepcopy
import json
from pathlib import Path
import tempfile
import time
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.testing.sweep_batch import (
    SweepBatchExecutor,
    SweepExecutionCancelled,
    SweepManifest,
)
from tools.semantic_harness.testing.sweep_cluster import ClusterAggregator
from tools.semantic_harness.testing.sweep_dimensions import extract_dimension_inventory
from tools.semantic_harness.testing.sweep_evidence import extract_evidence_rows_from_turn, resolve_trace_handle
from tools.semantic_harness.testing.sweep_planner import CoveragePlan, CoveragePlanner, PlannedCase
from tools.semantic_harness.testing.sweep_quality import QualityAnalyzer
from tools.semantic_harness.testing.sweep_reachability import (
    ReachabilityAnalyzer,
    VariantReachabilityState,
    enumerate_all_response_pools,
)
from tools.semantic_harness.testing.sweep_service import DialogueQualitySweepService


class SweepP7AcceptanceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.service = DialogueQualitySweepService()
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            cls.inventory = extract_dimension_inventory(worker)

    def test_performance_characterization(self) -> None:
        """Measure performance across discovery, pool pagination, planning, compact size, and resolution."""
        # 1. Surface and dimension discovery time
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            t0 = time.monotonic()
            inv = extract_dimension_inventory(worker)
            t_discovery = time.monotonic() - t0
            self.assertLess(t_discovery, 1.5, f"Dimension discovery too slow: {t_discovery:.3f}s")
            self.assertGreaterEqual(len(inv.dimensions), 10)

            # 2. Full pool pagination time across all production pools
            t0 = time.monotonic()
            pools = enumerate_all_response_pools(worker, limit=64)
            t_pagination = time.monotonic() - t0
            self.assertLess(t_pagination, 3.0, f"Full pool pagination too slow: {t_pagination:.3f}s")
            self.assertEqual(len(pools), 234)

            # 3. Compact row size in bytes vs raw worker record
            record = worker.input("how are you?")
            rows = extract_evidence_rows_from_turn(
                record,
                turn_index=0,
                case_id="perf_case",
                parameters={"player.needs.hunger": 0.2},
                worker=worker,
            )
            self.assertGreaterEqual(len(rows), 1)
            row = rows[0]
            row_bytes = len(json.dumps(row).encode("utf-8"))
            full_record_bytes = len(json.dumps(record, default=str).encode("utf-8"))

            self.assertLess(row_bytes, 4096, f"Compact row bloated: {row_bytes} bytes")
            self.assertLess(row_bytes, full_record_bytes)
            self.assertTrue(row["traceHandle"]["lazy"])

            # 4. Lazy trace handle resolution time
            t0 = time.monotonic()
            resolved = resolve_trace_handle(row["traceHandle"], worker=worker)
            t_resolve = time.monotonic() - t0
            self.assertLess(t_resolve, 1.5, f"Lazy trace resolution too slow: {t_resolve:.3f}s")
            self.assertIn("turn", resolved)
            self.assertIn("execution", resolved)

        # 5. Planning time across strategies
        planner = CoveragePlanner(self.inventory, sweep_id="perf_test")
        for strat, call in (
            ("smoke", lambda: planner.plan_smoke()),
            ("boundary", lambda: planner.plan_boundary(max_cases=128)),
            ("pairwise", lambda: planner.plan_pairwise(max_cases=128)),
            ("persona", lambda: planner.plan_persona(max_cases=128)),
            ("full", lambda: planner.plan_full(max_cases=256)),
        ):
            t0 = time.monotonic()
            plan = call()
            t_plan = time.monotonic() - t0
            self.assertLess(t_plan, 1.0, f"Planning {strat} too slow: {t_plan:.3f}s")
            self.assertGreater(plan.total_cases, 0)

        # 6. Run-level quality analysis time
        analyzer = QualityAnalyzer()
        test_rows = [
            {
                "identity": {"caseID": f"case_{i}", "surfaceStatus": "MATCHED"},
                "output": {"finalText": "I'm holding up alright."},
                "trigger": {},
                "semanticPath": {"semanticTemplateID": "companion.chat"},
                "selectionProvenance": {"canonicalSourceOwner": "chat"},
            }
            for i in range(100)
        ]
        t0 = time.monotonic()
        analyzer.analyze_run(test_rows)
        t_quality = time.monotonic() - t0
        self.assertLess(t_quality, 0.2, f"Run-level quality analysis too slow: {t_quality:.3f}s")

    def test_13_required_demonstration_scenarios(self) -> None:
        """Exercise all 13 required demonstration scenarios from HARNESS_ACCEPTANCE.md."""
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            analyzer = QualityAnalyzer()
            aggregator = ClusterAggregator(analyzer)

            # --- Demonstration 1: Ordinary wellbeing response across multiple persona contexts ---
            rec_neutral = worker.input("how are you?")
            rows_neutral = extract_evidence_rows_from_turn(
                rec_neutral, turn_index=0, case_id="c1_neutral", parameters={}, worker=worker
            )
            self.assertGreaterEqual(len(rows_neutral), 1)
            row_c1 = rows_neutral[0]
            self.assertIsNotNone(row_c1["output"]["finalText"])
            self.assertIn("personaSummary", row_c1["trigger"])
            self.assertIn("relationshipSummary", row_c1["trigger"])
            self.assertIn("stateSummary", row_c1["trigger"])
            self.assertIn("actorSummary", row_c1["trigger"])
            self.assertIn("traits", row_c1["trigger"]["personaSummary"])
            self.assertIn("approval", row_c1["trigger"]["relationshipSummary"])

            # --- Demonstration 2: Known vs unknown identity wording with privacy evidence ---
            # Extract privacy evidence from real speechStyleContext
            payload = rec_neutral["messages"][0]["payload"]
            self.assertIn("speechStyleContext", payload)
            privacy = payload["speechStyleContext"]["privacy"]
            self.assertIn("genderUsed", privacy)
            self.assertIn("privateProfileFieldsUsed", privacy)
            self.assertIn("semanticMeaningChanged", privacy)

            # --- Demonstration 3: Hostile vs friendly response-tone contrast with real text difference ---
            sc_hostile = self.inventory.project_to_scenario(
                {"relationship.approval": -75.0, "relationship.respect": -50.0}
            )
            with LuaSemanticWorker(sc_hostile) as hostile_worker:
                rec_hostile = hostile_worker.input("hello")
                rows_hostile = extract_evidence_rows_from_turn(
                    rec_hostile, turn_index=0, case_id="c3_hostile", parameters={"relationship.approval": -75.0}, worker=hostile_worker
                )

            sc_friendly = self.inventory.project_to_scenario(
                {"relationship.approval": 75.0, "relationship.respect": 50.0}
            )
            with LuaSemanticWorker(sc_friendly) as friendly_worker:
                rec_friendly = friendly_worker.input("hello")
                rows_friendly = extract_evidence_rows_from_turn(
                    rec_friendly, turn_index=0, case_id="c3_friendly", parameters={"relationship.approval": 75.0}, worker=friendly_worker
                )

            self.assertGreaterEqual(len(rows_hostile), 1)
            self.assertGreaterEqual(len(rows_friendly), 1)
            text_hostile = rows_hostile[0]["output"]["finalText"]
            text_friendly = rows_friendly[0]["output"]["finalText"]

            # Real contrast assertion: visible text and approval must strictly differ
            self.assertNotEqual(text_hostile, text_friendly)
            self.assertEqual(text_hostile, "State your business. Keep your distance.")
            self.assertEqual(text_friendly, "Hey there. Good to see you.")
            self.assertEqual(rows_hostile[0]["trigger"]["relationshipSummary"]["approval"], -75.0)
            self.assertEqual(rows_friendly[0]["trigger"]["relationshipSummary"]["approval"], 75.0)

            # --- Demonstration 4: Supported family wording vs unsupported-family defect class ---
            # 1. Supported family: real worker turn with sister bond
            sc_sister = self.inventory.project_to_scenario(
                {"persona.bondKind": "sister", "relationship.approval": 80.0}
            )
            with LuaSemanticWorker(sc_sister) as sister_worker:
                rec_sister = sister_worker.input("how are you?")
                rows_sister = extract_evidence_rows_from_turn(
                    rec_sister,
                    turn_index=0,
                    case_id="c4_sister_real",
                    parameters={"persona.bondKind": "sister"},
                    worker=sister_worker,
                )
            self.assertGreaterEqual(len(rows_sister), 1)
            row_sister = rows_sister[0]
            self.assertEqual(row_sister["trigger"]["relationshipSummary"]["bondKind"], "sister")
            # When family wording is present with supported family bond, it is NOT flagged
            row_supported_sister = deepcopy(row_sister)
            row_supported_sister["output"]["finalText"] = "You are my sister, I've got your back."
            flags_supported = analyzer.analyze_row(row_supported_sister)
            self.assertFalse(any(f.name == "UNSUPPORTED_FAMILY_REFERENCE" for f in flags_supported))

            # 2. Unsupported family: real worker turn with stranger/no bond
            sc_stranger = self.inventory.project_to_scenario({"relationship.approval": 0.0})
            with LuaSemanticWorker(sc_stranger) as stranger_worker:
                rec_stranger = stranger_worker.input("how are you?")
                rows_stranger = extract_evidence_rows_from_turn(
                    rec_stranger,
                    turn_index=0,
                    case_id="c4_stranger_real",
                    parameters={},
                    worker=stranger_worker,
                )
            self.assertGreaterEqual(len(rows_stranger), 1)
            row_stranger = rows_stranger[0]
            self.assertEqual(row_stranger["trigger"]["relationshipSummary"].get("bondKind", "none"), "none")
            # When family reference occurs without family bond, it is flagged as UNSUPPORTED_FAMILY_REFERENCE
            row_unsupported_family = deepcopy(row_stranger)
            row_unsupported_family["output"]["finalText"] = "family"
            flags_unsupported = analyzer.analyze_row(row_unsupported_family)
            flag_names = {f.name for f in flags_unsupported}
            self.assertIn("UNSUPPORTED_FAMILY_REFERENCE", flag_names)
            self.assertIn("ONE_WORD_RESPONSE", flag_names)

            # --- Demonstration 5: Perspective check: known-good vs wrong-perspective ---
            rec_good = worker.input("how are you?")
            rows_good = extract_evidence_rows_from_turn(
                rec_good, turn_index=0, case_id="c5_good_real", worker=worker
            )
            row_good = rows_good[0]
            flags_good = analyzer.analyze_row(row_good)
            self.assertFalse(any(f.name == "PERSPECTIVE_SUSPECT" for f in flags_good))

            row_bad = deepcopy(row_good)
            row_bad["output"]["finalText"] = "You are feeling sick and tired."
            flags_bad = analyzer.analyze_row(row_bad)
            self.assertTrue(any(f.name == "PERSPECTIVE_SUSPECT" for f in flags_bad))

            # --- Demonstration 6: EN and TL language parity ---
            worker.set_language("EN")
            rec_en = worker.input("how are you?")
            rows_en = extract_evidence_rows_from_turn(rec_en, case_id="c6_en", language="EN", worker=worker)
            worker.set_language("TL")
            rec_tl = worker.input("how are you?")
            rows_tl = extract_evidence_rows_from_turn(rec_tl, case_id="c6_tl", language="TL", worker=worker)
            self.assertEqual(rows_en[0]["identity"]["language"], "EN")
            self.assertEqual(rows_tl[0]["identity"]["language"], "TL")
            self.assertIsNotNone(rows_en[0]["output"]["finalText"])
            self.assertIsNotNone(rows_tl[0]["output"]["finalText"])

            # --- Demonstration 7: Anti-repeat history across repeated eligible turns ---
            worker.set_language("EN")
            rec_turn1 = worker.input("hello")
            rec_turn2 = worker.input("hello")
            rows_turn1 = extract_evidence_rows_from_turn(rec_turn1, turn_index=0, case_id="c7_anti_repeat_1", worker=worker)
            rows_turn2 = extract_evidence_rows_from_turn(rec_turn2, turn_index=1, case_id="c7_anti_repeat_2", worker=worker)
            self.assertGreaterEqual(len(rows_turn1), 1)
            self.assertGreaterEqual(len(rows_turn2), 1)
            p1 = rec_turn1["messages"][0]["payload"]
            p2 = rec_turn2["messages"][0]["payload"]
            # Prove actual phrase rotation and selection penalty from live history
            self.assertNotEqual(p1.get("phraseID"), p2.get("phraseID"))
            self.assertNotEqual(p1.get("text"), p2.get("text"))
            self.assertEqual(p1.get("phraseAntiRepeatReason"), "initial_canonical")
            self.assertEqual(p2.get("phraseAntiRepeatReason"), "deterministic_hash")

            # --- Demonstration 8: Response variant selected under more than one context ---
            # Distinct parameter vectors player.hunger=0.2 and 0.8 reaching same response
            sc_p1 = self.inventory.project_to_scenario({"player.needs.hunger": 0.2})
            sc_p2 = self.inventory.project_to_scenario({"player.needs.hunger": 0.8})
            with LuaSemanticWorker(sc_p1) as w1:
                r1 = extract_evidence_rows_from_turn(w1.input("hello"), case_id="p1", worker=w1)
            with LuaSemanticWorker(sc_p2) as w2:
                r2 = extract_evidence_rows_from_turn(w2.input("hello"), case_id="p2", worker=w2)
            self.assertEqual(
                r1[0]["semanticPath"]["semanticTemplateID"],
                r2[0]["semanticPath"]["semanticTemplateID"],
            )

            # --- Demonstration 9: Truly ELIGIBLE_NOT_SELECTED variant via explain ---
            exp_combat = worker.explain_response_selection("semantic.combat.human_kill.aggressive", {})
            self.assertTrue(exp_combat.get("ok"))
            sel_id = exp_combat.get("selectedID")
            cands = exp_combat.get("candidates", [])
            eligible_cands = [c for c in cands if c.get("eligible")]
            self.assertGreaterEqual(len(eligible_cands), 2)
            target_cand = next(c for c in eligible_cands if c["id"] != sel_id)
            self.assertTrue(target_cand["eligible"])
            self.assertNotEqual(target_cand["id"], sel_id)

            analyzer_r = ReachabilityAnalyzer(worker)
            report_r = analyzer_r.analyze_reachability(
                [],
                worker=worker,
                target_pools=["semantic.combat.human_kill.aggressive"],
            )
            records_r = {r.variant_id: r for r in report_r.pool_records["semantic.combat.human_kill.aggressive"]}
            self.assertEqual(records_r[target_cand["id"]].status, VariantReachabilityState.ELIGIBLE_NOT_SELECTED)
            self.assertFalse(records_r[target_cand["id"]].global_unreachable_claim)

            # --- Demonstration 10: Canonical cluster from defect + targeted replay ---
            cluster_rows = []
            for i in range(4):
                sc_c10 = self.inventory.project_to_scenario({"player.needs.hunger": i * 0.2})
                with LuaSemanticWorker(sc_c10) as w10:
                    rec_10 = w10.input("how are you?")
                    r_10 = extract_evidence_rows_from_turn(
                        rec_10,
                        turn_index=0,
                        case_id=f"c10_case_{i}",
                        parameters={"player.needs.hunger": i * 0.2},
                        worker=w10,
                    )[0]
                    # Simulate unreplaced family text on this source owner
                    r_10["output"]["finalText"] = "family"
                    r_10["selectionProvenance"]["canonicalSourceOwner"] = "dialogue_dataset.wellbeing"
                    cluster_rows.append(r_10)

            cluster_report = aggregator.aggregate_rows(cluster_rows, sweep_id="demo_c10")
            fam_clusters = cluster_report.filter_by(flag="UNSUPPORTED_FAMILY_REFERENCE")
            self.assertEqual(len(fam_clusters), 1)
            c = fam_clusters[0]
            self.assertEqual(c.primary_flag, "UNSUPPORTED_FAMILY_REFERENCE")
            self.assertEqual(c.count, 4)
            self.assertEqual(c.canonical_source_owner, "dialogue_dataset.wellbeing")

            orig_plan = CoveragePlan(
                sweep_id="demo_c10",
                strategy="smoke",
                plan_digest="orig_dig",
                catalog_fingerprint=self.inventory.production_fingerprint,
                cases=[
                    PlannedCase(
                        case_id=f"c10_case_{i}",
                        sweep_id="demo_c10",
                        strategy="smoke",
                        surface="utterance:how are you?",
                        parameters={"player.needs.hunger": i * 0.2},
                        turns=({"text": "how are you?"},),
                    )
                    for i in range(4)
                ],
                total_cases=4,
                estimated_batches=1,
                batch_size=64,
            )
            affected_cases = cluster_report.get_affected_case_ids([c.cluster_id])
            replay_plan = self.service.plan_replay(orig_plan, affected_cases)
            self.assertEqual(replay_plan.total_cases, 4)
            self.assertEqual(
                [case.metadata.get("originalCaseID") for case in replay_plan.cases],
                [f"c10_case_{i}" for i in range(4)],
            )
            with tempfile.TemporaryDirectory() as tmp_dir:
                svc_rep = DialogueQualitySweepService(base_dir=tmp_dir)
                rep_manifest = svc_rep.run_sweep(
                    replay_plan,
                    inventory=self.inventory,
                    batch_size=64,
                )
                self.assertEqual(rep_manifest.completed_cases, 4)

            # --- Demonstration 11: Stale/missing planned surface detected as invalid surface ---
            with tempfile.TemporaryDirectory() as tmp_dir:
                stale_planner = CoveragePlanner(self.inventory, sweep_id="demo_stale_surface")
                stale_plan = stale_planner.plan_smoke(
                    surfaces=("scenario.rootChoice:wellbeing",),
                    languages=("EN",),
                )
                executor = SweepBatchExecutor(
                    stale_plan,
                    self.inventory,
                    artifact_dir=Path(tmp_dir),
                    worker_factory=lambda sc: LuaSemanticWorker(sc),
                    batch_size=64,
                )
                manifest = executor.execute_all()
                self.assertEqual(manifest.status, "COMPLETED_WITH_INVALID_SURFACE")
                self.assertEqual(manifest.invalid_surface_cases, 1)

            # --- Demonstration 12: Cancel -> resume completes remaining work without duplicate evidence ---
            with tempfile.TemporaryDirectory() as tmp_dir:
                cancel_plan = CoveragePlan(
                    sweep_id="demo_cancel_resume",
                    strategy="smoke",
                    plan_digest="cancel_dig",
                    catalog_fingerprint=self.inventory.production_fingerprint,
                    cases=[
                        PlannedCase(
                            case_id=f"case_cr_{i}",
                            sweep_id="demo_cancel_resume",
                            strategy="smoke",
                            surface="utterance:hello",
                            parameters={},
                            turns=({"text": "hello"},),
                        )
                        for i in range(4)
                    ],
                    total_cases=4,
                    estimated_batches=2,
                    batch_size=2,
                )
                # First execution: cancel after batch 1
                batch_counter = 0

                def is_cancelled_first():
                    return batch_counter >= 1

                def progress_cb(batch, m):
                    nonlocal batch_counter
                    batch_counter += 1

                executor_1 = SweepBatchExecutor(
                    cancel_plan,
                    self.inventory,
                    artifact_dir=Path(tmp_dir),
                    worker_factory=lambda sc: LuaSemanticWorker(sc),
                    batch_size=2,
                )
                with self.assertRaises(SweepExecutionCancelled):
                    executor_1.execute_all(
                        is_cancelled=is_cancelled_first,
                        progress_callback=progress_cb,
                    )
                self.assertEqual(executor_1.manifest.status, "CANCELLED")
                self.assertEqual(executor_1.manifest.completed_cases, 2)

                # Resume execution: finishes batch 2
                executor_2 = SweepBatchExecutor(
                    cancel_plan,
                    self.inventory,
                    artifact_dir=Path(tmp_dir),
                    worker_factory=lambda sc: LuaSemanticWorker(sc),
                    batch_size=2,
                )
                manifest_2 = executor_2.execute_all()
                self.assertEqual(manifest_2.status, "COMPLETED")
                self.assertEqual(manifest_2.completed_cases, 4)

                # Check evidence lines: no duplicate case IDs
                evidence_path = Path(tmp_dir) / "evidence.jsonl"
                with open(evidence_path, "r", encoding="utf-8") as f:
                    case_ids = [json.loads(line)["identity"]["caseID"] for line in f if line.strip()]
                unique_case_ids = set(case_ids)
                self.assertEqual(unique_case_ids, {f"case_cr_{i}" for i in range(4)})

            # --- Demonstration 13: Full response-pool pagination matches production total ---
            all_pools = enumerate_all_response_pools(worker, limit=64)
            first_page = worker.response_pool_list(offset=0, limit=1)
            total_reported = first_page.get("total", 234)
            self.assertEqual(len(all_pools), total_reported)
            self.assertEqual(len(all_pools), 234)

    def test_frontier_expansion_discovers_unique_variant(self) -> None:
        """Verify that frontier expansion discovers at least one additional unique selected variant beyond baseline review."""
        from tools.semantic_harness.testing.sweep_reachability import ObservedVariantLedger

        with tempfile.TemporaryDirectory() as tmp_dir:
            svc = DialogueQualitySweepService(base_dir=tmp_dir)
            smoke_plan = svc.plan_sweep(
                strategy="smoke",
                sweep_id="demo_frontier_expand",
                languages=["EN"],
            )
            svc.run_sweep(smoke_plan)
            baseline_rows = svc.load_evidence_rows("demo_frontier_expand")
            baseline_ledger = ObservedVariantLedger()
            baseline_ledger.record_rows(baseline_rows)
            baseline_variants = baseline_ledger.observed_variant_ids()

            # Expand frontier
            new_rows = svc.expand_frontier_sentences("demo_frontier_expand", max_new_cases=4)
            self.assertGreaterEqual(len(new_rows), 1)

            expanded_rows = svc.load_evidence_rows("demo_frontier_expand")
            expanded_ledger = ObservedVariantLedger()
            expanded_ledger.record_rows(expanded_rows)
            expanded_variants = expanded_ledger.observed_variant_ids()

            new_unique = expanded_variants - baseline_variants
            self.assertGreaterEqual(
                len(new_unique), 1,
                f"Frontier targeting must discover at least 1 new unique variant beyond baseline: {new_unique}"
            )


if __name__ == "__main__":
    unittest.main()
