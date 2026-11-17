from __future__ import annotations

from copy import deepcopy
import unittest

from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO
from tools.providers.pnc.tests.worker_reuse import WarmWorkerTestMixin


PROVIDER = "projecthoomans.generated_affordances"


def generated(turn: dict) -> list[dict]:
    return [
        row
        for row in turn["observation"]["suggestions"]["candidates"]
        if row.get("providerID") == PROVIDER
    ]


class ConversationMultiTurnCoherenceContractTests(WarmWorkerTestMixin, unittest.TestCase):
    def test_npc_pending_question_drives_current_player_affordances(self) -> None:
        with self.warm_worker(deepcopy(DEFAULT_SCENARIO)) as worker:
            turn = worker.input("how are you doing?")

        pending = turn["contextAfter"]["dialogue"]["pendingFollowUp"]
        self.assertEqual(pending["kind"], "QUESTION")
        self.assertEqual(pending["flowID"], "wellbeing")
        self.assertEqual(pending["topic"], "wellbeing")

        rows = generated(turn)
        self.assertEqual(
            [row["strategy"] for row in rows],
            [
                "WELLBEING_POSITIVE",
                "WELLBEING_NEUTRAL",
                "WELLBEING_NEGATIVE",
            ],
        )
        self.assertEqual(
            {row["topic"] for row in rows},
            {"wellbeing"},
        )
        for row in rows:
            frame = row["frame"]
            self.assertEqual(frame["intent"], "INFORM")
            self.assertEqual(frame["subject"], "WELLBEING")
            self.assertTrue(frame["socialContext"]["selfDirected"])
            reply_to = frame["extensions"]["discourseFrame"]["replyTo"]
            self.assertEqual(reply_to["kind"], "pending_interaction")
            self.assertEqual(reply_to["flowID"], "wellbeing")

    def test_generated_and_typed_wellbeing_answers_converge(self) -> None:
        with self.warm_worker(deepcopy(DEFAULT_SCENARIO)) as worker:
            opening = worker.input("hello")
            positive = next(
                row for row in generated(opening)
                if row["strategy"] == "WELLBEING_POSITIVE"
            )
            clicked = worker.suggestion_click(positive["frame"])

        with self.warm_worker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.input("hello")
            typed = worker.input("I'm good")

        for turn in (clicked, typed):
            self.assertEqual(turn["result"]["ir"]["intent"], "INFORM")
            self.assertEqual(turn["result"]["ir"]["subject"], "WELLBEING")
            self.assertEqual(
                turn["result"]["decision"]["branch"],
                "SELF_STATE_RECEIVED",
            )
            self.assertEqual(turn["observation"]["flow"]["transition"], "match")
            self.assertIsNone(
                turn["contextAfter"]["dialogue"].get("pendingFollowUp")
            )
        self.assertEqual(
            clicked["result"]["ir"]["slots"]["state"]["value"],
            typed["result"]["ir"]["slots"]["state"]["value"],
        )
        self.assertEqual(
            clicked["result"]["ir"]["provenance"]["parser"],
            "semantic_click_frame",
        )
        self.assertEqual(
            typed["result"]["ir"]["provenance"]["parser"],
            "deterministic",
        )

    def test_identity_choice_frames_carry_safe_claim_metadata(self) -> None:
        with self.warm_worker(deepcopy(DEFAULT_SCENARIO)) as worker:
            turn = worker.input("what is your name?")

        rows = {row["strategy"]: row for row in generated(turn)}
        self.assertEqual(set(rows), {"DISCLOSE_NAME", "REFUSE_IDENTITY"})

        disclose = rows["DISCLOSE_NAME"]
        self.assertEqual(disclose["display"]["utterance"], "I'm Patrick Patz.")
        self.assertEqual(
            disclose["frame"]["slots"]["identityClaim"]["name"],
            "Patrick Patz",
        )
        self.assertTrue(disclose["frame"]["socialContext"]["identityClaim"])
        self.assertNotIn("npc", str(disclose["frame"]["slots"]).lower())

        refusal = rows["REFUSE_IDENTITY"]
        self.assertEqual(refusal["frame"]["kind"], "semantic_click_frame")
        self.assertEqual(refusal["frame"]["intent"], "REFUSE")
        self.assertEqual(refusal["frame"]["subject"], "IDENTITY")

if __name__ == "__main__":
    unittest.main()
