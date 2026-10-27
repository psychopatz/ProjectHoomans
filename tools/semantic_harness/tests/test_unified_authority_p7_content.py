"""P7 canonical content and production Observatory metadata acceptance."""

from __future__ import annotations

import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.dialogue_content import (
    MAX_FAMILIES,
    compile_dialogue_content,
    load_dialogue_content_source,
)
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[3]
SOURCE = (
    REPOSITORY
    / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json"
)


class UnifiedAuthorityP7ContentTests(unittest.TestCase):
    def test_compact_families_have_stable_content_ownership_and_en_tl_parity(self) -> None:
        compiled = compile_dialogue_content(load_dialogue_content_source(SOURCE))
        self.assertLessEqual(len(compiled["phraseFamilies"]), MAX_FAMILIES)
        self.assertEqual(
            set(compiled["translations"]["EN"]),
            set(compiled["translations"]["TL"]),
        )

        by_template = {
            family["semanticTemplateID"]: family
            for family in compiled["phraseFamilies"]
        }
        expected_owners = {
            "semantic.flow.farewell.default":
            "projecthoomans.dialogue_content.events",
            "semantic.combat.reaction.threat":
            "projecthoomans.dialogue_content.events",
            "semantic.medical.distress.call.default":
            "projecthoomans.dialogue_content.events",
            "semantic.leader_loss.default":
            "projecthoomans.dialogue_content.events",
            "semantic.tool_reply.admire.1":
            "projecthoomans.dialogue_content.tool_replies",
            "semantic.tool_reply.ask_name.named.1":
            "projecthoomans.dialogue_content.tool_replies",
            "semantic.tool_reply.order_camp.1":
            "projecthoomans.dialogue_content.tool_replies",
            "semantic.compat.bandits.hooman_hurt.default":
            "projecthoomans.dialogue_content.compatibility",
            "semantic.compat.projectalife.meta.gunfire":
            "projecthoomans.dialogue_content.compatibility",
            "semantic.compat.companion_dogs.feed.male":
            "projecthoomans.dialogue_content.compatibility",
        }
        for template_id, owner in expected_owners.items():
            with self.subTest(template_id=template_id):
                family = by_template[template_id]
                self.assertEqual(family["contentOwner"], owner)
                phrase = family["styles"]["neutral"][0]
                self.assertTrue(phrase["id"].startswith("phrase."))
                self.assertTrue(phrase["fallback"])
                self.assertIn(phrase["key"], compiled["translations"]["EN"])
                self.assertIn(phrase["key"], compiled["translations"]["TL"])

    def test_authoring_service_exposes_canonical_owner_metadata(self) -> None:
        service = SemanticLabAuthoringService(
            repository=REPOSITORY,
            runtime_root=REPOSITORY,
        )
        rows = {
            row["semanticTemplateID"]: row
            for row in service.list_dialogue_content()
            if row.get("semanticTemplateID")
        }
        self.assertEqual(
            rows["semantic.compat.bandits.hooman_hurt.default"]["contentOwner"],
            "projecthoomans.dialogue_content.compatibility",
        )
        self.assertEqual(
            rows["semantic.leader_loss.default"]["contentOwner"],
            "projecthoomans.dialogue_content.events",
        )
        self.assertIn("sourceFingerprint", rows["semantic.flow.farewell.default"])

    def test_live_response_pool_detail_carries_plan_content_and_event_lineage(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            listing = worker.response_pool_list(filter="semantic.leader_loss", limit=8)
            self.assertTrue(listing["ok"])
            self.assertTrue(listing["pools"])
            self.assertIn(
            "projecthoomans.dialogue_content.events",
                listing["pools"][0]["contentOwners"],
            )
            detail = worker.response_pool_detail("semantic.leader_loss.reaction", limit=16)

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
