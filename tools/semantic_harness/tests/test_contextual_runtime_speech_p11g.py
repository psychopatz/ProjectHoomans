"""P11G modular speech-realization registry and regression checks."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class ContextualRuntimeSpeechP11GTests(unittest.TestCase):
    def test_one_registry_exposes_domain_pack_families(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            catalog = worker.persona_catalog()["speechRealization"]

        families = set(catalog["families"])
        self.assertLessEqual(len(families), 64)
        self.assertTrue(any(item.startswith("semantic.command.") for item in families))
        self.assertTrue(any(item.startswith("semantic.question.") for item in families))
        self.assertTrue(any(item.startswith("semantic.social.") for item in families))
        self.assertEqual(len(catalog["coverage"]), 15)

    def test_domain_pack_resolution_preserves_style_and_translation_contract(self) -> None:
        neutral = deepcopy(DEFAULT_SCENARIO)
        neutral["runtime"]["language"] = "EN"
        warm = deepcopy(neutral)
        warm["npc"]["personalityOverride"] = True
        warm["npc"]["personality"] = {
            "socialStyle": "friendly",
            "romanceStyle": "flirty",
        }
        with LuaSemanticWorker(neutral) as worker:
            english = worker.input("Are you okay?")
            warm_response = worker.configure(warm)
            self.assertTrue(warm_response["ok"])
            styled = worker.input("Are you okay?")

        english_response = english["observation"]["response"]
        styled_response = styled["observation"]["response"]
        self.assertEqual(
            english_response["templateID"],
            styled_response["templateID"],
        )
        self.assertTrue(
            styled_response.get("realizationFamily")
            or styled_response.get("realizationVariant")
        )

    def test_en_tl_keep_semantic_identity_while_translating_pack_output(self) -> None:
        responses = {}
        for language in ("EN", "TL"):
            scenario = deepcopy(DEFAULT_SCENARIO)
            scenario["runtime"]["language"] = language
            with LuaSemanticWorker(scenario) as worker:
                responses[language] = worker.input("Are you okay?")

        en = responses["EN"]["observation"]["response"]
        tl = responses["TL"]["observation"]["response"]
        self.assertEqual(en["templateID"], tl["templateID"])
        self.assertEqual(en["realizationFamily"], tl["realizationFamily"])
        self.assertNotEqual(en["text"], tl["text"])


if __name__ == "__main__":
    unittest.main()
