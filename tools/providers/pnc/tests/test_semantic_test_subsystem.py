"""Unit tests for the canonical Semantic Test subsystem."""

from __future__ import annotations

import unittest
from pathlib import Path

from tools.semantic_harness.testing.comparator import (
    AssertionFailure,
    compare_value,
    evaluate_expectations,
)
from tools.semantic_harness.testing.executor import execute_case
from tools.semantic_harness.testing.loader import (
    SemanticCase,
    expand_matrix_case,
    load_cases_from_dict,
)
from tools.semantic_harness.testing.projection import ABSENT, resolve_observation_path
from tools.semantic_harness.testing.schema import (
    SCHEMA_V1,
    SchemaValidationError,
    validate_case,
    validate_fixture_document,
)


class SchemaValidationTests(unittest.TestCase):
    def test_valid_minimal_case(self) -> None:
        raw = {
            "schema": SCHEMA_V1,
            "id": "test.valid.case",
            "turns": [
                {
                    "text": "hello",
                    "expect": {
                        "ir.intent": "GREET",
                    },
                }
            ],
        }
        cases = validate_fixture_document(raw)
        self.assertEqual(len(cases), 1)
        self.assertEqual(cases[0]["id"], "test.valid.case")
        self.assertEqual(cases[0]["turns"][0]["text"], "hello")
        self.assertEqual(cases[0]["turns"][0]["expect"]["ir.intent"], {"equals": "GREET"})

    def test_rejects_invalid_schema_version(self) -> None:
        raw = {
            "schema": "invalid.schema.v99",
            "id": "test.invalid.schema",
            "turns": [{"text": "hello"}],
        }
        with self.assertRaises(SchemaValidationError) as cm:
            validate_fixture_document(raw)
        self.assertIn("Unsupported schema", str(cm.exception))

    def test_rejects_empty_turns(self) -> None:
        raw = {
            "schema": SCHEMA_V1,
            "id": "test.empty.turns",
            "turns": [],
        }
        with self.assertRaises(SchemaValidationError) as cm:
            validate_fixture_document(raw)
        self.assertIn("turns must be a non-empty list", str(cm.exception))

    def test_rejects_unsupported_operator(self) -> None:
        raw = {
            "schema": SCHEMA_V1,
            "id": "test.unsupported.op",
            "turns": [
                {
                    "text": "hello",
                    "expect": {
                        "ir.intent": {"regex": ".*"},
                    },
                }
            ],
        }
        with self.assertRaises(SchemaValidationError) as cm:
            validate_fixture_document(raw)
        self.assertIn("Unsupported operator 'regex'", str(cm.exception))

    def test_rejects_operator_type_mismatch(self) -> None:
        raw = {
            "schema": SCHEMA_V1,
            "id": "test.op.type",
            "turns": [
                {"text": "hello", "expect": {"count": {"min": "not_a_number"}}},
            ],
        }
        with self.assertRaises(SchemaValidationError) as cm:
            validate_fixture_document(raw)
        self.assertIn("requires a numeric value", str(cm.exception))


class MatrixExpansionTests(unittest.TestCase):
    def test_expands_matrix_with_deterministic_ids(self) -> None:
        doc = {
            "schema": SCHEMA_V1,
            "id": "greeting.matrix",
            "matrix": {
                "language": ["EN", "TL"],
                "weather": ["clear", "rain"],
            },
            "turns": [
                {"text": "hello", "expect": {"response.exists": True}}
            ],
        }
        cases = load_cases_from_dict(doc)
        self.assertEqual(len(cases), 4)
        expected_ids = {
            "greeting.matrix[language=EN,weather=clear]",
            "greeting.matrix[language=EN,weather=rain]",
            "greeting.matrix[language=TL,weather=clear]",
            "greeting.matrix[language=TL,weather=rain]",
        }
        self.assertEqual({c.case_id for c in cases}, expected_ids)
        
        # Verify parameter application into scenario
        en_rain = next(c for c in cases if "language=EN,weather=rain" in c.case_id)
        self.assertEqual(en_rain.scenario["runtime"]["language"], "EN")
        self.assertEqual(en_rain.scenario["world"]["weather"], "rain")

    def test_rejects_matrix_exceeding_max_limit(self) -> None:
        doc = {
            "schema": SCHEMA_V1,
            "id": "huge.matrix",
            "matrix": {
                "a": list(range(10)),
                "b": list(range(10)),
            },
            "turns": [{"text": "hi"}],
        }
        with self.assertRaises(SchemaValidationError) as cm:
            load_cases_from_dict(doc)
        self.assertIn("exceeding maximum limit", str(cm.exception))


