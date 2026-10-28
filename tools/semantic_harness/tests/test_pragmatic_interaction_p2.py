"""P2 real-worker acceptance for pragmatic beat/behavior arbitration."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


def merged(base: dict, patch: dict) -> dict:
    result = deepcopy(base)
    for key, value in patch.items():
        if isinstance(value, dict) and isinstance(result.get(key), dict):
            result[key] = merged(result[key], value)
        else:
            result[key] = deepcopy(value)
    return result


class PragmaticInteractionP2Tests(unittest.TestCase):
    def run_turn(self, patch: dict, text: str):
        with LuaSemanticWorker(merged(DEFAULT_SCENARIO, patch)) as worker:
            return worker.input(text)

    def selected(self, result: dict) -> tuple[str | None, str | None]:
        director = result["result"]["decision"].get("director") or {}
        return (
            (director.get("selectedBeat") or {}).get("id"),
            (director.get("selectedBehavior") or {}).get("id"),
        )

    def test_same_hostile_semantics_yield_contextual_behaviors(self) -> None:
        cases = [
            (
                {},
                "behavior.warn",
                "BOUNDARY_WARNING",
            ),
            (
                {
                    "npc": {
                        "personality": {
                            "aggression": 0.95,
                            "confidence": 0.85,
                            "forgiveness": 0.8,
                        }
                    }
                },
                "behavior.retaliate_verbally",
                "RETALIATE_VERBALLY",
            ),
            (
                {
                    "npc": {
                        "personality": {
                            "aggression": 0.2,
                            "confidence": 0.2,
                            "forgiveness": 0.8,
                        },
                        "conditionStats": {
                            "panic": 90,
                            "stress": 0,
                            "boredom": 0,
                        },
                    }
                },
                "behavior.deescalate",
                "DEESCALATE",
            ),
        ]
        for patch, expected_behavior, expected_act in cases:
            with self.subTest(expected_behavior=expected_behavior):
                result = self.run_turn(patch, "fuck ypuuuu")
                ir = result["result"]["ir"]
                self.assertEqual(ir["intent"], "HOSTILE_REMARK")
                self.assertEqual(ir["speechAct"], "HOSTILE_REMARK")
                self.assertEqual(ir["provenance"]["pattern"], "pnc.social.profanity")
                self.assertEqual(
                    self.selected(result),
                    ("beat.argument_escalation", expected_behavior),
                )
                decision = result["result"]["decision"]
                response = decision["response"]
                plan = response["plan"]
                self.assertEqual(response["sourcePoolID"], "semantic.hostile_remark")
                self.assertEqual(plan["sourcePoolID"], "semantic.hostile_remark")
                self.assertEqual(plan["dialogueAct"], expected_act)
                self.assertEqual(
                    decision["interactionPlan"]["behaviorID"],
                    expected_behavior,
                )
                self.assertEqual(
                    decision["interactionPlan"]["dialogueAct"],
                    expected_act,
                )
                self.assertNotEqual(
                    response.get("fallback"),
                    "I'm not sure what you mean.",
                )
                self.assertNotEqual(
                    response.get("selectionSource"),
                    "director",
                )

    def test_argument_exits_into_reconciliation_after_apology(self) -> None:
        scenario = merged(
            DEFAULT_SCENARIO,
            {"npc": {"personality": {"forgiveness": 0.85}}},
        )
        with LuaSemanticWorker(scenario) as worker:
            hostile = worker.input("fuck you")
            apology = worker.input("sorry")

        self.assertEqual(
            self.selected(hostile),
            ("beat.argument_escalation", "behavior.warn"),
        )
        director = apology["result"]["decision"]["director"]
        self.assertEqual(apology["result"]["ir"]["intent"], "APOLOGIZE")
        self.assertEqual(
            (director.get("exited") or {}).get("id"),
            "beat.argument_escalation",
        )
        self.assertEqual(
            (director.get("entered") or {}).get("id"),
            "beat.reconciliation",
        )
        self.assertEqual(
            (director.get("selectedBeat") or {}).get("id"),
            "beat.reconciliation",
        )
        self.assertEqual(
            (director.get("selectedBehavior") or {}).get("id"),
            "behavior.reconcile",
        )
        apology_decision = apology["result"]["decision"]
        self.assertEqual(
            apology_decision["response"]["sourcePoolID"],
            "semantic.apology",
        )
        self.assertEqual(
            apology_decision["response"]["plan"]["dialogueAct"],
            "RECONCILE",
        )
        self.assertEqual(
            apology_decision["interactionPlan"]["behaviorID"],
            "behavior.reconcile",
        )

    def test_active_argument_does_not_hijack_unrelated_grounded_question(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            hostile = worker.input("fuck you")
            wellbeing = worker.input("are you okay")

        self.assertEqual(
            (hostile["result"]["decision"]["director"]["selectedBeat"] or {}).get("id"),
            "beat.argument_escalation",
        )
        decision = wellbeing["result"]["decision"]
        director = decision.get("director") or {}
        self.assertEqual(
            (director.get("selectedBeat") or {}).get("id"),
            "beat.argument_escalation",
        )
        self.assertIsNone(director.get("selectedBehavior"))
        self.assertEqual(decision["branch"], "QUESTION_RECEIVED")
        self.assertNotEqual(
            decision["response"].get("sourcePoolID"),
            "semantic.hostile_remark",
        )

    def test_director_commit_stays_bounded_in_conversation_context(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            first = worker.input("fuck you")
            second = worker.input("sorry")
            snapshot = second.get("contextAfter") or {}

        director = (snapshot.get("dialogue") or {}).get("director") or {}
        active = director.get("active") or {}
        self.assertEqual(active.get("id"), "beat.reconciliation")
        self.assertLessEqual(len(director.get("recent") or []), 4)
        self.assertLessEqual(len(director.get("cooldowns") or {}), 16)
        self.assertGreaterEqual(int(director.get("revision") or 0), 2)


if __name__ == "__main__":
    unittest.main()
