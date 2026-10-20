"""C2-A sparse, owner-linked commitments on the real Lua worker."""

from __future__ import annotations

import unittest

from tools.semantic_harness.process import HarnessError
from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


def acknowledged_scenario() -> dict:
    return merge(
        DEFAULT_SCENARIO,
        {
            "npc": {
                "runtime": {
                    "conversationLease": {
                        "token": "harness-lease",
                        "playerOnlineID": 1,
                        "playerUsername": "Patrick Patz",
                        "startedAt": 1000,
                        "expiresAt": 4000,
                        "maximumDistance": 6,
                        "dangerRadius": 8,
                        "processedConversationRequests": {
                            "ack-1": {
                                "success": True,
                                "npcID": "npc_mara",
                                "outcomeID": "promise.accepted",
                            },
                        },
                    },
                },
            },
        },
    )


class ContextualConversationC2Tests(unittest.TestCase):
    def test_acknowledged_commitment_survives_knowledge_reload(self) -> None:
        with LuaSemanticWorker(acknowledged_scenario()) as worker:
            accepted = worker.commitment(
                {
                    "operation": "record",
                    "npcID": "npc_mara",
                    "commitmentID": "bandages-1",
                    "topic": "medical",
                    "intent": "bring bandages",
                    # This ref is valid only because the lease contains the
                    # successful authoritative acknowledgement event.
                    "sourceFactRefs": ["conversation:ack-1"],
                    "acknowledgementRequestID": "ack-1",
                    # A caller-supplied identity must not change the owner.
                    "characterUUID": "char_other",
                }
            )
            reloaded = worker.commitment(
                {
                    "operation": "save_reload",
                    "npcID": "npc_mara",
                }
            )
            repeated = worker.commitment(
                {
                    "operation": "record",
                    "npcID": "npc_mara",
                    "commitmentID": "bandages-1",
                    "topic": "medical",
                    "intent": "bring bandages",
                    "sourceFactRefs": ["conversation:ack-1"],
                    "acknowledgementRequestID": "ack-1",
                }
            )

        result = accepted["result"]
        commitment = result["commitment"]
        self.assertTrue(result["accepted"])
        self.assertTrue(result["committed"])
        self.assertEqual(result["characterUUID"], "char_patrick")
        self.assertTrue(commitment["authoritative"])
        self.assertEqual(commitment["owner"], "npc_knowledge_journal")
        self.assertEqual(commitment["ownerNPCID"], "npc_mara")
        self.assertEqual(commitment["sourceFactRefs"], ["conversation:ack-1"])
        self.assertEqual(reloaded["commitments"], [commitment])
        self.assertTrue(repeated["result"]["duplicate"])
        self.assertEqual(len(repeated["persistenceCommits"]), 1)

    def test_unknown_unacknowledged_and_wrong_owner_are_not_authoritative(
        self,
    ) -> None:
        with LuaSemanticWorker(acknowledged_scenario()) as worker:
            with self.assertRaisesRegex(
                HarnessError, "commitment_evidence_unknown"
            ):
                worker.commitment(
                    {
                        "operation": "record",
                        "npcID": "npc_mara",
                        "commitmentID": "unknown-fact",
                        "topic": "medical",
                        "intent": "invented need",
                        "sourceFactRefs": ["unknown"],
                        "acknowledgementRequestID": "ack-1",
                    }
                )

            with self.assertRaisesRegex(
                HarnessError, "acknowledgement_event_not_found"
            ):
                worker.commitment(
                    {
                        "operation": "record",
                        "npcID": "npc_mara",
                        "commitmentID": "unconfirmed",
                        "topic": "medical",
                        "intent": "claim only",
                        "sourceFactRefs": ["conversation:not-accepted"],
                        "acknowledgementRequestID": "not-accepted",
                    }
                )

            with self.assertRaisesRegex(HarnessError, "npc_not_found"):
                worker.commitment(
                    {
                        "operation": "record",
                        "npcID": "npc_other",
                        "commitmentID": "wrong-owner",
                        "topic": "medical",
                        "intent": "bring bandages",
                        "sourceFactRefs": ["conversation:ack-1"],
                        "acknowledgementRequestID": "ack-1",
                    }
                )

            visible = worker.commitment(
                {"operation": "list", "npcID": "npc_mara"}
            )
        self.assertEqual(visible["commitments"], [])


if __name__ == "__main__":
    unittest.main()
