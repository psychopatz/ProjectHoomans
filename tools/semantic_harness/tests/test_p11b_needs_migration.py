"""P11B Needs wording-shard migration contracts."""

from __future__ import annotations

from copy import deepcopy
import json
from pathlib import Path
import unittest

from tools.semantic_harness.codebuilder.conversation_compiler import (
    compile_conversation_sources,
)
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[3]
MANIFEST = (
    REPOSITORY
    / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json"
)
NEEDS_IDS = (
    "semantic.question.needs.offer.hunger",
    "semantic.question.needs.offer.thirst",
    "semantic.question.needs.offer.fatigue",
    "semantic.question.needs.offer.unknown",
    "semantic.question.needs.quantity.hunger",
    "semantic.question.needs.quantity.thirst",
    "semantic.question.needs.quantity.unknown",
    "semantic.question.needs.proposal.hunger",
    "semantic.question.needs.proposal.thirst",
    "semantic.question.needs.proposal.unknown",
)
EXPECTED = {
    "EN": {
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsOfferFatigueNeutral01":
            "A little rest would help, but this isn't something I can count.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsOfferHungerGuarded01":
            "I need food. Keep your distance.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsOfferHungerNeutral01":
            "Food would help, but I don't have an exact amount yet.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsOfferHungerTerse01":
            "I need food.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsOfferHungerWarm01":
            "Food would help, if you can spare it.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsOfferThirstNeutral01":
            "Water would help, but I don't have an exact amount yet.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsOfferUnknownNeutral01":
            "I don't know what I need right now.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsProposalHungerNeutral01":
            "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsProposalThirstNeutral01":
            "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsProposalUnknownNeutral01":
            "I can keep that as a proposal, but I need to confirm the item and amount before I record a commitment.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsQuantityHungerNeutral01":
            "I know food is what I need, but I can't give you an exact amount yet.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsQuantityThirstNeutral01":
            "I know water is what I need, but I can't give you an exact amount yet.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsQuantityUnknownNeutral01":
            "I can't confirm an exact amount yet. Which item do you mean?",
    },
    "TL": {
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsOfferFatigueNeutral01":
            "Makakatulong ang kaunting pahinga, pero hindi ito mabibilang.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsOfferHungerGuarded01":
            "Kailangan ko ng pagkain. Lumayo ka.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsOfferHungerNeutral01":
            "Makakatulong ang pagkain, pero wala akong eksaktong dami ngayon.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsOfferHungerTerse01":
            "Kailangan ko ng pagkain.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsOfferHungerWarm01":
            "Makakatulong ang pagkain, kung may maibibigay ka.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsOfferThirstNeutral01":
            "Makakatulong ang tubig, pero wala akong eksaktong dami ngayon.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsOfferUnknownNeutral01":
            "Hindi ko alam kung ano ang kailangan ko ngayon.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsProposalHungerNeutral01":
            "Ituturing ko muna itong panukala, pero kailangan ko pa ang gamit at dami bago ako magtala ng pangako.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsProposalThirstNeutral01":
            "Ituturing ko muna itong panukala, pero kailangan ko pa ang gamit at dami bago ako magtala ng pangako.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsProposalUnknownNeutral01":
            "Ituturing ko muna itong panukala, pero kailangan ko munang tiyakin ang gamit at dami bago ako magtala ng pangako.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsQuantityHungerNeutral01":
            "Alam kong pagkain ang kailangan ko, pero hindi ko pa masabi ang eksaktong dami.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsQuantityThirstNeutral01":
            "Alam kong tubig ang kailangan ko, pero hindi ko pa masabi ang eksaktong dami.",
        "UI_PNC_Conversation_Content_SemanticQuestionNeedsQuantityUnknownNeutral01":
            "Hindi ko makumpirma ang eksaktong dami. Anong gamit ang tinutukoy mo?",
    },
}
LEGACY_KEYS = {
    "UI_PNC_Conversation_Semantic_QuestionNeedsOfferHunger",
    "UI_PNC_Conversation_Semantic_QuestionNeedsOfferThirst",
    "UI_PNC_Conversation_Semantic_QuestionNeedsOfferFatigue",
    "UI_PNC_Conversation_Semantic_QuestionNeedsOfferUnknown",
    "UI_PNC_Conversation_Semantic_QuestionNeedsQuantityHunger",
    "UI_PNC_Conversation_Semantic_QuestionNeedsQuantityThirst",
    "UI_PNC_Conversation_Semantic_QuestionNeedsQuantityUnknown",
    "UI_PNC_Conversation_Semantic_QuestionNeedsProposalHunger",
    "UI_PNC_Conversation_Semantic_QuestionNeedsProposalThirst",
    "UI_PNC_Conversation_Semantic_QuestionNeedsProposalUnknown",
    "UI_PNC_Conversation_Semantic_RealizationNeedsHungerNeutral",
    "UI_PNC_Conversation_Semantic_RealizationNeedsHungerWarm",
    "UI_PNC_Conversation_Semantic_RealizationNeedsHungerTerse",
    "UI_PNC_Conversation_Semantic_RealizationNeedsHungerGuarded",
}


