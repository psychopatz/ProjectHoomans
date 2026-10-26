"""Worker catalog and real Tk coverage for typed simulation controls."""

from __future__ import annotations

import gc
import os
import time
import tkinter as tk
import unittest
from copy import deepcopy
from tkinter import ttk

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.ui.dialogs.settings import collect_scenario_settings
from tools.semantic_harness.ui.shell import SemanticHarnessApp


class SimulationControlCatalogP10CTests(unittest.TestCase):
    def test_worker_provides_bounded_typed_controls_and_registry_options(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            catalog = worker.simulation_control_catalog()
            persona = worker.persona_catalog()

        self.assertEqual(catalog.get("schema"), "semantic.simulation.control.catalog.v1")
        controls = catalog.get("controls")
        self.assertIsInstance(controls, list)
        self.assertLessEqual(len(controls), catalog.get("maxControls", 0))
        by_id = {row["id"]: row for row in controls}

        for key in ("hunger", "thirst", "fatigue", "stress", "boredom", "panic"):
            row = by_id[f"world.{key}"]
            self.assertEqual(row["control"], "slider")
            self.assertEqual((row["min"], row["max"], row["step"]), (0, 1, 0.05))
        self.assertEqual(by_id["world.zombieKills"]["control"], "integer")
        self.assertEqual(by_id["world.timeOfDay"]["control"], "slider")
        self.assertEqual(by_id["npc.health.state"]["control"], "combobox")
        self.assertEqual(by_id["npc.activeBehavior"]["control"], "combobox")
        self.assertEqual(by_id["persona.traits"]["control"], "multi_select")
        self.assertEqual(by_id["persona.bondKind"]["optionsSource"], "PNC.RelationshipKinds")
        self.assertEqual(by_id["npc.role"]["optionsSource"], "PNC.FactionConstants.ROLES")

        self.assertEqual(
            {row["value"] for row in by_id["persona.traits"]["options"]},
            {row["id"] for row in persona["traits"]},
        )
        self.assertEqual(
            set(by_id["persona.socialStyle"]["options"]),
            set(persona["personality"]["enums"]["socialStyle"]),
        )
        for dimension in persona["personality"]["dimensions"]:
            self.assertEqual(
                by_id[f"persona.personality.{dimension}"]["control"], "slider"
            )
        bond_options = set(by_id["persona.bondKind"]["options"])
        self.assertTrue({"mother", "friend", "lover"}.issubset(bond_options))
        self.assertIn("trader", by_id["npc.role"]["options"])

    def test_catalog_collection_keeps_typed_state_and_rejects_invalid_values(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            catalog = worker.simulation_control_catalog()
        friendly_trait = next(
            row["value"]
            for row in next(
                item for item in catalog["controls"] if item["id"] == "persona.traits"
            )["options"]
            if "friendly" in row["value"].lower()
        )
        values = {
            "world.hunger": 0.65,
            "world.zombieKills": 14,
            "world.timeOfDay": 21.5,
            "npc.health.state": "normal",
            "npc.health.current": 95,
            "npc.health.max": 100,
            "npc.health.body.overallPercent": 95,
            "npc.activeBehavior": "idle",
            "npc.role": "trader",
            "npc.gender": "female",
            "persona.bondKind": "mother",
            "persona.traits": [friendly_trait],
            "persona.socialStyle": "friendly",
            "relationship.approval": 80,
            "relationship.respect": 45,
            "relationship.familiarity": 70,
            "persona.personality.compassion": 0.85,
            "persona.authority.companion": True,
            "persona.authority.owned": True,
            "persona.authority.eligible": True,
        }
        updated = collect_scenario_settings(
            deepcopy(DEFAULT_SCENARIO), values, catalog
        )

        self.assertEqual(updated["world"]["hunger"], 0.65)
        self.assertEqual(updated["world"]["zombieKills"], 14)
        self.assertEqual(updated["world"]["timeOfDay"], 21.5)
        self.assertEqual(updated["npc"]["health"]["state"], "normal")
        self.assertEqual(updated["npc"]["health"]["current"], 95)
        self.assertEqual(updated["npc"]["health"]["body"]["overallPercent"], 95)
        self.assertEqual(updated["npc"]["role"], "trader")
        self.assertEqual(updated["npc"]["gender"], "female")
        self.assertEqual(updated["npc"]["startingRelationship"]["kind"], "mother")
        self.assertEqual(
            updated["npc"]["startingRelationship"]["source"],
            "starting_companion_trait",
        )
        self.assertEqual(updated["npc"]["traits"], [friendly_trait])
        self.assertEqual(updated["npc"]["relationship"]["approval"], 80)
        self.assertEqual(updated["npc"]["personality"]["compassion"], 0.85)
        self.assertNotIn("relationshipState", updated["npc"])

        preserved = collect_scenario_settings(
            deepcopy(DEFAULT_SCENARIO), {"persona.traits": ["reserved"]}, catalog
        )
        self.assertEqual(preserved["npc"]["traits"], ["reserved"])
        with self.assertRaisesRegex(ValueError, "outside the worker catalog"):
            collect_scenario_settings(
                deepcopy(DEFAULT_SCENARIO),
                {"persona.traits": ["invented_trait"]},
                catalog,
            )

        invalid = dict(values)
        invalid["world.hunger"] = 1.2
        with self.assertRaisesRegex(ValueError, "world.hunger must be at most 1"):
            collect_scenario_settings(deepcopy(DEFAULT_SCENARIO), invalid, catalog)
        invalid = dict(values)
        invalid["world.hunger"] = 0.63
        with self.assertRaisesRegex(ValueError, "world.hunger must use increments of 0.05"):
            collect_scenario_settings(deepcopy(DEFAULT_SCENARIO), invalid, catalog)
        invalid = dict(values)
        invalid["npc.health.state"] = "made-up"
        with self.assertRaisesRegex(ValueError, "not in the worker catalog"):
            collect_scenario_settings(deepcopy(DEFAULT_SCENARIO), invalid, catalog)

    def test_tk_simulation_settings_apply_typed_controls_to_the_real_worker(self) -> None:
        if not os.environ.get("DISPLAY"):
            self.skipTest("Tk display is unavailable")

        root = tk.Tk()
        app = SemanticHarnessApp(root, _parser().parse_args([]))

        def wait_until(predicate: object, timeout: float = 12.0) -> None:
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
            widgets = app.settings_control_widgets

            self.assertNotIn("world.hunger", widgets)
            self.assertNotIn("world.timeOfDay", widgets)
            self.assertIn("npc.needs.hunger", app.workbench_control_fields)
            self.assertNotIn("npc.health.state", widgets)
            self.assertNotIn("world.zombieKills", widgets)
            self.assertIsInstance(widgets["persona.bondKind"], ttk.Combobox)
            app.settings_variables["persona.bondKind"].set("mother")

            apply_button = next(
                widget
                for widget in descendants(app.settings_window)
                if isinstance(widget, ttk.Button) and widget.cget("text") == "Apply"
            )
            apply_button.invoke()
            wait_until(lambda: not app.busy and app.settings_window is None)

            self.assertEqual(app.scenario["npc"]["startingRelationship"]["kind"], "mother")

            app.input_var.set("What's up?")
            app.submit()
            wait_until(lambda: not app.busy and app.last_response is not None)
            suggestions = (app.last_response.get("observation") or {}).get("suggestions") or {}
            self.assertEqual(
                suggestions.get("activeHub"),
                {"id": "whats_up", "route": "semantic_hub"},
            )
            candidates = suggestions.get("candidates", [])
            self.assertTrue(candidates)
            current_group = next(
                group
                for group in suggestions["groups"]
                if group["id"] == suggestions["currentGroupID"]
            )
            self.assertTrue(current_group["candidates"])
        finally:
            app.close()
            del app
            del root
            gc.collect()


if __name__ == "__main__":
    unittest.main()
