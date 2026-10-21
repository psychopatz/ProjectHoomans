"""S2 constraint and privacy checks through the production Lua worker."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.worker import LuaSemanticWorker


class ContextualSuggestionsS2Tests(unittest.TestCase):
    def test_typed_all_any_not_predicates_and_fail_closed_results(self) -> None:
        private_scenario = deepcopy(DEFAULT_SCENARIO)
        private_scenario["npc"]["semanticAuthorization"] = {"private": True}
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            allowed = worker.suggestion_predicate(
                {
                    "all": [
                        {
                            "path": "npcState.activeBehavior",
                            "op": "eq",
                            "value": "idle",
                        },
                        {
                            "not": {
                                "path": "npcState.healthState",
                                "op": "eq",
                                "value": "dead",
                            }
                        },
                    ]
                }
            )
            any_allowed = worker.suggestion_predicate(
                {
                    "any": [
                        {
                            "path": "npcState.activeBehavior",
                            "op": "eq",
                            "value": "busy",
                        },
                        {
                            "path": "npcState.activeBehavior",
                            "op": "eq",
                            "value": "idle",
                        },
                    ]
                }
            )
            unknown = worker.suggestion_predicate(
                {"path": "not_public.value", "op": "eq", "value": "x"}
            )
        with LuaSemanticWorker(private_scenario) as worker:
            private = worker.suggestion_predicate(
                {
                    "path": "semanticAuthorization.private",
                    "op": "eq",
                    "value": True,
                }
            )

        self.assertTrue(allowed["result"]["allowed"])
        self.assertEqual(allowed["result"]["status"], "allowed")
        self.assertTrue(any_allowed["result"]["allowed"])
        self.assertEqual(any_allowed["result"]["reason"], "any_allowed")
        self.assertFalse(unknown["result"]["allowed"])
        self.assertEqual(unknown["result"]["status"], "unknown")
        self.assertFalse(private["result"]["allowed"])
        self.assertEqual(private["result"]["status"], "private")
        self.assertEqual(private["result"]["trace"][0]["path"], "<private>")

    def test_follow_stay_wait_at_constraints_fail_closed_for_npc_state(self) -> None:
        for behavior, expected in (
            ("idle", {"FOLLOW": "eligible", "STAY": "eligible"}),
            (
                "hostile",
                {"FOLLOW": "unavailable_rejected", "STAY": "unavailable_rejected"},
            ),
            (
                "busy",
                {"FOLLOW": "unavailable_rejected", "STAY": "unavailable_rejected"},
            ),
        ):
            with self.subTest(behavior=behavior):
                scenario = deepcopy(DEFAULT_SCENARIO)
                scenario["npc"]["activeBehavior"] = behavior
                with LuaSemanticWorker(scenario) as worker:
                    result = worker.preview("Are you okay?")

                capabilities = {
                    row["action"]: row
                    for row in result["observation"]["suggestions"][
                        "permittedCapabilities"
                    ]
                }
                for action, status in expected.items():
                    self.assertEqual(capabilities[action]["status"], status)
                self.assertEqual(
                    capabilities["WAIT_AT"]["status"],
                    "requires_destination"
                    if behavior == "idle"
                    else "unavailable_rejected",
                )
                self.assertTrue(result["observation"]["sideEffects"]["none"])

        unknown_scenario = deepcopy(DEFAULT_SCENARIO)
        unknown_scenario["npc"].pop("activeBehavior")
        with LuaSemanticWorker(unknown_scenario) as worker:
            unknown = worker.preview("Are you okay?")
        unknown_capabilities = {
            row["action"]: row
            for row in unknown["observation"]["suggestions"][
                "permittedCapabilities"
            ]
        }
        self.assertEqual(
            unknown_capabilities["FOLLOW"]["status"],
            "unavailable_unknown",
        )

    def test_player_projection_has_no_private_or_romance_inference(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["semanticAuthorization"] = {
            "private": True,
            "secretOrientation": "private_value",
        }
        scenario["npc"]["knowledge"] = {
            "secret": True,
            "undiscovered": "private_value",
        }
        with LuaSemanticWorker(scenario) as worker:
            result = worker.preview("Are you okay?")

        suggestions = result["observation"]["suggestions"]
        self.assertTrue(suggestions["privacy"]["playerVisible"])
        self.assertFalse(suggestions["privacy"]["unknownFieldsExposed"])
        serialized = str(suggestions)
        self.assertNotIn("private_value", serialized)
        self.assertNotIn("secretOrientation", serialized)
        self.assertFalse(
            any("romance" in candidate["id"] for candidate in suggestions["candidates"])
        )


if __name__ == "__main__":
    unittest.main()
