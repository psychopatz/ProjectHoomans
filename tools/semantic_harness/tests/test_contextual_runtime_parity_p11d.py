"""P11D proposal, compatibility, and deterministic lover progression tests."""

from __future__ import annotations

from copy import deepcopy
import os
import time
import tkinter as tk
import unittest

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.ui.shell import SemanticHarnessApp


class ContextualRuntimeParityP11DTests(unittest.TestCase):
    def scenario(
        self,
        *,
        player_gender: str = "male",
        player_traits: list[str] | None = None,
        npc_gender: str = "female",
        npc_orientation: str = "straight",
        npc_style: str = "flirty",
        bond_kind: str = "friend",
        approval: int = 100,
        respect: int = 100,
        familiarity: int = 100,
        seed: str = "accept_seed",
    ) -> dict:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["player"]["gender"] = player_gender
        scenario["player"]["traits"] = player_traits or []
        scenario["npc"]["gender"] = npc_gender
        scenario["npc"]["identitySeed"] = seed
        scenario["npc"]["personalityOverride"] = True
        scenario["npc"]["personality"] = {
            "orientation": npc_orientation,
            "romanceStyle": npc_style,
            "socialStyle": "friendly" if npc_style == "flirty" else "withdrawn",
        }
        scenario["npc"]["startingRelationship"] = {"kind": bond_kind}
        scenario["npc"]["relationship"].update(
            {
                "approval": approval,
                "respect": respect,
                "familiarity": familiarity,
            }
        )
        return scenario

    def proposal(self, scenario: dict) -> tuple[dict, dict]:
        with LuaSemanticWorker(scenario) as worker:
            return worker.relationship_proposal(), worker.snapshot()

    def test_same_gender_incompatible_and_gay_compatible(self) -> None:
        incompatible, _ = self.proposal(
            self.scenario(
                player_gender="male",
                npc_gender="male",
                npc_orientation="straight",
            )
        )
        self.assertFalse(incompatible["accepted"])
        self.assertEqual(incompatible["reason"], "orientation_incompatible")
        self.assertEqual(incompatible["action"], "RELATIONSHIP_PROPOSAL")

        compatible, _ = self.proposal(
            self.scenario(
                player_gender="male",
                player_traits=["PNC_Gay"],
                npc_gender="male",
                npc_orientation="gay",
            )
        )
        self.assertTrue(compatible["accepted"])
        self.assertEqual(
            compatible["simulationProjection"]["npc"]["bond"]["class"],
            "lover",
        )

    def test_bisexual_and_straight_compatibility_use_real_profiles(self) -> None:
        bisexual, _ = self.proposal(
            self.scenario(
                player_gender="male",
                player_traits=["PNC_Bisexual"],
                npc_gender="male",
                npc_orientation="gay",
            )
        )
        self.assertTrue(bisexual["accepted"])

        straight, _ = self.proposal(self.scenario())
        self.assertTrue(straight["accepted"])

    def test_family_and_below_threshold_are_blocked(self) -> None:
        family, _ = self.proposal(self.scenario(bond_kind="mother"))
        self.assertFalse(family["accepted"])
        self.assertEqual(family["reason"], "family_excluded")

        below, _ = self.proposal(
            self.scenario(approval=84, respect=60, familiarity=80)
        )
        self.assertFalse(below["accepted"])
        self.assertEqual(below["reason"], "approval_threshold")

    def test_flirty_and_reserved_are_deterministic_personality_tendencies(self) -> None:
        flirty, _ = self.proposal(self.scenario(npc_style="flirty"))
        reserved, _ = self.proposal(
            self.scenario(npc_style="reserved", seed="accept_seed")
        )
        flirty_probability = flirty["proposal"]["acceptance"]["probability"]
        reserved_probability = reserved["proposal"]["acceptance"]["probability"]
        self.assertGreater(flirty_probability, reserved_probability)
        self.assertTrue(flirty["accepted"])
        self.assertFalse(reserved["accepted"])
        self.assertEqual(reserved["reason"], "rejected")
        self.assertTrue(reserved["proposal"]["serverAuthoritative"])

        repeat, _ = self.proposal(self.scenario(npc_style="flirty"))
        self.assertEqual(
            repeat["proposal"]["acceptance"]["roll"],
            flirty["proposal"]["acceptance"]["roll"],
        )

    def test_rejection_cooldown_blocks_retry_and_persistence_round_trip(self) -> None:
        scenario = self.scenario(npc_style="reserved")
        with LuaSemanticWorker(scenario) as worker:
            rejected = worker.relationship_proposal()
            self.assertFalse(rejected["accepted"])
            self.assertEqual(rejected["reason"], "rejected")
            retry = worker.relationship_proposal()
            self.assertFalse(retry["accepted"])
            self.assertEqual(retry["reason"], "proposal_cooldown")
            persisted = worker.snapshot()["scenario"]
            self.assertEqual(
                persisted["npc"]["relationship"]["bond"]["class"],
                "friend",
            )
            self.assertIn(
                "relationship_proposal_rejected",
                [
                    memory["type"]
                    for memory in persisted["npc"]["relationship"]["memories"]
                ],
            )
            worker.configure(persisted)
            after_reload = worker.snapshot()
            self.assertEqual(
                after_reload["scenario"]["npc"]["relationship"]["bond"]["class"],
                "friend",
            )

    def test_starting_lover_is_preserved_without_a_new_proposal(self) -> None:
        result, snapshot = self.proposal(self.scenario(bond_kind="lover"))
        self.assertFalse(result["accepted"])
        self.assertEqual(result["reason"], "already_lover")
        self.assertEqual(
            snapshot["scenario"]["npc"]["relationship"]["bond"]["class"],
            "lover",
        )

    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_relationship_workbench_exposes_proposal_policy_and_action(self) -> None:
        root = tk.Tk()
        app = SemanticHarnessApp(root, _parser().parse_args([]))
        app._messagebox.showerror = lambda *_args, **_kwargs: None
        deadline = time.monotonic() + 15
        try:
            while not app.worker_ready and time.monotonic() < deadline:
                root.update()
                time.sleep(0.02)
            self.assertTrue(app.worker_ready)
            for control_id in (
                "relationship.romanceCompatibility",
                "relationship.proposalThreshold",
                "relationship.proposalCooldown",
                "relationship.proposalAvailable",
            ):
                self.assertIn(control_id, app.workbench_control_fields)
            self.assertEqual(app.proposal_button.cget("text"), "Propose relationship")
        finally:
            app.close()


if __name__ == "__main__":
    unittest.main()
