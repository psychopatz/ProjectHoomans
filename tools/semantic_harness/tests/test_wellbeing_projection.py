"""Real-production-Lua wellbeing scenario and projection acceptance probes.

These tests execute the persistent Semantic Lab Lua worker, not a Python mock
of the parser or a JSON-only replay. They validate the existing reactions;
new reaction behavior and native SP/MP acceptance belong to later phases.
"""

from __future__ import annotations

import tempfile
from pathlib import Path
import unittest

from tools.semantic_harness.runner import HarnessCase, detect_conflicts, run_case
from tools.semantic_harness.scenario import (
    DEFAULT_SCENARIO, load_scenario, merge, save_scenario, validate_scenario,
)
from tools.semantic_harness.worker import LuaSemanticWorker


class WellbeingProjectionTests(unittest.TestCase):
    @staticmethod
    def scenario(npc: dict, *, world: dict | None = None) -> dict:
        overrides = {"npc": npc}
        if world is not None:
            overrides["world"] = world
        return merge(DEFAULT_SCENARIO, overrides)

    def assert_offline_wellbeing(self, turn: dict) -> tuple[dict, dict]:
        self.assertTrue(turn["accepted"], turn.get("reason"))
        self.assertEqual(turn["result"]["ir"]["intent"], "QUESTION")
        self.assertEqual(turn["result"]["ir"]["subject"], "WELLBEING")
        self.assertEqual(turn["result"]["decision"]["route"], "deterministic")
        self.assertEqual(turn["llmCalls"], 0)
        self.assertEqual(turn["transport"], [])
        self.assertEqual(turn["toolCalls"], [])
        self.assertIn("PNC/Semantics/PNC_SemanticDialogueInput.lua", turn["loadedModules"])
        self.assertIn("PNC/Semantics/PNC_SemanticDialoguePolicy.lua", turn["loadedModules"])
        self.assertEqual(len(turn["messages"]), 1)
        self.assertEqual(turn["contextBefore"]["state"], None)
        self.assertIsInstance(turn["contextAfter"]["state"], dict)
        self.assertIsInstance(turn["routedSituation"], dict)
        self.assertFalse(detect_conflicts([turn]))
        return turn["routedSituation"]["npc"], turn["result"]["decision"]["response"]

    def test_wellbeing_context_is_production_routed_and_fact_grounded(self) -> None:
        neutral_needs = {"hunger": 0.05, "thirst": 0.05, "fatigue": 0.05}
        neutral_conditions = {"stress": 0.0, "panic": 0.0, "boredom": 0.0}
        cases = (
            ("healthy", {"healthState": "healthy", "needs": neutral_needs,
                         "conditionStats": neutral_conditions},
             "healthy", None, "semantic.question.wellbeing.default"),
            ("injured", {"healthState": "injured", "needs": neutral_needs,
                         "conditionStats": neutral_conditions},
             "injured", None, "semantic.question.wellbeing.injured"),
            ("thirst", {"healthState": "healthy",
                        "needs": {"hunger": 0.05, "thirst": 0.95, "fatigue": 0.05},
                        "conditionStats": neutral_conditions},
             "healthy", "thirst", "semantic.question.wellbeing.thirst"),
            ("panic", {"healthState": "healthy", "needs": neutral_needs,
                       "conditionStats": {"stress": 0.0, "panic": 95, "boredom": 0.0}},
             "healthy", None, "semantic.question.wellbeing.panic"),
        )
        for label, npc, health, need, template_prefix in cases:
            with self.subTest(case=label):
                with LuaSemanticWorker(self.scenario(npc)) as worker:
                    result = worker.input("Are you okay?")
                situation, response = self.assert_offline_wellbeing(result)
                self.assertEqual(situation["healthState"], health)
                self.assertEqual(situation["needs"].get("highest"), need)
                self.assertTrue(
                    response["templateID"].startswith(template_prefix),
                    response,
                )
                if label == "thirst":
                    self.assertIn(situation["needs"]["urgency"], ("severe", "emergency", "critical"))
                if label == "panic":
                    self.assertEqual(situation["emotion"]["highest"], "panic")

    def test_unknown_npc_health_and_empty_state_stay_unknown(self) -> None:
        # Explicit null overrides the legacy healthy default; explicit empty
        # state dictionaries block fallback to the world-level mock needs.
        scenario = self.scenario({
            "healthState": None, "activeBehavior": None,
            "needs": {}, "conditionStats": {},
        })
        with LuaSemanticWorker(scenario) as worker:
            result = worker.input("Are you okay?")
        situation, _ = self.assert_offline_wellbeing(result)
        self.assertIsNone(situation.get("healthState"))
        self.assertIsNone(situation["needs"].get("highest"))
        self.assertEqual(situation["activity"]["id"], "unknown")
        self.assertIsNone(situation["emotion"].get("highest"))
        # The existing default reply may still imply health. Improving that
        # reaction belongs to Phase 1; Phase 0A only proves source fidelity.

    def test_legacy_world_needs_and_editable_activity_remain_supported(self) -> None:
        scenario = self.scenario(
            {"activeBehavior": "fishing"},
            world={"thirst": 0.95},
        )
        with LuaSemanticWorker(scenario) as worker:
            result = worker.input("Are you okay?")
        situation, _ = self.assert_offline_wellbeing(result)
        self.assertEqual(situation["activity"]["id"], "fishing")
        self.assertEqual(situation["needs"]["highest"], "thirst")
        self.assertEqual(situation["healthState"], "healthy")

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
        self.assertEqual(restored["npc"]["healthState"], "injured")
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
        npc, response = self.assert_offline_wellbeing(first)
        self.assertEqual(npc["healthState"], "injured")
        self.assertTrue(response["templateID"].startswith("semantic.question.wellbeing.injured"))
        second = result.turns[1]
        self.assertTrue(second["accepted"])
        self.assertEqual(second["llmCalls"], 0)
        self.assertIsInstance(second["result"]["ir"], dict)
        self.assertIsInstance(second["contextBefore"]["state"], dict)
        # Baseline probe only: coherent follow-up reply is Phase 2 acceptance.

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
