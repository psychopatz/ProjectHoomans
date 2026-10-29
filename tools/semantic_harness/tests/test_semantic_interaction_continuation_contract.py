from __future__ import annotations

import unittest

from tools.semantic_harness.codebuilder.conversation_compiler import (
    CompileError,
    _validate_behavior_shard,
)


def behavior(continuation: dict | None) -> dict:
    record = {
        "id": "behavior.test.continuation",
        "version": 1,
        "owner": "Test",
        "act": "ASK_FOLLOWUP",
        "mode": "one_shot",
        "stimuli": ["NPC_SEMANTIC_ACT"],
        "requiredCapabilities": ["speech"],
        "outputs": {
            "speech": {
                "dialogueAct": "ASK_FOLLOWUP",
                "contentTemplateID": "semantic.interaction.memory.followup",
            }
        },
        "baseRelevance": 0.8,
        "modifiers": [],
    }
    if continuation is not None:
        record["continuation"] = continuation
    return {
        "behaviors": [record],
    }


class InteractionContinuationCompilerTests(unittest.TestCase):
    def test_emit_continuation_is_normalized_and_preserved(self) -> None:
        compiled = _validate_behavior_shard(
            behavior(
                {
                    "mode": "emit",
                    "target": "source",
                    "intent": "ASK_MEMORY_FOLLOWUP",
                    "speechAct": "ASK_FOLLOWUP",
                    "expectedResponse": "ANSWER_OR_ACK",
                }
            ),
            "test.json",
        )
        continuation = compiled["records"][0]["continuation"]
        self.assertEqual(continuation["mode"], "emit")
        self.assertEqual(continuation["target"], "source")
        self.assertEqual(continuation["intent"], "ASK_MEMORY_FOLLOWUP")
        self.assertEqual(continuation["speechAct"], "ASK_FOLLOWUP")
        self.assertEqual(continuation["expectedResponse"], "ANSWER_OR_ACK")
        self.assertTrue(continuation["inheritFactRefs"])
        self.assertTrue(continuation["inheritEventRefs"])

    def test_terminate_defaults_target_none(self) -> None:
        compiled = _validate_behavior_shard(
            behavior({"mode": "terminate"}),
            "test.json",
        )
        continuation = compiled["records"][0]["continuation"]
        self.assertEqual(continuation["mode"], "terminate")
        self.assertEqual(continuation["target"], "none")

    def test_invalid_continuation_fails_source_validation(self) -> None:
        with self.assertRaisesRegex(CompileError, "continuation.mode"):
            _validate_behavior_shard(
                behavior({"mode": "chat_forever"}),
                "test.json",
            )
        with self.assertRaisesRegex(CompileError, "continuation.target"):
            _validate_behavior_shard(
                behavior({"mode": "emit", "target": "everyone"}),
                "test.json",
            )
        with self.assertRaisesRegex(CompileError, "continuation.intent"):
            _validate_behavior_shard(
                behavior({"mode": "emit", "intent": "bad token"}),
                "test.json",
            )

    def test_missing_continuation_remains_backward_compatible(self) -> None:
        compiled = _validate_behavior_shard(
            behavior(None),
            "test.json",
        )
        self.assertNotIn("continuation", compiled["records"][0])


if __name__ == "__main__":
    unittest.main()
