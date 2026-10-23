"""P13C shared Player/NPC actor inspector acceptance."""

from __future__ import annotations

from hashlib import sha256
import os
from pathlib import Path
import time
import tkinter as tk
import unittest

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.runtime.player_engine_state import (
    OfflinePlayerEngineStateProvider,
)
from tools.semantic_harness.ui.shell import SemanticHarnessApp


class ActorInspectorsP13CTests(unittest.TestCase):
    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_real_save_import_populates_shared_player_and_npc_inspectors(self) -> None:
        root = tk.Tk()
        app = SemanticHarnessApp(root, _parser().parse_args([]))
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

            provider = OfflinePlayerEngineStateProvider()
            selected_entry = next(
                entry
                for entry in app.saved_world_entries
                if provider.project(Path(str(entry["path"]))).get("available")
            )
            source_path = Path(str(selected_entry["path"]))
            before = sha256(source_path.read_bytes()).hexdigest()
            native_probe = provider.project(source_path)
            native_player_uuid = str(native_probe["playerUUID"])
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

            self.assertTrue(app.saved_world_player_box["values"])
            player_label = next(
                label
                for label, row in app.saved_world_player_labels.items()
                if str(row.get("id")) == native_player_uuid
            )
            app.saved_world_player_box.set(player_label)
            groups = app.saved_world_tree.get_children("")
            group = next(
                group_id
                for group_id in groups
                if app.saved_world_tree.get_children(group_id)
            )
            app.saved_world_tree.item(group, open=True)
            actor_item = app.saved_world_tree.get_children(group)[0]
            app.saved_world_tree.selection_set(actor_item)
            app.saved_world_tree.focus(actor_item)
            app.saved_world_tree.event_generate("<<TreeviewSelect>>")
            actor = app.saved_world_tree_actor_rows[actor_item]

            app.saved_world_import_button.invoke()
            wait_until(
                lambda: not app.busy
                and app.source_snapshot_projection.get("metadata", {}).get(
                    "sourceKind"
                )
                == "SAVE"
            )

            for panel_name in ("Player", "NPC Target"):
                notebook = app.workbench_panel_notebooks[panel_name]
                self.assertEqual(
                    [notebook.tab(tab_id, "text") for tab_id in notebook.tabs()],
                    ["Overview", "Needs", "Personality & Traits", "Inventory"],
                )
                self.assertIn(
                    "Source:",
                    app.actor_overview_summaries[panel_name].get("1.0", "end"),
                )
                self.assertIn(
                    "Source:",
                    app.actor_needs_summaries[panel_name].get("1.0", "end"),
                )
                self.assertIn(
                    "source:",
                    app.actor_traits_summaries[panel_name].get("1.0", "end").lower(),
                )

            player_inventory = app.actor_inventory_views["Player"]
            self.assertIn("Source: SAVE", player_inventory.source_var.get())
            self.assertTrue(player_inventory.tree.get_children(""))
            self.assertIn(
                "native engine state: SAVE",
                app.actor_overview_summaries["Player"].get("1.0", "end"),
            )
            self.assertIn(
                str(app.scenario["player"]["characterUUID"]),
                app.actor_overview_summaries["Player"].get("1.0", "end"),
            )
            self.assertIn(
                str(actor["id"]),
                app.actor_overview_summaries["NPC Target"].get("1.0", "end"),
            )
            self.assertIsNot(
                app.actor_inventory_views["Player"],
                app.actor_inventory_views["NPC Target"],
            )
            self.assertEqual(
                tuple(app.actor_inventory_views["Player"].tree["columns"]),
                tuple(app.actor_inventory_views["NPC Target"].tree["columns"]),
            )
            self.assertEqual(before, sha256(source_path.read_bytes()).hexdigest())
        finally:
            try:
                app.close()
            except tk.TclError:
                pass


if __name__ == "__main__":
    unittest.main()
