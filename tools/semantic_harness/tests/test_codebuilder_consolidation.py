"""S0A/S1 proof for the unified CodeBuilder and Dataset Library boundaries."""

from __future__ import annotations

from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from tools.semantic_compiler.compiler import (
    compile_dialogue_dataset as legacy_compile_dialogue,
    compile_semantic_definitions as legacy_compile_semantic,
    load_dialogue_dataset as legacy_load_dialogue,
    load_semantic_source as legacy_load_semantic,
)
from tools.semantic_compiler.build import (
    write_dialogue_output as legacy_write_dialogue,
    write_semantic_output as legacy_write_semantic,
)
from tools.semantic_harness import app
from tools.semantic_harness.cli import _parser, cli
from tools.semantic_harness.codebuilder.compiler import (
    compile_dialogue_dataset,
    compile_semantic_definitions,
    load_dialogue_dataset,
    load_semantic_source,
)
from tools.semantic_harness.codebuilder.build import (
    write_dialogue_output,
    write_semantic_output,
)
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService


REPOSITORY = Path(__file__).resolve().parents[3]
DIALOGUE_SOURCE = REPOSITORY / "tools/semantic_compiler/common_interactions.json"
SEMANTIC_SOURCE = REPOSITORY / "tools/semantic_compiler/semantic_definitions.json"
DIALOGUE_OUTPUT = Path(
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/"
    "PNC_SemanticGeneratedDialogue.lua"
)
SEMANTIC_MANIFEST = Path(
    "Contents/mods/ProjectHoomans/common/media/translation/manifests/Conversation.json"
)


def _files(root: Path, paths: list[Path]) -> dict[Path, bytes]:
    return {
        path.relative_to(root): path.read_bytes()
        for path in paths
    }


def _seed_translation_manifest(root: Path) -> None:
    target = root / SEMANTIC_MANIFEST
    target.parent.mkdir(parents=True, exist_ok=True)
    source = REPOSITORY / SEMANTIC_MANIFEST
    target.write_bytes(source.read_bytes())


