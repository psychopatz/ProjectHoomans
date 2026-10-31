"""First-party semantic and compact metadata have one domain-owned source."""
import unittest
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO


class UnifiedEvidenceE2Tests(unittest.TestCase):
    def test_all_social_types_derive_canonical_registration(self):
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            audit = worker._request("TEST_EVIDENCE_METADATA")
        self.assertSetEqual(
            {row["id"] for row in audit["rows"]},
            {
                'abandoned_in_combat',
                'faction_member_attacked',
                'necroa_mask_removed',
                'necroa_player_mask_removed',
                'npc_dialogue_hostile_remark',
                'npc_dialogue_insult',
                'npc_dialogue_threat',
                'npc_proximity_greeting',
                'player_damaged_npc',
                'player_dialogue_hostile_remark',
                'player_dialogue_insult',
                'player_dialogue_threat',
                'player_emote_clap',
                'player_emote_insult',
                'player_emote_salute',
                'player_emote_thankyou',
                'player_emote_thumbsdown',
                'player_emote_thumbsup',
                'player_emote_wavebye',
                'player_emote_wavehi',
                'protected_from_attacker',
                'saved_from_incapacitation',
                'survived_combat_together',
                'survived_horde_attack',
                'treated_wound',
                'witnessed_player_hurt',
            },
        )
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
