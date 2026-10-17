"""Semantic Lab checks for the public Core-backed translation seam."""

from __future__ import annotations

import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


class SemanticTranslationIntegrationTests(unittest.TestCase):
    @staticmethod
    def assert_resolved_lookups(test: unittest.TestCase, lookups: list[dict]) -> None:
        test.assertTrue(lookups)
        test.assertTrue(
            all(not lookup.get("fallbackUsed", False) for lookup in lookups),
            lookups,
        )

    def test_public_catalogs_resolve_dialogue_domains_in_en_and_tl(self) -> None:
        for language in ("EN", "TL"):
            with self.subTest(language=language):
                scenario = merge(
                    DEFAULT_SCENARIO,
                    {"runtime": {"language": language}},
                )
                with LuaSemanticWorker(scenario) as worker:
                    greeting = worker.input("hello there")
                    identity = worker.input("what is your name")
                    wellbeing = worker.input("how are you doing?")
                    tool = worker.tool_reply(
                        [{"name": "ask_name", "accepted": True}],
                        {"npc_name": "Mara Vale"},
                    )
                    capabilities = worker.capabilities()

                manifest_paths = [
                    item["path"] for item in capabilities["moduleManifest"]
                ]
                self.assertIn(
                    "ProjectHoomans:shared:PNC/Translation/"
                    "PNC_TranslationBootstrap.lua",
                    manifest_paths,
                )

                self.assertEqual(len(greeting["messages"]), 2)
                greeting_payloads = [
                    message["payload"] for message in greeting["messages"]
                ]
                self.assertTrue(
                    greeting_payloads[0]["translationKey"].startswith(
                        "UI_PNC_Conversation_Semantic_FlowGreetingOpening"
                    )
                )
                self.assertTrue(
                    greeting_payloads[1]["translationKey"].startswith(
                        "UI_PNC_Conversation_Semantic_FlowGreetingOpeningQuestion"
                    )
                )
                self.assertEqual(
                    greeting["observation"]["translation"]["fallbackCount"],
                    0,
                )
                self.assert_resolved_lookups(
                    self, greeting["translation"]["lookups"]
                )

                identity_payload = identity["messages"][0]["payload"]
                self.assertTrue(
                    identity_payload["translationKey"].startswith(
                        "UI_PNC_Conversation_Semantic_QuestionIdentity"
                    )
                )
                self.assertEqual(
                    identity["translation"]["lookups"][0]["language"],
                    language,
                )
                self.assert_resolved_lookups(
                    self, identity["translation"]["lookups"]
                )

                wellbeing_payload = wellbeing["messages"][0]["payload"]
                self.assertTrue(
                    wellbeing_payload["translationKey"].startswith(
                        "UI_PNC_Conversation_Semantic_QuestionWellbeing"
                    )
                )
                if language == "TL":
                    self.assertNotEqual(
                        wellbeing_payload["text"],
                        wellbeing_payload["fallback"],
                    )
                self.assert_resolved_lookups(
                    self, wellbeing["translation"]["lookups"]
                )

                self.assertEqual(tool["language"], language)
                self.assertIn("Mara Vale", tool["text"])
                self.assert_resolved_lookups(self, tool["translationLookups"])
                self.assertEqual(tool["toolCalls"][0]["status"], "resolved")

                for turn in (greeting, identity, wellbeing):
                    self.assertEqual(turn["transport"], [])
                    self.assertEqual(turn["toolCalls"], [])


if __name__ == "__main__":
    unittest.main()
