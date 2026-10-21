"""Tk adapter for the real-Lua semantic dialogue worker."""

from __future__ import annotations

import argparse
import sys
from concurrent.futures import Future
from pathlib import Path
from typing import Any, Callable

from ..inspection.conversation_inspector import build_conversation_inspector
from ..codebuilder.service import SemanticLabAuthoringService
from ..studio.block_registry import SemanticBlockRegistryPane
from ..studio.dataset_library import DatasetLibraryPane
from .flow_editor.pane import FlowEditorPane
from ..studio.interaction_explorer_pane import InteractionExplorerPane
from ..studio.interaction_spec_pane import InteractionSpecPane
from ..inspection.rendering import conversation_first, pretty
from ..runtime.config import ConfigurationError
from ..runtime.scenario import load_scenario, save_scenario
from .dialogs.settings import open_runtime_settings as show_runtime_settings
from ..inspection.transcript import TranscriptBuffer
from ..runtime.worker import HarnessError, LuaSemanticWorker
from ..runtime.worker_session import WorkerReady, WorkerResult, WorkerSession
from ..studio.workflow import SemanticLabWorkflowPane


def npc_message_text(message: dict[str, Any]) -> str:
    """Return rendered production text before its English fallback."""

    payload = message.get("payload", {})
    return str(payload.get("text") or payload.get("fallback") or "")


def semantic_suggestion_rows(suggestions: dict[str, Any]) -> list[dict[str, Any]]:
    """Build the bounded visual slice from the production projection."""

    candidates = suggestions.get("candidates") or []
    capabilities = suggestions.get("permittedCapabilities") or []
    rows: list[dict[str, Any]] = []
    candidate_limit = max(0, 6 - len(capabilities)) if capabilities else 6
    for candidate in candidates[:candidate_limit]:
        rows.append(
            {
                "id": candidate.get("id"),
                "frame": candidate.get("frame"),
                "display": candidate.get("display") or {},
                "status": "eligible",
                "enabled": True,
                "source": candidate.get("source"),
            }
        )
    for capability in capabilities[: max(0, 6 - len(rows))]:
        status = capability.get("status") or "unavailable_unknown"
        rows.append(
            {
                "id": capability.get("id"),
                "action": capability.get("action"),
                "frame": capability.get("frame"),
                "display": capability.get("display") or {},
                "status": status,
                "enabled": status in {"eligible", "selected_for_preflight"},
                "source": capability.get("source"),
                "eligibility": capability.get("eligibility"),
            }
        )
    return rows


def semantic_suggestion_title(row: dict[str, Any]) -> str:
    display = row.get("display") or {}
    return str(
        display.get("label")
        or display.get("labelFallback")
        or display.get("utterance")
        or display.get("utteranceFallback")
        or row.get("id")
        or row.get("action")
        or "Suggestion"
    )


