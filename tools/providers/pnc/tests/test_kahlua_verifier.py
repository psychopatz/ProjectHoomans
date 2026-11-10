"""Real packaged Kahlua compiler, explicitly opt-in when game jar is present."""
from __future__ import annotations
import os
from pathlib import Path
import tempfile
import unittest

from tools.semantic_harness.kahlua_verifier.verify import (
    REPOSITORY, run_check, semantic_sources,
)

ROOT_ENV = os.environ.get("PZ_KAHLUA_GAME_ROOT")


class KahluaVerifierContractTests(unittest.TestCase):
    def test_semantic_source_scope_bounded_and_no_media_staging(self):
        files = semantic_sources(REPOSITORY)
        self.assertGreater(len(files), 0)
        self.assertLessEqual(len(files), 512)
        self.assertEqual(len(files), len(set(files)))
        self.assertTrue(all(file.suffix == ".lua" for file in files))
        self.assertFalse(any("tmpdir" in str(path) for path in files))

    @unittest.skipUnless(ROOT_ENV, "PZ_KAHLUA_GAME_ROOT is not set")
    def test_actual_compiler_accepts_real_source_and_rejects_invalid_lua(self):
        game_root = Path(ROOT_ENV)
        existing = semantic_sources(REPOSITORY)[0]
        result = run_check(game_root, [existing])
        self.assertTrue(result["passed"], result)
        self.assertFalse(result["gameLaunched"])
        self.assertFalse(result["luaExecuted"])
        self.assertEqual(result["writesToSource"], 0)
        with tempfile.TemporaryDirectory(
            prefix="obs-kahlua-negative-", dir=REPOSITORY / "tools"
        ) as directory:
            invalid = Path(directory) / "invalid.lua"
            invalid.write_text("local = \n", encoding="utf-8")
            negative = run_check(game_root, [invalid])
            self.assertFalse(negative["passed"], negative)
            self.assertIn("KAHLUA_FAIL", negative["failure"])
            self.assertEqual(invalid.read_text(), "local = \n")

    @unittest.skipUnless(ROOT_ENV, "PZ_KAHLUA_GAME_ROOT is not set")
    def test_invalid_paths_never_compile(self):
        game_root = Path(ROOT_ENV)
        with self.assertRaisesRegex(ValueError, "existing Lua"):
            run_check(game_root, [Path("/tmp/unrelated.lua")])
        with self.assertRaisesRegex(ValueError, "requires 1"):
            run_check(game_root, [])


if __name__ == "__main__":
    unittest.main()
