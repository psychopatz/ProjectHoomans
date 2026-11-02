"""P6 tests for review bundles, targeted replay, CLI, and Simulation UI."""

from __future__ import annotations

import json
import os
from pathlib import Path
import tempfile
import tkinter as tk
import unittest

from tools.semantic_harness.cli import _parser, cli
from tools.semantic_harness.testing.sweep_cluster import (
    DialogueClusterReport,
    DialogueQualityCluster,
)
from tools.semantic_harness.testing.sweep_dimensions import extract_dimension_inventory
from tools.semantic_harness.testing.sweep_planner import CoveragePlan, CoveragePlanner, PlannedCase
from tools.semantic_harness.testing.sweep_review import (
    REVIEW_BUNDLE_SCHEMA_V1,
    build_llm_review_bundle,
    create_replay_plan,
)
from tools.semantic_harness.testing.sweep_service import DialogueQualitySweepService
from tools.semantic_harness.tests.gui_test_support import SemanticLabGuiTestCase
from tools.semantic_harness.ui.quality_sweep_controller import (
    on_qs_apply_filter,
    on_qs_cancel,
    on_qs_cluster_select,
    on_qs_evidence_select,
    on_qs_plan,
    on_qs_refresh,
)
from tools.semantic_harness.ui.simulation_sweep_controller import (
    on_sweep_cluster_select,
    on_sweep_plan,
    on_sweep_refresh,
)


