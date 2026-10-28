from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


def generated(turn: dict, strategy: str) -> dict | None:
    for row in turn["observation"]["suggestions"]["candidates"]:
        if (
            row.get("providerID") == "projecthoomans.generated_affordances"
            and row.get("strategy") == strategy
        ):
            return row
    return None


class OpenEndedSemanticCombatAwarenessTests(unittest.TestCase):
    def test_double_down_advances_frontier_instead_of_immediate_self_loop(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.open_conversation()
            first = worker.input("fuckyouuuu")
            double_down = generated(first, "DOUBLE_DOWN")
            self.assertIsNotNone(double_down)
            second = worker.suggestion_click(double_down["frame"])

        self.assertEqual(
            (second["result"]["ir"]["intent"], second["result"]["ir"]["speechAct"]),
            ("HOSTILE_REMARK", "HOSTILE_REMARK"),
        )
        self.assertIsNone(
            generated(second, "DOUBLE_DOWN"),
            "generated frontier must not immediately offer DOUBLE_DOWN again",
        )
        remaining = {
            row.get("strategy")
            for row in second["observation"]["suggestions"]["candidates"]
            if row.get("providerID") == "projecthoomans.generated_affordances"
        }
        self.assertTrue(
            {"APOLOGIZE", "CLAIM_JOKE", "DEESCALATE", "CHALLENGE", "DISMISS"}
            & remaining,
            remaining,
        )

    def test_hostile_frontier_prioritizes_relevant_open_ended_moves(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.open_conversation()
            turn = worker.input("fuckyouuuu")

        strategies = [
            row.get("strategy")
            for row in turn["observation"]["suggestions"]["candidates"]
            if row.get("providerID") == "projecthoomans.generated_affordances"
        ]
        self.assertIn("DOUBLE_DOWN", strategies)
        self.assertIn("CLAIM_JOKE", strategies)
        self.assertIn("DEESCALATE", strategies)
        self.assertIn("ASK_WHY", strategies)
        self.assertNotIn("ACCEPT", strategies)
        self.assertNotIn("REFUSE", strategies)

    def test_typed_i_mean_it_reaffirms_active_hostility(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.open_conversation()
            worker.input("fuckyouuuu")
            turn = worker.input("yeah i meant it")
        self.assertEqual(
            (turn["result"]["ir"]["intent"], turn["result"]["ir"]["speechAct"]),
            ("HOSTILE_REMARK", "HOSTILE_REMARK"),
        )
        self.assertEqual(
            turn["result"]["ir"]["provenance"].get("contextualReframe"),
            "hostile_reaffirmation",
        )

    def test_i_mean_it_without_hostility_is_not_fabricated_as_hostile(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.open_conversation()
            turn = worker.input("i mean it")
        self.assertEqual(
            (turn["result"]["ir"]["intent"], turn["result"]["ir"]["speechAct"]),
            ("ACKNOWLEDGE", "ACKNOWLEDGE"),
        )

    def test_double_down_realization_is_locale_owned(self) -> None:
        surfaces: dict[str, str] = {}
        for language in ("EN", "TL"):
            scenario = deepcopy(DEFAULT_SCENARIO)
            scenario["runtime"]["language"] = language
            with LuaSemanticWorker(scenario) as worker:
                worker.open_conversation()
                turn = worker.input("fuckyouuuu")
            row = generated(turn, "DOUBLE_DOWN")
            self.assertIsNotNone(row)
            surfaces[language] = row["display"]["utterance"]
            self.assertTrue(surfaces[language])
        self.assertNotEqual(surfaces["EN"], surfaces["TL"])


if __name__ == "__main__":
    unittest.main()
