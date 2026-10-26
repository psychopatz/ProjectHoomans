"""Runtime-version discovery tests shared by the harness and Lua smoke runner."""

from __future__ import annotations

from pathlib import Path
import tempfile
import unittest

from tools.semantic_harness.runtime.config import (
    ConfigurationError,
    discover_newest_runtime,
    discover_dynamic_trading_runtime,
)


class RuntimeConfigTests(unittest.TestCase):
    def test_discover_newest_runtime_uses_numeric_order(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("common", "42.9", "42.20", "42.21", "notes"):
                (root / name).mkdir()

            self.assertEqual(discover_newest_runtime(root), "42.21")

    def test_discover_newest_runtime_rejects_missing_numeric_directory(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "common").mkdir()

            with self.assertRaises(ConfigurationError):
                discover_newest_runtime(root)

    def test_dynamic_trading_uses_newest_shared_module_runtime(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for module in ("DTCommon", "DTHoomans"):
                module_root = root / "Contents/mods" / module
                (module_root / "42.20").mkdir(parents=True)
            (root / "Contents/mods/DTCommon/42.21").mkdir()

            self.assertEqual(discover_dynamic_trading_runtime(root), "42.20")


if __name__ == "__main__":
    unittest.main()
