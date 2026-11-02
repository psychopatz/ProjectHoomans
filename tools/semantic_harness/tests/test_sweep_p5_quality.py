"""P5 tests for dialogue quality analyzer and canonical-source clustering."""

from __future__ import annotations

import unittest

from tools.semantic_harness.testing.sweep_cluster import (
    CLUSTER_SCHEMA_V1,
    ClusterAggregator,
    DialogueClusterReport,
    DialogueQualityCluster,
)
from tools.semantic_harness.testing.sweep_quality import QualityAnalyzer


class SweepP5QualityTests(unittest.TestCase):
    def setUp(self) -> None:
        self.analyzer = QualityAnalyzer()
        self.aggregator = ClusterAggregator(self.analyzer)

    def test_positive_quality_controls(self) -> None:
        # 1. Empty response
        row_empty = {
            "output": {"finalText": ""},
            "trigger": {},
            "semanticPath": {},
        }
        flags = self.analyzer.analyze_row(row_empty)
        self.assertEqual(len(flags), 1)
        self.assertEqual(flags[0].name, "EMPTY_RESPONSE")
        self.assertEqual(flags[0].severity, "CRITICAL")

        # 2. Placeholder leak
        row_leak = {
            "output": {"finalText": "Welcome back {0}, we survived."},
            "trigger": {},
            "semanticPath": {},
        }
        flags = self.analyzer.analyze_row(row_leak)
        self.assertTrue(any(f.name == "PLACEHOLDER_LEAK" for f in flags))

        # 3. Translation key leak
        row_key = {
            "output": {"finalText": "IGUI_PH_Wellbeing_Weary"},
            "trigger": {},
            "semanticPath": {},
        }
        flags = self.analyzer.analyze_row(row_key)
        self.assertTrue(any(f.name == "TRANSLATION_KEY_LEAK" for f in flags))

        # 4. One-word non-standard response
        row_word = {
            "output": {"finalText": "Greetings."},
            "trigger": {},
            "semanticPath": {},
        }
        flags = self.analyzer.analyze_row(row_word)
        self.assertTrue(any(f.name == "ONE_WORD_RESPONSE" for f in flags))

        # 5. Unsupported family reference (User-observed defect class)
        row_family_defect = {
            "output": {"finalText": "family"},
            "trigger": {
                "relationshipSummary": {"bondKind": "none"},
            },
            "semanticPath": {"semanticTemplateID": "wellbeing.reply"},
        }
        flags = self.analyzer.analyze_row(row_family_defect)
        flag_names = {f.name for f in flags}
        self.assertIn("UNSUPPORTED_FAMILY_REFERENCE", flag_names)
        self.assertIn("ONE_WORD_RESPONSE", flag_names)

        # 6. Relationship term without bond
        row_romantic = {
            "output": {"finalText": "Good to see you, darling."},
            "trigger": {"relationshipSummary": {"bondKind": "friend"}},
            "semanticPath": {},
        }
        flags = self.analyzer.analyze_row(row_romantic)
        self.assertTrue(any(f.name == "RELATIONSHIP_TERM_WITHOUT_BOND" for f in flags))

    def test_negative_quality_controls(self) -> None:
        """Mandatory negative controls: legitimate words/bonds must not be falsely flagged."""
        # Valid conversational short response
        for word in ("Yeah.", "No.", "Sure.", "Right.", "Okay."):
            row = {
                "output": {"finalText": word},
                "trigger": {},
                "semanticPath": {},
            }
            flags = self.analyzer.analyze_row(row)
            self.assertFalse(
                any(f.name == "ONE_WORD_RESPONSE" for f in flags),
                f"Valid short word '{word}' was falsely flagged as ONE_WORD_RESPONSE",
            )

        # Supported family reference with sister bond
        row_supported_sister = {
            "output": {"finalText": "You are my sister, I'll watch your back."},
            "trigger": {
                "relationshipSummary": {"bondKind": "sister", "bondClass": "family"},
            },
            "semanticPath": {},
        }
        flags = self.analyzer.analyze_row(row_supported_sister)
        self.assertFalse(
            any(f.name == "UNSUPPORTED_FAMILY_REFERENCE" for f in flags),
            "Supported family wording with sister bond was falsely flagged",
        )

        # Supported romantic term with lover bond
        row_supported_lover = {
            "output": {"finalText": "Stay safe, darling."},
            "trigger": {
                "relationshipSummary": {"bondKind": "lover", "bondClass": "lover"},
            },
            "semanticPath": {},
        }
        flags = self.analyzer.analyze_row(row_supported_lover)
        self.assertFalse(
            any(f.name == "RELATIONSHIP_TERM_WITHOUT_BOND" for f in flags),
            "Supported romantic wording with lover bond was falsely flagged",
        )

    def test_canonical_source_clustering(self) -> None:
        # 5 rows caused by the same canonical phrase defect
        rows = [
            {
                "identity": {"caseID": f"case_{i}", "language": "EN"},
                "output": {"finalText": "family"},
                "trigger": {
                    "parameters": {"player.hunger": i * 0.2},
                    "relationshipSummary": {"bondKind": "none"},
                },
                "semanticPath": {
                    "semanticTemplateID": "wellbeing.reply",
                    "phraseID": "phrase_defective_family",
                    "semanticVariantID": "var_defective_family",
                },
                "selectionProvenance": {
                    "canonicalSourceOwner": "dialogue_dataset.wellbeing",
                },
                "quality": {},
            }
            for i in range(5)
        ]

        report = self.aggregator.aggregate_rows(rows, sweep_id="test_clustering")
        self.assertEqual(report.schema, CLUSTER_SCHEMA_V1)
        self.assertEqual(report.total_rows, 5)
        self.assertEqual(report.flagged_rows, 5)

        # Find the unsupported family cluster
        fam_clusters = report.filter_by(flag="UNSUPPORTED_FAMILY_REFERENCE")
        self.assertEqual(len(fam_clusters), 1)
        cluster = fam_clusters[0]

        self.assertEqual(cluster.count, 5)
        self.assertEqual(cluster.canonical_source_owner, "dialogue_dataset.wellbeing")
        self.assertEqual(cluster.phrase_id, "phrase_defective_family")
        self.assertEqual(cluster.severity, "CRITICAL")
        self.assertEqual(len(cluster.affected_case_ids), 5)
        self.assertEqual(len(cluster.representative_examples), 5)

        # Verify affected case IDs retrieval
        replayed_cases = report.get_affected_case_ids([cluster.cluster_id])
        self.assertEqual(len(replayed_cases), 5)
        self.assertEqual(replayed_cases, [f"case_{i}" for i in range(5)])


if __name__ == "__main__":
    unittest.main()
