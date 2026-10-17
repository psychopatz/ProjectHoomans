"""Pure checks for the bounded Phase 6 Semantic Lab measurement helpers."""

from __future__ import annotations

import unittest

from tools.semantic_harness.phase6_performance import _distribution, _percentile


class Phase6PerformanceHelperTests(unittest.TestCase):
    def test_percentile_interpolates_bounded_samples(self) -> None:
        self.assertEqual(_percentile([1, 2, 3, 4], 0), 1)
        self.assertEqual(_percentile([1, 2, 3, 4], 100), 4)
        self.assertEqual(_percentile([1, 2, 3, 4], 50), 2.5)

    def test_distribution_preserves_sample_count_and_order_statistics(self) -> None:
        result = _distribution([4, 1, 3, 2])
        self.assertEqual(result["count"], 4)
        self.assertEqual(result["min"], 1)
        self.assertEqual(result["median"], 2.5)
        self.assertEqual(result["max"], 4)


if __name__ == "__main__":
    unittest.main()
