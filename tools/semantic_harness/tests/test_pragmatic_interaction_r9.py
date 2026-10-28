"""R9 headless acceptance for the integrated interaction workbench."""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path
import unittest

from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.ui.interaction_modules.model import _behavior_content_refs
from tools.semantic_harness.ui.interaction_inspector import interaction_summary


REPOSITORY = Path(__file__).resolve().parents[3]


class PragmaticInteractionR9Tests(unittest.TestCase):
    def test_behavior_outputs_link_to_dialogue_content_without_wording(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.beat_catalog()
        behavior = next(
            row for row in catalog["behaviors"]
            if row["id"] == "behavior.acknowledge_memory"
        )
        refs = _behavior_content_refs(behavior)
        self.assertEqual(
            refs["speech"],
            "semantic.interaction.memory.acknowledge",
        )
        self.assertEqual(
            refs["flavor"],
            "semantic.interaction.memory.acknowledge_flavor",
        )
        self.assertNotIn("translations", behavior)
        self.assertNotIn("fallback", behavior)
        self.assertEqual(
            set(behavior["outputs"]),
            {"speech", "emote", "flavor"},
        )

    def test_behavior_structural_diff_is_effect_free_and_separate_from_wording(self) -> None:
        service = SemanticLabAuthoringService(REPOSITORY)
        current = service.load_interaction_definition(
            "behavior.acknowledge_memory"
        )
        source = Path(current["sourcePath"])
        before = source.read_bytes()
        edited = deepcopy(current)
        edited["baseRelevance"] = float(current["baseRelevance"]) + 0.01

        report = service.preview_interaction_definition_edit(
            current["id"],
            edited,
            expected_source_fingerprint=current["sourceFingerprint"],
        )
        self.assertTrue(report["ok"], report)
        self.assertTrue(report["previewOnly"])
        self.assertTrue(report["effectFree"])
        self.assertEqual(source.read_bytes(), before)
        self.assertTrue(
            any(
                path.endswith(
                    "Generated/Conversation/Behaviors/Social/AcknowledgeMemory.lua"
                )
                for path in report["changedGeneratedPaths"]
            ),
            report["changedGeneratedPaths"],
        )

        speech = current["outputs"]["speech"]
        content = service.load_dialogue_content(
            "phrase.semantic.interaction.memory.acknowledge"
        )
        self.assertEqual(
            content["semanticTemplateID"],
            speech["contentTemplateID"],
        )
        self.assertNotIn("styles", current)

    def test_real_worker_inspector_exposes_r9_interaction_evidence(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            result = worker.input("fuck ypuuuu")
        observation = result["observation"]
        summary = interaction_summary(observation)
        director = observation["director"]

        self.assertEqual(
            director["stimulus"]["type"],
            "HUMAN_UTTERANCE",
        )
        self.assertEqual(
            director["stimulus"]["source"]["providerID"],
            "psychopatzcore.nlu",
        )
        self.assertTrue(director["pragmatic"]["providers"]["actor"])
        self.assertGreaterEqual(
            int(director["metrics"]["indexedBeatCandidateCount"]),
            1,
        )
        self.assertIn("PRAGMATIC INTERACTION DIRECTOR", summary)
        self.assertIn("Typed stimulus", summary)
        self.assertIn("Provider provenance", summary)
        self.assertIn("behavior source:", summary)
        self.assertIn("output adapters:", summary)
        self.assertIn("Bounded evaluation", summary)

    def test_developer_surface_links_structure_to_dialogue_content(self) -> None:
        builder = (
            REPOSITORY
            / "tools/semantic_harness/ui/studio_surface_builder.py"
        ).read_text(encoding="utf-8")
        content_pane = (
            REPOSITORY
            / "tools/semantic_harness/studio/dialogue_content_pane.py"
        ).read_text(encoding="utf-8")
        self.assertIn('text="Interaction Modules"', builder)
        self.assertNotIn('text="Beat Studio"', builder)
        self.assertIn("on_open_content=", builder)
        self.assertIn("def select_content(", content_pane)


if __name__ == "__main__":
    unittest.main()
