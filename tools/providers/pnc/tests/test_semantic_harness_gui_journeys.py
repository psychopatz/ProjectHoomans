"""Real Tk/Xvfb GUI end-to-end journeys through SemanticHarnessApp."""

from __future__ import annotations

import json
import os
from pathlib import Path
import shutil
import tempfile
import tkinter as tk
import unittest

from tools.providers.pnc.tests.gui_test_support import SemanticLabGuiTestCase

HOOMANS_ROOT = Path(__file__).resolve().parents[4]
CORE_ROOT = HOOMANS_ROOT.parent / "psychopatzCore"
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.studio.convo_engine_authoring_pane import (
    ConvoEngineAuthoringPane,
)
from tools.semantic_harness.testing import sweep_service as sweep_service_module


class _TempFileDialog:
    """Deterministic file-dialog adapter avoiding blocking native modals."""

    def __init__(self, target_path: Path) -> None:
        self.target_path = Path(target_path)

    def askopenfilename(self, **_kwargs: object) -> str:
        return str(self.target_path) if self.target_path.is_file() else ""

    def asksaveasfilename(self, **_kwargs: object) -> str:
        return str(self.target_path)


class _NonBlockingMessageBox:
    """Non-modal messagebox adapter capturing messages cleanly."""

    def __init__(self, *, confirm: bool = True) -> None:
        self.confirm = confirm
        self.errors: list[tuple[str, str]] = []
        self.infos: list[tuple[str, str]] = []

    def showerror(self, title: str, message: str) -> None:
        self.errors.append((str(title), str(message)))

    def showinfo(self, title: str, message: str) -> None:
        self.infos.append((str(title), str(message)))

    def askyesno(self, *_args: object) -> bool:
        return self.confirm


def _invoke_button_with_text(widget: object, text: str) -> bool:
    children = getattr(widget, "winfo_children", lambda: ())()
    for child in children:
        cget = getattr(child, "cget", None)
        invoke = getattr(child, "invoke", None)
        if callable(cget) and callable(invoke):
            try:
                if str(cget("text")) == text:
                    invoke()
                    return True
            except tk.TclError:
                pass
        if _invoke_button_with_text(child, text):
            return True
    return False


