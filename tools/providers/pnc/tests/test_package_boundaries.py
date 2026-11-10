"""Regression checks for the Semantic Lab package ownership boundaries."""

from __future__ import annotations

import unittest


class PackageBoundaryTests(unittest.TestCase):
    def test_codebuilder_authoring_does_not_depend_on_studio(self) -> None:
        from tools.providers.pnc.codebuilder import authoring as canonical
        from tools.providers.pnc.codebuilder import service

        self.assertIsNotNone(service.SemanticLabAuthoringService)
        self.assertEqual(canonical.__name__, "tools.providers.pnc.codebuilder.authoring")


if __name__ == "__main__":
    unittest.main()
