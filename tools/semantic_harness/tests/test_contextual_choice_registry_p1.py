"""P1 choice-registry contract tests through the production Lua worker."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class ContextualChoiceRegistryP1Tests(unittest.TestCase):
    def test_all_current_sources_normalize_to_the_versioned_candidate_contract(
        self,
    ) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            result = worker.input("hello")

        suggestions = result["observation"]["suggestions"]
        providers = suggestions["choiceRegistry"]["providers"]
        provider_ids = {provider["id"] for provider in providers}
        self.assertIn("projecthoomans.active_flow", provider_ids)
        self.assertIn("projecthoomans.response_plan", provider_ids)
        self.assertIn("projecthoomans.static_questions", provider_ids)
        self.assertIn("projecthoomans.capabilities", provider_ids)

        rows = suggestions["candidates"] + suggestions["permittedCapabilities"]
        self.assertTrue(rows)
        for row in rows:
            self.assertEqual(row["candidateSchema"], "semantic.choice.v1")
            self.assertTrue(row["providerID"] in provider_ids)
            self.assertEqual(
                row["source"]["providerID"],
                row["providerID"],
            )

    def test_registry_provider_order_and_candidate_order_are_repeatable(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            first = worker.input("hello")
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            second = worker.input("hello")

        first_suggestions = first["observation"]["suggestions"]
        second_suggestions = second["observation"]["suggestions"]
        first_order = [
            (provider["order"], provider["id"])
            for provider in first_suggestions["choiceRegistry"]["providers"]
        ]
        second_order = [
            (provider["order"], provider["id"])
            for provider in second_suggestions["choiceRegistry"]["providers"]
        ]
        self.assertEqual(first_order, second_order)
        self.assertEqual(
            [row["id"] for row in first_suggestions["candidates"]],
            [row["id"] for row in second_suggestions["candidates"]],
        )
        self.assertLessEqual(len(first_suggestions["candidates"]), 24)
        self.assertLessEqual(len(first_suggestions["permittedCapabilities"]), 24)

    def test_provider_contract_does_not_create_a_second_click_or_effect_lane(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            result = worker.input("hello")
            row = next(
                candidate
                for candidate in result["observation"]["suggestions"]["candidates"]
                if candidate["id"] == "greeting.thanks"
            )
            clicked = worker.suggestion_click(row["frame"])

        self.assertTrue(clicked["accepted"])
        self.assertEqual(clicked["result"]["ir"]["provenance"]["parser"], "semantic_click_frame")
        self.assertEqual(clicked["toolCalls"], [])
        self.assertEqual(clicked["dispatchTransport"], [])


if __name__ == "__main__":
    unittest.main()