@unittest.skipUnless(os.environ.get("DISPLAY"), "Tk display is unavailable")
class SemanticHarnessGuiJourneyTests(SemanticLabGuiTestCase):
    def test_tk_selection_validate_apply_and_preset_reconfiguration(self) -> None:
        root = tk.Tk()
        app = self.make_gui_app(root)
        app._messagebox = _NonBlockingMessageBox()
        self.wait_for_worker_ready(root, app)

        app.main_tabs.select(0)
        root.update_idletasks()
        app.selection_details_button.invoke()
        self.assertTrue(app.selection_details_visible)
        app.selection_details_button.invoke()
        self.assertFalse(app.selection_details_visible)

        preset_values = tuple(str(v) for v in app.selection_preset_box["values"])
        dt_label = next(v for v in preset_values if v.endswith("· dtabstract"))
        pnc_label = next(v for v in preset_values if v.endswith("· pnc"))

        app.selection_mode_var.set("Preset")
        app.selection_preset_var.set(dt_label)
        app.selection_validate_button.invoke()
        self.assertIn("Valid", app.selection_status_var.get())

        app.selection_apply_button.invoke()
        self.wait_for(
            root,
            lambda: app.worker_ready
            and not app.busy
            and isinstance(app.selection_active, dict)
            and "DTCommon" in (app.selection_active.get("providerIDs") or []),
            "timed out waiting for dtabstract preset apply in World & Mods",
            timeout=25.0,
        )

        app.selection_preset_var.set(pnc_label)
        app.selection_validate_button.invoke()
        app.selection_apply_button.invoke()
        self.wait_for(
            root,
            lambda: app.worker_ready
            and not app.busy
            and isinstance(app.selection_active, dict)
            and "ProjectHoomans" in (app.selection_active.get("providerIDs") or []),
            "timed out restoring pnc preset in World & Mods",
            timeout=25.0,
        )

    def test_tk_simulation_preview_language_scenario_io_and_worker_recovery(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory(prefix="s10c-sim-io-") as tmp:
            scenario_path = Path(tmp) / "scenario.json"
            root = tk.Tk()
            app = self.make_gui_app(root)
            app._filedialog = _TempFileDialog(scenario_path)
            msgbox = _NonBlockingMessageBox()
            app._messagebox = msgbox
            self.wait_for_worker_ready(root, app)

            # Preview & Send
            app.input_var.set("hello")
            app.preview_button.invoke()
            self.wait_for(
                root,
                lambda: not app.busy and bool(app.inspector.get("1.0", "end-1c").strip()),
                "timed out waiting for preview output",
            )
            app.send_button.invoke()
            self.wait_for(
                root,
                lambda: not app.busy
                and "PLAYER: hello" in app.transcript.get("1.0", "end-1c")
                and bool(app.last_response),
                "timed out waiting for Send response in transcript",
            )

            # Language switch via Simulation control + save/reset/load
            app.language_var.set("TL")
            app.set_language()
            self.wait_for(
                root,
                lambda: not app.busy
                and app.scenario.get("runtime", {}).get("language") == "TL",
                "timed out switching language to TL",
            )
            app.language_var.set("EN")
            app.set_language()
            self.wait_for(
                root,
                lambda: not app.busy
                and app.scenario.get("runtime", {}).get("language") == "EN",
                "timed out switching language back to EN",
            )

            app.save_button.invoke()
            self.assertTrue(scenario_path.is_file())
            saved = json.loads(scenario_path.read_text(encoding="utf-8"))
            self.assertEqual(saved.get("runtime", {}).get("language"), "EN")

            app.reset_button.invoke()
            self.wait_for(
                root,
                lambda: not app.busy and "Scenario reset." in app.transcript.get("1.0", "end-1c"),
                "timed out waiting for scenario Reset",
            )
            app.load_button.invoke()
            self.wait_for(
                root,
                lambda: not app.busy and "Loaded " in app.transcript.get("1.0", "end-1c"),
                "timed out waiting for scenario Load",
            )

            # Toolbar & dialog controls (diagnostics, advanced, layout, settings, log clear)
            was_trace = app.trace_panel_visible
            app.diagnostics_toggle_button.invoke()
            self.assertNotEqual(app.trace_panel_visible, was_trace)
            was_adv = app.advanced_controls_visible
            app.advanced_toggle_button.invoke()
            self.assertNotEqual(app.advanced_controls_visible, was_adv)
            app.reset_layout_button.invoke()
            self.assertTrue(app.trace_panel_visible)

            app.settings_button.invoke()
            root.update_idletasks()
            self.assertIsNotNone(app.settings_window)
            self.assertTrue(app.settings_window.winfo_exists())
            app.settings_window.destroy()
            app.settings_window = None

            app.clear_activity_log()

            # Diagnostics + Regression + World Knowledge + Snapshot + Restart recovery
            app.last_response = {}
            app.snapshot_button.invoke()
            self.wait_for(
                root,
                lambda: not app.busy and bool(app.last_response),
                "timed out waiting for Snapshot output",
            )
            app.world_knowledge_button.invoke()
            self.wait_for(
                root,
                lambda: not app.busy
                and bool(app.world_knowledge_inspector.get("1.0", "end-1c").strip()),
                "timed out waiting for World Knowledge inspection",
            )
            for reg_btn in (
                app.regression_greeting_button,
                app.regression_lifecycle_button,
                app.regression_rejection_button,
                app.regression_selection_button,
            ):
                reg_btn.invoke()
                self.wait_for(
                    root,
                    lambda: not app.busy
                    and bool(app.regression_output.get("1.0", "end-1c").strip()),
                    f"timed out waiting for regression button {reg_btn.cget('text')}",
                )

            # Controlled worker error + restart button recovery
            def broken_request(_worker: object) -> dict[str, object]:
                raise RuntimeError("injected worker request failure")

            app._start_operation(broken_request, lambda _resp: None)
            self.wait_for(
                root,
                lambda: not app.busy and bool(msgbox.errors),
                "expected actionable non-modal error capture on worker failure",
            )
            self.assertIn("injected worker request failure", msgbox.errors[-1][1])

            app.restart_button.invoke()
            self.wait_for(
                root,
                lambda: not app.busy
                and app.worker_ready
                and "Lua worker restarted" in app.transcript.get("1.0", "end-1c"),
                "timed out recovering via Restart worker button",
            )
            app.input_var.set("hello")
            app.send_button.invoke()
            self.wait_for(
                root,
                lambda: not app.busy and bool(app.last_response),
                "timed out submitting turn after worker restart",
            )

    def test_tk_quality_sweep_and_simulation_sweep_journeys(self) -> None:
        with tempfile.TemporaryDirectory(prefix="s10c-sweep-dir-") as sweep_tmp:
            orig_sweep_dir = sweep_service_module.DialogueQualitySweepService.__init__.__defaults__
            root = tk.Tk()
            app = self.make_gui_app(root)
            app._messagebox = _NonBlockingMessageBox()
            self.wait_for_worker_ready(root, app)

            # Isolate generated sweep reports inside temp directory
            from tools.semantic_harness.ui import simulation_sweep_controller as sim_sc
            from tools.semantic_harness.ui import quality_sweep_controller as qs_ctrl

            def temp_sweep_service() -> sweep_service_module.DialogueQualitySweepService:
                return sweep_service_module.DialogueQualitySweepService(base_dir=sweep_tmp)

            orig_sim_service = getattr(sim_sc, "DialogueQualitySweepService", None)
            orig_qs_service = qs_ctrl._service
            sim_sc.DialogueQualitySweepService = lambda **_kw: temp_sweep_service()
            qs_ctrl._service = temp_sweep_service
            self.addCleanup(setattr, qs_ctrl, "_service", orig_qs_service)
            if orig_sim_service is not None:
                self.addCleanup(
                    setattr, sim_sc, "DialogueQualitySweepService", orig_sim_service
                )

            # Simulation Quality Sweep tab: Plan -> Run -> Cancel -> Open Workbench button
            app.sweep_strategy_var.set("smoke")
            app.sweep_id_var.set("s10c_sim_sweep")
            app.sweep_plan_button.invoke()
            self.assertIsNotNone(app.current_sweep_plan)
            self.assertIn("Planned ", app.sweep_estimate_var.get())

            app.sweep_run_button.invoke()
            self.assertIsNotNone(app.current_sweep_manifest)
            app.sweep_cancel_button.invoke()
            self.assertIn("Cancel", app.sweep_status_var.get())
            app.sweep_open_workbench_button.invoke()
            root.update_idletasks()
            self.assertEqual(
                app.main_tabs.select(), str(app.quality_sweep_tab)
            )

            # Dedicated Quality Sweep tab: Generate -> Cancel mid-run / finish cleanly
            app.quality_sweep_id_var.set("s10c_dedicated_sweep")
            app.quality_sweep_strategy_var.set("smoke")
            app.qs_generate_button.invoke()
            self.wait_for(
                root,
                lambda: bool(getattr(app, "quality_sweep_is_running", False))
                or getattr(app, "quality_sweep_manifest", None) is not None,
                "timed out waiting for Quality Sweep run to start",
                timeout=20.0,
            )
            if getattr(app, "quality_sweep_is_running", False):
                app.qs_cancel_button.invoke()
                self.assertTrue(app.quality_sweep_cancel_requested)
            self.wait_for(
                root,
                lambda: not getattr(app, "quality_sweep_is_running", False),
                "timed out waiting for Quality Sweep stop/completion",
                timeout=45.0,
            )

    def test_tk_studio_convo_authoring_audit_and_hermetic_write_delete(self) -> None:
        root = tk.Tk()
        app = self.make_gui_app(root)
        app._messagebox = _NonBlockingMessageBox(confirm=True)
        self.wait_for_worker_ready(root, app)
        self.wait_for(
            root,
            lambda: getattr(app, "_studio_editors_ready", False),
            "timed out waiting for Studio editors",
        )

        # Toggle developer drawer and invoke read-only Studio preview & integrity audit
        app.main_tabs.select(app.studio_tab)
        app.developer_tools_button.invoke()
        root.update_idletasks()
        self.assertTrue(app.developer_tools_host.winfo_ismapped())

        pane = app.convo_engine_authoring
        self.assertTrue(_invoke_button_with_text(app.studio_tab, "Refresh families"))
        self.assertTrue(pane._families)
        self.assertTrue(_invoke_button_with_text(app.studio_tab, "Validate & trace"))
        self.assertTrue(_invoke_button_with_text(app.studio_tab, "Run ConvoEngine Integrity Audit"))
        self.assertIn("convoengine integrity audit", pane._status_var.get().lower())

        # Hermetic temp workspace for New family -> Write canonical source -> Duplicate -> Delete
        with tempfile.TemporaryDirectory(prefix="s10c-studio-hermetic-") as tmp:
            temp_root = Path(tmp)
            temp_core = temp_root / "psychopatzCore"
            temp_hoomans = temp_root / "ProjectHoomans"
            shutil.copytree(
                CORE_ROOT / "tools/semantic_harness",
                temp_core / "tools/semantic_harness",
            )
            shutil.copytree(
                CORE_ROOT / "Contents",
                temp_core / "Contents",
            )
            dst_convo = temp_hoomans / "tools/providers/pnc/codebuilder/sources/conversation"
            dst_convo.mkdir(parents=True, exist_ok=True)
            manifest = HOOMANS_ROOT / "tools/providers/pnc/provider.json"
            shutil.copy2(manifest, temp_hoomans / "tools/providers/pnc/provider.json")
            first_family = next(
                (HOOMANS_ROOT / "tools/providers/pnc/codebuilder/sources/conversation/dialogue").iterdir()
            )
            shutil.copytree(first_family, dst_convo / "dialogue" / first_family.name)

            hermetic_service = SemanticLabAuthoringService(
                temp_hoomans, core_repository=temp_core
            )
            host_frame = tk.Frame(root)
            from tkinter import ttk, scrolledtext

            hermetic_pane = ConvoEngineAuthoringPane(
                host_frame,
                tk,
                ttk,
                scrolledtext.ScrolledText,
                _NonBlockingMessageBox(confirm=True),
                hermetic_service,
            )
            self.assertTrue(_invoke_button_with_text(host_frame, "New family"))
            hermetic_pane._id_var.set("s10c_hermetic_topic")
            if isinstance(hermetic_pane._document, dict):
                hermetic_pane._document["id"] = "s10c_hermetic_topic"
            self.assertTrue(_invoke_button_with_text(host_frame, "Validate & trace"))
            self.assertTrue(_invoke_button_with_text(host_frame, "Write canonical source"))
            self.assertIsNotNone(hermetic_pane._current_entry)
            written_path = Path(str(hermetic_pane._current_entry["sourcePath"]))
            self.assertTrue(str(written_path).startswith(str(temp_hoomans)))
            self.assertTrue(written_path.is_file())

            written_entry = hermetic_pane._current_entry
            self.assertTrue(_invoke_button_with_text(host_frame, "Duplicate"))
            hermetic_pane._current_entry = written_entry
            self.assertTrue(_invoke_button_with_text(host_frame, "Delete"))
            self.assertFalse(written_path.exists())


if __name__ == "__main__":
    unittest.main()
