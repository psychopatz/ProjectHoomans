"""Tkinter chat UI and CLI for the real-Lua semantic dialogue harness."""

from __future__ import annotations

import argparse
from copy import deepcopy
import json
import sys
from concurrent.futures import Future, ThreadPoolExecutor
from pathlib import Path
from typing import Any, Callable

if __package__ in {None, ""}:
    # Keep direct `python tools/semantic_harness/app.py` useful for debugging;
    # the launcher still prefers package-module execution from any cwd.
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
    from tools.semantic_harness.config import ConfigurationError
    from tools.semantic_harness.doctor import run_doctor
    from tools.semantic_harness.process import install_shutdown_handler
    from tools.semantic_harness.runner import detect_conflicts, load_case, run_case
    from tools.semantic_harness.scenario import load_scenario, save_scenario, validate_scenario
    from tools.semantic_harness.worker import HarnessError, LuaSemanticWorker
else:
    from .config import ConfigurationError
    from .doctor import run_doctor
    from .process import install_shutdown_handler
    from .runner import detect_conflicts, load_case, run_case
    from .scenario import load_scenario, save_scenario, validate_scenario
    from .worker import HarnessError, LuaSemanticWorker


def pretty(value: Any) -> str:
    return json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True)


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
        self.worker: LuaSemanticWorker | None = None
        self.executor = ThreadPoolExecutor(max_workers=1, thread_name_prefix="semantic-harness")
        self.closed = False
        self.busy = False
        self.settings_window: Any | None = None
        self._future: Future[Any] | None = None
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
            state="normal" if self.worker is not None and not self.busy else "disabled"
        )

    def _set_status(self, value: str) -> None:
        if hasattr(self, "status_var"):
            self.status_var.set(value)

    def _append(self, speaker: str, text: str) -> None:
        self.transcript.configure(state="normal")
        self.transcript.insert("end", f"{speaker}: {text}\n\n")
        self.transcript.see("end")
        self.transcript.configure(state="disabled")

    def _set_text(self, widget: Any, value: str) -> None:
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

    def _create_worker(self) -> tuple[LuaSemanticWorker, dict[str, Any]]:
        worker = LuaSemanticWorker(self.scenario, **self._worker_kwargs())
        if self.closed:
            worker.close()
            raise HarnessError("GUI closed while Lua worker was starting")
        capabilities = worker.capabilities()
        if self.closed:
            worker.close()
            raise HarnessError("GUI closed while Lua worker was starting")
        return worker, capabilities

    def _start_worker(self) -> None:
        if self.closed:
            return
        self._future = self.executor.submit(self._create_worker)
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

    def _worker_ready(self, result: tuple[LuaSemanticWorker, dict[str, Any]]) -> None:
        worker, capabilities = result
        self.worker = worker
        self._set_status(f"Ready · Lua PID {worker.status().get('pid')}")
        self._set_controls(True)
        self._append("SYSTEM", "Lua worker ready. Production semantic modules are loaded.")
        self._set_text(self.trace, pretty(capabilities))

    def _start_operation(self, operation: Callable[[], Any], callback: Callable[[Any], None]) -> bool:
        if self.closed or self.worker is None or self.busy:
            return False
        self.busy = True
        self._set_status("Working…")
        self._set_controls(False)
        self._future = self.executor.submit(operation)
        self._poll_future(self._future, self._operation_finished(callback))
        return True

    def _operation_finished(self, callback: Callable[[Any], None]) -> Callable[[Any], None]:
        def finish(result: Any) -> None:
            self._set_controls(True)
            if self.worker is not None:
                self._set_status(f"Ready · Lua PID {self.worker.status().get('pid')}")
            callback(result)

        return finish

    def _show_operation_error(self, error: Exception) -> None:
        self.busy = False
        self._set_controls(self.worker is not None)
        self._set_status("Worker error")
        self._set_text(self.trace, str(error))
        self._messagebox.showerror("Harness error", str(error))

    def submit(self) -> None:
        value = self.input_var.get().strip()
        if not value or self.worker is None or self.busy:
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

        self._start_operation(lambda: self.worker.input(value), finish)

    def reset(self) -> None:
        if self.worker is None:
            return

        def finish(_: dict[str, Any]) -> None:
            self._set_text(self.transcript, "")
            self._set_text(self.trace, "")
            self._append("SYSTEM", "Scenario reset.")

        self._start_operation(self.worker.reset, finish)

    def load(self) -> None:
        filename = self._filedialog.askopenfilename(
            title="Load semantic scenario",
            filetypes=[("JSON scenarios", "*.json"), ("All files", "*")],
        )
        if not filename or self.worker is None or self.busy:
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

        self._start_operation(lambda: self.worker.configure(scenario), finish)

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
        """Open the modal editor for every configurable harness seam."""

        if self.worker is None or self.busy:
            return
        if self.settings_window is not None and self.settings_window.winfo_exists():
            self.settings_window.deiconify()
            self.settings_window.lift()
            self.settings_window.focus_force()
            return

        tk = self._tk
        ttk = self._ttk
        ScrolledText = self._ScrolledText
        dialog = tk.Toplevel(self.root)
        self.settings_window = dialog
        dialog.title("Mock runtime settings")
        dialog.geometry("900x700")
        dialog.minsize(760, 560)
        dialog.transient(self.root)
        dialog.columnconfigure(0, weight=1)
        dialog.rowconfigure(0, weight=1)

        def close_dialog() -> None:
            if dialog.winfo_exists():
                try:
                    dialog.grab_release()
                except tk.TclError:
                    pass
                dialog.destroy()
            self.settings_window = None

        dialog.protocol("WM_DELETE_WINDOW", close_dialog)

        draft = deepcopy(self.scenario)
        variables: dict[str, Any] = {}

        notebook = ttk.Notebook(dialog)
        notebook.grid(row=0, column=0, sticky="nsew", padx=10, pady=10)

        def page(title: str) -> Any:
            frame = ttk.Frame(notebook, padding=12)
            frame.columnconfigure(1, weight=1)
            notebook.add(frame, text=title)
            return frame

        def text_field(parent: Any, row: int, key: str, label: str, value: Any) -> None:
            variables[key] = tk.StringVar(value="" if value is None else str(value))
            ttk.Label(parent, text=label).grid(row=row, column=0, sticky="w", padx=(0, 10), pady=4)
            ttk.Entry(parent, textvariable=variables[key], width=32).grid(
                row=row, column=1, sticky="ew", pady=4
            )

        def check_field(parent: Any, row: int, key: str, label: str, value: Any) -> None:
            variables[key] = tk.BooleanVar(value=bool(value))
            ttk.Checkbutton(parent, text=label, variable=variables[key]).grid(
                row=row, column=0, columnspan=2, sticky="w", pady=4
            )

        def combo_field(
            parent: Any,
            row: int,
            key: str,
            label: str,
            value: Any,
            values: tuple[str, ...],
        ) -> None:
            variables[key] = tk.StringVar(value=str(value or values[0]))
            ttk.Label(parent, text=label).grid(row=row, column=0, sticky="w", padx=(0, 10), pady=4)
            ttk.Combobox(
                parent,
                textvariable=variables[key],
                values=values,
                state="readonly",
                width=29,
            ).grid(row=row, column=1, sticky="ew", pady=4)

        runtime = draft.setdefault("runtime", {})
        world = draft.setdefault("world", {})
        player = draft.setdefault("player", {})
        npc = draft.setdefault("npc", {})
        relationship = npc.setdefault("relationship", {})
        conversation = draft.setdefault("conversation", {})

        runtime_page = page("Runtime")
        combo_field(runtime_page, 0, "runtime.mode", "Network mode", runtime.get("mode"), ("singleplayer", "multiplayer"))
        combo_field(runtime_page, 1, "runtime.language", "Language", runtime.get("language"), ("EN", "TL"))
        check_field(runtime_page, 2, "runtime.llmEnabled", "LLM bridge enabled", runtime.get("llmEnabled"))
        check_field(
            runtime_page,
            3,
            "runtime.providerAvailable",
            "LLM provider available",
            runtime.get("providerAvailable"),
        )
        ttk.Label(
            runtime_page,
            text="These values control the headless engine seams; production semantic modules remain loaded.",
            wraplength=560,
        ).grid(row=4, column=0, columnspan=2, sticky="w", pady=(14, 4))

        world_page = page("World")
        for row, key in enumerate(
            ("hunger", "thirst", "fatigue", "stress", "boredom", "panic", "timeOfDay", "worldAgeHours")
        ):
            text_field(world_page, row, f"world.{key}", key, world.get(key))
        combo_field(world_page, 8, "world.weather", "Weather", world.get("weather"), ("clear", "rain", "fog"))
        ttk.Label(
            world_page,
            text="Needs use the game-style 0–1 scale. Time of day is in hours; world age is in hours.",
            wraplength=560,
        ).grid(row=9, column=0, columnspan=2, sticky="w", pady=(14, 4))

        actors_page = page("Player / NPC")
        actors_page.columnconfigure(1, weight=1)
        ttk.Label(actors_page, text="Player", font=("TkDefaultFont", 10, "bold")).grid(
            row=0, column=0, columnspan=2, sticky="w", pady=(0, 4)
        )
        for row, key in enumerate(("characterUUID", "forename", "surname", "displayName"), start=1):
            text_field(actors_page, row, f"player.{key}", key, player.get(key))
        npc_start = 6
        ttk.Label(actors_page, text="NPC", font=("TkDefaultFont", 10, "bold")).grid(
            row=npc_start, column=0, columnspan=2, sticky="w", pady=(12, 4)
        )
        for offset, key in enumerate(("npcID", "forename", "surname", "identityState", "relationshipState"), start=1):
            text_field(actors_page, npc_start + offset, f"npc.{key}", key, npc.get(key))
        text_field(actors_page, npc_start + 7, "relationship.approval", "approval", relationship.get("approval", 0))
        text_field(actors_page, npc_start + 8, "relationship.respect", "respect", relationship.get("respect", 0))
        text_field(actors_page, npc_start + 9, "relationship.familiarity", "familiarity", relationship.get("familiarity", 0))
        text_field(actors_page, npc_start + 10, "relationship.revision", "revision", relationship.get("revision", 1))
        combo_field(
            actors_page,
            npc_start + 11,
            "relationship.identityTrust",
            "identity trust",
            relationship.get("identityTrust", "unknown"),
            ("unknown", "trusted", "untrustworthy"),
        )
        traits = ScrolledText(actors_page, height=4, width=38, wrap="none")
        traits.grid(row=npc_start + 12, column=1, sticky="ew", pady=4)
        traits.insert("1.0", pretty(npc.get("traits", [])))
        variables["npc.traits"] = traits
        ttk.Label(actors_page, text="traits (JSON)").grid(row=npc_start + 12, column=0, sticky="nw", padx=(0, 10), pady=4)
        personality = ScrolledText(actors_page, height=4, width=38, wrap="none")
        personality.grid(row=npc_start + 13, column=1, sticky="ew", pady=4)
        personality.insert("1.0", pretty(npc.get("personality", {})))
        variables["npc.personality"] = personality
        ttk.Label(actors_page, text="personality (JSON)").grid(row=npc_start + 13, column=0, sticky="nw", padx=(0, 10), pady=4)

        inventory_page = page("Inventories")
        inventory_page.columnconfigure(0, weight=1)
        inventory_page.columnconfigure(1, weight=1)
        inventory_page.rowconfigure(1, weight=1)
        ttk.Label(
            inventory_page,
            text="Player inventory (native-like projection)",
            font=("TkDefaultFont", 10, "bold"),
        ).grid(row=0, column=0, sticky="w", padx=(0, 8), pady=(0, 6))
        ttk.Label(
            inventory_page,
            text="NPC inventory (authoritative compact model)",
            font=("TkDefaultFont", 10, "bold"),
        ).grid(row=0, column=1, sticky="w", padx=(8, 0), pady=(0, 6))
        player_inventory = ScrolledText(inventory_page, height=22, width=42, wrap="none")
        player_inventory.grid(row=1, column=0, sticky="nsew", padx=(0, 8))
        player_inventory.insert("1.0", pretty(player.get("inventory", {})))
        variables["player.inventory"] = player_inventory
        npc_inventory = ScrolledText(inventory_page, height=22, width=42, wrap="none")
        npc_inventory.grid(row=1, column=1, sticky="nsew", padx=(8, 0))
        npc_inventory.insert("1.0", pretty(npc.get("inventory", {})))
        variables["npc.inventory"] = npc_inventory
        ttk.Label(
            inventory_page,
            text=(
                "Edit complete JSON inventory projections here. Items may include itemID, fullType, displayName, "
                "stack, condition/state, container, equipment flags, and marketSense classification."
            ),
            wraplength=760,
        ).grid(row=2, column=0, columnspan=2, sticky="w", pady=(10, 0))

        conversation_page = page("Conversation")
        text_field(conversation_page, 0, "conversation.topic", "topic", conversation.get("topic"))
        text_field(conversation_page, 1, "conversation.token", "token", conversation.get("token"))
        ttk.Label(
            conversation_page,
            text="The token lets tests emulate a conversation lease/lifecycle without opening the game.",
            wraplength=560,
        ).grid(row=2, column=0, columnspan=2, sticky="w", pady=(14, 4))

        actions_page = page("Actions / Translations")
        actions_page.columnconfigure(1, weight=1)
        ttk.Label(
            actions_page,
            text="Command responses (JSON) are the mocked native action boundary. Add future commands here without code changes.",
            wraplength=600,
        ).grid(row=0, column=0, columnspan=2, sticky="w", pady=(0, 6))
        commands = ScrolledText(actions_page, height=10, width=70, wrap="none")
        commands.grid(row=1, column=0, columnspan=2, sticky="nsew", pady=(0, 14))
        actions_page.rowconfigure(1, weight=1)
        commands.insert("1.0", pretty(runtime.get("commandResponses", {})))
        variables["runtime.commandResponses"] = commands
        ttk.Label(
            actions_page,
            text="Native translation overrides (JSON) are optional test-only getText values keyed by translation ID.",
            wraplength=600,
        ).grid(row=2, column=0, columnspan=2, sticky="w", pady=(0, 6))
        translations = ScrolledText(actions_page, height=10, width=70, wrap="none")
        translations.grid(row=3, column=0, columnspan=2, sticky="nsew")
        actions_page.rowconfigure(3, weight=1)
        translations.insert("1.0", pretty(runtime.get("nativeTranslations", {})))
        variables["runtime.nativeTranslations"] = translations

        footer = ttk.Frame(dialog)
        footer.grid(row=1, column=0, sticky="ew", padx=10, pady=(0, 10))
        footer.columnconfigure(0, weight=1)
        ttk.Label(
            footer,
            text="Apply updates the live Lua worker. Save scenario writes the complete editable state to JSON.",
        ).grid(row=0, column=0, sticky="w")

        def read_value(key: str) -> Any:
            value = variables[key]
            if hasattr(value, "get") and not isinstance(value, ScrolledText):
                return value.get()
            return value.get("1.0", "end").strip()

        def number_value(key: str) -> float:
            try:
                return float(read_value(key))
            except (TypeError, ValueError) as error:
                raise ValueError(f"{key} must be a number") from error

        def json_value(key: str) -> Any:
            try:
                return json.loads(read_value(key))
            except json.JSONDecodeError as error:
                raise ValueError(f"{key} must contain valid JSON: {error.msg}") from error

        def collect() -> dict[str, Any]:
            updated = deepcopy(draft)
            updated_runtime = updated.setdefault("runtime", {})
            updated_world = updated.setdefault("world", {})
            updated_player = updated.setdefault("player", {})
            updated_npc = updated.setdefault("npc", {})
            updated_relationship = updated_npc.setdefault("relationship", {})
            updated_conversation = updated.setdefault("conversation", {})
            for key in ("mode", "language"):
                updated_runtime[key] = str(read_value(f"runtime.{key}")).strip()
            for key in ("llmEnabled", "providerAvailable"):
                updated_runtime[key] = bool(read_value(f"runtime.{key}"))
            for key in ("hunger", "thirst", "fatigue", "stress", "boredom", "panic", "timeOfDay", "worldAgeHours"):
                updated_world[key] = number_value(f"world.{key}")
            updated_world["weather"] = str(read_value("world.weather")).strip()
            for key in ("characterUUID", "forename", "surname", "displayName"):
                updated_player[key] = str(read_value(f"player.{key}")).strip()
            for key in ("npcID", "forename", "surname", "identityState", "relationshipState"):
                updated_npc[key] = str(read_value(f"npc.{key}")).strip()
            for key in ("approval", "respect", "familiarity", "revision"):
                updated_relationship[key] = number_value(f"relationship.{key}")
                if key == "revision":
                    updated_relationship[key] = int(updated_relationship[key])
            updated_relationship["identityTrust"] = str(read_value("relationship.identityTrust")).strip()
            updated_npc["traits"] = json_value("npc.traits")
            updated_npc["personality"] = json_value("npc.personality")
            player_inventory_value = json_value("player.inventory")
            if not isinstance(player_inventory_value, dict):
                raise ValueError("player.inventory must be a JSON object")
            npc_inventory_value = json_value("npc.inventory")
            if not isinstance(npc_inventory_value, dict):
                raise ValueError("npc.inventory must be a JSON object")
            updated_player["inventory"] = player_inventory_value
            updated_npc["inventory"] = npc_inventory_value
            for key in ("topic", "token"):
                updated_conversation[key] = str(read_value(f"conversation.{key}")).strip()
            command_responses = json_value("runtime.commandResponses")
            if not isinstance(command_responses, dict):
                raise ValueError("runtime.commandResponses must be a JSON object")
            translations = json_value("runtime.nativeTranslations")
            if not isinstance(translations, dict):
                raise ValueError("runtime.nativeTranslations must be a JSON object")
            updated_runtime["commandResponses"] = command_responses
            updated_runtime["nativeTranslations"] = translations
            validate_scenario(updated)
            return updated

        def apply(save_after: bool = False) -> None:
            try:
                updated = collect()
            except (TypeError, ValueError) as error:
                self._messagebox.showerror("Mock runtime settings", str(error), parent=dialog)
                return
            destination = self.scenario_path
            if save_after and destination is None:
                selected = self._filedialog.asksaveasfilename(
                    parent=dialog,
                    title="Save semantic scenario",
                    defaultextension=".json",
                    filetypes=[("JSON scenarios", "*.json"), ("All files", "*")],
                )
                if not selected:
                    return
                destination = Path(selected)

            def finish(response: dict[str, Any]) -> None:
                self.scenario = updated
                self.language_var.set(updated["runtime"]["language"])
                self._set_text(self.trace, pretty(response))
                self._append("SYSTEM", "Applied mock runtime settings to the Lua worker.")
                if save_after and destination is not None:
                    try:
                        save_scenario(destination, updated)
                    except (OSError, TypeError, ValueError) as error:
                        self._messagebox.showerror("Scenario save error", str(error), parent=dialog)
                        return
                    self.scenario_path = destination
                    self._append("SYSTEM", f"Saved mock runtime scenario to {destination}")
                close_dialog()

            if not self._start_operation(lambda: self.worker.configure(updated), finish):
                return

        ttk.Button(footer, text="Cancel", command=close_dialog).grid(row=0, column=1, padx=6)
        ttk.Button(footer, text="Apply", command=apply).grid(row=0, column=2, padx=6)
        ttk.Button(footer, text="Apply & Save", command=lambda: apply(True)).grid(row=0, column=3)
        dialog.grab_set()
        dialog.focus_force()

    def show_snapshot(self) -> None:
        if self.worker is None:
            return
        self._start_operation(lambda: self.worker.snapshot(), lambda response: self._set_text(self.trace, pretty(response)))

    def set_language(self) -> None:
        if self.worker is None or self.busy:
            return
        selected = self.language_var.get().strip().upper()

        def finish(response: dict[str, Any]) -> None:
            self.scenario.setdefault("runtime", {})["language"] = selected
            self._set_status(f"Ready · language {response.get('language', selected)}")
            self._set_text(self.trace, pretty(response))
            self._append("SYSTEM", f"Production translation language set to {selected}.")

        self._start_operation(lambda: self.worker.set_language(selected), finish)

    def restart(self) -> None:
        if self.worker is None or self.busy:
            return

        def finish(response: dict[str, Any]) -> None:
            self._set_text(self.trace, pretty(response))
            self._append("SYSTEM", "Lua worker restarted and the scenario was restored.")

        self._start_operation(self.worker.restart, finish)

    def close(self) -> None:
        if self.closed:
            return
        self.closed = True
        worker = self.worker
        self.worker = None
        if worker is not None:
            self.executor.submit(worker.close)
        self.executor.shutdown(wait=False, cancel_futures=True)
        self.root.destroy()


