"""P6 emergent initial beat-set acceptance."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


def scenario_with_personality(**values):
    scenario = deepcopy(DEFAULT_SCENARIO)
    scenario["npc"]["personality"] = values
    return scenario


class PragmaticInteractionP6Tests(unittest.TestCase):
    def test_suspicious_first_contact_persists_then_challenges_gossip(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            greeting = worker.input("hello")
            gossip = worker.input("do you have any news")
            wellbeing = worker.input("are you okay")

        first = greeting["result"]["decision"]["director"]
        self.assertEqual(
            first["selectedBeat"]["id"],
            "beat.suspicious_first_contact",
        )
        # Greeting flow remains authoritative for the first utterance.
        self.assertEqual(
            greeting["result"]["decision"]["response"]["sourcePoolID"],
            "semantic.flow.greeting.opening",
        )

        second = gossip["result"]["decision"]["director"]
        self.assertEqual(
            second["selectedBeat"]["id"],
            "beat.suspicious_first_contact",
        )
        self.assertEqual(
            second["selectedBehavior"]["id"],
            "behavior.challenge",
        )
        self.assertEqual(
            gossip["result"]["decision"]["response"]["sourcePoolID"],
            "semantic.gossip",
        )
        self.assertEqual(
            gossip["result"]["decision"]["response"]["plan"]["dialogueAct"],
            "CHALLENGE",
        )
        self.assertNotEqual(
            gossip["result"]["decision"]["response"]["fallback"],
            "I'm not sure what you mean.",
        )

        # The active dramatic situation does not steal a grounded wellbeing turn.
        third = wellbeing["result"]["decision"]
        self.assertEqual(third["branch"], "QUESTION_RECEIVED")
        self.assertNotEqual(
            third["response"].get("plan", {}).get("dialogueAct"),
            "CHALLENGE",
        )

    def test_argument_behavior_varies_without_changing_semantic_meaning(self) -> None:
        variants = [
            (
                scenario_with_personality(
                    aggression=0.95, confidence=0.85, forgiveness=0.8
                ),
                "behavior.retaliate_verbally",
                "RETALIATE_VERBALLY",
            ),
            (
                deepcopy(DEFAULT_SCENARIO),
                "behavior.warn",
                "BOUNDARY_WARNING",
            ),
        ]
        panic = scenario_with_personality(
            aggression=0.2, confidence=0.2, forgiveness=0.8
        )
        panic["npc"]["conditionStats"] = {
            "panic": 90,
            "stress": 0,
            "boredom": 0,
        }
        variants.append(
            (
                panic,
                "behavior.deescalate",
                "DEESCALATE",
            )
        )

        for scenario, expected_behavior, expected_act in variants:
            with self.subTest(expected_behavior=expected_behavior):
                with LuaSemanticWorker(scenario) as worker:
                    result = worker.input("fuck ypuuuu")
                ir = result["result"]["ir"]
                self.assertEqual(ir["intent"], "HOSTILE_REMARK")
                self.assertEqual(ir["provenance"]["pattern"], "pnc.social.profanity")
                director = result["result"]["decision"]["director"]
                self.assertEqual(
                    director["selectedBeat"]["id"],
                    "beat.argument_escalation",
                )
                self.assertEqual(
                    director["selectedBehavior"]["id"],
                    expected_behavior,
                )
                decision = result["result"]["decision"]
                self.assertEqual(
                    decision["response"]["sourcePoolID"],
                    "semantic.hostile_remark",
                )
                self.assertEqual(
                    decision["response"]["plan"]["dialogueAct"],
                    expected_act,
                )
                self.assertEqual(
                    decision["interactionPlan"]["behaviorID"],
                    expected_behavior,
                )

    def test_reconciliation_outcome_depends_on_forgiveness(self) -> None:
        cases = [
            (
                0.9,
                "behavior.reconcile",
                "RECONCILE",
            ),
            (
                0.1,
                "behavior.end_conversation",
                "END_CONVERSATION",
            ),
        ]
        for forgiveness, expected_behavior, expected_act in cases:
            with self.subTest(forgiveness=forgiveness):
                scenario = scenario_with_personality(
                    forgiveness=forgiveness
                )
                with LuaSemanticWorker(scenario) as worker:
                    worker.input("fuck you")
                    result = worker.input("sorry")
                director = result["result"]["decision"]["director"]
                self.assertEqual(
                    director["exited"]["id"],
                    "beat.argument_escalation",
                )
                self.assertEqual(
                    director["selectedBeat"]["id"],
                    "beat.reconciliation",
                )
                self.assertEqual(
                    director["selectedBehavior"]["id"],
                    expected_behavior,
                )
                decision = result["result"]["decision"]
                self.assertEqual(
                    decision["response"]["sourcePoolID"],
                    "semantic.apology",
                )
                self.assertEqual(
                    decision["response"]["plan"]["dialogueAct"],
                    expected_act,
                )
                self.assertEqual(
                    decision["interactionPlan"]["behaviorID"],
                    expected_behavior,
                )

    def test_initial_beats_are_data_not_hardwired_director_ids(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.beat_catalog()
        self.assertEqual(
            {item["id"] for item in catalog["beats"]},
            {
                "beat.suspicious_first_contact",
                "beat.argument_escalation",
                "beat.reconciliation",
            },
        )
        for beat in catalog["beats"]:
            self.assertTrue(beat["candidates"])
            for candidate in beat["candidates"]:
                self.assertTrue(candidate["behavior"].startswith("behavior."))


if __name__ == "__main__":
    unittest.main()
