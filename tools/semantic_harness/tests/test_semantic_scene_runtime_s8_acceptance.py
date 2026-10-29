from __future__ import annotations

from copy import deepcopy
from pathlib import Path
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


PROMPT = {
    "id": "behavior.s8_worker.synthetic_prompt",
    "owner": "S8WorkerFutureDomain",
    "act": "S8_WORKER_PROMPT",
    "mode": "one_shot",
    "stimuli": ["TASK_EVENT"],
    "requiredCapabilities": ["speech"],
    "outputs": {
        "speech": {
            "dialogueAct": "INFORM",
            "contentTemplateID": "semantic.social.acknowledged",
        }
    },
    "continuation": {
        "mode": "emit",
        "target": "other",
        "intent": "S8_WORKER_ACK",
        "speechAct": "ACKNOWLEDGE",
    },
    "when": {
        "path": "stimulus.semantic.intent",
        "op": "eq",
        "value": "S8_WORKER_SIGNAL",
    },
    "baseRelevance": 1,
    "modifiers": [],
}

ACK = {
    "id": "behavior.s8_worker.synthetic_ack",
    "owner": "S8WorkerFutureDomain",
    "act": "S8_WORKER_ACK",
    "mode": "one_shot",
    "stimuli": ["NPC_SEMANTIC_ACT"],
    "requiredCapabilities": ["speech"],
    "outputs": {
        "speech": {
            "dialogueAct": "ACKNOWLEDGE",
            "contentTemplateID": "semantic.social.acknowledged",
        }
    },
    "when": {
        "path": "stimulus.semantic.intent",
        "op": "eq",
        "value": "S8_WORKER_ACK",
    },
    "baseRelevance": 1,
    "modifiers": [],
}


class SemanticSceneRuntimeS8Acceptance(unittest.TestCase):
    def test_future_domain_registers_without_generic_algorithm_changes(self) -> None:
        fixture = {
            "eventID": "s8:worker:future-domain",
            "stimulusType": "TASK_EVENT",
            "intent": "S8_WORKER_SIGNAL",
            "speechAct": "INFORM",
            "subject": "S8_WORKER_FUTURE_SUBJECT",
            "topic": "S8_WORKER_FUTURE_DOMAIN",
            "autoContinue": True,
            "maxContinuationSteps": 2,
            "participants": [
                {"id": "npc-s8-worker-a", "confidence": 0.5},
                {"id": "npc-s8-worker-b", "confidence": 0.5},
            ],
            "historyLimit": 8,
            "sceneLimit": 4,
        }

        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            registered_prompt = worker.register_behavior(deepcopy(PROMPT))
            registered_ack = worker.register_behavior(deepcopy(ACK))
            view = worker.scene_observatory_fixture(fixture)

        self.assertTrue(registered_prompt["registered"])
        self.assertTrue(registered_ack["registered"])
        self.assertTrue(view["ok"])
        self.assertEqual(view["workerKind"], "production_lua")
        self.assertEqual(view["sceneCount"], 1)
        scene = view["scenes"][0]
        self.assertEqual(len(scene["semanticHistory"]), 2)
        self.assertEqual(
            scene["semanticHistory"][0]["behaviorID"],
            "behavior.s8_worker.synthetic_prompt",
        )
        self.assertEqual(
            scene["semanticHistory"][1]["behaviorID"],
            "behavior.s8_worker.synthetic_ack",
        )
        self.assertEqual(
            scene["semanticHistory"][1]["stimulusSourceID"],
            "npc-s8-worker-a",
        )
        self.assertEqual(
            scene["semanticHistory"][1]["responderID"],
            "npc-s8-worker-b",
        )
        self.assertEqual(scene["continuation"]["mode"], "none")

        root = Path(__file__).resolve().parents[3]
        core_files = [
            root
            / "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/"
            "Semantics/PNC_SemanticInteractionSceneRuntime.lua",
            root
            / "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/"
            "Semantics/PNC_SemanticInteractionDirector.lua",
            root
            / "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/"
            "Semantics/PNC_SemanticInteractionScheduler.lua",
            root
            / "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/"
            "Semantics/PNC_SemanticInteractionContinuation.lua",
        ]
        for path in core_files:
            source = path.read_text(encoding="utf-8")
            self.assertNotIn("S8_WORKER_SIGNAL", source, path.name)
            self.assertNotIn("behavior.s8_worker", source, path.name)

    def test_worker_observatory_limits_remain_bounded(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            with self.assertRaisesRegex(ValueError, "scene limit must be 1 to 8"):
                worker.scene_observatory_inspect(scene_limit=16)
            with self.assertRaisesRegex(ValueError, "history limit must be 1 to 8"):
                worker.scene_observatory_inspect(history_limit=16)


if __name__ == "__main__":
    unittest.main()
