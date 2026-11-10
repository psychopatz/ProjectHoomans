"""Contract checks for the package-level Semantic Lab entrypoint."""

from __future__ import annotations

import subprocess
import sys
import unittest


class PackageEntrypointTests(unittest.TestCase):
    def test_module_entrypoint_exposes_cli_help_without_starting_tk(self) -> None:
        result = subprocess.run(
            [sys.executable, "-m", "tools.semantic_harness", "--help"],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("usage:", result.stdout)
        self.assertIn("Tkinter chat UI and CLI", result.stdout)


if __name__ == "__main__":
    unittest.main()
