from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


def scene_fixture() -> dict:
    return {
        "eventID": "scene:worker:excursion",
        "stimulusType": "TASK_EVENT",
        "intent": "EXCURSION_PREPARING",
        "speechAct": "INFORM",
        "subject": "COMMUNITY_EXCURSION",
        "topic": "EXCURSION",
        "autoContinue": False,
        "participants": [
            {
                "id": "npc-scene-a",
                "confidence": 0.55,
                "sociability": 0.5,
            },
            {
                "id": "npc-scene-b",
                "confidence": 0.45,
                "sociability": 0.7,
            },
        ],
        "historyLimit": 4,
        "sceneLimit": 4,
    }


def assert_no_transcript_fields(test: unittest.TestCase, value: object) -> None:
    forbidden = {
        "rawText",
        "resolvedText",
        "fallback",
        "utterance",
        "transcript",
        "messages",
    }
    if isinstance(value, dict):
        for key, item in value.items():
            test.assertNotIn(key, forbidden)
            assert_no_transcript_fields(test, item)
    elif isinstance(value, list):
        for item in value:
            assert_no_transcript_fields(test, item)


class SemanticSceneObservatoryTests(unittest.TestCase):
    def test_worker_reads_production_scene_observatory(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            first = worker.scene_observatory_fixture(scene_fixture())
            scene_id = first["scenes"][0]["id"]
            again = worker.scene_observatory_inspect(
                scene_id=scene_id,
                scene_limit=4,
                history_limit=4,
            )

        self.assertTrue(first["ok"])
        self.assertEqual(first["workerKind"], "production_lua")
        self.assertEqual(
            first["schema"],
            "semantic.interaction.scene.observatory.v1",
        )
        self.assertTrue(first["readOnly"])
        self.assertFalse(first["transcriptStored"])
        self.assertEqual(first["sceneCount"], 1)
        scene = first["scenes"][0]
        self.assertEqual(scene["participantCount"], 2)
        self.assertEqual(scene["topic"], "EXCURSION")
        self.assertEqual(
            scene["currentTurn"]["behaviorID"],
            "behavior.scene_excursion_preparing",
        )
        self.assertEqual(scene["currentTurn"]["speakerID"], "npc-scene-a")
        self.assertEqual(scene["currentTurn"]["recipientID"], "npc-scene-b")
        self.assertEqual(scene["continuation"]["mode"], "emit")
        self.assertEqual(scene["continuation"]["targetID"], "npc-scene-b")
        self.assertEqual(
            first["opportunity"]["lastAdmission"]["providerID"],
            "semantic_harness.scene_observatory",
        )
        self.assertGreaterEqual(
            first["runtime"]["scheduler"]["metrics"]["directorEvaluations"],
            1,
        )
        self.assertGreaterEqual(
            first["opportunity"]["metrics"]["providerEvaluations"],
            1,
        )
        self.assertEqual(
            first["explanation"]["playerChoices"],
            "observer_or_non_player_recipient",
        )
        self.assertLessEqual(len(scene["semanticHistory"]), 4)
        self.assertLessEqual(len(first["scenes"]), 4)
        assert_no_transcript_fields(self, first)

        # Repeated inspection is read-only over the same production state.
        self.assertEqual(first["scenes"], again["scenes"])
        self.assertEqual(first["runtime"], again["runtime"])
        self.assertEqual(first["opportunity"], again["opportunity"])

    def test_worker_api_enforces_scene_observatory_bounds(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.scene_observatory_fixture(scene_fixture())
            with self.assertRaisesRegex(ValueError, "scene limit must be 1 to 8"):
                worker.scene_observatory_inspect(scene_limit=0)
            with self.assertRaisesRegex(ValueError, "scene limit must be 1 to 8"):
                worker.scene_observatory_inspect(scene_limit=9)
            with self.assertRaisesRegex(ValueError, "history limit must be 1 to 8"):
                worker.scene_observatory_inspect(history_limit=0)
            with self.assertRaisesRegex(ValueError, "history limit must be 1 to 8"):
                worker.scene_observatory_inspect(history_limit=9)


if __name__ == "__main__":
    unittest.main()
