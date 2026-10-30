"""S2 constraint and privacy checks through the production Lua worker."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


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
            ("idle", {"FOLLOW": "eligible", "GO": "eligible"}),
            ("hostile", {"GO": "unavailable_rejected"}),
            ("busy", {"GO": "unavailable_rejected"}),
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
                self.assertNotIn("STAY", capabilities)
                self.assertNotIn("WAIT_AT", capabilities)
                if behavior == "idle":
                    self.assertEqual(
                        capabilities["CAMP"]["status"],
                        "unavailable_no_camp_site",
                    )
                else:
                    self.assertNotIn("CAMP", capabilities)
                self.assertTrue(result["observation"]["sideEffects"]["noGameplayEffects"])

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
        self.assertNotIn("FOLLOW", unknown_capabilities)
        self.assertNotIn("STAY", unknown_capabilities)
        self.assertNotIn("WAIT_AT", unknown_capabilities)
        self.assertEqual(
            unknown_capabilities["GO"]["status"], "unavailable_unknown"
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

    def test_dynamic_dialogue_branches_fail_closed_for_busy_hostile_or_unknown_npc(self) -> None:
        for behavior in ("busy", "hostile"):
            scenario = deepcopy(DEFAULT_SCENARIO)
            scenario["npc"]["activeBehavior"] = behavior
            with self.subTest(behavior=behavior):
                with LuaSemanticWorker(scenario) as worker:
                    result = worker.input("hello")
                ids = {
                    candidate["id"]
                    for candidate in result["observation"]["suggestions"]["candidates"]
                }
                self.assertNotIn("greeting.thanks", ids)
                self.assertNotIn("greeting.check_in.report_wellbeing", ids)

        unknown_scenario = deepcopy(DEFAULT_SCENARIO)
        unknown_scenario["npc"].pop("activeBehavior")
        with LuaSemanticWorker(unknown_scenario) as worker:
            result = worker.input("hello")
        ids = {
            candidate["id"]
            for candidate in result["observation"]["suggestions"]["candidates"]
        }
        self.assertNotIn("greeting.thanks", ids)
        self.assertNotIn("greeting.check_in.report_wellbeing", ids)

    def test_relationship_boundaries_traits_and_unsupported_social_provider_fail_closed(self) -> None:
        for approval, expected in ((-1, "rejected"), (0, "allowed"), (1, "allowed")):
            scenario = deepcopy(DEFAULT_SCENARIO)
            scenario["npc"]["relationship"]["approval"] = approval
            with self.subTest(approval=approval):
                with LuaSemanticWorker(scenario) as worker:
                    result = worker.suggestion_predicate(
                        {
                            "path": "relationship.approval",
                            "op": "gte",
                            "value": 0,
                        }
                    )
                self.assertEqual(result["result"]["status"], expected)

        trait_scenario = deepcopy(DEFAULT_SCENARIO)
        trait_scenario["npc"]["traits"] = {"friendly": True}
        with LuaSemanticWorker(trait_scenario) as worker:
            trait_true = worker.suggestion_predicate(
                {"path": "npcState.traits.friendly", "op": "truthy"}
            )
            unsupported = worker.suggestion_predicate(
                {"path": "romance.compatibility", "op": "truthy"}
            )
            projection = worker.preview("Are you okay?")

        self.assertEqual(trait_true["result"]["status"], "allowed")
        self.assertEqual(unsupported["result"]["status"], "unknown")
        self.assertFalse(
            any(
                token in str(projection["observation"]["suggestions"])
                for token in ("romance", "consent", "orientation")
            )
        )


if __name__ == "__main__":
    unittest.main()
