"""Dataset-backed what's-up root and authored conversation registry coverage."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class WhatsUpConversationTests(unittest.TestCase):
    def test_initial_root_projection_uses_production_topic_groups(self) -> None:
        worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
        try:
            snapshot = worker.snapshot()
            suggestions = snapshot["suggestions"]
            root = next(
                item
                for item in suggestions["candidates"]
                if item["id"]
                == "conversation.root:menu:projecthoomans:whats_up"
            )
            self.assertEqual(
                root["frame"]["extensions"]["origin"],
                "conversation_root",
            )
            self.assertEqual(
                root["frame"]["extensions"]["categoryID"],
                "projecthoomans:whats_up",
            )
            self.assertIn(
                "topic:whats_up",
                {group["id"] for group in suggestions["groups"]},
            )
            clicked = worker.suggestion_click(root["frame"])
            self.assertTrue(clicked["accepted"])
            self.assertEqual(
                clicked["conversationBlock"]["categoryID"],
                "projecthoomans:whats_up",
            )
        finally:
            worker.close()

    def test_reviewed_aliases_use_one_typed_category_route(self) -> None:
        aliases = (
            "what's up",
            "whats up",
            "what is up",
            "what up",
            "whatsup",
            "what's new",
            "whats new",
            "anything new",
            "what's happening",
            "whats happening",
            "anything going on",
        )
        worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
        try:
            for value in aliases:
                response = worker.input(value)
                result = response["result"]
                self.assertTrue(response["accepted"], value)
                self.assertEqual(result["ir"]["subject"], "CONVERSATION_TOPIC")
                self.assertEqual(
                    result["ir"]["extensions"]["categoryID"],
                    "projecthoomans:whats_up",
                )
                candidate = next(
                    item
                    for item in response["observation"]["suggestions"]["candidates"]
                    if item["id"] == "conversation.whats_up"
                )
                self.assertEqual(
                    candidate["frame"]["extensions"]["route"],
                    "conversation_category",
                )
                mapping = result["candidates"]["selected"]["metadata"].get(
                    "mapping",
                    result["candidates"]["selected"]["metadata"],
                )
                self.assertEqual(mapping["canonicalConcept"], "WHATS_UP")
                worker.reset()
        finally:
            worker.close()

    def test_bounded_fuzzy_typo_uses_the_same_root_without_action_side_effects(self) -> None:
        worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
        try:
            response = worker.input("whaat up")
            result = response["result"]
            self.assertTrue(response["accepted"])
            self.assertEqual(result["ir"]["subject"], "CONVERSATION_TOPIC")
            self.assertTrue(result["ir"]["diagnostics"]["fuzzyMatch"])
            self.assertEqual(
                result["candidateDiagnostics"]["selectedPattern"],
                "pnc.question.whats_up.concept",
            )
            self.assertEqual(result["candidateDiagnostics"]["selectedPass"], "fuzzy")
            self.assertEqual(response["transport"], [])
            self.assertIn(
                "conversation.whats_up",
                [
                    item["id"]
                    for item in response["observation"]["suggestions"]["candidates"]
                ],
            )
        finally:
            worker.close()

    def test_specific_routes_remain_distinct_from_root(self) -> None:
        worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
        try:
            wellbeing = worker.input("what is going on with you")
            self.assertEqual(wellbeing["result"]["ir"]["subject"], "WELLBEING")
            self.assertNotIn(
                "conversation.whats_up",
                [item["id"] for item in wellbeing["observation"]["suggestions"]["candidates"]],
            )
            activity = worker.input("what have you been up to lately")
            self.assertEqual(activity["result"]["ir"]["subject"], "ACTIVITY")
            gossip = worker.input("any gossip")
            self.assertEqual(gossip["result"]["ir"]["subject"], "GOSSIP")
        finally:
            worker.close()

    def test_hostile_authority_hides_root_category_fail_closed(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["hostility"] = {"attackPlayers": True}
        worker = LuaSemanticWorker(scenario)
        try:
            response = worker.input("whats up")
            ids = {
                item["id"]
                for item in response["observation"]["suggestions"]["candidates"]
            }
            self.assertNotIn("conversation.whats_up", ids)
            self.assertTrue(
                any(
                    item["source"] == "typed_input"
                    and item["status"] == "hidden"
                    and item["reason"] == "no_eligible_block"
                    for item in response["observation"]["suggestions"]["trace"]
                )
            )
        finally:
            worker.close()

    def test_root_click_enters_authored_block_and_choice_replays_safely(self) -> None:
        worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
        try:
            root = worker.input("whats up")
            root_candidate = next(
                item
                for item in root["observation"]["suggestions"]["candidates"]
                if item["id"] == "conversation.whats_up"
            )
            clicked = worker.suggestion_click(root_candidate["frame"])
            block = clicked["conversationBlock"]
            self.assertTrue(clicked["accepted"])
            self.assertEqual(block["categoryID"], "projecthoomans:whats_up")
            self.assertIn(
                block["blockID"].split("whats_up_", 1)[-1].rsplit("_", 1)[0],
                {"local_activity", "supply_pressure", "survivor_rumors"},
            )
            self.assertEqual(block["topic"], "whats_up")
            self.assertEqual(
                [event["command"] for event in clicked["transport"]],
                ["ConversationBlock"],
            )
            detail = next(
                item
                for item in clicked["observation"]["suggestions"]["candidates"]
                if item["id"].endswith(":detail")
            )
            outcome = worker.suggestion_click(detail["frame"])
            self.assertTrue(outcome["accepted"])
            self.assertEqual(
                [event["command"] for event in outcome["transport"]],
                ["ConversationOutcome"],
            )
            self.assertEqual(outcome["conversationBlock"]["nodeID"], "details")
            duplicate = worker.suggestion_click(detail["frame"])
            self.assertFalse(duplicate["accepted"])
            self.assertEqual(duplicate["reason"], "suggestion_click_replayed")
            self.assertEqual(duplicate["transport"], [])
        finally:
            worker.close()

    def test_tl_uses_existing_translation_manager_for_root_and_block(self) -> None:
        worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
        try:
            worker.set_language("TL")
            response = worker.input("what's up")
            candidate = next(
                item
                for item in response["observation"]["suggestions"]["candidates"]
                if item["id"] == "conversation.whats_up"
            )
            self.assertEqual(candidate["display"]["label"], "Itanong kung ano ang balita")
            clicked = worker.suggestion_click(candidate["frame"])
            self.assertIn("May mga", clicked["conversationBlock"]["npcText"])
        finally:
            worker.close()


if __name__ == "__main__":
    unittest.main()
