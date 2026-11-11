"""tests for selection provenance and variant reachability frontier."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO
from tools.providers.pnc.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.testing.sweep_reachability import (
    REACHABILITY_SCHEMA_V1,
    ObservedVariantLedger,
    ReachabilityAnalyzer,
    ReachabilityReport,
    VariantReachabilityRecord,
    VariantReachabilityState,
    find_frontier_targets,
    synthesize_condition_contexts,
)


class SweepReachabilityTests(unittest.TestCase):
    def test_reachability_states_and_never_overclaiming_unreachable(self) -> None:
        rec = VariantReachabilityRecord(
            pool_id="pool_1",
            variant_id="var_1",
            status=VariantReachabilityState.TESTED_INELIGIBLE,
            rejection_reasons=["condition_mismatch"],
        )
        self.assertEqual(rec.status, "TESTED_INELIGIBLE")
        self.assertFalse(rec.global_unreachable_claim)

        d = rec.to_dict()
        self.assertEqual(d["globalUnreachableClaim"], False)

    def test_synthetic_reachability_report(self) -> None:
        records = {
            "test_pool": [
                VariantReachabilityRecord("test_pool", "v1", VariantReachabilityState.SELECTED, 1, 1, 1, ["c1"]),
                VariantReachabilityRecord("test_pool", "v2", VariantReachabilityState.ELIGIBLE_NOT_SELECTED, 1, 1, 0, rejection_reasons=["lower_score"]),
                VariantReachabilityRecord("test_pool", "v3", VariantReachabilityState.TESTED_INELIGIBLE, 1, 0, 0, failed_checks=["hasPendingRequest"]),
                VariantReachabilityRecord("test_pool", "v4", VariantReachabilityState.UNTESTED),
                VariantReachabilityRecord("test_pool", "v5", VariantReachabilityState.SELECTED_UNDER_SUSPICIOUS_CONTEXT, 1, 1, 1, ["c2"]),
            ]
        }
        status_counts = {
            VariantReachabilityState.SELECTED: 1,
            VariantReachabilityState.ELIGIBLE_NOT_SELECTED: 1,
            VariantReachabilityState.TESTED_INELIGIBLE: 1,
            VariantReachabilityState.UNTESTED: 1,
            VariantReachabilityState.SELECTED_UNDER_SUSPICIOUS_CONTEXT: 1,
        }
        report = ReachabilityReport(
            sweep_id="test_sweep",
            total_pools=1,
            total_variants=5,
            status_counts=status_counts,
            pool_records=records,
        )
        d = report.to_dict()
        self.assertEqual(d["schema"], REACHABILITY_SCHEMA_V1)
        self.assertEqual(d["totalVariants"], 5)
        self.assertIn("Finite non-selection in tested matrices does not prove global unreachability", d["globalUnreachableWarning"])

    def test_real_lua_reachability_analysis(self) -> None:
        """Integration with real LuaSemanticWorker verifying production selector explain."""
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            analyzer = ReachabilityAnalyzer(worker)

            # Mock evidence row where semantic.accept.default was selected
            mock_evidence_rows = [
                {
                    "identity": {"caseID": "case-accept-01"},
                    "selectionProvenance": {
                        "selectedVariantID": "semantic.accept.default",
                        "provenance": "EXACT_EMITTED_VARIANT_ID",
                    },
                    "semanticPath": {
                        "semanticTemplateID": "semantic.accept",
                        "semanticVariantID": "semantic.accept.default",
                    },
                    "output": {"finalText": "Sure."},
                    "quality": {"flags": []},
                }
            ]

            report = analyzer.analyze_reachability(
                mock_evidence_rows,
                worker=worker,
                target_pools=["semantic.accept"],
            )

            self.assertEqual(report.total_pools, 1)
            records = report.pool_records["semantic.accept"]
            rec_map = {r.variant_id: r for r in records}

            self.assertIn("semantic.accept.default", rec_map)
            self.assertEqual(rec_map["semantic.accept.default"].status, VariantReachabilityState.SELECTED)

            self.assertIn("semantic.accept.request", rec_map)
            self.assertEqual(rec_map["semantic.accept.request"].status, VariantReachabilityState.TESTED_INELIGIBLE)
            self.assertIn("hasPendingRequest", rec_map["semantic.accept.request"].failed_checks)

            # Mandatory rule: global_unreachable_claim must be False
            self.assertFalse(rec_map["semantic.accept.request"].global_unreachable_claim)

    def test_full_response_pool_pagination(self) -> None:
        """Verify that ReachabilityAnalyzer paginates the entire production pool registry."""
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            analyzer = ReachabilityAnalyzer(worker)
            pools, prod_total, is_complete = analyzer.enumerate_all_response_pools(worker)
            self.assertGreaterEqual(prod_total, 200)
            self.assertEqual(len(pools), prod_total)
            self.assertTrue(is_complete)

            # Analyze a sample slice and verify report metadata
            report = analyzer.analyze_reachability(
                [],
                worker=worker,
                target_pools=[p["id"] for p in pools[:5]],
            )
            self.assertEqual(report.total_pools, 5)
            self.assertGreater(report.total_variants, 0)


    def test_observed_variant_ledger(self) -> None:
        """Verify that ObservedVariantLedger aggregates execution truth correctly."""
        ledger = ObservedVariantLedger()
        row1 = {
            "identity": {"caseID": "c1", "language": "EN", "plannedSurface": "utterance:hello"},
            "selectionProvenance": {"selectedVariantID": "variant.hello.01", "selectedPoolID": "pool.hello"},
            "trigger": {"parameters": {"player.needs.hunger": 0.2}},
            "output": {"finalText": "Hello there."},
        }
        row2 = {
            "identity": {"caseID": "c2", "language": "TL", "plannedSurface": "utterance:hello"},
            "selectionProvenance": {"selectedVariantID": "variant.hello.01", "selectedPoolID": "pool.hello"},
            "trigger": {"parameters": {"player.needs.hunger": 0.8}},
            "output": {"finalText": "Kamusta ka."},
        }
        row3 = {
            "identity": {"caseID": "c3", "language": "EN", "plannedSurface": "utterance:bye"},
            "selectionProvenance": {"selectedVariantID": "variant.bye.01", "selectedPoolID": "pool.bye"},
            "trigger": {"parameters": {}},
            "output": {"finalText": "Goodbye."},
        }

        self.assertEqual(ledger.record_row(row1), "variant.hello.01")
        self.assertEqual(ledger.record_rows([row2, row3]), 2)
        self.assertEqual(ledger.total_observed_variants(), 2)
        self.assertTrue(ledger.is_observed("variant.hello.01"))
        self.assertTrue(ledger.is_observed("variant.bye.01"))
        self.assertFalse(ledger.is_observed("variant.unseen.01"))

        entry = ledger.get_entry("variant.hello.01")
        self.assertIsNotNone(entry)
        self.assertEqual(entry.count, 2)
        self.assertEqual(entry.languages, {"EN", "TL"})
        self.assertEqual(entry.surfaces, {"utterance:hello"})
        self.assertEqual(len(entry.rendered_sentences), 2)
        self.assertEqual(len(entry.context_vectors), 2)

        d = ledger.to_dict()
        self.assertEqual(d["totalObservedVariants"], 2)
        self.assertIn("variant.hello.01", d["entries"])

    def test_condition_guided_frontier_search_reaches_unobserved_variants(self) -> None:
        """Verify that condition-guided search uses failed checks to reach unobserved variants."""
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            analyzer = ReachabilityAnalyzer(worker)

            # Analyze pool semantic.flow.farewell where initially no rows exist
            report = analyzer.analyze_reachability(
                [],
                worker=worker,
                target_pools=["semantic.flow.farewell"],
            )
            rec_map = {r.variant_id: r for r in report.pool_records["semantic.flow.farewell"]}

            # Both variants should be reached/classified through frontier evaluation
            self.assertIn("semantic.flow.farewell.default", rec_map)
            self.assertIn("semantic.flow.farewell.friendly", rec_map)

            # semantic.flow.farewell.friendly requires socialStyle='friendly', which condition synthesis solves!
            friendly_rec = rec_map["semantic.flow.farewell.friendly"]
            self.assertEqual(friendly_rec.status, VariantReachabilityState.SELECTED)
            self.assertFalse(friendly_rec.global_unreachable_claim)

            # Report includes ledger metadata
            self.assertIn("ledger", report.to_dict())

    def test_genuine_eligible_not_selected_variant(self) -> None:
        """Verify a genuine ELIGIBLE_NOT_SELECTED variant where candidate is eligible but another variant wins."""
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            # Under empty context, semantic.combat.human_kill.aggressive has 3 eligible variants, but line_02 wins tiebreak
            exp = worker.explain_response_selection("semantic.combat.human_kill.aggressive", {})
            self.assertTrue(exp.get("ok"))
            sel_id = exp.get("selectedID")
            candidates = exp.get("candidates", [])

            eligible_not_selected = [
                c for c in candidates
                if c.get("eligible") and c.get("id") != sel_id
            ]
            self.assertGreaterEqual(len(eligible_not_selected), 1)

            target = eligible_not_selected[0]
            self.assertTrue(target["eligible"])
            self.assertNotEqual(target["id"], sel_id)

            # Analyzer reflects ELIGIBLE_NOT_SELECTED on target variant
            analyzer = ReachabilityAnalyzer(worker)
            report = analyzer.analyze_reachability(
                [],
                worker=worker,
                target_pools=["semantic.combat.human_kill.aggressive"],
            )
            rec_map = {r.variant_id: r for r in report.pool_records["semantic.combat.human_kill.aggressive"]}
            self.assertEqual(rec_map[target["id"]].status, VariantReachabilityState.ELIGIBLE_NOT_SELECTED)
            self.assertFalse(rec_map[target["id"]].global_unreachable_claim)

    def test_find_frontier_targets(self) -> None:
        """Verify find_frontier_targets discovers unobserved variants with reachable contexts."""
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            ledger = ObservedVariantLedger()
            # Only record default
            ledger.entries["semantic.flow.farewell.default"] = True

            targets = find_frontier_targets(
                worker,
                ledger,
                pool_ids=["semantic.flow.farewell"],
                limit=5,
            )
            self.assertGreaterEqual(len(targets), 1)
            target = targets[0]
            self.assertEqual(target["poolID"], "semantic.flow.farewell")
            self.assertEqual(target["variantID"], "semantic.flow.farewell.friendly")
            self.assertIn("socialStyle", target["context"])


if __name__ == "__main__":
    unittest.main()
