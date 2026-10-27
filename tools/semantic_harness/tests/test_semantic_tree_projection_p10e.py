"""P10E coverage for the shared derived Semantic Lab tree projection."""

from __future__ import annotations

import unittest

from tools.semantic_harness.studio.semantic_tree import (
    build_semantic_tree,
    filter_semantic_tree,
)


class SemanticTreeProjectionP10ETests(unittest.TestCase):
    def setUp(self) -> None:
        self.rows = [
            {"id": "semantic.compat.bandits.hooman_hurt", "variantCount": 4},
            {"id": "semantic.compat.companion_dogs.feed", "variantCount": 3},
            {"id": "phrase.semantic.medical.distress.call", "group": "events"},
            {"id": "semantic.command.player.follow", "variantCount": 2},
        ]

    def test_tree_is_derived_and_counts_descendants(self) -> None:
        tree = build_semantic_tree(self.rows)
        self.assertEqual(tree["count"], 4)
        compatibility = tree["children"]["compat"]
        self.assertEqual(compatibility["label"], "Compatibility")
        self.assertEqual(compatibility["count"], 2)
        self.assertEqual(
            compatibility["children"]["companion_dogs"]["label"],
            "Companion Dogs",
        )
        self.assertIn("semantic.medical.distress.call", tree["children"]["medical"]["children"]["distress"]["children"]["call"]["items"][0]["id"])

    def test_search_keeps_ancestors_and_auto_expands_matching_path(self) -> None:
        filtered = filter_semantic_tree(build_semantic_tree(self.rows), "dogs")
        self.assertEqual(filtered["count"], 1)
        self.assertIn("semantic.compat", filtered["expanded"])
        self.assertEqual(
            filtered["children"]["compat"]["children"]["companion_dogs"]["count"],
            1,
        )

        branch_match = filter_semantic_tree(
            build_semantic_tree(self.rows), "compatibility"
        )
        self.assertEqual(branch_match["count"], 2)
        self.assertIn("semantic.compat.bandits", branch_match["expanded"])

    def test_leaf_keeps_full_canonical_id(self) -> None:
        filtered = filter_semantic_tree(build_semantic_tree(self.rows), "semantic.command.player.follow")
        leaf = filtered["children"]["command"]["children"]["player"]["children"]["follow"]
        self.assertEqual(leaf["items"][0]["id"], "semantic.command.player.follow")


if __name__ == "__main__":
    unittest.main()
