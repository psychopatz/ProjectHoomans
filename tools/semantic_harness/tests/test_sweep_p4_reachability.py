"""P4 tests for selection provenance and variant reachability frontier."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.testing.sweep_reachability import (
    REACHABILITY_SCHEMA_V1,
    ReachabilityAnalyzer,
    ReachabilityReport,
    VariantReachabilityRecord,
    VariantReachabilityState,
)


class SweepP4ReachabilityTests(unittest.TestCase):
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


if __name__ == "__main__":
    unittest.main()
