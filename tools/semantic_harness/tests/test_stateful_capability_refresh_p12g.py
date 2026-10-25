"""Production-Lua acceptance for post-command capability reprojection."""

from __future__ import annotations

import unittest
from copy import deepcopy

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.tests.test_companion_orders_hub_p12e import open_orders


class StatefulCapabilityRefreshP12GTests(unittest.TestCase):
    def test_go_home_state_removes_no_longer_meaningful_go_row(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["runtime"]["commandResponses"]["return_home"] = {
            "accepted": True,
            "reason": "network_queued",
            "state": {
                "npc": {
                    "activeBehavior": "AtHome:returning",
                    "followState": {"mode": "idle"},
                },
            },
        }
        with LuaSemanticWorker(scenario) as worker:
            orders = open_orders(worker)
            go_home = next(
                row for row in orders["conversationPresentation"]["responseChannel"]["rows"]
                if row["id"] == "action.go_home"
            )
            result = worker.suggestion_click(go_home["frame"])
            action = result["result"]["actionResult"]
            self.assertTrue(action["accepted"])
            self.assertEqual(action["commandID"], "return_home")

            eligible = {
                row["action"]
                for row in result["observation"]["suggestions"]["permittedCapabilities"]
                if row.get("groupID") == "companion.orders"
            }
            self.assertEqual(eligible, {"FOLLOW"})
            self.assertEqual(result["scenario"]["npc"]["activeBehavior"], "AtHome:returning")

    def test_ineligible_authoritative_state_cannot_project_camp_destinations(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["activeBehavior"] = "busy"
        scenario["campSiteCandidates"] = [
            {
                "kind": "camp_site",
                "scope": "room",
                "siteID": "site-house",
                "roomID": "room-living",
                "roomType": "LIVING_ROOM",
                "label": "living room",
                "x": 10,
                "y": 20,
                "z": 0,
            },
        ]
        with LuaSemanticWorker(scenario) as worker:
            worker.open_conversation()
            root = worker.conversation_projection()["presentation"]["responseChannel"]
            root_rows = {row["id"]: row for row in root["rows"]}
            orders = worker.suggestion_click(root_rows["companion.orders:open"]["frame"])
            orders_rows = {
                row["id"]: row
                for row in orders["conversationPresentation"]["responseChannel"]["rows"]
            }
            camp = worker.suggestion_click(orders_rows["companion.orders:camp"]["frame"])
            camp_rows = camp["conversationPresentation"]["responseChannel"]["rows"]
            self.assertEqual(
                [row["id"] for row in camp_rows],
                ["semantic.back_to_root:companion.camp"],
            )


if __name__ == "__main__":
    unittest.main()
