"""P13A real-worker interaction acceptance for the World Browser."""

from __future__ import annotations

from hashlib import sha256
import os
from pathlib import Path
import time
import tkinter as tk
import unittest

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.ui.shell import SemanticHarnessApp


class OperationalWorldBrowserP13ATests(unittest.TestCase):
    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_real_save_player_hierarchy_import_and_talk_at_supported_geometries(self) -> None:
        for geometry in ("1080x700", "1280x800"):
            with self.subTest(geometry=geometry):
                root = tk.Tk()
                app = SemanticHarnessApp(root, _parser().parse_args([]))
                root.geometry(geometry)

                def wait_until(predicate: object, timeout: float = 45.0) -> None:
                    deadline = time.monotonic() + timeout
                    while not predicate() and time.monotonic() < deadline:
                        root.update()
                        time.sleep(0.02)
                    self.assertTrue(predicate(), f"timed out at {geometry}")

                try:
                    wait_until(lambda: app.worker_ready)
                    app.main_tabs.select(app.world_browser_tab)
                    app.saved_world_discover_button.invoke()
                    wait_until(
                        lambda: not app.busy and len(app.saved_world_entries) >= 2
                    )
                    self.assertGreater(app.saved_world_save_box.winfo_width(), 100)
                    self.assertGreater(app.saved_world_tree.winfo_width(), 400)

                    selected_entry = app.saved_world_entries[1]
                    source_path = Path(str(selected_entry["path"]))
                    before = sha256(source_path.read_bytes()).hexdigest()
                    app.saved_world_save_box.set(
                        next(
                            label
                            for label in app.saved_world_save_box["values"]
                            if str(selected_entry["saveName"]) in str(label)
                        )
                    )
                    app.saved_world_save_box.event_generate(
                        "<<ComboboxSelected>>"
                    )
                    wait_until(
                        lambda: not app.busy
                        and app.saved_world_browser.get("saveName")
                        == selected_entry["saveName"]
                    )

                    player_label = app.saved_world_player_box["values"][0]
                    app.saved_world_player_box.set(player_label)
                    all_groups = app.saved_world_tree.get_children("")
                    all_actor_items = [
                        item
                        for group_item in all_groups
                        for item in app.saved_world_tree.get_children(group_item)
                    ]
                    self.assertTrue(all_actor_items)
                    search_actor = app.saved_world_tree_actor_rows[all_actor_items[0]]
                    app.saved_world_search_var.set(str(search_actor["label"]))
                    app._render_saved_world_tree()
                    self.assertTrue(
                        any(
                            row.get("id") == search_actor["id"]
                            for row in app.saved_world_tree_actor_rows.values()
                        )
                    )
                    app.saved_world_search_var.set("")
                    app._render_saved_world_tree()
                    groups = app.saved_world_tree.get_children("")
                    group = next(
                        item
                        for item in groups
                        if app.saved_world_tree.get_children(item)
                    )
                    app.saved_world_tree.item(group, open=True)
                    actor_item = app.saved_world_tree.get_children(group)[0]
                    app.saved_world_tree.selection_set(actor_item)
                    app.saved_world_tree.focus(actor_item)
                    app.saved_world_tree.event_generate("<<TreeviewSelect>>")
                    actor = app.saved_world_tree_actor_rows[actor_item]
                    self.assertIn(actor["id"], app.saved_world_npc_var.get())

                    app.saved_world_import_button.invoke()
                    wait_until(
                        lambda: not app.busy
                        and app.source_snapshot_projection.get("metadata", {}).get(
                            "sourceKind"
                        )
                        == "SAVE"
                    )
                    self.assertEqual(app.scenario["npc"]["npcID"], actor["id"])
                    self.assertEqual(
                        app.main_tabs.tab(app.main_tabs.select(), "text"),
                        "Simulation",
                    )
                    self.assertFalse(app.npc_profile_box.winfo_ismapped())
                    self.assertFalse(app.developer_test_frame.winfo_ismapped())
                    self.assertIn("Loaded Player", app.saved_world_target_var.get())

                    app.talk_start_button.invoke()
                    wait_until(
                        lambda: not app.busy
                        and "Production target type:" in app.talk_output.get("1.0", "end")
                    )
                    talk_output = app.talk_output.get("1.0", "end")
                    self.assertIn("Route:", talk_output)
                    self.assertNotIn("synthetic", talk_output.lower())
                    self.assertEqual(before, sha256(source_path.read_bytes()).hexdigest())
                finally:
                    try:
                        app.close()
                    except tk.TclError:
                        pass


if __name__ == "__main__":
    unittest.main()
