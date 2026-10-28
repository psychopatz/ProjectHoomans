from __future__ import annotations

from copy import deepcopy
from pathlib import Path
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


REAL_SAVE = Path(
    "/home/psychopatz/Zomboid/Saves/Sandbox/"
    "2026-10-22_15-18-56/global_mod_data.bin"
)
DANA_NPC_ID = "npcDanapatz_Y5KK"


def payload(turn: dict) -> dict:
    return turn["messages"][0]["payload"]


def generated(turn: dict, strategy: str) -> dict:
    return next(
        row
        for row in turn["observation"]["suggestions"]["candidates"]
        if row.get("strategy") == strategy
        and row.get("providerID")
        == "projecthoomans.generated_affordances"
    )


def warning_sequence(scenario: dict, count: int = 4) -> list[tuple[str, str]]:
    rows: list[tuple[str, str]] = []
    with LuaSemanticWorker(deepcopy(scenario)) as worker:
        worker.open_conversation()
        turn = worker.input("fuckyouuuu")
        for _ in range(count):
            plan = turn["observation"]["interactionPlan"]
            if plan.get("behaviorID") != "behavior.warn":
                break
            current = payload(turn)
            rows.append(
                (
                    current["text"],
                    current["realizationVariant"],
                )
            )
            # Repeated typed hostility remains valid even when the generated
            # frontier suppresses an immediate DOUBLE_DOWN self-loop.
            turn = worker.input("fuckyouuuu")
    return rows


class LiveRegressionL4Tests(unittest.TestCase):
    def test_warn_uses_compositional_realization(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            turn = worker.input("fuckyouuuu")

        self.assertEqual(
            turn["observation"]["interactionPlan"]["behaviorID"],
            "behavior.warn",
        )
        current = payload(turn)
        self.assertEqual(current["realizationFamily"], "utterance_plan")
        self.assertTrue(
            current["realizationVariant"].startswith(
                "construction.en.social.warn_"
            )
        )
        self.assertEqual(
            current["utterancePlan"]["strategy"],
            "WARN",
        )
        self.assertEqual(
            current["utterancePlan"]["dialogueAct"],
            "BOUNDARY_WARNING",
        )
        self.assertNotIn("uuu", current["text"].lower())

    def test_warn_variation_is_bounded_deterministic_and_stateless(self) -> None:
        first = warning_sequence(DEFAULT_SCENARIO)
        second = warning_sequence(DEFAULT_SCENARIO)
        self.assertEqual(first, second)
        self.assertEqual(len(first), 4)
        self.assertEqual(len(set(first)), 4)
        for text, construction in first:
            self.assertTrue(text)
            self.assertTrue(
                construction.startswith("construction.en.social.warn_")
            )

    def test_warn_constructions_are_locale_owned(self) -> None:
        surfaces: dict[str, tuple[str, str]] = {}
        for language in ("EN", "TL"):
            scenario = deepcopy(DEFAULT_SCENARIO)
            scenario["runtime"]["language"] = language
            with LuaSemanticWorker(scenario) as worker:
                turn = worker.input("fuckyouuuu")
            current = payload(turn)
            surfaces[language] = (
                current["text"],
                current["realizationVariant"],
            )
            self.assertEqual(
                current["realizationFamily"],
                "utterance_plan",
            )
            self.assertIn(
                f"construction.{language.lower()}.social.warn_",
                current["realizationVariant"],
            )
        self.assertNotEqual(surfaces["EN"][0], surfaces["TL"][0])

    def test_aggressive_npc_still_selects_contextual_mirror(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["personalityOverride"] = True
        scenario["npc"]["personality"] = {
            "aggression": 0.95,
            "confidence": 0.85,
            "forgiveness": 0.8,
        }
        with LuaSemanticWorker(scenario) as worker:
            turn = worker.input("fuckyouuuu")

        self.assertEqual(
            turn["observation"]["interactionPlan"]["behaviorID"],
            "behavior.retaliate_verbally",
        )
        current = payload(turn)
        self.assertEqual(current["realizationFamily"], "utterance_plan")
        self.assertEqual(current["utterancePlan"]["strategy"], "MIRROR")
        self.assertTrue(
            current["realizationVariant"].startswith(
                "construction.en.social.mirror_retort"
            )
        )

    @unittest.skipUnless(REAL_SAVE.is_file(), "local Dana save unavailable")
    def test_exact_dana_warn_is_compositional_and_memory_safe(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.import_saved_selection(REAL_SAVE, npc_id=DANA_NPC_ID)
            worker.open_conversation()
            turn = worker.input("fuckyouuuu")

        self.assertTrue(turn["result"]["actionResult"]["accepted"])
        self.assertEqual(
            turn["result"]["actionResult"]["relationshipMemoryOutcome"][
                "status"
            ],
            "pruned",
        )
        self.assertEqual(
            turn["observation"]["interactionPlan"]["behaviorID"],
            "behavior.warn",
        )
        current = payload(turn)
        self.assertEqual(current["realizationFamily"], "utterance_plan")
        self.assertEqual(current["utterancePlan"]["strategy"], "WARN")
        self.assertNotIn(
            "couldn't apply that social reaction",
            current["text"].lower(),
        )
        self.assertEqual(
            turn["conversationPresentation"]["responseChannel"]["groupID"],
            "conversation_branch",
        )


if __name__ == "__main__":
    unittest.main()
