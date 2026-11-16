"""Imperative scenario validation, round-trip, and runner-API contracts for wellbeing."""

from __future__ import annotations

import tempfile
from pathlib import Path
import unittest

from tools.semantic_harness.testing.runner import HarnessCase, detect_conflicts, run_case
from tools.providers.pnc.runtime.scenario import (
    DEFAULT_SCENARIO, load_scenario, merge, save_scenario, validate_scenario,
)


class WellbeingProjectionTests(unittest.TestCase):
    @staticmethod
    def scenario(npc: dict, *, world: dict | None = None) -> dict:
        overrides = {"npc": npc}
        if world is not None:
            overrides["world"] = world
        return merge(DEFAULT_SCENARIO, overrides)

    def test_canonical_health_rejects_semantic_only_state_names(self) -> None:
        scenario = self.scenario({
            "health": {"state": "injured", "current": 95, "max": 100},
        })
        with self.assertRaisesRegex(ValueError, "npc.health.state"):
            validate_scenario(scenario)

    def test_editable_npc_state_round_trips_without_world_mutation(self) -> None:
        scenario = self.scenario({
            "healthState": "injured",
            "activeBehavior": "treatment",
            "needs": {"thirst": 0.93},
            "conditionStats": {"stress": 0.91},
        })
        world_before = dict(scenario["world"])
        validate_scenario(scenario)
        with tempfile.TemporaryDirectory() as directory:
            path = save_scenario(Path(directory) / "npc-state.json", scenario)
            restored = load_scenario(path)
        self.assertEqual(restored["npc"]["health"]["state"], "normal")
        self.assertEqual(restored["npc"]["health"]["body"]["openWoundCount"], 1)
        self.assertEqual(restored["npc"]["activeBehavior"], "treatment")
        self.assertEqual(restored["npc"]["needs"]["thirst"], 0.93)
        self.assertEqual(restored["npc"]["conditionStats"]["stress"], 0.91)
        self.assertEqual(restored["world"], world_before)

    def test_real_worker_multi_turn_replay_and_conflict_ledger(self) -> None:
        case = HarnessCase.from_mapping({
            "id": "wellbeing_baseline",
            "scenario": {
                "npc": {"healthState": "injured",
                        "needs": {"hunger": 0.05, "thirst": 0.05, "fatigue": 0.05},
                        "conditionStats": {}},
            },
            "inputs": ["Are you okay?", "What's wrong?"],
        })
        result = run_case(case)
        self.assertEqual(len(result.turns), 2)
        self.assertEqual(result.conflicts, [])
        first = result.turns[0]
        self.assertTrue(first["accepted"], first.get("reason"))
        self.assertFalse(detect_conflicts([first]))
        self.assertEqual(first["routedSituation"]["npc"]["healthState"], "injured")
        self.assertTrue(first["result"]["decision"]["response"]["templateID"].startswith("question.wellbeing.injured"))
        second = result.turns[1]
        self.assertTrue(second["accepted"])
        self.assertEqual(second["contextBefore"]["dialogue"]["currentTopic"], "wellbeing")
        self.assertEqual(second["contextBefore"]["dialogue"]["lastSpeaker"], "npc")
        self.assertEqual(second["contextAfter"]["dialogue"]["sequence"], 4)

    def test_invalid_state_shapes_rejected(self) -> None:
        for field in ("healthState", "activeBehavior"):
            with self.subTest(field=field):
                scenario = self.scenario({field: 42})
                with self.assertRaisesRegex(ValueError, field):
                    validate_scenario(scenario)
        for field in ("needs", "conditionStats"):
            with self.subTest(field=field):
                scenario = self.scenario({field: "invalid"})
                with self.assertRaisesRegex(ValueError, field):
                    validate_scenario(scenario)


if __name__ == "__main__":
    unittest.main()
