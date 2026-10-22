"""Corrective dynamic-topic and owned-action suggestion coverage."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.ui.shell import semantic_suggestion_rows
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class ContextualSuggestionsFollowupTests(unittest.TestCase):
    def test_time_topic_is_grouped_without_generic_social_questions(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            response = worker.input("what time is it")

        suggestions = response["observation"]["suggestions"]
        self.assertEqual(suggestions["currentTopic"], "time")
        self.assertEqual(suggestions["currentGroupID"], "topic:time")
        self.assertEqual(
            [candidate["id"] for candidate in suggestions["candidates"]],
            ["question.time", "question.date"],
        )
        rows = semantic_suggestion_rows(suggestions)
        self.assertEqual([row["id"] for row in rows], [
            "question.time",
            "question.date",
        ])
        self.assertEqual(
            [group["id"] for group in suggestions["groups"]],
            ["topic:time", "owned_actions"],
        )

    def test_unowned_npc_has_no_discoverable_companion_actions(self) -> None:
        scenario = merge(
            DEFAULT_SCENARIO,
            {
                "npc": {
                    "actorAuthority": {
                        "companion": False,
                        "owned": False,
                        "eligible": False,
                    }
                }
            },
        )
        with LuaSemanticWorker(scenario) as worker:
            response = worker.input("hello")

        suggestions = response["observation"]["suggestions"]
        self.assertEqual(suggestions["permittedCapabilities"], [])
        self.assertFalse(
            any(
                candidate.get("action") in {"FOLLOW", "STAY", "WAIT_AT"}
                for candidate in suggestions["candidates"]
            )
        )
        self.assertTrue(
            any(
                row["path"] == "actorAuthority" and row["status"] == "hidden"
                for row in suggestions["predicateTrace"]
            )
        )

    def test_time_suggestion_click_uses_canonical_question_route(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            first = worker.input("what time is it")
            time_candidate = next(
                candidate
                for candidate in first["observation"]["suggestions"][
                    "candidates"
                ]
                if candidate["id"] == "question.time"
            )
            clicked = worker.suggestion_click(time_candidate["frame"])

        self.assertTrue(clicked["accepted"])
        self.assertEqual(clicked["result"]["ir"]["subject"], "TIME")
        self.assertEqual(clicked["messages"][-1]["payload"]["text"], "It's 1:30 PM.")
        self.assertEqual(clicked["transport"], [])

    def test_accepted_follow_refreshes_current_state_and_action_surface(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            first = worker.input("hello")
            follow = next(
                row
                for row in first["observation"]["suggestions"][
                    "permittedCapabilities"
                ]
                if row["action"] == "FOLLOW"
            )
            clicked = worker.suggestion_click(follow["frame"])

        self.assertTrue(clicked["accepted"])
        self.assertEqual(len(clicked["transport"]), 1)
        statuses = {
            row["action"]: row["status"]
            for row in clicked["observation"]["suggestions"][
                "permittedCapabilities"
            ]
        }
        self.assertEqual(statuses["FOLLOW"], "unavailable_rejected")
        self.assertEqual(statuses["STAY"], "eligible")


if __name__ == "__main__":
    unittest.main()
