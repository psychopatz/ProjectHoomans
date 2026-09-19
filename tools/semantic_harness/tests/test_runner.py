"""Bounded conflict-ledger contract tests."""

from __future__ import annotations

import unittest
from unittest.mock import patch

from tools.semantic_harness.runner import ConflictLedger, detect_conflicts


def event_turn(event_id: str) -> dict[str, object]:
    return {
        "transport": [
            {
                "direction": "server_to_client",
                "payload": {"eventID": event_id},
            }
        ]
    }


class ConflictLedgerTests(unittest.TestCase):
    def test_streaming_ledger_matches_duplicate_detection(self) -> None:
        turns = [event_turn("evt-1"), event_turn("evt-1")]
        ledger = ConflictLedger()
        for turn in turns:
            ledger.add(turn)

        self.assertEqual(ledger.report(), detect_conflicts(turns))
        self.assertEqual(ledger.report()[0]["kind"], "duplicate_authoritative_event")
        self.assertEqual(ledger.report()[0]["firstTurnIndex"], 1)

    def test_event_id_limit_is_bounded_and_reported(self) -> None:
        with patch("tools.semantic_harness.runner.MAX_TRACKED_EVENT_IDS", 1):
            ledger = ConflictLedger()
            ledger.add(event_turn("evt-1"))
            ledger.add(event_turn("evt-2"))
            report = ledger.report()

        self.assertEqual(len(ledger._event_ids), 1)
        self.assertEqual(report[-1]["kind"], "audit_truncated")
        self.assertIn("event_id_limit", report[-1]["reasons"])

    def test_conflict_output_limit_keeps_a_truncation_marker(self) -> None:
        turns = [{"result": {"sequence": 1}}]
        turns.extend({"result": {"sequence": 1}} for _ in range(5))
        with patch("tools.semantic_harness.runner.MAX_REPORTED_CONFLICTS", 2):
            report = detect_conflicts(turns)

        self.assertEqual(len(report), 2)
        self.assertEqual(report[-1]["kind"], "audit_truncated")
        self.assertEqual(report[-1]["reasons"], ["conflict_limit"])

    def test_malformed_turn_is_a_reported_conflict(self) -> None:
        report = detect_conflicts([None])  # type: ignore[list-item]
        self.assertEqual(report, [{"kind": "invalid_turn_record", "turnIndex": 1}])

    def test_malformed_transport_collection_is_reported(self) -> None:
        report = detect_conflicts([{"transport": None}])
        self.assertEqual(
            report,
            [{"kind": "invalid_transport_collection", "turnIndex": 1}],
        )


if __name__ == "__main__":
    unittest.main()
