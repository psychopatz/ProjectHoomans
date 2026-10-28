"""R6 acceptance: pragmatic resolution and generic one-shot behavior arbitration."""

from __future__ import annotations

import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class PragmaticInteractionR6Tests(unittest.TestCase):
    def test_thanks_uses_one_shot_behavior_without_entering_a_beat(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            result = worker.input("thanks")

        decision = result["result"]["decision"]
        director = decision["director"]
        self.assertIsNone(director.get("selectedBeat"))
        self.assertEqual(director["behaviorSource"], "one_shot")
        self.assertEqual(
            director["selectedBehavior"]["id"],
            "behavior.acknowledge_thanks",
        )
        self.assertEqual(
            decision["interactionPlan"]["behaviorMode"],
            "one_shot",
        )
        self.assertIsNone(decision["interactionPlan"].get("beatID"))
        self.assertEqual(
            decision["interactionPlan"]["behaviorAct"],
            "ACKNOWLEDGE_THANKS",
        )
        self.assertEqual(
            decision["response"]["sourcePoolID"],
            "semantic.thanks",
        )
        self.assertEqual(
            decision["response"]["plan"]["dialogueAct"],
            "ACKNOWLEDGE",
        )
        self.assertEqual(
            result["observation"]["response"]["phraseSemanticTemplateID"],
            "semantic.social.acknowledged",
        )

    def test_generic_npc_semantic_act_preview_bypasses_nlu(self) -> None:
        stimulus = {
            "type": "NPC_SEMANTIC_ACT",
            "source": {
                "kind": "npc",
                "actorID": "npc-a",
                "providerID": "synthetic.scene",
            },
            "targets": ["npc_mara"],
            "semantic": {
                "intent": "THANK",
                "speechAct": "THANK",
                "topic": "social",
                "confidence": 1.0,
            },
        }
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            before = worker.snapshot()
            result = worker.preview_interaction(stimulus)
            after = worker.snapshot()

        self.assertTrue(result["previewed"], result)
        self.assertFalse(result["mutatedConversation"])
        preview = result["preview"]
        self.assertEqual(preview["stimulus"]["type"], "NPC_SEMANTIC_ACT")
        self.assertEqual(
            preview["stimulus"]["source"]["providerID"],
            "synthetic.scene",
        )
        self.assertEqual(preview["behaviorSource"], "one_shot")
        self.assertEqual(
            preview["selectedBehavior"]["id"],
            "behavior.acknowledge_thanks",
        )
        self.assertEqual(
            preview["interactionPlan"]["sourceStimulusType"],
            "NPC_SEMANTIC_ACT",
        )
        self.assertEqual(
            preview["interactionPlan"]["sourceActorID"],
            "npc-a",
        )
        before_dialogue = (before.get("context") or {}).get("dialogue") or {}
        after_dialogue = (after.get("context") or {}).get("dialogue") or {}
        self.assertEqual(
            int(before_dialogue.get("sequence") or 0),
            int(after_dialogue.get("sequence") or 0),
        )

    def test_contextual_yes_resolves_against_pending_flow_semantics(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            worker.input("hello")
            result = worker.input("yes")

        ir = result["result"]["ir"]
        self.assertEqual(ir["intent"], "ACCEPT")
        pragmatic = result["result"]["decision"]["director"]["pragmatic"]
        self.assertEqual(pragmatic["topic"], "greeting")
        self.assertEqual(pragmatic["topicSource"], "pending_interaction")
        self.assertEqual(pragmatic["subject"], "greeting")
        self.assertEqual(pragmatic["subjectSource"], "pending_interaction")
        self.assertEqual(
            pragmatic["replyTo"]["kind"],
            "pending_interaction",
        )
        self.assertEqual(
            pragmatic["replyTo"]["flowID"],
            "greeting",
        )
        self.assertEqual(
            pragmatic["replyTo"]["nodeID"],
            "await_thanks",
        )
        self.assertTrue(pragmatic["activeFlows"])
        for row in pragmatic["recentActs"]:
            self.assertNotIn("rawText", row)

    def test_behavior_schema_is_output_agnostic_at_top_level(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.beat_catalog()
        behavior = next(
            row for row in catalog["behaviors"]
            if row["id"] == "behavior.acknowledge_thanks"
        )
        self.assertEqual(behavior["act"], "ACKNOWLEDGE_THANKS")
        self.assertEqual(behavior["mode"], "one_shot")
        self.assertEqual(
            behavior["stimuli"],
            ["HUMAN_UTTERANCE", "NPC_SEMANTIC_ACT"],
        )
        self.assertEqual(behavior["requiredCapabilities"], ["speech"])
        self.assertIn("speech", behavior["outputs"])
        self.assertNotIn("dialogueAct", behavior)
        self.assertNotIn("contentTemplateID", behavior)


if __name__ == "__main__":
    unittest.main()
