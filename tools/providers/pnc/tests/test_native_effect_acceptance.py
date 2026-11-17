"""Cross-input production-worker acceptance for one companion capability."""

from __future__ import annotations

import unittest
from copy import deepcopy

from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO
from tools.providers.pnc.tests.worker_reuse import WarmWorkerTestMixin
from tools.providers.pnc.tests.companion_orders_test_support import open_orders


def action_signature(result: dict) -> tuple[str, str, str, str]:
    action = result["result"]["actionResult"]
    payload = result["dispatchTransport"][0]["payload"]
    return (
        action["commandID"],
        action["capabilityID"],
        action["handlerID"],
        payload["commandID"],
    )


class NativeEffectAcceptanceTests(WarmWorkerTestMixin, unittest.TestCase):
    def test_typed_and_semantic_button_follow_share_executor_and_effect(self) -> None:
        with self.warm_worker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.open_conversation()
            typed = worker.input("Follow me.")

        with self.warm_worker(deepcopy(DEFAULT_SCENARIO)) as worker:
            orders = open_orders(worker)
            follow = next(
                row for row in orders["conversationPresentation"]["responseChannel"]["rows"]
                if row["id"] == "action.follow"
            )
            button = worker.suggestion_click(follow["frame"])

        self.assertTrue(typed["accepted"])
        self.assertTrue(button["accepted"])
        self.assertEqual(action_signature(typed), action_signature(button))
        self.assertEqual(
            action_signature(typed),
            (
                "follow",
                "pnc:companion.follow",
                "PNC.Client.SendCompanionCommand",
                "follow",
            ),
        )
        self.assertEqual(typed["scenario"]["npc"]["followState"]["mode"], "following")
        self.assertEqual(button["scenario"]["npc"]["followState"]["mode"], "following")


if __name__ == "__main__":
    unittest.main()
