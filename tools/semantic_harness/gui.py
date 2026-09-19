"""Tk adapter for the real-Lua semantic dialogue worker."""

from __future__ import annotations

import argparse
import sys
from concurrent.futures import Future
from pathlib import Path
from typing import Any, Callable

from .config import ConfigurationError
from .rendering import pretty
from .scenario import load_scenario, save_scenario
from .settings_dialog import open_runtime_settings as show_runtime_settings
from .transcript import TranscriptBuffer
from .worker import HarnessError, LuaSemanticWorker
from .worker_session import WorkerReady, WorkerResult, WorkerSession


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
        self.root.title("Project Hoomans Semantic Lab")
        self.root.geometry("1180x800")
        self.scenario_path = Path(arguments.scenario) if arguments.scenario else None
        self.scenario = load_scenario(self.scenario_path)
        if arguments.language:
            self.scenario.setdefault("runtime", {})["language"] = arguments.language.upper()
        self.session = WorkerSession(
            lambda: LuaSemanticWorker(self.scenario, **self._worker_kwargs())
        )
        self.closed = False
        self.busy = False
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
        container = ttk.Frame(self.root, padding=8)
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
        self.input_var = self._tk.StringVar()
        input_box = ttk.Entry(transcript_frame, textvariable=self.input_var)
        input_box.grid(row=1, column=0, sticky="ew", padx=6, pady=(0, 6))
        input_box.bind("<Return>", lambda _: self.submit())
        self.send_button = ttk.Button(transcript_frame, text="Send", command=self.submit)
        self.send_button.grid(row=2, column=0, sticky="e", padx=6, pady=(0, 6))

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
        self.trace = ScrolledText(right, wrap="none", state="disabled")
        self.trace.grid(row=0, column=0, sticky="nsew", padx=6, pady=6)

        self._append("SYSTEM", "Window ready. Starting the isolated Lua worker…")
        self._set_controls(False)

    def _set_controls(self, enabled: bool) -> None:
        state = "normal" if enabled and not self.busy else "disabled"
        for button in (
            self.send_button,
            self.reset_button,
            self.load_button,
            self.settings_button,
            self.save_button,
            self.snapshot_button,
        ):
            button.configure(state=state)
        self.language_box.configure(state="readonly" if enabled and not self.busy else "disabled")
        self.restart_button.configure(
            state="normal" if self.session.ready and not self.busy else "disabled"
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
        self._set_text(self.trace, pretty(result.capabilities))

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

    def submit(self) -> None:
        value = self.input_var.get().strip()
        if not value or not self.session.ready or self.busy:
            return
        self.input_var.set("")

        def finish(response: dict[str, Any]) -> None:
            self._append("PLAYER", value)
            for message in response.get("messages", []):
                if message.get("speaker") == "npc":
                    payload = message.get("payload", {})
                    self._append("NPC", payload.get("fallback") or payload.get("text") or "")
            for call in response.get("toolCalls", []):
                self._append(
                    "TOOL/ACTION",
                    f"{call.get('label') or call.get('name')}"
                    f" [{call.get('name')}] · "
                    f"{call.get('status') or call.get('reason') or 'observed'}",
                )
            self._set_text(self.trace, pretty(response))

        self._start_operation(lambda worker: worker.input(value), finish)

    def reset(self) -> None:
        if not self.session.ready:
            return

        def finish(_: dict[str, Any]) -> None:
            self._set_text(self.transcript, "")
            self._set_text(self.trace, "")
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
            self._set_text(self.trace, pretty(response))
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
            lambda response: self._set_text(self.trace, pretty(response)),
        )

    def set_language(self) -> None:
        if not self.session.ready or self.busy:
            return
        selected = self.language_var.get().strip().upper()

        def finish(response: dict[str, Any]) -> None:
            self.scenario.setdefault("runtime", {})["language"] = selected
            self._set_status(f"Ready · language {response.get('language', selected)}")
            self._set_text(self.trace, pretty(response))
            self._append("SYSTEM", f"Production translation language set to {selected}.")

        self._start_operation(lambda worker: worker.set_language(selected), finish)

    def restart(self) -> None:
        if not self.session.ready or self.busy:
            return

        def finish(response: dict[str, Any]) -> None:
            self._set_text(self.trace, pretty(response))
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
