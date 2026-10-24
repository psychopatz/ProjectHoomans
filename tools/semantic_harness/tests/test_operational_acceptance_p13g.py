"""P13G real-save operational acceptance for GUI, worker, and CLI paths."""

from __future__ import annotations

from copy import deepcopy
from hashlib import sha256
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import tkinter as tk
import unittest
from typing import Any, Callable

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.runtime.player_engine_state import (
    OfflinePlayerEngineStateProvider,
)
from tools.semantic_harness.runtime.save_browser import SavedWorldBrowser
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.ui.shell import SemanticHarnessApp


REPOSITORY = Path(__file__).resolve().parents[3]
CORE_REPOSITORY = REPOSITORY.parent / "psychopatzCore"
SAVE = Path(
    "/home/psychopatz/Zomboid/Saves/Apocalypse/"
    "2026-10-14_13-57-03/global_mod_data.bin"
)
PLAYER = "char_1791957489838_240087"
NPC = "npcAdamBloom_48G5"


class OperationalAcceptanceP13GTests(unittest.TestCase):
    def _run_cli(self, *arguments: str) -> list[dict[str, Any]]:
        environment = dict(os.environ)
        environment["XDG_STATE_HOME"] = "/tmp/projecthoomans-p13g-cli-state"
        completed = subprocess.run(
            [sys.executable, "-m", "tools.semantic_harness", *arguments, "--jsonl"],
            cwd=REPOSITORY,
            env=environment,
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            completed.returncode,
            0,
            msg=f"CLI failed: {completed.stderr}\n{completed.stdout[:1200]}",
        )
        return [
            json.loads(line)
            for line in completed.stdout.splitlines()
            if line.strip()
        ]

    @unittest.skipUnless(SAVE.is_file(), "real P13G save is unavailable")
    def test_real_saved_categories_use_production_talk_routes(self) -> None:
        """Exercise the real imported target in each available world overlay."""

        source_hash = sha256(SAVE.read_bytes()).hexdigest()
        browser = SavedWorldBrowser(core_repository=CORE_REPOSITORY).browse(SAVE)
        players = browser.get("players") or []
        self.assertTrue(players)
        player_uuid = str(players[0].get("uuid") or players[0].get("id"))
        categories = browser.get("categories") or {}
        expected = {
            "Companions": "full_conversation",
            "Neutral NPCs": "full_conversation",
            "Hostile NPCs": "hostile_full_conversation",
            "Known Traders": "full_conversation",
        }
        selected = {
            name: next(
                (row for row in categories.get(name, []) if isinstance(row, dict)),
                None,
            )
            for name in expected
        }
        self.assertTrue(
            all(selected.values()),
            msg={name: bool(row) for name, row in selected.items()},
        )

        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            for category, route in expected.items():
                actor = selected[category]
                self.assertIsNotNone(actor)
                actor_id = str(actor["id"])
                with self.subTest(category=category, actor=actor_id):
                    worker.import_saved_selection(
                        SAVE,
                        player_uuid=player_uuid,
                        npc_id=actor_id,
                    )
                    result = worker.talk_start("current", "hello")
                    start = result.get("start") or {}
                    target = start.get("target") or {}
                    self.assertEqual(target.get("entryID"), actor_id)
                    self.assertEqual(target.get("route"), route)
                    if category == "Known Traders":
                        overlay = (start.get("integration") or {}).get(
                            "traderOverlay"
                        ) or {}
                        self.assertTrue(overlay.get("enabled"))

        self.assertEqual(source_hash, sha256(SAVE.read_bytes()).hexdigest())

    @unittest.skipUnless(SAVE.is_file(), "real P13G save is unavailable")
    def test_cli_reproduces_talk_gift_diff_reset_and_source_immutability(self) -> None:
        source_hash = sha256(SAVE.read_bytes()).hexdigest()
        mutated = self._run_cli(
            "--save",
            str(SAVE),
            "--player",
            PLAYER,
            "--npc",
            NPC,
            "--talk-start",
            "current",
            "--gift",
            "Base.Bandage",
            "--working-world-diff",
        )
        talk = next(
            row
            for row in mutated
            if isinstance(row.get("start"), dict)
            and (row.get("start") or {}).get("target", {}).get("entryID") == NPC
        )
        self.assertEqual(
            (talk.get("start") or {}).get("target", {}).get("route"),
            "full_conversation",
        )
        self.assertTrue(any(row.get("type") == "gift" for row in mutated))
        mutated_diff = next(
            row
            for row in mutated
            if row.get("schema") == "semantic.harness_working_world.diff.v1"
        )
        self.assertTrue(mutated_diff.get("changed"))

        reset = self._run_cli(
            "--save",
            str(SAVE),
            "--player",
            PLAYER,
            "--npc",
            NPC,
            "--gift",
            "Base.Bandage",
            "--reset-world",
            "--working-world-diff",
        )
        reset_row = next(row for row in reset if row.get("type") == "reset_world")
        self.assertEqual(reset_row.get("source"), "SAVE")
        reset_diff = next(
            row
            for row in reset
            if row.get("schema") == "semantic.harness_working_world.diff.v1"
        )
        self.assertFalse(reset_diff.get("changed"))
        self.assertEqual(source_hash, sha256(SAVE.read_bytes()).hexdigest())

    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    @unittest.skipUnless(SAVE.is_file(), "real P13G save is unavailable")
    def test_tk_real_save_workflow_loads_talks_gifts_and_resets(self) -> None:
        """Use visible controls at minimum and normal desktop geometries."""

        for geometry in ("1080x700", "1280x800"):
            with self.subTest(geometry=geometry):
                root = tk.Tk()
                app = SemanticHarnessApp(root, _parser().parse_args([]))
                root.geometry(geometry)

                def wait_until(
                    predicate: Callable[[], bool], timeout: float = 60.0
                ) -> None:
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
                        lambda: not app.busy
                        and any(
                            OfflinePlayerEngineStateProvider()
                            .project(Path(str(entry.get("path"))))
                            .get("available")
                            for entry in app.saved_world_entries
                        )
                    )
                    root.update_idletasks()
                    self.assertGreaterEqual(root.winfo_width(), int(geometry.split("x")[0]))
                    self.assertGreater(app.saved_world_save_box.winfo_width(), 100)
                    self.assertGreater(app.saved_world_tree.winfo_width(), 400)

                    provider = OfflinePlayerEngineStateProvider()
                    selected_entry = next(
                        entry
                        for entry in app.saved_world_entries
                        if provider.project(Path(str(entry["path"]))).get("available")
                    )
                    source_path = Path(str(selected_entry["path"]))
                    source_hash = sha256(source_path.read_bytes()).hexdigest()
                    native_uuid = str(provider.project(source_path)["playerUUID"])
                    save_label = next(
                        label
                        for label in app.saved_world_save_box["values"]
                        if str(selected_entry["saveName"]) in str(label)
                    )
                    app.saved_world_save_box.set(save_label)
                    app.saved_world_save_box.event_generate(
                        "<<ComboboxSelected>>"
                    )
                    wait_until(
                        lambda: not app.busy
                        and app.saved_world_browser.get("saveName")
                        == selected_entry["saveName"]
                    )
                    app.saved_world_view_box.set("Saved affiliations")
                    app.saved_world_view_box.event_generate(
                        "<<ComboboxSelected>>"
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
                        if group.get("kind") in {"faction", "community"}
                        and NPC in (group.get("memberIDs") or [])
                    )
                    app.saved_world_tree.item(group_id, open=True)
                    actor_item = next(
                        iid
                        for iid in app.saved_world_tree.get_children(group_id)
                        if app.saved_world_tree_actor_rows[iid].get("id") == NPC
                    )
                    app.saved_world_tree.selection_set(actor_item)
                    app.saved_world_tree.focus(actor_item)
                    app.saved_world_tree.event_generate("<<TreeviewSelect>>")
                    self.assertIn(NPC, app.saved_world_npc_var.get())

                    app.saved_world_import_button.invoke()
                    wait_until(
                        lambda: not app.busy
                        and app.source_snapshot_projection.get("metadata", {}).get(
                            "sourceKind"
                        )
                        == "SAVE"
                        and app.scenario.get("npc", {}).get("npcID") == NPC
                    )
                    imported_baseline = deepcopy(app.scenario)
                    baseline_relationship = deepcopy(
                        imported_baseline["npc"].get("relationship") or {}
                    )

                    app.talk_start_button.invoke()
                    wait_until(
                        lambda: not app.busy
                        and "Production target type:" in app.talk_output.get(
                            "1.0", "end"
                        )
                    )
                    talk_output = app.talk_output.get("1.0", "end")
                    self.assertIn("Route: full_conversation", talk_output)
                    self.assertIn(NPC, talk_output)

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
                    gift.give_button.invoke()
                    wait_until(
                        lambda: not app.busy
                        and "Gift: Player → NPC" in gift.result.get("1.0", "end")
                    )
                    report = gift.result.get("1.0", "end")
                    self.assertIn("NPC response:", report)
                    self.assertIn("Relationship before:", report)
                    self.assertIn("Relationship after:", report)
                    self.assertIn("Source save: UNCHANGED", report)
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
                        app._inventory_item_map(
                            app.scenario["player"]["inventory"]
                        ),
                        app._inventory_item_map(
                            imported_baseline["player"]["inventory"]
                        ),
                    )
                    self.assertEqual(
                        app._inventory_item_map(app.scenario["npc"]["inventory"]),
                        app._inventory_item_map(
                            imported_baseline["npc"]["inventory"]
                        ),
                    )
                    self.assertEqual(
                        app.scenario["npc"]["relationship"].get("approval"),
                        baseline_relationship.get("approval"),
                    )
                    self.assertEqual(
                        source_hash, sha256(source_path.read_bytes()).hexdigest()
                    )
                finally:
                    try:
                        app.close()
                    except tk.TclError:
                        pass


if __name__ == "__main__":
    unittest.main()
