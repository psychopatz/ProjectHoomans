"""Real registered Lua pools joined only to canonical manifest ownership."""
from __future__ import annotations
import os
import unittest
from tools.semantic_harness.inspection.response_translation_coverage import translation_coverage
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class TranslationManifestTests(unittest.TestCase):
    def test_generated_key_has_one_owner_in_every_manifest_locale(self):
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            report = translation_coverage(worker, "semantic.question.backstory.ambiguous")
        self.assertTrue(report["ok"])
        self.assertEqual(report["summary"]["ALL_MANIFESTED"], 1)
        row = report["variants"][0]
        self.assertEqual(row["status"], "ALL_MANIFESTED")
        self.assertEqual(report["languages"], ["EN", "TL"])
        for language in report["languages"]:
            self.assertEqual(len(row["manifestAssets"][language]), 1)
        self.assertEqual(row["missingLocales"], [])
        self.assertEqual(row["fallbackEvidence"], "UNTESTED")
        self.assertFalse(row["actualRuntimeLookupObserved"])
        self.assertEqual(report["writes"], 0)

    def test_authored_fallback_pool_is_not_falsely_claimed_untranslated(self):
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            report = translation_coverage(worker, "semantic.flow.greeting.opening")
            self.assertEqual(report["variantCount"], 3)
            self.assertEqual(
                report["summary"]["NOT_IN_CONVERSATION_MANIFEST"], 3)
            self.assertEqual(report["registryRevision"],
                             worker.response_pool_detail(
                                 "semantic.flow.greeting.opening")["registryRevision"])
        self.assertIn("not a runtime translation", " ".join(report["limitations"]))

    def test_unknown_pool_remains_error(self):
        from tools.semantic_harness.runtime.process import HarnessError
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            with self.assertRaises(HarnessError):
                translation_coverage(worker, "not.a.real.registered.pool")


@unittest.skipUnless(os.environ.get("DISPLAY"), "visible Tk needs Xvfb")
class TranslationManifestTkTests(unittest.TestCase):
    def test_studio_uses_same_read_only_translation_service(self):
        import tkinter as tk
        from tkinter import ttk
        from tkinter.scrolledtext import ScrolledText
        from tools.semantic_harness.studio.observatory_pane import SemanticObservatoryPane
        root = tk.Tk()
        root.withdraw()
        try:
            with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
                def run(operation, callback):
                    callback(operation(worker))
                    return True
                pane = SemanticObservatoryPane(root, tk, ttk, ScrolledText, run)
                pane.selected_pool = "semantic.question.backstory.ambiguous"
                pane.verify_translation_manifest()
                text = pane.views["Review"].get("1.0", "end")
                self.assertIn("ALL_MANIFESTED", text)
                self.assertIn("Static manifest membership", text)
                self.assertIn("TL/Conversation/Patterns.json", text)
        finally:
            root.destroy()


if __name__ == "__main__":
    unittest.main()
