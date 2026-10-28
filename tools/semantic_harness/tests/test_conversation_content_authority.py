"""Current Conversation content authority and runtime phrase contracts."""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path
import unittest

from tools.semantic_harness.codebuilder.conversation_compiler import (
    compile_conversation_sources,
    render_conversation_registry,
    render_conversation_runtime_plan,
)
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[3]

class ConversationContentAuthorityTests(unittest.TestCase):
    def test_manifest_compiler_is_deterministic_bounded_and_flat(self) -> None:
        first = compile_conversation_sources(REPOSITORY)
        second = compile_conversation_sources(REPOSITORY)
        self.assertEqual(
            first["wholeModelFingerprint"],
            second["wholeModelFingerprint"],
        )
        content = first["content"]
        self.assertGreaterEqual(len(content["phraseFamilies"]), 1)
        self.assertLessEqual(len(content["phraseFamilies"]), 512)
        family = next(
            item for item in content["phraseFamilies"]
            if item["id"] == "phrase.semantic.flow.greeting.opening.default"
        )
        self.assertEqual(
            family["semanticTemplateID"],
            "semantic.flow.greeting.opening.default",
        )
        self.assertTrue(
            all(len(phrases) >= 3 for phrases in family["styles"].values())
        )
        self.assertIn("EN", content["translations"])
        self.assertTrue(
            all(
                isinstance(value, str)
                for values in content["translations"].values()
                for value in values.values()
            )
        )

        _rendered, reports = render_conversation_runtime_plan(first)
        registry = render_conversation_registry(first, reports)
        self.assertIn("function Registry.FamilyFor", registry)
        self.assertIn("function Registry.PlayerChoice", registry)
        self.assertIn("PNC.Semantics.ConversationRegistry", registry)
        self.assertNotIn("DialogueContentRegistry", registry)

    def test_authoring_service_locks_structure_and_allows_content_only_edits(self) -> None:
        service = SemanticLabAuthoringService(repository=REPOSITORY, runtime_root=REPOSITORY)
        family = service.load_dialogue_content("phrase.semantic.flow.greeting.opening.default")
        source_fingerprint = family["sourceFingerprint"]

        unchanged = service.preview_dialogue_content_edit(
            family["id"], family, expected_source_fingerprint=source_fingerprint
        )
        self.assertTrue(unchanged["ok"])
        self.assertTrue(unchanged["structuralLocked"])
        self.assertEqual(unchanged["writes"], [])

        phrase_edit = deepcopy(family)
        phrase_edit["styles"]["neutral"][0]["translations"]["EN"] = (
            "Hey there. Great to see you."
        )
        edited = service.preview_dialogue_content_edit(
            phrase_edit["id"],
            phrase_edit,
            expected_source_fingerprint=source_fingerprint,
        )
        self.assertTrue(edited["ok"])
        self.assertTrue(edited["structuralLocked"])
        self.assertNotEqual(edited["contentFingerprint"], unchanged["contentFingerprint"])

        structural_edit = deepcopy(family)
        structural_edit["semanticTemplateID"] = "semantic.flow.not_allowed"
        rejected = service.preview_dialogue_content_edit(
            structural_edit["id"],
            structural_edit,
            expected_source_fingerprint=source_fingerprint,
        )
        self.assertFalse(rejected["ok"])
        self.assertTrue(rejected["structuralChange"])

        stale = service.preview_dialogue_content_edit(
            family["id"], family, expected_source_fingerprint="0" * 64
        )
        self.assertFalse(stale["ok"])
        self.assertTrue(stale["stale"])

        choice = service.load_dialogue_content("conversation.landing:whats_up")
        choice_edit = deepcopy(choice)
        # The choice wording can be reviewed independently while its normal
        # landing label remains stable by default.
        choice_edit["choiceTranslations"]["EN"] = "What is up?"
        choice_report = service.preview_dialogue_content_edit(
            choice["id"],
            choice_edit,
            expected_source_fingerprint=choice["sourceFingerprint"],
        )
        self.assertTrue(choice_report["ok"])
        self.assertTrue(choice_report["structuralLocked"])
        self.assertEqual(choice["labelTranslations"]["EN"], "What's up")
        self.assertEqual(choice["route"], "semantic_hub")
        self.assertEqual(choice["hubID"], "whats_up")
        self.assertEqual(choice["canonicalConcept"], "CONVERSATION_LANDING_WHATS_UP")

    def test_real_lua_phrase_layer_is_separate_and_effect_equivalent(self) -> None:
        all_rows: dict[str, list[dict]] = {}
        for language, canonical_text in (
            ("EN", "Hey there. Good to see you."),
            ("TL", "Uy, mabuti at nakita kita."),
        ):
            scenario = deepcopy(DEFAULT_SCENARIO)
            scenario["runtime"]["language"] = language
            with LuaSemanticWorker(scenario) as worker:
                rows = [worker.input("hello") for _ in range(5)]
                all_rows[language] = rows

            responses = [row["observation"]["response"] for row in rows]
            phrase_ids = [response["phraseID"] for response in responses]
            self.assertEqual(responses[0]["text"], canonical_text)
            self.assertEqual(len(set(phrase_ids)), 3)
            self.assertTrue(all(left != right for left, right in zip(phrase_ids, phrase_ids[1:])))
            self.assertEqual(
                [response["semanticVariantID"] for response in responses],
                ["semantic.flow.greeting.opening.default"] * 5,
            )
            self.assertEqual(
                [response["speechStyleVariant"] for response in responses],
                ["neutral"] * 5,
            )
            self.assertTrue(
                all(
                    response["phraseSelection"]["phraseID"] == response["phraseID"]
                    and response["phraseSelection"]["familyID"]
                    == "phrase.semantic.flow.greeting.opening.default"
                    and response["phraseSelection"]["style"] == "neutral"
                    for response in responses
                )
            )
            self.assertEqual(responses[0]["phraseAntiRepeatReason"], "initial_canonical")
            self.assertIn(
                "immediate_repeat_avoided",
                {response["phraseAntiRepeatReason"] for response in responses[1:]},
            )

            # The bounded phrase layer changes presentation only: greeting
            # routing, authority/effects, transport, and tools remain stable.
            for row in rows:
                self.assertEqual(row["result"]["ir"]["intent"], "GREET")
                self.assertIsNone(row["result"].get("actionResult"))
                self.assertEqual(row["transport"], [])
                self.assertEqual(row["toolCalls"], [])
                self.assertTrue(row["observation"]["sideEffects"]["none"])

        # The hash selection is deterministic for the same actor/family/style,
        # including across isolated worker processes.
        scenario = deepcopy(DEFAULT_SCENARIO)
        with LuaSemanticWorker(scenario) as first_worker:
            first_ids = [
                first_worker.input("hello")["observation"]["response"]["phraseID"]
                for _ in range(5)
            ]
        with LuaSemanticWorker(scenario) as second_worker:
            second_ids = [
                second_worker.input("hello")["observation"]["response"]["phraseID"]
                for _ in range(5)
            ]
        self.assertEqual(first_ids, second_ids)

    def test_player_choice_registry_preserves_landing_route_and_stable_label(self) -> None:
        expected = {
            "EN": ("What's up?", "What's up"),
            "TL": ("Ano ang balita?", "Ano ang balita"),
        }
        for language, (label_fallback, landing_label) in expected.items():
            scenario = deepcopy(DEFAULT_SCENARIO)
            scenario["runtime"]["language"] = language
            with LuaSemanticWorker(scenario) as worker:
                candidate = next(
                    item
                    for item in worker.snapshot()["suggestions"]["candidates"]
                    if item["id"] == "conversation.landing:whats_up"
                )
            frame = candidate["frame"]
            self.assertEqual(
                frame["labelKey"],
                "UI_PNC_Conversation_Content_ConversationLandingWhatsUpChoice",
            )
            self.assertEqual(frame["labelFallback"], label_fallback)
            self.assertEqual(frame["textFallback"], "What's up?")
            self.assertEqual(frame["extensions"]["route"], "semantic_hub")
            self.assertEqual(frame["extensions"]["hubID"], "whats_up")
            self.assertEqual(frame["extensions"]["canonicalConcept"], "WHATS_UP")
            self.assertEqual(candidate["id"], "conversation.landing:whats_up")
            self.assertEqual(landing_label, expected[language][1])


    def test_live_response_pool_detail_carries_plan_content_and_event_lineage(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            listing = worker.response_pool_list(
                filter="semantic.leader_loss",
                limit=8,
            )
            self.assertTrue(listing["ok"])
            self.assertTrue(listing["pools"])
            self.assertIn(
                "projecthoomans.dialogue_content.events",
                listing["pools"][0]["contentOwners"],
            )
            detail = worker.response_pool_detail(
                "semantic.leader_loss.reaction",
                limit=16,
            )

        self.assertTrue(detail["ok"])
        self.assertEqual(detail["variantCount"], 6)
        for variant in detail["variants"]:
            with self.subTest(variant=variant["id"]):
                self.assertEqual(
                    variant["contentOwner"],
                    "projecthoomans.dialogue_content.events",
                )
                self.assertEqual(
                    variant["provenance"]["selectionSource"],
                    "production_lua_response_catalog",
                )
                self.assertEqual(
                    variant["provenance"]["realizationID"],
                    variant["id"],
                )
                self.assertIn("responsePlan", variant)
                self.assertIn("followUpOffers", variant)
                self.assertIn("factRefs", variant["provenance"])



if __name__ == "__main__":
    unittest.main()
