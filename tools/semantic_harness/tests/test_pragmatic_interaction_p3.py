"""P3 headless observation acceptance for the interaction director."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class PragmaticInteractionP3Tests(unittest.TestCase):
    def test_observation_explains_hostile_turn_end_to_end(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["personality"] = {
            "aggression": 0.95,
            "confidence": 0.85,
            "forgiveness": 0.8,
        }
        with LuaSemanticWorker(scenario) as worker:
            result = worker.input("fuck ypuuuu")

        observation = result["observation"]
        self.assertEqual(observation["ir"]["intent"], "HOSTILE_REMARK")
        director = observation["director"]
        self.assertEqual(director["kind"], "interaction_director_preview")
        self.assertTrue(director["committed"])
        self.assertEqual(
            director["selectedBeat"]["id"],
            "beat.argument_escalation",
        )
        self.assertEqual(
            director["selectedBehavior"]["id"],
            "behavior.retaliate_verbally",
        )
        argument = next(
            row for row in director["beatCandidates"]
            if row["id"] == "beat.argument_escalation"
        )
        self.assertEqual(argument["status"], "eligible")
        self.assertTrue(argument["predicateTrace"]["rows"])
        retaliate = next(
            row for row in director["behaviorCandidates"]
            if row["id"] == "behavior.retaliate_verbally"
        )
        self.assertTrue(retaliate["eligible"])
        modifier = next(
            row for row in retaliate["modifiers"]
            if row["reason"] == "aggressive_personality"
        )
        self.assertTrue(modifier["matched"])
        self.assertEqual(modifier["delta"], 0.2)

        interaction_plan = observation["interactionPlan"]
        self.assertEqual(
            interaction_plan["beatID"],
            "beat.argument_escalation",
        )
        self.assertEqual(
            interaction_plan["behaviorID"],
            "behavior.retaliate_verbally",
        )
        self.assertEqual(
            interaction_plan["dialogueAct"],
            "RETALIATE_VERBALLY",
        )
        response = observation["response"]
        self.assertEqual(
            response["sourcePoolID"],
            "semantic.hostile_remark",
        )
        self.assertEqual(response["dialogueAct"], "RETALIATE_VERBALLY")
        self.assertTrue(response["text"])
        self.assertTrue(observation["translation"]["lookups"] or response["fallback"])
        self.assertIn("none", observation["sideEffects"])
        action = observation.get("actionResult") or {}
        self.assertEqual(action.get("speechAct"), "HOSTILE_REMARK")
        self.assertTrue(action.get("accepted"), action)

    def test_observation_shows_argument_exit_and_reconciliation_entry(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            worker.input("fuck you")
            result = worker.input("sorry")

        director = result["observation"]["director"]
        self.assertEqual(
            director["exited"]["id"],
            "beat.argument_escalation",
        )
        self.assertEqual(
            director["entered"]["id"],
            "beat.reconciliation",
        )
        self.assertEqual(
            director["contextAfter"]["active"]["id"],
            "beat.reconciliation",
        )
        self.assertGreaterEqual(
            int(director["contextAfter"]["revision"]),
            2,
        )

    def test_observation_bounds_candidate_and_trace_surfaces(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            result = worker.input("fuck you")
        director = result["observation"]["director"]
        self.assertLessEqual(len(director["beatCandidates"]), 12)
        self.assertLessEqual(len(director["behaviorCandidates"]), 12)
        for beat in director["beatCandidates"]:
            self.assertLessEqual(
                len((beat.get("predicateTrace") or {}).get("rows") or []),
                24,
            )
        for behavior in director["behaviorCandidates"]:
            self.assertLessEqual(
                len((behavior.get("eligibilityTrace") or {}).get("rows") or []),
                24,
            )


if __name__ == "__main__":
    unittest.main()
