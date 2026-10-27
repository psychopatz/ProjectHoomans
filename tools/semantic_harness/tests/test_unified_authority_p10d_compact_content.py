"""P10D acceptance for the compact canonical Dialogue Content source."""

from __future__ import annotations

import json
from pathlib import Path
import unittest

from tools.semantic_harness.codebuilder.dialogue_content import (
    CONTENT_SCHEMA,
    compile_dialogue_content,
    load_dialogue_content_source,
    render_dialogue_content_registry,
    render_dialogue_content_translation,
)


REPOSITORY = Path(__file__).resolve().parents[3]
SOURCE = (
    REPOSITORY
    / "tools/semantic_harness/codebuilder/sources/semantic_dialogue_content.json"
)


class UnifiedAuthorityP10DCompactContentTests(unittest.TestCase):
    def test_source_is_compact_derived_and_free_of_migration_archaeology(self) -> None:
        source = load_dialogue_content_source(SOURCE)
        self.assertEqual(source["schemaVersion"], 2)
        self.assertLess(SOURCE.stat().st_size, 150_000)

        serialized = json.dumps(source, ensure_ascii=False, sort_keys=True)
        for retired in (
            ".migrated.",
            "MIGRATED_",
            "legacySource",
            '"locked"',
            "semanticAuthority",
            '"conditions"',
            '"priority"',
            "responsePoolID",
            "semanticVariantID",
            "translationKeyPrefix",
        ):
            with self.subTest(retired=retired):
                self.assertNotIn(retired, serialized)

        self.assertEqual(
            set(source["groups"]),
            {"events", "tool_replies", "compatibility", "commands_emotes"},
        )
        for family in source["phraseFamilies"]:
            self.assertEqual(set(family), {"semanticTemplateID", "group", "styles"})
            self.assertTrue(family["semanticTemplateID"].startswith("semantic."))
            for phrases in family["styles"].values():
                for phrase in phrases:
                    self.assertEqual(set(phrase), {"translations"})
        for choice in source["playerChoices"]:
            self.assertEqual(
                set(choice),
                {
                    "id",
                    "kind",
                    "route",
                    "hubID",
                    "labelTranslations",
                    "choiceTranslations",
                },
            )

    def test_compiled_runtime_is_v2_and_deterministic_without_legacy_fields(self) -> None:
        source = load_dialogue_content_source(SOURCE)
        first = compile_dialogue_content(source)
        second = compile_dialogue_content(source)
        self.assertEqual(first, second)
        self.assertEqual(first["schema"], CONTENT_SCHEMA)
        self.assertEqual(first["schemaVersion"], 2)

        registry = render_dialogue_content_registry(first)
        self.assertIn('Registry.VERSION = 2', registry)
        for language in ("EN", "TL"):
            self.assertNotIn(".migrated.", render_dialogue_content_translation(first, language))
        for artifact in (registry, json.dumps(first["translations"], ensure_ascii=False)):
            for retired in (".migrated.", "MIGRATED_", "legacySource"):
                self.assertNotIn(retired, artifact)

        family_ids = {family["id"] for family in first["phraseFamilies"]}
        self.assertIn("phrase.semantic.command.player.follow", family_ids)
        self.assertIn("phrase.semantic.emote.player.wavehi", family_ids)
        self.assertIn("phrase.semantic.flow.greeting.opening.default", family_ids)


if __name__ == "__main__":
    unittest.main()
