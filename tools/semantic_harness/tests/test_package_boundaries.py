"""Regression checks for the Semantic Lab package ownership boundaries."""

from __future__ import annotations

import unittest


class PackageBoundaryTests(unittest.TestCase):
    def test_codebuilder_authoring_does_not_depend_on_studio(self) -> None:
        from tools.semantic_harness.codebuilder import authoring as canonical
        from tools.semantic_harness.codebuilder import service

        self.assertIsNotNone(service.SemanticLabAuthoringService)
        self.assertEqual(canonical.__name__, "tools.semantic_harness.codebuilder.authoring")

    def test_historical_authoring_facades_share_the_canonical_implementation(self) -> None:
        from tools.semantic_harness import authoring as legacy
        from tools.semantic_harness.codebuilder import authoring as canonical
        from tools.semantic_harness.studio import authoring as studio

        self.assertIs(legacy.preview_semantic_source, canonical.preview_semantic_source)
        self.assertIs(studio.preview_semantic_source, canonical.preview_semantic_source)
        self.assertEqual(studio.REPOSITORY, canonical.REPOSITORY)


if __name__ == "__main__":
    unittest.main()
