"""P11J native Talk target parity coverage."""

from __future__ import annotations

from copy import deepcopy
import json
import os
from pathlib import Path
import time
import tkinter as tk
import unittest

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.runtime.npc_profiles import apply_npc_profile
from tools.semantic_harness.runtime.config import discover_newest_runtime
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.ui.shell import SemanticHarnessApp
from tools.semantic_harness.ui.suggestion_projection import (
    conversation_presented_rows,
    npc_message_text,
)


class ContextualTalkParityP11JTests(unittest.TestCase):
    def test_p10h_production_native_conversation_parity_record(self) -> None:
        """Compare the complete primary surface to one production session.

        This deliberately compares production Lua's presentation projection
        with the thin Tk adapter.  It must not derive a choice group or
        candidate policy from the diagnostic/global suggestion projection.
        """

        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            opened = worker.open_conversation()
            production = opened["presentation"]
            channel = production["responseChannel"]
            relation = production["relationPresentation"]
            typed = production["semanticInput"]
            adapter_rows = conversation_presented_rows(production)
            production_rows = channel["rows"]

            self.assertEqual(
                production["schema"], "semantic.native_conversation_view.v1"
            )
            self.assertEqual(production["source"], "PNC.Conversation.TalkParity")
            self.assertEqual(production["talkStart"]["schema"], "semantic.talk.start.projection.v1")
            self.assertEqual(production["opening"]["nodeID"], "greeting")
            self.assertTrue(production["opening"]["messages"])
            opening_message = production["opening"]["messages"][0]
            self.assertTrue(opening_message.get("text"))
            self.assertEqual(
                npc_message_text(opening_message), opening_message["text"]
            )
            self.assertEqual(relation["source"], "PNC.Conversation.Relationship")
            self.assertTrue(relation["visible"])
            self.assertTrue(typed["available"])
            self.assertEqual(
                channel["choiceSurface"]["revision"], channel["revision"]
            )
            self.assertEqual(
                channel["choiceSurface"]["presentedCount"], len(production_rows)
            )
            self.assertEqual(
                [row["id"] for row in adapter_rows],
                [row["id"] for row in production_rows],
            )
            self.assertEqual(
                [row["text"] for row in adapter_rows],
                [row["text"] for row in production_rows],
            )
            self.assertEqual(
                [row["enabled"] for row in adapter_rows],
                [row["enabled"] for row in production_rows],
            )
            self.assertEqual(
                [row["semanticFrame"] for row in adapter_rows],
                [row["semanticFrame"] for row in production_rows],
            )

            clicked_row = next(row for row in production_rows if row["enabled"])
            clicked = worker.suggestion_click(clicked_row["semanticFrame"])
            next_presentation = clicked["conversationPresentation"]
            next_channel = next_presentation["responseChannel"]
            self.assertTrue(clicked["accepted"])
            self.assertEqual(
                clicked["choiceSurface"], next_channel["choiceSurface"]
            )
            self.assertEqual(
                clicked["conversationPresentation"],
                worker.snapshot()["conversationPresentation"],
            )
            self.assertNotEqual(
                [row["id"] for row in production_rows],
                [row["id"] for row in next_channel["rows"]],
            )

        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.open_conversation()
            before = worker.snapshot()["conversationPresentation"]
            suspended = worker.suspend_conversation()["presentation"]
            self.assertEqual(suspended["lifecycle"]["state"], "suspended")
            self.assertEqual(suspended["responseChannel"]["rows"], [])
            self.assertEqual(
                suspended["responseChannel"]["groupID"],
                before["responseChannel"]["groupID"],
            )
            resumed = worker.resume_conversation()["presentation"]
            self.assertEqual(resumed["lifecycle"]["state"], "active")
            self.assertEqual(
                resumed["responseChannel"]["groupID"],
                before["responseChannel"]["groupID"],
            )
            self.assertEqual(
                resumed["responseChannel"]["revision"],
                before["responseChannel"]["revision"],
            )
            goodbye = next(
                row
                for row in resumed["responseChannel"]["rows"]
                if row["id"].endswith(":goodbye")
            )
            closed = worker.suggestion_click(goodbye["semanticFrame"])
            self.assertTrue(closed["accepted"])
            self.assertEqual(
                closed["conversationPresentation"]["lifecycle"]["state"],
                "closed",
            )
            self.assertEqual(
                closed["conversationPresentation"]["responseChannel"]["rows"],
                [],
            )

    def test_catalog_is_production_owned_and_truthful(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            catalog = worker.talk_catalog()

        self.assertEqual(catalog["schema"], "semantic.talk.catalog.v1")
        self.assertEqual(
            [row["id"] for row in catalog["targets"]],
            ["current", "colonist", "follower", "neutral", "hostile"],
        )
        self.assertEqual(
            next(row for row in catalog["targets"] if row["id"] == "hostile")["label"],
            "Hostile / Enemy",
        )

    def test_matrix_uses_native_target_facts_and_restores_base_scenario(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        with LuaSemanticWorker(scenario) as worker:
            matrix = worker.talk_matrix(text="hello")
            restored = worker.snapshot()["scenario"]

        rows = {row["target"]["id"]: row for row in matrix["rows"]}
        self.assertEqual(
            {row["target"]["targetType"] for row in rows.values()},
            {"colonist", "follower", "neutral", "hostile"},
        )
        self.assertEqual(rows["colonist"]["target"]["route"], "full_conversation")
        self.assertEqual(rows["follower"]["target"]["targetType"], "follower")
        self.assertEqual(rows["neutral"]["target"]["audience"], "neutral")
        self.assertEqual(rows["hostile"]["target"]["audience"], "hostile")
        self.assertEqual(rows["hostile"]["target"]["route"], "hostile_full_conversation")
        self.assertEqual(rows["hostile"]["runtimeGraphPath"]["kind"], "semantic_flow")
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as navigation_worker:
            navigation_worker.open_conversation()
            root_channel = navigation_worker.conversation_projection()["presentation"]["responseChannel"]
            orders = navigation_worker.suggestion_click(
                next(
                    choice
                    for choice in root_channel["rows"]
                    if choice["id"] == "companion.orders:open"
                )["frame"]
            )
            order_ids = {
                choice["id"]
                for choice in orders["conversationPresentation"]["responseChannel"]["rows"]
            }
        self.assertIn(
            "action.follow",
            order_ids,
        )
        self.assertIn(
            "conversation.root:menu:ceasefire",
            {choice["id"] for choice in rows["hostile"]["start"]["opening"]["choices"]},
        )
        self.assertNotIn("semanticLabTalkTarget", restored["runtime"])

    def test_native_and_harness_enter_the_shared_talk_start_projection(self) -> None:
        project = Path(__file__).resolve().parents[3]
        runtime = discover_newest_runtime(project / "Contents/mods/ProjectHoomans")
        conversation_root = (
            project
            / "Contents/mods/ProjectHoomans"
            / runtime
            / "media/lua/client/PNC/Conversation"
        )
        lifecycle = (
            conversation_root
            / "Definition/PNC_ConversationDefinition_Lifecycle.lua"
        ).read_text()
        builder = (
            conversation_root
            / "Definition/PNC_ConversationDefinition_Builder.lua"
        ).read_text()
        parity = (
            conversation_root / "PNC_ConversationTalkParity.lua"
        ).read_text()
        targets = (
            conversation_root / "PNC_ConversationTalkParity_Targets.lua"
        ).read_text()
        lifecycle_open = (
            conversation_root
            / "Definition/PNC_ConversationDefinition_Lifecycle_Open.lua"
        ).read_text()

        self.assertIn(
            "PNC/Conversation/Definition/PNC_ConversationDefinition_Lifecycle_Open",
            lifecycle,
        )
        self.assertIn("TalkStart.Project(entry, player", lifecycle_open)
        self.assertIn("TalkStart.Project(entry,", builder)
        self.assertIn("TalkStart.Project(", parity + targets)
        self.assertNotIn("palette.ResolveType", parity)
        self.assertNotIn("audience.Resolve", parity)

        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            result = worker.talk_start(target_id="hostile", utterance="hello")

        projection = result["start"]["target"]
        self.assertEqual(projection["schema"], "semantic.talk.start.projection.v1")
        self.assertEqual(projection["route"], "hostile_full_conversation")
        self.assertEqual(projection["targetType"], "hostile")
        self.assertEqual(projection["tacticalClass"], "hostile")
        self.assertEqual(projection["opening"]["nodeID"], "greeting")

    def test_production_projection_exposes_exact_presented_session_rows(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            loaded = worker.snapshot()
            opened = worker.open_conversation()
            snapshot = worker.snapshot()
            response = worker.conversation_projection()

        self.assertEqual(
            loaded["conversationPresentation"]["lifecycle"]["state"],
            "loaded",
        )
        self.assertEqual(
            loaded["conversationPresentation"]["responseChannel"]["rows"],
            [],
        )
        self.assertEqual(opened["type"], "conversation_open")

        presentation = snapshot["conversationPresentation"]
        self.assertEqual(
            presentation["schema"],
            "semantic.native_conversation_view.v1",
        )
        self.assertEqual(
            response["presentation"],
            presentation,
        )
        rows = presentation["responseChannel"]["rows"]
        choice_surface = snapshot["choiceSurface"]
        suggestions = snapshot["suggestions"]
        self.assertEqual(
            len(rows),
            choice_surface["presentedCount"],
        )
        self.assertEqual(
            presentation["responseChannel"]["groupID"],
            suggestions["currentGroupID"],
        )
        self.assertEqual(
            presentation["responseChannel"]["revision"],
            choice_surface["revision"],
        )
        self.assertTrue(presentation["opening"]["messages"])
        self.assertTrue(presentation["semanticInput"]["available"])
        self.assertIn(
            presentation["lifecycle"]["state"],
            {"opening", "active"},
        )
        self.assertEqual(
            [row["id"] for row in rows],
            [row["id"] for row in rows if row["semanticFrame"] is not None],
        )
        self.assertTrue(all("enabled" in row for row in rows))

    def test_open_returns_bounded_projection_for_large_saved_world(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario.setdefault("world", {})["saveBackedDiagnostic"] = "x" * 120_000
        with LuaSemanticWorker(scenario) as worker:
            opened = worker.open_conversation()

        encoded = json.dumps(
            opened, ensure_ascii=False, separators=(",", ":")
        ).encode("utf-8")
        self.assertLess(len(encoded), 256 * 1024)
        self.assertNotIn("configured", opened)
        self.assertNotIn("snapshot", opened)
        self.assertEqual(
            opened["presentation"]["schema"],
            "semantic.native_conversation_view.v1",
        )

    def test_primary_renderer_adapter_preserves_production_row_order_and_frames(
        self,
    ) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.open_conversation()
            presentation = worker.snapshot()["conversationPresentation"]

        rows = conversation_presented_rows(presentation)
        production_rows = presentation["responseChannel"]["rows"]
        self.assertEqual(
            [row["id"] for row in rows],
            [row["id"] for row in production_rows],
        )
        self.assertEqual(
            [row["frame"] for row in rows],
            [row["semanticFrame"] for row in production_rows],
        )
        self.assertEqual(
            [row["enabled"] for row in rows],
            [row["enabled"] for row in production_rows],
        )

    def test_primary_click_uses_exact_production_frame_and_reprojects(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            opened = worker.open_conversation()
            before = opened["presentation"]
            row = next(
                row for row in before["responseChannel"]["rows"]
                if row["enabled"] is True
            )
            clicked = worker.suggestion_click(row["semanticFrame"])
            after = worker.snapshot()["conversationPresentation"]

        self.assertTrue(clicked["accepted"])
        self.assertEqual(clicked["type"], "semantic_click")
        self.assertEqual(
            clicked["conversationPresentation"],
            after,
        )
        self.assertNotEqual(
            before["responseChannel"]["rows"],
            after["responseChannel"]["rows"],
        )
        self.assertEqual(
            clicked["choiceSurface"],
            after["responseChannel"]["choiceSurface"],
        )

    def test_production_frame_rejection_is_stale_or_replayed_without_mutation(
        self,
    ) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            opened = worker.open_conversation()
            frame = next(
                row["semanticFrame"]
                for row in opened["presentation"]["responseChannel"]["rows"]
                if row["enabled"] is True
            )
            accepted = worker.suggestion_click(frame)
            before_duplicate = worker.snapshot()
            duplicate = worker.suggestion_click(frame)
            after_duplicate = worker.snapshot()

        self.assertTrue(accepted["accepted"])
        self.assertFalse(duplicate["accepted"])
        self.assertEqual(duplicate["reason"], "suggestion_click_replayed")
        self.assertEqual(
            before_duplicate["transcript"], after_duplicate["transcript"]
        )
        self.assertEqual(
            before_duplicate["conversationPresentation"],
            after_duplicate["conversationPresentation"],
        )

    def test_unpresented_production_frame_is_rejected_without_mutation(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            opened = worker.open_conversation()
            frame = deepcopy(
                next(
                    row["semanticFrame"]
                    for row in opened["presentation"]["responseChannel"]["rows"]
                    if row["enabled"] is True
                )
            )
            frame["candidateID"] = "conversation.root:menu:not-presented"
            before = worker.snapshot()
            rejected = worker.suggestion_click(frame)
            after = worker.snapshot()

        self.assertFalse(rejected["accepted"])
        self.assertEqual(rejected["reason"], "suggestion_not_presented")
        self.assertEqual(before["transcript"], after["transcript"])
        self.assertEqual(
            before["conversationPresentation"],
            after["conversationPresentation"],
        )

    def test_close_and_explicit_reopen_follow_the_same_production_session(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            opened = worker.open_conversation()
            goodbye = next(
                row for row in opened["presentation"]["responseChannel"]["rows"]
                if row["id"].endswith(":goodbye")
            )
            closed_response = worker.suggestion_click(
                goodbye["semanticFrame"]
            )
            closed = worker.snapshot()["conversationPresentation"]
            reopened_response = worker.open_conversation()
            reopened = worker.snapshot()["conversationPresentation"]

        self.assertTrue(closed_response["accepted"])
        self.assertEqual(closed["lifecycle"]["state"], "closed")
        self.assertTrue(closed["lifecycle"]["closed"])
        self.assertFalse(closed["semanticInput"]["available"])
        self.assertEqual(closed["responseChannel"]["rows"], [])
        self.assertEqual(reopened_response["type"], "conversation_open")
        self.assertIn(reopened["lifecycle"]["state"], {"opening", "active"})
        self.assertTrue(reopened["semanticInput"]["available"])
        self.assertTrue(reopened["responseChannel"]["rows"])

    def test_typed_emote_suspend_resume_share_the_production_semantic_state(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            opened = worker.open_conversation()
            typed = worker.input("What's up?")
            before = worker.snapshot()["conversationPresentation"]
            speech = worker.interaction_npc_speech(
                {
                    "npcID": DEFAULT_SCENARIO["npc"]["npcID"],
                    "act": "REQUEST",
                    "topic": "water",
                    "beatID": "beat:water",
                    "responsePlanID": "plan:water",
                }
            )
            transcript_before_emote = len(
                worker.snapshot()["transcript"]
            )
            emote = worker.conversation_emote(
                "thumbsup", topic="water", meaningful=True
            )
            suspended = worker.suspend_conversation()
            resumed = worker.resume_conversation()

        self.assertTrue(typed["accepted"])
        self.assertTrue(speech["result"]["accepted"])
        self.assertTrue(emote["accepted"])
        self.assertEqual(emote["envelope"]["source"], "emote")
        self.assertEqual(emote["envelope"]["act"], "ACK")
        self.assertEqual(
            emote["realization"]["realizationID"],
            "semantic.emote.reply.thumbsup.active",
        )
        self.assertTrue(emote["speech"]["accepted"])
        delivered = [
            message for message in emote["snapshot"]["transcript"]
            [transcript_before_emote:]
            if message.get("speaker") == "npc"
        ]
        self.assertEqual(len(delivered), 1)
        self.assertEqual(delivered[0]["payload"]["text"],
                         "Good. Let's keep moving on this.")
        self.assertEqual(
            emote["interaction"]["thread"]["activeBeat"]["id"],
            "beat:water",
        )
        self.assertEqual(suspended["type"], "conversation_suspend")
        self.assertEqual(
            suspended["presentation"]["lifecycle"]["state"],
            "suspended",
        )
        self.assertEqual(
            suspended["presentation"]["responseChannel"]["groupID"],
            before["responseChannel"]["groupID"],
        )
        self.assertEqual(
            suspended["presentation"]["responseChannel"]["rows"],
            [],
        )
        self.assertEqual(resumed["type"], "conversation_resume")
        self.assertEqual(
            resumed["presentation"]["responseChannel"]["groupID"],
            before["responseChannel"]["groupID"],
        )
        self.assertTrue(resumed["presentation"]["responseChannel"]["rows"])
        self.assertEqual(
            resumed["snapshot"]["interactionLifecycle"]["thread"]
            ["activeBeat"]["id"],
            "beat:water",
        )

    def test_landing_projection_keeps_shortcut_and_back_target_after_hub_turn(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            result = worker.talk_start(
                target_id="neutral", utterance="What's up?"
            )

        projection = result["snapshot"]["suggestions"]
        self.assertEqual(projection["rootGroupID"], "conversation_landing")
        self.assertEqual(projection["currentGroupID"], "semantic_hub.whats_up")
        root = next(
            group for group in projection["groups"]
            if group["id"] == "conversation_landing"
        )
        shortcut = next(
            candidate for candidate in root["candidates"]
            if candidate["id"] == "conversation.landing:whats_up"
        )
        self.assertEqual(
            shortcut["frame"]["kind"], "semantic_shortcut_frame"
        )
        self.assertEqual(shortcut["frame"]["textFallback"], "What's up?")
        hub = next(
            group for group in projection["groups"]
            if group["id"] == "semantic_hub.whats_up"
        )
        self.assertTrue(hub["allowBack"])
        self.assertEqual(
            hub["navigation"][0]["display"]["label"],
            "Let's talk something else",
        )
        self.assertEqual(
            hub["navigation"][0]["frame"]["kind"],
            "semantic_back_click_frame",
        )

    def test_owned_companion_uses_known_identity_policy(self) -> None:
        scenario = apply_npc_profile(deepcopy(DEFAULT_SCENARIO), "companion")
        with LuaSemanticWorker(scenario) as worker:
            root = worker.snapshot()["suggestions"]
            turn = worker.input("What's your name?")

        root_ids = {
            candidate["id"] for candidate in root.get("candidates", [])
        }
        self.assertNotIn("question.identity", root_ids)
        queued = (turn["observation"]["response"].get("queued") or [])
        self.assertTrue(queued)
        self.assertEqual(
            turn["observation"]["response"]["templateID"],
            "semantic.question.identity.known",
        )
        self.assertIn("already know each other", queued[0]["text"])

    def test_talk_something_else_returns_to_landing_with_navigation_reply(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            started = worker.talk_start(
                target_id="neutral", utterance="What's up?"
            )
            suggestions = started["snapshot"]["suggestions"]
            group = next(
                group
                for group in suggestions["groups"]
                if group["id"] == suggestions["currentGroupID"]
            )
            frame = group["navigation"][0]["frame"]
            before = worker.snapshot()
            clicked = worker.suggestion_click(frame)

            self.assertTrue(clicked["accepted"])
            self.assertEqual(
                clicked["observation"]["suggestions"]["currentGroupID"],
                "conversation_landing",
            )
            self.assertEqual(len(clicked["transcriptMessages"]), 2)
            self.assertEqual(clicked["transcriptMessages"][0]["speaker"], "player")
            self.assertEqual(
                clicked["transcriptMessages"][0]["value"],
                frame["textFallback"],
            )
            self.assertEqual(clicked["transcriptMessages"][1]["speaker"], "npc")
            self.assertEqual(len(clicked["messages"]), 1)
            self.assertEqual(clicked["messages"][0]["speaker"], "npc")
            self.assertIn(
                "talk",
                str(clicked["messages"][0]["payload"].get("text", "")).lower(),
            )
            self.assertGreater(
                clicked["contextAfter"]["dialogue"]["sequence"],
                before["context"]["dialogue"]["sequence"],
            )

    def test_cli_exposes_the_same_talk_operations(self) -> None:
        arguments = _parser().parse_args(["--no-gui", "--talk-matrix"])
        self.assertTrue(arguments.talk_matrix)
        self.assertIsNone(arguments.talk_start)
        self.assertEqual(arguments.talk_utterance, "hello")

    def test_unavailable_current_target_reports_reason_and_restores_scenario(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["alive"] = False
        with LuaSemanticWorker(scenario) as worker:
            matrix = worker.talk_matrix(target_types=["current"])
            restored = worker.snapshot()["scenario"]

        row = matrix["rows"][0]
        self.assertEqual(row["target"]["route"], "unavailable")
        self.assertEqual(
            row["target"]["availability"]["reason"], "npc_unavailable"
        )
        self.assertFalse(restored["npc"]["alive"])
        self.assertEqual(restored["npc"]["npcID"], scenario["npc"]["npcID"])
        self.assertNotIn("semanticLabTalkTarget", restored["runtime"])

    def test_trader_capability_is_an_overlay_on_the_talk_target(self) -> None:
        scenario = apply_npc_profile(deepcopy(DEFAULT_SCENARIO), "trader")
        with LuaSemanticWorker(scenario) as worker:
            matrix = worker.talk_matrix(target_types=["current"])

        row = matrix["rows"][0]
        target = row["target"]
        integration = row["integration"]
        self.assertEqual(target["targetType"], "neutral")
        self.assertEqual(target["tacticalClass"], "neutral")
        self.assertTrue(integration["traderOverlay"]["enabled"])
        self.assertEqual(
            integration["traderOverlay"]["providerID"],
            "dynamictrading.trader",
        )
        self.assertTrue(integration["dynamicTrading"]["loaded"])
        self.assertIn(
            "dynamictrading.trade",
            {choice["id"] for choice in row["semanticHubChoices"]},
        )

    def test_en_tl_keep_talk_routes_and_semantic_choices_identical(self) -> None:
        rows_by_language = {}
        for language in ("EN", "TL"):
            scenario = deepcopy(DEFAULT_SCENARIO)
            scenario["runtime"]["language"] = language
            with LuaSemanticWorker(scenario) as worker:
                matrix = worker.talk_matrix(
                    target_types=["colonist", "neutral", "hostile"],
                    text="hello",
                )
            rows_by_language[language] = {
                row["target"]["id"]: row for row in matrix["rows"]
            }

        for target_id in ("colonist", "neutral", "hostile"):
            english = rows_by_language["EN"][target_id]
            tagalog = rows_by_language["TL"][target_id]
            self.assertEqual(
                english["target"]["targetType"],
                tagalog["target"]["targetType"],
            )
            self.assertEqual(
                english["target"]["route"], tagalog["target"]["route"]
            )
            self.assertEqual(
                [choice["id"] for choice in english["semanticHubChoices"]],
                [choice["id"] for choice in tagalog["semanticHubChoices"]],
            )

    def test_recruitment_shortcut_and_typed_input_use_production_result_path(self) -> None:
        neutral = apply_npc_profile(deepcopy(DEFAULT_SCENARIO), "neutral")
        with LuaSemanticWorker(neutral) as worker:
            candidates = []
            suggestions = worker.snapshot()["suggestions"]
            for group in suggestions.get("groups", []):
                candidates.extend(group.get("candidates", []))
            recruit = next(
                candidate
                for candidate in candidates
                if candidate.get("id") == "conversation.root:menu:recruit"
            )
            clicked = worker.suggestion_click(recruit["frame"])

        clicked_npc = [
            message
            for message in clicked.get("messages", [])
            if message.get("speaker") == "npc"
        ]
        self.assertTrue(clicked_npc)
        self.assertTrue(clicked_npc[-1]["payload"].get("text"))
        self.assertTrue(
            clicked_npc[-1]["payload"]["key"].startswith(
                "response.recruit.reject.relationship."
            )
        )

        expected_replies = {
            "companion": "response.recruit.reject.member.",
            "enemy": "response.recruit.reject.hostile.",
        }
        for profile, response_prefix in expected_replies.items():
            scenario = apply_npc_profile(deepcopy(DEFAULT_SCENARIO), profile)
            with LuaSemanticWorker(scenario) as worker:
                result = worker.input("Would you like to join us?")
            npc_messages = [
                message
                for message in result.get("messages", [])
                if message.get("speaker") == "npc"
            ]
            self.assertTrue(npc_messages)
            payload = npc_messages[-1]["payload"]
            self.assertTrue(payload.get("text"))
            self.assertTrue(payload.get("key", "").startswith(response_prefix))

    def test_recruitment_authority_reads_staged_relationship_and_assigns_member(self) -> None:
        scenario = apply_npc_profile(deepcopy(DEFAULT_SCENARIO), "neutral")
        scenario["npc"]["tacticalClass"] = "neutral"
        scenario["npc"]["relationship"].update(
            approval=94,
            respect=95,
            familiarity=92,
            revision=2,
        )

        with LuaSemanticWorker(scenario) as worker:
            result = worker.input("Would you like to join us?")
            snapshot = worker.snapshot()

        npc_messages = [
            message
            for message in result["messages"]
            if message.get("speaker") == "npc"
        ]
        self.assertTrue(npc_messages)
        self.assertTrue(
            npc_messages[-1]["payload"]["key"].startswith("response.recruit.")
        )
        recruit_results = [
            item
            for item in result.get("transport", [])
            if item.get("payload", {}).get("success") is True
            and item.get("payload", {}).get("reason") == "recruited"
        ]
        self.assertTrue(recruit_results)
        self.assertTrue(snapshot["scenario"]["npc"]["recruited"])

    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_tk_talk_parity_surface_runs_the_real_worker(self) -> None:
        root = tk.Tk()
        app = SemanticHarnessApp(root, _parser().parse_args([]))
        app._messagebox.showerror = lambda *_args, **_kwargs: None
        root.geometry("1080x700")
        deadline = time.monotonic() + 15
        try:
            while not app.worker_ready and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertTrue(app.worker_ready)
            labels = [
                app.trace_tabs.tab(tab, "text") for tab in app.trace_tabs.tabs()
            ]
            self.assertIn("Talk parity", labels)
            app.run_talk_matrix()
            deadline = time.monotonic() + 15
            while app.busy and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            output = app.talk_output.get("1.0", "end")
            self.assertIn("semantic.talk.parity.matrix.v1", output)
            self.assertIn("Hostile / Enemy", output)
            self.assertEqual(
                app.trace_tabs.tab(app.trace_tabs.select(), "text"),
                "Talk parity",
            )
        finally:
            app.close()


if __name__ == "__main__":
    unittest.main()
