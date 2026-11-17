"""Static guard for method-level test classification and mechanism reasons."""

from __future__ import annotations

import ast
import json
from pathlib import Path
import unittest


REPOSITORY = Path(__file__).resolve().parents[4]
TESTS_DIR = Path(__file__).resolve().parent
CLASSIFICATION_PATH = (
    REPOSITORY / "docs" / "Jobs" / "SemanticTestSubsystem" / "TEST_CLASSIFICATION.json"
)
GENERIC_REASONS = frozenset(
    {
        "implementation runtime contract",
        "real worker test",
        "worker protocol",
        "production worker test",
        "low level runtime contract",
        "low_level_runtime_contract",
    }
)


def _iter_test_methods(path: Path) -> list[str]:
    tree = ast.parse(path.read_text(encoding="utf-8"))
    methods: list[str] = []
    for node in tree.body:
        if isinstance(node, ast.ClassDef):
            for item in node.body:
                if isinstance(item, ast.FunctionDef) and item.name.startswith("test_"):
                    methods.append(item.name)
    return methods


class TestClassificationGuardTests(unittest.TestCase):
    def test_classification_ledger_matches_test_tree_and_has_mechanism_reasons(self) -> None:
        self.assertTrue(CLASSIFICATION_PATH.is_file(), f"missing {CLASSIFICATION_PATH}")
        data = json.loads(CLASSIFICATION_PATH.read_text(encoding="utf-8"))
        self.assertEqual(data.get("schema"), "semantic.test-classification.v1")

        recorded_modules = {m["module"]: m for m in data.get("modules", [])}
        actual_files = sorted(TESTS_DIR.glob("test_*.py"))
        actual_names = {
            path.name
            for path in actual_files
            if _iter_test_methods(path)
        }
        self.assertEqual(set(recorded_modules), actual_names)

        for path in actual_files:
            actual_methods = _iter_test_methods(path)
            if not actual_methods:
                continue
            entry = recorded_modules[path.name]
            details = entry.get("methodDetails") or []
            self.assertEqual(
                [row.get("name") for row in details],
                actual_methods,
                f"methodDetails out of sync for {path.name}",
            )
            for row in details:
                if not row.get("usesDirectWorker"):
                    continue
                reason = str(row.get("reason") or "").strip()
                self.assertTrue(
                    reason,
                    f"{path.name}::{row.get('name')} missing direct-worker reason",
                )
                normalized = reason.lower().rstrip(".")
                self.assertNotIn(
                    normalized,
                    GENERIC_REASONS,
                    f"{path.name}::{row.get('name')} has generic reason: {reason!r}",
                )
                if row.get("category") == "LOW_LEVEL_RUNTIME_CONTRACT":
                    self.assertGreaterEqual(
                        len(reason),
                        20,
                        f"{path.name}::{row.get('name')} reason too short: {reason!r}",
                    )


if __name__ == "__main__":
    unittest.main()
