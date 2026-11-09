from __future__ import annotations

import unittest

from tools.semantic_harness.codebuilder import catalog_naming, translation_support
from tools.semantic_harness.codebuilder.dialogue_dataset import (
    compile_dialogue_dataset,
)
from tools.semantic_harness.codebuilder.lexicon_compiler import CompileError
from semantic_harness.codebuilder import (
    CompileError as CoreCompileError,
    compile_typed_dataset,
)


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

    def test_dialogue_adapter_delegates_to_core_typed_compiler(self) -> None:
        self.assertEqual(
            compile_dialogue_dataset.__module__,
            "tools.semantic_harness.codebuilder.dialogue_dataset",
        )
        self.assertEqual(
            compile_typed_dataset.__module__,
            "semantic_harness.codebuilder.dataset_compiler",
        )


if __name__ == "__main__":
    unittest.main()
