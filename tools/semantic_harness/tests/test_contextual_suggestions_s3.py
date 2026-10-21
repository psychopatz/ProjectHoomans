"""S3 canonical suggestion clicks through the production dialogue path."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.worker import LuaSemanticWorker


class ContextualSuggestionsS3Tests(unittest.TestCase):
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
