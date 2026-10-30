"""Production-Lua acceptance for the contextual companion Orders hub."""

from __future__ import annotations

import unittest
from copy import deepcopy

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


def response_channel(response: dict) -> dict:
    return response["conversationPresentation"]["responseChannel"]


def open_orders(worker: LuaSemanticWorker) -> dict:
    opened = worker.open_conversation()
    channel = worker.conversation_projection()["presentation"]["responseChannel"]
    hub = next(row["frame"] for row in channel["rows"]
               if row["id"] == "companion.orders:open")
    return worker.suggestion_click(hub)


class CompanionOrdersHubP12ETests(unittest.TestCase):
    def test_landing_has_one_orders_navigation_and_exclusive_initial_rows(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.open_conversation()
            channel = worker.conversation_projection()["presentation"]["responseChannel"]
            root_ids = {row["id"] for row in channel["rows"]}
            self.assertIn("companion.orders:open", root_ids)
            self.assertNotIn("action.follow", root_ids)
            self.assertNotIn("action.stay", root_ids)
            self.assertNotIn("action.wait_at", root_ids)

            orders = open_orders(worker)
            self.assertTrue(orders["accepted"])
            self.assertEqual(len(orders["messages"]), 1)
            self.assertEqual(orders["messages"][0]["speaker"], "npc")
            self.assertIn(
                "need",
                str(orders["messages"][0]["payload"].get("text", "")).lower(),
            )
            orders_channel = response_channel(orders)
            rows = {row["id"]: row for row in orders_channel["rows"]}
            self.assertEqual(orders_channel["groupID"], "companion.orders")
            self.assertIn("companion.orders:camp", rows)
            self.assertIn("action.follow", rows)
            self.assertIn("action.go_home", rows)
            self.assertNotIn("action.stay", rows)
            self.assertNotIn("action.wait_at", rows)

            camp = worker.suggestion_click(rows["companion.orders:camp"]["frame"])
            self.assertTrue(camp["accepted"])
            self.assertEqual(len(camp["messages"]), 1)
            self.assertEqual(camp["messages"][0]["speaker"], "npc")
            self.assertIn(
                "set up",
                str(camp["messages"][0]["payload"].get("text", "")).lower(),
            )
            self.assertEqual(
                camp["observation"]["suggestions"]["currentGroupID"],
                "companion.camp",
            )

    def test_follow_and_wait_reproject_from_authoritative_command_state(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            orders = open_orders(worker)
            follow = next(row["frame"] for row in response_channel(orders)["rows"]
                          if row["id"] == "action.follow")
            followed = worker.suggestion_click(follow)

            action = followed["result"]["actionResult"]
            self.assertEqual(action["commandID"], "follow")
            self.assertEqual(action["capabilityID"], "pnc:companion.follow")
            self.assertTrue(action["accepted"])
            self.assertEqual(followed["scenario"]["npc"]["followState"]["mode"],
                             "following")

            projection = followed["observation"]["suggestions"]
            self.assertEqual(projection["currentGroupID"], "companion.orders")
            order_actions = {
                row["action"]
                for row in projection["permittedCapabilities"]
                if row.get("groupID") == "companion.orders"
            }
            self.assertEqual(order_actions, {"STAY", "GO"})

            wait = next(row["frame"] for row in projection["permittedCapabilities"]
                        if row["action"] == "STAY")
            waited = worker.suggestion_click(wait)
            wait_action = waited["result"]["actionResult"]
            self.assertEqual(wait_action["commandID"], "stay")
            self.assertEqual(wait_action["capabilityID"], "pnc:companion.stay")
            self.assertTrue(wait_action["accepted"])
            self.assertEqual(waited["scenario"]["npc"]["followState"]["mode"],
                             "staying")

            after_wait = waited["observation"]["suggestions"]
            self.assertEqual(after_wait["currentGroupID"], "companion.orders")
            order_actions = {
                row["action"]
                for row in after_wait["permittedCapabilities"]
                if row.get("groupID") == "companion.orders"
            }
            self.assertEqual(order_actions, {"FOLLOW", "GO"})

    def test_go_home_uses_existing_return_home_command(self) -> None:
        scenario = merge(
            DEFAULT_SCENARIO,
            {
                "runtime": {
                    "commandResponses": {
                        "return_home": {
                            "accepted": True,
                            "reason": "network_queued",
                            "state": {
                                "npc": {
                                    "activeBehavior": "AtHome:returning",
                                    "followState": {"mode": "idle"},
                                }
                            },
                        }
                    }
                }
            },
        )
        with LuaSemanticWorker(scenario) as worker:
            orders = open_orders(worker)
            go_home = next(row["frame"]
                           for row in response_channel(orders)["rows"]
                           if row["id"] == "action.go_home")
            result = worker.suggestion_click(go_home)

        action = result["result"]["actionResult"]
        self.assertTrue(action["accepted"])
        self.assertEqual(action["commandID"], "return_home")
        self.assertEqual(action["capabilityID"], "pnc:companion.go_home")
        self.assertEqual(action["handlerID"], "PNC.Client.SendCompanionCommand")
        self.assertEqual(result["dispatchTransport"][0]["payload"]["commandID"],
                         "return_home")
        self.assertEqual(result["scenario"]["npc"]["activeBehavior"],
                         "AtHome:returning")
        self.assertEqual(result["observation"]["suggestions"]["currentGroupID"],
                         "companion.orders")


if __name__ == "__main__":
    unittest.main()
