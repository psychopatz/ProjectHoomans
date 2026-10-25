"""P12H acceptance for the authored What's up? semantic response path."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class WhatsUpSemanticResponseP12HTests(unittest.TestCase):
    def test_landing_shortcut_preserves_typed_semantic_route(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.open_conversation()
            channel = worker.conversation_projection()["presentation"]["responseChannel"]
            shortcut = next(
                row["frame"]
                for row in channel["rows"]
                if row["id"] == "conversation.landing:whats_up"
            )
            result = worker.suggestion_click(shortcut)

        self.assertTrue(result["accepted"])
        npc_messages = [
            message
            for message in result.get("messages", [])
            if message.get("speaker") == "npc"
        ]
        self.assertTrue(npc_messages)
        payload = npc_messages[-1]["payload"]
        self.assertTrue(payload.get("key", "").startswith("semantic.question.whats_up."))
        self.assertNotEqual(payload.get("text"), "Let me think about that.")

    def test_whats_up_uses_grounded_semantic_realization(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            result = worker.input("What's up?")

        self.assertTrue(result["accepted"])
        npc_messages = [
            message
            for message in result.get("messages", [])
            if message.get("speaker") == "npc"
        ]
        self.assertTrue(npc_messages)
        payload = npc_messages[-1]["payload"]
        self.assertTrue(payload.get("text"))
        self.assertNotEqual(payload.get("key"), "semantic.question.received")
        self.assertNotEqual(payload.get("text"), "Let me think about that.")
        self.assertTrue(
            payload.get("key", "").startswith("semantic.question.whats_up.")
        )


if __name__ == "__main__":
    unittest.main()
