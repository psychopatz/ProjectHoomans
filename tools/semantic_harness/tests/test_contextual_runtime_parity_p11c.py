"""P11C proof for durable friend promotion on the existing relationship record."""

from __future__ import annotations

import gc
import os
import tempfile
import time
import tkinter as tk
import unittest
from copy import deepcopy
from pathlib import Path

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.runtime.scenario import (
    DEFAULT_SCENARIO,
    load_scenario,
    save_scenario,
)
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.ui.shell import SemanticHarnessApp
from tools.semantic_harness.tests.gui_test_support import SemanticLabGuiTestCase


def relationship_scenario(approval: float, respect: float, familiarity: float) -> dict:
    scenario = deepcopy(DEFAULT_SCENARIO)
    scenario["npc"]["relationship"] = {
        "approval": approval,
        "respect": respect,
        "familiarity": familiarity,
        "revision": 1,
    }
    return scenario


class RuntimeParityP11CTests(SemanticLabGuiTestCase):
    def test_friend_gate_promotes_once_and_survives_standing_deterioration(self) -> None:
        below = relationship_scenario(79, 50, 60)
        with LuaSemanticWorker(below) as worker:
            first = worker.configure(deepcopy(below))
        self.assertEqual(first["simulationProjection"]["npc"].get("bond", {}).get("class", "none"), "none")

        crossed = relationship_scenario(80, 50, 60)
        with LuaSemanticWorker(crossed) as worker:
            promoted = worker.configure(deepcopy(crossed))
            after = worker.input("hello")
        bond = promoted["simulationProjection"]["npc"]["bond"]
        self.assertEqual(bond["class"], "friend")
        self.assertEqual(bond["source"], "relationship_milestone")
        self.assertEqual(after["relationshipAfter"]["bond"]["class"], "friend")

        deteriorated = deepcopy(promoted["scenario"])
        deteriorated["npc"]["relationship"].update(
            {"approval": -80, "respect": -20, "familiarity": 0}
        )
        with LuaSemanticWorker(deteriorated) as worker:
            result = worker.configure(deteriorated)
        final_bond = result["simulationProjection"]["npc"]["bond"]
        self.assertEqual(final_bond["class"], "friend")

    def test_starting_companion_relationships_seed_the_durable_record(self) -> None:
        for kind, expected_class in (
            ("friend", "friend"),
            ("lover", "lover"),
            ("mother", "family"),
            ("father", "family"),
            ("sister", "family"),
            ("brother", "family"),
        ):
            scenario = relationship_scenario(0, 0, 0)
            scenario["npc"]["startingRelationship"] = {"kind": kind}
            with LuaSemanticWorker(scenario) as worker:
                result = worker.configure(scenario)
            bond = result["simulationProjection"]["npc"]["bond"]
            self.assertEqual(bond["class"], expected_class, kind)
            if expected_class == "family":
                self.assertEqual(bond["kind"], kind)

    def test_bond_persists_through_scenario_round_trip(self) -> None:
        scenario = relationship_scenario(80, 50, 60)
        with LuaSemanticWorker(scenario) as worker:
            configured = worker.configure(scenario)
        saved = configured["scenario"]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "friend.json"
            save_scenario(path, saved)
            loaded = load_scenario(path)
        self.assertEqual(
            loaded["npc"]["relationship"]["bond"]["class"], "friend"
        )

    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_tk_relationship_panel_displays_durable_bond_after_apply(self) -> None:
        root = tk.Tk()
        root.geometry("1080x700")
        app = self.make_gui_app(root)

        def wait_until(predicate: object, timeout: float = 15.0) -> None:
            deadline = time.monotonic() + timeout
            while not predicate() and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertTrue(predicate())

        try:
            wait_until(lambda: app.worker_ready)
            fields = app.workbench_control_fields
            self.assertEqual(fields["relationship.bond"].kind, "read_only")
            fields["relationship.approval"].variable.set(80)
            fields["relationship.respect"].variable.set(50)
            fields["relationship.familiarity"].variable.set(60)
            app.apply_simulation_settings()
            wait_until(lambda: not app.busy and app.simulation_projection)
            wait_until(
                lambda: fields["relationship.bond"].widget.cget("text") == "friend"
            )
        finally:
            app.close()
            del app
            del root
            gc.collect()


if __name__ == "__main__":
    unittest.main()
