"""Runtime package ownership contracts."""

from __future__ import annotations

import unittest

from tools.semantic_harness.runtime.config import HarnessConfig
from tools.semantic_harness.transport.process import LuaProcess
from tools.semantic_harness.transport.protocol import ProtocolError
from tools.semantic_harness.core.scenario import derive_display_name
from tools.semantic_harness.core.worker import SemanticWorker
from tools.providers.pnc.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.core.worker_session import WorkerSession


class RuntimePackageTests(unittest.TestCase):
    def test_runtime_modules_are_canonical_implementations(self) -> None:
        self.assertEqual(HarnessConfig.__module__, "tools.semantic_harness.runtime.config")
        self.assertEqual(LuaProcess.__module__, "tools.semantic_harness.transport.process")
        self.assertEqual(LuaSemanticWorker.__module__, "tools.providers.pnc.runtime.worker")

    def test_protocol_is_core_owned(self) -> None:
        self.assertEqual(ProtocolError.__module__, "tools.semantic_harness.transport.protocol")

    def test_shared_harness_mechanics_are_core_owned(self) -> None:
        self.assertEqual(WorkerSession.__module__, "tools.semantic_harness.core.worker_session")
        self.assertTrue(issubclass(LuaSemanticWorker, SemanticWorker))
        self.assertEqual(derive_display_name.__module__, "tools.semantic_harness.core.scenario")


if __name__ == "__main__":
    unittest.main()
