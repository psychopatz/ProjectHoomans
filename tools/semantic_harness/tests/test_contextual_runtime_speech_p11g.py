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
        self.assertIn("semantic.flow.greeting.opening.default", families)
        self.assertIn("semantic.question.wellbeing.default", families)
        self.assertIn("semantic.question.knowledge.known", families)
        self.assertNotIn(
            "UI_PNC_Conversation_Semantic_GeneratedFollowQueued",
            families,
        )
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            follow = worker.input("Follow me")
        self.assertEqual(
            follow["messages"][0]["payload"]["phraseFamilyID"],
            "phrase.semantic.command.follow.queued",
        )
        phrase_content = catalog["phraseContent"]
        self.assertTrue(phrase_content["families"])
        self.assertEqual(len(phrase_content["fingerprint"]), 64)
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
