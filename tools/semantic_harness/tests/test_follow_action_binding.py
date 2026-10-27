"""Real-Lua Semantic Lab acceptance for the typed FOLLOW binding."""

from __future__ import annotations

import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class FollowActionBindingTests(unittest.TestCase):
    def test_live_catalog_exposes_follow_binding(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()

        follow = next(
            action for action in catalog["actionCatalog"] if action["id"] == "FOLLOW"
        )
        self.assertTrue(follow["recognized"])
        self.assertTrue(follow["dispatchable"])
        self.assertEqual(follow["bindingStatus"], "registered")
        self.assertEqual(follow["binding"]["id"], "pnc:companion.follow")
        self.assertEqual(follow["binding"]["commandID"], "follow")
        self.assertEqual(
            follow["binding"]["handlerID"], "PNC.Client.SendCompanionCommand"
        )
        self.assertEqual(follow["binding"]["route"], "existing_companion_command")

    def test_follow_vertical_slice_is_real_lua_and_preview_is_pure(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            previews = [worker.preview("Follow me") for _ in range(2)]
            committed = worker.input("Follow me")
            negated = worker.input("Don't follow me")
            question = worker.input("Are you following me?")
            ambiguous = worker.input("maybe follow me")

        for preview in previews:
            self.assertEqual(preview["type"], "preview")
            self.assertEqual(preview["observation"]["ir"]["action"], "FOLLOW")
            self.assertEqual(
                preview["observation"]["capabilityBinding"]["id"],
                "pnc:companion.follow",
            )
            self.assertTrue(preview["observation"]["sideEffects"]["none"])
            self.assertEqual(preview["transport"], [])
            self.assertEqual(preview["toolCalls"], [])

        result = committed["result"]
        self.assertEqual(result["ir"]["intent"], "REQUEST")
        self.assertEqual(result["ir"]["action"], "FOLLOW")
        self.assertEqual(result["ir"]["provenance"]["pattern"], "pnc.command.follow")
        self.assertEqual(result["decision"]["branch"], "COMMAND_ACCEPTED")
        self.assertTrue(committed["observation"]["flow"]["generated"])
        self.assertTrue(committed["observation"]["flow"]["matched"])
        self.assertEqual(committed["observation"]["flow"]["resultNodeId"], "queued")
        self.assertEqual(result["actionResult"]["commandID"], "follow")
        self.assertTrue(result["actionResult"]["accepted"])
        self.assertEqual(result["actionResult"]["reason"], "network_queued")
        self.assertEqual(
            result["actionResult"]["capabilityID"], "pnc:companion.follow"
        )
        self.assertEqual(
            result["actionResult"]["handlerID"], "PNC.Client.SendCompanionCommand"
        )
        self.assertEqual(result["actionResult"]["request"]["npcID"], "npc_mara")
        self.assertEqual(result["actionResult"]["request"]["requestID"], 1)
        self.assertEqual(
            [event["payload"]["commandID"] for event in committed["transport"]],
            ["follow"],
        )
        self.assertEqual(len(committed["toolCalls"]), 1)
        self.assertEqual(committed["toolCalls"][0]["name"], "follow")
        self.assertEqual(committed["toolCalls"][0]["authority"], "mock")
        self.assertEqual(
            committed["messages"][0]["payload"]["text"],
            "Okay, I'll follow you.",
        )

        # The explicit negated pattern is STOP, so it must never silently
        # reuse the FOLLOW binding or issue a follow command.
        self.assertEqual(negated["result"]["ir"]["action"], "STOP")
        self.assertNotIn(
            "follow",
            [event["payload"]["commandID"] for event in negated["transport"]],
        )
        self.assertEqual(
            negated["result"]["actionResult"]["commandID"], "stay"
        )

        for safe_negative in (question, ambiguous):
            self.assertEqual(safe_negative["transport"], [])
            self.assertEqual(safe_negative["toolCalls"], [])
            self.assertEqual(safe_negative["observation"]["sideEffects"]["none"], True)
        self.assertEqual(question["result"]["decision"]["branch"], "ASK_CLARIFICATION")
        self.assertEqual(ambiguous["result"]["decision"]["branch"], "ASK_CLARIFICATION")

    def test_unauthorized_follow_has_authority_result_and_truthful_reply(self) -> None:
        scenario = merge(
            DEFAULT_SCENARIO,
            {
                "runtime": {
                    "commandResponses": {
                        "follow": {
                            "accepted": False,
                            "reason": "unauthorized_companion",
                        }
                    }
                }
            },
        )
        with LuaSemanticWorker(scenario) as worker:
            denied = worker.input("Follow me")

        action = denied["result"]["actionResult"]
        self.assertFalse(action["accepted"])
        self.assertEqual(action["status"], "rejected")
        self.assertEqual(action["reason"], "unauthorized_companion")
        self.assertEqual(len(denied["transport"]), 1)
        self.assertEqual(denied["transport"][0]["payload"]["commandID"], "follow")
        self.assertEqual(len(denied["toolCalls"]), 1)
        self.assertFalse(denied["toolCalls"][0]["accepted"])
        self.assertEqual(denied["toolCalls"][0]["capabilityID"], "pnc:companion.follow")
        self.assertEqual(
            denied["messages"][0]["payload"]["text"],
            "I can't follow you right now.",
        )
        self.assertNotEqual(
            denied["observation"]["response"]["text"], "Okay."
        )

    def test_unauthorized_follow_preserves_tl_translation(self) -> None:
        scenario = merge(
            DEFAULT_SCENARIO,
            {
                "runtime": {
                    "language": "TL",
                    "commandResponses": {
                        "follow": {
                            "accepted": False,
                            "reason": "unauthorized_companion",
                        }
                    },
                }
            },
        )
        with LuaSemanticWorker(scenario) as worker:
            denied = worker.input("Follow me")

        self.assertEqual(
            denied["messages"][0]["payload"]["text"],
            "Hindi kita masusundan ngayon.",
        )
        self.assertEqual(
            denied["messages"][0]["payload"]["translationKey"],
            "UI_PNC_Conversation_Semantic_GeneratedFollowRejected",
        )


if __name__ == "__main__":
    unittest.main()
