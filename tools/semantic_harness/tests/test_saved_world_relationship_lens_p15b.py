"""P15B/P15C player-relative saved-world browser coverage."""

from __future__ import annotations

from hashlib import sha256
import os
from pathlib import Path
import tempfile
import time
import tkinter as tk
import unittest

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.runtime.save_browser import SavedWorldBrowser
from tools.semantic_harness.runtime.worker import CORE_REPOSITORY
from tools.semantic_harness.ui.shell import SemanticHarnessApp


REAL_SAVE = Path(
    "/home/psychopatz/Zomboid/Saves/Apocalypse/"
    "2026-10-14_13-57-03/global_mod_data.bin"
)


@unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
class SavedWorldRelationshipLensP15BTests(unittest.TestCase):
    def _wait_for_worker(self, root: tk.Tk, app: SemanticHarnessApp) -> None:
        deadline = time.monotonic() + 30.0
        while not app._worker_initialized and time.monotonic() < deadline:
            root.update()
            time.sleep(0.02)
        self.assertTrue(app._worker_initialized)

    def test_default_lens_groups_actors_relative_to_selected_player(self) -> None:
        if not REAL_SAVE.is_file():
            self.skipTest("real local save is unavailable")
        before = sha256(REAL_SAVE.read_bytes()).hexdigest()
        root = tk.Tk()
        with tempfile.TemporaryDirectory() as directory:
            app = SemanticHarnessApp(
                root,
                _parser().parse_args(
                    ["--ui-state", str(Path(directory) / "ui-state.json")]
                ),
            )
            try:
                self._wait_for_worker(root, app)
                browser = SavedWorldBrowser(CORE_REPOSITORY).browse(REAL_SAVE)
                app.saved_world_browser = browser
                app.saved_world_player_labels = {
                    str(row.get("label") or row.get("id")): row
                    for row in browser["players"]
                }
                app.saved_world_player_var.set(browser["players"][0]["label"])
                app.saved_world_view_var.set("Relationship to Player")
                app._render_saved_world_tree()

                labels = {
                    str(group.get("label"))
                    for group in app.saved_world_tree_group_nodes.values()
                }
                self.assertIn("Player faction / companions", labels)
                self.assertIn("Hostile / looters", labels)
                self.assertIn("Settlers / communities", labels)
                self.assertIn("Traders / providers", labels)
                self.assertTrue(
                    all(
                        group.get("kind") == "relationship_category"
                        for group in app.saved_world_tree_group_nodes.values()
                    )
                )

                companion_iid, companion = next(
                    (iid, actor)
                    for iid, actor in app.saved_world_tree_actor_rows.items()
                    if actor.get("relationshipBadge") == "companion"
                )
                row_text = app.saved_world_tree.item(companion_iid, "text")
                self.assertNotIn(": patz Fellowship", row_text)
                self.assertEqual(
                    app.saved_world_tree.set(companion_iid, "group"),
                    "patz Fellowship",
                )
                self.assertIn(
                    "relationship_companion",
                    app.saved_world_tree.item(companion_iid, "tags"),
                )
                self.assertEqual(
                    companion["relationshipCategory"],
                    "Player faction / companions",
                )
                self.assertEqual(before, sha256(REAL_SAVE.read_bytes()).hexdigest())
            finally:
                app.close()
        try:
            root.destroy()
        except tk.TclError:
            pass

    def test_browser_lens_and_search_preferences_persist(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            state_path = Path(directory) / "ui-state.json"
            arguments = _parser().parse_args(["--ui-state", str(state_path)])
            root = tk.Tk()
            app = SemanticHarnessApp(root, arguments)
            try:
                self._wait_for_worker(root, app)
                app.saved_world_view_var.set("Saved affiliations")
                app.saved_world_search_var.set("Jordan")
                app._save_ui_state()
            finally:
                app.close()
            try:
                root.destroy()
            except tk.TclError:
                pass

            restored_root = tk.Tk()
            restored = SemanticHarnessApp(restored_root, arguments)
            try:
                self._wait_for_worker(restored_root, restored)
                self.assertEqual(
                    restored.saved_world_view_var.get(), "Saved affiliations"
                )
                self.assertEqual(restored.saved_world_search_var.get(), "Jordan")
            finally:
                restored.close()
                try:
                    restored_root.destroy()
                except tk.TclError:
                    pass

    def test_top_level_relationship_navigation_keeps_saved_overlays_reachable(self) -> None:
        if not REAL_SAVE.is_file():
            self.skipTest("real local save is unavailable")
        root = tk.Tk()
        with tempfile.TemporaryDirectory() as directory:
            app = SemanticHarnessApp(
                root,
                _parser().parse_args(
                    ["--ui-state", str(Path(directory) / "ui-state.json")]
                ),
            )
            try:
                self._wait_for_worker(root, app)
                browser = SavedWorldBrowser(CORE_REPOSITORY).browse(REAL_SAVE)
                app.saved_world_browser = browser
                app.saved_world_player_labels = {
                    str(row.get("label") or row.get("id")): row
                    for row in browser["players"]
                }
                app.saved_world_player_var.set(browser["players"][0]["label"])
                app._render_saved_world_tree()

                expected = {
                    "All relationship categories",
                    "Player faction / companions",
                    "Settlers / communities",
                    "Hostile / looters",
                    "Traders / providers",
                    "Neutral / unaffiliated",
                    "Other faction members",
                    "Unknown / unsupported",
                    "Saved affiliations / overlays",
                }
                self.assertTrue(
                    expected.issubset(set(app.saved_world_relationship_nav_buttons))
                )

                app._select_saved_world_relationship_category("Hostile / looters")
                self.assertEqual(
                    app.saved_world_view_var.get(), "Relationship to Player"
                )
                self.assertEqual(
                    {
                        str(group.get("label"))
                        for group in app.saved_world_tree_group_nodes.values()
                    },
                    {"Hostile / looters"},
                )

                app._select_saved_world_relationship_category(
                    "Saved affiliations / overlays"
                )
                self.assertEqual(app.saved_world_view_var.get(), "Saved affiliations")
                self.assertTrue(
                    any(
                        str(group.get("kind")) in {"faction", "community", "overlay", "provider_overlay"}
                        for group in app.saved_world_tree_group_nodes.values()
                    )
                )
            finally:
                app.close()
        try:
            root.destroy()
        except tk.TclError:
            pass


if __name__ == "__main__":
    unittest.main()
