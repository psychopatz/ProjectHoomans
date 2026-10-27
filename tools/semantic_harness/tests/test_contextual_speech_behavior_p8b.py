"""P8B production-worker speech-family and bond realization coverage."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class ContextualSpeechBehaviorP8BTests(unittest.TestCase):
    def _scenario(self, style: str, bond: str | None = None) -> dict:
        scenario = deepcopy(DEFAULT_SCENARIO)
        npc = scenario["npc"]
        if style == "warm":
            npc.update(
                {
                    "traits": ["friendly"],
                    "personality": {
                        "socialStyle": "friendly",
                        "compassion": 0.95,
                        "sociability": 0.95,
                        "forgiveness": 0.9,
                        "bravery": 0.8,
                        "aggression": 0.1,
                    },
                    "relationship": {
                        "approval": 80,
                        "respect": 70,
                        "familiarity": 100,
                    },
                }
            )
        elif style == "guarded":
            npc.update(
                {
                    "traits": ["reserved"],
                    "personality": {
                        "socialStyle": "withdrawn",
                        "compassion": 0.1,
                        "sociability": 0.1,
                        "forgiveness": 0.1,
                        "bravery": 0.1,
                        "aggression": 0.9,
                    },
                    "relationship": {
                        "approval": -80,
                        "respect": -20,
                        "familiarity": 100,
                    },
                }
            )
        else:
            npc.update(
                {
                    "traits": [],
                    "personality": {
                        "socialStyle": "neutral",
                        "compassion": 0.5,
                        "sociability": 0.5,
                        "forgiveness": 0.5,
                        "bravery": 0.5,
                        "aggression": 0.5,
                    },
                    "relationship": {
                        "approval": 0,
                        "respect": 0,
                        "familiarity": 0,
                    },
                }
            )
        if bond is not None:
            npc["startingRelationship"] = {
                "kind": bond,
                "source": "starting_companion_trait",
            }
        return scenario

    def _turn(self, scenario: dict, text: str, language: str = "EN") -> dict:
        with LuaSemanticWorker(deepcopy(scenario)) as worker:
            if language != "EN":
                worker.set_language(language)
            return worker.input(text)

    @staticmethod
    def _response(turn: dict) -> tuple[dict, dict]:
        response = turn["observation"]["response"]
        queued = (response.get("queued") or [response])[0]
        return response, queued

    def test_non_greeting_production_families_have_visible_variants(self) -> None:
        texts = (
            "how are you doing?",
            "are you hurt?",
            "what is your name?",
            "okay",
            "sorry",
            "I disagree",
            "back off",
            "any gossip?",
            "what are you doing?",
            "follow me",
        )
        for text in texts:
            with self.subTest(text=text):
                warm, warm_q = self._response(
                    self._turn(self._scenario("warm"), text)
                )
                guarded, guarded_q = self._response(
                    self._turn(self._scenario("guarded"), text)
                )
                self.assertTrue(warm_q.get("realizationFamily"), text)
                self.assertTrue(guarded_q.get("realizationFamily"), text)
                self.assertIn(
                    warm_q.get("realizationVariant"),
                    {"warm", "guarded", "neutral", "terse"},
                )
                self.assertIn(
                    guarded_q.get("realizationVariant"),
                    {"warm", "guarded", "neutral", "terse"},
                )
                self.assertNotEqual(warm_q.get("text"), guarded_q.get("text"))
                # Style changes presentation only: the production semantic
                # response/action lane remains the same family of meaning.
                self.assertEqual(warm.get("result", {}).get("ir", {}).get("intent"),
                                 guarded.get("result", {}).get("ir", {}).get("intent"))
                self.assertEqual(
                    warm.get("result", {}).get("ir", {}).get("action"),
                    guarded.get("result", {}).get("ir", {}).get("action"),
                )

    def test_refusal_reuse_does_not_turn_authoritative_no_into_acknowledgement(self) -> None:
        turn = self._turn(self._scenario("guarded"), "I disagree")
        response, queued = self._response(turn)
        self.assertEqual(response["selectionID"], "semantic.refuse.withdrawn")
        self.assertEqual(response["templateID"], "semantic.social.dispute_withdrawn")
        self.assertIn("leave", queued["text"].lower())

        default = self._turn(self._scenario("neutral"), "I disagree")
        _, default_q = self._response(default)
        self.assertEqual(default_q["text"], "No.")
        self.assertNotIn("hear you", default_q["text"].lower())

    def test_bond_terms_are_whole_phrase_arguments_and_standing_independent(self) -> None:
        friend = self._scenario("warm", bond="mother")
        enemy = self._scenario("guarded", bond="mother")
        friendly_turn = self._turn(friend, "okay")
        enemy_turn = self._turn(enemy, "okay")

        for turn, state in ((friendly_turn, "friend"), (enemy_turn, "enemy")):
            actor = turn["contextAfter"]["actorConversationContext"]
            self.assertEqual(actor["bond"]["class"], "family")
            self.assertEqual(actor["bond"]["kind"], "mother")
            self.assertEqual(actor["relationship"]["state"], state)
            _, queued = self._response(turn)
            self.assertEqual(queued["args"]["familyAddress"], "Mom")
            self.assertIn("Mom", queued["text"])

    def test_tl_keeps_semantic_identity_and_localizes_bond_term(self) -> None:
        scenario = self._scenario("warm", bond="mother")
        english, english_q = self._response(self._turn(scenario, "okay", "EN"))
        tagalog, tagalog_q = self._response(self._turn(scenario, "okay", "TL"))
        self.assertEqual(english["templateID"], tagalog["templateID"])
        self.assertEqual(english_q["key"], tagalog_q["key"])
        self.assertEqual(english_q["args"]["familyAddress"], "Mom")
        self.assertEqual(tagalog_q["args"]["familyAddress"], "Nanay")
        self.assertIn("Nanay", tagalog_q["text"])

    def test_production_catalog_exposes_machine_readable_realization_coverage(self) -> None:
        with LuaSemanticWorker(self._scenario("neutral")) as worker:
            catalog = worker.persona_catalog()
        coverage = catalog["speechRealization"]["coverage"]
        families = set(catalog["speechRealization"]["families"])
        phrase_content = catalog["speechRealization"]["phraseContent"]
        names = {row["family"] for row in coverage}
        self.assertTrue({"greeting", "wellbeing", "medical", "companion_action"} <= names)
        self.assertNotIn("semantic.question.health_state.healthy", families)
        self.assertTrue(phrase_content["families"])
        self.assertEqual(len(phrase_content["fingerprint"]), 64)
        self.assertIn("UI_PNC_Conversation_Semantic_GeneratedFollowQueued", families)


if __name__ == "__main__":
    unittest.main()
