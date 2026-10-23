"""P12D read-only saved-world browser tests."""

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
from tools.semantic_harness.tests.test_save_catalog_p12b import pz_file
from tools.semantic_harness.ui.shell import SemanticHarnessApp


CORE_REPOSITORY = Path("/home/psychopatz/Zomboid/Workshop/psychopatzCore")


class SaveBrowserTests(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.save_path = Path(self.directory.name) / "global_mod_data.bin"
        tables = [
            (
                "PNC_PlayerCharacters",
                [
                    ("schemaVersion", 6),
                    (
                        "byUUID",
                        {
                            "char_saved": {
                                "uuid": "char_saved",
                                "accountKey": "slot_0",
                                "displayName": "Saved Player",
                                "status": "active",
                            }
                        },
                    ),
                ],
            ),
            ("PNC_Core_Global", [("schemaVersion", 16)]),
            (
                "PNC_Factions",
                [
                    ("schemaVersion", 6),
                    (
                        "byID",
                        {
                            "faction_saved": {
                                "id": "faction_saved",
                                "name": "Saved Fellowship",
                                "status": "active",
                                "memberIDs": {"npcFollower": True},
                            }
                        },
                    ),
                ],
            ),
            (
                "PNC_npcFollower",
                [
                    ("schemaVersion", 16),
                    (
                        "identity",
                        {
                            "displayName": "Follower Saved",
                            "survivor": {
                                "forename": "Follower",
                                "surname": "Saved",
                            },
                        },
                    ),
                    (
                        "affiliation",
                        {
                            "factionID": "faction_saved",
                            "communityID": "community_saved",
                        },
                    ),
                    (
                        "hostility",
                        {"mode": "defend_owner", "attackPlayers": False},
                    ),
                    ("orderSpec", {"kind": "follow"}),
                    ("generation", {"source": "WORLD_POPULATION_DIRECTOR"}),
                ],
            ),
            (
                "PNC_npcTrader",
                [
                    ("schemaVersion", 16),
                    ("identity", {"displayName": "Trader Saved"}),
                    (
                        "affiliation",
                        {"originArchetypeID": "trader"},
                    ),
                    ("hostility", {"mode": "neutral"}),
                    ("orderSpec", {"kind": "roam"}),
                    ("generation", {"source": "dynamic_trading"}),
                ],
            ),
            (
                "PNC_npcHostile",
                [
                    ("schemaVersion", 16),
                    ("identity", {"displayName": "Hostile Saved"}),
                    ("affiliation", {}),
                    (
                        "hostility",
                        {"mode": "hostile", "attackPlayers": True},
                    ),
                    ("orderSpec", {"kind": "roam"}),
                    ("generation", {}),
                ],
            ),
        ]
        self.save_path.write_bytes(pz_file(tables))

    def test_browser_projects_saved_world_categories_without_writing(self) -> None:
        before = sha256(self.save_path.read_bytes()).hexdigest()
        result = SavedWorldBrowser(CORE_REPOSITORY).browse(self.save_path)
        after = sha256(self.save_path.read_bytes()).hexdigest()

        self.assertEqual(result["schema"], "semantic.save_browser.v1")
        self.assertEqual(result["players"][0]["entityKey"], "player:slot_0:char_saved")
        self.assertEqual(result["counts"]["npcs"], 3)
        self.assertEqual(
            {row["label"] for row in result["categories"]["Followers"]},
            {"Follower Saved"},
        )
        self.assertEqual(
            {row["label"] for row in result["categories"]["Known Traders"]},
            {"Trader Saved"},
        )
        self.assertEqual(
            {row["label"] for row in result["categories"]["Hostile NPCs"]},
            {"Hostile Saved"},
        )
        self.assertEqual(result["factions"][0]["label"], "Saved Fellowship")
        self.assertEqual(result["communities"][0]["id"], "community_saved")
        self.assertEqual(before, after)

    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_workbench_exposes_saved_world_browser_controls(self) -> None:
        root = tk.Tk()
        root.geometry("1280x860")
        app = SemanticHarnessApp(root, _parser().parse_args([]))

        try:
            deadline = time.monotonic() + 20
            while not app._worker_initialized and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertTrue(app._worker_initialized)
            self.assertTrue(hasattr(app, "saved_world_save_box"))
            self.assertTrue(hasattr(app, "saved_world_category_box"))
            self.assertTrue(hasattr(app, "saved_world_import_button"))
        finally:
            app.close()


if __name__ == "__main__":
    unittest.main()
