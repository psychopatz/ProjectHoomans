"""Real production Lua registry inspection (no synthetic catalog)."""
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.runtime.process import HarnessError


class ResponseObservatoryTests(unittest.TestCase):
    def test_loaded_registry_detail_is_bounded_and_read_only(self):
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            listing = worker.flow_catalog()["responsePoolCatalog"]
            self.assertTrue(listing)
            entry = next(row for row in listing if row["variantCount"] > 0)
            first = worker.response_pool_detail(entry["id"], limit=1)
            self.assertTrue(first["ok"], first)
            self.assertEqual(first["poolID"], entry["id"])
            self.assertEqual(first["variantCount"], entry["variantCount"])
            self.assertEqual(len(first["variants"]), 1)
            self.assertIn("templateID", first["variants"][0])
            self.assertIn("when", first["variants"][0])
            self.assertEqual(first["sourcePath"], "UNKNOWN")
            again = worker.response_pool_detail(entry["id"], limit=1)
            self.assertEqual(first["poolID"], again["poolID"])
            self.assertEqual(first["variantCount"], again["variantCount"])
            self.assertEqual(first["sourcePath"], again["sourcePath"])
            with self.assertRaisesRegex(HarnessError, "response_pool_unavailable"):
                worker.response_pool_detail("missing.pool")
            with self.assertRaisesRegex(HarnessError, "invalid_page"):
                worker.response_pool_detail(entry["id"], limit=17)


if __name__ == "__main__":
    unittest.main()
