"""B3 real-worker regression for compositional backstory questions."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.worker import LuaSemanticWorker


class GroundedPersonalDialogueB3Tests(unittest.TestCase):
    def test_questions_emit_backstory_kind_and_fail_closed_without_dossier(self) -> None:
        questions = {
            "what did you do before": "former_job",
            "what was your job": "former_job",
            "where are you from": "hometown",
            "what is your hobby": "hobby",
            "tell me about your family": "family_background",
            "what are you afraid of": "fear",
            "what happened to you": "tragedy",
            "how did you survive": "survival_origin",
            "when is your birthday": "date_of_birth",
        }
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            for text, kind in questions.items():
                with self.subTest(text=text):
                    preview = worker.preview(text)
                    result = preview["result"]
                    ir = result["ir"]
                    self.assertEqual(ir["intent"], "QUESTION")
                    self.assertEqual(ir["subject"], "NPC_BACKSTORY")
                    self.assertEqual(ir["slots"]["backstoryKind"], kind)
                    self.assertEqual(
                        ir["extensions"]["facts"]["NPC_BACKSTORY"]["status"],
                        "unknown",
                    )
                    self.assertEqual(
                        ir["extensions"]["facts"]["NPC_BACKSTORY"]["reason"],
                        "backstory_not_disclosed",
                    )
                    self.assertEqual(
                        ir["extensions"]["facts"]["NPC_BACKSTORY"]["topicID"],
                        "backstory." + kind,
                    )
                    self.assertEqual(result["decision"]["route"], "deterministic")


if __name__ == "__main__":
    unittest.main()
