"""First-party semantic and compact metadata have one domain-owned source."""
import unittest
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO


class UnifiedEvidenceE2Tests(unittest.TestCase):
    def test_all_social_types_derive_canonical_registration(self):
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            audit = worker._request("TEST_EVIDENCE_METADATA")
        self.assertEqual(len(audit["rows"]), 23)
        codes = {row["id"]: row["code"] for row in audit["rows"]}
        self.assertNotIn(
            "witnessed_player_kill",
            codes,
            "routine zombie kills are ephemeral semantic stimuli, not durable evidence",
        )
        self.assertEqual(codes["saved_from_incapacitation"], 1101)
        self.assertEqual(codes["abandoned_in_combat"], 1102)
        self.assertEqual(codes["protected_from_attacker"], 1103)
        self.assertEqual(codes["survived_horde_attack"], 1104)
        self.assertEqual(codes["player_dialogue_insult"], 1026626453)
        for row in audit["rows"]:
            self.assertTrue(row["described"], row)
            self.assertTrue(row["canonical"], row)
            self.assertFalse(row["dynamic"], row)
            self.assertGreater(row["retentionSalience"], 0)
            if row["actorPolicyRequired"]:
                self.assertTrue(row["actorCanonical"], row)
        self.assertTrue(audit["fallbackDynamic"])
