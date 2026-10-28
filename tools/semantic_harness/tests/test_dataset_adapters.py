"""S4 provenance-gated MASSIVE/SGD build-time adapter contracts."""

from __future__ import annotations

import hashlib
from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import tempfile
import unittest

from tools.semantic_harness.codebuilder.dialogue_dataset import compile_dialogue_dataset
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.codebuilder.dataset_adapters import (
    preview_dataset_adapter,
    promote_reviewed_candidates,
)
from tools.semantic_harness.cli import _parser, cli


REPOSITORY = Path(__file__).resolve().parents[3]

def _write_manifest(
    directory: Path,
    source: Path,
    *,
    adapter: str,
    source_name: str,
    redistribution: str = "metadata_only",
    allow_raw_text: bool = False,
) -> Path:
    manifest = directory / f"{adapter}.manifest.json"
    manifest.write_text(
        json.dumps(
            {
                "adapter": adapter,
                "sourceName": source_name,
                "version": "test-1",
                "revision": "test-revision",
                "url": "https://example.invalid/reviewed-source",
                "sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
                "language": "en-US",
                "license": "test-reviewed-license",
                "allowedUse": "analysis/evaluation",
                "redistribution": redistribution,
                "allowRawText": allow_raw_text,
                "reviewedOn": "2026-10-19",
            }
        ),
        encoding="utf-8",
    )
    return manifest


class DatasetAdapterTests(unittest.TestCase):
    def test_massive_adapter_is_bounded_and_never_runtime_packaged(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "massive.jsonl"
            source.write_text(
                "\n".join(
                    json.dumps(row)
                    for row in (
                        {"id": "m-1", "locale": "en-US", "domain": "weather", "intent": "weather_query", "utt": "is it raining"},
                        {"id": "m-2", "locale": "tl-PH", "domain": "weather", "intent": "weather_query", "utt": "umuulan ba"},
                    )
                )
                + "\n",
                encoding="utf-8",
            )
            manifest = _write_manifest(root, source, adapter="massive", source_name="MASSIVE")
            report = preview_dataset_adapter("massive", source, manifest)

        self.assertTrue(report["ok"], report)
        self.assertEqual(report["candidateCount"], 2)
        self.assertFalse(report["runtimePackaged"])
        self.assertFalse(report["promotionAllowed"])
        self.assertEqual(report["writes"], [])
        self.assertNotIn("raw", report["candidates"][0])
        self.assertNotIn("fullRecord", report["candidates"][0])
        self.assertEqual(report["candidates"][0]["status"], "unmapped")

    def test_sgd_adapter_normalizes_user_turn_state_without_copying_dialogue(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "sgd.json"
            source.write_text(
                json.dumps(
                    {
                        "dialogues": [
                            {
                                "dialogue_id": "dlg-1",
                                "turns": [
                                    {"speaker": "SYSTEM", "utterance": "How can I help?"},
                                    {
                                        "speaker": "USER",
                                        "utterance": "which item do you mean",
                                        "frames": [{"service": "Medical", "state": {"active_intent": "Clarify", "slot_values": {"item": ["bandage"]}}}],
                                        "dialogue_acts": [{"act": "REQUEST", "slot": "item"}],
                                    },
                                ],
                            }
                        ]
                    }
                ),
                encoding="utf-8",
            )
            manifest = _write_manifest(root, source, adapter="sgd", source_name="SGD")
            report = preview_dataset_adapter("sgd", source, manifest)

        self.assertTrue(report["ok"], report)
        self.assertEqual(report["candidateCount"], 1)
        candidate = report["candidates"][0]
        self.assertEqual(candidate["service"], "Medical")
        self.assertEqual(candidate["intent"], "Clarify")
        self.assertEqual(candidate["status"], "unmapped")
        self.assertNotIn("turns", candidate)
        self.assertFalse(report["runtimePackaged"])

    def test_promotion_requires_explicit_raw_text_clearance_and_uses_existing_compiler(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "massive.jsonl"
            source.write_text(
                json.dumps({"id": "m-1", "intent": "wellbeing", "utt": "please check my condition"}) + "\n",
                encoding="utf-8",
            )
            metadata_manifest = _write_manifest(root, source, adapter="massive", source_name="MASSIVE")
            metadata_report = preview_dataset_adapter("massive", source, metadata_manifest)
            candidate_id = metadata_report["candidates"][0]["id"]
            blocked = promote_reviewed_candidates(
                metadata_report,
                [{"candidateID": candidate_id, "approved": True, "mapping": {"canonicalConcept": "WELLBEING", "dialogueState": "WELLBEING_FOLLOW_UP", "emit": {"intent": "QUESTION", "speechAct": "QUESTION", "subject": "WELLBEING"}}}],
            )
            self.assertFalse(blocked["ok"])

            approved_manifest = _write_manifest(
                root,
                source,
                adapter="massive",
                source_name="MASSIVE",
                redistribution="approved",
                allow_raw_text=True,
            )
            approved_report = preview_dataset_adapter("massive", source, approved_manifest)
            promoted = promote_reviewed_candidates(
                approved_report,
                [{
                    "candidateID": candidate_id,
                    "approved": True,
                    "mapping": {
                        "canonicalConcept": "WELLBEING",
                        "dialogueState": "WELLBEING_FOLLOW_UP",
                        "emit": {"intent": "QUESTION", "speechAct": "QUESTION", "subject": "WELLBEING"},
                    },
                    "negatives": ["please check my own condition"],
                }],
            )

        self.assertTrue(promoted["ok"], promoted)
        self.assertEqual(promoted["promotedCount"], 1)
        document = SemanticLabAuthoringService(
            repository=REPOSITORY,
            runtime_root=REPOSITORY,
        ).load_dataset_document("common_dialogue")
        document["patterns"].append(promoted["patterns"][0])
        compiled = compile_dialogue_dataset(document)
        self.assertTrue(any(item["id"] == promoted["patterns"][0]["id"] for item in compiled["patterns"]))
        self.assertEqual(promoted["writes"], [])

    def test_headless_cli_routes_adapter_preview_through_semantic_lab(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "massive.jsonl"
            source.write_text(
                json.dumps({"id": "m-1", "utt": "is it raining"}) + "\n",
                encoding="utf-8",
            )
            manifest = _write_manifest(root, source, adapter="massive", source_name="MASSIVE")
            arguments = _parser().parse_args([
                "--adapt-dataset", "massive",
                "--dataset-source", str(source),
                "--dataset-manifest", str(manifest),
                "--jsonl",
            ])
            output = io.StringIO()
            with redirect_stdout(output):
                self.assertEqual(cli(arguments), 0)
            report = json.loads(output.getvalue())
            self.assertEqual(report["type"], "dataset_adapter_review")
            self.assertTrue(report["effectFree"])
            self.assertEqual(report["writes"], [])

    def test_adapter_rejects_runtime_media_source(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "Contents/mods/ProjectHoomans/common/media/raw.jsonl"
            source.parent.mkdir(parents=True)
            source.write_text(json.dumps({"utt": "raw"}) + "\n", encoding="utf-8")
            manifest = _write_manifest(root, source, adapter="massive", source_name="MASSIVE")
            report = preview_dataset_adapter("massive", source, manifest)
        self.assertFalse(report["ok"])
        self.assertTrue(any("cannot be under" in item["message"] for item in report["diagnostics"]))


if __name__ == "__main__":
    unittest.main()
