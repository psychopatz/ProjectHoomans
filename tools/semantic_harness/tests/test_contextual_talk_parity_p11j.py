"""P11J native Talk target parity coverage."""

from __future__ import annotations

from copy import deepcopy
import os
from pathlib import Path
import time
import tkinter as tk
import unittest

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.runtime.npc_profiles import apply_npc_profile
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.ui.shell import SemanticHarnessApp


class ContextualTalkParityP11JTests(unittest.TestCase):
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
        self.assertIn(
            "action.follow",
            {choice["id"] for choice in rows["colonist"]["start"]["opening"]["choices"]},
        )
        self.assertIn(
            "conversation.root:menu:ceasefire",
            {choice["id"] for choice in rows["hostile"]["start"]["opening"]["choices"]},
        )
        self.assertNotIn("semanticLabTalkTarget", restored["runtime"])

    def test_native_and_harness_enter_the_shared_talk_start_projection(self) -> None:
        project = Path(__file__).resolve().parents[3]
        lifecycle = (
            project
            / "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Conversation/Definition/PNC_ConversationDefinition_Lifecycle.lua"
        ).read_text()
        builder = (
            project
            / "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Conversation/Definition/PNC_ConversationDefinition_Builder.lua"
        ).read_text()
        parity = (
            project
            / "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Conversation/PNC_ConversationTalkParity.lua"
        ).read_text()

        self.assertIn("TalkStart.Project(entry, player", lifecycle)
        self.assertIn("TalkStart.Project(entry, player", builder)
        self.assertIn("TalkStart.Project(", parity)
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
