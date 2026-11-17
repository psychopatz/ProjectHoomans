"""Mechanism contracts for semantic-cognition request/response transport targeting."""

from __future__ import annotations

import unittest

from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.providers.pnc.tests.worker_reuse import WarmWorkerTestMixin


class SemanticCognitionTransportTests(WarmWorkerTestMixin, unittest.TestCase):
    def test_request_and_response_transport_preserve_authoritative_target(self) -> None:
        scenario = merge(
            DEFAULT_SCENARIO,
            {
                "npc": {"identityState": "known", "forename": "Sarah"},
                "runtime": {
                    "semanticCognitionResponses": {
                        "GOSSIP": {
                            "targetID": "npc_mara",
                            "gossip": {"subject": "Sarah", "codes": [1001]},
                        },
                    },
                },
            },
        )
        with self.warm_worker(scenario) as worker:
            result = worker.input("any news about Sarah?")

        request = next(
            event
            for event in result["dispatchTransport"]
            if event.get("command") == "SemanticCognitionRequest"
        )
        response = next(
            event
            for event in result["dispatchTransport"]
            if event.get("eventName") == "OnServerCommand"
            and event.get("command") == "SemanticCognition"
        )
        self.assertEqual(request["payload"]["targetID"], "npc_mara")
        self.assertEqual(response["payload"]["targetID"], "npc_mara")

    def test_mismatched_response_target_is_visible_at_transport_boundary(self) -> None:
        scenario = merge(
            DEFAULT_SCENARIO,
            {
                "npc": {"identityState": "known", "forename": "Sarah"},
                "runtime": {
                    "semanticCognitionResponses": {
                        "GOSSIP": {
                            "targetID": "npc_mara",
                            "responseTargetID": "npc_unavailable",
                            "gossip": {"subject": "Sarah", "codes": [1001]},
                        },
                    },
                },
            },
        )
        with self.warm_worker(scenario) as worker:
            result = worker.input("any news about Sarah?")

        request = next(
            event
            for event in result["dispatchTransport"]
            if event.get("command") == "SemanticCognitionRequest"
        )
        response = next(
            event
            for event in result["dispatchTransport"]
            if event.get("eventName") == "OnServerCommand"
            and event.get("command") == "SemanticCognition"
        )
        self.assertEqual(request["payload"]["targetID"], "npc_mara")
        self.assertEqual(response["payload"]["targetID"], "npc_unavailable")


if __name__ == "__main__":
    unittest.main()
