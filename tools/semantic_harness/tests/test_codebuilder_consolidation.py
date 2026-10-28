"""Current CodeBuilder/Dataset Library consolidation contracts."""

from __future__ import annotations

from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import unittest
from unittest.mock import patch

from tools.semantic_harness import app
from tools.semantic_harness.cli import _parser, cli
from tools.semantic_harness.codebuilder.dialogue_contract import (
    validate_branch_offers,
)
from tools.semantic_harness.codebuilder.lexicon_compiler import CompileError
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService


REPOSITORY = Path(__file__).resolve().parents[3]


class CodeBuilderConsolidationTests(unittest.TestCase):
    def test_branch_offer_contract_is_typed_bounded_and_player_safe(self) -> None:
        offer = {
            "id": "lab.branch.offer",
            "labelKey": "UI_Lab_Branch_Label",
            "labelFallback": "Choose this",
            "utteranceKey": "UI_Lab_Branch_Utterance",
            "utteranceFallback": "Choose this.",
            "frame": {"intent": "THANK", "speechAct": "THANK"},
            "constraints": {
                "all": [
                    {"path": "ir.intent", "op": "eq", "value": "GREET"},
                    {
                        "any": [
                            {
                                "path": "npcState.activeBehavior",
                                "op": "eq",
                                "value": "idle",
                            },
                            {
                                "not": {
                                    "path": "npcState.healthState",
                                    "op": "eq",
                                    "value": "dead",
                                }
                            },
                        ],
                    },
                ],
            },
        }
        normalized = validate_branch_offers([offer], "lab.offers")
        self.assertEqual(normalized[0]["id"], "lab.branch.offer")
        self.assertEqual(normalized[0]["frame"]["intent"], "THANK")
        with self.assertRaises(CompileError):
            validate_branch_offers(
                [{**offer, "visibility": "private"}],
                "lab.private",
            )
        with self.assertRaises(CompileError):
            validate_branch_offers(
                [{**offer, "constraints": {"mystery": True}}],
                "lab.unknown",
            )

    def test_authoring_service_uses_manifest_backed_datasets(self) -> None:
        service = SemanticLabAuthoringService(
            repository=REPOSITORY,
            runtime_root=REPOSITORY,
        )
        self.assertEqual(service.repository, REPOSITORY.resolve())
        report = service.preview_dataset_generation("semantic_flows")
        self.assertTrue(report["ok"], report)
        self.assertTrue(report["previewOnly"])
        self.assertEqual(report["writes"], [])
        self.assertTrue(report["generatedPaths"])
        self.assertTrue(
            all("Generated/Dialogue/" not in path for path in report["generatedPaths"])
        )
        self.assertTrue(
            all(
                "Generated/SemanticAuthoring/" not in path
                for path in report["generatedPaths"]
            )
        )

    def test_dataset_library_catalog_search_and_validation_use_canonical_sources(self) -> None:
        service = SemanticLabAuthoringService(
            repository=REPOSITORY,
            runtime_root=REPOSITORY,
        )
        sources = service.list_dataset_sources()
        self.assertEqual(
            [source["id"] for source in sources],
            [
                "semantic_flows",
                "common_dialogue",
                "grounded_personal",
                "wordnet_concepts",
            ],
        )
        self.assertTrue(
            all(source["exists"] and source["editable"] for source in sources)
        )

        matches = service.search_dataset("follow", limit=8)
        self.assertTrue(matches)
        self.assertTrue(
            any(row["sourceID"] == "semantic_flows" for row in matches)
        )
        self.assertTrue(
            any(row["sourceID"] == "wordnet_concepts" for row in matches)
        )

        for source in sources:
            report = service.preview_dataset_edit(
                source["id"],
                service.load_dataset_document(source["id"]),
            )
            self.assertTrue(report["ok"], source["id"])
            self.assertTrue(report["previewOnly"])
            self.assertTrue(report["effectFree"])
            self.assertEqual(report["writes"], [])

    def test_headless_cli_routes_dataset_library_operation(self) -> None:
        arguments = _parser().parse_args(["--list-datasets", "--jsonl"])
        output = io.StringIO()
        with redirect_stdout(output):
            self.assertEqual(cli(arguments), 0)
        record = json.loads(output.getvalue())
        self.assertEqual(record["type"], "dataset_library")
        self.assertEqual(
            [source["id"] for source in record["sources"]][:3],
            ["semantic_flows", "common_dialogue", "grounded_personal"],
        )

    def test_headless_cli_routes_block_registry_operation(self) -> None:
        arguments = _parser().parse_args(["--list-blocks", "--jsonl"])
        output = io.StringIO()
        with redirect_stdout(output):
            self.assertEqual(cli(arguments), 0)
        record = json.loads(output.getvalue())
        self.assertEqual(record["type"], "semantic_block_registry")
        self.assertTrue(record["blocks"])

    def test_workflow_service_previews_conversation_generation(self) -> None:
        service = SemanticLabAuthoringService(
            repository=REPOSITORY,
            runtime_root=REPOSITORY,
        )
        report = service.preview_workflow(
            "common_dialogue",
            ["language.speech_act", "dialogue_responses.response_pool"],
        )
        self.assertTrue(report["ok"], report)
        self.assertTrue(report["previewOnly"])
        self.assertTrue(report["effectFree"])
        self.assertEqual(report["writes"], [])
        self.assertEqual(report["workflow"]["datasetID"], "common_dialogue")
        self.assertTrue(report["sourcePreview"]["generatedPaths"])
        self.assertTrue(
            any(
                "Generated/Conversation/" in path
                for path in report["sourcePreview"]["generatedPaths"]
            )
        )

    def test_workflow_generation_requires_explicit_approval(self) -> None:
        service = SemanticLabAuthoringService(
            repository=REPOSITORY,
            runtime_root=REPOSITORY,
        )
        report = service.generate_workflow(
            "common_dialogue",
            ["language.speech_act"],
            approved=False,
        )
        self.assertFalse(report["ok"])
        self.assertFalse(report["generationApproved"])
        self.assertTrue(report["previewOnly"])
        self.assertEqual(report["writes"], [])

    def test_headless_cli_routes_workflow_preview_through_semantic_lab(self) -> None:
        arguments = _parser().parse_args([
            "--workflow-preview",
            "common_dialogue",
            "--workflow-blocks",
            "language.speech_act",
            "--jsonl",
        ])
        output = io.StringIO()
        with redirect_stdout(output):
            self.assertEqual(cli(arguments), 0)
        report = json.loads(output.getvalue())
        self.assertTrue(report["ok"])
        self.assertEqual(report["workflow"]["datasetID"], "common_dialogue")

    def test_app_selects_headless_mode_for_authoring_operation(self) -> None:
        with patch.object(app, "install_shutdown_handler"), patch.object(
            app,
            "cli",
            return_value=0,
        ) as run_cli:
            self.assertEqual(app.main(["--list-datasets"]), 0)
        run_cli.assert_called_once()


if __name__ == "__main__":
    unittest.main()
