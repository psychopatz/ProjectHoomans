"""Visible transcript retention contract tests."""

from __future__ import annotations

import unittest

from tools.semantic_harness.transcript import TranscriptBuffer


class TranscriptBufferTests(unittest.TestCase):
    def test_caps_entry_size_and_discards_oldest_messages(self) -> None:
        transcript = TranscriptBuffer(max_entries=2, max_chars=80, max_entry_chars=40)
        first, removed = transcript.append("PLAYER", "x" * 100)
        self.assertEqual(removed, 0)
        self.assertLessEqual(len(first), 40)
        self.assertIn("truncated", first)

        _, removed = transcript.append("NPC", "one")
        self.assertEqual(removed, 0)
        third, removed = transcript.append("NPC", "two")
        self.assertEqual(removed, len(first))
        self.assertLessEqual(len(third), 40)
        self.assertEqual(transcript.entry_count, 2)
        self.assertEqual(transcript.char_count, len("NPC: one\n\n") + len(third))

    def test_character_limit_and_clear_keep_accounting_consistent(self) -> None:
        transcript = TranscriptBuffer(max_entries=10, max_chars=40, max_entry_chars=40)
        first, _ = transcript.append("A", "one")
        second, removed = transcript.append("B", "x" * 100)
        self.assertEqual(removed, len(first))
        self.assertIn("truncated", second)
        self.assertEqual(transcript.char_count, 40)

        transcript.clear()
        self.assertEqual(transcript.entry_count, 0)
        self.assertEqual(transcript.char_count, 0)

    def test_rejects_impossible_limits(self) -> None:
        with self.assertRaisesRegex(ValueError, "too small"):
            TranscriptBuffer(max_chars=12, max_entry_chars=12)


if __name__ == "__main__":
    unittest.main()
