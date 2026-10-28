from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


PROVIDER = "projecthoomans.generated_affordances"


def generated(turn: dict) -> list[dict]:
    return [
        row
        for row in turn["observation"]["suggestions"]["candidates"]
        if row.get("providerID") == PROVIDER
    ]


class CoherentConversationC8Tests(unittest.TestCase):
    def test_greeting_question_binds_short_reply_to_pending_interaction(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            opening = worker.input("hello")
            reply = worker.input("not really")

        self.assertEqual(generated(opening), [])
        pending = opening["contextAfter"]["dialogue"]["pendingFollowUp"]
        self.assertEqual(pending["kind"], "QUESTION")
        self.assertEqual(pending["topic"], "greeting")

        ir = reply["result"]["ir"]
        frame = ir["extensions"]["discourseFrame"]
        self.assertEqual(ir["intent"], "DISAGREE")
        self.assertEqual(ir["subject"], "greeting")
        self.assertEqual(ir["extensions"]["topic"], "greeting")
        self.assertEqual(frame["replyTo"]["kind"], "pending_interaction")
        self.assertEqual(frame["replyTo"]["flowID"], "greeting")
        self.assertEqual(frame["topic"], "greeting")
        self.assertGreater(frame["contextualSupport"], 0)
        self.assertEqual(reply["observation"]["flow"]["flowId"], "greeting")

    def test_generated_followup_replies_to_npc_answer_and_preserves_topic(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            first = worker.input("what time is it")
            followup = next(
                row for row in generated(first)
                if row["strategy"] == "ASK_FOLLOWUP"
            )
            second = worker.suggestion_click(followup["frame"])

        dynamic = followup["frame"]["extensions"]["dynamicAffordance"]
        reply_to = followup["frame"]["extensions"]["discourseFrame"]["replyTo"]
        self.assertEqual(dynamic["evidence"]["topic"], "time")
        self.assertEqual(dynamic["evidence"]["replyTo"], "npc_response_plan")
        self.assertEqual(reply_to["kind"], "npc_response_plan")
        self.assertEqual(reply_to["dialogueAct"], "INFORM")

        ir = second["result"]["ir"]
        self.assertEqual(ir["provenance"]["parser"], "semantic_click_frame")
        self.assertEqual(ir["intent"], "QUESTION")
        self.assertEqual(ir["subject"], "TIME")
        self.assertEqual(ir["extensions"]["topic"], "time")
        self.assertEqual(
            second["contextAfter"]["dialogue"]["currentTopic"],
            "time",
        )
        self.assertIn("1:30 PM", second["observation"]["response"]["text"])

    def test_hostility_then_generated_apology_enters_reconciliation_and_clears_stale_lanes(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            hostile = worker.input("fuckyouuuu")
            apology = next(
                row for row in generated(hostile)
                if row["strategy"] == "APOLOGIZE"
            )
            repaired = worker.suggestion_click(apology["frame"])

        director = repaired["observation"]["director"]
        self.assertEqual(director["exited"]["id"], "beat.argument_escalation")
        self.assertEqual(director["entered"]["id"], "beat.reconciliation")
        self.assertEqual(
            director["contextAfter"]["active"]["id"],
            "beat.reconciliation",
        )
        self.assertEqual(
            repaired["result"]["decision"]["response"]["plan"]["dialogueAct"],
            "RECONCILE",
        )
        stale = {
            row["strategy"]
            for row in generated(repaired)
        } & {"APOLOGIZE", "CHALLENGE", "DISMISS", "CALL_BLUFF"}
        self.assertEqual(stale, set())

    def test_referent_reuse_stays_grounded_without_transcript_memory(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["residence"] = {"label": "Riverside Camp"}
        with LuaSemanticWorker(scenario) as worker:
            first = worker.input("where is your home")
            followup = worker.input("what about it")

        self.assertEqual(
            first["result"]["ir"]["diagnostics"]["factStatus"],
            "known",
        )
        target = followup["result"]["ir"]["target"]
        self.assertEqual(target["resolvedReference"], "IT")
        self.assertEqual(target["concept"], "NPC_RESIDENCE")
        self.assertEqual(
            followup["result"]["decision"]["response"]["selectionSource"],
            "conversation_reference",
        )
        self.assertIn(
            "Riverside Camp",
            followup["observation"]["response"]["text"],
        )
        dialogue = followup["contextAfter"]["dialogue"]
        self.assertLessEqual(len(dialogue.get("recentTurns", [])), 12)
        self.assertNotIn("transcript", dialogue)

    def test_topic_interruption_and_resumption_share_one_bounded_state(self) -> None:
        scenario = merge(
            DEFAULT_SCENARIO,
            {
                "npc": {
                    "needs": {"hunger": 0.9},
                    "conditionStats": {},
                },
                "world": {"weather": "rain"},
            },
        )
        with LuaSemanticWorker(scenario) as worker:
            worker.input("do you need anything")
            worker.input("how many")
            worker.input("i will get some")
            weather = worker.input("what is the weather")
            resumed = worker.input("okay")

        weather_context = weather["contextAfter"]["dialogue"]
        self.assertEqual(weather_context["currentTopic"], "weather")
        self.assertEqual(weather_context["previousTopic"], "needs")
        self.assertEqual(
            weather["observation"]["flow"]["transition"],
            "interrupt_start",
        )
        self.assertEqual(
            weather_context["pendingFollowUp"]["topic"],
            "needs",
        )

        resumed_context = resumed["contextAfter"]["dialogue"]
        self.assertEqual(
            resumed["observation"]["flow"]["transition"],
            "resume_match",
        )
        self.assertEqual(resumed_context["currentTopic"], "needs")
        self.assertEqual(resumed_context["previousTopic"], "weather")
        self.assertEqual(
            resumed["result"]["ir"]["extensions"]["contextualFollowUp"][
                "status"
            ],
            "matched",
        )
        self.assertEqual(resumed["transport"], [])
        self.assertEqual(resumed["toolCalls"], [])


if __name__ == "__main__":
    unittest.main()
