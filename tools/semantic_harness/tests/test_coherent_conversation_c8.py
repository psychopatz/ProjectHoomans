from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


PROVIDER = "projecthoomans.generated_affordances"


def generated(turn: dict) -> list[dict]:
    return [
        row
        for row in turn["observation"]["suggestions"]["candidates"]
        if row.get("providerID") == PROVIDER
    ]


class CoherentConversationC8Tests(unittest.TestCase):
    def test_npc_pending_question_drives_current_player_affordances(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
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
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            opening = worker.input("hello")
            positive = next(
                row for row in generated(opening)
                if row["strategy"] == "WELLBEING_POSITIVE"
            )
            clicked = worker.suggestion_click(positive["frame"])

        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
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

    def test_identity_question_generates_safe_disclosure_and_evasion(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            turn = worker.input("what is your name?")
            rows = {row["strategy"]: row for row in generated(turn)}

            self.assertEqual(
                set(rows),
                {"DISCLOSE_NAME", "REFUSE_IDENTITY"},
            )
            disclose = rows["DISCLOSE_NAME"]
            self.assertEqual(disclose["display"]["utterance"], "I'm Patrick Patz.")
            self.assertEqual(
                disclose["frame"]["slots"]["identityClaim"]["name"],
                "Patrick Patz",
            )
            self.assertTrue(
                disclose["frame"]["socialContext"]["identityClaim"]
            )
            self.assertNotIn(
                "npc",
                str(disclose["frame"]["slots"]).lower(),
            )

            accepted = worker.suggestion_click(disclose["frame"])

        self.assertEqual(
            accepted["result"]["decision"]["branch"],
            "IDENTITY_CLAIM_RECEIVED",
        )
        self.assertEqual(
            accepted["observation"]["flow"]["transition"],
            "match",
        )
        self.assertIsNone(
            accepted["contextAfter"]["dialogue"].get("pendingFollowUp")
        )

        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            turn = worker.input("what is your name?")
            refusal = next(
                row for row in generated(turn)
                if row["strategy"] == "REFUSE_IDENTITY"
            )
            declined = worker.suggestion_click(refusal["frame"])

        self.assertEqual(
            declined["result"]["decision"]["branch"],
            "IDENTITY_NAME_EVASION",
        )
        self.assertEqual(declined["observation"]["flow"]["transition"], "cancel")
        self.assertIsNone(
            declined["contextAfter"]["dialogue"].get("pendingFollowUp")
        )

    def test_topic_interrupt_and_resume_use_same_bounded_discourse_state(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["needs"]["hunger"] = 0.9
        scenario["world"]["weather"] = "rain"
        with LuaSemanticWorker(scenario) as worker:
            worker.input("do you need anything")
            worker.input("how many")
            worker.input("i will get some")
            weather = worker.input("what is the weather")
            resumed = worker.input("okay")

        weather_dialogue = weather["contextAfter"]["dialogue"]
        self.assertEqual(weather_dialogue["currentTopic"], "weather")
        self.assertEqual(weather_dialogue["previousTopic"], "needs")
        self.assertEqual(
            weather["result"]["ir"]["extensions"]["contextualFollowUp"][
                "status"
            ],
            "interrupted",
        )
        self.assertEqual(
            weather_dialogue["pendingFollowUp"]["flowID"],
            "needs",
        )

        resumed_dialogue = resumed["contextAfter"]["dialogue"]
        self.assertEqual(
            resumed["observation"]["flow"]["transition"],
            "resume_match",
        )
        self.assertEqual(resumed_dialogue["currentTopic"], "needs")
        self.assertEqual(resumed_dialogue["previousTopic"], "weather")
        self.assertEqual(
            resumed["result"]["ir"]["extensions"]["contextualFollowUp"][
                "status"
            ],
            "matched",
        )

    def test_referent_reuse_comes_from_prior_semantic_turn_not_raw_text(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["residence"] = {"label": "Riverside Camp"}
        with LuaSemanticWorker(scenario) as worker:
            worker.input("where is your home")
            follow = worker.input("what about it")

        target = follow["result"]["ir"]["target"]
        self.assertEqual(target["resolvedReference"], "IT")
        self.assertEqual(target["concept"], "NPC_RESIDENCE")
        self.assertEqual(
            follow["result"]["decision"]["response"]["selectionSource"],
            "conversation_reference",
        )
        self.assertIn(
            "Riverside Camp",
            follow["messages"][-1]["payload"]["text"],
        )

    def test_hostility_repair_transitions_one_shared_beat_state(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            hostile = worker.input("go away")
            # Use a direct hostile input if this lower-intensity utterance does
            # not enter the argument beat on the selected personality.
            if (
                hostile["observation"]["director"]
                .get("contextAfter", {})
                .get("active", {})
                .get("id")
                != "beat.argument_escalation"
            ):
                hostile = worker.input("you are useless")
            apology = worker.input("sorry")

        self.assertEqual(
            hostile["observation"]["director"]["contextAfter"]["active"]["id"],
            "beat.argument_escalation",
        )
        self.assertEqual(
            apology["observation"]["director"]["exited"]["id"],
            "beat.argument_escalation",
        )
        self.assertEqual(
            apology["observation"]["director"]["entered"]["id"],
            "beat.reconciliation",
        )
        self.assertEqual(
            apology["observation"]["director"]["contextAfter"]["active"]["id"],
            "beat.reconciliation",
        )


if __name__ == "__main__":
    unittest.main()
