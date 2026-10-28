from __future__ import annotations

import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class CoherentConversationC1C2Tests(unittest.TestCase):
    def run_input(self, text: str) -> dict:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            return worker.input(text)

    def test_compact_and_elongated_social_language_recovers_semantically(self):
        cases = [
            ("fuckyou", "INSULT", "compact_alias"),
            ("fuckyouuuu", "INSULT", "elongated_compact_alias"),
            ("shutthefuckup", "HOSTILE_REMARK", "compact_alias"),
            ("youidiot", "INSULT", "compact_alias"),
            ("youreuseless", "INSULT", "compact_alias"),
            ("illkillyou", "THREATEN", "compact_alias"),
            ("gooo away", "HOSTILE_REMARK", "elongation"),
        ]
        for text, expected, recovery_kind in cases:
            with self.subTest(text=text):
                result = self.run_input(text)
                ir = result["result"]["ir"]
                self.assertEqual(ir["intent"], expected)
                recovery = ir["provenance"]["surfaceRecovery"]
                self.assertEqual(recovery["kind"], recovery_kind)
                self.assertFalse(recovery["mutationSafe"])
                self.assertEqual(ir["normalizedText"], text.lower())

    def test_exact_input_remains_exact_and_unrecovered(self):
        result = self.run_input("fuck you")
        ir = result["result"]["ir"]
        self.assertEqual(ir["intent"], "INSULT")
        self.assertEqual(ir["provenance"]["candidatePass"], "exact")
        self.assertNotIn("surfaceRecovery", ir["provenance"])

    def test_recovered_mutating_actions_are_rejected_by_candidate_eligibility(self):
        for text, pattern in (
            ("followme", "pnc.command.follow"),
            ("gohome", "pnc.command.go_home"),
        ):
            with self.subTest(text=text):
                result = self.run_input(text)
                ir = result["result"]["ir"]
                diagnostics = result["result"]["candidateDiagnostics"]
                self.assertIsNone(ir.get("action"))
                self.assertEqual(diagnostics["reason"], "no_eligible_candidate")
                rejection = next(
                    item for item in diagnostics["rejections"]
                    if item["patternID"] == pattern
                )
                self.assertEqual(
                    rejection["reason"],
                    "recovered_mutating_action",
                )
                self.assertFalse(
                    rejection["details"]["recovery"]["mutationSafe"]
                )

    def test_malicious_wish_is_hostile_but_not_equivalent_to_threat(self):
        wish = self.run_input("i hope you die")["result"]["ir"]
        threat = self.run_input("i'll kill you")["result"]["ir"]

        self.assertEqual(wish["intent"], "HOSTILE_REMARK")
        self.assertTrue(wish["socialContext"]["maliciousWish"])
        wish_features = wish["extensions"]["socialFeatures"]
        self.assertEqual(wish_features["directedness"], "RECIPIENT")
        self.assertGreaterEqual(wish_features["hostility"], 0.8)
        self.assertLess(wish_features["threat"], 0.5)

        self.assertEqual(threat["intent"], "THREATEN")
        threat_features = threat["extensions"]["socialFeatures"]
        self.assertGreaterEqual(threat_features["threat"], 0.9)

    def test_world_profanity_is_not_recipient_hostility(self):
        ir = self.run_input("i fucking hate this rain")["result"]["ir"]
        self.assertEqual(ir["intent"], "COMPLAIN")
        self.assertEqual(ir["subject"], "WORLD")
        features = ir["extensions"]["socialFeatures"]
        self.assertEqual(features["directedness"], "WORLD")
        self.assertEqual(features["hostility"], 0)
        self.assertEqual(features["threat"], 0)

    def test_intensified_need_beats_identity_capture(self):
        ir = self.run_input("i'm fucking starving")["result"]["ir"]
        self.assertEqual(ir["intent"], "INFORM")
        self.assertEqual(ir["subject"], "HUNGER")
        self.assertNotIn("identityClaim", ir.get("socialContext", {}))
        features = ir["extensions"]["socialFeatures"]
        self.assertEqual(features["directedness"], "SELF")
        self.assertEqual(features["hostility"], 0)

    def test_negated_negative_assessment_is_not_insult(self):
        ir = self.run_input("you're not bad")["result"]["ir"]
        self.assertEqual(ir["intent"], "COMPLIMENT")
        self.assertTrue(ir["socialContext"]["negatedNegative"])
        features = ir["extensions"]["socialFeatures"]
        self.assertTrue(features["negatedNegative"])
        self.assertGreater(features["valence"], 0)
        self.assertLessEqual(features["hostility"], 0.1)

    def test_existing_fuzzy_action_safety_is_preserved(self):
        result = self.run_input("give me waterr")
        ir = result["result"]["ir"]
        decision = result["result"]["decision"]
        self.assertEqual(ir["intent"], "REQUEST")
        self.assertEqual(ir["action"], "GIVE")
        self.assertEqual(decision["branch"], "ASK_CLARIFICATION")


if __name__ == "__main__":
    unittest.main()
