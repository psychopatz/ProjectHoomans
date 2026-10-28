"""P5 compiler promotion and beat-inspector acceptance."""

from __future__ import annotations

from copy import deepcopy
import json
import shutil
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.conversation_compiler import (
    CONVERSATION_SOURCE_RELATIVE,
)
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.ui.interaction_inspector import interaction_summary, interaction_timeline_record


REPOSITORY = Path(__file__).resolve().parents[3]


class PragmaticInteractionP5Tests(unittest.TestCase):
    def test_promotion_preview_is_effect_free_and_source_fingerprinted(self) -> None:
        service = SemanticLabAuthoringService(REPOSITORY)
        current = service.load_interaction_definition("beat.argument_escalation")
        source = Path(current["sourcePath"])
        before = source.read_bytes()

        edited = deepcopy(current)
        edited["baseRelevance"] = 0.73
        report = service.preview_interaction_definition_edit(
            "beat.argument_escalation",
            edited,
            expected_source_fingerprint=current["sourceFingerprint"],
        )
        self.assertTrue(report["ok"], report)
        self.assertTrue(report["previewOnly"])
        self.assertTrue(report["effectFree"])
        self.assertIn(
            "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/"
            "Semantics/Generated/Conversation/Beats/Social.lua",
            report["changedGeneratedPaths"],
        )
        self.assertEqual(source.read_bytes(), before)

        stale = service.preview_interaction_definition_edit(
            "beat.argument_escalation",
            edited,
            expected_source_fingerprint="stale-fingerprint",
        )
        self.assertFalse(stale["ok"])
        self.assertTrue(stale["stale"])

    def test_promotion_writes_only_canonical_source_then_regenerates(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            repository = Path(directory)
            shutil.copytree(
                REPOSITORY / CONVERSATION_SOURCE_RELATIVE,
                repository / CONVERSATION_SOURCE_RELATIVE,
            )
            service = SemanticLabAuthoringService(
                repository,
                runtime_root=REPOSITORY,
            )
            current = service.load_interaction_definition(
                "beat.argument_escalation"
            )
            edited = deepcopy(current)
            edited["baseRelevance"] = 0.74
            edited.pop("translations", None)
            edited["labelKey"] = "SHOULD_NOT_BECOME_CANONICAL"
            edited["descriptionKey"] = "SHOULD_NOT_BECOME_CANONICAL"

            report = service.write_interaction_definition_edit(
                "beat.argument_escalation",
                edited,
                expected_source_fingerprint=current["sourceFingerprint"],
            )
            self.assertTrue(report["ok"], report)
            self.assertFalse(report["previewOnly"])
            self.assertFalse(report["effectFree"])

            refreshed = service.load_interaction_definition(
                "beat.argument_escalation"
            )
            self.assertEqual(refreshed["baseRelevance"], 0.74)
            source_document = json.loads(
                Path(refreshed["sourcePath"]).read_text(encoding="utf-8")
            )
            canonical = next(
                row for row in source_document["beats"]
                if row["id"] == "beat.argument_escalation"
            )
            self.assertNotIn("labelKey", canonical)
            self.assertNotIn("descriptionKey", canonical)
            self.assertNotIn("translations", canonical)

            self.assertTrue(
                (
                    repository
                    / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/"
                    "Semantics/Generated/Conversation/Beats/Social.lua"
                ).is_file()
            )
            for language in ("EN", "TL"):
                self.assertFalse(
                    (
                        repository
                        / "Contents/mods/ProjectHoomans/common/media/translation"
                        / language
                        / "Conversation/Director.json"
                    ).exists()
                )

    def test_inspector_summary_and_timeline_use_real_worker_evidence(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["personality"] = {
            "aggression": 0.95,
            "confidence": 0.85,
            "forgiveness": 0.8,
        }
        with LuaSemanticWorker(scenario) as worker:
            result = worker.input("fuck ypuuuu")
        observation = result["observation"]
        summary = interaction_summary(observation)
        self.assertIn("PRAGMATIC INTERACTION DIRECTOR", summary)
        self.assertIn("beat.argument_escalation", summary)
        self.assertIn("behavior.retaliate_verbally", summary)
        self.assertIn("aggressive_personality", summary)
        self.assertIn("semantic.hostile_remark", summary)
        self.assertIn("RETALIATE_VERBALLY", summary)

        row = interaction_timeline_record(result)
        self.assertEqual(row["intent"], "HOSTILE_REMARK")
        self.assertEqual(row["beat"], "beat.argument_escalation")
        self.assertEqual(row["behavior"], "behavior.retaliate_verbally")
        self.assertEqual(
            row["evidence"]["interactionPlan"]["beatID"],
            "beat.argument_escalation",
        )
        self.assertEqual(
            row["evidence"]["response"]["sourcePoolID"],
            "semantic.hostile_remark",
        )


if __name__ == "__main__":
    unittest.main()
