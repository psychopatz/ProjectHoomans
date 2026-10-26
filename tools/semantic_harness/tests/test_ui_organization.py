"""Real-save proof for the compact Semantic Lab Simulation workspace."""

from __future__ import annotations

import os
from pathlib import Path
import tempfile
import time
import tkinter as tk
import unittest

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.ui.shell import SemanticHarnessApp


class SemanticLabUIOrganizationTests(unittest.TestCase):
    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_save_backed_simulation_is_compact_at_minimum_geometry(self) -> None:
        self._assert_save_backed_layout("1080x700")

    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_save_backed_simulation_is_compact_at_desktop_geometry(self) -> None:
        self._assert_save_backed_layout("1280x800")

    def _assert_save_backed_layout(self, geometry: str) -> None:
        state_dir = tempfile.TemporaryDirectory(prefix="projecthoomans-ui-org-")
        state_path = Path(state_dir.name) / "ui-state.json"
        root = tk.Tk()
        app = SemanticHarnessApp(
            root,
            _parser().parse_args(
                ["--ui-state", str(state_path), "--reset-ui-state"]
            ),
        )
        # The product intentionally restores the user's diagnostics choice;
        # make this compact-layout test deterministic instead of depending on
        # the desktop's persisted preference.
        app._ui_state["trace_panel_visible"] = False
        app._ui_state["advanced_controls_visible"] = False
        if app.trace_panel_visible:
            app._toggle_trace_panel()
        if app.advanced_controls_visible:
            app._toggle_advanced_controls()
        root.geometry(geometry)

        def wait_until(predicate: object, timeout: float = 45.0) -> None:
            deadline = time.monotonic() + timeout
            while not predicate() and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertTrue(predicate(), f"timed out at geometry {geometry}")

        try:
            wait_until(lambda: app.worker_ready)
            app.main_tabs.select(app.world_browser_tab)
            app.saved_world_discover_button.invoke()
            wait_until(lambda: not app.busy and bool(app.saved_world_entries))

            save_label = str(app.saved_world_save_box["values"][0])
            app.saved_world_save_box.set(save_label)
            app.saved_world_save_box.event_generate("<<ComboboxSelected>>")
            wait_until(lambda: not app.busy and bool(app.saved_world_browser.get("saveName")))
            app.saved_world_view_box.set("Saved affiliations")
            app.saved_world_view_box.event_generate("<<ComboboxSelected>>")
            self.assertTrue(app.saved_world_player_box["values"])
            app.saved_world_player_box.set(app.saved_world_player_box["values"][0])

            actor_item = next(
                iid
                for iid, actor in app.saved_world_tree_actor_rows.items()
                if actor.get("factionLabel") or actor.get("communityLabel")
            )
            app.saved_world_tree.selection_set(actor_item)
            app.saved_world_tree.focus(actor_item)
            app.saved_world_tree.event_generate("<<TreeviewSelect>>")
            actor = app.saved_world_tree_actor_rows[actor_item]
            group_label = actor.get("factionLabel") or actor.get("communityLabel")
            app.saved_world_import_button.invoke()
            wait_until(
                lambda: not app.busy
                and app.source_snapshot_projection.get("metadata", {}).get(
                    "sourceKind"
                )
                == "SAVE"
            )
            root.update_idletasks()
            wait_until(lambda: app.transcript.winfo_width() > 700, timeout=5)

            self.assertFalse(app.trace_panel_visible)
            self.assertFalse(app.advanced_controls_visible)
            self.assertEqual(app.diagnostics_toggle_button.cget("text"), "Show diagnostics")
            self.assertEqual(app.advanced_toggle_button.cget("text"), "Show advanced")
            self.assertGreater(app.transcript.winfo_width(), 700)

            context = app.simulation_context_var.get()
            self.assertIn("Source SAVE", context)
            self.assertIn("Target:", context)
            if actor.get("factionLabel"):
                self.assertIn(f"Faction: {group_label}", context)
            else:
                self.assertIn(f"Community: {group_label}", context)

            overview = app.actor_overview_summaries["NPC Target"].get("1.0", "end")
            self.assertIn(f"Faction: {actor.get('factionLabel') or 'MISSING'}", overview)
            self.assertIn("technical NPC ID:", overview)
            self.assertNotIn(f"Faction: {actor.get('factionID')}", overview)

            faction_tab = next(
                tab
                for tab in app.workbench_notebook.tabs()
                if app.workbench_notebook.tab(tab, "text") == "Faction / Community"
            )
            app.workbench_notebook.select(faction_tab)
            faction_context = app.faction_context_summary.get("1.0", "end")
            self.assertIn("Standing verification", faction_context)
            self.assertIn("Faction/community standing (group):", faction_context)
            self.assertIn("source: MISSING", faction_context)
            self.assertIn(str(group_label), faction_context)

            app.advanced_toggle_button.invoke()
            root.update_idletasks()
            self.assertTrue(app.advanced_controls_visible)
            self.assertTrue(app.reset_button.winfo_ismapped())
            app.advanced_toggle_button.invoke()
            app.diagnostics_toggle_button.invoke()
            root.update_idletasks()
            self.assertTrue(app.trace_panel_visible)
            self.assertTrue(app.trace_pane.winfo_ismapped())
            app.diagnostics_toggle_button.invoke()
        finally:
            try:
                app.close()
            finally:
                try:
                    root.destroy()
                except tk.TclError:
                    pass
            state_dir.cleanup()


if __name__ == "__main__":
    unittest.main()
