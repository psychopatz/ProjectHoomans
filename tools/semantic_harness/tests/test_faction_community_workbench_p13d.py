"""P13D saved faction/community context and member-target acceptance."""

from __future__ import annotations

from hashlib import sha256
import os
from pathlib import Path
import time
import tkinter as tk
import unittest

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.ui.shell import SemanticHarnessApp
from tools.semantic_harness.tests.gui_test_support import SemanticLabGuiTestCase


class FactionCommunityWorkbenchP13DTests(SemanticLabGuiTestCase):
    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_saved_groups_show_persisted_context_and_load_member_target(self) -> None:
        root = tk.Tk()
        app = self.make_gui_app(root)
        root.geometry("1080x700")

        def wait_until(predicate: object, timeout: float = 45.0) -> None:
            deadline = time.monotonic() + timeout
            while not predicate() and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertTrue(predicate(), "timed out waiting for Semantic Lab")

        try:
            wait_until(lambda: app.worker_ready)
            app.main_tabs.select(app.world_browser_tab)
            app.saved_world_discover_button.invoke()
            wait_until(lambda: not app.busy and app.saved_world_entries)

            selected_entry = app.saved_world_entries[0]
            source_path = Path(str(selected_entry["path"]))
            before = sha256(source_path.read_bytes()).hexdigest()
            save_label = next(
                label
                for label in app.saved_world_save_box["values"]
                if str(selected_entry["saveName"]) in str(label)
            )
            app.saved_world_save_box.set(save_label)
            app.saved_world_save_box.event_generate("<<ComboboxSelected>>")
            wait_until(
                lambda: not app.busy
                and app.saved_world_browser.get("saveName")
                == selected_entry["saveName"]
            )
            app.saved_world_view_box.set("Saved affiliations")
            app.saved_world_view_box.event_generate("<<ComboboxSelected>>")

            group_rows = app.saved_world_tree_group_nodes
            kinds = {
                str(group.get("kind"))
                for group in group_rows.values()
                if isinstance(group, dict)
            }
            self.assertIn("faction", kinds)
            self.assertIn("community", kinds)
            self.assertIn("provider_overlay", kinds)

            faction_iid, faction = next(
                (iid, group)
                for iid, group in group_rows.items()
                if group.get("kind") == "faction" and group.get("memberIDs")
            )
            app.saved_world_tree.selection_set(faction_iid)
            app.saved_world_tree.focus(faction_iid)
            app.saved_world_tree.event_generate("<<TreeviewSelect>>")
            details = app.saved_world_group_inspector.get("1.0", "end")
            self.assertIn(str(faction["group"]["id"]), details)
            self.assertIn("members:", details)
            self.assertIn("Source: SAVE", app.saved_world_group_source_var.get())
            self.assertIn(str(faction["label"]), app.saved_world_group_title_var.get())

            app.saved_world_tree.item(faction_iid, open=True)
            actor_item = app.saved_world_tree.get_children(faction_iid)[0]
            app.saved_world_tree.selection_set(actor_item)
            app.saved_world_tree.focus(actor_item)
            app.saved_world_tree.event_generate("<<TreeviewSelect>>")
            actor = app.saved_world_tree_actor_rows[actor_item]
            self.assertEqual(app.saved_world_npc_var.get(), actor["id"])
            self.assertIn(str(faction["label"]), app.saved_world_group_title_var.get())

            app.saved_world_import_button.invoke()
            wait_until(
                lambda: not app.busy
                and app.source_snapshot_projection.get("metadata", {}).get(
                    "sourceKind"
                )
                == "SAVE"
            )
            self.assertEqual(app.scenario["npc"]["npcID"], actor["id"])
            self.assertIn("Loaded Player", app.saved_world_target_var.get())
            self.assertEqual(before, sha256(source_path.read_bytes()).hexdigest())
        finally:
            try:
                app.close()
            except tk.TclError:
                pass


if __name__ == "__main__":
    unittest.main()
