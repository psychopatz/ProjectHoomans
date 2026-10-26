"""P4 precedence, contextual ranking, and privacy contracts."""

from __future__ import annotations

from copy import deepcopy
import json
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class ContextualRankingP4Tests(unittest.TestCase):
    def _turn(self, updates: dict[str, object], value: str = "hello") -> dict:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"].update(updates)
        with LuaSemanticWorker(scenario) as worker:
            return worker.input(value)

    @staticmethod
    def _rows(turn: dict) -> list[dict]:
        return turn["observation"]["suggestions"]["candidates"]

    def test_documented_precedence_classes_order_existing_sources(self) -> None:
        turn = self._turn({})
        rows = self._rows(turn)
        by_id = {row["id"]: row for row in rows}

        self.assertEqual(
            by_id["greeting.thanks"]["ranking"]["class"],
            "BRANCH_CONTINUATION",
        )
        self.assertEqual(
            by_id["greeting.check_in.report_wellbeing"]["ranking"]["class"],
            "DIRECT_RESPONSE",
        )
        self.assertLess(
            by_id["greeting.thanks"]["ranking"]["order"],
            by_id["greeting.check_in.report_wellbeing"]["ranking"]["order"],
        )
        self.assertEqual(
            [row["ranking"]["order"] for row in rows], list(range(1, len(rows) + 1))
        )
        self.assertEqual(
            turn["observation"]["suggestions"]["ranking"]["privacy"],
            {
                "privateFieldsInspected": False,
                "privateRelationshipScoresExposed": False,
                "undiscoveredFactsExposed": False,
            },
        )

    def test_situation_fit_reorders_without_changing_semantic_ids_or_frame(self) -> None:
        healthy = self._turn({}, "Are you okay?")
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["healthState"] = "injured"
        with LuaSemanticWorker(scenario) as worker:
            injured = worker.input("Are you okay?")
            healthy_rows = self._rows(healthy)
            injured_rows = self._rows(injured)
            self.assertEqual(
                {row["id"] for row in healthy_rows},
                {row["id"] for row in injured_rows},
            )
            healthy_order = [row["id"] for row in healthy_rows]
            injured_order = [row["id"] for row in injured_rows]
            self.assertNotEqual(healthy_order, injured_order)
            self.assertLess(
                injured_order.index("question.health"),
                injured_order.index("question.wellbeing"),
            )

            health = next(
                row for row in injured_rows if row["id"] == "question.health"
            )
            self.assertEqual(health["frame"]["candidateID"], "question.health")
            clicked = worker.suggestion_click(health["frame"])
            self.assertTrue(clicked["accepted"], clicked.get("reason"))

    def test_private_fields_do_not_change_projection_or_ranking_trace(self) -> None:
        public = self._turn({"healthState": "normal"}, "Are you okay?")
        private = self._turn(
            {
                "healthState": "normal",
                "orientation": "private-orientation-sentinel",
                "romanceStyle": "private-romance-sentinel",
                "jealousyStyle": "private-jealousy-sentinel",
                "secretBackstory": "private-backstory-sentinel",
            },
            "Are you okay?",
        )
        public_rows = self._rows(public)
        private_rows = self._rows(private)
        self.assertEqual(
            [(row["id"], row["ranking"]["class"], row["ranking"]["order"]) for row in public_rows],
            [(row["id"], row["ranking"]["class"], row["ranking"]["order"]) for row in private_rows],
        )
        rendered = json.dumps(private["observation"]["suggestions"], sort_keys=True)
        self.assertNotIn("private-orientation-sentinel", rendered)
        self.assertNotIn("private-romance-sentinel", rendered)
        self.assertNotIn("private-jealousy-sentinel", rendered)
        self.assertNotIn("private-backstory-sentinel", rendered)

if __name__ == "__main__":
    unittest.main()
