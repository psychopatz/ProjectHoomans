"""What's Up direct routing and authored ConversationBlock coverage."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.scenario import DEFAULT_SCENARIO


class WhatsUpConversationTests(unittest.TestCase):
    def assert_direct_opening(self, response: dict) -> dict:
        self.assertTrue(response["accepted"])
        result = response["result"]
        self.assertEqual(result["ir"]["subject"], "CONVERSATION_TOPIC")
        self.assertEqual(
            result["ir"]["extensions"]["categoryID"],
            "projecthoomans:whats_up",
        )
        observation = response["observation"]
        block = observation["conversationBlock"]
        self.assertEqual(block["nodeID"], "opening")
        self.assertTrue(block["npcText"])
        self.assertEqual(
            {choice["id"] for choice in block["choices"]},
            {"detail", "personal"},
        )
        self.assertTrue(
            any(
                message.get("text")
                for message in observation["authoritativeMessages"]
            )
        )
        candidate_ids = {
            candidate["id"]
            for candidate in observation["suggestions"]["candidates"]
        }
        self.assertNotIn("conversation.whats_up", candidate_ids)
        self.assertIn(
            "ConversationBlock",
            {
                event.get("command")
                for event in response["transport"]
                if isinstance(event, dict)
            },
        )
        return observation["conversationGraph"]

    def test_initial_root_projection_keeps_ask_whats_up_before_entry(self) -> None:
        worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
        try:
            snapshot = worker.snapshot()
            candidates = snapshot["suggestions"]["candidates"]
            root = next(
                item
                for item in candidates
                if item["id"]
                == "conversation.root:menu:projecthoomans:whats_up"
            )
            self.assertEqual(
                root["frame"]["extensions"]["origin"],
                "conversation_root",
            )
            clicked = worker.suggestion_click(root["frame"])
            self.assertTrue(clicked["accepted"])
            self.assertEqual(
                clicked["conversationBlock"]["categoryID"],
                "projecthoomans:whats_up",
            )
        finally:
            worker.close()

    def test_reviewed_aliases_enter_category_once(self) -> None:
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
                graph = self.assert_direct_opening(worker.input(value))
                self.assertEqual(graph["currentNodeID"], "opening")
                self.assertEqual(graph["entryNodeID"], "opening")
                self.assertEqual(
                    {node["id"] for node in graph["nodes"]},
                    {"opening", "details", "personal", "followup", "closing"},
                )
                self.assertTrue(graph["edges"])
                worker.reset()
        finally:
            worker.close()

    def test_bounded_fuzzy_typo_uses_direct_category_route(self) -> None:
        worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
        try:
            response = worker.input("whaat up")
            graph = self.assert_direct_opening(response)
            self.assertTrue(response["result"]["ir"]["diagnostics"]["fuzzyMatch"])
            self.assertEqual(graph["categoryID"], "projecthoomans:whats_up")
        finally:
            worker.close()

    def test_specific_routes_remain_distinct_from_whats_up(self) -> None:
        worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
        try:
            wellbeing = worker.input("what is going on with you")
            self.assertEqual(
                wellbeing["result"]["ir"]["subject"], "WELLBEING"
            )
            self.assertNotIn(
                "conversation.whats_up",
                {
                    item["id"]
                    for item in wellbeing["observation"]["suggestions"][
                        "candidates"
                    ]
                },
            )
            activity = worker.input("what have you been up to lately")
            self.assertEqual(activity["result"]["ir"]["subject"], "ACTIVITY")
            gossip = worker.input("any gossip")
            self.assertEqual(gossip["result"]["ir"]["subject"], "GOSSIP")
        finally:
            worker.close()

    def test_hostile_authority_hides_typed_category_fail_closed(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["hostility"] = {"attackPlayers": True}
        worker = LuaSemanticWorker(scenario)
        try:
            response = worker.input("whats up")
            observation = response["observation"]
            self.assertIsNone(observation.get("conversationBlock"))
            self.assertNotIn(
                "conversation.whats_up",
                {
                    item["id"]
                    for item in observation["suggestions"]["candidates"]
                },
            )
            self.assertTrue(
                any(
                    item["source"] == "typed_input"
                    and item["status"] == "hidden"
                    and item["reason"] == "no_eligible_block"
                    for item in observation["suggestions"]["trace"]
                )
            )
        finally:
            worker.close()

    def test_root_choice_and_normal_choice_replay_safely(self) -> None:
        worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
        try:
            snapshot = worker.snapshot()
            root = next(
                item
                for item in snapshot["suggestions"]["candidates"]
                if item["id"]
                == "conversation.root:menu:projecthoomans:whats_up"
            )
            entered = worker.suggestion_click(root["frame"])
            self.assertTrue(entered["accepted"])
            detail = next(
                item
                for item in entered["observation"]["suggestions"]["candidates"]
                if item["id"].endswith(":detail")
            )
            outcome = worker.suggestion_click(detail["frame"])
            self.assertTrue(outcome["accepted"])
            self.assertEqual(outcome["conversationBlock"]["nodeID"], "details")
            self.assertIn(
                "ConversationOutcome",
                {event.get("command") for event in outcome["transport"]},
            )
            replay = worker.suggestion_click(detail["frame"])
            self.assertFalse(replay["accepted"])
            self.assertEqual(replay["reason"], "suggestion_click_replayed")
            self.assertEqual(replay["transport"], [])
        finally:
            worker.close()

    def test_graph_choice_frame_matches_normal_choice_frame(self) -> None:
        button_worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
        graph_worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
        try:
            button_entry = button_worker.input("whatsup")
            button_frame = next(
                candidate["frame"]
                for candidate in button_entry["observation"]["suggestions"][
                    "candidates"
                ]
                if candidate["id"].endswith(":detail")
            )
            graph_entry = graph_worker.input("whatsup")
            graph_frame = next(
                edge["frame"]
                for edge in graph_entry["observation"]["conversationGraph"]["edges"]
                if edge["choiceID"] == "detail"
            )
            self.assertEqual(graph_frame, button_frame)
            button_result = button_worker.suggestion_click(button_frame)
            graph_result = graph_worker.suggestion_click(graph_frame)
            self.assertTrue(button_result["accepted"])
            self.assertTrue(graph_result["accepted"])
            self.assertEqual(
                button_result["conversationBlock"]["nodeID"],
                graph_result["conversationBlock"]["nodeID"],
            )
            self.assertEqual(
                [event["command"] for event in button_result["transport"]],
                [event["command"] for event in graph_result["transport"]],
            )
            self.assertEqual(
                graph_result["observation"]["conversationGraph"]["currentNodeID"],
                "details",
            )
            visited = {
                node["id"]
                for node in graph_result["observation"]["conversationGraph"]["nodes"]
                if node.get("state") == "visited"
            }
            self.assertIn("opening", visited)
        finally:
            button_worker.close()
            graph_worker.close()

    def test_tl_uses_translation_manager_for_direct_block(self) -> None:
        worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
        try:
            worker.set_language("TL")
            response = worker.input("what's up")
            graph = self.assert_direct_opening(response)
            self.assertTrue(
                any("May mga" in node["npcText"] for node in graph["nodes"])
            )
        finally:
            worker.close()

    def test_full_graph_projection_covers_several_authored_categories(self) -> None:
        for category_id in (
            "projecthoomans:wellbeing",
            "projecthoomans:small_talk",
            "projecthoomans:ask_about",
            "projecthoomans:needs",
        ):
            with self.subTest(category=category_id):
                worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
                try:
                    candidate = next(
                        item
                        for item in worker.snapshot()["suggestions"]["candidates"]
                        if (item.get("frame") or {}).get("extensions", {}).get(
                            "categoryID"
                        )
                        == category_id
                    )
                    response = worker.suggestion_click(candidate["frame"])
                    graph = response["observation"]["conversationGraph"]
                    self.assertTrue(response["accepted"])
                    self.assertEqual(graph["categoryID"], category_id)
                    self.assertTrue(graph["nodes"])
                    self.assertEqual(graph["currentNodeID"], graph["entryNodeID"])
                    self.assertTrue(
                        all("source" in node for node in graph["nodes"])
                    )
                finally:
                    worker.close()


if __name__ == "__main__":
    unittest.main()
