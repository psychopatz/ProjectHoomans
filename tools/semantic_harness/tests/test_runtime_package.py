"""Runtime package ownership contracts."""

from __future__ import annotations

import unittest

from tools.semantic_harness.runtime.config import HarnessConfig
from tools.semantic_harness.runtime.process import LuaProcess
from tools.semantic_harness.runtime.protocol import ProtocolError
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class RuntimePackageTests(unittest.TestCase):
    def test_runtime_modules_are_canonical_implementations(self) -> None:
        self.assertEqual(HarnessConfig.__module__, "tools.semantic_harness.runtime.config")
        self.assertEqual(LuaProcess.__module__, "tools.semantic_harness.runtime.process")
        self.assertEqual(LuaSemanticWorker.__module__, "tools.semantic_harness.runtime.worker")


if __name__ == "__main__":
    unittest.main()
