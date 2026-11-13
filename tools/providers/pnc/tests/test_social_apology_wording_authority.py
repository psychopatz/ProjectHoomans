"""Social Apology wording-shard migration contracts."""

from __future__ import annotations

import json
from pathlib import Path
import unittest

from tools.semantic_harness.codebuilder.conversation_compiler import (
    compile_conversation_sources,
)
from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.providers.pnc.runtime.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[4]
CORE_REPOSITORY = REPOSITORY.parent / "psychopatzCore"
MANIFEST = (
    CORE_REPOSITORY
    / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json"
)
APOLOGY_IDS = (
    "semantic.social.apology.default",
    "semantic.social.apology.friendly",
    "semantic.social.apology.stressed",
    "semantic.social.apology.withdrawn",
)
STYLES = ("neutral", "warm", "terse", "guarded")
TRANSLATIONS = {
    "EN": {
        "default": {
            "neutral": "What are you apologizing for?",
            "warm": "What are you apologizing for?",
            "terse": "What are you apologizing for?",
            "guarded": "What are you apologizing for?"
        },
        "friendly": {
            "neutral": "It's okay. We can put that behind us.",
            "warm": "It's okay. I appreciate you saying that.",
            "terse": "It's okay.",
            "guarded": "I heard you. Leave it there."
        },
        "stressed": {
            "neutral": "I know things are tense. Let's keep it calm.",
            "warm": "I know things are tense. Thanks for saying that.",
            "terse": "Keep it calm.",
            "guarded": "Things are tense. Leave it there."
        },
        "withdrawn": {
            "neutral": "All right. Let's leave it there.",
            "warm": "All right. Let's leave it there for now.",
            "terse": "Leave it.",
            "guarded": "All right. Leave it there."
        }
    },
    "TL": {
        "default": {
            "neutral": "Ano ang hinihingi mo ng tawad?",
            "warm": "Ano ang hinihingi mo ng tawad?",
            "terse": "Ano ang hinihingi mo ng tawad?",
            "guarded": "Ano ang hinihingi mo ng tawad?"
        },
        "friendly": {
            "neutral": "Ayos lang. Kalimutan na natin iyon.",
            "warm": "Ayos lang. Pinahahalagahan ko ang sinabi mo.",
            "terse": "Ayos lang.",
            "guarded": "Narinig kita. Tama na."
        },
        "stressed": {
            "neutral": "Alam kong tensiyonado tayo. Panatilihin nating mahinahon.",
            "warm": "Alam kong tensiyonado tayo. Salamat sa pagsabi niyan.",
            "terse": "Maging mahinahon.",
            "guarded": "Tensiyonado tayo. Tama na iyon."
        },
        "withdrawn": {
            "neutral": "Sige. Tama na iyon.",
            "warm": "Sige. Tama na muna iyon.",
            "terse": "Tama na.",
            "guarded": "Sige. Tama na iyon."
        }
    }
}
RETIRED_KEYS = {
    f"UI_PNC_Conversation_Semantic_Apology{name}"
    for name in ("Default", "Friendly", "Stressed", "Withdrawn")
}
RETIRED_KEYS.update(
    f"UI_PNC_Conversation_Semantic_RealizationApology{family}{style}"
    for family in ("", "Friendly", "Stressed", "Withdrawn")
    for style in ("Neutral", "Warm", "Terse", "Guarded")
)


