"""P13E production gift and isolated inventory verification acceptance."""

from __future__ import annotations

from copy import deepcopy
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


class InventoryGiftWorkbenchP13ETests(unittest.TestCase):
    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_real_save_gift_uses_production_route_and_resets_working_world(self) -> None:
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
            before_hash = sha256(source_path.read_bytes()).hexdigest()
            native_uuid = str(provider.project(source_path)["playerUUID"])
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
            player_label = next(
                label
                for label, row in app.saved_world_player_labels.items()
                if str(row.get("id")) == native_uuid
            )
            app.saved_world_player_box.set(player_label)
            group_id = next(
                group_id
                for group_id, group in app.saved_world_tree_group_nodes.items()
                if "npcAdamBloom_48G5" in (group.get("memberIDs") or [])
            )
            app.saved_world_tree.item(group_id, open=True)
            actor_item = next(
                iid
                for iid in app.saved_world_tree.get_children(group_id)
                if app.saved_world_tree_actor_rows[iid].get("id")
                == "npcAdamBloom_48G5"
            )
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
            self.assertEqual(app.scenario["npc"]["npcID"], actor["id"])

            gift = app.inventory_gift_workbench
            self.assertIsNotNone(gift)
            bandage_row = next(
                row_id
                for row_id, item in gift.player_view.item_rows.items()
                if item.get("fullType") == "Base.Bandage"
            )
            gift.player_view.tree.selection_set(bandage_row)
            gift.player_view.tree.focus(bandage_row)
            gift.player_view.tree.event_generate("<<TreeviewSelect>>")
            root.update()
            self.assertEqual(str(gift.give_button["state"]), "normal")
            imported_baseline = deepcopy(app.scenario)
            baseline_relationship = deepcopy(
                imported_baseline["npc"].get("relationship") or {}
            )

            gift.give_button.invoke()
            wait_until(
                lambda: not app.busy
                and "Gift: Player → NPC" in gift.result.get("1.0", "end")
            )
            report = gift.result.get("1.0", "end")
            self.assertIn("production status:", report)
            self.assertIn("Player inventory before → after:", report)
            self.assertIn("NPC inventory before → after:", report)
            self.assertIn("NPC response:", report)
            self.assertIn("Relationship before:", report)
            self.assertIn("Relationship after:", report)
            self.assertIn("Source save: UNCHANGED", report)
            self.assertNotEqual(
                app._inventory_item_map(app.scenario["player"]["inventory"]),
                app._inventory_item_map(imported_baseline["player"]["inventory"]),
            )
            self.assertNotEqual(
                app.scenario["npc"]["relationship"].get("approval"),
                baseline_relationship.get("approval"),
            )

            gift.reset_button.invoke()
            wait_until(
                lambda: not app.busy
                and "Working world reset" in gift.result.get("1.0", "end")
            )
            self.assertEqual(
                app._inventory_item_map(app.scenario["player"]["inventory"]),
                app._inventory_item_map(imported_baseline["player"]["inventory"]),
            )
            self.assertEqual(
                app._inventory_item_map(app.scenario["npc"]["inventory"]),
                app._inventory_item_map(imported_baseline["npc"]["inventory"]),
            )
            self.assertEqual(
                app.scenario["npc"]["relationship"].get("approval"),
                baseline_relationship.get("approval"),
            )
            self.assertEqual(before_hash, sha256(source_path.read_bytes()).hexdigest())
        finally:
            try:
                app.close()
            except tk.TclError:
                pass


if __name__ == "__main__":
    unittest.main()
