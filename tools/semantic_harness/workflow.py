"""In-app Semantic Lab workflow over the shared authoring service."""

from __future__ import annotations

import json
import re
from typing import Any, Callable

from .codebuilder.service import SemanticLabAuthoringService


class SemanticLabWorkflowPane:
    """Select a canonical source, compose blocks, and approve one build."""

    def __init__(
        self,
        parent: Any,
        tk: Any,
        ttk: Any,
        scrolled_text: Any,
        messagebox: Any,
        service: SemanticLabAuthoringService,
        *,
        on_generate: Callable[[str, list[str], dict[str, Any] | None], Any],
        on_inspect: Callable[[], Any],
    ) -> None:
        self._tk = tk
        self._ttk = ttk
        self._messagebox = messagebox
        self.service = service
        self._on_generate = on_generate
        self._on_inspect = on_inspect
        self._production_catalog: dict[str, Any] | None = None
        self._sources: list[dict[str, Any]] = []
        self._blocks: list[dict[str, Any]] = []
        self._last_preview: dict[str, Any] | None = None
        self._preview_key: str | None = None
        self._approved_key: str | None = None
        self._last_spec: dict[str, Any] | None = None

        self.frame = ttk.Frame(parent, padding=8)
        self.frame.grid(row=0, column=0, sticky="nsew")
        self.frame.rowconfigure(2, weight=1)
        self.frame.columnconfigure(0, weight=1)
        self.frame.columnconfigure(1, weight=2)

        self._source_var = tk.StringVar()
        self._query_var = tk.StringVar()
        self._spec_id_var = tk.StringVar(value="pnc.lab.former_job")
        self._utterance_var = tk.StringVar(value="what was your old job")
        self._negative_var = tk.StringVar(value="do not ask about my old job")
        self._kind_var = tk.StringVar(value="former_job")
        self._pool_var = tk.StringVar(value="semantic.lab.former_job")
        self._english_var = tk.StringVar(value="I worked as %1 before all this.")
        self._tagalog_var = tk.StringVar(value="Nagtrabaho ako bilang %1 bago ang lahat ng ito.")
        self._status_var = tk.StringVar(value="Select a canonical dataset to begin.")

        toolbar = ttk.Frame(self.frame)
        toolbar.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 6))
        toolbar.columnconfigure(1, weight=1)
        ttk.Label(toolbar, text="Dataset").grid(row=0, column=0, padx=(0, 6))
        self._source_box = ttk.Combobox(
            toolbar,
            textvariable=self._source_var,
            state="readonly",
            width=28,
        )
        self._source_box.grid(row=0, column=1, sticky="ew")
        self._source_box.bind("<<ComboboxSelected>>", lambda _event: self._selection_changed())
        self._refresh_button = ttk.Button(toolbar, text="Refresh sources", command=self.refresh)
        self._refresh_button.grid(row=0, column=2, padx=(6, 0))
        ttk.Label(toolbar, text="Block search").grid(row=0, column=3, padx=(14, 6))
        self._query_entry = ttk.Entry(toolbar, textvariable=self._query_var, width=24)
        self._query_entry.grid(row=0, column=4)
        self._search_button = ttk.Button(toolbar, text="Search", command=self.search_blocks)
        self._search_button.grid(row=0, column=5, padx=(6, 0))
        self._status = ttk.Label(self.frame, textvariable=self._status_var)
        self._status.grid(row=1, column=0, columnspan=2, sticky="w", pady=(0, 6))

        left = ttk.LabelFrame(self.frame, text="Compose reusable blocks")
        left.grid(row=2, column=0, sticky="nsew", padx=(0, 8))
        left.rowconfigure(0, weight=1)
        left.columnconfigure(0, weight=1)
        self._block_list = tk.Listbox(
            left,
            width=48,
            exportselection=False,
            selectmode="extended",
        )
        self._block_list.grid(row=0, column=0, sticky="nsew")
        block_scroll = ttk.Scrollbar(left, orient="vertical", command=self._block_list.yview)
        block_scroll.grid(row=0, column=1, sticky="ns")
        self._block_list.configure(yscrollcommand=block_scroll.set)

        parameters = ttk.LabelFrame(left, text="Grounded interaction parameters")
        parameters.grid(row=1, column=0, columnspan=2, sticky="ew", pady=(6, 0))
        parameters.columnconfigure(1, weight=1)
        self._add_entry(parameters, 0, "Spec ID", self._spec_id_var)
        self._add_entry(parameters, 1, "Utterance", self._utterance_var)
        self._add_entry(parameters, 2, "Negative utterance", self._negative_var)
        ttk.Label(parameters, text="Backstory kind").grid(row=3, column=0, sticky="w", padx=6, pady=2)
        self._kind_box = ttk.Combobox(
            parameters,
            textvariable=self._kind_var,
            state="readonly",
            values=("former_job", "hometown", "education", "hobby", "family_background", "value", "survival_origin", "fear", "tragedy", "date_of_birth"),
        )
        self._kind_box.grid(row=3, column=1, sticky="ew", padx=(0, 6), pady=2)
        self._add_entry(parameters, 4, "Response pool", self._pool_var)
        self._add_entry(parameters, 5, "EN response", self._english_var)
        self._add_entry(parameters, 6, "TL response", self._tagalog_var)

        right = ttk.LabelFrame(self.frame, text="Workflow contract and generated-source preview")
        right.grid(row=2, column=1, sticky="nsew")
        right.rowconfigure(0, weight=1)
        right.columnconfigure(0, weight=1)
        self._report = scrolled_text(right, wrap="none", state="disabled")
        self._report.grid(row=0, column=0, sticky="nsew")

        actions = ttk.Frame(self.frame)
        actions.grid(row=3, column=0, columnspan=2, sticky="ew", pady=(6, 0))
        self._validate_button = ttk.Button(
            actions, text="Validate composition", command=self.validate_composition,
        )
        self._validate_button.pack(side="left")
        self._preview_button = ttk.Button(
            actions, text="Preview generated source", command=self.preview_source,
        )
        self._preview_button.pack(side="left", padx=6)
        self._approve_button = ttk.Button(
            actions, text="Approve generation", command=self.approve_generation,
        )
        self._approve_button.pack(side="left")
        self._generate_button = ttk.Button(
            actions, text="Generate + restart worker", command=self.generate,
        )
        self._generate_button.pack(side="left", padx=6)
        self._inspect_button = ttk.Button(
            actions, text="Inspect live dialogue", command=self._on_inspect,
        )
        self._inspect_button.pack(side="right")
        self._buttons = (
            self._refresh_button,
            self._search_button,
            self._validate_button,
            self._preview_button,
            self._approve_button,
            self._generate_button,
            self._inspect_button,
        )
        self._enabled = True
        self.refresh()

    def _add_entry(self, parent: Any, row: int, label: str, variable: Any) -> None:
        """Add one editable parameter row to the workflow composer."""

        self._ttk.Label(parent, text=label).grid(
            row=row, column=0, sticky="w", padx=6, pady=2
        )
        self._ttk.Entry(parent, textvariable=variable).grid(
            row=row, column=1, sticky="ew", padx=(0, 6), pady=2
        )

    def _set_report(self, value: Any) -> None:
        self._report.configure(state="normal")
        self._report.delete("1.0", "end")
        self._report.insert("1.0", json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True) + "\n")
        self._report.configure(state="disabled")

    def _selection_key(self) -> str:
        return json.dumps(
            {
                "datasetID": self._source_var.get().strip(),
                "blockIDs": self._selected_block_ids(),
                "spec": self._compose_spec(raise_errors=False),
            },
            sort_keys=True,
        )

    def _selected_block_ids(self) -> list[str]:
        return [self._blocks[index]["id"] for index in self._block_list.curselection()]

    def _compose_spec(self, *, raise_errors: bool = True) -> dict[str, Any] | None:
        """Materialize the selected block graph into the existing spec contract."""

        source_id = self._source_var.get().strip()
        selected = [self._blocks[index] for index in self._block_list.curselection()]
        selected_types = [str(block.get("id")) for block in selected]
        required = {
            "language.trigger": "trigger",
            "language.backstory_subject": "backstory subject",
            "memory.backstory_fact": "backstory fact",
            "dialogue_responses.response_pool": "response pool",
        }
        if source_id == "grounded_personal_dialogue":
            missing = [label for block_id, label in required.items() if selected_types.count(block_id) != 1]
            if missing:
                if raise_errors:
                    raise ValueError(
                        "grounded dialogue requires exactly one selected " + ", ".join(missing)
                    )
                return None
            kind = self._kind_var.get().strip()
            slug = re.sub(r"[^a-z0-9]+", "_", self._spec_id_var.get().strip().lower()).strip("_")
            if not slug:
                if raise_errors:
                    raise ValueError("Spec ID is required")
                return None
            return {
                "schema": "semantic.interaction_spec.v1",
                "id": self._spec_id_var.get().strip(),
                "owner": "SemanticLab",
                "blocks": [
                    {"id": "trigger", "type": "language.trigger", "parameters": {
                        "utterance": self._utterance_var.get().strip(),
                        "negativeUtterance": self._negative_var.get().strip(),
                        "frame": {"intent": "QUESTION", "speechAct": "QUESTION"},
                    }},
                    {"id": "backstory", "type": "language.backstory_subject", "parameters": {
                        "backstoryKind": kind,
                        "factProvider": "npc_backstory",
                        "topicID": f"backstory.{kind}",
                        "disclosure": "server_authorized",
                    }},
                    {"id": "fact", "type": "memory.backstory_fact", "parameters": {
                        "providerID": "npc_backstory",
                        "subject": "NPC_BACKSTORY",
                        "authority": "server",
                        "immutable": True,
                        "privacy": "private",
                    }},
                    {"id": "response", "type": "dialogue_responses.response_pool", "parameters": {
                        "poolID": self._pool_var.get().strip(),
                        "variants": [{
                            "id": "answer",
                            "key": "UI_PNC_Conversation_Semantic_Lab" + "".join(word.title() for word in slug.split("_")),
                            "en": self._english_var.get().strip(),
                            "tl": self._tagalog_var.get().strip(),
                            "translationArgs": {"content": "fact_content"},
                        }],
                    }},
                ],
                "connections": [
                    {"from": "trigger", "to": "backstory", "type": "semantic"},
                    {"from": "backstory", "to": "fact", "type": "fact"},
                    {"from": "fact", "to": "response", "type": "response"},
                ],
            }
        if raise_errors:
            raise ValueError(
                "select Grounded personal dialogue and its trigger, backstory subject, backstory fact, and response-pool blocks"
            )
        return None

    def _selection_changed(self) -> None:
        self._last_preview = None
        self._preview_key = None
        self._approved_key = None
        self._last_spec = None
        self._status_var.set(f"Selected {self._source_var.get().strip()}; compose blocks and validate.")

    def refresh(self) -> None:
        self._sources = self.service.list_workflow_datasets()
        source_ids = [str(source["id"]) for source in self._sources]
        self._source_box.configure(values=source_ids)
        if self._source_var.get() not in source_ids:
            self._source_var.set(source_ids[0] if source_ids else "")
        self.search_blocks()
        self._status_var.set(
            f"{len(self._sources)} generation-ready datasets; select blocks for composition."
        )

    def set_production_catalog(self, catalog: dict[str, Any] | None) -> None:
        self._production_catalog = catalog if isinstance(catalog, dict) else None
        self.search_blocks()

    def search_blocks(self) -> None:
        self._blocks = self.service.search_semantic_blocks(
            self._query_var.get().strip(),
            production_catalog=self._production_catalog,
            limit=128,
        )
        self._block_list.delete(0, "end")
        for block in self._blocks:
            self._block_list.insert(
                "end",
                f"{block.get('category', '?')} · {block.get('label', block.get('id', '?'))}",
            )
        self._last_preview = None
        self._preview_key = None
        self._approved_key = None

    def validate_composition(self) -> dict[str, Any] | None:
        source_id = self._source_var.get().strip()
        if not source_id:
            self._status_var.set("Select a generation-ready dataset first")
            return None
        report = self.service.validate_workflow_selection(
            source_id,
            self._selected_block_ids(),
            production_catalog=self._production_catalog,
        )
        try:
            spec = self._compose_spec()
            composition = self.service.validate_interaction_spec(
                spec,
                production_catalog=self._production_catalog,
            )
            report["composition"] = composition
            report["ok"] = report.get("ok") is True and composition.get("ok") is True
            report.setdefault("diagnostics", []).extend(composition.get("diagnostics", []))
            self._last_spec = spec
        except ValueError as error:
            report["ok"] = False
            report.setdefault("diagnostics", []).append({"severity": "error", "message": str(error)})
            self._last_spec = None
        self._set_report(report)
        self._last_preview = None
        self._preview_key = None
        self._approved_key = None
        if report.get("ok") is True:
            self._status_var.set("Composition valid; preview the generated source before approval.")
        else:
            self._status_var.set("Composition rejected; resolve the reported dataset/block errors.")
        return report

    def preview_source(self) -> dict[str, Any] | None:
        source_id = self._source_var.get().strip()
        if not source_id:
            self._status_var.set("Select a generation-ready dataset first")
            return None
        try:
            spec = self._compose_spec()
        except ValueError as error:
            report = {
                "ok": False,
                "type": "semantic_lab_workflow_preview",
                "workflow": {"datasetID": source_id, "blockIDs": self._selected_block_ids()},
                "diagnostics": [{"severity": "error", "message": str(error)}],
                "previewOnly": True,
                "effectFree": True,
                "writes": [],
            }
            spec = None
        else:
            report = self.service.preview_workflow(
                source_id,
                self._selected_block_ids(),
                production_catalog=self._production_catalog,
                interaction_spec=spec,
            )
        self._last_spec = spec
        self._set_report(report)
        self._last_preview = report
        self._preview_key = self._selection_key()
        self._approved_key = None
        if report.get("ok") is True:
            self._status_var.set("Generated Lua/EN-TL/manifest preview is ready for approval; no files written.")
        else:
            self._status_var.set("Generated-source preview rejected; no files written.")
        return report

    def approve_generation(self) -> bool:
        if not self._last_preview or self._last_preview.get("ok") is not True:
            self._status_var.set("Preview a valid workflow before approval")
            return False
        if self._selection_key() != self._preview_key:
            self._status_var.set("Selection changed; preview again before approval")
            return False
        generated_paths = self._last_preview.get("sourcePreview", {}).get("generatedPaths", [])
        if not self._messagebox.askyesno(
            "Approve Semantic Lab generation",
            "Approve the validated workflow to write its generated Lua, EN/TL, and manifests?\n\n"
            + "\n".join(str(path) for path in generated_paths[:8]),
        ):
            self._status_var.set("Generation approval cancelled; preview remains unchanged")
            return False
        self._approved_key = self._selection_key()
        self._status_var.set("Workflow approved; generate to write artifacts and restart the worker.")
        return True

    def generate(self) -> None:
        if self._approved_key != self._selection_key():
            self._status_var.set("Approve the current generated-source preview first")
            return
        self._on_generate(
            self._source_var.get().strip(),
            self._selected_block_ids(),
            self._last_spec,
        )

    def show_generation(self, report: dict[str, Any]) -> None:
        self._set_report(report)
        self._last_preview = report
        self._preview_key = None
        self._approved_key = None
        if report.get("ok") is True:
            self._status_var.set("Artifacts generated; worker restart requested. Inspect live dialogue when ready.")
        else:
            self._status_var.set("Generation failed; no worker restart was requested.")

    def set_enabled(self, enabled: bool) -> None:
        self._enabled = enabled
        state = "normal" if enabled else "disabled"
        readonly = "readonly" if enabled else "disabled"
        self._source_box.configure(state=readonly)
        self._query_entry.configure(state=state)
        self._block_list.configure(state=state)
        for button in self._buttons:
            button.configure(state=state)
