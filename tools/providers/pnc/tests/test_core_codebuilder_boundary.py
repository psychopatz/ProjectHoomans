from __future__ import annotations

import unittest

from tools.semantic_harness.codebuilder.catalog_naming import ModuleNameRegistry
from tools.semantic_harness.codebuilder.translation_support import normalize_language
from tools.semantic_harness.codebuilder.dialogue_dataset import (
    compile_dialogue_dataset,
)
from tools.semantic_harness.codebuilder.dialogue_contract import (
    _validate_branch_constraint,
    _validate_source_refs,
)
from tools.semantic_harness.codebuilder.dialogue_responses import (
    _validate_response_condition,
    _validate_translation_args,
)
from tools.semantic_harness.codebuilder.conversation_model import (
    fingerprint as core_conversation_fingerprint,
)
from tools.semantic_harness.codebuilder.lexicon_compiler import CompileError
from tools.semantic_harness.codebuilder import (
    CompileError as CoreCompileError,
    compile_typed_dataset,
)
from tools.semantic_harness.codebuilder import rule_contract


class CoreCodeBuilderBoundaryTests(unittest.TestCase):
    def test_generic_codebuilder_helpers_are_core_owned(self) -> None:
        self.assertEqual(
            normalize_language.__module__,
            "tools.semantic_harness.codebuilder.translation_support",
        )
        self.assertEqual(
            ModuleNameRegistry.__module__,
            "tools.semantic_harness.codebuilder.catalog_naming",
        )
        self.assertEqual(
            core_conversation_fingerprint.__module__,
            "tools.semantic_harness.codebuilder.conversation_model",
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
            "tools.semantic_harness.codebuilder.dataset_compiler",
        )

    def test_dialogue_rule_adapters_delegate_structural_validation_to_core(self) -> None:
        self.assertEqual(
            _validate_source_refs(["Fixture source"], {"Fixture source"}, "sourceRefs"),
            ["Fixture source"],
        )
        self.assertEqual(
            _validate_branch_constraint(
                {"path": "relationship.state", "op": "eq", "value": "trusted"},
                "constraints",
            ),
            {"path": "relationship.state", "op": "eq", "value": "trusted"},
        )
        self.assertEqual(
            _validate_translation_args({"name": "string"}, "translationArgs"),
            {"name": "string"},
        )
        self.assertEqual(
            _validate_response_condition(
                {"topic": "weather"}, "semantic.weather", "reply"
            ),
            {"topic": "weather"},
        )
        self.assertEqual(
            _validate_branch_constraint.__module__,
            "tools.semantic_harness.codebuilder.dialogue_contract",
        )
        self.assertEqual(
            rule_contract.validate_predicate.__module__,
            "tools.semantic_harness.codebuilder.rule_contract",
        )
        self.assertEqual(
            rule_contract.validate_typed_arguments.__module__,
            "tools.semantic_harness.codebuilder.rule_contract",
        )


if __name__ == "__main__":
    unittest.main()
