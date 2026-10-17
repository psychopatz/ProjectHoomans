"""Static Phase 6 guards for semantic submission ownership."""

from __future__ import annotations

import re
import unittest
from pathlib import Path


REPOSITORY = Path(__file__).resolve().parents[3]
SEMANTIC_INPUT_ROOT = (
    REPOSITORY
    / "Contents"
    / "mods"
    / "ProjectHoomans"
    / "42.20"
    / "media"
    / "lua"
    / "client"
    / "PNC"
    / "Semantics"
)
TICK_REGISTRATION = re.compile(r"\bEvents\s*\.\s*OnTick\b|\bOnTick\s*\.\s*Add\b")


class Phase6StaticBoundaryTests(unittest.TestCase):
    def test_semantic_input_modules_have_no_tick_polling_registration(self) -> None:
        paths = sorted(SEMANTIC_INPUT_ROOT.glob("PNC_SemanticDialogueInput*.lua"))
        self.assertTrue(paths, "semantic input modules were not found")
        offenders = [
            str(path.relative_to(REPOSITORY))
            for path in paths
            if TICK_REGISTRATION.search(path.read_text(encoding="utf-8"))
        ]
        self.assertEqual(
            offenders,
            [],
            "semantic dialogue submission must remain request-driven; "
            f"tick registration found in {offenders}",
        )


if __name__ == "__main__":
    unittest.main()
