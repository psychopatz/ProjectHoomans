"""C5-B dataset review and fresh production-worker restart acceptance."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.authoring import (
    generate_dialogue_source,
    preview_dialogue_source,
)
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[3]
DATASET = REPOSITORY / (
    "tools/semantic_harness/codebuilder/sources/common_interactions.json"
)


class DatasetReviewTests(unittest.TestCase):
    def test_existing_code_builder_preview_reports_approved_provenance_and_paths(self) -> None:
        first = preview_dialogue_source(DATASET)
        second = preview_dialogue_source(DATASET)

        self.assertTrue(first["ok"])
        self.assertTrue(first["previewOnly"])
        self.assertTrue(first["effectFree"])
        self.assertEqual(first["writes"], [])
        self.assertEqual(first["patternCount"], 47)
        self.assertEqual(first["responseVariantCount"], 31)
        self.assertEqual(
            first["candidateReview"]["summary"],
            {"approved": 20, "rejected": 0, "not_candidate": 44},
        )
        self.assertEqual(
            first["candidateReview"]["provenance"]["approvedWithProvenance"],
            20,
        )
        self.assertEqual(
            first["sourceMetadata"]["integrationStatus"],
            {
                "imported": 2,
                "mapped": 2,
                "approved": 2,
                "compiled": 2,
                "workerVerified": 2,
            },
        )
        references = {
            reference["name"]: reference
            for reference in first["sourceMetadata"]["references"]
        }
        self.assertEqual(
            references["MASSIVE"]["recordRefs"][0]["recordID"],
            "98",
        )
        self.assertEqual(
            references["SGD"]["recordRefs"][0]["dialogueID"],
            "90_00031",
        )
        self.assertEqual(first["candidateReview"]["collisions"], [])
        self.assertTrue(all(row["status"] == "unchanged" for row in first["artifactDiffs"]))
        self.assertEqual(
            [row["status"] for row in first["artifacts"]],
            [row["status"] for row in first["artifactDiffs"]],
        )
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

    def test_artifact_diff_view_is_bounded_and_does_not_write(self) -> None:
        entry = (
            Path("Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics")
            / "PNC_SemanticGeneratedDialogue.lua"
        )
        with tempfile.TemporaryDirectory() as directory:
            repository = Path(directory)
            target = repository / entry
            target.parent.mkdir(parents=True)
            target.write_text("return { stale = true }\n", encoding="utf-8")
            report = preview_dialogue_source(DATASET, repository=repository)

        changed = next(row for row in report["artifactDiffs"] if row["path"] == str(entry))
        self.assertTrue(report["ok"])
        self.assertEqual(changed["status"], "changed")
        self.assertIn("preview/", changed["diff"])
        self.assertLessEqual(len(changed["diff"]), 12_000)
        self.assertFalse(report["writes"])

    def test_explicit_generation_uses_existing_writer_and_is_byte_stable(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            repository = Path(directory)
            first = generate_dialogue_source(DATASET, repository=repository)
            first_hashes = {
                path: Path(path).read_bytes()
                for path in first["writes"]
            }
            second = generate_dialogue_source(DATASET, repository=repository)
            second_hashes = {
                path: Path(path).read_bytes()
                for path in second["writes"]
            }

        self.assertTrue(first["ok"])
        self.assertTrue(first["generationApproved"])
        self.assertEqual(len(first["writes"]), 10)
        self.assertEqual(first_hashes, second_hashes)
        self.assertTrue(all(row["status"] == "unchanged" for row in second["artifactDiffs"]))
        self.assertEqual(second["reloadedBy"], "caller_restart_required")

    def test_generation_refuses_an_explicitly_rejected_candidate(self) -> None:
        document = json.loads(DATASET.read_text(encoding="utf-8"))
        document["responsePools"][0]["variants"][0]["reviewed"] = False
        with tempfile.TemporaryDirectory() as directory:
            source_path = Path(directory) / "rejected.json"
            output_root = Path(directory) / "output"
            source_path.write_text(json.dumps(document), encoding="utf-8")
            report = generate_dialogue_source(source_path, repository=output_root)

        self.assertFalse(report["ok"])
        self.assertFalse(report["generationApproved"])
        self.assertEqual(report["writes"], [])
        self.assertIn("rejected dataset candidates", report["diagnostics"][0]["message"])

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

            dataset_turns = [
                worker.input("is it currently snowing"),
                worker.input("How is the weather on 9th of March?"),
            ]

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

        self.assertEqual(
            dataset_turns[0]["result"]["ir"]["provenance"]["pattern"],
            "pnc.dataset.massive.weather.is_it_currently_snowing",
        )
        self.assertEqual(
            dataset_turns[1]["result"]["ir"]["provenance"]["pattern"],
            "pnc.dataset.sgd.weather.how_is_the_weather_on_9th_of_march",
        )
        for turn in dataset_turns:
            self.assertEqual(
                turn["result"]["decision"]["response"]["plan"]["dialogueAct"],
                "QUESTION_RECEIVED",
            )
            self.assertTrue(turn["messages"][0]["payload"]["text"])
            self.assertEqual(turn["transport"], [])
            self.assertTrue(turn["observation"]["sideEffects"]["none"])


if __name__ == "__main__":
    unittest.main()