class NeedsWordingShardTests(unittest.TestCase):
    def test_compiler_owns_needs_families_by_needs_shard(self) -> None:
        model = compile_conversation_sources(
            REPOSITORY, manifest_path=MANIFEST,
        )
        entry = next(
            shard for shard in model["shards"]
            if shard["path"] == "content/needs.json"
        )
        self.assertEqual(entry["domain"], "needs")
        self.assertEqual(
            {
                model["locations"]["phrase." + template_id]["sourceShard"]
                for template_id in NEEDS_IDS
            },
            {"content/needs.json"},
        )
        self.assertEqual(
            [
                family["semanticTemplateID"]
                for family in model["content"]["phraseFamilies"]
                if family["semanticTemplateID"] in NEEDS_IDS
            ],
            sorted(NEEDS_IDS),
        )

    def test_generated_needs_translation_is_complete_and_legacy_keys_are_retired(
        self,
    ) -> None:
        for language, expected in EXPECTED.items():
            with self.subTest(language=language):
                generated = json.loads(
                    (
                        REPOSITORY
                        / f"Contents/mods/ProjectHoomans/common/media/translation/"
                        f"{language}/Conversation/Needs.json"
                    ).read_text(encoding="utf-8")
                )
                self.assertEqual(generated, expected)
                for catalog_name in ("Responses", "Realizations"):
                    catalog = json.loads(
                        (
                            REPOSITORY
                            / f"Contents/mods/ProjectHoomans/common/media/translation/"
                            f"{language}/Conversation/Semantic/{catalog_name}.json"
                        ).read_text(encoding="utf-8")
                    )
                    self.assertTrue(LEGACY_KEYS.isdisjoint(catalog))

        status_source = (
            REPOSITORY
            / "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/"
            "SpeechRealization/Families/Status.lua"
        ).read_text(encoding="utf-8")
        self.assertNotIn("NeedsHunger", status_source)
        key_map = (
            REPOSITORY
            / "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Semantics/"
            "PNC_SemanticDialogueInput_Presentation_Responses_Translation_Keys_Question_Needs.lua"
        ).read_text(encoding="utf-8")
        for template_id in NEEDS_IDS:
            self.assertNotIn(template_id, key_map)

    def test_real_worker_preserves_needs_identity_and_no_effects_in_en_tl(
        self,
    ) -> None:
        expected = {
            "EN": (
                "UI_PNC_Conversation_Content_SemanticQuestionNeedsOfferHungerNeutral01",
                "Food would help, but I don't have an exact amount yet.",
                "UI_PNC_Conversation_Content_SemanticQuestionNeedsQuantityHungerNeutral01",
                "I know food is what I need, but I can't give you an exact amount yet.",
                "UI_PNC_Conversation_Content_SemanticQuestionNeedsProposalHungerNeutral01",
                "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
            ),
            "TL": (
                "UI_PNC_Conversation_Content_SemanticQuestionNeedsOfferHungerNeutral01",
                "Makakatulong ang pagkain, pero wala akong eksaktong dami ngayon.",
                "UI_PNC_Conversation_Content_SemanticQuestionNeedsQuantityHungerNeutral01",
                "Alam kong pagkain ang kailangan ko, pero hindi ko pa masabi ang eksaktong dami.",
                "UI_PNC_Conversation_Content_SemanticQuestionNeedsProposalHungerNeutral01",
                "Ituturing ko muna itong panukala, pero kailangan ko pa ang gamit at dami bago ako magtala ng pangako.",
            ),
        }
        scenario_base = merge(
            DEFAULT_SCENARIO,
            {
                "npc": {
                    "healthState": "injured",
                    "needs": {"hunger": 0.9},
                    "conditionStats": {},
                },
            },
        )
        for language, contract in expected.items():
            with self.subTest(language=language):
                scenario = deepcopy(scenario_base)
                scenario["runtime"]["language"] = language
                with LuaSemanticWorker(scenario) as worker:
                    turns = [
                        worker.input("Do you need anything?"),
                        worker.input("How many?"),
                        worker.input("I'll get some"),
                    ]
                for index, turn in enumerate(turns):
                    self.assertTrue(turn["accepted"], turn.get("reason"))
                    payload = turn["messages"][0]["payload"]
                    self.assertEqual(payload["semanticTemplateID"], (
                        NEEDS_IDS[index * 3]
                        if index == 0 else
                        NEEDS_IDS[4] if index == 1 else NEEDS_IDS[7]
                    ))
                    self.assertEqual(payload["translationKey"], contract[index * 2])
                    self.assertEqual(payload["text"], contract[index * 2 + 1])
                    self.assertEqual(turn["dispatchTransport"], [])
                    self.assertEqual(turn["toolCalls"], [])
                    self.assertTrue(turn["observation"]["sideEffects"]["noGameplayEffects"])


if __name__ == "__main__":
    unittest.main()
