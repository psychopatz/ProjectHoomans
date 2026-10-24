"""GUI entry-point proof for explicit production save-backed startup."""

from __future__ import annotations

from hashlib import sha256
import os
from pathlib import Path
import time
import tkinter as tk
import unittest

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.ui.shell import SemanticHarnessApp


REAL_SAVE = Path(
    "/home/psychopatz/Zomboid/Saves/Apocalypse/"
    "2026-10-14_13-57-03/global_mod_data.bin"
)
PLAYER_UUID = "char_1791957489838_240087"
NPC_ID = "npcBarneyYamamoto_2OXA"
JORDAN_NPC_ID = "npcJordanMcLane_0LBN"


@unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
class GuiSavedPairEntrypointTests(unittest.TestCase):
    def test_explicit_saved_pair_starts_in_production_mode(self) -> None:
        if not REAL_SAVE.is_file():
            self.skipTest("real local save is unavailable")
        root = tk.Tk()
        app = SemanticHarnessApp(
            root,
            _parser().parse_args(
                [
                    "--gui",
                    "--load-saved-pair",
                    "--save",
                    str(REAL_SAVE),
                    "--player",
                    PLAYER_UUID,
                    "--npc",
                    NPC_ID,
                ]
            ),
        )

        def wait_until(predicate: object, timeout: float = 45.0) -> None:
            deadline = time.monotonic() + timeout
            while not predicate() and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertTrue(predicate(), "timed out waiting for saved GUI startup")

        try:
            wait_until(
                lambda: not app.busy
                and app.source_snapshot_projection.get("metadata", {}).get(
                    "sourceKind"
                )
                == "SAVE"
            )
            self.assertTrue(app.save_backed_mode)
            self.assertEqual(app.scenario["npc"]["npcID"], NPC_ID)
            self.assertIn("Source SAVE", app.simulation_context_var.get())
            self.assertIn("Target:", app.simulation_context_var.get())
            self.assertIn("Save-backed mode active", app.fixture_mode_var.get())
            self.assertNotIn("synthetic", app.transcript.get("1.0", "end").lower())
        finally:
            try:
                app.close()
            except tk.TclError:
                pass

    def test_relationship_sliders_are_runtime_only_production_overrides(self) -> None:
        if not REAL_SAVE.is_file():
            self.skipTest("real local save is unavailable")
        source_before = sha256(REAL_SAVE.read_bytes()).digest()
        root = tk.Tk()
        app = SemanticHarnessApp(
            root,
            _parser().parse_args(
                [
                    "--gui",
                    "--load-saved-pair",
                    "--save",
                    str(REAL_SAVE),
                    "--player",
                    PLAYER_UUID,
                    "--npc",
                    NPC_ID,
                ]
            ),
        )

        def wait_until(predicate: object, timeout: float = 45.0) -> None:
            deadline = time.monotonic() + timeout
            while not predicate() and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertTrue(predicate(), "timed out waiting for saved GUI startup")

        try:
            wait_until(
                lambda: not app.busy
                and app.source_snapshot_projection.get("metadata", {}).get(
                    "sourceKind"
                )
                == "SAVE"
            )
            relationship_summary = app.relationship_context_summary.get("1.0", "end")
            self.assertIn("Personal relationship", relationship_summary)
            self.assertIn("source MISSING", relationship_summary)

            app.input_var.set("fuck you")
            app.submit()
            wait_until(lambda: not app.busy and "TOOL/ACTION:" in app.transcript.get("1.0", "end"))
            self.assertIn("player_dialogue_insult", app.transcript.get("1.0", "end"))

            app.workbench_control_fields["relationship.approval"].variable.set(-20)
            app.workbench_control_fields["relationship.respect"].variable.set(-10)
            app.workbench_control_fields["relationship.familiarity"].variable.set(12)
            wait_until(
                lambda: not app.busy
                and isinstance(
                    app.scenario.get("npc", {}).get("relationship"), dict
                )
                and app.scenario["npc"]["relationship"].get("approval") == -20
            )
            override = app.runtime_relationship_override_projection.get(NPC_ID)
            self.assertEqual(override["owner"], "PNC.Relationships.SetDebugBaseline")
            self.assertEqual(override["source"], "HARNESS_RUNTIME_OVERRIDE")
            self.assertIn("Runtime-only relationship override", app.relationship_context_summary.get("1.0", "end"))
            self.assertEqual(sha256(REAL_SAVE.read_bytes()).digest(), source_before)

            app.reset()
            wait_until(lambda: not app.busy and not app.runtime_relationship_override_projection)
            self.assertIn("source MISSING", app.relationship_context_summary.get("1.0", "end"))
            self.assertIn(
                "MISSING",
                app.workbench_control_fields["relationship.approval"].slider_display.cget(
                    "text"
                ),
            )
            self.assertEqual(sha256(REAL_SAVE.read_bytes()).digest(), source_before)
        finally:
            try:
                app.close()
            except tk.TclError:
                pass

    def test_saved_production_dossier_and_interactions_are_visible_on_demand(self) -> None:
        if not REAL_SAVE.is_file():
            self.skipTest("real local save is unavailable")
        source_before = sha256(REAL_SAVE.read_bytes()).digest()
        root = tk.Tk()
        app = SemanticHarnessApp(
            root,
            _parser().parse_args(
                [
                    "--gui",
                    "--load-saved-pair",
                    "--save",
                    str(REAL_SAVE),
                    "--player",
                    PLAYER_UUID,
                    "--npc",
                    "npcKentLangley_OWOJ",
                ]
            ),
        )

        def wait_until(predicate: object, timeout: float = 45.0) -> None:
            deadline = time.monotonic() + timeout
            while not predicate() and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertTrue(predicate(), "timed out waiting for saved GUI startup")

        try:
            wait_until(
                lambda: not app.busy
                and app.source_snapshot_projection.get("metadata", {}).get(
                    "sourceKind"
                )
                == "SAVE"
            )
            notebook = app.workbench_panel_notebooks["NPC Target"]
            dossier_tab = next(
                tab for tab in notebook.tabs()
                if notebook.tab(tab, "text") == "Dossier"
            )
            notebook.select(dossier_tab)
            wait_until(
                lambda: not app.busy
                and app.npc_dossier_projection.get("status") == "HYDRATED"
            )
            dossier_text = app.npc_dossier_summary.get("1.0", "end")
            self.assertIn("Knowledge revision", dossier_text)
            self.assertIn("Known information", dossier_text)

            interactions_tab = next(
                tab for tab in notebook.tabs()
                if notebook.tab(tab, "text") == "Interactions"
            )
            notebook.select(interactions_tab)
            wait_until(
                lambda: not app.busy
                and app.relationship_history_projection.get("status") == "HYDRATED"
            )
            self.assertIn("Recorded interactions", app.npc_interaction_summary.get("1.0", "end"))

            app.input_var.set("fuck you")
            app.submit()
            wait_until(
                lambda: not app.busy
                and "player_dialogue_insult" in app.npc_interaction_summary.get("1.0", "end")
                and "Last semantic action" in app.npc_interaction_summary.get("1.0", "end")
            )
            interaction_text = app.npc_interaction_summary.get("1.0", "end")
            self.assertIn("result: APPLIED", interaction_text)
            self.assertIn("Current relationship: Approval", interaction_text)
            self.assertIn("Saved baseline:", interaction_text)
            self.assertIn("Last semantic action", interaction_text)
            self.assertIn("status=APPLIED", interaction_text)
            self.assertIn("Requested effect:", interaction_text)
            self.assertEqual(sha256(REAL_SAVE.read_bytes()).digest(), source_before)
        finally:
            try:
                app.close()
            except tk.TclError:
                pass

    def test_saved_production_action_refreshes_relationship_sliders(self) -> None:
        """A production social action must repaint the authoritative values."""

        if not REAL_SAVE.is_file():
            self.skipTest("real local save is unavailable")
        source_before = sha256(REAL_SAVE.read_bytes()).digest()
        root = tk.Tk()
        app = SemanticHarnessApp(
            root,
            _parser().parse_args(
                [
                    "--gui",
                    "--load-saved-pair",
                    "--save",
                    str(REAL_SAVE),
                    "--player",
                    PLAYER_UUID,
                    "--npc",
                    JORDAN_NPC_ID,
                ]
            ),
        )

        def wait_until(predicate: object, timeout: float = 45.0) -> None:
            deadline = time.monotonic() + timeout
            while not predicate() and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertTrue(predicate(), "timed out waiting for saved GUI startup")

        try:
            wait_until(
                lambda: not app.busy
                and app.source_snapshot_projection.get("metadata", {}).get(
                    "sourceKind"
                )
                == "SAVE"
            )
            app.input_var.set("fuck you")
            app.submit()
            wait_until(
                lambda: not app.busy
                and "player_dialogue_insult" in app.transcript.get("1.0", "end")
            )

            relationship = app.scenario["npc"]["relationship"]
            self.assertAlmostEqual(relationship["approval"], -3.62, places=2)
            self.assertAlmostEqual(relationship["respect"], -2.71, places=2)
            self.assertAlmostEqual(relationship["familiarity"], 1.0, places=2)
            for key, expected in (
                ("approval", -3.62),
                ("respect", -2.71),
                ("familiarity", 1.0),
            ):
                field = app.workbench_control_fields[f"relationship.{key}"]
                self.assertAlmostEqual(float(field.get_value()), expected, places=2)
                self.assertNotIn("MISSING", field.slider_display.cget("text"))
            self.assertIn("TOOL/ACTION:", app.transcript.get("1.0", "end"))
            self.assertEqual(sha256(REAL_SAVE.read_bytes()).digest(), source_before)

            app.reset()
            wait_until(lambda: not app.busy and not app.runtime_relationship_override_projection)
            self.assertEqual(
                app.workbench_control_fields["relationship.approval"].get_value(),
                0,
            )
            self.assertIn(
                "MISSING",
                app.workbench_control_fields["relationship.approval"].slider_display.cget(
                    "text"
                ),
            )
            self.assertEqual(sha256(REAL_SAVE.read_bytes()).digest(), source_before)
        finally:
            try:
                app.close()
            except tk.TclError:
                pass


if __name__ == "__main__":
    unittest.main()
