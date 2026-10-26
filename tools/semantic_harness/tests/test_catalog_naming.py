from __future__ import annotations

import unittest

from tools.semantic_harness.codebuilder.catalog_naming import (
    ModuleNameRegistry,
    compact_segment,
    module_path,
    pascal_segment,
)


class CatalogNamingTests(unittest.TestCase):
    def test_readable_segments_preserve_word_boundaries(self) -> None:
        self.assertEqual(pascal_segment("whats_up_part_01"), "WhatsUpPart01")
        self.assertEqual(pascal_segment("HTTPServer42"), "HttpServer42")

    def test_long_segments_use_a_stable_short_hash_suffix(self) -> None:
        value = "a" * 80
        first = compact_segment(value, "semantic.long.first")
        second = compact_segment(value, "semantic.long.first")
        self.assertEqual(first, second)
        self.assertLessEqual(len(first), 32)
        self.assertIn("__", first)

    def test_same_directory_collisions_receive_distinct_suffixes(self) -> None:
        registry = ModuleNameRegistry()
        first = module_path("Catalog/Patterns", ["Question", "Identity"], "pnc.one", registry)
        second = module_path("Catalog/Patterns", ["Question", "Identity"], "pnc.two", registry)
        self.assertEqual(first, "Catalog/Patterns/Question/Identity")
        self.assertNotEqual(first, second)
        self.assertTrue(second.startswith("Catalog/Patterns/Question/Identity__"))


if __name__ == "__main__":
    unittest.main()
