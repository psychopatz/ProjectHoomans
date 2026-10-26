"""Worker-backed item catalog and structured inventory UI regression tests."""

from __future__ import annotations

import gc
import json
import os
import time
import tkinter as tk
import unittest
from copy import deepcopy

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.runtime.item_catalog import _parse_script_text
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.ui.dialogs.inventory_editor import StructuredInventoryEditor
from tools.semantic_harness.ui.shell import SemanticHarnessApp
from tools.semantic_harness.tests.gui_test_support import SemanticLabGuiTestCase


class StructuredInventoryP10DTests(SemanticLabGuiTestCase):
    def test_item_script_catalog_parses_definitions_without_tk_item_policy(self) -> None:
        parsed = _parse_script_text(
            "module Base\n{\n"
            " item Bandage\n {\n DisplayName = Bandage,\n Weight = 0.1,\n }\n"
            "}\n"
        )
        self.assertEqual(
            parsed,
            [{"fullType": "Base.Bandage", "displayName": "Bandage"}],
        )

    def test_worker_item_catalog_comes_from_installed_pz_item_scripts(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            catalog = worker.item_catalog("Bandage", limit=100)

        self.assertEqual(catalog.get("schema"), "semantic.item.catalog.v1")
        self.assertEqual(catalog.get("source"), "Project Zomboid media/scripts")
        self.assertTrue(catalog.get("sourceAvailable"))
        bandage = next(
            row for row in catalog["results"] if row["fullType"] == "Base.Bandage"
        )
        self.assertEqual(bandage["displayName"], "Bandage")

    def test_real_tk_inventory_editor_round_trips_structured_and_advanced_json(self) -> None:
        if not os.environ.get("DISPLAY"):
            self.skipTest("Tk display is unavailable")

        root = tk.Tk()
        app = self.make_gui_app(root)
        errors: list[str] = []
        app._messagebox.showerror = lambda _title, message, **_kwargs: errors.append(str(message))

        def wait_until(predicate: object, timeout: float = 15.0) -> None:
            deadline = time.monotonic() + timeout
            while not predicate() and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertTrue(predicate())

        def descendants(widget: tk.Misc) -> list[tk.Misc]:
            result: list[tk.Misc] = []
            for child in widget.winfo_children():
                result.append(child)
                result.extend(descendants(child))
            return result

        try:
            wait_until(lambda: app.worker_ready)
            app.open_runtime_settings()
            wait_until(lambda: app.settings_window is not None)
            editor = app.settings_variables["player.inventory"]
            npc_editor = app.settings_variables["npc.inventory"]
            self.assertIsInstance(editor, StructuredInventoryEditor)
            self.assertIsInstance(npc_editor, StructuredInventoryEditor)
            self.assertIsNot(editor, npc_editor)
            self.assertEqual(editor.notebook.tab(editor.structured_tab, "text"), "Structured")
            self.assertEqual(editor.notebook.tab(editor.json_tab, "text"), "Advanced JSON")

            editor.search_var.set("Bandage")
            editor.search_button.invoke()
            wait_until(lambda: not app.busy and bool(editor.results_box["values"]))
            bandage_label = next(
                label
                for label in editor.results_box["values"]
                if str(label).endswith("· Base.Bandage")
            )
            editor.results_var.set(bandage_label)
            editor.add_button.invoke()
            self.assertTrue(editor.selected_row_id)
            editor.quantity_var.set("3")
            editor.condition_var.set("damaged")
            editor.commit_button.invoke()
            editor.condition_var.set("normal")
            editor.container_var.set("backpack")
            editor.location_var.set("medical bag")
            editor.equipped_var.set(True)
            editor.favorite_var.set(True)
            editor.equip_slot_var.set("Belt")
            editor.commit_button.invoke()

            editor.notebook.select(editor.json_tab)
            root.update()
            advanced = json.loads(editor.json_editor.get("1.0", "end"))
            bandage = next(
                item for item in advanced["items"]
                if item.get("itemID", "").startswith("semantic-lab-player-item-")
            )
            self.assertEqual(bandage["fullType"], "Base.Bandage")
            self.assertEqual(bandage["stack"], 3)
            self.assertEqual(bandage["condition"], "normal")
            self.assertEqual(bandage["container"], "backpack")
            self.assertEqual(bandage["location"], "medical bag")
            self.assertTrue(bandage["equipped"])
            self.assertTrue(bandage["favorite"])
            self.assertEqual(bandage["equipSlot"], "Belt")
            advanced["customInventoryField"] = {"keep": True}
            bandage["customItemField"] = "preserved"
            bandage["marketSense"] = {"primary": "medical", "tags": ["first_aid"]}
            editor.json_editor.delete("1.0", "end")
            editor.json_editor.insert("1.0", json.dumps(advanced, indent=2))

            editor.notebook.select(editor.structured_tab)
            root.update()
            new_item_row = next(
                row for row in editor.rows
                if isinstance(row.get("item"), dict)
                and row["item"].get("itemID", "").startswith("semantic-lab-player-item-")
            )
            editor.tree.selection_set(new_item_row["rowID"])
            root.update()
            self.assertIn("medical", editor.market_sense_var.get())
            structured = editor.get_value()
            round_tripped = next(
                item for item in structured["items"]
                if item.get("itemID", "").startswith("semantic-lab-player-item-")
            )
            self.assertEqual(round_tripped["stack"], 3)
            self.assertEqual(round_tripped["condition"], "normal")
            self.assertEqual(round_tripped["container"], "backpack")
            self.assertEqual(round_tripped["location"], "medical bag")
            self.assertTrue(round_tripped["equipped"])
            self.assertTrue(round_tripped["favorite"])
            self.assertEqual(round_tripped["equipSlot"], "Belt")
            self.assertEqual(round_tripped["customItemField"], "preserved")
            self.assertEqual(structured["customInventoryField"], {"keep": True})

            editor.notebook.select(editor.json_tab)
            root.update()
            second_advanced = json.loads(editor.json_editor.get("1.0", "end"))
            self.assertEqual(second_advanced["customInventoryField"], {"keep": True})
            self.assertEqual(
                next(item for item in second_advanced["items"]
                     if item.get("itemID", "").startswith("semantic-lab-player-item-"))["stack"],
                3,
            )
            editor.notebook.select(editor.structured_tab)
            root.update()

            # Removal is scoped to the selected item and leaves the first add intact.
            editor.add_button.invoke()
            extra_item_id = editor._row_for(editor.selected_row_id)["item"]["itemID"]
            editor.remove_button.invoke()
            self.assertNotIn(
                extra_item_id,
                {
                    str(row.get("item", {}).get("itemID"))
                    for row in editor.rows
                    if isinstance(row.get("item"), dict)
                },
            )

            apply_button = next(
                widget
                for widget in descendants(app.settings_window)
                if widget.winfo_class() == "TButton"
                and str(widget.cget("text")) == "Apply"
            )
            self.assertIsInstance(
                app.settings_control_fields["player.inventory"].get_value(),
                dict,
            )
            apply_button.invoke()
            wait_until(lambda: not app.busy)
            self.assertEqual(errors, [])
            self.assertIsNone(app.settings_window)
            applied_inventory = app.scenario["player"]["inventory"]
            applied_bandage = next(
                item for item in applied_inventory["items"]
                if item.get("itemID", "").startswith("semantic-lab-player-item-")
            )
            self.assertEqual(applied_bandage["fullType"], "Base.Bandage")
            self.assertEqual(applied_bandage["stack"], 3)
            self.assertEqual(applied_bandage["condition"], "normal")
            self.assertEqual(applied_bandage["container"], "backpack")
            self.assertEqual(applied_bandage["location"], "medical bag")
            self.assertTrue(applied_bandage["equipped"])
            self.assertTrue(applied_bandage["favorite"])
            self.assertEqual(applied_bandage["equipSlot"], "Belt")
            self.assertEqual(applied_bandage["customItemField"], "preserved")
            self.assertEqual(
                applied_inventory["customInventoryField"], {"keep": True}
            )
        finally:
            app.close()
            del app
            del root
            gc.collect()


if __name__ == "__main__":
    unittest.main()
