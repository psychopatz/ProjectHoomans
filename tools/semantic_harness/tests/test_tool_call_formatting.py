"""Focused tests for readable production tool/action transcript entries."""

from __future__ import annotations

import unittest

from tools.semantic_harness.inspection.tool_calls import format_tool_call


class ToolCallFormattingTests(unittest.TestCase):
    def test_authority_request_shows_contract_route_and_input(self) -> None:
        rendered = format_tool_call(
            {
                "label": "validate_identity",
                "name": "SemanticIdentityRequest",
                "status": "sent",
                "authority": "singleplayer",
                "source": "transport",
                "arguments": {
                    "claimedName": "Quinn Owens",
                    "conversationToken": "private-token",
                    "kind": "identity_claim",
                    "npcID": "npc_mara",
                    "requestID": "identity_exchange:1002:1",
                },
            }
        )

        self.assertIn("validate_identity\n", rendered)
        self.assertIn("Contract: SemanticIdentityRequest", rendered)
        self.assertIn("Status: SENT", rendered)
        self.assertIn("Route: authority=singleplayer · source=transport", rendered)
        self.assertIn("claimedName=Quinn Owens", rendered)
        self.assertNotIn("private-token", rendered)

    def test_relationship_result_shows_response_change_and_state(self) -> None:
        rendered = format_tool_call(
            {
                "label": "adjust_relationship",
                "name": "AdjustRelationship",
                "status": "applied",
                "authority": "server",
                "accepted": True,
                "arguments": {
                    "relationshipAfter": {
                        "approval": -4,
                        "familiarity": 1,
                        "identityTrust": "untrustworthy",
                        "relationshipState": "unknown",
                        "respect": -6,
                        "revision": 2,
                    },
                    "relationshipDelta": {
                        "approval": -4,
                        "familiarity": 1,
                        "respect": -6,
                    },
                    "responseText": "I don't believe you.",
                },
            }
        )

        self.assertIn("Status: APPLIED", rendered)
        self.assertIn("Route: authority=server", rendered)
        self.assertIn("Response: I don't believe you.", rendered)
        self.assertIn("Change: approval -4 · respect -6 · familiarity +1", rendered)
        self.assertIn("State: identityTrust=untrustworthy", rendered)
        self.assertIn("Result: accepted", rendered)


if __name__ == "__main__":
    unittest.main()
