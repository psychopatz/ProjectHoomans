"""The production worker loads the same provider seam used by gameplay."""
import unittest
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO


class UnifiedEvidenceE1Tests(unittest.TestCase):
    def test_tier_schema_in_production_worker(self):
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            result = worker._request("TEST_EVIDENCE_PROVIDERS")
            rows = result["evidence"]["rows"]
            self.assertEqual([row["sourceTier"] for row in rows],
                             ["SESSION", "TODAY", "DURABLE"])
            for row in rows:
                self.assertNotIn("rawText", row)
                self.assertEqual(row["retentionSalience"], 220)
                self.assertEqual(row["confidence"], .8)
                self.assertEqual(row["effectiveStrength"], .5)
                self.assertEqual(row["ageHours"], 1)
            self.assertEqual(worker.input("hello")["observation"]["ir"]["intent"], "GREET")
