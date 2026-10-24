"""GUI entry-point proof for explicit production save-backed startup."""

from __future__ import annotations

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


if __name__ == "__main__":
    unittest.main()
