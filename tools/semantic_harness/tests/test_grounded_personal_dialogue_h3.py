"""H3 real-worker regressions for grounded backstory conversations."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


class GroundedPersonalDialogueH3Tests(unittest.TestCase):
    @staticmethod
    def scenario(familiarity: int = 80, language: str = "EN") -> dict:
        return merge(
            DEFAULT_SCENARIO,
            {
                "npc": {
                    "npcID": "npc-h3-grounded",
                    "identitySeed": 90210,
                    "identity": {"seed": 90210},
                    "tacticalClass": "colonist",
                    "relationship": {"familiarity": familiarity},
                },
                "runtime": {"language": language},
            },
        )

    @staticmethod
    def final_text(turn: dict) -> str:
        messages = turn["observation"].get("authoritativeMessages", [])
        if messages:
            return str(messages[-1].get("text") or "")
        return ""

    @staticmethod
    def translation_keys(turn: dict) -> set[str]:
        return {
            str(lookup.get("key"))
            for lookup in turn.get("translation", {}).get("lookups", [])
            if lookup.get("key")
        }

    def test_familiarity_gates_disclosure_and_preserves_follow_up_context(self) -> None:
        with LuaSemanticWorker(self.scenario()) as worker:
            old_job = worker.input("what was your old job")
            self.assertEqual(
                old_job["result"]["ir"]["provenance"]["pattern"],
                "pnc.backstory.question.former_job.old_job",
            )
            self.assertEqual(
                self.final_text(old_job),
                "I worked as farmer before all this.",
            )
            self.assertIn(
                "UI_PNC_Conversation_Semantic_QuestionBackstoryFormerJob",
                self.translation_keys(old_job),
            )
            self.assertIn("knowledge", old_job["contextAfter"])

            where = worker.input("where?")
            self.assertEqual(
                where["result"]["ir"]["provenance"]["pattern"],
                "pnc.backstory.follow_up.where",
            )
            self.assertEqual(
                self.final_text(where),
                "I remember that part of my life, but I don't have more detail about where it was.",
            )
            self.assertIn(
                "UI_PNC_Conversation_Semantic_QuestionBackstoryFollowUpLocation",
                self.translation_keys(where),
            )
            self.assertNotEqual(
                where["result"]["decision"]["branch"], "ASK_CLARIFICATION"
            )

            miss = worker.input("do you miss it?")
            self.assertEqual(
                miss["result"]["ir"]["provenance"]["pattern"],
                "pnc.backstory.follow_up.do_you_miss_it",
            )
            self.assertEqual(
                self.final_text(miss),
                "Sometimes. I still think about that part of my life.",
            )
            self.assertIn(
                "UI_PNC_Conversation_Semantic_QuestionBackstoryFollowUpMiss",
                self.translation_keys(miss),
            )

    def test_private_backstory_refuses_without_authorized_disclosure(self) -> None:
        with LuaSemanticWorker(self.scenario(familiarity=0)) as worker:
            turn = worker.input("what was your old job")

        self.assertEqual(
            turn["result"]["decision"]["branch"], "QUESTION_RECEIVED"
        )
        self.assertEqual(
            self.final_text(turn),
            "I'm not ready to talk about that yet.",
        )
        self.assertIn(
            "UI_PNC_Conversation_Semantic_QuestionBackstoryRefusal",
            self.translation_keys(turn),
        )
        self.assertNotIn("knowledge", turn["contextAfter"])

    def test_authoritative_backstory_sentence_resolves_in_tagalog(self) -> None:
        with LuaSemanticWorker(self.scenario(language="TL")) as worker:
            turn = worker.input("what was your old job")

        self.assertEqual(
            self.final_text(turn),
            "Nagtrabaho ako bilang farmer bago ang lahat ng ito.",
        )
        self.assertEqual(turn["translation"]["language"], "TL")
        self.assertTrue(
            all(
                not lookup.get("fallbackUsed", False)
                for lookup in turn["translation"]["lookups"]
            )
        )


if __name__ == "__main__":
    unittest.main()
