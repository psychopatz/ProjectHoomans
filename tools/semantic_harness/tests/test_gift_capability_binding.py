"""Real-Lua Semantic Lab acceptance for the existing gift lifecycle route."""

from __future__ import annotations

import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class GiftCapabilityBindingTests(unittest.TestCase):
    def test_live_catalog_exposes_existing_gift_transfer_binding(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            gift = next(
                row
                for row in worker.flow_catalog()["actionCatalog"]
                if row["id"] == "GIFT"
            )

        self.assertTrue(gift["recognized"])
        self.assertTrue(gift["dispatchable"])
        self.assertEqual(gift["binding"]["id"], "pnc:gift.offer")
        self.assertEqual(
            gift["binding"]["handlerID"],
            "PNC.Client.SendInventoryTransfer",
        )
        self.assertEqual(
            gift["binding"]["route"], "existing_inventory_transfer"
        )
        self.assertEqual(gift["workflowKind"], "multi_stage_gift")

    def test_gift_offer_preview_and_authoritative_result_trace(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            previews = [
                worker.preview("I want to give you an apple") for _ in range(2)
            ]
            committed = worker.input("I want to give you an apple")
            vague = worker.input("I have a gift for you")

        for preview in previews:
            self.assertEqual(preview["observation"]["ir"]["action"], "GIFT")
            self.assertEqual(
                preview["observation"]["capabilityBinding"]["id"],
                "pnc:gift.offer",
            )
            self.assertTrue(preview["observation"]["sideEffects"]["none"])
            self.assertEqual(preview["transport"], [])
            self.assertEqual(preview["toolCalls"], [])

        result = committed["result"]
        self.assertEqual(result["ir"]["intent"], "OFFER")
        self.assertEqual(result["ir"]["action"], "GIFT")
        self.assertEqual(
            result["ir"]["provenance"]["pattern"], "pnc.social.gift_give_you"
        )
        self.assertEqual(
            result["decision"]["branch"], "GIFT_OFFER_DISPATCHED"
        )
        self.assertTrue(result["actionResult"]["accepted"])
        self.assertTrue(result["actionResult"]["pending"])
        self.assertEqual(
            result["actionResult"]["capabilityID"], "pnc:gift.offer"
        )
        self.assertEqual(
            result["actionResult"]["handlerID"],
            "PNC.Client.SendInventoryTransfer",
        )
        self.assertTrue(result["flow"]["generated"])
        self.assertEqual(result["flow"]["workflowKind"], "multi_stage_gift")
        self.assertEqual(result["flow"]["capabilityID"], "pnc:gift.offer")
        self.assertEqual(result["flow"]["resultNodeId"], "pending")
        self.assertEqual(result["flow"]["resultOutcome"], "pending")
        self.assertEqual(result["flow"]["dispatchCount"], 1)
        self.assertEqual(
            result["actionResult"]["request"]["itemIDs"], ["player_apple_1"]
        )
        self.assertEqual(
            [event["command"] for event in committed["transport"]].count(
                "InventoryTransfer"
            ),
            1,
        )
        self.assertIn(
            "InventoryResult",
            [event["command"] for event in committed["transport"]],
        )
        self.assertEqual(committed["messages"][0]["payload"]["text"],
                         "Thank you for the Apple.")
        self.assertEqual(committed["toolCalls"][0]["name"], "GIFT")
        self.assertIn(
            "AdjustRelationship", [call["name"] for call in committed["toolCalls"]]
        )

        self.assertEqual(
            vague["result"]["decision"]["branch"], "GIFT_SELECTION_REQUIRED"
        )
        self.assertEqual(vague["transport"], [])
        self.assertEqual(vague["toolCalls"][0]["name"], "GIFT")
        self.assertFalse(vague["toolCalls"][0]["accepted"])
        self.assertEqual(vague["toolCalls"][0]["reason"],
                         "inventory_ui_unavailable")

    def test_generated_gift_authorization_gate_and_lifecycle_template(self) -> None:
        gated_scenario = merge(
            DEFAULT_SCENARIO,
            {"conversation": {"semanticAuthorization": {"authorized": False}}},
        )
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()
            generation = catalog["generation"]
        with LuaSemanticWorker(gated_scenario) as worker:
            result = worker.input("I want to give you an apple")
            worker.set_language("TL")
            tagalog = worker.input("I want to give you an apple")

        gift_flows = [
            flow for flow in catalog["flows"]
            if flow.get("workflowKind") == "multi_stage_gift"
        ]
        self.assertEqual(len(gift_flows), 1)
        self.assertEqual(
            set(gift_flows[0]["nodes"]),
            {"authorize", "request", "selection_required", "pending",
             "completed", "rejected", "failed"},
        )
        self.assertEqual(generation["summary"]["generated"], 17)
        self.assertEqual(generation["summary"]["unsupported_workflow"], 0)
        self.assertEqual(
            next(row for row in generation["coverage"] if row["id"] == "GIFT")["classification"],
            "generated",
        )
        self.assertEqual(result["result"]["flow"]["toNodeId"], "rejected")
        self.assertEqual(
            result["result"]["actionResult"]["status"],
            "semantic_dispatch_blocked",
        )
        self.assertEqual(result["transport"], [])
        self.assertEqual(
            result["messages"][0]["payload"]["text"],
            "I can't accept that gift right now.",
        )
        self.assertEqual(
            tagalog["messages"][0]["payload"]["text"],
            "Hindi ko matanggap ang regalong iyan ngayon.",
        )


if __name__ == "__main__":
    unittest.main()
