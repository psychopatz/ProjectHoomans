from __future__ import annotations

import unittest

from tools.semantic_harness.codebuilder import catalog_naming, translation_support
from tools.semantic_harness.codebuilder.lexicon_compiler import CompileError
from semantic_harness.codebuilder import CompileError as CoreCompileError


class CoreCodeBuilderBoundaryTests(unittest.TestCase):
    def test_generic_codebuilder_helpers_are_core_owned(self) -> None:
        self.assertEqual(
            translation_support.normalize_language.__module__,
            "semantic_harness.codebuilder.translation_support",
        )
        self.assertEqual(
            catalog_naming.ModuleNameRegistry.__module__,
            "semantic_harness.codebuilder.catalog_naming",
        )

    def test_hoomans_compiler_errors_reuse_core_contract(self) -> None:
        self.assertIs(CompileError, CoreCompileError)


if __name__ == "__main__":
    unittest.main()
