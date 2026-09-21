"""Small dependency-free regression tests for the real-Lua worker."""

from __future__ import annotations

import json
import os
import tempfile
import textwrap
import threading
import time
from pathlib import Path
import unittest

from tools.semantic_harness.config import HarnessConfig
from tools.semantic_harness.process import HarnessError, LuaProcess
from tools.semantic_harness.runner import HarnessCase, detect_conflicts, run_case
from tools.semantic_harness.scenario import DEFAULT_SCENARIO, load_scenario, merge, save_scenario
from tools.semantic_harness.worker import LuaSemanticWorker


class SemanticHarnessTests(unittest.TestCase):
    @staticmethod
    def message_text(result: dict) -> str:
        messages = result.get("messages", [])
        if not messages:
            return ""
        payload = messages[0].get("payload", {})
        return payload.get("fallback") or payload.get("text") or ""

    def test_worker_loads_production_modules_and_parses_greeting(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            result = worker.input("hello there")
        self.assertTrue(result["accepted"])
        self.assertEqual(result["result"]["decision"]["route"], "deterministic")
        self.assertIn("PNC/Semantics/PNC_SemanticDialogueInput.lua", result["loadedModules"])
        self.assertEqual(len(result["messages"]), 1)

    def test_scenario_save_round_trip_preserves_editable_runtime_state(self) -> None:
        scenario = merge(
            DEFAULT_SCENARIO,
            {
                "world": {"weather": "rain", "timeOfDay": 23.75},
                "runtime": {
                    "mode": "multiplayer",
                    "language": "TL",
                    "nativeTranslations": {"UI_Test": "Mabuhay %1"},
                    "commandResponses": {
                        "camp": {
                            "accepted": False,
                            "reason": "unsafe_site",
                            "details": {"siteLabel": "church", "siteScope": "yard"},
                        }
                    },
                },
                "npc": {
                    "traits": {"friendly": True},
                    "relationship": {"approval": 12},
                },
            },
        )
        with tempfile.TemporaryDirectory() as directory:
            path = save_scenario(Path(directory) / "edited.json", scenario)
            loaded = load_scenario(path)
        self.assertEqual(loaded["world"]["weather"], "rain")
        self.assertEqual(loaded["world"]["timeOfDay"], 23.75)
        self.assertEqual(loaded["runtime"]["mode"], "multiplayer")
        self.assertEqual(loaded["runtime"]["language"], "TL")
        self.assertEqual(loaded["runtime"]["nativeTranslations"]["UI_Test"], "Mabuhay %1")
        self.assertFalse(loaded["runtime"]["commandResponses"]["camp"]["accepted"])
        self.assertEqual(loaded["npc"]["traits"], {"friendly": True})
        self.assertEqual(loaded["npc"]["relationship"]["approval"], 12)
        self.assertEqual(loaded["player"]["inventory"]["items"][0]["fullType"], "Base.Apple")
        self.assertEqual(loaded["npc"]["inventory"]["items"][0]["fullType"], "Base.CannedSardines")

    def test_semantic_inventory_query_uses_editable_npc_inventory(self) -> None:
        scenario = merge(
            DEFAULT_SCENARIO,
            {
                "npc": {
                    "inventory": {
                        "revision": 7,
                        "items": [
                            {
                                "itemID": "npc_beans_1",
                                "fullType": "Base.CannedBeans",
                                "displayName": "Canned Beans",
                                "stack": 3,
                                "marketSense": {
                                    "primary": "FoodCanned",
                                    "category": "Food",
                                    "subcategory": "canned",
                                    "leaf": "beans",
                                    "tags": ["food", "canned"],
                                    "capabilities": {"edible": True},
                                },
                            }
                        ],
                    }
                }
            },
        )
        with LuaSemanticWorker(scenario) as worker:
            result = worker.input("do you have food")

        self.assertEqual(result["result"]["decision"]["branch"], "INVENTORY_QUERY_RECEIVED")
        action = result["result"]["actionResult"]
        self.assertEqual(action["result"]["inventoryRevision"], 7)
        self.assertEqual(action["result"]["items"][0]["displayName"], "Canned Beans")
        self.assertIn("Canned Beans", self.message_text(result))
        self.assertIn("query_inventory", {call["label"] for call in result["toolCalls"]})
        self.assertTrue(any(
            event["command"] == "SemanticInventoryQuery"
            for event in result["transport"]
        ))

    def test_news_questions_use_gossip_semantics_not_inventory(self) -> None:
        for utterance in (
            "you got any new",
            "you got any news",
            "have you got any news",
            "do you have any news",
            "any gossip?",
            "any gossips?",
            "tell me some gossip",
            "what's the gossip?",
            "have you heard any rumors?",
        ):
            with self.subTest(utterance=utterance):
                with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
                    result = worker.input(utterance)

                semantic = result["result"]
                ir = semantic["ir"]
                self.assertEqual(ir["intent"], "GOSSIP")
                self.assertEqual(ir["speechAct"], "GOSSIP")
                self.assertEqual(ir["subject"], "GOSSIP")
                self.assertEqual(
                    ir["slots"]["information"]["event"],
                    "NEWS",
                )
                self.assertEqual(
                    semantic["decision"]["branch"],
                    "GOSSIP_RECEIVED",
                )
                self.assertTrue(self.message_text(result))
                self.assertNotIn(
                    "query_inventory",
                    {call["label"] for call in result["toolCalls"]},
                )
                self.assertFalse(any(
                    event["command"] == "SemanticInventoryQuery"
                    for event in result["transport"]
                ))

        known_npc_scenario = merge({}, DEFAULT_SCENARIO)
        known_npc_scenario["npc"]["identityState"] = "known"
        known_npc_scenario["npc"]["forename"] = "Sarah"
        with LuaSemanticWorker(known_npc_scenario) as worker:
            named_news_query = worker.input("any news about Sarah?")
        named_semantic = named_news_query["result"]
        self.assertEqual(
            named_semantic["ir"]["intent"],
            "GOSSIP",
        )
        self.assertEqual(
            named_semantic["ir"]["target"]["name"],
            "Sarah Vale",
        )
        self.assertEqual(
            named_semantic["decision"]["branch"],
            "GOSSIP_RECEIVED",
        )
        self.assertNotIn(
            "query_inventory",
            {call["label"] for call in named_news_query["toolCalls"]},
        )

        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            new_item_query = worker.input("you got any new batteries")
        self.assertEqual(
            new_item_query["result"]["decision"]["branch"],
            "INVENTORY_QUERY_RECEIVED",
        )
        self.assertIn(
            "query_inventory",
            {call["label"] for call in new_item_query["toolCalls"]},
        )

    def test_gift_uses_editable_player_inventory_and_mutates_npc_projection(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            result = worker.input("here's an apple for you")
            snapshot = worker.snapshot()

        self.assertEqual(result["result"]["decision"]["branch"], "GIFT_OFFER_DISPATCHED")
        self.assertIn("transfer_item", {call["label"] for call in result["toolCalls"]})
        self.assertIn("adjust_relationship", {call["label"] for call in result["toolCalls"]})
        self.assertTrue(any(
            event["command"] == "InventoryTransfer"
            and event["direction"] == "client_to_server"
            for event in result["transport"]
        ))
        self.assertIn("Thank you for the Apple", self.message_text(result))
        self.assertEqual(result["relationshipAfter"]["approval"], 3)

        player_items = snapshot["scenario"]["player"]["inventory"]["items"]
        npc_items = snapshot["scenario"]["npc"]["inventory"]["items"]
        self.assertNotIn("player_apple_1", player_items)
        self.assertTrue(any(
            item.get("fullType") == "Base.Apple"
            and item.get("stack") == 1
            for item in npc_items.values()
        ))
        self.assertEqual(snapshot["scenario"]["player"]["inventory"]["revision"], 2)
        self.assertEqual(snapshot["scenario"]["npc"]["inventory"]["revision"], 2)

    def test_worker_can_restart_and_restore_the_current_scenario(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            worker.input("hello")
            response = worker.restart()
            result = worker.input("hello")
        self.assertEqual(response["type"], "configured")
        self.assertEqual(result["result"]["sequence"], 1)

    def test_actual_player_name_uses_authoritative_identity_exchange(self) -> None:
        scenario = merge(
            DEFAULT_SCENARIO,
            {"player": {"displayName": "SteamAlias"}},
        )
        with LuaSemanticWorker(scenario) as worker:
            worker.input("what is your name")
            result = worker.input("I'm Patrick")
        self.assertTrue(result["accepted"])
        self.assertEqual(result["result"]["ir"]["socialContext"]["identityClaim"], True)
        self.assertEqual(result["relationshipAfter"]["identityTrust"], "trusted")
        self.assertTrue(any(
            event.get("command") == "SemanticIdentityRequest"
            for event in result["transport"]
        ))
        self.assertIn(
            "validate_identity",
            {call.get("label") for call in result["toolCalls"]},
        )
        self.assertIn(
            "adjust_relationship",
            {call.get("label") for call in result["toolCalls"]},
        )
        self.assertEqual(len(result["messages"]), 1)
        self.assertIn("Mara", result["messages"][0]["payload"]["fallback"])

    def test_natural_identity_phrases_use_the_actual_character_name(self) -> None:
        for phrase in (
            "I'm Patrick, now your turn",
            "Patrick is my name, nice to meet you",
            "my name is Patrick",
            "call me Patrick",
        ):
            with self.subTest(phrase=phrase):
                with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
                    worker.input("what is your name")
                    result = worker.input(phrase)
                self.assertTrue(result["result"]["ir"]["socialContext"]["identityClaim"])
                self.assertEqual(result["relationshipAfter"]["identityTrust"], "trusted")
                self.assertIn("Mara", self.message_text(result))

    def test_profile_forename_phrase_is_authoritative_not_display_name(self) -> None:
        scenario = merge(
            DEFAULT_SCENARIO,
            {
                "player": {
                    "forename": "Psycho",
                    "surname": "Patz",
                    "displayName": "SteamDisplayName",
                }
            },
        )
        with LuaSemanticWorker(scenario) as worker:
            worker.input("what is your name")
            result = worker.input("Im psycho, now your turn")
        self.assertEqual(result["relationshipAfter"]["identityTrust"], "trusted")
        self.assertIn("Mara", self.message_text(result))

    def test_false_name_does_not_disclose_npc_name(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            worker.input("what is your name")
            result = worker.input("I'm Patricia")
        self.assertEqual(result["relationshipAfter"]["identityTrust"], "untrustworthy")
        self.assertLess(result["relationshipAfter"]["respect"], 0)
        self.assertTrue(any(
            "isn't your exact name" in (message.get("payload", {}).get("fallback") or "")
            for message in result["messages"]
        ))
        self.assertFalse(any(
            "Mara" in (message.get("payload", {}).get("fallback") or "")
            for message in result["messages"]
        ))

    def test_topic_change_after_name_question_costs_trust_and_stays_wary(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            worker.input("what is your name")
            result = worker.input("I'm starving")
            follow_up = worker.input("what is your name")
        self.assertEqual(result["result"]["decision"]["branch"], "IDENTITY_NAME_EVASION")
        self.assertEqual(result["relationshipAfter"]["identityTrust"], "untrustworthy")
        self.assertLess(result["relationshipAfter"]["approval"], 0)
        self.assertLess(result["relationshipAfter"]["respect"], 0)
        self.assertIn("trust", self.message_text(result).lower())
        follow_up_text = self.message_text(follow_up).lower()
        self.assertTrue(any(
            marker in follow_up_text for marker in ("trust", "lie", "liar")
        ))

    def test_self_reflection_is_not_an_insult_and_directed_insult_is(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            self_mockery = worker.input("I'm an idiot")
            directed = worker.input("you are an idiot")
        self.assertEqual(
            self_mockery["result"]["decision"]["branch"],
            "SELF_REFLECTION_RECEIVED",
        )
        self.assertEqual(self_mockery["result"]["ir"]["subject"], "SELF")
        self.assertEqual(directed["result"]["decision"]["branch"], "HOSTILE_REMARK_RECEIVED")
        self.assertEqual(directed["result"]["ir"]["subject"], "RECIPIENT")

    def test_self_blame_stays_self_directed(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            result = worker.input("it was my fault")
        self.assertEqual(result["result"]["decision"]["branch"], "SELF_REFLECTION_RECEIVED")
        self.assertEqual(
            result["result"]["ir"]["socialContext"]["reflectionType"],
            "SELF_BLAME",
        )

    def test_self_reflection_response_uses_relationship_and_traits(self) -> None:
        friendly = merge(
            DEFAULT_SCENARIO,
            {"npc": {"traits": {"friendly": True}, "relationshipState": "Friend"}},
        )
        reserved = merge(
            DEFAULT_SCENARIO,
            {"npc": {"traits": {"reserved": True}, "relationshipState": "Member"}},
        )
        with LuaSemanticWorker(friendly) as worker:
            friendly_result = worker.input("I'm an idiot")
        with LuaSemanticWorker(reserved) as worker:
            reserved_result = worker.input("I'm an idiot")
        self.assertIn("matter", self.message_text(friendly_result).lower())
        self.assertIn("harder", self.message_text(reserved_result).lower())

    def test_first_person_state_is_not_identity_claim(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            result = worker.input("I'm starving")
        ir = result["result"]["ir"]
        self.assertFalse(ir.get("socialContext", {}).get("identityClaim", False))
        self.assertNotEqual(ir.get("subject"), "IDENTITY")

    def test_real_tagalog_tool_catalog_and_live_language_switch(self) -> None:
        scenario = merge(DEFAULT_SCENARIO, {"runtime": {"language": "TL"}})
        with LuaSemanticWorker(scenario) as worker:
            name_reply = worker.tool_reply(
                [{"name": "ask_name", "accepted": True}],
                {"npc_name": "Mara Vale"},
            )
            language = worker.set_language("EN")
            camp_reply = worker.tool_reply(
                [{"name": "order_camp", "commandID": "order_camp", "accepted": True}],
                {"npc_name": "Mara Vale"},
            )
        self.assertEqual(name_reply["language"], "TL")
        self.assertIn("Mara Vale", name_reply["text"])
        self.assertEqual(name_reply["toolCalls"][0]["label"], "ask_name")
        self.assertTrue(any(
            lookup["key"].startswith("UI_PNC_Conversation_ToolReply_AskNameNamed_")
            for lookup in name_reply["translationLookups"]
        ))
        self.assertEqual(language["language"], "EN")
        self.assertEqual(camp_reply["language"], "EN")
        self.assertIn("camp", camp_reply["text"].lower())

    def test_tagalog_identity_exchange_uses_canonical_npc_translation(self) -> None:
        scenario = merge(DEFAULT_SCENARIO, {"runtime": {"language": "TL"}})
        with LuaSemanticWorker(scenario) as worker:
            worker.input("what is your name")
            result = worker.input("I'm Patrick")
        payload = result["messages"][0]["payload"]
        self.assertEqual(
            payload["key"],
            "UI_PNC_Conversation_Semantic_IdentityExchangeConfirmed",
        )
        self.assertEqual(payload["args"], ["Patrick", "Mara Vale"])
        self.assertEqual(
            payload["text"],
            "Sige, Patrick. Ikinagagalak kitang makilala. Ako si Mara Vale.",
        )
        self.assertTrue(any(
            lookup["kind"] == "trFormat"
            and lookup["key"] == payload["key"]
            and lookup["language"] == "TL"
            for lookup in result["translation"]["lookups"]
        ))

    def test_tagalog_semantic_identity_and_self_reflection_use_catalogs(self) -> None:
        scenario = merge(
            DEFAULT_SCENARIO,
            {
                "runtime": {"language": "TL"},
                "npc": {
                    "traits": {"friendly": True},
                    "relationshipState": "Friend",
                },
            },
        )
        with LuaSemanticWorker(scenario) as worker:
            initial = worker.input("what is your name")
            worker.input("I'm Patricia")
            wary = worker.input("what is your name")
        with LuaSemanticWorker(scenario) as worker:
            reflection = worker.input("I'm an idiot")
        initial_payload = initial["messages"][0]["payload"]
        self.assertTrue(initial_payload["translationKey"].startswith(
            "UI_PNC_Conversation_Semantic_QuestionIdentity"
        ))
        self.assertNotIn("Mara", initial_payload["text"])
        self.assertTrue(any(
            word in initial_payload["text"].lower()
            for word in ("pangalan", "tawag")
        ))
        wary_payload = wary["messages"][0]["payload"]
        self.assertTrue(wary_payload["translationKey"].startswith(
            "UI_PNC_Conversation_Semantic_QuestionIdentityWary"
        ))
        self.assertIn("pangalan", wary_payload["text"].lower())
        self.assertIn("sarili", reflection["messages"][0]["payload"]["text"].lower())

    def test_action_boundary_uses_configurable_mock_and_reports_tools(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            result = worker.input("let's camp here")
        self.assertTrue(any(
            call["name"] == "camp"
            and call["label"] == "camp"
            and call["status"] == "pending"
            for call in result["toolCalls"]
        ))
        self.assertTrue(any(
            event.get("command") == "CompanionCommand"
            and event.get("payload", {}).get("commandID") == "camp"
            for event in result["transport"]
        ))
        text = self.message_text(result).lower()
        self.assertIn("safehouse", text)
        self.assertNotIn("to in", text)

    def test_worker_reports_grounded_module_manifest_and_translation_state(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            capabilities = worker.capabilities()
        manifest_paths = [item["path"] for item in capabilities["moduleManifest"]]
        self.assertIn(
            "ProjectHoomans:shared:PNC/Translation/PNC_TranslationBootstrap.lua",
            manifest_paths,
        )
        self.assertIn(
            "ProjectHoomans:shared:PNC/Conversation/PNC_ConversationToolReplies.lua",
            manifest_paths,
        )
        self.assertIn(
            "ProjectHoomans:server:PNC/Semantics/Inventory/PNC_SemanticInventoryQueryService.lua",
            manifest_paths,
        )
        self.assertIn(
            "ProjectHoomans:shared:PNC/Gifts/PNC_GiftMarketSenseAdapter.lua",
            manifest_paths,
        )
        self.assertEqual(capabilities["translation"]["language"], "EN")
        self.assertIn("PNC/Translation/PNC_TranslationBootstrap.lua", capabilities["loadedModules"])

    @staticmethod
    def fake_worker() -> tuple[tempfile.TemporaryDirectory[str], HarnessConfig]:
        temporary = tempfile.TemporaryDirectory()
        script = Path(temporary.name) / "fake_worker.py"
        script.write_text(
            textwrap.dedent(
                """
                #!/usr/bin/env python3
                import json
                import sys
                import time

                print(json.dumps({"protocolVersion": 1, "id": "__hello__", "ok": True, "type": "hello"}), flush=True)
                for line in sys.stdin:
                    request = json.loads(line)
                    command = request.get("command")
                    if command == "SLEEP":
                        time.sleep(0.5)
                    if command == "QUIT":
                        print(json.dumps({"protocolVersion": 1, "id": request["id"], "ok": True, "type": "closed"}), flush=True)
                        break
                    print(json.dumps({
                        "protocolVersion": 1,
                        "id": request["id"],
                        "ok": True,
                        "type": "echo",
                        "payload": request.get("payload"),
                    }), flush=True)
                """
            ).strip()
            + "\n",
            encoding="utf-8",
        )
        script.chmod(script.stat().st_mode | 0o111)
        repository = Path(__file__).resolve().parents[2]
        config = HarnessConfig(
            repository=repository,
            core_repository=repository.parent / "psychopatzCore",
            lua_bin=script,
            worker_script=script,
            startup_timeout=1.0,
            request_timeout=1.0,
            shutdown_timeout=0.2,
        )
        return temporary, config

    def test_process_correlates_requests_and_serializes_concurrent_callers(self) -> None:
        temporary, config = self.fake_worker()
        self.addCleanup(temporary.cleanup)
        runtime = LuaProcess(config)
        self.addCleanup(runtime.close)
        hello = runtime.start()
        self.assertEqual(hello["type"], "hello")
        results: list[dict] = []
        errors: list[Exception] = []
        barrier = threading.Barrier(3)

        def call(value: int) -> None:
            try:
                barrier.wait(timeout=1)
                results.append(runtime.request("ECHO", {"value": value}))
            except Exception as error:  # pragma: no cover - assertion reports the error
                errors.append(error)

        threads = [threading.Thread(target=call, args=(value,)) for value in (1, 2)]
        for thread in threads:
            thread.start()
        barrier.wait(timeout=1)
        for thread in threads:
            thread.join(timeout=2)
        self.assertEqual(errors, [])
        self.assertEqual(sorted(response["payload"]["value"] for response in results), [1, 2])
        self.assertEqual(runtime.state, "READY")

    def test_process_timeout_fails_fast_and_terminates_the_worker(self) -> None:
        temporary, base_config = self.fake_worker()
        self.addCleanup(temporary.cleanup)
        config = HarnessConfig(
            repository=base_config.repository,
            core_repository=base_config.core_repository,
            lua_bin=base_config.lua_bin,
            worker_script=base_config.worker_script,
            startup_timeout=1.0,
            request_timeout=0.05,
            shutdown_timeout=0.1,
        )
        runtime = LuaProcess(config)
        self.addCleanup(runtime.close)
        runtime.start()
        started = time.monotonic()
        with self.assertRaises(HarnessError):
            runtime.request("SLEEP")
        elapsed = time.monotonic() - started
        self.assertLess(elapsed, 1.0)
        self.assertEqual(runtime.state, "FAILED")

    def test_case_runner_returns_turns_and_ignores_transport_mirrors(self) -> None:
        report = run_case(
            HarnessCase(
                case_id="greeting",
                scenario=merge({}, DEFAULT_SCENARIO),
                inputs=("hello",),
            )
        )
        self.assertTrue(report.as_dict()["ok"])
        self.assertEqual(len(report.turns), 1)

    def test_conflict_ledger_detects_duplicate_authoritative_events(self) -> None:
        turn = {
            "result": {"sequence": 1},
            "relationshipBefore": {"revision": 1},
            "relationshipAfter": {"revision": 2},
            "transport": [
                {"direction": "server_to_client", "payload": {"eventID": "event-1"}},
                {"direction": "event", "payload": {"eventID": "event-1"}},
            ],
        }
        self.assertEqual(detect_conflicts([turn]), [])
        duplicate = {
            **turn,
            "transport": [
                {"direction": "server_to_client", "payload": {"eventID": "event-1"}},
                {"direction": "server_to_client", "payload": {"eventID": "event-1"}},
            ],
        }
        conflicts = detect_conflicts([duplicate])
        self.assertEqual(conflicts[0]["kind"], "duplicate_authoritative_event")


if __name__ == "__main__":
    unittest.main()
