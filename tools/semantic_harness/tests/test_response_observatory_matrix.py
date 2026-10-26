"""Grounded multi-language production-Lua Observatory checks."""
from __future__ import annotations

import os
from pathlib import Path
import subprocess
import sys
import tempfile
import json
import unittest

from tools.semantic_harness.inspection.response_observatory import (
    run_quality_matrix, compare_quality_reports, review_variant_proposal,
)


class ResponseQualityMatrixTests(unittest.TestCase):
    def test_greeting_and_companion_actions_en_tl(self):
        result = run_quality_matrix([
            {"label": "EN greeting", "language": "EN",
             "utterance": "hello",
             "expected": {"lastKey": "semantic.flow.greeting.opening.question.default",
                          "maxActions": 0}},
            {"label": "TL greeting", "language": "TL",
             "utterance": "hello",
             "expected": {"lastKey": "semantic.flow.greeting.opening.question.default",
                          "maxActions": 0}},
            {"label": "follow request", "language": "EN",
             "utterance": "follow me",
             "expected": {"minActions": 1, "accepted": True}},
        ])
        self.assertTrue(result["ok"])
        self.assertEqual(result["passed"], 3)
        self.assertFalse(result["truncated"])
        self.assertNotEqual(
            result["cases"][0]["responseTexts"][-1],
            result["cases"][1]["responseTexts"][-1],
        )
        self.assertEqual(result["cases"][2]["transportCount"], 1)

    def test_observation_is_not_falsely_accepted(self):
        result = run_quality_matrix([{"utterance": "goodbye"}])
        self.assertEqual(result["passed"], 0)
        self.assertEqual(result["observedOnly"], 1)
        self.assertEqual(result["cases"][0]["status"], "OBSERVED_ONLY")

    def test_negative_expectation_is_reported_as_failure(self):
        result = run_quality_matrix([
            {"utterance": "hello", "expected": {"minActions": 1}},
        ])
        self.assertFalse(result["ok"])
        self.assertEqual(result["failed"], 1)

    def test_safe_proposal_preflight_never_changes_loaded_pool(self):
        from tools.semantic_harness.runtime.worker import LuaSemanticWorker
        from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            original = worker.response_pool_detail(
                "semantic.flow.greeting.opening", limit=16)
            candidate = {
                "poolID": original["poolID"],
                "expectedContentFingerprint": original["contentFingerprint"],
                "variants": [{
                    "id": "semantic.flow.greeting.opening.default",
                    "EN": "Hi there, friend.", "TL": "Kumusta, kaibigan.",
                }],
            }
            good = review_variant_proposal(worker, candidate)
            self.assertTrue(good["ok"])
            self.assertFalse(good["approved"])
            self.assertEqual(good["writes"], 0)
            self.assertFalse(good["canonicalOwnerVerified"])
            self.assertEqual(
                original["contentFingerprint"],
                worker.response_pool_detail(original["poolID"])["contentFingerprint"],
            )
            candidate["variants"][0]["priority"] = 99
            rejected = review_variant_proposal(worker, candidate)
            self.assertFalse(rejected["ok"])
            self.assertIn("metadata edits forbidden", rejected["errors"][0])
            del candidate["variants"][0]["priority"]
            candidate["expectedContentFingerprint"] = "catalog-v1:0"
            self.assertEqual(review_variant_proposal(worker, candidate)["reason"],
                             "stale_baseline")

    def test_comparison_flags_regressions_and_missing_cases(self):
        row = {
            "label": "Greeting EN", "language": "EN",
            "status": "PASS", "responseKeys": ["a"],
            "responseTexts": ["hi"], "actions": 0,
            "transportCount": 0, "accepted": True,
        }
        base = {
            "type": "response_quality_matrix", "schemaVersion": 1,
            "sourceKind": "FIXTURE", "truncated": False,
            "cases": [row],
        }
        candidate = json.loads(json.dumps(base))
        candidate["cases"][0]["responseTexts"] = ["different"]
        candidate["cases"][0]["status"] = "FAIL"
        compare = compare_quality_reports(base, candidate)
        self.assertFalse(compare["ok"])
        self.assertEqual(len(compare["regressions"]), 1)
        self.assertIn("responseTexts", compare["changes"][0]["diff"])
        candidate["cases"] = []
        self.assertEqual(len(compare_quality_reports(base, candidate)["skipped"]), 1)

    def test_invalid_language_and_large_case_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "language"):
            run_quality_matrix([{"language": "XX"}])
        with self.assertRaisesRegex(ValueError, "utterance"):
            run_quality_matrix([{"utterance": "a" * 201}])

    def test_cli_catalog_and_explain_use_real_lua(self):
        root = Path(__file__).resolve().parents[3]
        base = [sys.executable, "-m", "tools.semantic_harness",
                "--no-gui", "--jsonl"]
        list_response = subprocess.run(
            base + ["--response-pools", "greeting", "--response-limit", "2"],
            cwd=root, capture_output=True, text=True, timeout=20,
        )
        self.assertEqual(list_response.returncode, 0, list_response.stderr)
        catalog = json.loads(list_response.stdout)
        self.assertLessEqual(len(catalog["pools"]), 2)
        self.assertIn("registryRevision", catalog)
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "context.json"
            path.write_text(json.dumps(
                {"worldContext": {"weather": {"raining": True}},
                 "npcID": "obs-cli"}))
            explain = subprocess.run(
                base + ["--explain-response-pool",
                        "semantic.flow.greeting.opening",
                        "--response-context-file", str(path)],
                cwd=root, capture_output=True, text=True, timeout=20,
            )
        self.assertEqual(explain.returncode, 0, explain.stderr)
        self.assertEqual(
            json.loads(explain.stdout)["selectedID"],
            "semantic.flow.greeting.opening.rain",
        )


@unittest.skipUnless(os.environ.get("DISPLAY"), "real Tk needs X11/Xvfb")
class ObservatoryTkTests(unittest.TestCase):
    def test_visible_widgets_against_live_lua_worker(self):
        import tkinter as tk
        from tkinter import ttk
        from tkinter.scrolledtext import ScrolledText
        from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
        from tools.semantic_harness.runtime.worker import LuaSemanticWorker
        from tools.semantic_harness.studio.observatory_pane import (
            SemanticObservatoryPane,
        )

        root = tk.Tk()
        root.withdraw()
        try:
            with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
                def run(operation, callback):
                    callback(operation(worker))
                    return True
                pane = SemanticObservatoryPane(
                    root, tk, ttk, ScrolledText, run)
                pane.filter_var.set("greeting")
                pane.refresh()
                self.assertEqual(len(pane.pools.get_children()), 3)
                pane.pools.selection_set("semantic.flow.greeting.opening")
                pane._selected()
                self.assertIn("semantic.flow.greeting.opening.rain",
                    pane.views["Catalog"].get("1.0", "end"))
                pane.context_var.set("Rainy fixture")
                pane.explain()
                self.assertIn("sole_highest_score",
                    pane.views["Catalog"].get("1.0", "end"))
                pane.test_utterance()
                self.assertIn("Hello. Good to see you.",
                    pane.views["Test Lab"].get("1.0", "end"))
        finally:
            root.destroy()


if __name__ == "__main__":
    unittest.main()