class CodeBuilderConsolidationTests(unittest.TestCase):
    def test_legacy_modules_are_thin_identity_wrappers(self) -> None:
        self.assertIs(legacy_compile_dialogue, compile_dialogue_dataset)
        self.assertIs(legacy_compile_semantic, compile_semantic_definitions)
        self.assertIs(legacy_load_dialogue, load_dialogue_dataset)
        self.assertIs(legacy_load_semantic, load_semantic_source)
        self.assertIs(legacy_write_dialogue, write_dialogue_output)
        self.assertIs(legacy_write_semantic, write_semantic_output)

    def test_dialogue_writer_matches_checked_in_artifacts(self) -> None:
        source = load_dialogue_dataset(DIALOGUE_SOURCE)
        compiled = compile_dialogue_dataset(source)
        snapshots: list[dict[Path, bytes]] = []
        with tempfile.TemporaryDirectory() as first_dir, tempfile.TemporaryDirectory() as second_dir:
            for directory, writer in (
                (Path(first_dir), write_dialogue_output),
                (Path(second_dir), legacy_write_dialogue),
            ):
                _seed_translation_manifest(directory)
                output = directory / DIALOGUE_OUTPUT
                output.parent.mkdir(parents=True, exist_ok=True)
                written = writer(output, compiled)
                snapshots.append(_files(directory, written))
        self.assertEqual(snapshots[0], snapshots[1])
        for relative, content in snapshots[0].items():
            expected = REPOSITORY / relative
            if relative.name.endswith("Generated.json"):
                # These two files are shared translation catalogs and contain
                # other approved generation families in the checked-in tree.
                self.assertTrue(content, relative)
                continue
            self.assertTrue(expected.is_file(), relative)
            self.assertEqual(content, expected.read_bytes(), relative)

    def test_semantic_writer_matches_legacy_entrypoint_and_artifacts(self) -> None:
        source = load_semantic_source(SEMANTIC_SOURCE)
        compiled = compile_semantic_definitions(source)
        snapshots: list[dict[Path, bytes]] = []
        with tempfile.TemporaryDirectory() as first_dir, tempfile.TemporaryDirectory() as second_dir:
            for directory, writer in (
                (Path(first_dir), write_semantic_output),
                (Path(second_dir), legacy_write_semantic),
            ):
                _seed_translation_manifest(directory)
                written = writer(directory, compiled)
                snapshots.append(_files(directory, written))
        self.assertEqual(snapshots[0], snapshots[1])
        for relative, content in snapshots[0].items():
            expected = REPOSITORY / relative
            if relative.name.endswith("Generated.json"):
                # The checked-in translation files are shared with the larger
                # generated dialogue catalog; wrapper parity is the exact
                # comparison for this source-scoped build.
                self.assertTrue(content, relative)
                continue
            self.assertTrue(expected.is_file(), relative)
            self.assertEqual(content, expected.read_bytes(), relative)

    def test_headless_cli_routes_source_preview_through_authoring_service(self) -> None:
        arguments = _parser().parse_args([
            "--compile-source", str(SEMANTIC_SOURCE), "--jsonl",
        ])
        output = io.StringIO()
        report = {"ok": True, "type": "semantic_compile_preview", "writes": []}
        with patch.object(
            SemanticLabAuthoringService,
            "preview_semantic_source",
            return_value=report,
        ) as preview:
            with redirect_stdout(output):
                self.assertEqual(cli(arguments), 0)
        preview.assert_called_once()
        self.assertEqual(json.loads(output.getvalue()), report)

    def test_authoring_service_binds_repository_for_direct_callers(self) -> None:
        service = SemanticLabAuthoringService(repository=REPOSITORY)
        self.assertEqual(service.repository, REPOSITORY.resolve())
        report = service.preview_semantic_source(SEMANTIC_SOURCE)
        self.assertTrue(report["ok"])
        self.assertTrue(report["previewOnly"])
        self.assertEqual(report["writes"], [])

    def test_dataset_library_catalog_search_and_validation_use_canonical_sources(self) -> None:
        service = SemanticLabAuthoringService(repository=REPOSITORY)
        sources = service.list_dataset_sources()
        self.assertEqual(
            [source["id"] for source in sources],
            [
                "semantic_definitions",
                "common_interactions",
                "grounded_personal_dialogue",
                "wordnet_concepts",
            ],
        )
        self.assertTrue(all(source["exists"] and source["editable"] for source in sources))

        matches = service.search_dataset("follow", limit=8)
        self.assertTrue(matches)
        self.assertTrue(any(row["sourceID"] == "semantic_definitions" for row in matches))
        self.assertTrue(any(row["sourceID"] == "wordnet_concepts" for row in matches))

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
        report = {"ok": True, "type": "dataset_library", "sources": []}
        with patch.object(
            SemanticLabAuthoringService,
            "list_dataset_sources",
            return_value=[],
        ) as list_sources:
            with redirect_stdout(output):
                self.assertEqual(cli(arguments), 0)
        list_sources.assert_called_once()
        record = json.loads(output.getvalue())
        self.assertEqual(record["type"], report["type"])
        self.assertEqual(record["sources"], report["sources"])

    def test_headless_cli_routes_block_registry_operation(self) -> None:
        arguments = _parser().parse_args(["--list-blocks", "--jsonl"])
        output = io.StringIO()
        report = {"ok": True, "type": "semantic_block_registry", "blocks": []}
        with patch.object(
            SemanticLabAuthoringService,
            "list_semantic_blocks",
            return_value=report,
        ) as list_blocks:
            with redirect_stdout(output):
                self.assertEqual(cli(arguments), 0)
        list_blocks.assert_called_once()
        self.assertEqual(json.loads(output.getvalue()), report)

    def test_workflow_service_composes_blocks_and_previews_existing_artifacts(self) -> None:
        service = SemanticLabAuthoringService(repository=REPOSITORY)
        report = service.preview_workflow(
            "common_interactions",
            ["language.speech_act", "dialogue_responses.response_pool"],
        )
        self.assertTrue(report["ok"], report)
        self.assertTrue(report["previewOnly"])
        self.assertTrue(report["effectFree"])
        self.assertEqual(report["writes"], [])
        self.assertEqual(report["workflow"]["datasetID"], "common_interactions")
        self.assertEqual(report["selection"]["blocks"]["blockIDs"], [
            "language.speech_act",
            "dialogue_responses.response_pool",
        ])
        self.assertTrue(report["sourcePreview"]["generatedPaths"])

    def test_workflow_generation_requires_explicit_approval(self) -> None:
        service = SemanticLabAuthoringService(repository=REPOSITORY)
        report = service.generate_workflow(
            "common_interactions",
            ["language.speech_act"],
            approved=False,
        )
        self.assertFalse(report["ok"])
        self.assertFalse(report["generationApproved"])
        self.assertTrue(report["previewOnly"])
        self.assertEqual(report["writes"], [])

    def test_headless_cli_routes_workflow_preview_through_semantic_lab(self) -> None:
        arguments = _parser().parse_args([
            "--workflow-preview", "common_interactions",
            "--workflow-blocks", "language.speech_act",
            "--jsonl",
        ])
        output = io.StringIO()
        report = {"ok": True, "type": "semantic_lab_workflow_preview", "writes": []}
        with patch.object(
            SemanticLabAuthoringService,
            "preview_workflow",
            return_value=report,
        ) as preview:
            with redirect_stdout(output):
                self.assertEqual(cli(arguments), 0)
        preview.assert_called_once_with("common_interactions", ["language.speech_act"])
        self.assertEqual(json.loads(output.getvalue()), report)

    def test_app_selects_headless_mode_for_authoring_operation(self) -> None:
        with patch.object(app, "install_shutdown_handler"), patch.object(app, "cli", return_value=0) as run_cli:
            self.assertEqual(app.main(["--list-datasets"]), 0)
        run_cli.assert_called_once()


if __name__ == "__main__":
    unittest.main()
