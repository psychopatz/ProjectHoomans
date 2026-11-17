"""GUI ownership contracts for the consolidated Semantic Lab surfaces."""

from __future__ import annotations

import json
import os
from pathlib import Path
import time
import tkinter as tk
import unittest

from tools.semantic_harness.entrypoints.cli import _parser
from tools.semantic_harness.ui.shell import SemanticHarnessApp
from tools.providers.pnc.tests.gui_test_support import SemanticLabGuiTestCase


def _labels(notebook: object) -> list[str]:
    return [
        notebook.tab(tab, "text")
        for tab in notebook.tabs()
    ]


@unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
class SurfaceConsolidationTkTests(SemanticLabGuiTestCase):
    def _wait_until(self, root: tk.Misc, predicate: object, timeout: float = 20.0) -> None:
        deadline = time.monotonic() + timeout
        while not predicate() and time.monotonic() < deadline:
            root.update()
            time.sleep(0.02)
        self.assertTrue(predicate())

    def test_studio_and_simulation_have_one_home_per_job(self) -> None:
        root = tk.Tk()
        app = self.make_gui_app(root)
        self.assertEqual(_labels(app.studio_notebook), [
            "Conversations", "Source / Impact", "Review",
        ])
        self.wait_for(
            root,
            lambda: getattr(app, "_studio_editors_ready", False),
            "timed out waiting for deferred Studio editors",
        )
        self.assertTrue(app.toggle_legacy_surfaces(True))
        self.assertEqual(_labels(app.studio_notebook), [
            "Conversations",
            "Source / Impact",
            "Review",
            "Explore (Legacy)",
            "Dialogue Content (Legacy)",
        ])
        self.assertEqual(_labels(app.studio_explore_notebook), [
            "Responses", "Interactions",
        ])
        self.assertEqual(_labels(app.advanced_notebook), [
            "Interaction Modules",
            "Flow editor",
            "Canonical source editor",
            "Block contracts",
            "Interaction composer",
            "Workflow composer",
        ])
        self.assertTrue(hasattr(app, "developer_tools_button"))
        self.assertTrue(hasattr(app, "dialogue_content"))
        self.assertEqual(_labels(app.observatory.tabs), [
            "Registered responses",
        ])
        self.assertNotIn("Test Lab", _labels(app.observatory.tabs))
        self.assertNotIn("Coverage", _labels(app.observatory.tabs))
        self.assertFalse(app.toggle_legacy_surfaces(False))
        self.assertEqual(_labels(app.studio_notebook), [
            "Conversations", "Source / Impact", "Review",
        ])

        self.assertEqual(_labels(app.trace_tabs), [
            "Inspect", "Graph", "Interactions",
            "Compare / Regression", "Quality Sweep", "World", "Debug",
        ])
        self.assertEqual(_labels(app.inspect_tabs), [
            "Understanding", "Authority / effects", "Predicates", "Provenance",
        ])
        self.assertEqual(_labels(app.graph_tabs), [
            "Dialogue graph", "Runtime details",
        ])
        self.assertEqual(_labels(app.compare_tabs), [
            "Context comparison", "Talk parity", "Regression",
        ])
        self.assertEqual(_labels(app.debug_tabs), [
            "Worker", "Raw worker record",
        ])
        self.assertTrue(hasattr(app, "selection_explain_button"))
        self.assertTrue(hasattr(app, "regression_output"))
        self.assertTrue(hasattr(app, "source_explorer"))

    def test_structural_studio_tools_are_hidden_behind_developer_launcher(self) -> None:
        root = tk.Tk()
        app = self.make_gui_app(root)
        self.wait_for(
            root,
            lambda: getattr(app, "_studio_editors_ready", False),
            "timed out waiting for deferred Studio editors",
        )
        root.update()
        app.main_tabs.select(app.studio_tab)
        app.developer_tools_host.grid_remove()
        root.update_idletasks()
        self.assertFalse(app.developer_tools_host.winfo_ismapped())

        app.developer_tools_button.invoke()
        root.update_idletasks()
        self.assertTrue(app.developer_tools_host.winfo_ismapped())
        self.assertEqual(
            _labels(app.advanced_notebook)[0],
            "Interaction Modules",
        )

        app.developer_tools_button.invoke()
        root.update_idletasks()
        self.assertFalse(app.developer_tools_host.winfo_ismapped())

    def test_interaction_module_content_link_uses_dialogue_content_home(self) -> None:
        root = tk.Tk()
        app = self.make_gui_app(root)
        self.wait_for(
            root,
            lambda: getattr(app, "_studio_editors_ready", False),
            "timed out waiting for deferred Studio editors",
        )
        root.update()

        app.interaction_modules._on_open_content(
            "semantic.interaction.memory.acknowledge"
        )
        root.update_idletasks()

        self.assertEqual(
            app.studio_notebook.tab(app.studio_notebook.select(), "text"),
            "Dialogue Content (Legacy)",
        )
        self.assertEqual(app.authoring_service.list_dialogue_content(), [])
        self.assertIn(
            "semantic.interaction.memory.acknowledge",
            app.dialogue_content._status_var.get(),
        )

    def test_dialogue_content_review_uses_shared_review_home(self) -> None:
        root = tk.Tk()
        app = self.make_gui_app(root)
        self.wait_for(
            root,
            lambda: getattr(app, "_studio_editors_ready", False),
            "timed out waiting for deferred Studio editors",
        )
        app.toggle_legacy_surfaces(True)
        root.update()
        greeting = next(
            row
            for row in app.authoring_service.list_convo_engine_families()
            if (row.get("canonicalID") or row["id"]) == "flow.greeting.opening.default"
        )
        document = json.loads(
            Path(greeting["sourcePath"]).read_text(encoding="utf-8")
        )
        preview = app.authoring_service.preview_convo_engine_document(
            document, source_path=greeting["sourcePath"]
        )
        say_variants = preview["compiled"]["records"][0]["payload"]["say"]["realizations"]["1"]["variants"]
        line = next(v for v in say_variants if v["id"] == "neutral")["text"]["EN"][0]
        report = {
            "contentID": greeting["canonicalID"],
            "kind": "phraseFamily",
            "sourceFingerprint": greeting["sourceFingerprint"],
            "contentFingerprint": greeting["sourceFingerprint"],
            "contentBefore": {
                "kind": "phraseFamily",
                "semanticTemplateID": greeting["canonicalID"],
                "styles": {"neutral": [{"translations": {"EN": line}}]},
            },
            "contentAfter": {
                "kind": "phraseFamily",
                "semanticTemplateID": greeting["canonicalID"],
                "styles": {"neutral": [{"translations": {"EN": line}}]},
            },
        }
        app.dialogue_content.on_send_review(report)
        root.update_idletasks()
        self.assertEqual(
            app.studio_notebook.tab(app.studio_notebook.select(), "text"),
            "Review",
        )
        review = app.observatory.views["Review"].get("1.0", "end")
        self.assertIn("Dialogue Content review", review)
        self.assertIn("Structural metadata: PRESERVED / LOCKED", review)
        self.assertIn("Hey there. Good to see you.", review)

    def test_regression_and_selection_explanation_stay_in_simulation(self) -> None:
        root = tk.Tk()
        app = self.make_gui_app(root)
        app._messagebox.showerror = lambda *_args, **_kwargs: None
        self.wait_for_worker_ready(root, app)
        self.wait_for(
            root,
            lambda: app.session.ready,
            "timed out waiting for the foreground Semantic Lab session",
        )
        app.input_var.set("hello")
        app.submit()
        self.wait_for(
            root,
            lambda: bool(app.last_response),
            "timed out waiting for the submitted production response",
        )

        app.run_regression()
        self.wait_for(
            root,
            lambda: "PASS=" in app.regression_output.get("1.0", "end")
            and "FAIL=0" in app.regression_output.get("1.0", "end"),
            "timed out waiting for the production regression matrix",
            timeout=60.0,
        )
        self.assertIn("PASS=", app.regression_output.get("1.0", "end"))
        self.assertIn("FAIL=0", app.regression_output.get("1.0", "end"))
        self.assertEqual(
            app.trace_tabs.tab(app.trace_tabs.select(), "text"),
            "Compare / Regression",
        )
        self.assertEqual(
            app.compare_tabs.tab(app.compare_tabs.select(), "text"),
            "Regression",
        )

        app.explain_current_selection()
        self.wait_for(
            root,
            lambda: "semantic.flow.greeting.opening.default"
            in app.provenance_inspector.get("1.0", "end"),
            "timed out waiting for the production selection explanation",
        )
        self.assertIn(
            "semantic.flow.greeting.opening.default",
            app.provenance_inspector.get("1.0", "end"),
        )
        self.assertEqual(
            app.trace_tabs.tab(app.trace_tabs.select(), "text"), "Inspect"
        )
        self.assertEqual(
            app.inspect_tabs.tab(app.inspect_tabs.select(), "text"),
            "Provenance",
        )


if __name__ == "__main__":
    unittest.main()
