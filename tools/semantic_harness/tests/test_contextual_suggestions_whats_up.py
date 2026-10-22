"""What's Up activates the semantic hub through the production Lua worker."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class WhatsUpSemanticHubTests(unittest.TestCase):
    ALIASES = (
        "what's up",
        "whats up",
        "what is up",
        "what up",
        "whatsup",
        "what's new",
        "whats new",
        "anything new",
        "what's happening",
        "whats happening",
        "anything going on",
    )

    def test_reviewed_aliases_activate_hub_without_conversation_block(self) -> None:
        for utterance in self.ALIASES:
            with self.subTest(utterance=utterance):
                worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
                try:
                    response = worker.input(utterance)
                    self.assertTrue(response["accepted"])
                    ir = response["result"]["ir"]
                    self.assertEqual(ir["intent"], "QUESTION")
                    self.assertEqual(ir["speechAct"], "QUESTION")
                    self.assertEqual(ir["subject"], "CONVERSATION_TOPIC")
                    self.assertEqual(ir["extensions"]["topic"], "whats_up")
                    self.assertEqual(ir["extensions"]["route"], "semantic_hub")
                    self.assertEqual(ir["extensions"]["hubID"], "whats_up")
                    self.assertNotIn("categoryID", ir["extensions"])

                    observation = response["observation"]
                    self.assertIsNone(observation.get("conversationBlock"))
                    self.assertIsNone(observation.get("conversationGraph"))
                    suggestions = observation["suggestions"]
                    self.assertEqual(
                        suggestions["activeHub"],
                        {"id": "whats_up", "route": "semantic_hub"},
                    )
                    self.assertTrue(suggestions["choiceRegistry"]["providers"])
                    self.assertNotIn(
                        "semantic_hub.whats_up",
                        {item["id"] for item in suggestions["candidates"]},
                    )
                finally:
                    worker.close()

    def test_typed_root_phrase_activates_without_a_second_hub_click(self) -> None:
        worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
        try:
            activated = worker.input("What's up?")
            self.assertTrue(activated["accepted"])
            ir = activated["result"]["ir"]
            self.assertEqual(ir["extensions"]["route"], "semantic_hub")
            self.assertEqual(ir["extensions"]["hubID"], "whats_up")
            self.assertEqual(
                activated["observation"]["suggestions"]["activeHub"]["id"],
                "whats_up",
            )
            self.assertIsNone(activated["observation"].get("conversationBlock"))
            self.assertIsNone(activated["observation"].get("conversationGraph"))
        finally:
            worker.close()

    def test_specific_conversation_semantics_remain_direct(self) -> None:
        cases = (
            ("Are you okay?", "WELLBEING"),
            ("Any gossip?", "GOSSIP"),
            ("Are you hurt?", "NPC_HEALTH_STATE"),
            ("Do you need anything?", "NEEDS"),
            ("What have you been doing?", "ACTIVITY"),
        )
        for utterance, expected_subject in cases:
            with self.subTest(utterance=utterance):
                worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
                try:
                    response = worker.input(utterance)
                    self.assertTrue(response["accepted"])
                    self.assertEqual(
                        response["result"]["ir"]["subject"], expected_subject
                    )
                    self.assertIsNone(
                        response["observation"].get("conversationBlock")
                    )
                finally:
                    worker.close()


if __name__ == "__main__":
    unittest.main()
