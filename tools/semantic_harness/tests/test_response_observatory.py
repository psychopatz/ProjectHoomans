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
            self.assertEqual(first["sourcePath"], first["variants"][0]["sourcePath"])
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


    def test_production_registration_origin_differs_from_generated_owner(self):
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            authored = worker.response_pool_detail(
                "semantic.flow.greeting.opening", limit=16)
            self.assertEqual(authored["sourceKind"], "AUTHORED_LUA")
            self.assertIn("_FlowGreeting.lua", authored["sourcePath"])
            self.assertTrue(all(v["sourcePath"] == authored["sourcePath"]
                                for v in authored["variants"]))
            generated = worker.response_pool_detail(
                "semantic.command.follow.queued", limit=16)
            self.assertEqual(generated["sourceKind"],
                             "GENERATED_REGISTRATION_SITE")
            self.assertIn("AutomaticFlowGenerator_Registration.lua",
                          generated["sourcePath"])
            self.assertNotEqual(generated["sourceKind"], "AUTHORED_LUA")
            lineage = generated["generatedActionLineage"]
            self.assertEqual(lineage["capabilityID"], "pnc:companion.follow")
            self.assertEqual(lineage["commandActionID"], "FOLLOW")
            self.assertTrue(lineage["canonicalOwnerVerified"])
            self.assertTrue(lineage["verifiedCanonicalActionPath"].endswith(
                "PNC_SemanticCommandAdapter_CompanionActions.lua"
            ))
            self.assertNotEqual(
                lineage["verifiedCanonicalActionPath"], generated["sourcePath"]
            )

    def test_observed_lookup_does_not_invent_generated_selection(self):
        from tools.semantic_harness.inspection.response_turn_trace import (
            inspect_response_turn,
        )
        from tools.semantic_harness.runtime.scenario import merge
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            opening = inspect_response_turn(worker, worker.input("hello"))
            first = opening["npcMessages"][0]
            self.assertEqual(first["selectedVariantID"],
                             "semantic.flow.greeting.opening.default")
            self.assertEqual(first["selectionProvenance"],
                             "EXACT_EMITTED_VARIANT_ID")
            self.assertEqual(first["registeredVariants"][0]["sourceKind"],
                             "AUTHORED_LUA")
            self.assertEqual(opening["effects"]["actionCount"], 0)
            follow = inspect_response_turn(worker, worker.input("follow me"))
            reply = follow["npcMessages"][-1]
            self.assertIsNone(reply["selectedVariantID"])
            self.assertEqual(reply["selectionProvenance"],
                             "TEMPLATE_CANDIDATES_ONLY")
            self.assertEqual(reply["registeredVariants"][0]["sourceKind"],
                             "GENERATED_REGISTRATION_SITE")
            self.assertEqual(follow["effects"]["transportCount"], 1)
            self.assertEqual(follow["effects"]["actionCount"], 1)
            with self.assertRaisesRegex(HarnessError, "invalid_response_key"):
                worker.response_key_lookup("")

    def test_production_lua_coverage_distinguishes_dominance_from_unreachable(self):
        import json
        from pathlib import Path
        from tools.semantic_harness.inspection.response_selection_coverage import (
            selection_coverage,
        )
        root = Path(__file__).resolve().parents[3]
        fixture = json.loads(
            (root / "tools/semantic_harness/fixtures"
             / "observatory_greeting_selection.json").read_text()
        )
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            before = worker.explain_response_selection(
                "semantic.flow.greeting.opening",
                {"npcID": "history-proof", "socialStyle": "friendly"}, "constant")
            state = worker.inspect_actor_state()
            report = selection_coverage(worker, fixture)
            after = worker.explain_response_selection(
                "semantic.flow.greeting.opening",
                {"npcID": "history-proof", "socialStyle": "friendly"}, "constant")
            actor = worker.inspect_actor_state()
        self.assertEqual(before["selectedID"], after["selectedID"])
        for key in ("id", "protocolVersion"):
            state.pop(key, None)
            actor.pop(key, None)
        self.assertEqual(state, actor)
        self.assertTrue(report["noRuntimeSelectionOrGameplayMutation"])
        self.assertTrue(report["neverClaimsGloballyUnreachable"])
        self.assertEqual(report["caseCount"], 4)
        counts = {
            row["variantID"].split(".")[-1]:
                (row["eligibleCases"], row["selectedCases"])
            for row in report["variants"]
        }
        self.assertEqual(counts, {
            "default": (4, 1),
            "friendly": (2, 1),
            "rain": (2, 2),
        })
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            only_rain = selection_coverage(worker, {
                "poolID": "semantic.flow.greeting.opening",
                "cases": [{"context": {
                    "npcID": "rain-dominates",
                    "worldContext": {"weather": {"raining": True}},
                    "socialStyle": "friendly",
                }}],
            })
        lower = {v["variantID"].split(".")[-1]: v for v in only_rain["variants"]}
        self.assertEqual(lower["friendly"]["testedStatus"],
                         "ELIGIBLE_BUT_NOT_SELECTED_IN_TESTED_CONTEXTS")
        self.assertEqual(lower["friendly"]["lowerRankedCases"], 1)
        self.assertNotIn("unreachable", str(lower).lower())

    def test_selection_coverage_rejects_invalid_or_excess_contexts(self):
        from tools.semantic_harness.inspection.response_selection_coverage import (
            selection_coverage,
        )
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            with self.assertRaisesRegex(ValueError, "1 to 16"):
                selection_coverage(worker, {
                    "poolID": "semantic.flow.greeting.opening",
                    "cases": [{"context": {}}] * 17,
                })
            with self.assertRaisesRegex(ValueError, "explicit Lua context"):
                selection_coverage(worker, {
                    "poolID": "semantic.flow.greeting.opening",
                    "cases": [{"context": "not a Lua table"}],
                })

    def test_lookup_does_not_mutate_real_worker_actor_state(self):
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            before = worker.inspect_actor_state()
            for _ in range(3):
                worker.response_key_lookup(
                    "semantic.flow.greeting.opening.default")
            after = worker.inspect_actor_state()
            for key in ("id", "protocolVersion"):
                before.pop(key, None)
                after.pop(key, None)
            self.assertEqual(before, after)

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
                    "semantic.command.follow.queued",
                    {"npcID": "isolation", "socialStyle": "friendly"}, "same",
                )
            after = worker.inspect_actor_state()
            for key in ("id", "protocolVersion"):
                before.pop(key, None)
                after.pop(key, None)
            self.assertEqual(before, after)


if __name__ == "__main__":
    unittest.main()
