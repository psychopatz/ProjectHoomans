"""V1 reusable graph authoring proof through the existing worker pipeline."""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path
import shutil
import tempfile
import unittest

from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.inspection.conversation_inspector import build_conversation_inspector
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.tests.test_interaction_spec import backstory_spec, stay_spec
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[3]
BACKSTORY_BLOCKS = [
    "language.trigger",
    "language.backstory_subject",
    "memory.backstory_fact",
    "dialogue_responses.response_pool",
]
ACTION_BLOCKS = [
    "language.trigger",
    "gameplay_actions.capability",
    "dialogue_responses.response_pool",
]


class V1VisualAuthoringTests(unittest.TestCase):
    @staticmethod
    def scenario() -> dict:
        return merge(
            DEFAULT_SCENARIO,
            {
                "player": {"characterUUID": "v1-player"},
                "npc": {
                    "npcID": "npc-v1-graph",
                    "identitySeed": 90210,
                    "identity": {"seed": 90210},
                    "tacticalClass": "colonist",
                    "relationship": {"familiarity": 80},
                },
            },
        )

    @staticmethod
    def _isolated_repository(root: Path) -> None:
        (root / "Contents" / "mods").mkdir(parents=True)
        shutil.copytree(
            REPOSITORY / "Contents" / "mods" / "ProjectHoomans",
            root / "Contents" / "mods" / "ProjectHoomans",
        )
        (root / "tools" / "semantic_harness" / "codebuilder" / "sources").mkdir(
            parents=True
        )
        shutil.copy2(
            REPOSITORY
            / "tools"
            / "semantic_harness"
            / "codebuilder"
            / "sources"
            / "grounded_personal_dialogue.json",
            root
            / "tools"
            / "semantic_harness"
            / "codebuilder"
            / "sources"
            / "grounded_personal_dialogue.json",
        )
        shutil.copytree(
            REPOSITORY / "tools" / "semantic_harness" / "lua",
            root / "tools" / "semantic_harness" / "lua",
        )
        (root / "tests" / "support").mkdir(parents=True)
        shutil.copy2(
            REPOSITORY / "tests" / "support" / "test.lua",
            root / "tests" / "support" / "test.lua",
        )
        shutil.copy2(
            REPOSITORY / "tests" / "test_config.lua",
            root / "tests" / "test_config.lua",
        )
        source = REPOSITORY / (
            "tools/semantic_harness/codebuilder/sources/semantic_definitions.json"
        )
        target = root / (
            "tools/semantic_harness/codebuilder/sources/semantic_definitions.json"
        )
        target.write_text(source.read_text(encoding="utf-8"), encoding="utf-8")

    def test_backstory_and_registered_action_share_preview_approval_generation_and_worker(self) -> None:
        backstory = backstory_spec(
            spec_id="pnc.lab.v1.former_job",
            utterance="what was your v1 profession",
            pool_id="semantic.lab.v1.former_job",
            key="UI_PNC_Conversation_Semantic_LabV1FormerJob",
        )
        action = deepcopy(stay_spec())
        action["id"] = "pnc.lab.v1.follow"
        action["blocks"][0]["parameters"]["utterance"] = "v1 orchard lantern"
        action["blocks"][0]["parameters"]["negativeUtterance"] = "not v1 orchard lantern"
        action["blocks"][0]["parameters"]["frame"]["action"] = "FOLLOW"
        action["blocks"][1]["parameters"]["capabilityID"] = "pnc:companion.follow"
        action["blocks"][1]["parameters"]["action"] = "FOLLOW"
        action["blocks"][2]["parameters"]["poolID"] = "semantic.lab.v1.follow"
        action["blocks"][2]["parameters"]["variants"][0]["key"] = "UI_PNC_Conversation_Semantic_LabV1Follow"
        action["blocks"][2]["parameters"]["variants"][0]["en"] = "Okay, I will follow you for V1."
        action["blocks"][2]["parameters"]["variants"][0]["tl"] = "Sige, susunod ako sa iyo para sa V1."

        with tempfile.TemporaryDirectory(prefix="project-hoomans-v1-") as directory:
            root = Path(directory)
            self._isolated_repository(root)
            service = SemanticLabAuthoringService(repository=root, runtime_root=REPOSITORY)
            with LuaSemanticWorker(self.scenario()) as catalog_worker:
                catalog = catalog_worker.flow_catalog()

            backstory_preview = service.preview_workflow(
                "grounded_personal_dialogue",
                BACKSTORY_BLOCKS,
                production_catalog=catalog,
                interaction_spec=backstory,
            )
            action_preview = service.preview_workflow(
                "semantic_definitions",
                ACTION_BLOCKS,
                production_catalog=catalog,
                interaction_spec=action,
            )
            self.assertTrue(backstory_preview["ok"], backstory_preview)
            self.assertTrue(action_preview["ok"], action_preview)
            self.assertTrue(backstory_preview["effectFree"])
            self.assertTrue(action_preview["effectFree"])
            self.assertEqual(backstory_preview["writes"], [])
            self.assertEqual(action_preview["writes"], [])
            self.assertNotEqual(
                backstory_preview["sourcePreview"]["generatedSourceFingerprint"],
                action_preview["sourcePreview"]["generatedSourceFingerprint"],
            )
            self.assertIn("semanticLabGraph", backstory_preview["sourcePreview"]["compiled"])

            generated_backstory = service.generate_workflow(
                "grounded_personal_dialogue",
                BACKSTORY_BLOCKS,
                production_catalog=catalog,
                interaction_spec=backstory,
                approved=True,
            )
            generated_action = service.generate_workflow(
                "semantic_definitions",
                ACTION_BLOCKS,
                production_catalog=catalog,
                interaction_spec=action,
                approved=True,
            )
            self.assertTrue(generated_backstory["ok"], generated_backstory)
            self.assertTrue(generated_action["ok"], generated_action)
            self.assertTrue(all(Path(path).is_file() for path in generated_backstory["writes"]))
            self.assertTrue(all(Path(path).is_file() for path in generated_action["writes"]))

            with LuaSemanticWorker(
                self.scenario(),
                repository=root,
                core_repository=REPOSITORY.parent / "psychopatzCore",
            ) as worker:
                backstory_turn = worker.input("what was your v1 profession")
                action_turn = worker.input("v1 orchard lantern")

            self.assertEqual(
                backstory_turn["messages"][0]["payload"]["text"],
                "I worked as farmer before all this.",
            )
            self.assertEqual(action_turn["result"]["ir"]["action"], "FOLLOW")
            self.assertEqual(
                action_turn["messages"][0]["payload"]["text"],
                "Okay, I will follow you for V1.",
            )
            self.assertTrue(action_turn["observation"]["sideEffects"]["actions"])
            inspection = build_conversation_inspector(action_turn)
            self.assertTrue(
                inspection["acceptanceChain"]["selectedGraph"]["available"]
            )
            self.assertEqual(
                inspection["acceptanceChain"]["selectedGraph"]["schema"],
                "semantic.interaction_spec.v1",
            )

            changed_action = deepcopy(action)
            changed_action["blocks"][2]["parameters"]["variants"][0]["en"] = (
                "I will follow you after this graph edit."
            )
            changed_generated = service.generate_workflow(
                "semantic_definitions",
                ACTION_BLOCKS,
                production_catalog=catalog,
                interaction_spec=changed_action,
                approved=True,
            )
            self.assertTrue(changed_generated["ok"], changed_generated)
            self.assertNotEqual(
                generated_action["sourcePreview"]["generatedSourceFingerprint"],
                changed_generated["sourcePreview"]["generatedSourceFingerprint"],
            )
            with LuaSemanticWorker(
                self.scenario(),
                repository=root,
                core_repository=REPOSITORY.parent / "psychopatzCore",
            ) as worker:
                changed_turn = worker.input("v1 orchard lantern")
            self.assertEqual(
                changed_turn["messages"][0]["payload"]["text"],
                "I will follow you after this graph edit.",
            )


if __name__ == "__main__":
    unittest.main()
