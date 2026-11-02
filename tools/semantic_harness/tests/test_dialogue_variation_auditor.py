"""Tests for canonical dialogue variation auditor and capacity bounds."""

from __future__ import annotations

import unittest
from pathlib import Path
from copy import deepcopy

from tools.semantic_harness.codebuilder.dialogue_content import (
    MAX_PHRASES_PER_STYLE,
    compile_dialogue_content,
    CompileError,
)
from tools.semantic_harness.codebuilder.variation_auditor import (
    CLASSIFICATION_EXPAND,
    CLASSIFICATION_PLAYER_UI,
    CLASSIFICATION_THIRD_PARTY,
    audit_corpus,
    normalize_exact,
    normalize_near,
    extract_placeholders,
    classify_style,
)


class DialogueVariationCapacityAndAuditorTests(unittest.TestCase):
    def test_phrase_bound_is_sixteen(self) -> None:
        self.assertEqual(MAX_PHRASES_PER_STYLE, 16)

    def test_compiler_accepts_up_to_sixteen_phrases(self) -> None:
        phrases = [
            {"translations": {"EN": f"Phrase {i:02d}", "TL": f"Pangungusap {i:02d}"}}
            for i in range(1, 17)
        ]
        doc = {
            "schemaVersion": 2,
            "source": {
                "name": "Test",
                "version": "1.0",
                "contentLicense": "Test License",
            },
            "groups": {
                "test_group": {"contentOwner": "test.owner"}
            },
            "phraseFamilies": [
                {
                    "semanticTemplateID": "semantic.test.capacity",
                    "group": "test_group",
                    "styles": {"neutral": phrases},
                }
            ],
            "playerChoices": [],
        }
        compiled = compile_dialogue_content(doc)
        self.assertEqual(len(compiled["phraseFamilies"]), 1)
        self.assertEqual(len(compiled["phraseFamilies"][0]["styles"]["neutral"]), 16)

    def test_compiler_rejects_seventeen_phrases(self) -> None:
        phrases = [
            {"translations": {"EN": f"Phrase {i:02d}", "TL": f"Pangungusap {i:02d}"}}
            for i in range(1, 18)
        ]
        doc = {
            "schemaVersion": 2,
            "source": {
                "name": "Test",
                "version": "1.0",
                "contentLicense": "Test License",
            },
            "groups": {
                "test_group": {"contentOwner": "test.owner"}
            },
            "phraseFamilies": [
                {
                    "semanticTemplateID": "semantic.test.capacity_overflow",
                    "group": "test_group",
                    "styles": {"neutral": phrases},
                }
            ],
            "playerChoices": [],
        }
        with self.assertRaises(CompileError) as ctx:
            compile_dialogue_content(doc)
        self.assertIn("exceeds the phrase bound", str(ctx.exception))

    def test_compiler_rejects_empty_phrases(self) -> None:
        doc = {
            "schemaVersion": 2,
            "source": {
                "name": "Test",
                "version": "1.0",
                "contentLicense": "Test License",
            },
            "groups": {
                "test_group": {"contentOwner": "test.owner"}
            },
            "phraseFamilies": [
                {
                    "semanticTemplateID": "semantic.test.capacity_empty",
                    "group": "test_group",
                    "styles": {"neutral": []},
                }
            ],
            "playerChoices": [],
        }
        with self.assertRaises(CompileError) as ctx:
            compile_dialogue_content(doc)
        self.assertIn("requires 1..16 phrases", str(ctx.exception))

    def test_normalization_and_placeholders(self) -> None:
        self.assertEqual(normalize_exact("  Hello,  World!  "), "hello, world!")
        self.assertEqual(normalize_near("Hello, World!"), "hello world")
        self.assertEqual(
            extract_placeholders("Hello {name}, do you have {item}?"),
            ["item", "name"],
        )

    def test_classification_logic(self) -> None:
        cls, _ = classify_style("content/compatibility.json", "semantic.compat.bandits.test", "neutral", [])
        self.assertEqual(cls, CLASSIFICATION_THIRD_PARTY)

        cls, _ = classify_style("content/command/player.json", "semantic.command.player.follow", "neutral", [])
        self.assertEqual(cls, CLASSIFICATION_PLAYER_UI)

        cls, _ = classify_style("content/social/emotes/player.json", "semantic.emote.player.clap", "neutral", [])
        self.assertEqual(cls, CLASSIFICATION_PLAYER_UI)

        cls, _ = classify_style("content/greeting.json", "semantic.flow.greeting.opening.default", "neutral", [])
        self.assertEqual(cls, CLASSIFICATION_EXPAND)

    def test_corpus_audit_matches_audited_baseline(self) -> None:
        report = audit_corpus()
        self.assertEqual(report.total_families, 505)
        self.assertEqual(report.total_styles, 729)
        self.assertLessEqual(report.under_10_count, 729)
        self.assertEqual(report.classification_counts[CLASSIFICATION_EXPAND], 683)
        self.assertEqual(report.classification_counts[CLASSIFICATION_THIRD_PARTY], 27)
        self.assertEqual(report.classification_counts[CLASSIFICATION_PLAYER_UI], 19)
        # 13 greeting styles migrated to 10 phrases
        self.assertGreaterEqual(report.phrase_distribution.get(10, 0), 13)
        self.assertLessEqual(report.eligible_under_10_count, 670)


if __name__ == "__main__":
    unittest.main()
