"""Fresh-worker acceptance for the compiler-generated FOLLOW definition."""

from __future__ import annotations

import json
import hashlib
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.authoring import (
    generate_semantic_source,
    preview_semantic_source,
)
from tools.semantic_harness.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[3]


class SemanticAuthoringCompilerWorkerTests(unittest.TestCase):
    def test_lab_source_preview_is_effect_free_and_reports_mod_paths(self) -> None:
        report = preview_semantic_source(
            REPOSITORY / "tools/semantic_compiler/semantic_definitions.json"
        )
        self.assertTrue(report["ok"])
        self.assertTrue(report["previewOnly"])
        self.assertTrue(report["effectFree"])
        self.assertEqual(report["writes"], [])
        self.assertIn(
            "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/PNC_SemanticGeneratedDefinitions.lua",
            report["generatedPaths"],
        )
        self.assertIn(
            "Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/Semantic/Generated.json",
            report["generatedPaths"],
        )
        self.assertEqual(report["capabilityIDs"], ["pnc:companion.follow"])
        self.assertEqual(
            report["translationKeys"],
            {
                "EN": ["UI_PNC_Conversation_Semantic_AuthoredFollowAccepted"],
                "TL": ["UI_PNC_Conversation_Semantic_AuthoredFollowAccepted"],
            },
        )

    def test_lab_source_preview_returns_diagnostic_without_writing(self) -> None:
        source = json.loads(
            (REPOSITORY / "tools/semantic_compiler/semantic_definitions.json")
            .read_text(encoding="utf-8")
        )
        source["definitions"][0]["capability"] = "pnc:missing.action"
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "invalid.json"
            path.write_text(json.dumps(source), encoding="utf-8")
            report = preview_semantic_source(path)
        self.assertFalse(report["ok"])
        self.assertTrue(report["previewOnly"])
        self.assertTrue(report["effectFree"])
        self.assertEqual(report["generatedPaths"], [])
        self.assertEqual(report["writes"], [])
        self.assertIn("unregistered capability", report["diagnostics"][0]["message"])

    def test_approved_generation_writes_modular_artifacts_byte_stably(self) -> None:
        source = REPOSITORY / "tools/semantic_compiler/semantic_definitions.json"
        with tempfile.TemporaryDirectory() as directory:
            output_root = Path(directory)
            first = generate_semantic_source(
                source, repository=output_root, runtime_root=REPOSITORY
            )
            self.assertTrue(first["ok"])
            self.assertTrue(first["generationApproved"])
            self.assertTrue(first["writes"])
            hashes_before = {
                path: hashlib.sha256(Path(path).read_bytes()).hexdigest()
                for path in first["writes"]
            }
            second = generate_semantic_source(
                source, repository=output_root, runtime_root=REPOSITORY
            )
            hashes_after = {
                path: hashlib.sha256(Path(path).read_bytes()).hexdigest()
                for path in second["writes"]
            }
        self.assertEqual(hashes_before, hashes_after)
        self.assertEqual(second["reloadedBy"], "caller_restart_required")

    def test_generated_definition_loads_routes_and_survives_restart(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()
            self.assertIn(
                "pnc.dialogue.follow.flow",
                [flow["id"] for flow in catalog["flows"]],
            )
            previews = [worker.preview("Keep close behind me") for _ in range(2)]
            first = worker.input("Keep close behind me")
            negative = worker.input("Don't keep close behind me")
            question = worker.input("Are you keeping close behind me")
            worker.restart()
            after_restart = worker.input("Please keep close behind me")

        for preview in previews:
            self.assertEqual(
                preview["observation"]["ir"]["pattern"],
                "pnc.dialogue.follow.keep_close_behind_me",
            )
            self.assertTrue(preview["observation"]["sideEffects"]["none"])
            self.assertEqual(preview["transport"], [])
            self.assertEqual(preview["toolCalls"], [])

        result = first["result"]
        self.assertEqual(
            result["ir"]["provenance"]["pattern"],
            "pnc.dialogue.follow.keep_close_behind_me",
        )
        self.assertEqual(result["ir"]["action"], "FOLLOW")
        self.assertEqual(result["actionResult"]["capabilityID"], "pnc:companion.follow")
        self.assertEqual([event["command"] for event in first["transport"]], ["CompanionCommand"])
        self.assertEqual(first["transport"][0]["payload"]["commandID"], "follow")

        for safe_negative in (negative, question):
            self.assertEqual(safe_negative["transport"], [])
            self.assertEqual(safe_negative["toolCalls"], [])
            self.assertTrue(safe_negative["observation"]["sideEffects"]["none"])
        self.assertEqual(negative["result"]["decision"]["branch"], "ASK_CLARIFICATION")
        self.assertEqual(question["result"]["decision"]["branch"], "ASK_CLARIFICATION")
        self.assertEqual(
            after_restart["result"]["ir"]["provenance"]["pattern"],
            "pnc.dialogue.follow.please_keep_close_behind_me",
        )
        self.assertEqual(after_restart["result"]["actionResult"]["commandID"], "follow")


if __name__ == "__main__":
    unittest.main()
