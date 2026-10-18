"""C5-B dataset review and fresh production-worker restart acceptance."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.authoring import preview_dialogue_source
from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[3]
DATASET = REPOSITORY / "tools/semantic_compiler/common_interactions.json"


class DatasetReviewTests(unittest.TestCase):
    def test_existing_code_builder_preview_reports_approved_provenance_and_paths(self) -> None:
        first = preview_dialogue_source(DATASET)
        second = preview_dialogue_source(DATASET)

        self.assertTrue(first["ok"])
        self.assertTrue(first["previewOnly"])
        self.assertTrue(first["effectFree"])
        self.assertEqual(first["writes"], [])
        self.assertEqual(first["patternCount"], 31)
        self.assertEqual(first["responseVariantCount"], 31)
        self.assertEqual(
            first["candidateReview"]["summary"],
            {"approved": 8, "rejected": 0, "not_candidate": 54},
        )
        self.assertEqual(
            first["candidateReview"]["provenance"]["approvedWithProvenance"],
            8,
        )
        self.assertEqual(first["candidateReview"]["collisions"], [])
        self.assertIn(
            "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/PNC_SemanticGeneratedDialogue.lua",
            first["generatedPaths"],
        )
        self.assertIn(
            "Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/Semantic/GeneratedDialogue.json",
            first["generatedPaths"],
        )
        self.assertIn(
            "Contents/mods/ProjectHoomans/common/media/translation/manifests/Conversation.json",
            first["generatedPaths"],
        )
        self.assertEqual(first["artifacts"], second["artifacts"])

    def test_code_builder_reports_collision_and_rejects_the_affected_candidate(self) -> None:
        document = json.loads(DATASET.read_text(encoding="utf-8"))
        document["patterns"][1]["utterance"] = document["patterns"][0]["utterance"]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "collision.json"
            path.write_text(json.dumps(document), encoding="utf-8")
            report = preview_dialogue_source(path)

        self.assertFalse(report["ok"])
        self.assertTrue(report["previewOnly"])
        self.assertEqual(report["writes"], [])
        self.assertTrue(
            any(collision["kind"] == "positive_duplicate"
                for collision in report["candidateReview"]["collisions"])
        )
        affected = {
            candidate["id"]: candidate
            for candidate in report["candidateReview"]["candidates"]
            if candidate["id"] in {
                document["patterns"][0]["id"],
                document["patterns"][1]["id"],
            }
        }
        self.assertEqual({row["status"] for row in affected.values()}, {"rejected"})
        self.assertTrue(all(row["reason"].startswith("collision:") for row in affected.values()))
        self.assertIn("mapped by both", report["diagnostics"][0]["message"])

    def test_code_builder_rejects_reviewed_candidate_without_provenance(self) -> None:
        document = json.loads(DATASET.read_text(encoding="utf-8"))
        document["patterns"][0]["sourceRefs"] = []
        document["patterns"][0]["mapping"]["sourceRefs"] = []
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "unprovenanced.json"
            path.write_text(json.dumps(document), encoding="utf-8")
            report = preview_dialogue_source(path)

        candidate = next(
            row for row in report["candidateReview"]["candidates"]
            if row["id"] == document["patterns"][0]["id"]
        )
        self.assertFalse(report["ok"])
        self.assertEqual(candidate["status"], "rejected")
        self.assertEqual(candidate["reason"], "missing_provenance")
        self.assertIn("requires 1 to 4 source references", report["diagnostics"][0]["message"])

    def test_reviewed_catalog_survives_actual_lua_worker_restart(self) -> None:
        report = preview_dialogue_source(DATASET)
        self.assertTrue(report["ok"])
        scenario = merge(
            DEFAULT_SCENARIO,
            {
                "npc": {
                    "healthState": "injured",
                    "needs": {"hunger": 0.9},
                    "conditionStats": {},
                },
                "world": {"weather": "rain"},
            },
        )

        with LuaSemanticWorker(scenario) as worker:
            worker.input("Do you need anything?")
            worker.input("How many?")
            worker.input("I'll get some")
            before = worker.preview("Can we talk about the weather")
            restart = worker.restart()
            after = worker.input("Can we talk about the weather")

        self.assertTrue(restart.get("accepted", True))
        for turn in (before, after):
            self.assertEqual(
                turn["result"]["ir"]["provenance"]["pattern"],
                "pnc.dataset.question.weather.can_we_talk_about_the_weather",
            )
            self.assertEqual(turn["result"]["decision"]["response"]["plan"]["dialogueAct"], "WEATHER_REPORT")
        self.assertTrue(after["messages"][0]["payload"]["text"])
        self.assertEqual(after["transport"], [])
        self.assertEqual(after["toolCalls"], [])
        self.assertTrue(after["observation"]["sideEffects"]["none"])


if __name__ == "__main__":
    unittest.main()
