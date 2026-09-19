"""Runtime scenario settings form and its side-effect-free draft parser."""

from __future__ import annotations

from copy import deepcopy
import json
from pathlib import Path
from typing import Any, Callable, Mapping, Protocol

from .rendering import pretty
from .scenario import save_scenario, validate_scenario


class SettingsDialogHost(Protocol):
    """Narrow GUI callbacks and state required by the settings modal."""

    root: Any
    _tk: Any
    _ttk: Any
    _ScrolledText: Any
    _filedialog: Any
    _messagebox: Any
    scenario_path: Path | None
    scenario: dict[str, Any]
    worker_ready: bool
    busy: bool
    settings_window: Any | None
    language_var: Any
    trace: Any

    def _start_operation(self, operation: Callable[[Any], Any], callback: Callable[[Any], None]) -> bool: ...
    def _set_text(self, widget: Any, value: str) -> None: ...
    def _append(self, speaker: str, text: str) -> None: ...


def collect_scenario_settings(draft: dict[str, Any], values: Mapping[str, Any]) -> dict[str, Any]:
    """Build and validate an updated scenario from primitive form values."""

    def read_value(key: str) -> Any:
        return values[key]

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
    player_inventory = json_value("player.inventory")
    if not isinstance(player_inventory, dict):
        raise ValueError("player.inventory must be a JSON object")
    npc_inventory = json_value("npc.inventory")
    if not isinstance(npc_inventory, dict):
        raise ValueError("npc.inventory must be a JSON object")
    updated_player["inventory"] = player_inventory
    updated_npc["inventory"] = npc_inventory
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


def open_runtime_settings(host: SettingsDialogHost) -> None:
    """Open the modal editor for every configurable harness seam."""

    if not host.worker_ready or host.busy:
        return
    if host.settings_window is not None and host.settings_window.winfo_exists():
        host.settings_window.deiconify()
        host.settings_window.lift()
        host.settings_window.focus_force()
        return

    tk = host._tk
    ttk = host._ttk
    ScrolledText = host._ScrolledText
    dialog = tk.Toplevel(host.root)
    host.settings_window = dialog
    dialog.title("Mock runtime settings")
    dialog.geometry("900x700")
    dialog.minsize(760, 560)
    dialog.transient(host.root)
    dialog.columnconfigure(0, weight=1)
    dialog.rowconfigure(0, weight=1)

    def close_dialog() -> None:
        if dialog.winfo_exists():
            try:
                dialog.grab_release()
            except tk.TclError:
                pass
            dialog.destroy()
        host.settings_window = None

    dialog.protocol("WM_DELETE_WINDOW", close_dialog)

    draft = deepcopy(host.scenario)
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

    def collect() -> dict[str, Any]:
        values: dict[str, Any] = {}
        for key, value in variables.items():
            if hasattr(value, "get") and not isinstance(value, ScrolledText):
                values[key] = value.get()
            else:
                values[key] = value.get("1.0", "end").strip()
        return collect_scenario_settings(draft, values)

    def apply(save_after: bool = False) -> None:
        try:
            updated = collect()
        except (TypeError, ValueError) as error:
            host._messagebox.showerror("Mock runtime settings", str(error), parent=dialog)
            return
        destination = host.scenario_path
        if save_after and destination is None:
            selected = host._filedialog.asksaveasfilename(
                parent=dialog,
                title="Save semantic scenario",
                defaultextension=".json",
                filetypes=[("JSON scenarios", "*.json"), ("All files", "*")],
            )
            if not selected:
                return
            destination = Path(selected)

        def finish(response: dict[str, Any]) -> None:
            host.scenario = updated
            host.language_var.set(updated["runtime"]["language"])
            host._set_text(host.trace, pretty(response))
            host._append("SYSTEM", "Applied mock runtime settings to the Lua worker.")
            if save_after and destination is not None:
                try:
                    save_scenario(destination, updated)
                except (OSError, TypeError, ValueError) as error:
                    host._messagebox.showerror("Scenario save error", str(error), parent=dialog)
                    return
                host.scenario_path = destination
                host._append("SYSTEM", f"Saved mock runtime scenario to {destination}")
            close_dialog()

        if not host._start_operation(lambda worker: worker.configure(updated), finish):
            return

    ttk.Button(footer, text="Cancel", command=close_dialog).grid(row=0, column=1, padx=6)
    ttk.Button(footer, text="Apply", command=apply).grid(row=0, column=2, padx=6)
    ttk.Button(footer, text="Apply & Save", command=lambda: apply(True)).grid(row=0, column=3)
    dialog.grab_set()
    dialog.focus_force()
