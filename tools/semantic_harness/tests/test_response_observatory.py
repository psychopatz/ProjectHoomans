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
            self.assertIn("planSummary", first["variants"][0])
            self.assertGreater(first["registryRevision"], 0)
            self.assertTrue(first["contentFingerprint"].startswith("catalog-v1:"))
            self.assertIn("when", first["variants"][0])
            self.assertEqual(first["sourcePath"], "UNKNOWN")
            again = worker.response_pool_detail(entry["id"], limit=1)
            self.assertEqual(first["poolID"], again["poolID"])
            self.assertEqual(first["variantCount"], again["variantCount"])
            self.assertEqual(first["sourcePath"], again["sourcePath"])
            self.assertEqual(first["variants"], again["variants"])
            self.assertEqual(first["contentFingerprint"], again["contentFingerprint"])
            with self.assertRaisesRegex(HarnessError, "response_pool_unavailable"):
                worker.response_pool_detail("missing.pool")
            with self.assertRaisesRegex(HarnessError, "invalid_page"):
                worker.response_pool_detail(entry["id"], limit=17)


    def test_pool_list_paging_and_invalid_limit(self):
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            a = worker.response_pool_list(filter="greeting", limit=2)
            b = worker.response_pool_list(filter="greeting", offset=2, limit=2)
            self.assertTrue(a["ok"])
            self.assertGreater(a["total"], 2)
            self.assertEqual(len(a["pools"]), 2)
            self.assertTrue(a["hasMore"])
            self.assertFalse({v["id"] for v in a["pools"]} &
                             {v["id"] for v in b["pools"]})
            with self.assertRaisesRegex(HarnessError, "invalid_page"):
                worker.response_pool_list(limit=1000)

    def test_explain_parity_and_read_only_repeat_history(self):
        pool = "semantic.question.wellbeing"
        context = {"npcID": "observatory-parity-test", "healthState": "healthy"}
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            first = worker.explain_response_selection(pool, context, "seed")
            again = worker.explain_response_selection(pool, context, "seed")
            self.assertEqual(first["selectedID"], again["selectedID"])
            self.assertEqual(first["selectedIndex"], again["selectedIndex"])
            self.assertGreater(first["tieCount"], 1)
            self.assertTrue(any(row["eligible"] for row in first["candidates"]))
            self.assertTrue(any(not row["eligible"] for row in first["candidates"]))
            normal = worker.sample_response_selection(pool, context, "seed")
            self.assertTrue(normal["mutatedFixtureHistory"])
            self.assertEqual(first["selectedID"], normal["selectedID"])
            next_explain = worker.explain_response_selection(pool, context, "seed")
            self.assertTrue(next_explain["rotated"])
            self.assertNotEqual(next_explain["selectedID"], first["selectedID"])
            self.assertEqual(next_explain["selectedID"],
                             worker.sample_response_selection(pool, context, "seed")["selectedID"])

    def test_weather_and_unknown_npc_facts_are_not_invented(self):
        pool = "semantic.flow.greeting.opening"
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            rain = worker.explain_response_selection(pool, {
                "npcID": "obs-rain", "worldContext": {
                    "weather": {"raining": True}}}, "x")
            self.assertEqual(rain["selectedID"],
                             "semantic.flow.greeting.opening.rain")
            absent = worker.explain_response_selection(pool, {
                "npcID": "obs-unknown"}, "x")
            self.assertEqual(absent["selectedID"],
                             "semantic.flow.greeting.opening.default")
            blocked = next(row for row in absent["candidates"]
                           if row["id"] == "semantic.flow.greeting.opening.rain")
            self.assertFalse(blocked["eligible"])
            self.assertFalse(blocked["checks"][0]["actualKnown"])

    def test_explain_does_not_mutate_actor_fixture(self):
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            before = worker.inspect_actor_state()
            for _ in range(4):
                worker.explain_response_selection(
                    "semantic.generated.simple_command.follow.queued",
                    {"npcID": "isolation", "socialStyle": "friendly"}, "same",
                )
            after = worker.inspect_actor_state()
            for key in ("id", "protocolVersion"):
                before.pop(key, None)
                after.pop(key, None)
            self.assertEqual(before, after)


if __name__ == "__main__":
    unittest.main()
