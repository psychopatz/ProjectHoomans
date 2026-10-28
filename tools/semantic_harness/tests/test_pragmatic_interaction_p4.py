"""P4 worker-local interaction module authoring seam acceptance."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class PragmaticInteractionP4WorkerTests(unittest.TestCase):
    def test_catalog_validate_preview_register_and_run_draft(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.beat_catalog()
            self.assertEqual(catalog["beatCount"], 3)
            self.assertEqual(catalog["behaviorCount"], 12)
            argument = next(
                item for item in catalog["beats"]
                if item["id"] == "beat.argument_escalation"
            )

            draft = deepcopy(argument)
            draft["id"] = "beat.lab_argument"
            draft["owner"] = "SemanticLab"
            draft["baseRelevance"] = 0.99
            draft["labelKey"] = "UI_Lab_Beat_Argument_Label"
            draft["descriptionKey"] = "UI_Lab_Beat_Argument_Description"

            valid = worker.validate_beat(draft)
            self.assertTrue(valid["valid"], valid)

            before = worker.snapshot()
            preview = worker.preview_beat(draft, "fuck ypuuuu")
            after = worker.snapshot()
            self.assertTrue(preview["valid"], preview)
            self.assertTrue(preview["previewed"], preview)
            self.assertTrue(preview["draft"]["eligible"])
            self.assertEqual(
                preview["draft"]["beat"]["id"],
                "beat.lab_argument",
            )
            self.assertEqual(
                preview["draft"]["selectedBehavior"]["id"],
                "behavior.warn",
            )
            self.assertFalse(preview["mutatedConversation"])
            self.assertFalse(preview["registered"])
            before_dialogue = (before.get("context") or {}).get("dialogue") or {}
            after_dialogue = (after.get("context") or {}).get("dialogue") or {}
            self.assertEqual(int(before_dialogue.get("sequence") or 0), 0)
            self.assertEqual(int(after_dialogue.get("sequence") or 0), 0)
            before_director = before_dialogue.get("director") or {}
            after_director = after_dialogue.get("director") or {}
            self.assertIsNone(before_director.get("active"))
            self.assertIsNone(after_director.get("active"))
            self.assertEqual(int(after_director.get("revision") or 0), 0)
            self.assertEqual(worker.beat_catalog()["beatCount"], 3)

            registered = worker.register_beat(draft)
            self.assertTrue(registered["registered"], registered)
            self.assertEqual(registered["beatCount"], 4)
            result = worker.input("fuck ypuuuu")
            self.assertEqual(
                result["result"]["decision"]["director"]["selectedBeat"]["id"],
                "beat.lab_argument",
            )
            self.assertEqual(
                result["result"]["decision"]["interactionPlan"]["beatID"],
                "beat.lab_argument",
            )
            self.assertEqual(
                result["result"]["decision"]["response"]["sourcePoolID"],
                "semantic.hostile_remark",
            )
            self.assertEqual(
                result["result"]["decision"]["response"]["plan"]["dialogueAct"],
                "BOUNDARY_WARNING",
            )

    def test_behavior_draft_validates_and_can_feed_a_draft_beat(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.beat_catalog()
            warn = next(
                item for item in catalog["behaviors"]
                if item["id"] == "behavior.warn"
            )
            behavior = deepcopy(warn)
            behavior["id"] = "behavior.lab_warn"
            behavior["owner"] = "SemanticLab"
            behavior["baseRelevance"] = 1.0
            behavior["labelKey"] = "UI_Lab_Behavior_Warn_Label"
            behavior["descriptionKey"] = "UI_Lab_Behavior_Warn_Description"

            valid_behavior = worker.validate_behavior(behavior)
            self.assertTrue(valid_behavior["valid"], valid_behavior)
            registered_behavior = worker.register_behavior(behavior)
            self.assertTrue(
                registered_behavior["registered"],
                registered_behavior,
            )

            argument = next(
                item for item in registered_behavior["beats"]
                if item["id"] == "beat.argument_escalation"
            )
            draft = deepcopy(argument)
            draft["id"] = "beat.lab_behavior_test"
            draft["owner"] = "SemanticLab"
            draft["baseRelevance"] = 1.0
            draft["labelKey"] = "UI_Lab_Beat_Behavior_Test_Label"
            draft["descriptionKey"] = "UI_Lab_Beat_Behavior_Test_Description"
            draft["candidates"] = [
                {"behavior": "behavior.lab_warn", "relevance": 1.0},
            ]
            valid_beat = worker.validate_beat(draft)
            self.assertTrue(valid_beat["valid"], valid_beat)
            preview = worker.preview_beat(draft, "fuck you")
            self.assertTrue(preview["draft"]["eligible"])
            self.assertEqual(
                preview["draft"]["selectedBehavior"]["id"],
                "behavior.lab_warn",
            )

    def test_invalid_draft_is_rejected_by_production_registry(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.beat_catalog()
            draft = deepcopy(catalog["beats"][0])
            draft["id"] = "beat.lab_invalid"
            draft["candidates"] = [
                {"behavior": "behavior.does_not_exist", "relevance": 0.5},
            ]
            result = worker.validate_beat(draft)
            self.assertFalse(result["valid"])
            self.assertIn("beat_behavior_unknown", result["reason"])


if __name__ == "__main__":
    unittest.main()
