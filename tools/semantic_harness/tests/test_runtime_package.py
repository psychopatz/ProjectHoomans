"""Import compatibility contracts for the runtime package migration."""

from __future__ import annotations

import unittest

from tools.semantic_harness.config import HarnessConfig as LegacyConfig
from tools.semantic_harness.process import LuaProcess as LegacyProcess
from tools.semantic_harness.protocol import ProtocolError as LegacyProtocolError
from tools.semantic_harness.runtime.config import HarnessConfig
from tools.semantic_harness.runtime.process import LuaProcess
from tools.semantic_harness.runtime.protocol import ProtocolError
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO as RUNTIME_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.scenario import DEFAULT_SCENARIO as LEGACY_SCENARIO
from tools.semantic_harness.worker import LuaSemanticWorker as LegacyWorker


class RuntimePackageTests(unittest.TestCase):
    def test_legacy_runtime_facades_preserve_public_identity(self) -> None:
        self.assertIs(LegacyConfig, HarnessConfig)
        self.assertIs(LegacyProcess, LuaProcess)
        self.assertIs(LegacyProtocolError, ProtocolError)
        self.assertIs(LegacyWorker, LuaSemanticWorker)
        self.assertIs(LEGACY_SCENARIO, RUNTIME_SCENARIO)

    def test_runtime_modules_are_canonical_implementations(self) -> None:
        self.assertEqual(HarnessConfig.__module__, "tools.semantic_harness.runtime.config")
        self.assertEqual(LuaProcess.__module__, "tools.semantic_harness.runtime.process")
        self.assertEqual(LuaSemanticWorker.__module__, "tools.semantic_harness.runtime.worker")


if __name__ == "__main__":
    unittest.main()
