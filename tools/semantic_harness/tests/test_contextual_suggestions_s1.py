"""S1 production semantic suggestion projections through the real Lua worker."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.worker import LuaSemanticWorker


class ContextualSuggestionsS1Tests(unittest.TestCase):
    def test_preview_is_bounded_repeatable_and_non_executing(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            before = worker.snapshot()
            first = worker.preview("Are you okay?")
            second = worker.preview("Are you okay?")
            after = worker.snapshot()

        for preview in (first, second):
            self.assertTrue(preview["accepted"])
            suggestions = preview["observation"]["suggestions"]
            self.assertEqual(suggestions["schemaVersion"], 1)
            self.assertLessEqual(len(suggestions["candidates"]), 5)
            self.assertTrue(suggestions["candidates"])
            self.assertEqual(preview["messages"], [])
            self.assertEqual(preview["transport"], [])
            self.assertEqual(preview["toolCalls"], [])
            self.assertTrue(preview["observation"]["sideEffects"]["none"])

        first_suggestions = first["observation"]["suggestions"]
        second_suggestions = second["observation"]["suggestions"]
        self.assertEqual(first_suggestions, second_suggestions)
        self.assertEqual(before["transcript"], after["transcript"])
        self.assertEqual(before["transport"], after["transport"])
        self.assertEqual(before["trace"], after["trace"])
        self.assertEqual(before["relationship"], after["relationship"])

        for candidate in first_suggestions["candidates"]:
            frame = candidate["frame"]
            self.assertEqual(frame["kind"], "semantic_click_frame")
            self.assertNotIn("callback", frame)
            self.assertNotIn("action", frame)

    def test_typed_and_response_plan_sources_share_stable_frames(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            result = worker.input("Are you okay?")

        suggestions = result["observation"]["suggestions"]
        self.assertEqual(suggestions["revision"], result["result"]["sequence"])
        self.assertEqual(
            suggestions["trace"][0]["source"],
            "typed_input",
        )
        self.assertEqual(
            suggestions["trace"][1]["source"],
            "npc_response_plan",
        )
        wellbeing_detail = next(
            item
            for item in suggestions["candidates"]
            if item["id"] == "question.wellbeing_detail"
        )
        self.assertEqual(wellbeing_detail["source"]["kind"], "typed_input")
        self.assertEqual(
            {source["kind"] for source in wellbeing_detail["sources"]},
            {"typed_input", "npc_response_plan"},
        )
        self.assertEqual(
            wellbeing_detail["frame"]["patternID"],
            "pnc.question.wellbeing_follow_up_what_is_wrong",
        )
        self.assertTrue(result["observation"]["sideEffects"]["none"])

    def test_suggestion_catalog_resolves_en_and_tl(self) -> None:
        for language, expected in (
            ("EN", "Ask about wellbeing"),
            ("TL", "Itanong ang kalagayan"),
        ):
            with self.subTest(language=language):
                scenario = deepcopy(DEFAULT_SCENARIO)
                scenario["runtime"]["language"] = language
                with LuaSemanticWorker(scenario) as worker:
                    result = worker.input("Are you okay?")

                labels = {
                    item["display"]["label"]
                    for item in result["observation"]["suggestions"]["candidates"]
                }
                self.assertIn(expected, labels)
                self.assertEqual(result["translation"]["language"], language)


if __name__ == "__main__":
    unittest.main()