class SweepP6UiAndReviewTests(SemanticLabGuiTestCase):
    def test_llm_review_bundle_structure_and_boundedness(self) -> None:
        clusters = [
            DialogueQualityCluster(
                cluster_id="cluster:unsupported_family:123",
                primary_flag="UNSUPPORTED_FAMILY_REFERENCE",
                severity="CRITICAL",
                confidence="DEFINITE",
                count=3,
                canonical_source_owner="dialogue_dataset.wellbeing",
                pool_id="wellbeing.reply",
                phrase_id="phrase_family_01",
                affected_case_ids=["case_1", "case_2", "case_3"],
                affected_context_ranges={"bonds": ["none", "friend"]},
                representative_examples=[
                    {
                        "caseID": "case_1",
                        "finalText": "family",
                        "parameters": {},
                        "bondKind": "none",
                        "flagDetail": "Family reference used without bond",
                    }
                ],
                suggested_remedy="Gate family terms behind family bond.",
            )
        ]
        report = DialogueClusterReport(
            sweep_id="test_review",
            total_rows=10,
            flagged_rows=3,
            clean_rows=7,
            total_clusters=1,
            clusters=clusters,
        )

        clean_evidence = [
            {
                "identity": {"caseID": "clean_1"},
                "output": {"finalText": "I'm holding together."},
                "trigger": {"parameters": {}, "relationshipSummary": {"bondKind": "friend"}},
                "semanticPath": {"semanticTemplateID": "wellbeing.reply"},
                "quality": {"flags": []},
            }
        ]

        bundle = build_llm_review_bundle(report, clean_evidence)
        self.assertEqual(bundle["schema"], REVIEW_BUNDLE_SCHEMA_V1)
        self.assertEqual(bundle["totalClusters"], 1)
        self.assertEqual(len(bundle["clusters"]), 1)
        c0 = bundle["clusters"][0]
        self.assertEqual(c0["primaryFlag"], "UNSUPPORTED_FAMILY_REFERENCE")
        self.assertEqual(len(c0["contrastingGoodOutputs"]), 1)
        self.assertEqual(c0["contrastingGoodOutputs"][0]["finalText"], "I'm holding together.")

        # Check serialization size
        encoded = json.dumps(bundle)
        self.assertLess(len(encoded.encode("utf-8")), 8192)

    def test_create_replay_plan(self) -> None:
        cases = [
            PlannedCase(case_id=f"case_{i}", sweep_id="orig", strategy="smoke", surface="s", parameters={})
            for i in range(10)
        ]
        orig_plan = CoveragePlan(
            sweep_id="orig",
            strategy="smoke",
            plan_digest="dig",
            catalog_fingerprint="fp",
            cases=cases,
            total_cases=10,
            estimated_batches=1,
            batch_size=64,
        )

        replay_plan = create_replay_plan(orig_plan, ["case_2", "case_5"])
        self.assertEqual(replay_plan.strategy, "replay")
        self.assertEqual(replay_plan.total_cases, 2)
        replayed_ids = [c.metadata.get("originalCaseID") for c in replay_plan.cases]
        self.assertEqual(replayed_ids, ["case_2", "case_5"])

    def test_cli_argument_parsing(self) -> None:
        parser = _parser()
        args = parser.parse_args(["--sweep-plan", "--sweep-strategy", "boundary", "--sweep-max-cases", "128"])
        self.assertTrue(args.sweep_plan)
        self.assertEqual(args.sweep_strategy, "boundary")
        self.assertEqual(args.sweep_max_cases, 128)

    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_simulation_ui_quality_sweep_tab(self) -> None:
        root = tk.Tk()
        app = self.make_gui_app(root)

        try:
            root.geometry("1080x700")
            app.main_tabs.select(app.simulation_tab)

            # Check that Quality Sweep is present in trace_tabs
            tab_names = [app.trace_tabs.tab(t, "text") for t in app.trace_tabs.tabs()]
            self.assertIn("Quality Sweep", tab_names)

            # Ensure hermetic catalogs for UI planning test
            app.simulation_control_catalog = {
                "controls": [
                    {
                        "id": "runtime.language",
                        "path": "runtime.language",
                        "valueType": "enum",
                        "options": ["EN", "TL"],
                    }
                ]
            }
            app.persona_catalog = {"relationshipKinds": []}

            # Switch to Quality Sweep tab
            app.trace_tabs.select(app.sweep_frame)
            root.update_idletasks()

            # Test Planning from UI
            app.sweep_strategy_var.set("smoke")
            on_sweep_plan(app)
            self.assertIsNotNone(app.current_sweep_plan)
            self.assertIn("Planned", app.sweep_estimate_var.get())

            # Mock report on UI
            mock_clusters = [
                DialogueQualityCluster(
                    cluster_id="cluster:test:01",
                    primary_flag="ONE_WORD_RESPONSE",
                    severity="HIGH",
                    confidence="SUSPECT",
                    count=2,
                    canonical_source_owner="test_source",
                    representative_examples=[
                        {"caseID": "case_1", "finalText": "Huh.", "bondKind": "none"}
                    ],
                )
            ]
            app.current_cluster_report = DialogueClusterReport(
                sweep_id="test",
                total_rows=5,
                flagged_rows=2,
                clean_rows=3,
                total_clusters=1,
                clusters=mock_clusters,
            )

            # Insert cluster into tree and select it
            app.sweep_cluster_tree.insert(
                "", "end", iid="cluster:test:01",
                values=("HIGH", "ONE_WORD_RESPONSE", 2, "test_source", "cluster:test:01")
            )
            app.sweep_cluster_tree.selection_set("cluster:test:01")
            on_sweep_cluster_select(app)

            # Verify details text populated
            details_content = app.sweep_details_text.get("1.0", "end")
            self.assertIn("ONE_WORD_RESPONSE", details_content)
            self.assertIn("Huh.", details_content)

        finally:
            root.destroy()

    @unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
    def test_dedicated_quality_sweep_workbench(self) -> None:
        root = tk.Tk()
        app = self.make_gui_app(root)

        try:
            root.geometry("1200x800")
            main_tab_names = [app.main_tabs.tab(t, "text") for t in app.main_tabs.tabs()]
            self.assertIn("Quality Sweep", main_tab_names)
            app.main_tabs.select(app.quality_sweep_tab)
            root.update_idletasks()

            # Sentence-first controls are the primary workflow.
            self.assertTrue(hasattr(app, "qs_generate_button"))
            self.assertTrue(hasattr(app, "qs_evidence_tree"))
            self.assertTrue(hasattr(app, "qs_inspector_text"))
            self.assertFalse(app.qs_advanced_visible)

            app.simulation_control_catalog = {
                "controls": [
                    {
                        "id": "runtime.language",
                        "path": "runtime.language",
                        "valueType": "enum",
                        "options": ["EN", "TL"],
                    }
                ]
            }
            app.persona_catalog = {"relationshipKinds": []}

            app.quality_sweep_strategy_var.set("smoke")
            on_qs_plan(app)
            self.assertIsNotNone(app.quality_sweep_plan)
            self.assertIn("examples", app.quality_sweep_summary_var.get())
            self.assertIn("triggers", app.quality_sweep_summary_var.get())

            mock_rows = [
                {
                    "rowID": "row_1",
                    "identity": {
                        "caseID": "case_smoke_1",
                        "plannedSurface": "scenario.utterance:hello",
                        "reachedSurface": "semantic.greeting",
                        "surfaceStatus": "MATCHED",
                        "language": "EN",
                        "input": {"text": "hello"},
                    },
                    "trigger": {
                        "parameters": {"relationship.approval": 10},
                        "personaSummary": {
                            "traits": ["pnc_brawler"],
                            "socialStyle": "neutral",
                            "personality": {"aggression": 0.5},
                        },
                        "relationshipSummary": {
                            "bondKind": "none",
                            "approval": 10,
                            "respect": 20,
                        },
                        "stateSummary": {
                            "activeBehavior": "idle",
                            "npcNeeds": {"highest": "thirst", "level": "MINOR"},
                        },
                    },
                    "semanticPath": {
                        "semanticTemplateID": "greeting.reply",
                        "semanticVariantID": "var_default",
                        "phraseID": "phrase_hello_01",
                    },
                    "output": {"finalText": "Hey there."},
                    "selectionProvenance": {
                        "canonicalSourceOwner": "dialogue_dataset.greeting"
                    },
                    "authority": {},
                    "quality": {"flags": []},
                },
                {
                    "rowID": "row_2",
                    "identity": {
                        "caseID": "case_smoke_2",
                        "plannedSurface": "scenario.utterance:wellbeing",
                        "reachedSurface": "semantic.ask_clarification",
                        "surfaceStatus": "INVALID_SURFACE",
                        "language": "EN",
                        "input": {"text": "how are you?"},
                    },
                    "trigger": {
                        "parameters": {},
                        "personaSummary": {},
                        "relationshipSummary": {"bondKind": "none"},
                        "stateSummary": {},
                    },
                    "semanticPath": {
                        "semanticTemplateID": "semantic.ask_clarification",
                        "semanticVariantID": "var_fallback",
                    },
                    "output": {"finalText": "I'm not sure what you mean."},
                    "selectionProvenance": {
                        "canonicalSourceOwner": "core.fallback"
                    },
                    "authority": {},
                    "quality": {
                        "flags": [
                            {
                                "name": "INVALID_SURFACE",
                                "severity": "HIGH",
                                "confidence": "DEFINITE",
                            }
                        ]
                    },
                },
            ]
            app.quality_sweep_evidence_rows = mock_rows
            on_qs_apply_filter(app)
            self.assertEqual(len(app.quality_sweep_filtered_rows), 2)
            self.assertEqual(len(app.qs_evidence_tree.get_children()), 2)

            app.qs_filter_flagged_only_var.set(True)
            on_qs_apply_filter(app)
            self.assertEqual(
                [r["rowID"] for r in app.quality_sweep_filtered_rows],
                ["row_2"],
            )

            app.qs_filter_flagged_only_var.set(False)
            on_qs_apply_filter(app)
            app.qs_evidence_tree.selection_set("row_1")
            on_qs_evidence_select(app)
            inspector_text = app.qs_inspector_text.get("1.0", "end")
            self.assertIn("Hey there.", inspector_text)
            self.assertIn("pnc_brawler", inspector_text)
            self.assertIn("approval", inspector_text.lower())
            self.assertIn("greeting.reply", inspector_text)
            self.assertIn("dialogue_dataset.greeting", inspector_text)
            row_1_vals = app.qs_evidence_tree.item("row_1", "values")
            self.assertEqual(row_1_vals[5], "dialogue_dataset.greeting")
            row_2_vals = app.qs_evidence_tree.item("row_2", "values")
            self.assertEqual(row_2_vals[5], "core.fallback")

            app.quality_sweep_is_running = True
            on_qs_cancel(app)
            self.assertTrue(app.quality_sweep_cancel_requested)
            self.assertIn("Stopping safely", app.quality_sweep_status_var.get())
        finally:
            root.destroy()



if __name__ == "__main__":
    unittest.main()