class SemanticHarnessApp:
    """Nonblocking Tk adapter over the same session API used by the CLI."""

    def __init__(self, root: Any, arguments: argparse.Namespace) -> None:
        import tkinter as tk
        from tkinter import filedialog, messagebox, ttk
        from tkinter.scrolledtext import ScrolledText

        self.root = root
        self._tk = tk
        self._filedialog = filedialog
        self._messagebox = messagebox
        self._ttk = ttk
        self._ScrolledText = ScrolledText
        self.arguments = arguments
        repository = Path(arguments.repository) if arguments.repository else None
        self.authoring_service = SemanticLabAuthoringService(
            repository=repository,
            runtime_root=repository,
        )
        self.root.title("Project Hoomans Semantic Lab")
        self.root.geometry("1320x860")
        self.scenario_path = Path(arguments.scenario) if arguments.scenario else None
        self.scenario = load_scenario(self.scenario_path)
        if arguments.language:
            self.scenario.setdefault("runtime", {})["language"] = arguments.language.upper()
        self.session = WorkerSession(
            lambda: LuaSemanticWorker(self.scenario, **self._worker_kwargs())
        )
        self.closed = False
        self.busy = False
        self._production_catalog: dict[str, Any] | None = None
        self.settings_window: Any | None = None
        self._future: Future[Any] | None = None
        self._transcript_buffer = TranscriptBuffer()
        self._build_ui()
        self.root.protocol("WM_DELETE_WINDOW", self.close)
        self._set_status("Starting Lua worker…")
        self.root.after(20, self._start_worker)

    def _build_ui(self) -> None:
        ttk = self._ttk
        ScrolledText = self._ScrolledText
        self.main_tabs = ttk.Notebook(self.root)
        self.main_tabs.pack(fill="both", expand=True, padx=6, pady=6)

        studio_tab = ttk.Frame(self.main_tabs, padding=6)
        simulation_tab = ttk.Frame(self.main_tabs, padding=8)
        studio_tab.rowconfigure(0, weight=1)
        studio_tab.columnconfigure(0, weight=1)
        simulation_tab.rowconfigure(0, weight=1)
        simulation_tab.columnconfigure(0, weight=1)
        studio_notebook = ttk.Notebook(studio_tab)
        studio_notebook.grid(row=0, column=0, sticky="nsew")
        workflow_tab = ttk.Frame(studio_notebook, padding=8)
        editor_tab = ttk.Frame(studio_notebook, padding=8)
        library_tab = ttk.Frame(studio_notebook, padding=8)
        blocks_tab = ttk.Frame(studio_notebook, padding=8)
        composer_tab = ttk.Frame(studio_notebook, padding=8)
        for panel in (workflow_tab, editor_tab, library_tab, blocks_tab, composer_tab):
            panel.rowconfigure(0, weight=1)
            panel.columnconfigure(0, weight=1)
        studio_notebook.add(workflow_tab, text="Build workflow")
        studio_notebook.add(editor_tab, text="Flow + interactions")
        studio_notebook.add(library_tab, text="Dataset library")
        studio_notebook.add(blocks_tab, text="Block palette")
        studio_notebook.add(composer_tab, text="Interaction composer")
        self.main_tabs.add(studio_tab, text="Studio")
        self.main_tabs.add(simulation_tab, text="Simulation")

        container = ttk.Frame(simulation_tab)
        container.pack(fill="both", expand=True)
        container.columnconfigure(0, weight=3)
        container.columnconfigure(1, weight=2)
        container.rowconfigure(0, weight=1)

        transcript_frame = ttk.LabelFrame(container, text="Conversation")
        transcript_frame.grid(row=0, column=0, sticky="nsew", padx=(0, 8))
        transcript_frame.rowconfigure(0, weight=1)
        transcript_frame.columnconfigure(0, weight=1)
        self.transcript = ScrolledText(transcript_frame, wrap="word", state="disabled")
        self.transcript.grid(row=0, column=0, sticky="nsew", padx=6, pady=6)

        suggestion_frame = ttk.LabelFrame(
            transcript_frame, text="Contextual semantic suggestions"
        )
        suggestion_frame.grid(row=1, column=0, sticky="ew", padx=6, pady=(0, 6))
        suggestion_frame.grid_propagate(False)
        suggestion_frame.configure(height=112)
        for column in range(3):
            suggestion_frame.columnconfigure(column, weight=1)
        self.suggestion_buttons: list[Any] = []
        self.suggestion_rows: list[dict[str, Any]] = []
        self.suggestion_interactive = False
        for index in range(6):
            button = ttk.Button(
                suggestion_frame,
                text="",
                command=lambda index=index: self.click_suggestion(index),
            )
            button.grid(
                row=index // 3,
                column=index % 3,
                sticky="ew",
                padx=3,
                pady=3,
            )
            self.suggestion_buttons.append(button)
        self.suggestion_status = ttk.Label(
            suggestion_frame,
            text="Run a production preview or turn to inspect suggestions.",
        )
        self.suggestion_status.grid(
            row=2, column=0, columnspan=3, sticky="w", padx=4, pady=(0, 2)
        )

        self.input_var = self._tk.StringVar()
        input_box = ttk.Entry(transcript_frame, textvariable=self.input_var)
        input_box.grid(row=2, column=0, sticky="ew", padx=6, pady=(0, 6))
        input_box.bind("<Return>", lambda _: self.submit())
        self.send_button = ttk.Button(transcript_frame, text="Send", command=self.submit)
        self.send_button.grid(row=3, column=0, sticky="e", padx=6, pady=(0, 6))

        controls = ttk.Frame(container)
        controls.grid(row=1, column=0, sticky="ew", padx=(0, 8), pady=(8, 0))
        self.reset_button = ttk.Button(controls, text="Reset", command=self.reset)
        self.reset_button.pack(side="left")
        self.load_button = ttk.Button(controls, text="Load scenario", command=self.load)
        self.load_button.pack(side="left", padx=6)
        self.settings_button = ttk.Button(
            controls, text="Mock runtime…", command=self.open_runtime_settings
        )
        self.settings_button.pack(side="left")
        self.preview_button = ttk.Button(controls, text="Preview", command=self.preview)
        self.preview_button.pack(side="left", padx=6)
        self.save_button = ttk.Button(controls, text="Save scenario", command=self.save)
        self.save_button.pack(side="left", padx=6)
        self.snapshot_button = ttk.Button(controls, text="Snapshot", command=self.show_snapshot)
        self.snapshot_button.pack(side="left")
        self.restart_button = ttk.Button(controls, text="Restart worker", command=self.restart)
        self.restart_button.pack(side="left", padx=6)
        self.language_var = self._tk.StringVar(value=self.scenario.get("runtime", {}).get("language", "EN"))
        self.language_box = ttk.Combobox(
            controls,
            textvariable=self.language_var,
            values=("EN", "TL"),
            width=6,
            state="readonly",
        )
        self.language_box.pack(side="left", padx=(12, 6))
        self.language_box.bind("<<ComboboxSelected>>", lambda _: self.set_language())
        self.status_var = self._tk.StringVar(value="Starting…")
        ttk.Label(controls, textvariable=self.status_var).pack(side="right")

        right = ttk.LabelFrame(container, text="Semantic trace")
        right.grid(row=0, column=1, rowspan=2, sticky="nsew")
        right.rowconfigure(0, weight=1)
        right.columnconfigure(0, weight=1)
        self.trace_tabs = ttk.Notebook(right)
        self.trace_tabs.grid(row=0, column=0, sticky="nsew", padx=6, pady=6)

        conversation_frame = ttk.Frame(self.trace_tabs)
        conversation_frame.rowconfigure(0, weight=1)
        conversation_frame.columnconfigure(0, weight=1)
        self.inspector = ScrolledText(
            conversation_frame, wrap="word", state="disabled"
        )
        self.inspector.grid(row=0, column=0, sticky="nsew")
        self.trace_tabs.add(conversation_frame, text="Conversation understanding")

        authority_frame = ttk.Frame(self.trace_tabs)
        authority_frame.rowconfigure(0, weight=1)
        authority_frame.columnconfigure(0, weight=1)
        self.authority = ScrolledText(
            authority_frame, wrap="word", state="disabled"
        )
        self.authority.grid(row=0, column=0, sticky="nsew")
        self.trace_tabs.add(authority_frame, text="Command authority")

        raw_frame = ttk.Frame(self.trace_tabs)
        raw_frame.rowconfigure(0, weight=1)
        raw_frame.columnconfigure(0, weight=1)
        self.trace = ScrolledText(raw_frame, wrap="none", state="disabled")
        self.trace.grid(row=0, column=0, sticky="nsew")
        self.trace_tabs.add(raw_frame, text="Raw worker record")

        suggestion_trace_frame = ttk.Frame(self.trace_tabs)
        suggestion_trace_frame.rowconfigure(0, weight=1)
        suggestion_trace_frame.columnconfigure(0, weight=1)
        self.suggestion_inspector = ScrolledText(
            suggestion_trace_frame, wrap="none", state="disabled"
        )
        self.suggestion_inspector.grid(row=0, column=0, sticky="nsew")
        self.trace_tabs.add(suggestion_trace_frame, text="Suggestions + predicates")

        editor_notebook = ttk.Notebook(editor_tab)
        editor_notebook.grid(row=0, column=0, sticky="nsew")
        flow_frame = ttk.Frame(editor_notebook)
        flow_frame.rowconfigure(0, weight=1)
        flow_frame.columnconfigure(0, weight=1)
        interaction_frame = ttk.Frame(editor_notebook)
        interaction_frame.rowconfigure(0, weight=1)
        interaction_frame.columnconfigure(0, weight=1)
        editor_notebook.add(interaction_frame, text="Interaction explorer")
        editor_notebook.add(flow_frame, text="Flow graph")
        self.flow_editor = FlowEditorPane(
            flow_frame,
            self._tk,
            ttk,
            ScrolledText,
            self._filedialog,
            self._messagebox,
            on_refresh=self.refresh_flow_catalog,
            on_validate=self.validate_flow_draft,
            on_register=self.register_flow_draft,
            on_compile_source=self.compile_semantic_source,
            on_generate_source=self.generate_semantic_source,
            on_review_dataset=self.review_dialogue_source,
            on_generate_dataset=self.generate_dialogue_source,
        )
        self.interaction_explorer = InteractionExplorerPane(
            interaction_frame,
            self._tk,
            ttk,
            ScrolledText,
            self.authoring_service,
            on_open_flow=self.flow_editor.select_flow,
        )
        self.interaction_composer = InteractionSpecPane(
            composer_tab,
            self._tk,
            ttk,
            ScrolledText,
            self._messagebox,
            on_preview=self.preview_interaction_spec,
            on_generate=self.generate_interaction_spec,
            on_inspect=self.inspect_live_worker,
        )
        self.dataset_library = DatasetLibraryPane(
            library_tab,
            self._tk,
            ttk,
            ScrolledText,
            self._messagebox,
            self.authoring_service,
        )
        self.block_registry = SemanticBlockRegistryPane(
            blocks_tab,
            self._tk,
            ttk,
            ScrolledText,
            self.authoring_service,
            on_refresh=self.refresh_flow_catalog,
        )
        self.workflow_pane = SemanticLabWorkflowPane(
            workflow_tab,
            self._tk,
            ttk,
            ScrolledText,
            self._messagebox,
            self.authoring_service,
            on_generate=self.generate_workflow,
            on_inspect=self.inspect_live_worker,
        )
        self.simulation_tab = simulation_tab

        self._append("SYSTEM", "Window ready. Starting the isolated Lua worker…")
        self._set_controls(False)

    def _set_controls(self, enabled: bool) -> None:
        state = "normal" if enabled and not self.busy else "disabled"
        for button in (
            self.send_button,
            self.reset_button,
            self.load_button,
            self.settings_button,
            self.preview_button,
            self.save_button,
            self.snapshot_button,
        ):
            button.configure(state=state)
        self.language_box.configure(state="readonly" if enabled and not self.busy else "disabled")
        self.restart_button.configure(
            state="normal" if self.session.ready and not self.busy else "disabled"
        )
        self.flow_editor.set_enabled(enabled and not self.busy)
        self.interaction_explorer.set_enabled(enabled and not self.busy)
        self.interaction_composer.set_enabled(enabled and not self.busy)
        self.workflow_pane.set_enabled(enabled and not self.busy)
        self._refresh_suggestion_controls(enabled and not self.busy)

    def _refresh_suggestion_controls(self, enabled: bool) -> None:
        for index, button in enumerate(self.suggestion_buttons):
            row = self.suggestion_rows[index] if index < len(self.suggestion_rows) else None
            button.configure(
                state=(
                    "normal"
                    if enabled
                    and self.suggestion_interactive
                    and row
                    and row.get("enabled") is True
                    else "disabled"
                )
            )

    @property
    def worker_ready(self) -> bool:
        return self.session.ready

    def _set_status(self, value: str) -> None:
        if hasattr(self, "status_var"):
            self.status_var.set(value)

    def _append(self, speaker: str, text: str) -> None:
        entry, removed_chars = self._transcript_buffer.append(speaker, text)
        self.transcript.configure(state="normal")
        if removed_chars:
            self.transcript.delete("1.0", f"1.0 + {removed_chars} chars")
        self.transcript.insert("end", entry)
        self.transcript.see("end")
        self.transcript.configure(state="disabled")

    def _set_text(self, widget: Any, value: str) -> None:
        if widget is getattr(self, "transcript", None):
            self._transcript_buffer.clear()
        widget.configure(state="normal")
        widget.delete("1.0", "end")
        widget.insert("end", value)
        widget.configure(state="disabled")

    def _worker_kwargs(self) -> dict[str, Any]:
        return {
            "lua_bin": self.arguments.lua,
            "repository": Path(self.arguments.repository) if self.arguments.repository else None,
            "core_repository": Path(self.arguments.core_repository) if self.arguments.core_repository else None,
            "startup_timeout": self.arguments.startup_timeout,
            "request_timeout": self.arguments.timeout,
            "shutdown_timeout": self.arguments.shutdown_timeout,
        }

    def _start_worker(self) -> None:
        if self.closed:
            return
        self._future = self.session.start()
        self._poll_future(self._future, self._worker_ready)

    def _poll_future(self, future: Future[Any], callback: Callable[[Any], None]) -> None:
        if self.closed:
            return
        if not future.done():
            self.root.after(25, self._poll_future, future, callback)
            return
        self.busy = False
        try:
            result = future.result()
        except (HarnessError, ConfigurationError, OSError, ValueError) as error:
            self._set_status("Worker failed")
            self._set_controls(False)
            self._set_text(self.trace, str(error))
            self._messagebox.showerror("Semantic harness startup/error", str(error))
            return
        callback(result)

    def _worker_ready(self, result: WorkerReady) -> None:
        self._set_status(f"Ready · Lua PID {result.status.get('pid')}")
        self._set_controls(True)
        self._append("SYSTEM", "Lua worker ready. Production semantic modules are loaded.")
        capabilities = result.capabilities or {}
        flow_catalog = capabilities.get("flowCatalog", {})
        self._set_text(
            self.inspector,
            pretty({
                "state": "ready",
                "worker": result.status,
                "flows": flow_catalog.get("flowCount", 0),
                "engineFacts": len(flow_catalog.get("factCatalog", [])),
                "engineEvents": len(flow_catalog.get("eventCatalog", [])),
                "commands": len(flow_catalog.get("commandCatalog", [])),
                "hint": "Use the Flow editor tab to build and validate production branches.",
            }),
        )
        self._set_text(self.trace, pretty(capabilities))
        self.flow_editor.set_catalog(flow_catalog)
        self.interaction_explorer.set_catalog(flow_catalog)
        self.interaction_composer.set_production_catalog(flow_catalog)
        self.block_registry.set_catalog(flow_catalog)
        self._production_catalog = flow_catalog
        self.workflow_pane.set_production_catalog(flow_catalog)

    def _start_operation(
        self,
        operation: Callable[[LuaSemanticWorker], Any],
        callback: Callable[[Any], None],
    ) -> bool:
        if self.closed or not self.session.ready or self.busy:
            return False
        self.busy = True
        self._set_status("Working…")
        self._set_controls(False)
        self._future = self.session.submit(operation)
        self._poll_future(self._future, self._operation_finished(callback))
        return True

    def _operation_finished(self, callback: Callable[[Any], None]) -> Callable[[Any], None]:
        def finish(result: WorkerResult[Any]) -> None:
            self._set_controls(True)
            self._set_status(f"Ready · Lua PID {result.status.get('pid')}")
            callback(result.value)

        return finish

    def _show_operation_error(self, error: Exception) -> None:
        self.busy = False
        self._set_controls(self.session.ready)
        self._set_status("Worker error")
        self._set_text(self.trace, str(error))
        self._messagebox.showerror("Harness error", str(error))

    def _show_response(self, response: dict[str, Any]) -> None:
        view = build_conversation_inspector(response)
        self._set_text(self.inspector, conversation_first(view))
        self._set_text(self.authority, pretty(view.get("commandAuthority", {})))
        self._set_text(self.trace, pretty(response))
        observation = response.get("observation") or {}
        suggestions = observation.get("suggestions") or {}
        self._render_suggestions(response, suggestions)

    def _render_suggestions(
        self, response: dict[str, Any], suggestions: dict[str, Any]
    ) -> None:
        self.suggestion_rows = semantic_suggestion_rows(suggestions)
        self.suggestion_interactive = (
            response.get("type") == "turn" and response.get("accepted") is True
        )
        for index, button in enumerate(self.suggestion_buttons):
            row = self.suggestion_rows[index] if index < len(self.suggestion_rows) else None
            if row:
                button.configure(text=semantic_suggestion_title(row))
            else:
                button.configure(text="")
        revision = suggestions.get("revision", "—")
        trace_count = len(suggestions.get("predicateTrace") or [])
        self.suggestion_status.configure(
            text=(
                f"Revision {revision} · {len(self.suggestion_rows)} visible · "
                f"{trace_count} bounded predicate trace rows"
            )
        )
        self._set_text(
            self.suggestion_inspector,
            pretty(
                {
                    "projection": suggestions,
                    "visualRows": [
                        {
                            "id": row.get("id"),
                            "action": row.get("action"),
                            "label": semantic_suggestion_title(row),
                            "status": row.get("status"),
                            "enabled": row.get("enabled"),
                            "source": row.get("source"),
                            "eligibility": row.get("eligibility"),
                        }
                        for row in self.suggestion_rows
                    ],
                }
            ),
        )
        self._refresh_suggestion_controls(self.session.ready and not self.busy)

    def submit(self) -> None:
        value = self.input_var.get().strip()
        if not value or not self.session.ready or self.busy:
            return
        self.input_var.set("")

        def finish(response: dict[str, Any]) -> None:
            self._append("PLAYER", value)
            for message in response.get("messages", []):
                if message.get("speaker") == "npc":
                    self._append("NPC", npc_message_text(message))
            for call in response.get("toolCalls", []):
                self._append(
                    "TOOL/ACTION",
                    f"{call.get('label') or call.get('name')}"
                    f" [{call.get('name')}] · "
                    f"{call.get('status') or call.get('reason') or 'observed'}",
                )
            self._show_response(response)

        self._start_operation(lambda worker: worker.input(value), finish)

    def click_suggestion(self, index: int) -> None:
        if not self.session.ready or self.busy or not self.suggestion_interactive:
            return
        if index < 0 or index >= len(self.suggestion_rows):
            return
        row = self.suggestion_rows[index]
        frame = row.get("frame")
        if not isinstance(frame, dict) or row.get("enabled") is not True:
            return
        label = semantic_suggestion_title(row)

        def finish(response: dict[str, Any]) -> None:
            if response.get("accepted") is True:
                utterance = (row.get("display") or {}).get("utterance") or label
                self._append("PLAYER", str(utterance))
                for message in response.get("messages", []):
                    if message.get("speaker") == "npc":
                        self._append("NPC", npc_message_text(message))
                for call in response.get("toolCalls", []):
                    self._append(
                        "TOOL/ACTION",
                        f"{call.get('label') or call.get('name')}"
                        f" [{call.get('name')}] · "
                        f"{call.get('status') or call.get('reason') or 'observed'}",
                    )
                self._append("SYSTEM", f"Clicked semantic suggestion: {label}")
            else:
                self._append(
                    "SYSTEM",
                    f"Suggestion rejected: {response.get('reason') or 'unknown'}",
                )
            self._show_response(response)

        self._start_operation(lambda worker: worker.suggestion_click(frame), finish)

    def preview(self) -> None:
        """Inspect a production decision without recording or dispatching it."""

        value = self.input_var.get().strip()
        if not value or not self.session.ready or self.busy:
            return

        def finish(response: dict[str, Any]) -> None:
            self._show_response(response)
            self._append("SYSTEM", f"Preview only; no state or action mutation: {value}")

        self._start_operation(lambda worker: worker.preview(value), finish)

    def reset(self) -> None:
        if not self.session.ready:
            return

        def finish(_: dict[str, Any]) -> None:
            self._set_text(self.transcript, "")
            self._set_text(self.inspector, "")
            self._set_text(self.authority, "")
            self._set_text(self.trace, "")
            self._set_text(self.suggestion_inspector, "")
            self.suggestion_rows = []
            self.suggestion_interactive = False
            self._render_suggestions({}, {})
            self._append("SYSTEM", "Scenario reset.")

        self._start_operation(lambda worker: worker.reset(), finish)

    def load(self) -> None:
        filename = self._filedialog.askopenfilename(
            title="Load semantic scenario",
            filetypes=[("JSON scenarios", "*.json"), ("All files", "*")],
        )
        if not filename or not self.session.ready or self.busy:
            return
        try:
            scenario = load_scenario(Path(filename))
        except (OSError, ValueError) as error:
            self._messagebox.showerror("Scenario error", str(error))
            return

        def finish(response: dict[str, Any]) -> None:
            self.scenario = scenario
            self.scenario_path = Path(filename)
            self.language_var.set(scenario.get("runtime", {}).get("language", "EN"))
            self._set_text(self.transcript, "")
            self._show_response(response)
            self._append("SYSTEM", f"Loaded {filename}")

        self._start_operation(lambda worker: worker.configure(scenario), finish)

    def save(self) -> None:
        """Persist the current in-memory scenario to its JSON scenario store."""

        if self.busy:
            return
        filename = self.scenario_path
        if filename is None:
            selected = self._filedialog.asksaveasfilename(
                title="Save semantic scenario",
                defaultextension=".json",
                filetypes=[("JSON scenarios", "*.json"), ("All files", "*")],
            )
            if not selected:
                return
            filename = Path(selected)
        try:
            save_scenario(filename, self.scenario)
        except (OSError, TypeError, ValueError) as error:
            self._messagebox.showerror("Scenario save error", str(error))
            return
        self.scenario_path = filename
        self._set_status(f"Saved scenario · {filename.name}")
        self._append("SYSTEM", f"Saved mock runtime scenario to {filename}")

    def open_runtime_settings(self) -> None:
        show_runtime_settings(self)

    def show_snapshot(self) -> None:
        if not self.session.ready:
            return
        self._start_operation(
            lambda worker: worker.snapshot(),
            self._show_response,
        )

    def refresh_flow_catalog(self) -> None:
        if not self.session.ready or self.busy:
            return
        self._start_operation(
            lambda worker: worker.flow_catalog(),
            self._flow_catalog_finished,
        )

    def _flow_catalog_finished(self, response: dict[str, Any]) -> None:
        self.flow_editor.set_catalog(response)
        self.interaction_explorer.set_catalog(response)
        self.interaction_composer.set_production_catalog(response)
        self.block_registry.set_catalog(response)
        self._production_catalog = response
        self.workflow_pane.set_production_catalog(response)
        self._append(
            "SYSTEM",
            f"Loaded {response.get('flowCount', 0)} normalized production flows.",
        )

    def validate_flow_draft(self, definition: dict[str, Any]) -> None:
        if not self.session.ready or self.busy:
            return
        self._start_operation(
            lambda worker: worker.validate_flow(definition),
            self.flow_editor.show_validation,
        )

    def register_flow_draft(self, definition: dict[str, Any]) -> None:
        if not self.session.ready or self.busy:
            return
        self._start_operation(
            lambda worker: worker.register_flow(definition),
            self.flow_editor.show_registration,
        )

    def compile_semantic_source(self, source_path: Path) -> None:
        """Preview canonical source offline; do not mutate the Lua worker."""
        report = self.authoring_service.preview_semantic_source(source_path)
        self.flow_editor.show_source_report(report)
        self._set_text(self.inspector, pretty(report))
        self._set_text(self.trace, pretty(report))
        if report.get("ok") is True:
            self._append(
                "SYSTEM",
                f"Compiler preview valid; no files written: {source_path.name}",
            )
        else:
            diagnostics = report.get("diagnostics") or []
            message = diagnostics[0].get("message") if diagnostics else "invalid source"
            self._append("SYSTEM", f"Compiler preview rejected: {message}")

    def review_dialogue_source(self, source_path: Path) -> None:
        """Review the canonical dialogue dataset through the existing Code Builder."""
        report = self.authoring_service.preview_dialogue_source(source_path)
        self.flow_editor.show_dataset_report(report)
        self._set_text(self.inspector, pretty(report))
        self._set_text(self.trace, pretty(report))
        review = report.get("candidateReview") or {}
        summary = review.get("summary") or {}
        collisions = review.get("collisions") or []
        artifact_diffs = report.get("artifactDiffs") or []
        changed = sum(
            1 for row in artifact_diffs
            if isinstance(row, dict) and row.get("status") != "unchanged"
        )
        if report.get("ok") is True:
            self._append(
                "SYSTEM",
                f"Dataset review valid; {summary.get('approved', 0)} approved, "
                f"{summary.get('rejected', 0)} rejected, {len(collisions)} collisions, "
                f"{changed} artifact diffs; "
                "no files written.",
            )
        else:
            diagnostics = report.get("diagnostics") or []
            message = diagnostics[0].get("message") if diagnostics else "invalid dataset"
            self._append("SYSTEM", f"Dataset review rejected: {message}")

    def generate_dialogue_source(self, source_path: Path) -> None:
        """Write approved dialogue artifacts through the existing Code Builder writer."""
        report = self.authoring_service.generate_dialogue_source(source_path)
        self.flow_editor.show_dataset_report(report)
        self._set_text(self.inspector, pretty(report))
        self._set_text(self.trace, pretty(report))
        if report.get("ok") is not True:
            diagnostics = report.get("diagnostics") or []
            message = diagnostics[0].get("message") if diagnostics else "generation failed"
            self._append("SYSTEM", f"Dialogue generation rejected: {message}")
            return
        writes = report.get("writes") or []
        self._append(
            "SYSTEM",
            f"Generated {len(writes)} dialogue artifacts; restarting Lua worker.",
        )
        self.restart()

    def generate_semantic_source(self, source_path: Path) -> None:
        """Generate approved artifacts, then restart the existing worker."""
        report = self.authoring_service.generate_semantic_source(source_path)
        self.flow_editor.show_source_report(report)
        self._set_text(self.inspector, pretty(report))
        self._set_text(self.trace, pretty(report))
        if report.get("ok") is not True:
            diagnostics = report.get("diagnostics") or []
            message = diagnostics[0].get("message") if diagnostics else "generation failed"
            self._append("SYSTEM", f"Source generation rejected: {message}")
            return
        self._append(
            "SYSTEM",
            f"Generated {len(report.get('writes', []))} files; restarting Lua worker.",
        )
        self.restart()

    def preview_interaction_spec(self, spec: dict[str, Any]) -> dict[str, Any]:
        """Preview a configured Studio interaction through the embedded builder."""

        report = self.authoring_service.preview_interaction_spec(
            spec,
            production_catalog=self._production_catalog,
        )
        self._set_text(self.inspector, pretty(report))
        self._set_text(self.trace, pretty(report))
        return report

    def generate_interaction_spec(self, spec: dict[str, Any]) -> None:
        """Write an approved InteractionSpec, then restart the real Lua worker."""

        report = self.authoring_service.generate_interaction_spec(
            spec,
            approved=True,
            production_catalog=self._production_catalog,
        )
        self.interaction_composer.show_generation(report)
        self._set_text(self.inspector, pretty(report))
        self._set_text(self.trace, pretty(report))
        if report.get("ok") is not True:
            diagnostics = report.get("diagnostics") or []
            message = diagnostics[0].get("message") if diagnostics else "generation failed"
            self._append("SYSTEM", f"Interaction generation rejected: {message}")
            return
        self._append(
            "SYSTEM",
            f"Generated {len(report.get('writes', []))} interaction artifacts; restarting Lua worker.",
        )
        self.restart()

    def generate_workflow(
        self,
        source_id: str,
        block_ids: list[str],
        interaction_spec: dict[str, Any] | None = None,
    ) -> None:
        """Generate the approved in-app workflow through the shared service."""
        report = self.authoring_service.generate_workflow(
            source_id,
            block_ids,
            approved=True,
            production_catalog=self._production_catalog,
            interaction_spec=interaction_spec,
        )
        self.workflow_pane.show_generation(report)
        self._set_text(self.inspector, pretty(report))
        self._set_text(self.trace, pretty(report))
        if report.get("ok") is not True:
            diagnostics = report.get("diagnostics") or []
            message = diagnostics[0].get("message") if diagnostics else "workflow generation failed"
            self._append("SYSTEM", f"Workflow generation rejected: {message}")
            return
        self._append(
            "SYSTEM",
            f"Generated {len(report.get('writes', []))} artifacts; restarting Lua worker.",
        )
        self.restart()

    def set_language(self) -> None:
        if not self.session.ready or self.busy:
            return
        selected = self.language_var.get().strip().upper()

        def finish(response: dict[str, Any]) -> None:
            self.scenario.setdefault("runtime", {})["language"] = selected
            self._set_status(f"Ready · language {response.get('language', selected)}")
            self._show_response(response)
            self._append("SYSTEM", f"Production translation language set to {selected}.")

        self._start_operation(lambda worker: worker.set_language(selected), finish)

    def inspect_live_worker(self) -> None:
        """Return to the real-worker conversation surface after a build."""
        self.main_tabs.select(self.simulation_tab)
        self._append("SYSTEM", "Live worker inspection is ready in the Simulation tab.")

    def restart(self) -> None:
        if not self.session.ready or self.busy:
            return

        def finish(response: dict[str, Any]) -> None:
            self._show_response(response)
            self._append("SYSTEM", "Lua worker restarted and the scenario was restored.")

        self._start_operation(lambda worker: worker.restart(), finish)

    def close(self) -> None:
        if self.closed:
            return
        self.closed = True
        self.session.close()
        self.root.destroy()


def run_gui(arguments: argparse.Namespace) -> int:
    try:
        import tkinter as tk
    except ImportError as error:
        print(f"semantic harness GUI unavailable: install Tk or use --no-gui ({error})", file=sys.stderr)
        return 2
    try:
        root = tk.Tk()
    except tk.TclError as error:
        print(f"semantic harness GUI unavailable: {error}; use --no-gui or run with a display", file=sys.stderr)
        return 2
    try:
        SemanticHarnessApp(root, arguments)
        root.mainloop()
    except (HarnessError, ConfigurationError, OSError, ValueError) as error:
        print(f"semantic harness GUI error: {error}", file=sys.stderr)
        try:
            root.destroy()
        except tk.TclError:
            pass
        return 2
    return 0
