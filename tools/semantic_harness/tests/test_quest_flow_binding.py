"""G3B acceptance for the semantic Clinic Supplies quest contract."""

from __future__ import annotations

import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class QuestFlowBindingTests(unittest.TestCase):
    def test_quest_operations_are_generated_from_registered_metadata(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()

        generation = catalog["generation"]
        rows = {row["id"]: row for row in generation["coverage"]}
        self.assertEqual(generation["summary"]["generated"], 17)
        self.assertEqual(generation["summary"]["metadata_incomplete"], 0)
        self.assertEqual(generation["summary"]["unsupported_workflow"], 0)
        for action, capability in (
            ("HELP", "pnc:quest.clinic_supplies.offer"),
            ("QUEST_ACCEPT", "pnc:quest.clinic_supplies.accept"),
            ("QUEST_STATUS", "pnc:quest.clinic_supplies.status"),
            ("QUEST_TURN_IN", "pnc:quest.clinic_supplies.turn_in"),
        ):
            self.assertEqual(rows[action]["classification"], "generated")
            self.assertEqual(rows[action]["capabilityID"], capability)

        flows = {
            flow["capabilityID"]: flow
            for flow in catalog["flows"]
            if flow.get("capabilityID", "").startswith("pnc:quest.")
        }
        self.assertEqual(set(flows), {
            "pnc:quest.clinic_supplies.offer",
            "pnc:quest.clinic_supplies.accept",
            "pnc:quest.clinic_supplies.status",
            "pnc:quest.clinic_supplies.turn_in",
        })
        template_versions = {flow["templateVersion"] for flow in flows.values()}
        self.assertEqual(template_versions, {1})
        for flow in flows.values():
            action = flow["nodes"]["request"]["action"]
            self.assertEqual(action["route"], "existing_quest_contract")
            self.assertEqual(action["binding"]["handlerID"],
                             "PNC.Client.RequestSemanticQuest")
            self.assertEqual(action["dispatchCount"], 1)

    def test_real_worker_routes_offer_accept_query_and_turn_in_results(self) -> None:
        phrases = (
            ("Can you help me?", "HELP", "available",
             "UI_PNC_Conversation_Semantic_QuestOffer"),
            ("Yes I will help with the supplies", "QUEST_ACCEPT", "accepted",
             "UI_PNC_Conversation_Semantic_QuestAccepted"),
            ("Is the clinic supplies quest done", "QUEST_STATUS", "active",
             "UI_PNC_Conversation_Semantic_QuestProgress"),
            ("I want to turn in the supplies", "QUEST_TURN_IN", "rewarded",
             "UI_PNC_Conversation_Semantic_QuestRewarded"),
        )
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            for phrase, action, status, translation_key in phrases:
                with self.subTest(phrase=phrase):
                    result = worker.input(phrase)
                    semantic = result["result"]
                    self.assertEqual(semantic["ir"]["action"], action)
                    self.assertTrue(semantic["flow"]["generated"])
                    self.assertEqual(semantic["flow"]["dispatchCount"], 1)
                    self.assertEqual(semantic["actionResult"]["status"], status)
                    self.assertEqual(
                        semantic["actionResult"]["handlerID"],
                        "PNC.Client.RequestSemanticQuest",
                    )
                    self.assertEqual(
                        [event["command"] for event in result["transport"]],
                        ["SemanticQuestRequest", "SemanticQuestResult"],
                    )
                    self.assertEqual(
                        result["messages"][0]["payload"]["translationKey"],
                        translation_key,
                    )

    def test_quest_denied_failed_preview_and_repeat_are_truthful(self) -> None:
        denied_scenario = merge(
            DEFAULT_SCENARIO,
            {"runtime": {"questResponses": {
                "offer": {
                    "accepted": False,
                    "status": "rejected",
                    "reason": "quest_locked",
                },
            }}},
        )
        failed_scenario = merge(
            DEFAULT_SCENARIO,
            {"runtime": {"questResponses": {
                "offer": {
                    "accepted": False,
                    "status": "failed",
                    "reason": "quest_service_failed",
                },
            }}},
        )
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            preview = worker.preview("Can you help me?")
            first = worker.input("Can you help me?")
            repeated = worker.input("Can you help me?")
        with LuaSemanticWorker(denied_scenario) as worker:
            denied = worker.input("Can you help me?")
        with LuaSemanticWorker(failed_scenario) as worker:
            failed = worker.input("Can you help me?")

        self.assertTrue(preview["result"]["flow"]["generated"])
        self.assertEqual(preview["transport"], [])
        self.assertEqual(preview["messages"], [])
        self.assertEqual(first["result"]["flow"]["dispatchCount"], 1)
        self.assertEqual(repeated["result"]["actionResult"]["status"], "available")
        self.assertEqual(denied["result"]["flow"]["resultNodeId"], "rejected")
        self.assertEqual(
            denied["messages"][0]["payload"]["translationKey"],
            "UI_PNC_Conversation_Semantic_QuestLocked",
        )
        self.assertEqual(failed["result"]["flow"]["resultNodeId"], "failed")
        self.assertEqual(
            failed["messages"][0]["payload"]["translationKey"],
            "UI_PNC_Conversation_Semantic_QuestFailed",
        )

    def test_quest_response_has_en_and_tl_fallbacks(self) -> None:
        scenario = merge(DEFAULT_SCENARIO, {"runtime": {"language": "TL"}})
        with LuaSemanticWorker(scenario) as worker:
            result = worker.input("Can you help me?")
        payload = result["messages"][0]["payload"]
        self.assertEqual(payload["translationKey"],
                         "UI_PNC_Conversation_Semantic_QuestOffer")
        self.assertEqual(
            payload["text"],
            "May kahilingan ako para sa suplay ng klinika na matutulungan mo.",
        )
        self.assertEqual(result["translation"]["language"], "TL")

    def test_multiplayer_uses_production_boundary_and_deduplicates_replay(
        self,
    ) -> None:
        scenario = merge(DEFAULT_SCENARIO, {"runtime": {"mode": "multiplayer"}})
        with LuaSemanticWorker(scenario) as worker:
            capabilities = worker.capabilities()
            self.assertIn("REPLAY_SEMANTIC_QUEST", capabilities["capabilities"])

            first = worker.input("Can you help me?")
            self.assertEqual(worker.snapshot()["questBoundary"], "production")
            manifest = first["loadedModules"]
            self.assertIn(
                "PNC/Quests/PNC_QuestService.lua",
                manifest,
            )
            self.assertIn(
                "PNC/Networking/Handlers/PNC_ServerSemanticQuestCommandHandler.lua",
                manifest,
            )
            self.assertEqual(
                first["result"]["actionResult"]["status"],
                "pending",
                first["result"]["actionResult"],
            )
            self.assertEqual(
                first["result"]["actionResult"]["reason"], "network_queued"
            )
            self.assertEqual(first["result"]["flow"]["resultNodeId"], "queued")
            self.assertEqual(
                [(event["direction"], event["command"])
                 for event in first["transport"]],
                [
                    ("client_to_server", "SemanticQuestRequest"),
                    ("server_to_client", "SemanticQuestResult"),
                ],
            )
            self.assertEqual(
                first["messages"][0]["payload"]["translationKey"],
                "UI_PNC_Conversation_Semantic_QuestOffer",
            )

            request = next(
                event["payload"]
                for event in first["transport"]
                if event["command"] == "SemanticQuestRequest"
            )
            before = worker.snapshot()
            worker.replay_quest_request(request)
            after = worker.snapshot()
            self.assertEqual(len(after["transcript"]), len(before["transcript"]))
            self.assertEqual(len(after["queued"]), len(before["queued"]))
            duplicate_results = [
                event for event in after["transport"]
                if event["command"] == "SemanticQuestResult"
                and event["payload"].get("duplicate") is True
            ]
            self.assertEqual(len(duplicate_results), 1)
            self.assertEqual(
                duplicate_results[0]["payload"]["reason"],
                "duplicate_request",
            )

            restarted = worker.restart()
            self.assertIn("PNC/Quests/PNC_QuestService.lua", restarted["loadedModules"])
            second = worker.input("Can you help me?")
            self.assertEqual(
                [(event["direction"], event["command"])
                 for event in second["transport"]],
                [
                    ("client_to_server", "SemanticQuestRequest"),
                    ("server_to_client", "SemanticQuestResult"),
                ],
            )
            self.assertEqual(
                second["messages"][0]["payload"]["translationKey"],
                "UI_PNC_Conversation_Semantic_QuestOffer",
            )


if __name__ == "__main__":
    unittest.main()
