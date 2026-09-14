#!/usr/bin/env python3
"""Tkinter CRUD manager for Project Hoomans unique NPC definitions."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any, Optional

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import tkinter as tk
from tkinter import filedialog, messagebox, ttk

from unique_npc_manager.runtime_export import generated_definition_id
from unique_npc_manager.schema import ConversionError, build_payload, encode, output_name
from unique_npc_manager.storage import (
    DraftStore,
    RuntimeDefinitionStore,
    StorageError,
    atomic_write,
)


CONFIG_NAME = "ProjectHoomans_UniqueNPCManager.json"


def project_root() -> Path:
    return Path(__file__).resolve().parents[2]


def default_paths() -> dict[str, str]:
    root = project_root()
    return {
        "hoomans_root": str(Path.home() / "Zomboid" / "Lua" / "Hoomans"),
        "runtime_root": str(
            root
            / "Contents"
            / "mods"
            / "ProjectHoomans"
            / "42.20"
            / "media"
            / "lua"
            / "shared"
            / "PNC"
            / "Generated"
            / "UniqueNPC"
        ),
    }


class UniqueNPCManager(tk.Tk):
    def __init__(self) -> None:
        super().__init__()
        self.title("Project Hoomans - Unique NPC Manager")
        self.geometry("1280x820")
        self.minsize(980, 620)

        self.settings = self._load_settings()
        self.draft_store = DraftStore(Path(self.settings["hoomans_root"]))
        self.runtime_store = RuntimeDefinitionStore(
            Path(self.settings["runtime_root"])
        )
        self.current_filename: Optional[str] = None
        self.current_definition: Optional[dict[str, Any]] = None
        self.dirty = False

        self.status_var = tk.StringVar(value="Ready")
        self.first_var = tk.StringVar()
        self.surname_var = tk.StringVar()
        self.gender_var = tk.StringVar(value="Male")
        self.id_var = tk.StringVar()
        self.archetype_var = tk.StringVar()
        self.faction_var = tk.StringVar()
        self.chance_var = tk.StringVar()
        self.hoomans_path_var = tk.StringVar(value=self.settings["hoomans_root"])
        self.runtime_path_var = tk.StringVar(value=self.settings["runtime_root"])

        self._build_style()
        self._build_toolbar()
        self._build_notebook()
        self._build_status_bar()
        self._refresh_all()

    def _build_style(self) -> None:
        style = ttk.Style(self)
        try:
            style.theme_use("clam")
        except tk.TclError:
            pass
        style.configure("Title.TLabel", font=("TkDefaultFont", 12, "bold"))
        style.configure("Error.TLabel", foreground="#a83232")
        style.configure("Ok.TLabel", foreground="#26733b")

    def _build_toolbar(self) -> None:
        bar = ttk.Frame(self, padding=(8, 8, 8, 4))
        bar.pack(fill="x")
        actions = [
            ("New", self.new_draft),
            ("Open", self.open_draft),
            ("Save", self.save_draft),
            ("Save As", self.save_as),
            ("Duplicate", self.duplicate_draft),
            ("Delete", self.delete_draft),
            ("Import", self.import_draft),
            ("Export Lua", self.export_current),
            ("Export All", self.export_all),
            ("Validate All", self.validate_all),
            ("Refresh", self._refresh_all),
        ]
        for label, command in actions:
            ttk.Button(bar, text=label, command=command).pack(side="left", padx=2)

    def _build_notebook(self) -> None:
        self.notebook = ttk.Notebook(self)
        self.notebook.pack(fill="both", expand=True, padx=8, pady=(0, 4))
        self.drafts_tab = ttk.Frame(self.notebook)
        self.runtime_tab = ttk.Frame(self.notebook)
        self.validation_tab = ttk.Frame(self.notebook)
        self.settings_tab = ttk.Frame(self.notebook)
        self.notebook.add(self.drafts_tab, text="Hoomans Files")
        self.notebook.add(self.runtime_tab, text="Runtime Definitions")
        self.notebook.add(self.validation_tab, text="Validation")
        self.notebook.add(self.settings_tab, text="Settings")
        self._build_drafts_tab()
        self._build_runtime_tab()
        self._build_validation_tab()
        self._build_settings_tab()

    def _build_drafts_tab(self) -> None:
        pane = ttk.Panedwindow(self.drafts_tab, orient="horizontal")
        pane.pack(fill="both", expand=True)
        left = ttk.Frame(pane, padding=4)
        right = ttk.Frame(pane, padding=(8, 4, 4, 4))
        pane.add(left, weight=1)
        pane.add(right, weight=3)

        columns = ("file", "name", "id", "state")
        self.draft_tree = ttk.Treeview(left, columns=columns, show="headings")
        headings = {"file": "File", "name": "Name", "id": "Definition ID", "state": "State"}
        widths = {"file": 150, "name": 150, "id": 180, "state": 100}
        for column in columns:
            self.draft_tree.heading(column, text=headings[column])
            self.draft_tree.column(column, width=widths[column], anchor="w")
        draft_scroll = ttk.Scrollbar(left, orient="vertical", command=self.draft_tree.yview)
        self.draft_tree.configure(yscrollcommand=draft_scroll.set)
        self.draft_tree.pack(side="left", fill="both", expand=True)
        draft_scroll.pack(side="right", fill="y")
        self.draft_tree.bind("<<TreeviewSelect>>", self._on_draft_selected)

        title = ttk.Label(right, text="Definition Editor", style="Title.TLabel")
        title.pack(anchor="w", pady=(0, 6))
        form = ttk.Frame(right)
        form.pack(fill="x")
        self._field(form, 0, 0, "First name", self.first_var)
        self._field(form, 0, 2, "Surname", self.surname_var)
        self._field(form, 1, 0, "Gender", self.gender_var, values=("Male", "Female"))
        self._field(form, 1, 2, "Definition ID", self.id_var)
        self._field(form, 2, 0, "Archetype", self.archetype_var)
        self._field(form, 2, 2, "Faction (optional)", self.faction_var)
        self._field(form, 3, 0, "Spawn chance", self.chance_var)
        ttk.Label(
            form,
            text="Blank faction leaves the NPC unbound; runtime may assign one.",
        ).grid(row=3, column=2, columnspan=2, sticky="w", padx=(8, 0), pady=4)
        for column in (1, 3):
            form.columnconfigure(column, weight=1)

        ttk.Label(right, text="Canonical definition JSON", style="Title.TLabel").pack(
            anchor="w", pady=(12, 4)
        )
        raw_frame = ttk.Frame(right)
        raw_frame.pack(fill="both", expand=True)
        self.raw_text = tk.Text(raw_frame, wrap="none", undo=True, font=("TkFixedFont", 10))
        raw_y = ttk.Scrollbar(raw_frame, orient="vertical", command=self.raw_text.yview)
        raw_x = ttk.Scrollbar(raw_frame, orient="horizontal", command=self.raw_text.xview)
        self.raw_text.configure(yscrollcommand=raw_y.set, xscrollcommand=raw_x.set)
        self.raw_text.grid(row=0, column=0, sticky="nsew")
        raw_y.grid(row=0, column=1, sticky="ns")
        raw_x.grid(row=1, column=0, sticky="ew")
        raw_frame.rowconfigure(0, weight=1)
        raw_frame.columnconfigure(0, weight=1)
        ttk.Label(
            right,
            text="The JSON editor preserves detailed itemState/modData metadata. Runtime output is generated as Lua.",
        ).pack(anchor="w", pady=(4, 0))

    def _field(
        self,
        parent: ttk.Frame,
        row: int,
        label_column: int,
        label: str,
        variable: tk.StringVar,
        values: Optional[tuple[str, ...]] = None,
    ) -> None:
        ttk.Label(parent, text=label).grid(
            row=row, column=label_column, sticky="w", padx=(0 if label_column == 0 else 8, 4), pady=4
        )
        if values:
            widget: tk.Widget = ttk.Combobox(
                parent, textvariable=variable, values=values, state="readonly", width=18
            )
        else:
            widget = ttk.Entry(parent, textvariable=variable)
        widget.grid(row=row, column=label_column + 1, sticky="ew", pady=4)

    def _build_runtime_tab(self) -> None:
        toolbar = ttk.Frame(self.runtime_tab, padding=4)
        toolbar.pack(fill="x")
        ttk.Button(toolbar, text="Rebuild Loader", command=self.rebuild_loader).pack(side="left")
        ttk.Button(toolbar, text="Delete Selected Lua", command=self.delete_runtime).pack(
            side="left", padx=5
        )
        ttk.Button(toolbar, text="Open Runtime Folder", command=self.open_runtime_folder).pack(
            side="left", padx=5
        )
        self.runtime_path_label = ttk.Label(toolbar, textvariable=self.runtime_path_var)
        self.runtime_path_label.pack(side="left", padx=12)

        body = ttk.Panedwindow(self.runtime_tab, orient="horizontal")
        body.pack(fill="both", expand=True, padx=4, pady=4)
        left = ttk.Frame(body)
        right = ttk.Frame(body, padding=8)
        body.add(left, weight=1)
        body.add(right, weight=2)
        self.runtime_tree = ttk.Treeview(
            left, columns=("module", "source", "status"), show="headings"
        )
        for column, heading, width in (
            ("module", "Lua module", 240),
            ("source", "Hoomans source", 180),
            ("status", "Status", 120),
        ):
            self.runtime_tree.heading(column, text=heading)
            self.runtime_tree.column(column, width=width, anchor="w")
        runtime_scroll = ttk.Scrollbar(left, orient="vertical", command=self.runtime_tree.yview)
        self.runtime_tree.configure(yscrollcommand=runtime_scroll.set)
        self.runtime_tree.pack(side="left", fill="both", expand=True)
        runtime_scroll.pack(side="right", fill="y")
        self.runtime_tree.bind("<<TreeviewSelect>>", self._on_runtime_selected)
        ttk.Label(right, text="Generated Lua", style="Title.TLabel").pack(anchor="w")
        self.runtime_text = tk.Text(right, wrap="none", state="disabled", font=("TkFixedFont", 10))
        runtime_text_scroll = ttk.Scrollbar(right, orient="vertical", command=self.runtime_text.yview)
        self.runtime_text.configure(yscrollcommand=runtime_text_scroll.set)
        self.runtime_text.pack(side="left", fill="both", expand=True, pady=(6, 0))
        runtime_text_scroll.pack(side="right", fill="y", pady=(6, 0))

    def _build_validation_tab(self) -> None:
        bar = ttk.Frame(self.validation_tab, padding=4)
        bar.pack(fill="x")
        ttk.Button(bar, text="Validate All", command=self.validate_all).pack(side="left")
        ttk.Button(bar, text="Repair Index", command=self.repair_index).pack(side="left", padx=5)
        self.validation_text = tk.Text(
            self.validation_tab, wrap="word", state="disabled", font=("TkFixedFont", 10)
        )
        self.validation_text.pack(fill="both", expand=True, padx=4, pady=4)

    def _build_settings_tab(self) -> None:
        frame = ttk.Frame(self.settings_tab, padding=12)
        frame.pack(fill="both", expand=True)
        ttk.Label(frame, text="Hoomans drafts folder", style="Title.TLabel").grid(
            row=0, column=0, sticky="w", pady=5
        )
        ttk.Entry(frame, textvariable=self.hoomans_path_var).grid(
            row=0, column=1, sticky="ew", padx=8, pady=5
        )
        ttk.Button(frame, text="Browse", command=self.choose_hoomans_folder).grid(
            row=0, column=2, pady=5
        )
        ttk.Label(frame, text="Generated runtime Lua folder", style="Title.TLabel").grid(
            row=1, column=0, sticky="w", pady=5
        )
        ttk.Entry(frame, textvariable=self.runtime_path_var).grid(
            row=1, column=1, sticky="ew", padx=8, pady=5
        )
        ttk.Button(frame, text="Browse", command=self.choose_runtime_folder).grid(
            row=1, column=2, pady=5
        )
        ttk.Button(frame, text="Save Settings", command=self.save_settings).grid(
            row=2, column=1, sticky="w", pady=12
        )
        ttk.Label(
            frame,
            text="The runtime folder must be inside the Project Hoomans mod's media/lua/shared tree for the game to load it.",
            wraplength=800,
        ).grid(row=3, column=0, columnspan=3, sticky="w")
        frame.columnconfigure(1, weight=1)

    def _build_status_bar(self) -> None:
        ttk.Label(self, textvariable=self.status_var, relief="sunken", anchor="w").pack(
            fill="x", side="bottom", padx=8, pady=(0, 8)
        )

    def _load_settings(self) -> dict[str, str]:
        settings = default_paths()
        path = Path.home() / "Zomboid" / "Lua" / CONFIG_NAME
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
            if isinstance(payload, dict):
                for key in settings:
                    if isinstance(payload.get(key), str) and payload[key].strip():
                        settings[key] = payload[key]
        except (OSError, json.JSONDecodeError):
            pass
        return settings

    def save_settings(self) -> None:
        self.settings = {
            "hoomans_root": self.hoomans_path_var.get().strip(),
            "runtime_root": self.runtime_path_var.get().strip(),
        }
        if not self.settings["hoomans_root"] or not self.settings["runtime_root"]:
            messagebox.showerror("Settings", "Both managed folders are required.")
            return
        path = Path.home() / "Zomboid" / "Lua" / CONFIG_NAME
        atomic_write(path, encode(self.settings))
        self.draft_store = DraftStore(Path(self.settings["hoomans_root"]))
        self.runtime_store = RuntimeDefinitionStore(Path(self.settings["runtime_root"]))
        self._refresh_all()
        self.status_var.set("Settings saved")

    def choose_hoomans_folder(self) -> None:
        selected = filedialog.askdirectory(initialdir=self.hoomans_path_var.get())
        if selected:
            self.hoomans_path_var.set(selected)

    def choose_runtime_folder(self) -> None:
        selected = filedialog.askdirectory(initialdir=self.runtime_path_var.get())
        if selected:
            self.runtime_path_var.set(selected)

    def _refresh_all(self) -> None:
        self.refresh_drafts()
        self.refresh_runtime()
        self.validate_all()

    def refresh_drafts(self) -> None:
        selected = self.current_filename
        for item in self.draft_tree.get_children():
            self.draft_tree.delete(item)
        for filename in self.draft_store.list_files():
            try:
                definition = self.draft_store.load(filename)
                normalized = build_payload(definition)["definition"]
                state = "Generated" if self.runtime_store.has_generated(normalized) else "Draft"
                self.draft_tree.insert(
                    "", "end", iid=filename,
                    values=(filename, normalized.get("displayName", ""), normalized.get("id", ""), state),
                )
            except (StorageError, ConversionError) as exc:
                self.draft_tree.insert(
                    "", "end", iid=filename,
                    values=(filename, "<invalid>", "", str(exc)),
                )
        if selected and self.draft_tree.exists(selected):
            self.draft_tree.selection_set(selected)
            self.draft_tree.focus(selected)

    def refresh_runtime(self) -> None:
        for item in self.runtime_tree.get_children():
            self.runtime_tree.delete(item)
        source_by_id: dict[str, str] = {}
        for filename in self.draft_store.list_files():
            try:
                definition = build_payload(self.draft_store.load(filename))["definition"]
                source_by_id[str(definition.get("uniqueDefinitionId"))] = filename
            except (StorageError, ConversionError):
                continue
        for path in sorted(self.runtime_store.root.glob("*.lua")):
            if path.name == "PNC_UniqueNPCDefinitions.lua" or ".bak." in path.name:
                continue
            content = path.read_text(encoding="utf-8", errors="replace")
            if "PNC_GENERATED_UNIQUE_NPC" not in content:
                continue
            identifier = generated_definition_id(path)
            source = source_by_id.get(identifier, "<missing source>")
            status = "Synced" if source != "<missing source>" else "Orphaned"
            self.runtime_tree.insert("", "end", iid=path.name, values=(path.name, source, status))

    def _on_draft_selected(self, _event: tk.Event) -> None:
        selection = self.draft_tree.selection()
        if not selection:
            return
        filename = selection[0]
        try:
            definition = self.draft_store.load(filename)
        except StorageError as exc:
            self.status_var.set(str(exc))
            return
        self.current_filename = filename
        self.current_definition = definition
        self.dirty = False
        self._show_definition(definition)
        self.status_var.set(f"Loaded {filename}")

    def _show_definition(self, definition: dict[str, Any]) -> None:
        identity = definition.get("identity") if isinstance(definition.get("identity"), dict) else {}
        survivor = identity.get("survivor") if isinstance(identity.get("survivor"), dict) else {}
        display = str(definition.get("displayName") or definition.get("name") or "")
        pieces = display.split()
        self.first_var.set(str(survivor.get("forename") or (pieces[0] if pieces else "")))
        self.surname_var.set(str(survivor.get("surname") or " ".join(pieces[1:])))
        self.gender_var.set("Female" if definition.get("isFemale") is True else "Male")
        self.id_var.set(str(definition.get("uniqueDefinitionId") or definition.get("id") or ""))
        self.archetype_var.set(str(definition.get("archetypeID") or ""))
        self.faction_var.set(str(definition.get("factionID") or ""))
        self.chance_var.set(str(definition.get("spawnChance") if definition.get("spawnChance") is not None else ""))
        self.raw_text.delete("1.0", "end")
        self.raw_text.insert("1.0", encode(definition))

    def _definition_from_editor(self) -> dict[str, Any]:
        try:
            definition = json.loads(self.raw_text.get("1.0", "end-1c"))
        except json.JSONDecodeError as exc:
            raise StorageError(f"invalid JSON at line {exc.lineno}, column {exc.colno}") from exc
        if not isinstance(definition, dict):
            raise StorageError("definition JSON must be an object")
        identity = definition.setdefault("identity", {})
        if not isinstance(identity, dict):
            raise StorageError("identity must be an object")
        survivor = identity.setdefault("survivor", {})
        if not isinstance(survivor, dict):
            raise StorageError("identity.survivor must be an object")
        first = self.first_var.get().strip()
        surname = self.surname_var.get().strip()
        if first:
            survivor["forename"] = first
        if surname:
            survivor["surname"] = surname
        display = " ".join(value for value in (first, surname) if value)
        if display:
            definition["displayName"] = display
            definition["name"] = display
        definition["isFemale"] = self.gender_var.get() == "Female"
        if self.id_var.get().strip():
            definition["id"] = self.id_var.get().strip()
            definition["uniqueDefinitionId"] = self.id_var.get().strip()
        if self.archetype_var.get().strip():
            definition["archetypeID"] = self.archetype_var.get().strip()
        else:
            definition.pop("archetypeID", None)
        faction = self.faction_var.get().strip()
        if faction and faction.lower() != "random":
            definition["factionID"] = faction
        else:
            definition.pop("factionID", None)
        chance = self.chance_var.get().strip()
        if chance:
            try:
                definition["spawnChance"] = float(chance)
            except ValueError as exc:
                raise StorageError("spawn chance must be numeric") from exc
        else:
            definition.pop("spawnChance", None)
        return definition

    def new_draft(self) -> None:
        self.current_filename = None
        self.current_definition = {
            "displayName": "",
            "name": "",
            "isFemale": False,
            "identity": {"survivor": {}},
            "version": 1,
            "appearance": {"outfit": {"mode": "none"}, "slots": {}, "voice": {"mode": "random"}},
            "startingItems": [],
        }
        self._show_definition(self.current_definition)
        self.dirty = True
        self.draft_tree.selection_remove(self.draft_tree.selection())
        self.status_var.set("New draft; enter a first name and surname")

    def open_draft(self) -> None:
        filename = filedialog.askopenfilename(
            title="Open Hoomans draft",
            initialdir=str(self.draft_store.root),
            filetypes=(("Hoomans files", "*.txt"), ("All files", "*.*")),
        )
        if not filename:
            return
        try:
            target = self.draft_store.import_file(Path(filename))
        except (StorageError, ConversionError) as exc:
            messagebox.showerror("Open draft", str(exc))
            return
        self.current_filename = target.name
        self.refresh_drafts()
        if self.draft_tree.exists(target.name):
            self.draft_tree.selection_set(target.name)
        self.status_var.set(f"Opened {target.name}")

    def import_draft(self) -> None:
        self.open_draft()

    def _save_definition(self, filename: Optional[str] = None) -> Optional[Path]:
        try:
            definition = self._definition_from_editor()
            payload = build_payload(definition)
            target = self.draft_store.save(payload["definition"], filename or self.current_filename)
        except (StorageError, ConversionError) as exc:
            messagebox.showerror("Save draft", str(exc))
            return None
        self.current_filename = target.name
        self.current_definition = payload["definition"]
        self.dirty = False
        self.refresh_drafts()
        if self.draft_tree.exists(target.name):
            self.draft_tree.selection_set(target.name)
        self.status_var.set(f"Saved {target.name}")
        return target

    def save_draft(self) -> None:
        self._save_definition()

    def save_as(self) -> None:
        try:
            definition = build_payload(self._definition_from_editor())["definition"]
            suggested = output_name(definition)
        except (StorageError, ConversionError) as exc:
            messagebox.showerror("Save As", str(exc))
            return
        filename = filedialog.asksaveasfilename(
            title="Save Hoomans draft as",
            initialdir=str(self.draft_store.root),
            initialfile=suggested,
            defaultextension=".txt",
            filetypes=(("Hoomans files", "*.txt"),),
        )
        if filename:
            self._save_definition(Path(filename).name)

    def duplicate_draft(self) -> None:
        if not self.current_definition:
            messagebox.showinfo("Duplicate", "Select a draft first.")
            return
        definition = json.loads(json.dumps(self.current_definition))
        identity = definition.setdefault("identity", {}).setdefault("survivor", {})
        identity["surname"] = f"{identity.get('surname', 'NPC')} Copy"
        definition["displayName"] = f"{identity.get('forename', 'New')} {identity['surname']}"
        definition["name"] = definition["displayName"]
        definition.pop("id", None)
        definition.pop("uniqueDefinitionId", None)
        self._show_definition(definition)
        self.current_filename = None
        self.current_definition = definition
        self._save_definition()

    def delete_draft(self) -> None:
        if not self.current_filename:
            return
        if not messagebox.askyesno(
            "Delete draft", f"Move {self.current_filename} to the Hoomans trash folder?"
        ):
            return
        filename = self.current_filename
        definition = self.current_definition
        try:
            self.draft_store.delete(filename)
            if definition:
                normalized = build_payload(definition)["definition"]
                if self.runtime_store.has_generated(normalized) and messagebox.askyesno(
                    "Delete runtime definition", "Also remove its generated Lua definition?"
                ):
                    self.runtime_store.delete(normalized)
        except (StorageError, ConversionError) as exc:
            messagebox.showerror("Delete draft", str(exc))
            return
        self.current_filename = None
        self.current_definition = None
        self._refresh_all()
        self.status_var.set(f"Deleted {filename}")

    def export_current(self) -> None:
        if not self.current_definition:
            messagebox.showinfo("Export Lua", "Select or create a draft first.")
            return
        try:
            definition = build_payload(self._definition_from_editor())["definition"]
            path = self.runtime_store.export(definition)
        except (StorageError, ConversionError) as exc:
            messagebox.showerror("Export Lua", str(exc))
            return
        self.current_definition = definition
        self.refresh_drafts()
        self.refresh_runtime()
        self.status_var.set(f"Generated {path.name} and rebuilt the loader")

    def export_all(self) -> None:
        exported = 0
        errors: list[str] = []
        for filename in self.draft_store.list_files():
            try:
                definition = build_payload(self.draft_store.load(filename))["definition"]
                self.runtime_store.export(definition)
                exported += 1
            except (StorageError, ConversionError) as exc:
                errors.append(f"{filename}: {exc}")
        self.refresh_drafts()
        self.refresh_runtime()
        self._write_validation([f"Exported {exported} definition(s)"] + errors)
        self.status_var.set(f"Exported {exported} definition(s)")

    def rebuild_loader(self) -> None:
        path = self.runtime_store.rebuild()
        self.refresh_runtime()
        self.status_var.set(f"Rebuilt {path.name}")

    def delete_runtime(self) -> None:
        selection = self.runtime_tree.selection()
        if not selection:
            messagebox.showinfo("Delete runtime definition", "Select a generated Lua module first.")
            return
        filename = selection[0]
        if not messagebox.askyesno(
            "Delete runtime definition",
            f"Move generated {filename} to a backup and rebuild the loader?",
        ):
            return
        try:
            backup = self.runtime_store.delete_module(filename)
        except StorageError as exc:
            messagebox.showerror("Delete runtime definition", str(exc))
            return
        self.refresh_drafts()
        self.refresh_runtime()
        self.status_var.set(f"Removed {filename}; backup: {backup.name}")

    def _on_runtime_selected(self, _event: tk.Event) -> None:
        selection = self.runtime_tree.selection()
        self.runtime_text.configure(state="normal")
        self.runtime_text.delete("1.0", "end")
        if selection:
            path = self.runtime_store.root / selection[0]
            if path.exists():
                self.runtime_text.insert("1.0", path.read_text(encoding="utf-8", errors="replace"))
        self.runtime_text.configure(state="disabled")

    def validate_all(self) -> None:
        messages: list[str] = []
        seen_ids: dict[str, str] = {}
        valid = 0
        for filename in self.draft_store.list_files():
            try:
                definition = build_payload(self.draft_store.load(filename))["definition"]
                identifier = str(definition["id"])
                if identifier in seen_ids:
                    messages.append(
                        f"ERROR {filename}: duplicate ID {identifier} also used by {seen_ids[identifier]}"
                    )
                else:
                    seen_ids[identifier] = filename
                if self.runtime_store.has_generated(definition):
                    messages.append(f"OK    {filename}: valid and generated ({identifier})")
                else:
                    messages.append(f"WARN  {filename}: valid but runtime Lua is not generated")
                if "factionID" not in definition:
                    messages.append(f"INFO  {filename}: faction is unbound")
                valid += 1
            except (StorageError, ConversionError) as exc:
                messages.append(f"ERROR {filename}: {exc}")
        if not messages:
            messages.append("No Hoomans files found.")
        messages.insert(0, f"Validated {valid} Hoomans file(s).")
        self._write_validation(messages)

    def _write_validation(self, messages: list[str]) -> None:
        self.validation_text.configure(state="normal")
        self.validation_text.delete("1.0", "end")
        self.validation_text.insert("1.0", "\n".join(messages) + "\n")
        self.validation_text.configure(state="disabled")

    def repair_index(self) -> None:
        path = self.draft_store.rebuild_index()
        self.refresh_drafts()
        self.status_var.set(f"Rebuilt {path.name}")

    def open_runtime_folder(self) -> None:
        path = self.runtime_store.root
        try:
            if sys.platform == "win32":
                import os

                os.startfile(path)  # type: ignore[attr-defined]
            elif sys.platform == "darwin":
                import subprocess

                subprocess.Popen(["open", str(path)])
            else:
                import subprocess

                subprocess.Popen(["xdg-open", str(path)])
        except OSError as exc:
            messagebox.showerror("Open folder", str(exc))


def main() -> int:
    app = UniqueNPCManager()
    app.mainloop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
