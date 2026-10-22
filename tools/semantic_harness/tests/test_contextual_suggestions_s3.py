"""S3 canonical suggestion clicks through the production dialogue path."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class ContextualSuggestionsS3Tests(unittest.TestCase):
    def test_semantic_question_click_appends_one_player_turn(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            typed = worker.input("Are you okay?")
            frame = next(
                candidate["frame"]
                for candidate in typed["observation"]["suggestions"]["candidates"]
                if candidate["id"] == "question.needs"
            )
            before = worker.snapshot()
            click = worker.suggestion_click(frame)
            after = worker.snapshot()

        self.assertTrue(click["accepted"])
        new_player_rows = [
            row
            for row in after["transcript"]
            if row.get("speaker") == "player"
        ][len([row for row in before["transcript"] if row.get("speaker") == "player"]):]
        self.assertEqual(len(new_player_rows), 1)
        self.assertEqual(new_player_rows[0]["value"], "Do you need anything?")

    def test_topic_group_click_reuses_core_surface_without_turn_or_effect(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            result = worker.input("what time is it")
            group = next(
                item
                for item in result["observation"]["suggestions"]["groups"]
                if item["id"] == "owned_actions"
            )
            before = worker.snapshot()
            clicked = worker.suggestion_click(group["frame"])
            after = worker.snapshot()
            duplicate = worker.suggestion_click(group["frame"])
            after_duplicate = worker.snapshot()

        self.assertTrue(clicked["accepted"])
        self.assertEqual(clicked["messages"], [])
        self.assertEqual(clicked["transport"], [])
        self.assertEqual(before["transcript"], after["transcript"])
        self.assertEqual(
            clicked["observation"]["suggestions"]["currentGroupID"],
            "owned_actions",
        )
        self.assertEqual(
            clicked["choiceSurface"]["source"],
            "semantic_suggestions",
        )
        self.assertFalse(duplicate["accepted"])
        self.assertEqual(duplicate["reason"], "suggestion_click_replayed")
        self.assertEqual(after["transcript"], after_duplicate["transcript"])
        self.assertEqual(after["transport"], after_duplicate["transport"])

    def test_question_click_reuses_canonical_ir_without_a_second_parser(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            typed = worker.input("Are you okay?")
            frame = next(
                candidate["frame"]
                for candidate in typed["observation"]["suggestions"]["candidates"]
                if candidate["id"] == "question.needs"
            )
            click = worker.suggestion_click(frame)

        self.assertTrue(click["accepted"])
        ir = click["result"]["ir"]
        self.assertEqual(ir["kind"], "semantic_suggestion_frame")
        self.assertEqual(ir["provenance"]["parser"], "semantic_click_frame")
        self.assertEqual(ir["provenance"]["candidateID"], "question.needs")
        self.assertIsNone(click["result"].get("actionResult"))
        self.assertEqual(click["toolCalls"], [])

    def test_dynamic_response_branch_click_uses_canonical_ir_and_replays_safely(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            result = worker.input("hello")
            candidate = next(
                item
                for item in result["observation"]["suggestions"]["candidates"]
                if item["id"] == "greeting.check_in.report_wellbeing"
            )
            click = worker.suggestion_click(candidate["frame"])
            before_duplicate = worker.snapshot()
            duplicate = worker.suggestion_click(candidate["frame"])
            after_duplicate = worker.snapshot()

        self.assertTrue(click["accepted"])
        ir = click["result"]["ir"]
        self.assertEqual(ir["kind"], "semantic_suggestion_frame")
        self.assertEqual(ir["intent"], "INFORM")
        self.assertEqual(ir["subject"], "WELLBEING")
        self.assertEqual(ir["slots"]["state"]["value"], "fine")
        self.assertEqual(ir["provenance"]["parser"], "semantic_click_frame")
        self.assertEqual(
            ir["provenance"]["branchOfferID"],
            "greeting.check_in.report_wellbeing",
        )
        self.assertIsNone(click["result"].get("actionResult"))
        self.assertEqual(click["toolCalls"], [])
        self.assertEqual(click["transport"], [])
        self.assertIn(
            "You're welcome. Take care.",
            [message["payload"]["text"] for message in click["messages"]],
        )
        self.assertFalse(duplicate["accepted"])
        self.assertEqual(duplicate["reason"], "duplicate_suggestion")
        self.assertEqual(before_duplicate["transcript"], after_duplicate["transcript"])
        self.assertEqual(before_duplicate["trace"], after_duplicate["trace"])

    def test_dynamic_flow_branch_click_transitions_existing_flow(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            result = worker.input("hello")
            candidate = next(
                item
                for item in result["observation"]["suggestions"]["candidates"]
                if item["id"] == "greeting.thanks"
            )
            click = worker.suggestion_click(candidate["frame"])

        self.assertTrue(click["accepted"])
        self.assertEqual(click["result"]["ir"]["intent"], "THANK")
        self.assertEqual(click["result"]["flow"]["toNodeId"], "complete")
        self.assertEqual(click["toolCalls"], [])
        self.assertEqual(click["transport"], [])

    def test_stale_click_is_rejected_without_mutation(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            first = worker.input("Are you okay?")
            frame = next(
                candidate["frame"]
                for candidate in first["observation"]["suggestions"]["candidates"]
                if candidate["id"] == "question.needs"
            )
            worker.input("What happened?")
            before = worker.snapshot()
            stale = worker.suggestion_click(frame)
            after = worker.snapshot()

        self.assertFalse(stale["accepted"])
        self.assertEqual(stale["reason"], "stale_suggestion")
        self.assertEqual(before["transcript"], after["transcript"])
        self.assertEqual(before["transport"], after["transport"])
        self.assertEqual(before["trace"], after["trace"])

    def test_duplicate_click_is_deduplicated_without_a_second_turn(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            result = worker.input("Are you okay?")
            frame = next(
                candidate["frame"]
                for candidate in result["observation"]["suggestions"]["candidates"]
                if candidate["id"] == "question.needs"
            )
            first = worker.suggestion_click(frame)
            before = worker.snapshot()
            duplicate = worker.suggestion_click(frame)
            after = worker.snapshot()

        self.assertTrue(first["accepted"])
        self.assertFalse(duplicate["accepted"])
        self.assertEqual(duplicate["reason"], "duplicate_suggestion")
        self.assertEqual(before["transcript"], after["transcript"])
        self.assertEqual(before["transport"], after["transport"])
        self.assertEqual(before["trace"], after["trace"])

    def test_follow_click_uses_existing_action_dispatch_and_wait_at_fails_closed(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            result = worker.input("Are you okay?")
            capabilities = {
                row["action"]: row
                for row in result["observation"]["suggestions"][
                    "permittedCapabilities"
                ]
            }
            follow = worker.suggestion_click(capabilities["FOLLOW"]["frame"])

        self.assertTrue(follow["accepted"])
        self.assertEqual(follow["result"]["ir"]["action"], "FOLLOW")
        self.assertEqual(
            follow["result"]["actionResult"]["capabilityID"],
            "pnc:companion.follow",
        )
        self.assertEqual(len(follow["transport"]), 1)
        self.assertEqual(follow["transport"][0]["command"], "CompanionCommand")

        wait_scenario = deepcopy(DEFAULT_SCENARIO)
        with LuaSemanticWorker(wait_scenario) as worker:
            result = worker.input("Are you okay?")
            wait = next(
                row
                for row in result["observation"]["suggestions"][
                    "permittedCapabilities"
                ]
                if row["action"] == "WAIT_AT"
            )
            before = worker.snapshot()
            rejected = worker.suggestion_click(wait["frame"])
            after = worker.snapshot()

        self.assertFalse(rejected["accepted"])
        self.assertEqual(
            rejected["reason"],
            "suggestion_click_ineligible_unknown",
        )
        self.assertEqual(before["transport"], after["transport"])
        self.assertEqual(before["trace"], after["trace"])


if __name__ == "__main__":
    unittest.main()
