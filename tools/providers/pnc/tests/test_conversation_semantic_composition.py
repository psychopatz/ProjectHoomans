"""Semantic Lab uses the Conversation-owned semantic composition root."""

from copy import deepcopy
import unittest

from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO
from tools.providers.pnc.tests.worker_reuse import WarmWorkerTestMixin


class ConversationSemanticCompositionTests(WarmWorkerTestMixin, unittest.TestCase):
    def test_worker_loads_conversation_semantic_runtime(self) -> None:
        with self.warm_worker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.open_conversation()
            snapshot = worker.snapshot()

        self.assertIn(
            "PNC/ConvoEngine/RuntimeFacade.lua",
            snapshot["loadedModules"],
        )


if __name__ == "__main__":
    unittest.main()
