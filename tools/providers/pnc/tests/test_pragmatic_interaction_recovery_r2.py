"""R2 recovery acceptance: behaviors use ordinary Dialogue Content."""

from __future__ import annotations

from copy import deepcopy
import json
from pathlib import Path
import shutil
import tempfile
import unittest

from tools.semantic_harness.codebuilder.conversation_compiler import (
    CONVERSATION_SOURCE_RELATIVE,
    compile_conversation_sources,
    conversation_translation_catalogs_by_owner,
)
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO
from tools.providers.pnc.runtime.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[4]
CORE_REPOSITORY = REPOSITORY.parent / "psychopatzCore"


class PragmaticInteractionRecoveryR2Tests(unittest.TestCase):
    def test_behaviors_reference_dialogue_content_not_response_pools(self) -> None:
        model = compile_conversation_sources(REPOSITORY)
        behaviors = {item["id"]: item for item in model["behaviors"]}
        self.assertEqual(
            behaviors["behavior.warn"]["outputs"]["speech"]["contentTemplateID"],
            "semantic.social.hostile_boundary",
        )
        self.assertEqual(
            behaviors["behavior.retaliate_verbally"]["outputs"]["speech"]["contentTemplateID"],
            "semantic.interaction.argument.retaliate",
        )
        self.assertEqual(
            behaviors["behavior.deescalate"]["outputs"]["speech"]["contentTemplateID"],
            "semantic.interaction.argument.deescalate",
        )
        self.assertEqual(
            behaviors["behavior.challenge"]["outputs"]["speech"]["contentTemplateID"],
            "semantic.interaction.first_contact.challenge",
        )
        for behavior in behaviors.values():
            self.assertNotIn("responsePool", behavior)
            self.assertNotIn("contentTemplateID", behavior)
            self.assertNotIn("dialogueAct", behavior)

        director_pools = [
            item["id"]
            for item in model["dialogue"].get("responsePools", [])
            if str(item.get("id") or "").startswith("semantic.director.")
        ]
        self.assertEqual(director_pools, [])

        templates = {
            item["semanticTemplateID"]
            for item in model["content"]["phraseFamilies"]
        }
        for template in (
            "semantic.interaction.argument.retaliate",
            "semantic.interaction.argument.deescalate",
            "semantic.interaction.first_contact.challenge",
        ):
            self.assertIn(template, templates)

        catalogs = conversation_translation_catalogs_by_owner(model)
        for language in ("EN", "TL"):
            self.assertTrue(
                any(
                    "conversation.content.semantic.interaction.argument.retaliate.neutral.01"
                    in owner_catalogs.get(language, {}).get("Social", {})
                    for owner_catalogs in catalogs.values()
                )
            )

    def test_existing_dialogue_content_authoring_edits_interaction_wording(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            repository = Path(directory)
            shutil.copytree(
                CORE_REPOSITORY / CONVERSATION_SOURCE_RELATIVE,
                repository / CONVERSATION_SOURCE_RELATIVE,
            )
            service = SemanticLabAuthoringService(
                repository,
                runtime_root=repository,
                core_repository=repository,
            )
            content_id = "phrase.semantic.interaction.argument.retaliate"
            current = service.load_dialogue_content(content_id)
            self.assertEqual(
                current["sourceShard"],
                "content/social/interaction/argument/retaliate.json",
            )
            edited = deepcopy(current)
            edited["styles"]["neutral"][0]["translations"]["EN"] = (
                "You are really pushing me now."
            )
            edited["styles"]["neutral"][0]["translations"]["TL"] = (
                "Talagang sinusubok mo ako ngayon."
            )

            preview = service.preview_dialogue_content_edit(
                content_id,
                edited,
                expected_source_fingerprint=current["sourceFingerprint"],
            )
            self.assertTrue(preview["ok"], preview)
            self.assertTrue(preview["structuralLocked"])

            written = service.write_dialogue_content_edit(
                content_id,
                edited,
                expected_source_fingerprint=current["sourceFingerprint"],
            )
            self.assertTrue(written["ok"], written)
            refreshed = service.load_dialogue_content(content_id)
            self.assertEqual(
                refreshed["styles"]["neutral"][0]["translations"]["EN"],
                "You are really pushing me now.",
            )
            self.assertEqual(
                refreshed["styles"]["neutral"][0]["translations"]["TL"],
                "Talagang sinusubok mo ako ngayon.",
            )
            source = json.loads(
                (
                    repository
                    / CONVERSATION_SOURCE_RELATIVE
                    / "content/social/interaction/argument/retaliate.json"
                ).read_text(encoding="utf-8")
            )
            for family in source["phraseFamilies"]:
                for phrases in family["styles"].values():
                    for phrase in phrases:
                        self.assertNotIn("phraseID", phrase)
                        self.assertNotIn("translationKey", phrase)
            self.assertEqual(
                source["phraseFamilies"][0]["styles"]["neutral"][0]["EN"],
                "You are really pushing me now.",
            )
            self.assertFalse(
                (
                    repository
                    / CONVERSATION_SOURCE_RELATIVE
                    / "translations"
                ).exists()
            )
            en = (
                repository
                / "Contents/mods/PsychopatzCore/common/media/translation"
                / "EN/Conversation/Social.json"
            ).read_text(encoding="utf-8")
            tl = (
                repository
                / "Contents/mods/PsychopatzCore/common/media/translation"
                / "TL/Conversation/Social.json"
            ).read_text(encoding="utf-8")
            self.assertIn("You are really pushing me now.", en)
            self.assertIn("Talagang sinusubok mo ako ngayon.", tl)

    def test_real_worker_uses_one_response_authority_and_content_realization(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["personality"] = {
            "aggression": 0.95,
            "confidence": 0.85,
            "forgiveness": 0.8,
        }
        with LuaSemanticWorker(scenario) as worker:
            result = worker.input("fuck ypuuuu")

        decision = result["result"]["decision"]
        interaction = decision["interactionPlan"]
        self.assertEqual(
            interaction["behaviorID"],
            "behavior.retaliate_verbally",
        )
        self.assertEqual(
            interaction["contentTemplateID"],
            "semantic.interaction.argument.retaliate",
        )
        self.assertEqual(
            decision["response"]["sourcePoolID"],
            "semantic.hostile_remark",
        )
        self.assertEqual(
            decision["response"]["plan"]["dialogueAct"],
            "RETALIATE_VERBALLY",
        )
        self.assertEqual(
            decision["response"]["plan"]["turns"][0]["segments"][0]["templateID"],
            "semantic.interaction.argument.retaliate",
        )
        visible = result["observation"]["response"]
        self.assertEqual(
            visible["semanticTemplateID"],
            "semantic.interaction.argument.retaliate",
        )
        self.assertTrue(visible["text"])
        self.assertNotEqual(visible.get("selectionSource"), "director")


if __name__ == "__main__":
    unittest.main()