def _print_result(value: Any, jsonl: bool) -> None:
    if jsonl:
        print(json.dumps(value, ensure_ascii=False, separators=(",", ":")))
    else:
        print(pretty(value))


def cli(arguments: argparse.Namespace) -> int:
    try:
        worker_kwargs = {
            "lua_bin": arguments.lua,
            "repository": Path(arguments.repository) if arguments.repository else None,
            "core_repository": Path(arguments.core_repository) if arguments.core_repository else None,
            "startup_timeout": arguments.startup_timeout,
            "request_timeout": arguments.timeout,
            "shutdown_timeout": arguments.shutdown_timeout,
        }
        if arguments.case:
            report = run_case(load_case(Path(arguments.case)), **worker_kwargs)
            _print_result(report.as_dict(), arguments.jsonl)
            return 0 if report.conflicts == [] else 3
        scenario = load_scenario(Path(arguments.scenario) if arguments.scenario else None)
        if arguments.language:
            scenario.setdefault("runtime", {})["language"] = arguments.language.upper()
        with LuaSemanticWorker(
            scenario,
            **worker_kwargs,
        ) as worker:
            turns: list[dict[str, Any]] = []
            if arguments.snapshot:
                _print_result(worker.snapshot(), arguments.jsonl)
            for value in arguments.input:
                result = worker.input(value)
                turns.append(result)
                _print_result(result, arguments.jsonl)
            if arguments.interactive:
                for line in sys.stdin:
                    value = line.strip()
                    if value:
                        result = worker.input(value)
                        turns.append(result)
                        _print_result(result, arguments.jsonl)
            if arguments.audit:
                conflicts = detect_conflicts(turns)
                _print_result(
                    {"type": "audit", "ok": not conflicts, "conflicts": conflicts},
                    arguments.jsonl,
                )
    except (HarnessError, ConfigurationError, OSError, ValueError) as error:
        print(f"semantic harness error: {error}", file=sys.stderr)
        return 2
    return 0


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scenario", help="JSON scenario file")
    parser.add_argument("--case", help="JSON replay case with scenario and inputs")
    parser.add_argument("--lua", help="Lua executable; defaults to PNC_HARNESS_LUA, lua, or luajit")
    parser.add_argument("--repository", help="Project Hoomans repository")
    parser.add_argument("--core-repository", help="PsychopatzCore repository")
    parser.add_argument("--no-gui", "--cli", dest="no_gui", action="store_true", help="run inputs and print JSON")
    parser.add_argument("--interactive", action="store_true", help="read one conversation input per stdin line")
    parser.add_argument("--jsonl", action="store_true", help="emit compact one-record-per-line JSON")
    parser.add_argument("--audit", action="store_true", help="emit a bounded conflict audit after turns")
    parser.add_argument("--doctor", action="store_true", help="run bounded headless runtime diagnostics")
    parser.add_argument("--doctor-json", action="store_true", help="emit doctor diagnostics as one JSON record")
    parser.add_argument("--snapshot", action="store_true")
    parser.add_argument("--language", choices=("EN", "TL"), help="production translation language")
    parser.add_argument("--input", action="append", default=[], help="chat input; repeatable")
    parser.add_argument("--timeout", type=float, default=5.0, help="per-request timeout in seconds")
    parser.add_argument("--startup-timeout", type=float, default=8.0, help="worker startup timeout in seconds")
    parser.add_argument("--shutdown-timeout", type=float, default=1.0, help="worker shutdown timeout in seconds")
    return parser


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


def main() -> int:
    install_shutdown_handler()
    arguments = _parser().parse_args()
    if arguments.doctor or arguments.doctor_json:
        return run_doctor(
            repository=arguments.repository,
            core_repository=arguments.core_repository,
            lua_bin=arguments.lua,
            startup_timeout=arguments.startup_timeout,
            request_timeout=arguments.timeout,
            json_output=arguments.doctor_json,
        )
    if arguments.no_gui:
        return cli(arguments)
    return run_gui(arguments)


if __name__ == "__main__":
    raise SystemExit(main())