class SocialApologyWordingShardTests(unittest.TestCase):
    def test_apology_without_an_antecedent_requests_context_without_dispatch(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            turn = worker.input("sorry")
        self.assertTrue(turn["accepted"])
        self.assertEqual(turn["result"]["ir"]["intent"], "APOLOGIZE")
        self.assertEqual(
            turn["result"]["decision"]["response"]["templateID"],
            "semantic.interaction.context.clarify",
        )
        self.assertEqual(turn["dispatchTransport"], [])
        self.assertEqual(turn["toolCalls"], [])
        self.assertEqual(turn["relationshipBefore"], turn["relationshipAfter"])
        self.assertEqual(turn["llmCalls"], 0)

    def test_compiler_owns_fixed_apology_families_by_apology_shard(self) -> None:
        model = compile_conversation_sources(
            REPOSITORY,
            manifest_path=MANIFEST,
        )
        plans = [
            item
            for item in model["psdlRuntimePlans"]
            if item.get("payload", {})
            .get("metadata", {})
            .get("responseTemplateID") in APOLOGY_IDS
        ]
        self.assertEqual(len(plans), len(APOLOGY_IDS) * len(STYLES))
        for plan in plans:
            payload = plan["payload"]
            metadata = payload["metadata"]
            self.assertEqual(plan["domain"], "social_apology")
            self.assertTrue(
                plan["sourceShard"].startswith("adopters/hoomans/dialogue/social_apology/"),
                plan["sourceShard"],
            )
            self.assertIn(metadata["responseTemplateID"], APOLOGY_IDS)
            self.assertIn(metadata["style"], STYLES)
            variants = payload["response"]["variants"]
            self.assertEqual(len(variants), 10)
            self.assertTrue(all(set(item["text"]) == {"EN", "TL"} for item in variants))

    def test_generated_apology_psdl_source_is_complete_and_legacy_fixed_keys_retired(
        self,
    ) -> None:
        source_dir = (
            REPOSITORY
            / "tools/providers/pnc/codebuilder/sources/conversation/dialogue/social_apology"
        )
        files = sorted(source_dir.glob("*.json"))
        self.assertEqual(len(files), len(APOLOGY_IDS))
        records = [
            record
            for path in files
            for record in json.loads(path.read_text(encoding="utf-8")).get("records", [])
        ]
        self.assertEqual(len(records), len(APOLOGY_IDS) * len(STYLES))
        for record in records:
            self.assertEqual(record["owner"], "ProjectHoomans")
            self.assertEqual(record["metadata"]["sourceSurface"], "content/social_apology.json")
            self.assertEqual(record["metadata"]["responseTemplateID"] in APOLOGY_IDS, True)
            self.assertIn(record["metadata"]["style"], STYLES)
            self.assertEqual(len(record["response"]["variants"]), 10)
            for variant in record["response"]["variants"]:
                self.assertEqual(set(variant["text"]), {"EN", "TL"})
                self.assertTrue(all(variant["text"][language] for language in ("EN", "TL")))
        for language in ("EN", "TL"):
            self.assertFalse(
                (
                    REPOSITORY
                    / "Contents/mods/ProjectHoomans/common/media/translation/"
                    f"{language}/Conversation/Apology.json"
                ).exists()
            )
            for catalog_name in ("Responses", "Realizations"):
                catalog = json.loads(
                    (
                        REPOSITORY
                        / "Contents/mods/ProjectHoomans/common/media/translation/"
                        f"{language}/Conversation/Semantic/{catalog_name}.json"
                    ).read_text(encoding="utf-8")
                )
                self.assertTrue(RETIRED_KEYS.isdisjoint(catalog))
                if catalog_name == "Responses":
                    self.assertIn(
                        "UI_PNC_Conversation_Semantic_ApologyTrusted",
                        catalog,
                    )

        static_map = (
            REPOSITORY
            / "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/"
            "Semantics/PNC_SemanticDialogueInput_Presentation_Responses_"
            "Translation_Keys_Social.lua"
        ).read_text(encoding="utf-8")
        social_families = (
            REPOSITORY
            / "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/"
            "Semantics/SpeechRealization/Families/Social.lua"
        ).read_text(encoding="utf-8")
        self.assertTrue(RETIRED_KEYS.isdisjoint(static_map))
        self.assertIn("semantic.social.apology.trusted", static_map)
        for apology_id in APOLOGY_IDS:
            self.assertNotIn(apology_id, social_families)

    def test_real_worker_preserves_apology_identity_and_no_effects_in_en_tl(
        self,
    ) -> None:
        cases = (
            (
                "default",
                {"personality": {"socialStyle": "neutral"}},
                "neutral",
                "neutral",
            ),
            ("friendly", {"traits": {"friendly": True}}, "friendly", "warm"),
            (
                "stressed",
                {
                    "traits": {"reserved": True},
                    "conditionStats": {"stress": 95},
                    "personality": {"socialStyle": "neutral"},
                },
                "neutral",
                "neutral",
            ),
            (
                "withdrawn",
                {
                    "traits": {"reserved": True},
                    "personality": {"socialStyle": "withdrawn"},
                },
                "withdrawn",
                "terse",
            ),
        )
        for language in TRANSLATIONS:
            for family, npc, social_style, _style in cases:
                with self.subTest(language=language, family=family):
                    scenario = merge(
                        DEFAULT_SCENARIO,
                        {"runtime": {"language": language}, "npc": npc},
                    )
                    with LuaSemanticWorker(scenario) as worker:
                        # An apology must refer to an accepted prior offense;
                        # the current relation resolver never invents one.
                        worker.input("You're an idiot")
                        turn = worker.input("sorry")
                    response = turn["result"]["decision"]["response"]
                    payload = turn["messages"][0]["payload"]
                    self.assertTrue(turn["accepted"], turn.get("reason"))
                    self.assertEqual(turn["result"]["ir"]["intent"], "APOLOGIZE")
                    self.assertEqual(
                        turn["result"]["decision"]["branch"],
                        "SOCIAL_ACKNOWLEDGED",
                    )
                    self.assertEqual(
                        response["selectionID"],
                        f"semantic.apology.{family}",
                    )
                    self.assertEqual(response["sourcePoolID"], "semantic.apology")
                    # The catalog still selects the personality/emotion family.
                    # The admitted reconciliation behavior owns the final speech
                    # plan; current utterance construction realizes its meaning.
                    self.assertEqual(response["templateID"], "semantic.social.apology.friendly")
                    self.assertEqual(payload["semanticTemplateID"], response["templateID"])
                    realization = payload["utteranceRealization"]
                    self.assertEqual(realization["locale"], language)
                    self.assertEqual(
                        realization["constructionID"],
                        f"construction.{language.lower()}.social.acknowledge",
                    )
                    self.assertEqual(
                        payload["text"],
                        {"EN": "I hear you.", "TL": "Naiintindihan ko."}[language],
                    )
                    self.assertEqual(
                        turn["routedSituation"]["social"]["style"],
                        social_style,
                    )
                    self.assertEqual(turn["llmCalls"], 0)
                    self.assertEqual(turn["dispatchTransport"], [])
                    self.assertEqual(turn["toolCalls"], [])
                    self.assertIsNone(turn["result"].get("actionResult"))
                    self.assertEqual(turn["relationshipBefore"], turn["relationshipAfter"])


if __name__ == "__main__":
    unittest.main()
