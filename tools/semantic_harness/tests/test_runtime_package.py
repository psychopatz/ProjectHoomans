"""Runtime package ownership contracts."""

from __future__ import annotations

import unittest

from tools.semantic_harness.runtime.config import HarnessConfig
from semantic_harness.process import LuaProcess
from semantic_harness.protocol import ProtocolError
from semantic_harness.scenario import derive_display_name
from semantic_harness.worker import SemanticWorker
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from semantic_harness.worker_session import WorkerSession


class RuntimePackageTests(unittest.TestCase):
    def test_runtime_modules_are_canonical_implementations(self) -> None:
        self.assertEqual(HarnessConfig.__module__, "tools.semantic_harness.runtime.config")
        self.assertEqual(LuaProcess.__module__, "semantic_harness.process")
        self.assertEqual(LuaSemanticWorker.__module__, "tools.semantic_harness.runtime.worker")

    def test_protocol_is_core_owned(self) -> None:
        self.assertEqual(ProtocolError.__module__, "semantic_harness.protocol")

    def test_shared_harness_mechanics_are_core_owned(self) -> None:
        self.assertEqual(WorkerSession.__module__, "semantic_harness.worker_session")
        self.assertTrue(issubclass(LuaSemanticWorker, SemanticWorker))
        self.assertEqual(derive_display_name.__module__, "semantic_harness.scenario")


if __name__ == "__main__":
    unittest.main()
