"""Semantic Lab uses the Conversation-owned semantic composition root."""

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class ConversationSemanticCompositionTests(unittest.TestCase):
    def test_worker_loads_conversation_semantic_runtime(self) -> None:
        worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
        worker.open_conversation()
        snapshot = worker.snapshot()

        self.assertIn(
            "PNC/Conversation/Semantic/PNC_ConversationSemanticRuntime.lua",
            snapshot["loadedModules"],
        )


if __name__ == "__main__":
    unittest.main()
