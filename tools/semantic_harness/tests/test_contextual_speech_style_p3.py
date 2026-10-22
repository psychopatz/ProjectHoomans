"""P3 transient speech-style and realization-family contracts."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class ContextualSpeechStyleP3Tests(unittest.TestCase):
    def _scenario(self, **npc_updates: object) -> dict:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"].update(npc_updates)
        return scenario

    def _turn(self, scenario: dict, language: str = "EN") -> dict:
        with LuaSemanticWorker(deepcopy(scenario)) as worker:
            if language != "EN":
                worker.set_language(language)
            return worker.input("hello")

    def test_style_families_change_only_realization_fields(self) -> None:
        neutral = self._turn(
            self._scenario(
                traits=[],
                personality={
                    "socialStyle": "neutral",
                    "compassion": 0.5,
                    "sociability": 0.5,
                    "aggression": 0.5,
                },
                relationship={
                    "approval": 0,
                    "respect": 0,
                    "familiarity": 0,
                    "revision": 1,
                },
            )
        )
        warm = self._turn(
            self._scenario(
                traits=["friendly"],
                personality={
                    "socialStyle": "friendly",
                    "compassion": 0.9,
                    "sociability": 0.9,
                    "aggression": 0.1,
                },
                relationship={
                    "approval": 80,
                    "respect": 70,
                    "familiarity": 80,
                    "revision": 2,
                    "relationshipState": "friend",
                    "identityTrust": "trusted",
                },
            )
        )
        guarded = self._turn(
            self._scenario(
                traits=["reserved"],
                personality={
                    "socialStyle": "withdrawn",
                    "compassion": 0.1,
                    "sociability": 0.1,
                    "aggression": 0.7,
                },
                relationship={
                    "approval": -80,
                    "respect": -20,
                    "familiarity": 0,
                    "revision": 3,
                    "relationshipState": "enemy",
                    "identityTrust": "untrustworthy",
                },
            )
        )

        neutral_style = neutral["contextAfter"]["speechStyleContext"]
        warm_style = warm["contextAfter"]["speechStyleContext"]
        guarded_style = guarded["contextAfter"]["speechStyleContext"]
        self.assertEqual(neutral_style["variant"], "neutral")
        self.assertEqual(warm_style["variant"], "warm")
        self.assertEqual(guarded_style["variant"], "guarded")

        neutral_response = neutral["observation"]["response"]
        warm_response = warm["observation"]["response"]
        guarded_response = guarded["observation"]["response"]
        self.assertNotEqual(neutral_response["key"], warm_response["key"])
        self.assertNotEqual(neutral_response["key"], guarded_response["key"])
        self.assertEqual(
            neutral_response["sourcePoolID"], warm_response["sourcePoolID"]
        )
        self.assertEqual(
            neutral_response["sourcePoolID"], guarded_response["sourcePoolID"]
        )
        self.assertEqual(
            {row["id"] for row in neutral["observation"]["suggestions"]["candidates"]},
            {row["id"] for row in warm["observation"]["suggestions"]["candidates"]},
        )
        self.assertEqual(
            {row["id"] for row in neutral["observation"]["suggestions"]["candidates"]},
            {row["id"] for row in guarded["observation"]["suggestions"]["candidates"]},
        )
        self.assertEqual(
            neutral_response["plan"]["kind"], warm_response["plan"]["kind"]
        )
        self.assertEqual(
            neutral_response["plan"]["sourcePoolID"],
            warm_response["plan"]["sourcePoolID"],
        )
        self.assertTrue(neutral_response["realization"]["applied"])
        self.assertEqual(neutral_response["realization"]["neutralFallbackCount"], 0)

    def test_terse_variant_is_deterministic_and_gender_neutral(self) -> None:
        terse = self._turn(
            self._scenario(
                identity={"isFemale": True, "identitySource": "registry"},
                traits=[],
                personality={
                    "socialStyle": "neutral",
                    "compassion": 0.5,
                    "sociability": 0.0,
                    "aggression": 0.9,
                },
                relationship={
                    "familiarity": 50,
                },
                activeBehavior="busy",
            )
        )
        same_without_gender = self._turn(
            self._scenario(
                identity={"isFemale": False, "identitySource": "registry"},
                traits=[],
                personality={
                    "socialStyle": "neutral",
                    "compassion": 0.5,
                    "sociability": 0.0,
                    "aggression": 0.9,
                },
                relationship={
                    "familiarity": 50,
                },
                activeBehavior="busy",
            )
        )

        terse_style = terse["contextAfter"]["speechStyleContext"]
        same_style = same_without_gender["contextAfter"]["speechStyleContext"]
        self.assertEqual(terse_style["variant"], "terse")
        self.assertEqual(terse_style["dimensions"], same_style["dimensions"])
        self.assertFalse(terse_style["privacy"]["genderUsed"])
        self.assertEqual(
            terse["observation"]["response"]["key"],
            same_without_gender["observation"]["response"]["key"],
        )

    def test_tl_uses_the_same_realization_family_and_semantic_plan(self) -> None:
        scenario = self._scenario(
            traits=["friendly"],
            personality={"socialStyle": "friendly", "compassion": 0.9},
            relationship={
                "approval": 70,
                "respect": 60,
                "familiarity": 75,
                "revision": 5,
                "relationshipState": "friend",
            },
        )
        english = self._turn(scenario, "EN")
        tagalog = self._turn(scenario, "TL")
        self.assertEqual(
            english["observation"]["response"]["key"],
            tagalog["observation"]["response"]["key"],
        )
        self.assertEqual(
            english["observation"]["response"]["sourcePoolID"],
            tagalog["observation"]["response"]["sourcePoolID"],
        )
        self.assertEqual(
            english["observation"]["response"]["plan"]["sourcePoolID"],
            tagalog["observation"]["response"]["plan"]["sourcePoolID"],
        )
        self.assertEqual(
            english["contextAfter"]["speechStyleContext"]["variant"],
            tagalog["contextAfter"]["speechStyleContext"]["variant"],
        )


if __name__ == "__main__":
    unittest.main()
