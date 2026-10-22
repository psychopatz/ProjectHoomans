"""P11B proof for actor-owned needs and production social projections."""

from __future__ import annotations

import gc
import os
import time
import tkinter as tk
import unittest
from copy import deepcopy

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.ui.shell import SemanticHarnessApp


class RuntimeParityP11BTests(unittest.TestCase):
    def test_catalog_owns_needs_by_actor_and_exposes_real_trait_sources(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            catalog = worker.simulation_control_catalog()
            persona = worker.persona_catalog()

        rows = {row["id"]: row for row in catalog["controls"]}
        for actor in ("player", "npc"):
            for need in ("hunger", "thirst", "fatigue", "stress", "boredom", "panic"):
                row = rows[f"{actor}.needs.{need}"]
                self.assertEqual(row["control"], "slider")
                self.assertTrue(row["workbench"])
                self.assertEqual(row["workbenchTab"], "Needs")
        self.assertNotIn("world.hunger", {
            row["id"] for row in catalog["controls"] if row.get("workbench")
        })
        self.assertEqual(
            {row["value"] for row in rows["player.traits"]["options"]},
            {row["id"] for row in persona["playerTraits"]},
        )
        self.assertIn("npc.personalityOverride", rows)
        self.assertEqual(rows["npc.personalityMode"]["control"], "read_only")
        for dimension in persona["personality"]["dimensions"]:
            self.assertTrue(rows[f"persona.personality.{dimension}"]["requiresOverride"])

    def test_player_traits_and_npc_generated_profile_use_production_resolvers(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["player"]["traits"] = ["PNC_Gay", "PNC_Flirty", "PNC_Friendly"]
        scenario["npc"]["identitySeed"] = "p11b-seed"
        scenario["npc"]["archetype"] = "Doctor"
        scenario["npc"]["traits"] = ["pnc_friendly"]
        with LuaSemanticWorker(scenario) as worker:
            projection = worker.configure(scenario)["simulationProjection"]
            catalog = worker.persona_catalog()

        player_profile = projection["player"]["socialProfile"]
        self.assertEqual(player_profile["orientation"], "gay")
        self.assertEqual(player_profile["romanceStyle"], "flirty")
        self.assertEqual(player_profile["socialStyle"], "friendly")
        self.assertEqual(projection["npc"]["personalityMode"], "generated")
        self.assertEqual(projection["npc"]["personality"]["generatedFromSeed"], True)
        self.assertEqual(projection["npc"]["personality"]["traitFingerprint"], "pnc_friendly")
        self.assertEqual(catalog["npcPersonalityMode"], "generated")

    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_tk_actor_needs_and_generated_personality_override_are_visible(self) -> None:
        root = tk.Tk()
        root.geometry("1080x700")
        app = SemanticHarnessApp(root, _parser().parse_args([]))

        def wait_until(predicate: object, timeout: float = 15.0) -> None:
            deadline = time.monotonic() + timeout
            while not predicate() and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertTrue(predicate())

        try:
            wait_until(lambda: app.worker_ready)
            fields = app.workbench_control_fields
            self.assertIsInstance(fields["player.needs.hunger"].widget, tk.Scale)
            self.assertIsInstance(fields["npc.needs.panic"].widget, tk.Scale)
            self.assertIsInstance(fields["player.traits"].widget, tk.Listbox)
            self.assertEqual(fields["npc.personalityMode"].kind, "read_only")
            self.assertEqual(str(fields["persona.personality.compassion"].widget.cget("state")), "disabled")

            fields["npc.personalityOverride"].variable.set(True)
            root.update_idletasks()
            self.assertEqual(str(fields["persona.personality.compassion"].widget.cget("state")), "normal")
        finally:
            app.close()
            del app
            del root
            gc.collect()


if __name__ == "__main__":
    unittest.main()