class ComparatorAndProjectionTests(unittest.TestCase):
    def test_path_resolution(self) -> None:
        turn = {
            "observation": {
                "ir": {"intent": "GREET", "subject": "SOCIAL"},
                "response": {"templateID": "semantic.flow.greeting", "fallback": "Hello there!"},
                "flow": {"matched": True, "flowId": "greeting"},
            },
            "result": {
                "ir": {"intent": "GREET"},
            },
            "messages": [
                {"speaker": "npc", "payload": {"text": "Hello there!", "semanticTemplateID": "semantic.flow.greeting"}}
            ],
            "relationshipAfter": {"identityTrust": "known"},
        }

        self.assertEqual(resolve_observation_path(turn, "ir.intent"), "GREET")
        self.assertEqual(resolve_observation_path(turn, "ir.subject"), "SOCIAL")
        self.assertEqual(resolve_observation_path(turn, "response.templateID"), "semantic.flow.greeting")
        self.assertEqual(resolve_observation_path(turn, "response.fallback"), "Hello there!")
        self.assertEqual(resolve_observation_path(turn, "response.text"), "Hello there!")
        self.assertEqual(resolve_observation_path(turn, "flow.matched"), True)
        self.assertEqual(resolve_observation_path(turn, "relationshipAfter.identityTrust"), "known")
        self.assertIs(resolve_observation_path(turn, "missing.field"), ABSENT)

    def test_comparator_operators(self) -> None:
        # equals / notEquals
        self.assertIsNone(compare_value("a", "equals", "val", "val"))
        self.assertIsNotNone(compare_value("a", "equals", "val", "wrong"))
        self.assertIsNone(compare_value("a", "notEquals", "val", "other"))
        self.assertIsNotNone(compare_value("a", "notEquals", "val", "val"))

        # exists / absent
        self.assertIsNone(compare_value("a", "exists", True, "something"))
        self.assertIsNotNone(compare_value("a", "exists", True, ABSENT))
        self.assertIsNone(compare_value("a", "absent", True, ABSENT))
        self.assertIsNotNone(compare_value("a", "absent", True, "present"))

        # contains / notContains
        self.assertIsNone(compare_value("a", "contains", "lo", "hello"))
        self.assertIsNotNone(compare_value("a", "contains", "xyz", "hello"))
        self.assertIsNone(compare_value("a", "notContains", "xyz", "hello"))
        self.assertIsNotNone(compare_value("a", "notContains", "lo", "hello"))

        # prefix / oneOf
        self.assertIsNone(compare_value("a", "prefix", "semantic.", "semantic.flow.greeting"))
        self.assertIsNotNone(compare_value("a", "prefix", "other.", "semantic.flow.greeting"))
        self.assertIsNone(compare_value("a", "oneOf", ["A", "B"], "A"))
        self.assertIsNotNone(compare_value("a", "oneOf", ["A", "B"], "C"))

        # min / max
        self.assertIsNone(compare_value("a", "min", 5, 10))
        self.assertIsNotNone(compare_value("a", "min", 15, 10))
        self.assertIsNone(compare_value("a", "max", 10, 5))
        self.assertIsNotNone(compare_value("a", "max", 5, 10))

        # count / minCount / maxCount
        self.assertIsNone(compare_value("a", "count", 3, [1, 2, 3]))
        self.assertIsNotNone(compare_value("a", "count", 2, [1, 2, 3]))
        self.assertIsNone(compare_value("a", "minCount", 2, [1, 2, 3]))
        self.assertIsNone(compare_value("a", "maxCount", 5, [1, 2, 3]))

        # truthy / falsy
        self.assertIsNone(compare_value("a", "truthy", True, 1))
        self.assertIsNone(compare_value("a", "falsy", True, 0))
        self.assertIsNone(compare_value("a", "falsy", True, ABSENT))


class RealWorkerExecutionTests(unittest.TestCase):
    def test_single_turn_greeting_execution(self) -> None:
        case = SemanticCase(
            case_id="pilot.greeting.basic",
            suite="pilot",
            tags=("greeting", "pilot"),
            scenario={},
            turns=(
                {
                    "text": "hello",
                    "expect": {
                        "ir.intent": "GREET",
                        "response.exists": True,
                        "flow.matched": True,
                    },
                },
            ),
        )
        result = execute_case(case)
        self.assertTrue(result.passed, result.summary() + str(result.failures))
        self.assertEqual(len(result.turns), 1)
        self.assertEqual(len(result.failures), 0)
        self.assertEqual(len(result.conflicts), 0)


if __name__ == "__main__":
    unittest.main()
