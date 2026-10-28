"""Bounded compact retention remains useful after detailed retention drops."""
import unittest
from tools.semantic_harness.tests.test_unified_evidence_e0 import saved_worker, storage, turn, byte_size


class UnifiedEvidenceE3Tests(unittest.TestCase):
    def test_durable_owner_survives_day_without_compact_today(self):
        with saved_worker() as worker:
            storage(worker, addMemory="abandoned_in_combat")
            after = storage(worker, advanceDays=1)
            rows = after["evidence"]["rows"]
            self.assertEqual(len(rows), 1)
            self.assertEqual(rows[0]["sourceTier"], "DURABLE")
            self.assertEqual(rows[0]["relations"]["opens"], ["repair"])
            self.assertEqual(rows[0]["effectiveStrength"], 1)
            self.assertFalse((after.get("memory") or {}).get("s"))

    def test_production_turn_exposes_all_tiers_and_cross_session_recall(self):
        with saved_worker() as worker:
            worker.input("fuck you")
            serialized = storage(worker)["serializedRecord"]
            result = worker.input("im sorry")
            evidence = result["observation"]["director"]["pragmatic"]["evidence"]
            tiers = {row["sourceTier"] for row in evidence["rows"]}
            self.assertEqual(tiers, {"SESSION", "TODAY", "DURABLE"})
            self.assertTrue(all(row["status"] == "queried" for row in evidence["providers"]))
        with saved_worker(serialized) as replay:
            evidence = storage(replay)["evidence"]
            self.assertEqual({row["sourceTier"] for row in evidence["rows"]}, {"TODAY", "DURABLE"})
            rows = evidence["rows"]
            self.assertTrue(all(row["relations"]["opens"] == ["repair"] for row in rows))
            self.assertTrue(all(row["retentionSalience"] == 150 for row in rows))
            self.assertFalse(any("contextualRelevance" in row for row in rows))

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
                 "player_disapproved", "witnessed_player_hurt"]
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
