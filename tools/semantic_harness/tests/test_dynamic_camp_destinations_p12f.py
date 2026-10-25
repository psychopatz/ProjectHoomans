"""Production-Lua acceptance for dynamic semantic CampSite destinations."""

from __future__ import annotations

import unittest
from copy import deepcopy

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


def camp_scenario(response: dict) -> dict:
    scenario = deepcopy(DEFAULT_SCENARIO)
    scenario["locationObservation"] = {
        "schemaVersion": 1,
        "kind": "semantic_location_observation",
        "source": "harness_fixture",
        "scope": "client_local",
        "origin": {"x": 10, "y": 20, "z": 0},
        "campSiteCandidates": [
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
            {
                "kind": "camp_site",
                "scope": "room",
                "siteID": "site-house",
                "roomID": "room-kitchen",
                "roomType": "KITCHEN",
                "label": "kitchen",
                "x": 11,
                "y": 20,
                "z": 0,
            },
        ],
    }
    scenario["runtime"]["commandResponses"]["camp"] = response
    return scenario


def camp_surface(worker: LuaSemanticWorker) -> dict:
    worker.open_conversation()
    root = worker.conversation_projection()["presentation"]["responseChannel"]
    root_rows = {row["id"]: row for row in root["rows"]}
    orders = worker.suggestion_click(root_rows["companion.orders:open"]["frame"])
    orders_channel = orders["conversationPresentation"]["responseChannel"]
    order_rows = {row["id"]: row for row in orders_channel["rows"]}
    camp = worker.suggestion_click(order_rows["companion.orders:camp"]["frame"])
    return camp


class DynamicCampDestinationsP12FTests(unittest.TestCase):
    def test_only_valid_discovered_destinations_project_and_transport(self) -> None:
        response = {
            "accepted": True,
            "reason": "network_queued",
            "state": {
                "npc": {
                    "activeBehavior": "camping",
                    "campSite": {
                        "siteID": "site-house",
                        "roomID": "room-living",
                    },
                },
            },
        }
        with LuaSemanticWorker(camp_scenario(response)) as worker:
            camp = camp_surface(worker)
            self.assertTrue(camp["accepted"])
            self.assertEqual(len(camp["messages"]), 1)
            self.assertEqual(camp["messages"][0]["speaker"], "npc")
            self.assertIn(
                "set up",
                str(camp["messages"][0]["payload"].get("text", "")).lower(),
            )
            channel = camp["conversationPresentation"]["responseChannel"]
            rows = {row["id"]: row for row in channel["rows"]}

            self.assertEqual(channel["groupID"], "companion.camp")
            self.assertIn("action.camp_site:site-house|room-living", rows)
            self.assertIn("action.camp_site:site-house|room-kitchen", rows)
            self.assertNotIn("action.camp_site:site-house|room-bedroom", rows)

            selected = rows["action.camp_site:site-house|room-living"]
            target = selected["frame"]["target"]
            self.assertEqual(target["siteID"], "site-house")
            self.assertEqual(target["roomID"], "room-living")
            self.assertEqual(target["kind"], "camp_site")

            result = worker.suggestion_click(selected["frame"])
            action = result["result"]["actionResult"]
            payload = result["transport"][0]["payload"]
            self.assertTrue(action["accepted"])
            self.assertEqual(len(result["messages"]), 1)
            self.assertEqual(result["messages"][0]["speaker"], "npc")
            self.assertIn(
                "living room",
                str(result["messages"][0]["payload"].get("text", "")).lower(),
            )
            self.assertEqual(action["commandID"], "camp")
            self.assertEqual(action["handlerID"], "PNC.Client.SendCompanionCommand")
            self.assertEqual(payload["commandID"], "camp")
            self.assertEqual(payload["campSiteHint"]["siteID"], "site-house")
            self.assertEqual(payload["campSiteHint"]["roomID"], "room-living")
            self.assertEqual(result["scenario"]["npc"]["activeBehavior"], "camping")

    def test_stale_server_result_rejects_without_mutating_order_state(self) -> None:
        response = {
            "accepted": False,
            "reason": "camp_site_hint_stale",
            "details": {"siteReason": "camp_site_hint_stale"},
        }
        with LuaSemanticWorker(camp_scenario(response)) as worker:
            camp = camp_surface(worker)
            channel = camp["conversationPresentation"]["responseChannel"]
            selected = next(
                row for row in channel["rows"]
                if row["id"] == "action.camp_site:site-house|room-kitchen"
            )

            result = worker.suggestion_click(selected["frame"])
            action = result["result"]["actionResult"]
            payload = result["transport"][0]["payload"]
            self.assertFalse(action["accepted"])
            self.assertEqual(len(result["messages"]), 1)
            self.assertEqual(result["messages"][0]["speaker"], "npc")
            self.assertIn(
                "camp",
                str(result["messages"][0]["payload"].get("text", "")).lower(),
            )
            self.assertEqual(action["commandID"], "camp")
            self.assertEqual(action["reason"], "camp_site_hint_stale")
            self.assertEqual(payload["campSiteHint"]["roomID"], "room-kitchen")
            self.assertEqual(result["scenario"]["npc"]["activeBehavior"], "idle")

    def test_empty_camp_projection_is_truthful_and_conversational(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            opened = worker.open_conversation()
            root = opened["presentation"]["responseChannel"]
            orders = worker.suggestion_click(
                next(row for row in root["rows"]
                     if row["id"] == "companion.orders:open")["semanticFrame"]
            )
            orders_channel = orders["conversationPresentation"]["responseChannel"]
            camp = worker.suggestion_click(
                next(row for row in orders_channel["rows"]
                     if row["id"] == "companion.orders:camp")["semanticFrame"]
            )

        rows = camp["conversationPresentation"]["responseChannel"]["rows"]
        self.assertTrue(camp["accepted"])
        self.assertEqual(len(camp["messages"]), 1)
        self.assertIn(
            "good place",
            str(camp["messages"][0]["payload"].get("text", "")).lower(),
        )
        self.assertFalse(any(row["id"].startswith("action.camp_site")
                             for row in rows))


if __name__ == "__main__":
    unittest.main()
