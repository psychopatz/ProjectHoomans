"""P12H production mutation-route acceptance tests."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class ProductionMutationP12HTests(unittest.TestCase):
    def test_normal_semantic_proposal_choice_calls_production_route(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["relationship"].update(
            {"approval": 100, "respect": 100, "familiarity": 100, "revision": 2}
        )
        scenario["npc"]["identitySeed"] = "p12h-proposal"
        with LuaSemanticWorker(scenario) as worker:
            source_before = deepcopy(worker.source_snapshot.to_dict())
            suggestions = worker.snapshot()["suggestions"]
            candidates = [
                candidate
                for candidate in suggestions.get("candidates", [])
                if candidate.get("id") == "social.relationship_proposal"
            ]
            if not candidates:
                for group in suggestions.get("groups", []):
                    candidates.extend(
                        candidate
                        for candidate in group.get("candidates", [])
                        if candidate.get("id") == "social.relationship_proposal"
                    )
            self.assertTrue(candidates, suggestions)

            clicked = worker.suggestion_click(candidates[0]["frame"])
            after = worker.snapshot()
            source_after = worker.source_snapshot.to_dict()
            relationship = after["scenario"]["npc"]["relationship"]
            memories = relationship.get("memories") or []

        self.assertTrue(clicked["accepted"], clicked)
        self.assertEqual(source_after, source_before)
        self.assertGreaterEqual(len(memories), 1)
        self.assertIn(
            memories[-1].get("type"),
            {"relationship_proposal_accepted", "relationship_proposal_rejected"},
        )
        self.assertEqual(
            source_before["data"]["npc"]["relationship"]["revision"], 2
        )
        self.assertEqual(
            source_before["data"]["npc"]["relationship"].get("memories", []),
            [],
        )
        self.assertGreater(relationship["revision"], 2)


if __name__ == "__main__":
    unittest.main()
