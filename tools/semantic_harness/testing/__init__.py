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
from .sweep_dimensions import (
    EXPLICIT_SCENARIO_ADAPTERS,
    InvalidDimensionValueError,
    PrerequisiteDimensionError,
    ReadOnlyDimensionError,
    SweepDimension,
    SweepDimensionError,
    SweepDimensionInventory,
    UnsupportedDimensionError,
    extract_dimension_inventory,
)
from .sweep_evidence import (
    ALLOWED_EVIDENCE_SCHEMAS,
    EVIDENCE_SCHEMA_V1,
    QualityFlag,
    extract_evidence_rows_from_turn,
    validate_evidence_row,
)

__all__ = [
    "ABSENT",
    "ALLOWED_EVIDENCE_SCHEMAS",
    "AssertionFailure",
    "CaseResult",
    "ConflictLedger",
    "EVIDENCE_SCHEMA_V1",
    "EXPLICIT_SCENARIO_ADAPTERS",
    "HarnessCase",
    "HarnessRun",
    "InvalidDimensionValueError",
    "PrerequisiteDimensionError",
    "QualityFlag",
    "ReadOnlyDimensionError",
    "SCHEMA_V1",
    "SchemaValidationError",
    "SemanticCase",
    "SweepDimension",
    "SweepDimensionError",
    "SweepDimensionInventory",
    "TurnResult",
    "UnsupportedDimensionError",
    "compare_value",
    "detect_conflicts",
    "discover_cases",
    "evaluate_expectations",
    "execute_case",
    "execute_cases",
    "expand_matrix_case",
    "extract_dimension_inventory",
    "extract_evidence_rows_from_turn",
    "load_case",
    "load_cases_from_dict",
    "load_cases_from_file",
    "resolve_observation_path",
    "run_case",
    "validate_case",
    "validate_evidence_row",
    "validate_expectations",
    "validate_fixture_document",
]
