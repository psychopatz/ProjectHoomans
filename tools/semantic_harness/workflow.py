"""In-app Semantic Lab workflow over the shared authoring service."""

from __future__ import annotations

import json
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
        on_generate: Callable[[str, list[str]], Any],
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

        self.frame = ttk.Frame(parent, padding=8)
        self.frame.grid(row=0, column=0, sticky="nsew")
        self.frame.rowconfigure(2, weight=1)
        self.frame.columnconfigure(0, weight=1)
        self.frame.columnconfigure(1, weight=2)

        self._source_var = tk.StringVar()
        self._query_var = tk.StringVar()
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
            },
            sort_keys=True,
        )

    def _selected_block_ids(self) -> list[str]:
        return [self._blocks[index]["id"] for index in self._block_list.curselection()]

    def _selection_changed(self) -> None:
        self._last_preview = None
        self._preview_key = None
        self._approved_key = None
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
        report = self.service.preview_workflow(
            source_id,
            self._selected_block_ids(),
            production_catalog=self._production_catalog,
        )
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
        self._on_generate(self._source_var.get().strip(), self._selected_block_ids())

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
