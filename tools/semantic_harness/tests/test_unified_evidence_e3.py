"""Bounded compact retention remains useful after detailed retention drops."""
import unittest
from tools.semantic_harness.tests.test_unified_evidence_e0 import saved_worker, storage, turn, byte_size


class UnifiedEvidenceE3Tests(unittest.TestCase):
    def test_today_survives_relationship_saturation(self):
        with saved_worker() as worker:
            before = storage(worker, saturate=True)
            result = turn(worker, "fuck you")
            after = storage(worker)
        self.assertEqual(result["action"]["relationshipMemoryOutcome"]["status"], "pruned")
        self.assertTrue(result["action"]["accepted"])
        self.assertEqual(len(after["relationship"]["memories"]), 20)
        self.assertEqual(after["memory"]["s"][0], 1026626453)
        self.assertLess(byte_size(after["serializedRecord"]) - byte_size(before["serializedRecord"]), 4000)
        self.assertEqual(before["roots"], after["roots"])

    def test_salience_pressure_coalescing_and_day_rollover(self):
        churn = ["player_greeted", "npc_greeted_player", "player_farewelled",
                 "player_thanked", "player_praised", "player_saluted",
                 "player_disapproved", "witnessed_player_kill", "witnessed_player_hurt"]
        with saved_worker() as worker:
            storage(worker, project="saved_from_incapacitation")
            for _ in range(5):
                for event in churn:
                    snapshot = storage(worker, project=event)
                    self.assertLessEqual(len(snapshot["memory"]["s"]), 24)
            values = snapshot["memory"]["s"]
            self.assertIn(1101, values[::3])
            self.assertEqual(len(set(zip(values[::3], values[1::3]))), len(values) // 3)
            repeated = storage(worker, project="saved_from_incapacitation")
            self.assertEqual(len(repeated["memory"]["s"]), len(values))
            rolled = storage(worker, advanceDays=1)
            self.assertFalse(rolled["memory"].get("s"))
            self.assertLessEqual(len(rolled["memory"].get("l", [])), 24)
