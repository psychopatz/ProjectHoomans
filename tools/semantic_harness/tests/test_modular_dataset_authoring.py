"""Current modular Conversation dataset authoring contracts."""

from __future__ import annotations

from pathlib import Path
import unittest

from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[3]


class ModularDatasetAuthoringTests(unittest.TestCase):
    def setUp(self) -> None:
        self.service = SemanticLabAuthoringService(
            repository=REPOSITORY,
            runtime_root=REPOSITORY,
        )

    def test_catalog_exposes_only_real_modular_sources(self) -> None:
        sources = self.service.list_dataset_sources()
        self.assertEqual(
            [source["id"] for source in sources],
            [
                "semantic_flows",
                "common_dialogue",
                "grounded_personal",
                "wordnet_concepts",
            ],
        )
        for source in sources:
            self.assertTrue(source["exists"], source)
            self.assertTrue(source["editable"], source)
            for path in source["paths"]:
                self.assertNotIn("semantic_dialogue_content.json", path)
                self.assertNotIn("common_interactions.json", path)
                self.assertNotIn("grounded_personal_dialogue.json", path)
                self.assertNotIn("semantic_definitions.json", path)

    def test_logical_dialogue_domains_preserve_expected_records(self) -> None:
        common = self.service.load_dataset_document("common_dialogue")
        self.assertEqual(len(common["patterns"]), 47)
        self.assertEqual(len(common["responsePools"]), 13)
        self.assertEqual(
            sum(len(pool["variants"]) for pool in common["responsePools"]),
            31,
        )

        personal = self.service.load_dataset_document("grounded_personal")
        self.assertEqual(len(personal["patterns"]), 7)
        self.assertEqual(len(personal["responsePools"]), 13)
        self.assertEqual(
            sum(len(pool["variants"]) for pool in personal["responsePools"]),
            13,
        )

        semantic = self.service.load_dataset_document("semantic_flows")
        self.assertEqual(len(semantic["definitions"]), 2)

    def test_generation_preview_uses_only_conversation_outputs(self) -> None:
        for source_id in (
            "semantic_flows",
            "common_dialogue",
            "grounded_personal",
        ):
            with self.subTest(source_id=source_id):
                report = self.service.preview_dataset_generation(source_id)
                self.assertTrue(report["ok"], report)
                self.assertTrue(report["previewOnly"])
                self.assertTrue(report["effectFree"])
                self.assertEqual(report["writes"], [])
                paths = report["generatedPaths"]
                self.assertTrue(paths)
                self.assertTrue(
                    any("Generated/Conversation/" in path for path in paths)
                )
                forbidden = (
                    "Generated/Dialogue/",
                    "Generated/SemanticAuthoring/",
                    "Generated/DialogueContent/",
                    "CommonInteractions.json",
                    "GroundedPersonalDialogue.json",
                )
                self.assertFalse(
                    any(token in path for path in paths for token in forbidden)
                )
                self.assertTrue(
                    all(
                        row["status"] == "unchanged"
                        for row in report["generatedArtifactDiffs"]
                    )
                )

    def test_real_worker_still_uses_grounded_and_authored_flow_records(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            backstory = worker.input("what did you do before all this")
            follow = worker.input("follow me")
        self.assertTrue(backstory["accepted"])
        self.assertTrue(follow["accepted"])


if __name__ == "__main__":
    unittest.main()
