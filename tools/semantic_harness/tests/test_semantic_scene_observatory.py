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




def tactical_scene_fixture() -> dict:
    fixture = scene_fixture()
    fixture.update(
        {
            "eventID": "scene:worker:horde",
            "stimulusType": "DANGER_CHANGED",
            "intent": "COMBAT_HORDE_ALERT",
            "speechAct": "WARN",
            "subject": "ZOMBIE_HORDE",
            "topic": "COMBAT",
            "dangerKind": "zombie_horde",
            "pressureBand": "horde",
            "nearbyCount": 8,
            "tacticalSpatial": {
                "targetKind": "zombie_group",
                "targetRef": "horde:worker",
                "targetPositionSource": "combat_centroid",
                "headingSource": "live_body",
                "clockToken": "CLOCK_08",
                "relativeSector8": "REAR_LEFT",
                "distanceBand": "NEAR",
                "freshnessMs": 0,
                "presentationMode": "clock",
                "presentationReason": "tactical_role:guard",
            },
        }
    )
    return fixture


def coarse_scene_fixture() -> dict:
    fixture = tactical_scene_fixture()
    fixture["eventID"] = "scene:worker:horde:coarse"
    fixture["tacticalSpatial"]["presentationMode"] = "coarse"
    fixture["tacticalSpatial"]["presentationReason"] = "civilian_fallback"
    return fixture


def omitted_scene_fixture() -> dict:
    fixture = tactical_scene_fixture()
    fixture["eventID"] = "scene:worker:horde:omitted"
    fixture["tacticalSpatial"].pop("clockToken", None)
    fixture["tacticalSpatial"].pop("headingSource", None)
    fixture["tacticalSpatial"]["presentationMode"] = "omitted"
    fixture["tacticalSpatial"]["presentationReason"] = "heading_unavailable"
    return fixture


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


    def test_worker_exposes_bounded_tactical_spatial_without_transcript(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            view = worker.scene_observatory_fixture(tactical_scene_fixture())

        self.assertTrue(view["ok"])
        self.assertEqual(view["sceneCount"], 1)
        spatial = view["scenes"][0]["tacticalSpatial"]
        self.assertTrue(spatial["available"])
        self.assertEqual(spatial["clockToken"], "CLOCK_08")
        self.assertEqual(spatial["relativeSector8"], "REAR_LEFT")
        self.assertEqual(spatial["headingSource"], "live_body")
        self.assertEqual(spatial["presentationMode"], "clock")
        self.assertEqual(
            spatial["presentationReason"], "tactical_role:guard"
        )
        self.assertIsNone(spatial.get("suppressionReason"))
        assert_no_transcript_fields(self, view)


    def test_worker_explains_coarse_and_omitted_tactical_modes(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            coarse = worker.scene_observatory_fixture(coarse_scene_fixture())
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            omitted = worker.scene_observatory_fixture(omitted_scene_fixture())

        coarse_spatial = coarse["scenes"][0]["tacticalSpatial"]
        self.assertEqual(coarse_spatial["presentationMode"], "coarse")
        self.assertEqual(
            coarse_spatial["presentationReason"], "civilian_fallback"
        )
        self.assertIsNone(coarse_spatial.get("suppressionReason"))

        omitted_spatial = omitted["scenes"][0]["tacticalSpatial"]
        self.assertEqual(omitted_spatial["presentationMode"], "omitted")
        self.assertEqual(
            omitted_spatial["suppressionReason"], "heading_unavailable"
        )
        self.assertIsNone(omitted_spatial.get("clockToken"))
        assert_no_transcript_fields(self, coarse)
        assert_no_transcript_fields(self, omitted)

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
