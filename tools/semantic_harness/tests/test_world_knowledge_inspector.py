"""Semantic Lab GUI projection and explainability for World Knowledge."""

from __future__ import annotations

import unittest

from tools.semantic_harness.inspection.world_knowledge import (
    build_world_knowledge_inspector,
)
from tools.semantic_harness.tests.test_grounded_world_knowledge_gossip import (
    scenario_for,
)
from tools.semantic_harness.worker import LuaSemanticWorker


class WorldKnowledgeInspectorTests(unittest.TestCase):
    def test_real_worker_projection_answers_why_actor_knows(self) -> None:
        scenario = scenario_for("alice", "EN", [
            {
                "actorID": "actor:alice",
                "factIndex": 1,
                "provenance": "witnessed",
                "source": "semantic_lab_fixture",
                "acquisitionPath": "scenario_authority",
                "confidence": 0.95,
            },
        ])
        with LuaSemanticWorker(scenario) as worker:
            worker.input("any gossip?")
            initial = worker.world_knowledge_inspect(actor_id="actor:alice")
            fact_id = initial["ledger"]["facts"][0]["factID"]
            raw = worker.world_knowledge_inspect(
                actor_id="actor:alice", fact_id=fact_id
            )

        view = build_world_knowledge_inspector(raw)
        self.assertEqual(view["source"], "real_lua_worker")
        self.assertTrue(view["factLedger"]["facts"])
        self.assertEqual(view["actorKnowledge"]["actorID"], "actor:alice")
        self.assertTrue(view["candidateSelection"]["ranked"])
        self.assertTrue(view["whyActorKnows"])
        self.assertEqual(
            view["whyActorKnows"]["factID"],
            view["finalRealization"]["factRefs"][0],
        )
        self.assertEqual(view["whyActorKnows"]["provenance"], "witnessed")
        self.assertEqual(view["finalRealization"]["source"], "world_knowledge")
        self.assertEqual(view["finalRealization"]["localization"], "EN")


if __name__ == "__main__":
    unittest.main()
