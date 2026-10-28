"""Canonical generated-source ownership proven with CodeBuilder and real Lua."""
import unittest
import os
from pathlib import Path
from copy import deepcopy

from tools.semantic_harness.inspection.response_source_lineage import (
    inspect_codebuilder_lineage,
)
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class ObservatoryCodeBuilderLineageTests(unittest.TestCase):
    def test_generated_dialogue_variant_is_verified_but_pool_can_be_mixed(self):
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            report = inspect_codebuilder_lineage(worker, "semantic.accept")
            self.assertTrue(report["ok"])
            self.assertGreater(report["verifiedVariantCount"], 0)
            owned = {item["variantID"]: item for item in report["sourceOwners"]}
            entry = owned["semantic.accept.dataset.pending_started"]
            self.assertTrue(entry["verifiedCanonicalSource"])
            self.assertEqual(entry["canonicalSource"]["sourceID"],
                             "common_dialogue")
            self.assertEqual(entry["canonicalSource"]["generatedArtifactParity"],
                             "unchanged")
            self.assertFalse(owned["semantic.accept.request"]["verifiedCanonicalSource"])
            self.assertFalse(report["fullPoolCanonicalOwnershipVerified"])
            self.assertEqual(report["writes"], 0)

    def test_semantic_definition_and_personal_dataset_have_distinct_sources(self):
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            a = inspect_codebuilder_lineage(worker, "semantic.authored.follow")
            b = inspect_codebuilder_lineage(
                worker, "semantic.question.backstory.ambiguous")
        a_row = next(row for row in a["sourceOwners"] if row["variantID"] == "accepted")
        b_row = next(row for row in b["sourceOwners"]
                     if row["variantID"] ==
                     "semantic.question.backstory.ambiguous.generated")
        self.assertEqual(a_row["canonicalSource"]["sourceID"],
                         "semantic_flows")
        self.assertEqual(b_row["canonicalSource"]["sourceID"],
                         "grounded_personal")
        self.assertEqual(a_row["canonicalSource"]["generatedArtifactParity"],
                         "unchanged")

    def test_falsified_canonical_content_never_becomes_verified_owner(self):
        from tools.semantic_harness.codebuilder.service import (
            SemanticLabAuthoringService,
        )
        service = SemanticLabAuthoringService()
        original = service.load_dataset_document
        def tampered_source(source_id):
            doc = deepcopy(original(source_id))
            if source_id == "common_dialogue":
                variant = next(pool for pool in doc["responsePools"]
                               if pool["id"] == "semantic.accept")["variants"][0]
                variant["fallback"] = "Invented sentence not in actual Lua"
            return doc
        service.load_dataset_document = tampered_source
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            report = inspect_codebuilder_lineage(
                worker, "semantic.accept", authoring_service=service)
        owned = {row["variantID"]: row for row in report["sourceOwners"]}
        self.assertFalse(
            owned["semantic.accept.dataset.pending_started"]["verifiedCanonicalSource"])
        self.assertEqual(report["writes"], 0)

    def test_directly_authored_lua_is_not_misclassified_as_codebuilder_source(self):
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            report = inspect_codebuilder_lineage(
                worker, "semantic.flow.greeting.opening")
        self.assertEqual(report["verifiedVariantCount"], 0)
        self.assertFalse(report["fullPoolCanonicalOwnershipVerified"])
        self.assertTrue(all(row["sourceKind"] == "UNKNOWN"
                            for row in report["sourceOwners"]))


@unittest.skipUnless(os.environ.get("DISPLAY"), "visible Tk needs X11/Xvfb")
class ObservatoryLineageTkTests(unittest.TestCase):
    def test_gui_review_displays_verified_and_unknown_owners(self):
        import tkinter as tk
        from tkinter import ttk
        from tkinter.scrolledtext import ScrolledText
        from tools.semantic_harness.studio.observatory_pane import (
            SemanticObservatoryPane,
        )
        root = tk.Tk()
        root.withdraw()
        try:
            with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
                def synchronous(operation, callback):
                    callback(operation(worker))
                    return True
                pane = SemanticObservatoryPane(
                    root, tk, ttk, ScrolledText, synchronous,
                    repository=Path(__file__).resolve().parents[3])
                pane.selected_pool = "semantic.accept"
                pane.verify_source_lineage()
                report = pane.views["Review"].get("1.0", "end")
                self.assertIn("common_responses.json", report)
                self.assertIn("UNKNOWN", report)
                self.assertIn("approval still required", report)
        finally:
            root.destroy()


if __name__ == "__main__":
    unittest.main()
