"""S2 reusable-block registry contracts over the real production catalog."""

from __future__ import annotations

from pathlib import Path
import unittest

from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[3]


class SemanticBlockRegistryTests(unittest.TestCase):
    def test_static_registry_exposes_all_required_categories_and_contracts(self) -> None:
        service = SemanticLabAuthoringService(repository=REPOSITORY)
        catalog = service.list_semantic_blocks()
        categories = {item["id"] for item in catalog["categories"]}
        self.assertEqual(
            categories,
            {
                "language",
                "conditions",
                "world_facts",
                "context",
                "memory",
                "dialogue_responses",
                "gameplay_actions",
                "quests",
            },
        )
        block_ids = {block["id"] for block in catalog["blocks"]}
        self.assertIn("conditions.gate", block_ids)
        self.assertIn("memory.gossip", block_ids)
        self.assertIn("response:semantic.authored.follow", block_ids)
        self.assertFalse(catalog["productionCatalogLoaded"])

    def test_live_registry_uses_existing_lua_catalog_values(self) -> None:
        service = SemanticLabAuthoringService(repository=REPOSITORY)
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            production_catalog = worker.flow_catalog()

        catalog = service.list_semantic_blocks(production_catalog)
        block_ids = {block["id"] for block in catalog["blocks"]}
        self.assertTrue(catalog["productionCatalogLoaded"])
        self.assertIn("action:pnc:companion.follow", block_ids)
        self.assertIn("quest:pnc:quest.clinic_supplies.accept", block_ids)
        self.assertIn("fact:world.time.week", block_ids)
        self.assertIn("event:engine:zombie_killed", block_ids)
        speech = next(
            block for block in catalog["blocks"] if block["id"] == "language.speech_act"
        )
        self.assertIn("REQUEST", speech["values"])
        action = next(
            block for block in catalog["blocks"]
            if block["id"] == "action:pnc:companion.follow"
        )
        self.assertEqual(action["definition"]["bindingID"], "pnc:companion.follow")

        matches = service.search_semantic_blocks(
            "world.time.week",
            production_catalog=production_catalog,
        )
        self.assertTrue(any(row["id"] == "fact:world.time.week" for row in matches))

    def test_block_selection_validation_is_effect_free_and_fails_closed(self) -> None:
        service = SemanticLabAuthoringService(repository=REPOSITORY)
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            production_catalog = worker.flow_catalog()

        valid = service.validate_semantic_blocks(
            ["conditions.gate", "action:pnc:companion.follow"],
            production_catalog=production_catalog,
        )
        self.assertTrue(valid["valid"], valid)
        self.assertTrue(valid["effectFree"])
        self.assertEqual(valid["writes"], [])

        invalid = service.validate_semantic_blocks(
            ["action:pnc:missing", "action:pnc:missing"],
            production_catalog=production_catalog,
        )
        self.assertFalse(invalid["valid"])
        self.assertEqual(len(invalid["diagnostics"]), 2)
        self.assertEqual(invalid["writes"], [])


if __name__ == "__main__":
    unittest.main()
