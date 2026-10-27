"""G0A acceptance for metadata-driven simple-command flow generation."""

from __future__ import annotations

import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class AutomaticFlowGenerationTests(unittest.TestCase):
    def test_live_coverage_generates_follow_and_stay_from_one_template(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()
            coverage = worker.flow_coverage()
            capabilities = worker.capabilities()

        generation = catalog["generation"]
        self.assertEqual(generation["templateVersion"], 1)
        self.assertIn("simple_command:v1", generation["templateFingerprint"])
        self.assertEqual(generation["summary"]["generated"], 17)
        self.assertEqual(generation["summary"]["unsupported_workflow"], 0)
        self.assertEqual(generation["summary"]["metadata_incomplete"], 0)
        rows = {
            row["id"]: row for row in generation["coverage"]
        }
        self.assertEqual(rows["FOLLOW"]["classification"], "generated")
        self.assertEqual(rows["STAY"]["classification"], "generated")
        self.assertEqual(rows["WAIT_AT"]["classification"], "generated")
        self.assertEqual(rows["FETCH"]["classification"], "generated")
        self.assertEqual(
            {row["id"] for row in coverage},
            set(rows),
        )
        manifest_roles = {
            module["role"]: module["path"]
            for module in capabilities["moduleManifest"]
            if module.get("role") in {
                "semantic_generation_manifest", "semantic_generated_flows",
            }
        }
        self.assertIn("PNC_SemanticAutomaticFlowManifest.lua", manifest_roles["semantic_generation_manifest"])
        self.assertIn("PNC_SemanticGeneratedAutomaticFlows.lua", manifest_roles["semantic_generated_flows"])

        flows = {
            flow["id"]: flow
            for flow in catalog["flows"]
            if flow.get("workflowKind") == "simple_command"
        }
        self.assertEqual(len(flows), 9)
        follow = flows[rows["FOLLOW"]["flowID"]]
        stay = flows[rows["STAY"]["flowID"]]
        self.assertEqual(set(follow["nodes"]), set(stay["nodes"]))
        self.assertEqual(follow["templateVersion"], stay["templateVersion"])
        for flow in (follow, stay):
            action = flow["nodes"]["request"]["action"]
            self.assertEqual(action["dispatchCount"], 1)
            self.assertEqual(
                set(action["resultTransitions"]),
                {"accepted", "failed", "network_queued", "pending", "queued", "rejected"},
            )
            self.assertEqual(
                set(action["resultTransitions"].values()),
                {"queued", "rejected", "failed"},
            )

    def test_parameterized_task_template_generates_wait_at_and_fetch(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()
            wait_at = worker.input("Wait at the campfire")
            fetch = worker.input("Bring me the can opener")

        task_flows = [
            flow for flow in catalog["flows"]
            if flow.get("workflowKind") == "parameterized_task"
        ]
        self.assertEqual(
            {flow["capabilityID"] for flow in task_flows},
            {
                "pnc:task.consume",
                "pnc:task.drink",
                "pnc:task.eat",
                "pnc:task.fetch",
                "pnc:task.give",
                "pnc:task.refill",
                "pnc:task.wait_at",
            },
        )
        for flow in task_flows:
            action = flow["nodes"]["request"]["action"]
            self.assertEqual(action["route"], "existing_semantic_task")
            self.assertEqual(action["dispatchCount"], 1)
            self.assertEqual(
                set(action["resultTransitions"].values()),
                {"admitted", "active", "completed", "rejected", "failed"},
            )
            self.assertEqual(
                set(flow["nodes"]),
                {"authorize", "request", "admitted", "active", "completed", "rejected", "failed"},
            )
        for result, capability, node, text in (
            (wait_at, "pnc:task.wait_at", "admitted", "Okay, I'll wait there."),
            (fetch, "pnc:task.fetch", "admitted", "I'll fetch that."),
        ):
            flow = result["result"]["flow"]
            self.assertTrue(flow["generated"])
            self.assertEqual(flow["workflowKind"], "parameterized_task")
            self.assertEqual(flow["capabilityID"], capability)
            self.assertEqual(flow["resultNodeId"], node)
            self.assertEqual(flow["resultOutcome"], node)
            self.assertEqual(flow["dispatchCount"], 1)
            self.assertEqual(result["result"]["actionResult"]["handlerID"], "PNC.Client.RequestSemanticTask")
            self.assertEqual(len(result["transport"]), 1)
            self.assertEqual(result["messages"][0]["payload"]["text"], text)

    def test_all_dispatchable_registered_capabilities_use_existing_handlers(self) -> None:
        phrases = {
            "CAMP": "Camp here",
            "GO": "Go home",
            "STOP": "Stop following me",
            "GIVE": "Give me the can opener",
            "EAT": "Eat the apple",
            "DRINK": "Drink the water",
            "REFILL": "Refill the bottle",
            "CONSUME": "Use the bandage",
        }
        expected_handlers = {
            "CAMP": "PNC.Client.SendCompanionCommand",
            "GO": "PNC.Client.SendCompanionCommand",
            "STOP": "PNC.Client.SendCompanionCommand",
            "GIVE": "PNC.Client.RequestSemanticTask",
            "EAT": "PNC.Client.RequestSemanticTask",
            "DRINK": "PNC.Client.RequestSemanticTask",
            "REFILL": "PNC.Client.RequestSemanticTask",
            "CONSUME": "PNC.Client.RequestSemanticTask",
        }
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()
            turns = {
                action: worker.input(phrase)
                for action, phrase in phrases.items()
            }

        coverage = {row["id"]: row for row in catalog["generation"]["coverage"]}
        self.assertEqual(catalog["generation"]["summary"]["generated"], 17)
        self.assertEqual(catalog["generation"]["summary"]["legacy"], 0)
        self.assertEqual(catalog["generation"]["summary"]["unsupported_workflow"], 0)
        self.assertEqual(coverage["HELP"]["classification"], "generated")
        self.assertEqual(coverage["TAKE"]["classification"], "recognition_only")

        for action, result in turns.items():
            flow = result["result"]["flow"]
            action_result = result["result"]["actionResult"]
            self.assertTrue(flow["generated"], action)
            self.assertEqual(flow["dispatchCount"], 1, action)
            self.assertEqual(action_result["handlerID"], expected_handlers[action])
            self.assertEqual(len(result["transport"]), 1, action)
            self.assertTrue(result["messages"], action)

    def test_parameterized_task_result_branches_and_gate_are_truthful(self) -> None:
        rejected_scenario = merge(
            DEFAULT_SCENARIO,
            {"runtime": {"taskResponses": {
                "WAIT_AT": {
                    "accepted": False,
                    "reason": "task_denied",
                    "details": {"status": "rejected"},
                },
            }}},
        )
        failed_scenario = merge(
            DEFAULT_SCENARIO,
            {"runtime": {"taskResponses": {
                "WAIT_AT": {
                    "accepted": False,
                    "reason": "task_failed",
                    "details": {"status": "failed"},
                },
            }}},
        )
        gated_scenario = merge(
            DEFAULT_SCENARIO,
            {"conversation": {"semanticAuthorization": {"authorized": False}}},
        )
        with LuaSemanticWorker(rejected_scenario) as worker:
            rejected = worker.input("Wait at the campfire")
        with LuaSemanticWorker(failed_scenario) as worker:
            failed = worker.input("Wait at the campfire")
        with LuaSemanticWorker(gated_scenario) as worker:
            gated = worker.input("Wait at the campfire")

        self.assertEqual(rejected["result"]["flow"]["resultNodeId"], "rejected")
        self.assertEqual(
            rejected["messages"][0]["payload"]["text"],
            "I can't wait there right now.",
        )
        self.assertEqual(failed["result"]["flow"]["resultNodeId"], "failed")
        self.assertEqual(
            failed["messages"][0]["payload"]["text"],
            "I couldn't wait there.",
        )
        self.assertEqual(gated["result"]["flow"]["toNodeId"], "rejected")
        self.assertEqual(gated["transport"], [])
        self.assertEqual(
            gated["result"]["actionResult"]["status"],
            "semantic_dispatch_blocked",
        )

    def test_real_worker_records_result_nodes_and_one_dispatch(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            follow = worker.input("Follow me")
            stay = worker.input("Stay here")

        for result, action, response_key in (
            (follow, "follow", "UI_PNC_Conversation_Semantic_GeneratedFollowQueued"),
            (stay, "stay", "UI_PNC_Conversation_Semantic_GeneratedStayQueued"),
        ):
            flow = result["result"]["flow"]
            self.assertTrue(flow["generated"])
            self.assertEqual(flow["resultOutcome"], "queued")
            self.assertEqual(flow["resultNodeId"], "queued")
            self.assertEqual(flow["dispatchCount"], 1)
            self.assertEqual(result["result"]["actionResult"]["status"], "accepted")
            self.assertEqual(result["result"]["actionResult"]["commandID"], action)
            self.assertEqual(len(result["transport"]), 1)
            self.assertEqual(result["messages"][0]["payload"]["translationKey"], response_key)

    def test_generated_simple_command_uses_relationship_and_personality_context(self) -> None:
        friendly_scenario = merge(
            DEFAULT_SCENARIO,
            {"npc": {"traits": {"friendly": True}}},
        )
        trusted_scenario = merge(
            DEFAULT_SCENARIO,
            {
                "npc": {
                    "traits": {"reserved": True},
                    "startingRelationship": {
                        "kind": "friend",
                        "source": "starting_companion_trait",
                    },
                    "relationship": {
                        "approval": 80,
                        "respect": 70,
                        "familiarity": 80,
                    },
                }
            },
        )
        tl_scenario = merge(
            friendly_scenario,
            {"runtime": {"language": "TL"}},
        )

        with LuaSemanticWorker(friendly_scenario) as worker:
            friendly = worker.input("Follow me")
        with LuaSemanticWorker(trusted_scenario) as worker:
            trusted = worker.input("Follow me")
        with LuaSemanticWorker(tl_scenario) as worker:
            tagalog = worker.input("Follow me")

        self.assertEqual(
            friendly["messages"][0]["payload"]["translationKey"],
            "UI_PNC_Conversation_Semantic_RealizationCompanionFollowWarm",
        )
        self.assertEqual(
            trusted["messages"][0]["payload"]["translationKey"],
            "UI_PNC_Conversation_Semantic_RealizationCompanionFollowWarm",
        )
        self.assertEqual(
            tagalog["messages"][0]["payload"]["translationKey"],
            "UI_PNC_Conversation_Semantic_RealizationCompanionFollowWarm",
        )
        self.assertEqual(tagalog["messages"][0]["payload"]["text"], "Siyempre, susunod ako sa iyo.")
        for result in (friendly, trusted, tagalog):
            self.assertTrue(result["result"]["flow"]["generated"])
            self.assertEqual(result["result"]["flow"]["resultOutcome"], "queued")
            self.assertEqual(result["result"]["flow"]["dispatchCount"], 1)
            self.assertEqual(len(result["transport"]), 1)

    def test_generated_simple_command_uses_bounded_previous_action_memory(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            first = worker.input("Follow me")
            repeated = worker.input("Follow me")

        self.assertEqual(
            first["messages"][0]["payload"]["translationKey"],
            "UI_PNC_Conversation_Semantic_GeneratedFollowQueued",
        )
        self.assertEqual(
            repeated["messages"][0]["payload"]["translationKey"],
            "UI_PNC_Conversation_Semantic_GeneratedFollowQueuedRepeated",
        )
        self.assertEqual(repeated["result"]["flow"]["resultOutcome"], "queued")
        self.assertEqual(repeated["result"]["flow"]["dispatchCount"], 1)
        self.assertEqual(len(repeated["transport"]), 1)

    def test_denied_failed_and_context_gate_are_truthful(self) -> None:
        denied_scenario = merge(
            DEFAULT_SCENARIO,
            {"runtime": {"commandResponses": {
                "follow": {"accepted": False, "reason": "unauthorized_companion"},
            }}},
        )
        failed_scenario = merge(
            DEFAULT_SCENARIO,
            {"runtime": {"commandResponses": {
                "follow": {
                    "accepted": False,
                    "reason": "transport_failed",
                    "details": {"status": "failed"},
                },
            }}},
        )
        gated_scenario = merge(
            DEFAULT_SCENARIO,
            {"conversation": {"semanticAuthorization": {"authorized": False}}},
        )
        with LuaSemanticWorker(denied_scenario) as worker:
            denied = worker.input("Follow me")
        with LuaSemanticWorker(failed_scenario) as worker:
            failed = worker.input("Follow me")
        with LuaSemanticWorker(gated_scenario) as worker:
            gated = worker.input("Follow me")

        self.assertEqual(denied["result"]["flow"]["resultNodeId"], "rejected")
        self.assertEqual(denied["messages"][0]["payload"]["text"], "I can't follow you right now.")
        self.assertEqual(failed["result"]["flow"]["resultNodeId"], "failed")
        self.assertEqual(failed["messages"][0]["payload"]["text"], "I couldn't start following you.")
        self.assertEqual(gated["result"]["flow"]["toNodeId"], "rejected")
        self.assertEqual(gated["result"]["actionResult"]["status"], "semantic_dispatch_blocked")
        self.assertEqual(gated["transport"], [])
        self.assertEqual(gated["messages"][0]["payload"]["text"], "I can't follow you right now.")

    def test_preview_is_pure_and_generation_survives_restart(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            first = worker.preview("Follow me")
            second = worker.preview("Follow me")
            generated = worker.generate_flows()
            regenerated = worker.generate_flows()
            worker.restart()
            after_restart = worker.flow_catalog()

        for preview in (first, second):
            self.assertTrue(preview["result"]["flow"]["generated"])
            self.assertEqual(preview["result"]["flow"]["toNodeId"], "request")
            self.assertEqual(preview["transport"], [])
            self.assertEqual(preview["messages"], [])
        self.assertEqual(
            generated["generation"]["templateFingerprint"],
            after_restart["generation"]["templateFingerprint"],
        )
        self.assertEqual(
            generated["generation"]["generatedFlowIDs"],
            after_restart["generation"]["generatedFlowIDs"],
        )
        self.assertEqual(
            regenerated["generation"]["regeneratedFlowIDs"],
            generated["generation"]["generatedFlowIDs"],
        )
        self.assertEqual(
            regenerated["generation"]["generatedFlowIDs"],
            generated["generation"]["generatedFlowIDs"],
        )

    def test_authoritative_gossip_memory_reaches_response_selection_in_en_and_tl(self) -> None:
        for language, expected in (
            ("EN", "Mara has been looking out for people."),
            ("TL", "Inaalalayan ni Mara ang mga tao."),
        ):
            scenario = merge(
                DEFAULT_SCENARIO,
                {"runtime": {
                    "language": language,
                    "semanticCognitionResponses": {
                        "GOSSIP": {
                            "targetID": "self",
                            "gossip": {"subject": "Mara", "codes": [1001]},
                        },
                    },
                }},
            )
            with self.subTest(language=language):
                with LuaSemanticWorker(scenario) as worker:
                    result = worker.input("any gossip?")

                response = result["result"]["decision"]["response"]
                self.assertEqual(response["templateID"], "semantic.gossip.memory")
                self.assertEqual(result["messages"][0]["payload"]["text"], expected)
                self.assertEqual(
                    [
                        event["command"]
                        for event in result["transport"]
                        if event.get("command") == "SemanticCognitionRequest"
                    ],
                    ["SemanticCognitionRequest"],
                )
                self.assertTrue(any(
                    event.get("eventName") == "OnServerCommand"
                    and event.get("command") == "SemanticCognition"
                    for event in result["transport"]
                ))

        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            unavailable = worker.input("any gossip?")
        self.assertEqual(
            unavailable["result"]["decision"]["response"]["templateID"],
            "semantic.gossip.unknown",
        )
        self.assertFalse(any(
            event.get("command") == "SemanticCognitionRequest"
            for event in unavailable["transport"]
        ))

    def test_authoritative_gossip_is_target_scoped_across_repeated_renamed_and_unavailable_targets(self) -> None:
        first_scenario = merge(
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
        with LuaSemanticWorker(first_scenario) as worker:
            first = worker.input("any news about Sarah?")
            second_scenario = merge(
                first_scenario,
                {
                    "npc": {"forename": "Morgan"},
                    "runtime": {
                        "semanticCognitionResponses": {
                            "GOSSIP": {
                                "targetID": "npc_mara",
                                "gossip": {
                                    "subject": "Morgan",
                                    "codes": [1001],
                                },
                            },
                        },
                    },
                },
            )
            worker.configure(second_scenario)
            second = worker.input("any news about Morgan?")

        self.assertEqual(
            first["result"]["decision"]["response"]["fallback"],
            "Sarah has been looking out for people.",
        )
        self.assertEqual(
            second["result"]["decision"]["response"]["fallback"],
            "Morgan has been looking out for people.",
        )
        second_request = next(
            event for event in second["transport"]
            if event.get("command") == "SemanticCognitionRequest"
        )
        self.assertEqual(second_request["payload"]["targetID"], "npc_mara")
        second_response = next(
            event for event in second["transport"]
            if event.get("eventName") == "OnServerCommand"
            and event.get("command") == "SemanticCognition"
        )
        self.assertEqual(second_response["payload"]["targetID"], "npc_mara")

        unavailable_scenario = merge(
            first_scenario,
            {
                "runtime": {
                    "semanticCognitionResponses": {
                        "GOSSIP": {
                            "targetID": "npc_unavailable",
                            "gossip": {"subject": "Sarah", "codes": [1001]},
                        },
                    },
                },
            },
        )
        with LuaSemanticWorker(unavailable_scenario) as worker:
            unavailable = worker.input("any news about Sarah?")
        self.assertEqual(
            unavailable["result"]["decision"]["response"]["templateID"],
            "semantic.gossip.unknown",
        )
        self.assertFalse(any(
            event.get("command") == "SemanticCognitionRequest"
            for event in unavailable["transport"]
        ))

        stale_scenario = merge(
            first_scenario,
            {
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
        with LuaSemanticWorker(stale_scenario) as worker:
            stale = worker.input("any news about Sarah?")
        self.assertEqual(
            stale["result"]["decision"]["response"]["templateID"],
            "semantic.gossip.unknown",
        )
        stale_response = next(
            event for event in stale["transport"]
            if event.get("eventName") == "OnServerCommand"
            and event.get("command") == "SemanticCognition"
        )
        self.assertEqual(stale_response["payload"]["targetID"], "npc_unavailable")
        self.assertFalse(any(
            message.get("payload", {}).get("text")
            == "Sarah has been looking out for people."
            for message in stale["messages"]
        ))


if __name__ == "__main__":
    unittest.main()
