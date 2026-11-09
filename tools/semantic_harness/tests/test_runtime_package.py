"""Runtime package ownership contracts."""

from __future__ import annotations

import unittest

from tools.semantic_harness.runtime.config import HarnessConfig
from tools.semantic_harness.runtime.process import LuaProcess
from tools.semantic_harness.runtime.protocol import ProtocolError
from tools.semantic_harness.runtime.scenario import derive_display_name
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.runtime.worker_session import WorkerSession


class RuntimePackageTests(unittest.TestCase):
    def test_runtime_modules_are_canonical_implementations(self) -> None:
        self.assertEqual(HarnessConfig.__module__, "tools.semantic_harness.runtime.config")
        self.assertEqual(LuaProcess.__module__, "tools.semantic_harness.runtime.process")
        self.assertEqual(LuaSemanticWorker.__module__, "tools.semantic_harness.runtime.worker")

    def test_protocol_is_core_owned_with_hoomans_compatibility_path(self) -> None:
        self.assertEqual(ProtocolError.__module__, "semantic_harness.protocol")

    def test_shared_harness_mechanics_are_core_owned_with_hoomans_paths(self) -> None:
        self.assertEqual(WorkerSession.__module__, "semantic_harness.worker_session")
        self.assertEqual(derive_display_name.__module__, "semantic_harness.scenario")


if __name__ == "__main__":
    unittest.main()
