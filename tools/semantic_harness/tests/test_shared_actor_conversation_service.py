"""Real-worker checks for the Core actor-service Hoomans boundary."""

from __future__ import annotations

import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class SharedActorConversationServiceTests(unittest.TestCase):
    def test_real_worker_attaches_one_core_service_to_the_session(self) -> None:
        scenario = merge(DEFAULT_SCENARIO, {"npc": {"npcID": "mara"}})
        with LuaSemanticWorker(scenario) as worker:
            first = worker.input("hello")
            second = worker.input("where do you live")

        first_service = first["actorConversation"]
        second_service = second["actorConversation"]
        self.assertEqual(first_service["actorID"], "mara")
        self.assertEqual(second_service["actorID"], "mara")
        self.assertEqual(first_service["conversationID"], "harness-conversation")
        self.assertEqual(second_service["conversationID"], "harness-conversation")
        self.assertEqual(first_service["turnCount"], 1)
        self.assertEqual(second_service["turnCount"], 2)
        self.assertEqual(
            first_service["state"]["version"],
            second_service["state"]["version"],
        )

    def test_compound_turn_uses_the_same_actor_service_and_router(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            turn = worker.input("im fine, how about you")

        service = turn["actorConversation"]
        self.assertEqual(service["actorID"], DEFAULT_SCENARIO["npc"]["npcID"])
        self.assertEqual(service["turnCount"], 2)
        self.assertEqual(len(turn["result"]["compound"]["parts"]), 2)
        self.assertEqual(turn["llmCalls"], 0)
        self.assertEqual(turn["transport"], [])


if __name__ == "__main__":
    unittest.main()
