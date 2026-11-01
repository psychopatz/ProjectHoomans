"""Harness diagnostics, case replay, performance, and Lua test execution."""

from .comparator import AssertionFailure, compare_value, evaluate_expectations
from .executor import CaseResult, TurnResult, execute_case, execute_cases
from .loader import (
    SemanticCase,
    discover_cases,
    expand_matrix_case,
    load_cases_from_dict,
    load_cases_from_file,
)
from .projection import ABSENT, resolve_observation_path
from .runner import ConflictLedger, HarnessCase, HarnessRun, detect_conflicts, load_case, run_case
from .schema import (
    SCHEMA_V1,
    SchemaValidationError,
    validate_case,
    validate_expectations,
    validate_fixture_document,
)

__all__ = [
    "ABSENT",
    "AssertionFailure",
    "CaseResult",
    "ConflictLedger",
    "HarnessCase",
    "HarnessRun",
    "SCHEMA_V1",
    "SchemaValidationError",
    "SemanticCase",
    "TurnResult",
    "compare_value",
    "detect_conflicts",
    "discover_cases",
    "evaluate_expectations",
    "execute_case",
    "execute_cases",
    "expand_matrix_case",
    "load_case",
    "load_cases_from_dict",
    "load_cases_from_file",
    "resolve_observation_path",
    "run_case",
    "validate_case",
    "validate_expectations",
    "validate_fixture_document",
]
