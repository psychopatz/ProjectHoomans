"""Production-flow graph model and the Semantic Lab visual editor pane."""

from __future__ import annotations

import copy
import json
from pathlib import Path
from typing import Any, Callable

from .codebuilder.blocks import GATE_TYPES, TRANSITION_FIELDS
from .codebuilder.codeblocks import (
    codeblocks_to_flow,
    flow_to_codeblocks,
    validate_codeblock_document,
)

def graph_transform(point: tuple[float, float], zoom: float, pan: tuple[float, float]) -> tuple[float, float]:
    """Transform model coordinates into canvas coordinates."""

    return point[0] * zoom + pan[0], point[1] * zoom + pan[1]


def graph_inverse(point: tuple[float, float], zoom: float, pan: tuple[float, float]) -> tuple[float, float]:
    """Transform canvas coordinates into model coordinates."""

    return (point[0] - pan[0]) / zoom, (point[1] - pan[1]) / zoom


def graph_render_mode(zoom: float) -> str:
    """Return the amount of detail that remains readable at ``zoom``."""

    if zoom < 0.55:
        return "overview"
    if zoom < 0.8:
        return "compact"
    return "detail"


def flow_draft(flow: dict[str, Any]) -> dict[str, Any]:
    """Return an editable copy of one normalized production flow."""

    return copy.deepcopy(flow)


def _title_identifier(value: str) -> str:
    """Turn a bounded registry identifier segment into a UI label."""

    words = str(value).replace("_", " ").replace("-", " ").split()
    return " ".join(word[:1].upper() + word[1:] for word in words)


def flow_display_name(
    flow_id: str,
    flow: dict[str, Any] | None = None,
) -> str:
    """Return a compact label while preserving the canonical flow ID."""

    flow_id = str(flow_id)
    flow = flow if isinstance(flow, dict) else {}
    workflow_kind = str(flow.get("workflowKind") or "")
    capability_id = str(flow.get("capabilityID") or "")
    generated = workflow_kind != "" or flow_id.startswith("pnc.generated.")
    if not generated:
        return flow_id

    if not capability_id:
        generated_parts = flow_id.split(".")
        if len(generated_parts) >= 4:
            capability_id = ".".join(generated_parts[3:])
            if capability_id.startswith("pnc."):
                capability_id = "pnc:" + capability_id[4:]
    if capability_id.startswith("pnc:"):
        capability_id = capability_id[4:]
    segments = [
        _title_identifier(segment)
        for segment in capability_id.split(".")
        if segment
    ]
    if segments:
        return " / ".join(segments)
    return flow_id


def flow_graph_model(flow: dict[str, Any]) -> dict[str, Any]:
    """Build deterministic nodes/edges for the visual graph and tests."""

    if not isinstance(flow, dict):
        raise ValueError("flow must be an object")
    nodes = flow.get("nodes")
    if not isinstance(nodes, dict) or not nodes:
        raise ValueError("flow.nodes must be a non-empty object")

    node_rows: list[dict[str, Any]] = []
    edges: list[dict[str, Any]] = []
    for node_id in sorted(nodes):
        node = nodes[node_id]
        if not isinstance(node, dict):
            raise ValueError(f"flow node {node_id!r} must be an object")
        transitions = {
            field: node[field]
            for field in TRANSITION_FIELDS
            if node.get(field) not in (None, "")
        }
        action = node.get("action") if isinstance(node.get("action"), dict) else {}
        raw_result_transitions = node.get("resultTransitions")
        if not isinstance(raw_result_transitions, dict):
            raw_result_transitions = action.get("resultTransitions", {})
        result_transitions = {
            str(outcome): target
            for outcome, target in raw_result_transitions.items()
            if target not in (None, "")
        }
        node_rows.append({
            "id": node_id,
            "terminal": node.get("terminal") is True,
            "action": copy.deepcopy(action) if action else None,
            "responsePool": node.get("responsePool"),
            "responseTemplate": node.get("responseTemplate"),
            "accepts": copy.deepcopy(node.get("accepts", [])),
            "slots": copy.deepcopy(node.get("slots", {})),
            "gate": copy.deepcopy(node.get("gate")),
            "transitions": transitions,
            "resultTransitions": result_transitions,
        })
        for field, target in transitions.items():
            edges.append({
                "fromNodeID": node_id,
                "field": field,
                "toNodeID": target,
                "internal": target in nodes,
            })
        for outcome, target in result_transitions.items():
            edges.append({
                "fromNodeID": node_id,
                "field": f"result:{outcome}",
                "toNodeID": target,
                "internal": target in nodes,
            })

    return {
        "schemaVersion": 1,
        "flowID": flow.get("id"),
        "owner": flow.get("owner"),
        "version": flow.get("version"),
        "workflowKind": flow.get("workflowKind"),
        "capabilityID": flow.get("capabilityID"),
        "generated": flow.get("workflowKind") is not None,
        "initial": flow.get("initial"),
        "triggers": copy.deepcopy(flow.get("triggers", [])),
        "nodes": node_rows,
        "edges": edges,
    }


def coverage_summary(coverage: list[dict[str, Any]]) -> dict[str, int]:
    """Count live capability classifications shown by Semantic Lab."""

    summary: dict[str, int] = {}
    for row in coverage:
        if not isinstance(row, dict):
            continue
        classification = str(row.get("classification") or "unknown")
        summary[classification] = summary.get(classification, 0) + 1
    return summary


def coverage_lines(coverage: list[dict[str, Any]]) -> list[str]:
    """Render exact bounded coverage reasons for the visual coverage view."""

    lines: list[str] = []
    for row in sorted(
        (item for item in coverage if isinstance(item, dict)),
        key=lambda item: str(item.get("id") or ""),
    ):
        capability = str(row.get("id") or "<unknown>")
        classification = str(row.get("classification") or "unknown")
        reason = str(row.get("reason") or "unspecified")
        flow_id = row.get("flowID")
        suffix = f" -> {flow_id}" if flow_id else ""
        lines.append(f"{capability}: {classification} ({reason}){suffix}")
    return lines


def _json_text(value: Any) -> str:
    return json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True)


class FlowEditorPane:
    """Visual graph plus bounded form editor backed by worker callbacks."""

    def __init__(
        self,
        parent: Any,
        tk_module: Any,
        ttk: Any,
        scrolled_text: Any,
        filedialog: Any,
        messagebox: Any,
        *,
        on_refresh: Callable[[], Any],
        on_validate: Callable[[dict[str, Any]], Any],
        on_register: Callable[[dict[str, Any]], Any],
        on_compile_source: Callable[[Path], Any] | None = None,
        on_generate_source: Callable[[Path], Any] | None = None,
        on_review_dataset: Callable[[Path], Any] | None = None,
        on_generate_dataset: Callable[[Path], Any] | None = None,
    ) -> None:
        self._tk = tk_module
        self._ttk = ttk
        self._ScrolledText = scrolled_text
        self._filedialog = filedialog
        self._messagebox = messagebox
        self._on_refresh = on_refresh
        self._on_validate = on_validate
        self._on_register = on_register
        self._on_compile_source = on_compile_source
        self._on_generate_source = on_generate_source
        self._on_review_dataset = on_review_dataset
        self._on_generate_dataset = on_generate_dataset
        self._catalog: dict[str, dict[str, Any]] = {}
        self._flow_id_to_label: dict[str, str] = {}
        self._flow_label_to_id: dict[str, str] = {}
        self._draft: dict[str, Any] | None = None
        self._selected_node: str | None = None
        self._node_positions: dict[str, tuple[float, float]] = {}
        self._fact_catalog: list[dict[str, Any]] = []
        self._command_catalog: list[str] = []
        self._action_catalog: list[dict[str, Any]] = []
        self._trigger_catalog: list[dict[str, Any]] = []
        self._coverage: list[dict[str, Any]] = []
        self._history: list[dict[str, Any]] = []
        self._history_index = -1
        self._nested_flows: list[dict[str, Any]] = []
        self._zoom = 1.0
        self._pan = (24.0, 42.0)
        self._drag_node: str | None = None
        self._drag_anchor: tuple[float, float] | None = None
        self._drag_origin: tuple[float, float] | None = None
        self._pan_anchor: tuple[float, float] | None = None
        self._pan_origin: tuple[float, float] | None = None

        self.frame = ttk.Frame(parent, padding=6)
        self.frame.grid(row=0, column=0, sticky="nsew")
        self.frame.rowconfigure(1, weight=1)
        self.frame.columnconfigure(0, weight=1)
        self._build_toolbar()
        self._build_body()
        self.set_status("Load a production flow to begin editing.")

    def _build_toolbar(self) -> None:
        ttk = self._ttk
        toolbar = ttk.Frame(self.frame)
        toolbar.grid(row=0, column=0, sticky="ew", pady=(0, 6))
        toolbar.columnconfigure(0, weight=1)
        self.flow_var = self._tk.StringVar()

        primary_toolbar = ttk.Frame(toolbar)
        primary_toolbar.grid(row=0, column=0, sticky="w")

        self.refresh_button = ttk.Button(
            primary_toolbar, text="Refresh registry", command=self._on_refresh
        )
        self.refresh_button.grid(row=0, column=0)
        self.coverage_button = ttk.Button(
            primary_toolbar, text="Coverage", command=self.show_coverage
        )
        self.coverage_button.grid(row=0, column=1, padx=(6, 0))
        self.validate_button = ttk.Button(
            primary_toolbar, text="Validate draft", command=self.validate_draft
        )
        self.validate_button.grid(row=0, column=2, padx=(6, 0))
        self.register_button = ttk.Button(
            primary_toolbar, text="Register draft", command=self.register_draft
        )
        self.register_button.grid(row=0, column=3, padx=(6, 0))
        self.add_button = ttk.Button(
            primary_toolbar, text="Add node", command=self.add_node
        )
        self.add_button.grid(row=0, column=4, padx=(10, 0))
        self.duplicate_button = ttk.Button(
            primary_toolbar, text="Duplicate", command=self.duplicate_node
        )
        self.duplicate_button.grid(row=0, column=5, padx=(4, 0))
        self.delete_button = ttk.Button(
            primary_toolbar, text="Delete", command=self.delete_node
        )
        self.delete_button.grid(row=0, column=6, padx=(4, 0))
        self.undo_button = ttk.Button(primary_toolbar, text="Undo", command=self.undo)
        self.undo_button.grid(row=0, column=7, padx=(10, 0))
        self.redo_button = ttk.Button(primary_toolbar, text="Redo", command=self.redo)
        self.redo_button.grid(row=0, column=8, padx=(4, 0))
        self.fit_button = ttk.Button(primary_toolbar, text="Fit", command=self.fit_graph)
        self.fit_button.grid(row=0, column=9, padx=(10, 0))
        self.zoom_button = ttk.Button(
            primary_toolbar, text="100%", command=self.reset_zoom
        )
        self.zoom_button.grid(row=0, column=10, padx=(4, 0))

        secondary_toolbar = ttk.Frame(toolbar)
        secondary_toolbar.grid(row=1, column=0, sticky="ew", pady=(4, 0))
        secondary_toolbar.columnconfigure(8, weight=1)

        self.load_button = ttk.Button(
            secondary_toolbar, text="Open draft", command=self.load_draft
        )
        self.load_button.grid(row=0, column=0, padx=(0, 0))
        self.save_button = ttk.Button(
            secondary_toolbar, text="Save draft", command=self.save_draft
        )
        self.save_button.grid(row=0, column=1, padx=(6, 0))
        self.rename_button = ttk.Button(
            secondary_toolbar, text="Rename", command=self.rename_node
        )
        self.rename_button.grid(row=0, column=2, padx=(10, 0))
        self.connect_button = ttk.Button(
            secondary_toolbar, text="Connect", command=self.connect_node
        )
        self.connect_button.grid(row=0, column=3, padx=(4, 0))
        self.trigger_button = ttk.Button(
            secondary_toolbar, text="Add trigger", command=self.add_trigger
        )
        self.trigger_button.grid(row=0, column=4, padx=(8, 0))
        self.command_button = ttk.Button(
            secondary_toolbar, text="Add action", command=self.add_command_trigger
        )
        self.command_button.grid(row=0, column=5, padx=(4, 0))
        self.compile_source_button = ttk.Button(
            secondary_toolbar, text="Compile source…", command=self.compile_source
        )
        self.compile_source_button.grid(row=0, column=6, padx=(8, 0))
        self.generate_source_button = ttk.Button(
            secondary_toolbar, text="Generate source…", command=self.generate_source
        )
        self.generate_source_button.grid(row=0, column=7, padx=(4, 0))
        self.review_dataset_button = ttk.Button(
            secondary_toolbar, text="Review dataset…", command=self.review_dataset
        )
        self.review_dataset_button.grid(row=0, column=8, padx=(8, 0))
        self.generate_dataset_button = ttk.Button(
            secondary_toolbar, text="Generate dialogue…", command=self.generate_dataset
        )
        self.generate_dataset_button.grid(row=0, column=9, padx=(4, 0))

        self.status_var = self._tk.StringVar()
        ttk.Label(toolbar, textvariable=self.status_var).grid(
            row=2, column=0, sticky="w", pady=(4, 0)
        )
        self._action_buttons = (
            self.refresh_button,
            self.coverage_button,
            self.validate_button,
            self.register_button,
            self.add_button,
            self.duplicate_button,
            self.delete_button,
            self.rename_button,
            self.connect_button,
            self.trigger_button,
            self.command_button,
            self.undo_button,
            self.redo_button,
            self.fit_button,
            self.zoom_button,
            self.load_button,
            self.save_button,
            self.compile_source_button,
            self.generate_source_button,
            self.review_dataset_button,
            self.generate_dataset_button,
        )

    def _build_body(self) -> None:
        ttk = self._ttk
        body = ttk.PanedWindow(self.frame, orient="horizontal")
        body.grid(row=1, column=0, sticky="nsew")

        flow_frame = ttk.LabelFrame(body, text="Production flows")
        flow_frame.rowconfigure(0, weight=1)
        flow_frame.columnconfigure(0, weight=1)
        self.flow_list = self._tk.Listbox(
            flow_frame, width=34, height=12, exportselection=False,
            selectmode="browse", activestyle="dotbox",
        )
        self.flow_list.grid(row=0, column=0, sticky="nsew")
        flow_scroll = ttk.Scrollbar(
            flow_frame, orient="vertical", command=self.flow_list.yview,
        )
        flow_scroll.grid(row=0, column=1, sticky="ns")
        self.flow_list.configure(yscrollcommand=flow_scroll.set)
        self.flow_list.bind("<<ListboxSelect>>", self._on_flow_list_select)
        body.add(flow_frame, weight=1)

        graph_frame = ttk.LabelFrame(body, text="Flow graph · nodes and transitions")
        graph_frame.rowconfigure(1, weight=1)
        graph_frame.columnconfigure(0, weight=1)
        self.graph_hint_var = self._tk.StringVar(value="Select a production flow")
        ttk.Label(
            graph_frame, textvariable=self.graph_hint_var, anchor="w",
        ).grid(row=0, column=0, columnspan=2, sticky="ew", padx=8, pady=(2, 4))
        self.canvas = self._tk.Canvas(
            graph_frame,
            width=680,
            height=560,
            background="#10151b",
            highlightthickness=0,
        )
        self.canvas.grid(row=1, column=0, sticky="nsew")
        self.canvas.bind("<MouseWheel>", self._on_mouse_wheel)
        self.canvas.bind("<Button-4>", lambda event: self._zoom_at(event, 1.12))
        self.canvas.bind("<Button-5>", lambda event: self._zoom_at(event, 1 / 1.12))
        self.canvas.bind("<Button-1>", self._on_canvas_left_down)
        self.canvas.bind("<B1-Motion>", self._drag_node_motion)
        self.canvas.bind("<ButtonRelease-1>", self._stop_node_drag)
        self.canvas.bind("<Button-2>", self._start_pan)
        self.canvas.bind("<B2-Motion>", self._drag_pan)
        self.canvas.bind("<ButtonRelease-2>", self._stop_pan)
        self.canvas.bind("<Configure>", lambda _event: self._draw_graph())
        y_scroll = ttk.Scrollbar(
            graph_frame, orient="vertical", command=self.canvas.yview
        )
        y_scroll.grid(row=1, column=1, sticky="ns")
        x_scroll = ttk.Scrollbar(
            graph_frame, orient="horizontal", command=self.canvas.xview
        )
        x_scroll.grid(row=2, column=0, sticky="ew")
        self.canvas.configure(xscrollcommand=x_scroll.set, yscrollcommand=y_scroll.set)
        body.add(graph_frame, weight=4)

        form_panel = ttk.LabelFrame(body, text="Editable flow definition")
        form_panel.rowconfigure(0, weight=1)
        form_panel.columnconfigure(0, weight=1)
        form_canvas = self._tk.Canvas(form_panel, highlightthickness=0)
        form_canvas.grid(row=0, column=0, sticky="nsew")
        form_scroll = ttk.Scrollbar(
            form_panel, orient="vertical", command=form_canvas.yview
        )
        form_scroll.grid(row=0, column=1, sticky="ns")
        form_canvas.configure(yscrollcommand=form_scroll.set)
        form_frame = ttk.Frame(form_canvas)
        form_frame.columnconfigure(1, weight=1)
        form_frame.rowconfigure(11, weight=1)
        form_frame.rowconfigure(13, weight=1)
        form_window = form_canvas.create_window((0, 0), window=form_frame, anchor="nw")

        def update_form_scroll_region(_event: Any = None) -> None:
            form_canvas.configure(scrollregion=form_canvas.bbox("all"))

        def resize_form_content(event: Any) -> None:
            form_canvas.itemconfigure(form_window, width=event.width)

        form_frame.bind("<Configure>", update_form_scroll_region)
        form_canvas.bind("<Configure>", resize_form_content)
        body.add(form_panel, weight=2)

        self.flow_id_var = self._tk.StringVar()
        self.owner_var = self._tk.StringVar()
        self.initial_var = self._tk.StringVar()
        self._add_entry(form_frame, 0, "Flow ID", self.flow_id_var)
        self._add_entry(form_frame, 1, "Owner", self.owner_var)
        self._add_entry(form_frame, 2, "Initial node", self.initial_var)

        ttk.Label(form_frame, text="Triggers (JSON frames)").grid(
            row=3, column=0, sticky="nw", padx=(6, 6), pady=(8, 2)
        )
        self.triggers_text = self._ScrolledText(form_frame, height=5, width=38, wrap="none")
        self.triggers_text.grid(row=3, column=1, sticky="ew", padx=(0, 6), pady=(8, 2))

        ttk.Separator(form_frame).grid(
            row=4, column=0, columnspan=2, sticky="ew", padx=6, pady=6
        )
        ttk.Label(form_frame, text="Selected node").grid(
            row=5, column=0, sticky="w", padx=(6, 6), pady=2
        )
        self.node_var = self._tk.StringVar()
        self.node_box = ttk.Combobox(
            form_frame, textvariable=self.node_var, state="readonly", width=25
        )
        self.node_box.grid(row=5, column=1, sticky="ew", padx=(0, 6), pady=2)
        self.node_box.bind("<<ComboboxSelected>>", lambda _: self._select_node())

        self.terminal_var = self._tk.BooleanVar(value=False)
        ttk.Checkbutton(
            form_frame, text="Terminal node", variable=self.terminal_var
        ).grid(row=6, column=1, sticky="w", padx=(0, 6), pady=2)
        self.response_pool_var = self._tk.StringVar()
        self.response_template_var = self._tk.StringVar()
        self._add_entry(form_frame, 7, "Response pool", self.response_pool_var)
        self._add_entry(form_frame, 8, "Response template", self.response_template_var)

        gate_frame = ttk.LabelFrame(form_frame, text="Gate / engine variable")
        gate_frame.grid(row=9, column=0, columnspan=2, sticky="ew", padx=6, pady=6)
        gate_frame.columnconfigure(1, weight=1)
        self.gate_type_var = self._tk.StringVar(value="none")
        self.gate_fact_var = self._tk.StringVar()
        self.gate_field_var = self._tk.StringVar()
        self.gate_operator_var = self._tk.StringVar(value="==")
        self.gate_value_var = self._tk.StringVar()
        self.gate_start_var = self._tk.StringVar()
        self.gate_end_var = self._tk.StringVar()
        self.gate_unknown_policy_var = self._tk.StringVar(value="tri_state")
        self._add_combo(gate_frame, 0, "Type", self.gate_type_var, GATE_TYPES)
        self.fact_box = self._add_combo(gate_frame, 1, "Fact", self.gate_fact_var, ())
        self._add_combo(gate_frame, 2, "Operator", self.gate_operator_var, ("==", "~=", ">=", "<=", ">", "<", "contains"))
        self._add_entry(gate_frame, 3, "Field", self.gate_field_var)
        self._add_entry(gate_frame, 4, "Value", self.gate_value_var)
        self._add_entry(gate_frame, 5, "Start hour", self.gate_start_var)
        self._add_entry(gate_frame, 6, "End hour", self.gate_end_var)
        self._add_combo(gate_frame, 7, "Unknown", self.gate_unknown_policy_var, ("tri_state", "pass", "fail"))

        transitions_frame = ttk.LabelFrame(form_frame, text="Transitions")
        transitions_frame.grid(row=10, column=0, columnspan=2, sticky="ew", padx=6, pady=6)
        transitions_frame.columnconfigure(1, weight=1)
        self.transition_vars: dict[str, Any] = {}
        for offset, field in enumerate(TRANSITION_FIELDS):
            variable = self._tk.StringVar()
            self.transition_vars[field] = variable
            ttk.Label(transitions_frame, text=field).grid(
                row=offset, column=0, sticky="w", padx=6, pady=2
            )
            ttk.Entry(transitions_frame, textvariable=variable).grid(
                row=offset, column=1, sticky="ew", padx=(0, 6), pady=2
            )

        accepts_frame = ttk.LabelFrame(form_frame, text="Accepted frames (JSON)")
        accepts_frame.grid(row=11, column=0, columnspan=2, sticky="nsew", padx=6, pady=6)
        accepts_frame.rowconfigure(0, weight=1)
        accepts_frame.columnconfigure(0, weight=1)
        self.accepts_text = self._ScrolledText(accepts_frame, height=7, width=38, wrap="none")
        self.accepts_text.grid(row=0, column=0, sticky="nsew")

        self.apply_button = ttk.Button(
            form_frame, text="Apply node fields", command=self.apply_node_fields
        )
        self.apply_button.grid(row=12, column=1, sticky="e", padx=6, pady=(0, 6))
        codeblocks_frame = ttk.LabelFrame(form_frame, text="Declarative codeblocks · typed round trip")
        codeblocks_frame.grid(row=13, column=0, columnspan=2, sticky="nsew", padx=6, pady=6)
        codeblocks_frame.rowconfigure(0, weight=1)
        codeblocks_frame.columnconfigure(0, weight=1)
        self.codeblocks_text = self._ScrolledText(
            codeblocks_frame, height=12, width=38, wrap="none"
        )
        self.codeblocks_text.grid(row=0, column=0, sticky="nsew")
        codeblock_buttons = ttk.Frame(codeblocks_frame)
        codeblock_buttons.grid(row=1, column=0, sticky="e", pady=(6, 0))
        self.sync_codeblocks_button = ttk.Button(
            codeblock_buttons, text="Sync from graph", command=self.sync_codeblocks
        )
        self.sync_codeblocks_button.pack(side="left")
        self.validate_codeblocks_button = ttk.Button(
            codeblock_buttons, text="Validate codeblocks", command=self.validate_codeblocks
        )
        self.validate_codeblocks_button.pack(side="left", padx=6)
        self.apply_codeblocks_button = ttk.Button(
            codeblock_buttons, text="Apply codeblocks", command=self.apply_codeblocks
        )
        self.apply_codeblocks_button.pack(side="left")
        self._action_buttons = self._action_buttons + (
            self.apply_button,
            self.sync_codeblocks_button,
            self.validate_codeblocks_button,
            self.apply_codeblocks_button,
        )

    def _add_entry(self, parent: Any, row: int, label: str, variable: Any) -> None:
        self._ttk.Label(parent, text=label).grid(
            row=row, column=0, sticky="w", padx=(6, 6), pady=2
        )
        self._ttk.Entry(parent, textvariable=variable).grid(
            row=row, column=1, sticky="ew", padx=(0, 6), pady=2
        )

    def _add_combo(self, parent: Any, row: int, label: str, variable: Any, values: Any) -> Any:
        self._ttk.Label(parent, text=label).grid(
            row=row, column=0, sticky="w", padx=6, pady=2
        )
        combo = self._ttk.Combobox(
            parent, textvariable=variable, values=values, width=25,
            state="normal",
        )
        combo.grid(row=row, column=1, sticky="ew", padx=(0, 6), pady=2)
        return combo

    def set_enabled(self, enabled: bool) -> None:
        state = "normal" if enabled else "disabled"
        for button in self._action_buttons:
            button.configure(state=state)
        self.flow_list.configure(state=state)
        self.node_box.configure(state="readonly" if enabled else "disabled")
        self.codeblocks_text.configure(state=state)

    def set_status(self, value: str) -> None:
        self.status_var.set(value)

    def set_catalog(self, catalog: dict[str, Any] | list[dict[str, Any]]) -> None:
        flows = catalog.get("flows", []) if isinstance(catalog, dict) else catalog
        if isinstance(catalog, dict):
            raw_actions = catalog.get("actionCatalog", [])
            self._action_catalog = [
                copy.deepcopy(action) for action in raw_actions
                if isinstance(action, dict) and action.get("id")
            ]
            if not self._action_catalog:
                self._action_catalog = [
                    {"id": str(action), "recognized": True}
                    for action in catalog.get("commandCatalog", [])
                    if str(action)
                ]
            self._command_catalog = [
                str(action.get("id")) for action in self._action_catalog
                if action.get("id")
            ]
            self._trigger_catalog = [
                copy.deepcopy(trigger) for trigger in catalog.get("triggerCatalog", [])
                if isinstance(trigger, dict) and trigger.get("id")
            ]
            self._fact_catalog = [
                copy.deepcopy(fact) for fact in catalog.get("factCatalog", [])
                if isinstance(fact, dict) and fact.get("id")
            ]
            if hasattr(self, "fact_box"):
                self.fact_box.configure(
                    values=[fact["id"] for fact in self._fact_catalog]
                )
            generation = catalog.get("generation", {})
            raw_coverage = generation.get("coverage")
            if not isinstance(raw_coverage, list):
                raw_coverage = catalog.get("capabilityCoverage", [])
            self._coverage = [
                copy.deepcopy(row) for row in raw_coverage
                if isinstance(row, dict)
            ]
        self._catalog = {
            str(flow.get("id")): flow_draft(flow)
            for flow in flows
            if isinstance(flow, dict) and flow.get("id")
        }
        flow_ids = sorted(self._catalog)
        self._flow_id_to_label = {}
        self._flow_label_to_id = {}
        for flow_id in flow_ids:
            label = flow_display_name(flow_id, self._catalog[flow_id])
            if label in self._flow_label_to_id:
                label = f"{label} [{flow_id}]"
            self._flow_id_to_label[flow_id] = label
            self._flow_label_to_id[label] = flow_id
        selected_id = self.flow_var.get() if self.flow_var.get() in self._catalog else (
            flow_ids[0] if flow_ids else ""
        )
        self.flow_list.delete(0, "end")
        for flow_id in flow_ids:
            self.flow_list.insert("end", self._flow_id_to_label[flow_id])
        self.flow_var.set(selected_id)
        if selected_id:
            selected_index = flow_ids.index(selected_id)
            self.flow_list.selection_clear(0, "end")
            self.flow_list.selection_set(selected_index)
            self.flow_list.activate(selected_index)
            self.flow_list.see(selected_index)
        self._select_flow()
        summary = coverage_summary(self._coverage)
        if summary:
            self.set_status(
                f"{len(flow_ids)} production flows loaded · "
                f"coverage generated={summary.get('generated', 0)}"
                f"/{len(self._coverage)}"
            )
        else:
            self.set_status(f"{len(flow_ids)} production flows loaded")

    def show_coverage(self) -> None:
        if not self._coverage:
            self.set_status("No live capability coverage is loaded; refresh registry")
            return
        summary = coverage_summary(self._coverage)
        heading = ", ".join(
            f"{key}={summary[key]}" for key in sorted(summary)
        )
        self._messagebox.showinfo(
            "Semantic capability coverage",
            "Live production capability coverage: " + heading
            + "\n\n" + "\n".join(coverage_lines(self._coverage)),
        )
        self.set_status("Displayed live capability coverage and exact reasons")

    def _on_flow_list_select(self, _event: Any) -> None:
        selection = self.flow_list.curselection()
        if not selection:
            return
        label = str(self.flow_list.get(selection[0]))
        self.flow_var.set(self._flow_label_to_id.get(label, label))
        self._select_flow()

    def _select_flow_list_item(self, flow_id: str) -> None:
        items = self.flow_list.get(0, "end")
        label = self._flow_id_to_label.get(flow_id, flow_id)
        self.flow_list.selection_clear(0, "end")
        for index, item in enumerate(items):
            if str(item) == label:
                self.flow_list.selection_set(index)
                self.flow_list.activate(index)
                self.flow_list.see(index)
                return

    def select_flow(self, flow_id: str) -> None:
        """Open a registered flow selected from the interaction explorer."""

        flow_id = str(flow_id)
        if flow_id not in self._catalog:
            self.set_status(f"Flow is not in the live catalog: {flow_id}")
            return
        self.flow_var.set(flow_id)
        self._select_flow_list_item(flow_id)
        self._select_flow()

    def _select_flow(self) -> None:
        flow = self._catalog.get(self.flow_var.get())
        if flow is None:
            self._draft = None
            self._selected_node = None
            self._draw_graph()
            return
        self._draft = flow_draft(flow)
        authoring_metadata = self._draft.get("_semanticLab")
        self._nested_flows = (
            copy.deepcopy(authoring_metadata.get("nestedFlows", []))
            if isinstance(authoring_metadata, dict)
            and isinstance(authoring_metadata.get("nestedFlows"), list)
            else []
        )
        self._history = [flow_draft(self._draft)]
        self._history_index = 0
        self._node_positions = {}
        self._selected_node = self._draft.get("initial")
        if self._selected_node not in (self._draft.get("nodes") or {}):
            self._selected_node = next(iter(self._draft.get("nodes", {})), None)
        self._populate_flow_fields()
        self._populate_node_fields()
        self._draw_graph()

    def _write_text(self, widget: Any, value: str) -> None:
        widget.configure(state="normal")
        widget.delete("1.0", "end")
        widget.insert("1.0", value)

    def _read_text(self, widget: Any) -> str:
        return widget.get("1.0", "end").strip()

    def _read_codeblock_document(self) -> dict[str, Any] | None:
        try:
            document = json.loads(self._read_text(self.codeblocks_text) or "{}")
        except json.JSONDecodeError as error:
            self.set_status(f"Codeblocks JSON is invalid: {error.msg}")
            return None
        if not isinstance(document, dict):
            self.set_status("Codeblocks document must be a JSON object")
            return None
        return document

    def sync_codeblocks(self) -> None:
        if not self._draft:
            self.set_status("Select a flow before syncing codeblocks")
            return
        self._write_text(
            self.codeblocks_text,
            _json_text(flow_to_codeblocks(self._draft, nested_flows=self._nested_flows)),
        )
        self.set_status("Codeblocks synchronized from the visual graph")

    def validate_codeblocks(self) -> dict[str, Any] | None:
        document = self._read_codeblock_document()
        if document is None:
            return None
        report = validate_codeblock_document(
            document,
            known_flow_ids=self._catalog,
        )
        if report["valid"]:
            self.set_status("Codeblocks valid; no flow or worker state changed")
        else:
            message = report["diagnostics"][0]["message"] if report["diagnostics"] else "invalid codeblocks"
            self.set_status(f"Codeblocks rejected: {message}")
        return report

    def apply_codeblocks(self) -> dict[str, Any] | None:
        if not self._draft:
            self.set_status("Select a flow before applying codeblocks")
            return None
        document = self._read_codeblock_document()
        if document is None:
            return None
        before = flow_draft(self._draft)
        result = codeblocks_to_flow(
            document,
            base_flow=self._draft,
            known_flow_ids=self._catalog,
        )
        if result["valid"] is not True or not isinstance(result.get("flow"), dict):
            message = result["diagnostics"][0]["message"] if result["diagnostics"] else "invalid codeblocks"
            self.set_status(f"Codeblocks rejected: {message}")
            return result
        self._draft = flow_draft(result["flow"])
        self._nested_flows = copy.deepcopy(result.get("nestedFlows", []))
        if self._nested_flows:
            self._draft.setdefault("_semanticLab", {})["nestedFlows"] = copy.deepcopy(self._nested_flows)
        elif isinstance(self._draft.get("_semanticLab"), dict):
            self._draft["_semanticLab"].pop("nestedFlows", None)
            if not self._draft["_semanticLab"]:
                self._draft.pop("_semanticLab", None)
        self._selected_node = self._draft.get("initial")
        self._commit_history_change(before)
        self._populate_flow_fields()
        self._populate_node_fields()
        self._draw_graph()
        self.set_status(
            "Codeblocks applied to the visual graph; validate through the production Registry before registering"
        )
        return result

    def _populate_flow_fields(self) -> None:
        if not self._draft:
            return
        self.flow_id_var.set(str(self._draft.get("id", "")))
        self.owner_var.set(str(self._draft.get("owner", "")))
        self.initial_var.set(str(self._draft.get("initial", "")))
        self._write_text(self.triggers_text, _json_text(self._draft.get("triggers", [])))
        if hasattr(self, "codeblocks_text"):
            self._write_text(
                self.codeblocks_text,
                _json_text(flow_to_codeblocks(self._draft, nested_flows=self._nested_flows)),
            )

    def _populate_node_fields(self) -> None:
        nodes = self._draft.get("nodes", {}) if self._draft else {}
        node = nodes.get(self._selected_node, {}) if isinstance(nodes, dict) else {}
        node_ids = sorted(nodes) if isinstance(nodes, dict) else []
        self.node_box.configure(values=node_ids)
        self.node_var.set(self._selected_node or "")
        self.terminal_var.set(node.get("terminal") is True)
        self.response_pool_var.set(str(node.get("responsePool") or ""))
        self.response_template_var.set(str(node.get("responseTemplate") or ""))
        for field, variable in self.transition_vars.items():
            variable.set(str(node.get(field) or ""))
        self._write_text(self.accepts_text, _json_text(node.get("accepts", [])))
        gate = node.get("gate") if isinstance(node.get("gate"), dict) else {}
        self.gate_type_var.set(str(gate.get("type") or "none"))
        self.gate_fact_var.set(str(gate.get("fact") or gate.get("subject") or ""))
        self.gate_field_var.set(str(gate.get("field") or ""))
        self.gate_operator_var.set(str(gate.get("operator") or "=="))
        self.gate_value_var.set(str(gate.get("value") if gate.get("value") is not None else ""))
        self.gate_start_var.set(str(gate.get("startHour") if gate.get("startHour") is not None else ""))
        self.gate_end_var.set(str(gate.get("endHour") if gate.get("endHour") is not None else ""))
        self.gate_unknown_policy_var.set(str(gate.get("unknownPolicy") or "tri_state"))

    def _record_history(self, before: dict[str, Any] | None = None) -> None:
        snapshot = flow_draft(before if before is not None else self._draft or {})
        if self._history_index >= 0 and self._history[self._history_index] == snapshot:
            return
        self._history = self._history[: self._history_index + 1]
        self._history.append(snapshot)
        self._history_index = len(self._history) - 1

    def _restore_history(self, index: int) -> None:
        if index < 0 or index >= len(self._history):
            return
        self._draft = flow_draft(self._history[index])
        nodes = self._draft.get("nodes", {})
        if self._selected_node not in nodes:
            self._selected_node = self._draft.get("initial")
        if self._selected_node not in nodes:
            self._selected_node = next(iter(nodes), None)
        self._history_index = index
        self._populate_flow_fields()
        self._populate_node_fields()
        self._draw_graph()

    def undo(self) -> None:
        if self._history_index <= 0:
            self.set_status("Nothing to undo")
            return
        self._restore_history(self._history_index - 1)
        self.set_status("Undo")

    def redo(self) -> None:
        if self._history_index + 1 >= len(self._history):
            self.set_status("Nothing to redo")
            return
        self._restore_history(self._history_index + 1)
        self.set_status("Redo")

    def _select_node(self, node_id: str | None = None) -> None:
        selected = node_id or self.node_var.get()
        nodes = self._draft.get("nodes", {}) if self._draft else {}
        if selected not in nodes:
            return
        self._selected_node = selected
        self._populate_node_fields()
        self._draw_graph()

    def _prompt(self, title: str, prompt: str, initial: str = "") -> str | None:
        from tkinter import simpledialog

        return simpledialog.askstring(title, prompt, initialvalue=initial, parent=self.frame)

    def _choose_catalog_item(
        self,
        title: str,
        items: list[dict[str, Any]],
        display: Callable[[dict[str, Any]], str],
    ) -> dict[str, Any] | None:
        """Show a small searchable-by-selection catalog picker."""

        if not items:
            return None
        window = self._tk.Toplevel(self.frame)
        window.title(title)
        window.transient(self.frame.winfo_toplevel())
        window.geometry("620x360")
        window.columnconfigure(0, weight=1)
        window.rowconfigure(0, weight=1)
        listbox = self._tk.Listbox(window, activestyle="dotbox", selectmode="browse")
        listbox.grid(row=0, column=0, sticky="nsew", padx=(8, 0), pady=8)
        scrollbar = self._ttk.Scrollbar(window, orient="vertical", command=listbox.yview)
        scrollbar.grid(row=0, column=1, sticky="ns", padx=(0, 8), pady=8)
        listbox.configure(yscrollcommand=scrollbar.set)
        for item in items:
            listbox.insert("end", display(item))
        listbox.selection_set(0)
        listbox.activate(0)
        selected: dict[str, Any] = {"item": None}

        def accept(_event: Any = None) -> None:
            selection = listbox.curselection()
            if selection:
                selected["item"] = items[selection[0]]
            window.destroy()

        def cancel(_event: Any = None) -> None:
            window.destroy()

        buttons = self._ttk.Frame(window)
        buttons.grid(row=1, column=0, columnspan=2, sticky="e", padx=8, pady=(0, 8))
        self._ttk.Button(buttons, text="Add", command=accept).pack(side="left", padx=(0, 6))
        self._ttk.Button(buttons, text="Cancel", command=cancel).pack(side="left")
        listbox.bind("<Double-Button-1>", accept)
        window.bind("<Return>", accept)
        window.bind("<Escape>", cancel)
        window.protocol("WM_DELETE_WINDOW", cancel)
        window.grab_set()
        listbox.focus_set()
        self.frame.wait_window(window)
        return selected["item"]

    def _commit_history_change(self, before: dict[str, Any]) -> None:
        self._record_history(before)
        self._history = self._history[: self._history_index + 1]
        self._history.append(flow_draft(self._draft or {}))
        self._history_index = len(self._history) - 1

    def add_node(self) -> None:
        if not self._draft:
            self.set_status("Select a flow before adding a node")
            return
        nodes = self._draft.setdefault("nodes", {})
        initial = "node_1"
        candidate = self._prompt("Add node", "Node ID", initial)
        node_id = (candidate or "").strip()
        if not node_id:
            return
        if node_id in nodes:
            self.set_status(f"Node already exists: {node_id}")
            return
        before = flow_draft(self._draft)
        nodes[node_id] = {
            "terminal": True,
            "accepts": [],
            "responsePool": None,
            "responseTemplate": None,
        }
        if self._selected_node in nodes and self._selected_node != node_id:
            source = nodes[self._selected_node]
            if source.get("terminal") is True:
                source["terminal"] = False
            if not source.get("onMatch") and not source.get("next"):
                source["onMatch"] = node_id
        self._selected_node = node_id
        self._commit_history_change(before)
        self._populate_node_fields()
        self._draw_graph()
        self.set_status(f"Added node {node_id}")

    def duplicate_node(self) -> None:
        if not self._draft or self._selected_node not in self._draft.get("nodes", {}):
            self.set_status("Select a node before duplicating")
            return
        nodes = self._draft["nodes"]
        source = nodes[self._selected_node]
        candidate = self._prompt("Duplicate node", "New node ID", f"{self._selected_node}_copy")
        node_id = (candidate or "").strip()
        if not node_id or node_id in nodes:
            return
        before = flow_draft(self._draft)
        nodes[node_id] = flow_draft(source)
        self._selected_node = node_id
        self._commit_history_change(before)
        self._populate_node_fields()
        self._draw_graph()
        self.set_status(f"Duplicated node as {node_id}")

    def rename_node(self) -> None:
        if not self._draft or self._selected_node not in self._draft.get("nodes", {}):
            self.set_status("Select a node before renaming")
            return
        old_id = self._selected_node
        candidate = self._prompt("Rename node", "New node ID", old_id)
        new_id = (candidate or "").strip()
        if not new_id or new_id == old_id or new_id in self._draft["nodes"]:
            return
        before = flow_draft(self._draft)
        nodes = self._draft["nodes"]
        nodes[new_id] = nodes.pop(old_id)
        nodes[new_id]["id"] = new_id
        for node in nodes.values():
            for field in TRANSITION_FIELDS:
                if node.get(field) == old_id:
                    node[field] = new_id
        if self._draft.get("initial") == old_id:
            self._draft["initial"] = new_id
        self._selected_node = new_id
        self._commit_history_change(before)
        self._populate_flow_fields()
        self._populate_node_fields()
        self._draw_graph()
        self.set_status(f"Renamed node to {new_id}")

    def delete_node(self) -> None:
        if not self._draft or self._selected_node not in self._draft.get("nodes", {}):
            self.set_status("Select a node before deleting")
            return
        if len(self._draft["nodes"]) <= 1:
            self.set_status("A flow must retain at least one node")
            return
        node_id = self._selected_node
        before = flow_draft(self._draft)
        self._draft["nodes"].pop(node_id, None)
        for node in self._draft["nodes"].values():
            for field in TRANSITION_FIELDS:
                if node.get(field) == node_id:
                    node.pop(field, None)
        if self._draft.get("initial") == node_id:
            self._draft["initial"] = sorted(self._draft["nodes"])[0]
        self._selected_node = self._draft.get("initial")
        self._commit_history_change(before)
        self._populate_flow_fields()
        self._populate_node_fields()
        self._draw_graph()
        self.set_status(f"Deleted node {node_id}")

    def connect_node(self) -> None:
        if not self._draft or self._selected_node not in self._draft.get("nodes", {}):
            self.set_status("Select a source node before connecting")
            return
        target = self._prompt("Connect node", "Target node or exit (cancel/resume/suspend)")
        field = self._prompt("Connect node", "Transition field", "onMatch")
        target = (target or "").strip()
        field = (field or "").strip()
        if not target or field not in TRANSITION_FIELDS:
            return
        if target not in self._draft["nodes"] and target not in ("cancel", "resume", "suspend"):
            self.set_status(f"Unknown target: {target}")
            return
        before = flow_draft(self._draft)
        self._draft["nodes"][self._selected_node][field] = target
        self._commit_history_change(before)
        self._populate_node_fields()
        self._draw_graph()
        self.set_status(f"Connected {self._selected_node}.{field} → {target}")

    def add_trigger(self) -> None:
        if not self._draft:
            self.set_status("Select a flow before adding a trigger")
            return
        frame: dict[str, Any] | None = None
        selected_trigger: dict[str, Any] | None = None
        if self._trigger_catalog:
            custom = {
                "id": "<custom>",
                "label": "Custom JSON frame",
                "frame": None,
            }
            selected_trigger = self._choose_catalog_item(
                "Add semantic trigger",
                self._trigger_catalog + [custom],
                lambda item: (
                    f"{item['id']}  ·  {item.get('label', '')}"
                    if item.get("id") != "<custom>"
                    else item["label"]
                ),
            )
            if selected_trigger is None:
                return
            if selected_trigger.get("id") != "<custom>":
                candidate = selected_trigger.get("frame")
                frame = copy.deepcopy(candidate) if isinstance(candidate, dict) else None

        if frame is None:
            raw = self._prompt(
                "Add trigger frame",
                "Trigger JSON (include intent/speechAct/action/subject)",
                '{"intent":"GREET","speechAct":"GREET"}',
            )
            if not raw:
                return
            try:
                frame = json.loads(raw)
            except json.JSONDecodeError as error:
                self.set_status(f"Trigger JSON is invalid: {error.msg}")
                return
        if not isinstance(frame, dict) or not frame:
            self.set_status("Trigger must be a non-empty JSON object")
            return
        before = flow_draft(self._draft)
        self._draft.setdefault("triggers", []).append(frame)
        self._commit_history_change(before)
        self._populate_flow_fields()
        self._draw_graph()
        self.set_status(
            f"Trigger {selected_trigger.get('id')} added; validate before registering"
            if selected_trigger and selected_trigger.get("id") != "<custom>"
            else "Trigger added; validate before registering"
        )

    def add_command_trigger(self) -> None:
        if not self._draft:
            self.set_status("Select a flow before adding an action trigger")
            return
        selected_action: dict[str, Any] | None = None
        if self._action_catalog:
            selected_action = self._choose_catalog_item(
                "Add semantic action trigger",
                self._action_catalog,
                lambda item: (
                    f"{item['id']}  ·  "
                    f"{', '.join(item.get('transports', [])) or 'policy only'}"
                    + (
                        f"  ·  {item['binding'].get('id')}"
                        f" → {item['binding'].get('commandID')}"
                        if isinstance(item.get('binding'), dict)
                        else "  ·  recognition only"
                    )
                ),
            )
            if selected_action is None:
                return
            action = str(selected_action.get("id", "")).upper()
        else:
            default = self._command_catalog[0] if self._command_catalog else "FOLLOW"
            action = self._prompt(
                "Add semantic action trigger",
                "Action (from the live semantic capability catalog)",
                default,
            )
            action = (action or "").strip().upper()
            if not action:
                return
        if self._command_catalog and action not in self._command_catalog:
            self.set_status(f"Unknown command action: {action}")
            return
        action_frame = (
            copy.deepcopy(selected_action.get("frame"))
            if selected_action and isinstance(selected_action.get("frame"), dict)
            else {
                "intent": "REQUEST",
                "speechAct": "REQUEST",
                "action": action,
            }
        )
        before = flow_draft(self._draft)
        self._draft.setdefault("triggers", []).append(action_frame)
        self._commit_history_change(before)
        self._populate_flow_fields()
        self._draw_graph()
        binding = selected_action.get("binding") if selected_action else None
        if isinstance(binding, dict):
            self.set_status(
                f"Trigger {action} added; binding {binding.get('id')} → "
                f"{binding.get('handlerID')} ({binding.get('commandID')}); "
                "trigger only—Preview never dispatches"
            )
        else:
            self.set_status(
                f"Trigger {action} added; recognition only—no executable binding"
            )

    def _parse_array(self, widget: Any, label: str) -> list[Any]:
        try:
            value = json.loads(self._read_text(widget) or "[]")
        except json.JSONDecodeError as error:
            raise ValueError(f"{label} is not valid JSON: {error.msg}") from error
        if not isinstance(value, list):
            raise ValueError(f"{label} must be a JSON array")
        return value

    def _commit_fields(self) -> dict[str, Any] | None:
        if not self._draft:
            self.set_status("Select a production flow or open a draft first")
            return None
        before = flow_draft(self._draft)
        draft = flow_draft(self._draft)
        flow_id = self.flow_id_var.get().strip()
        owner = self.owner_var.get().strip()
        initial = self.initial_var.get().strip()
        if not flow_id or not owner or not initial:
            self.set_status("Flow ID, owner, and initial node are required")
            return None
        try:
            triggers = self._parse_array(self.triggers_text, "Triggers")
            accepts = self._parse_array(self.accepts_text, "Accepted frames")
        except ValueError as error:
            self.set_status(str(error))
            return None
        draft["id"] = flow_id
        draft["owner"] = owner
        draft["initial"] = initial
        draft["triggers"] = triggers
        nodes = draft.setdefault("nodes", {})
        if self._selected_node not in nodes:
            self.set_status("Select a valid node before applying fields")
            return None
        node = nodes[self._selected_node]
        node["terminal"] = self.terminal_var.get() is True
        node["responsePool"] = self.response_pool_var.get().strip() or None
        node["responseTemplate"] = self.response_template_var.get().strip() or None
        for field, variable in self.transition_vars.items():
            value = variable.get().strip()
            if value:
                node[field] = value
            else:
                node.pop(field, None)
        node["accepts"] = accepts
        gate_type = self.gate_type_var.get().strip() or "none"
        if gate_type == "none":
            node.pop("gate", None)
        else:
            gate = copy.deepcopy(node.get("gate")) if isinstance(node.get("gate"), dict) else {}
            gate["type"] = gate_type
            fact = self.gate_fact_var.get().strip()
            field = self.gate_field_var.get().strip()
            operator = self.gate_operator_var.get().strip()
            value = self.gate_value_var.get().strip()
            start_hour = self.gate_start_var.get().strip()
            end_hour = self.gate_end_var.get().strip()
            unknown_policy = self.gate_unknown_policy_var.get().strip()
            if fact:
                gate["fact"] = fact
            elif gate_type == "pnc:fact":
                gate.pop("fact", None)
            if field:
                gate["field"] = field
            else:
                gate.pop("field", None)
            if operator:
                gate["operator"] = operator
            if value:
                gate["value"] = value
            else:
                gate.pop("value", None)
            for key, raw in (("startHour", start_hour), ("endHour", end_hour)):
                if raw:
                    try:
                        gate[key] = float(raw)
                    except ValueError:
                        self.set_status(f"{key} must be numeric")
                        return None
                else:
                    gate.pop(key, None)
            if unknown_policy in ("pass", "fail"):
                gate["unknownPolicy"] = unknown_policy
            else:
                gate.pop("unknownPolicy", None)
            node["gate"] = gate
        self._draft = draft
        if draft != before:
            self._commit_history_change(before)
        self._populate_flow_fields()
        self._populate_node_fields()
        self._draw_graph()
        return draft

    def apply_node_fields(self) -> None:
        if self._commit_fields() is not None:
            self.set_status("Draft fields applied; validate before registering")

    def validate_draft(self) -> None:
        draft = self._commit_fields()
        if draft is not None:
            self._on_validate(flow_draft(draft))

    def register_draft(self) -> None:
        draft = self._commit_fields()
        if draft is None:
            return
        if draft.get("workflowKind") and draft.get("id") in self._catalog:
            self.set_status(
                "Generated flow is regeneration-owned; rename or duplicate "
                "the draft before authored registration"
            )
            return
        self._on_register(flow_draft(draft))

    def compile_source(self) -> None:
        filename = self._filedialog.askopenfilename(
            title="Preview canonical semantic source",
            filetypes=[("Semantic definitions", "*.json"), ("All files", "*")],
        )
        if not filename:
            return
        if self._on_compile_source is None:
            self.set_status("Compiler preview is unavailable")
            return
        self._on_compile_source(Path(filename))

    def generate_source(self) -> None:
        filename = self._filedialog.askopenfilename(
            title="Generate approved semantic source",
            filetypes=[("Semantic definitions", "*.json"), ("All files", "*")],
        )
        if not filename:
            return
        if self._on_generate_source is None:
            self.set_status("Source generation is unavailable")
            return
        if not self._messagebox.askyesno(
            "Generate semantic source",
            "Write the validated Lua, EN/TL, and manifest artifacts and restart the worker?",
        ):
            self.set_status("Source generation cancelled; preview remains unchanged")
            return
        self._on_generate_source(Path(filename))

    def review_dataset(self) -> None:
        filename = self._filedialog.askopenfilename(
            title="Review dialogue dataset candidates",
            filetypes=[("Dialogue datasets", "*.json"), ("All files", "*")],
        )
        if not filename:
            return
        if self._on_review_dataset is None:
            self.set_status("Dataset review is unavailable")
            return
        self._on_review_dataset(Path(filename))

    def generate_dataset(self) -> None:
        filename = self._filedialog.askopenfilename(
            title="Generate approved dialogue artifacts",
            filetypes=[("Dialogue datasets", "*.json"), ("All files", "*")],
        )
        if not filename:
            return
        if self._on_generate_dataset is None:
            self.set_status("Dialogue generation is unavailable")
            return
        if not self._messagebox.askyesno(
            "Generate dialogue artifacts",
            "Write the reviewed Lua, EN/TL, and manifest artifacts and restart the worker?",
        ):
            self.set_status("Dialogue generation cancelled; diff preview remains unchanged")
            return
        self._on_generate_dataset(Path(filename))

    def show_source_report(self, report: dict[str, Any]) -> None:
        if report.get("ok") is True:
            writes = report.get("writes") or []
            if writes:
                self.set_status(
                    "Generated and ready for worker restart "
                    f"({len(writes)} files written)"
                )
                return
            self.set_status(
                "Compiler preview valid; no files written "
                f"({len(report.get('generatedPaths', []))} planned paths)"
            )
        else:
            diagnostics = report.get("diagnostics") or []
            message = diagnostics[0].get("message") if diagnostics else "invalid source"
            self.set_status(f"Compiler preview rejected: {message}")

    def show_dataset_report(self, report: dict[str, Any]) -> None:
        review = report.get("candidateReview") or {}
        summary = review.get("summary") or {}
        collisions = review.get("collisions") or []
        artifact_diffs = report.get("artifactDiffs") or []
        writes = report.get("writes") or []
        changed = sum(
            1 for row in artifact_diffs
            if isinstance(row, dict) and row.get("status") != "unchanged"
        )
        if report.get("ok") is True:
            write_status = (
                f"{len(writes)} files written; worker restart required"
                if writes else "no files written"
            )
            self.set_status(
                "Dataset preview valid; "
                f"{summary.get('approved', 0)} approved, "
                f"{summary.get('rejected', 0)} rejected, "
                f"{len(collisions)} collisions, {changed} artifact diffs, {write_status}"
            )
            return
        diagnostics = report.get("diagnostics") or []
        message = diagnostics[0].get("message") if diagnostics else "invalid dataset"
        self.set_status(
            "Dataset preview rejected; "
            f"{summary.get('rejected', 0)} rejected, {len(collisions)} collisions, "
            f"{changed} artifact diffs: {message}"
        )

    def show_validation(self, response: dict[str, Any]) -> None:
        if response.get("valid") is True:
            normalized = response.get("definition")
            if isinstance(normalized, dict):
                self._draft = flow_draft(normalized)
                self._history = [flow_draft(self._draft)]
                self._history_index = 0
                self._populate_flow_fields()
                self._populate_node_fields()
                self._draw_graph()
            self.set_status("Production Registry.Validate: valid")
        else:
            self.set_status(f"Production Registry.Validate: {response.get('reason', 'invalid')}")

    def show_registration(self, response: dict[str, Any]) -> None:
        if response.get("registered") is True:
            self.set_catalog(response)
            definition = response.get("definition") or {}
            flow_id = str(definition.get("id", self.flow_var.get()))
            self.flow_var.set(flow_id)
            self._select_flow_list_item(flow_id)
            self._select_flow()
            self.set_status(
                f"Registered {definition.get('id', 'flow')} through production Registry"
            )
        else:
            self.set_status(
                f"Register rejected: {response.get('reason', 'unknown error')}"
            )

    def save_draft(self) -> None:
        draft = self._commit_fields()
        if draft is None:
            return
        filename = self._filedialog.asksaveasfilename(
            title="Save semantic flow draft",
            defaultextension=".json",
            filetypes=[("Flow definitions", "*.json"), ("All files", "*")],
        )
        if not filename:
            return
        if self._nested_flows:
            draft.setdefault("_semanticLab", {})["nestedFlows"] = copy.deepcopy(self._nested_flows)
        try:
            Path(filename).write_text(
                json.dumps(draft, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
            )
        except OSError as error:
            self._messagebox.showerror("Flow draft error", str(error))
            return
        self.set_status(f"Saved draft {Path(filename).name}")

    def load_draft(self) -> None:
        filename = self._filedialog.askopenfilename(
            title="Open semantic flow draft",
            filetypes=[("Flow definitions", "*.json"), ("All files", "*")],
        )
        if not filename:
            return
        try:
            loaded = json.loads(Path(filename).read_text(encoding="utf-8"))
            if not isinstance(loaded, dict) or not isinstance(loaded.get("nodes"), dict):
                raise ValueError("flow draft must contain an object-valued nodes field")
        except (OSError, ValueError, json.JSONDecodeError) as error:
            self._messagebox.showerror("Flow draft error", str(error))
            return
        self._draft = flow_draft(loaded)
        authoring_metadata = loaded.get("_semanticLab")
        self._nested_flows = (
            copy.deepcopy(authoring_metadata.get("nestedFlows", []))
            if isinstance(authoring_metadata, dict)
            and isinstance(authoring_metadata.get("nestedFlows"), list)
            else []
        )
        self._history = [flow_draft(self._draft)]
        self._history_index = 0
        self._node_positions = {}
        self.flow_var.set(str(loaded.get("id", "draft")))
        self.flow_list.selection_clear(0, "end")
        self._selected_node = loaded.get("initial")
        if self._selected_node not in loaded.get("nodes", {}):
            self._selected_node = next(iter(loaded.get("nodes", {})), None)
        self._populate_flow_fields()
        self._populate_node_fields()
        self._draw_graph()
        self.set_status(f"Opened draft {Path(filename).name}; validate before registering")

    def _canvas_point(self, event: Any) -> tuple[float, float]:
        canvasx = getattr(self.canvas, "canvasx", None)
        canvasy = getattr(self.canvas, "canvasy", None)
        return (
            float(canvasx(event.x) if canvasx else event.x),
            float(canvasy(event.y) if canvasy else event.y),
        )

    def _on_mouse_wheel(self, event: Any) -> None:
        delta = getattr(event, "delta", 0)
        self._zoom_at(event, 1.12 if delta > 0 else 1 / 1.12)

    def _zoom_at(self, event: Any, factor: float) -> None:
        point = self._canvas_point(event)
        old_zoom = self._zoom
        new_zoom = max(0.35, min(2.5, old_zoom * factor))
        if new_zoom == old_zoom:
            return
        model_point = graph_inverse(point, old_zoom, self._pan)
        self._zoom = new_zoom
        self._pan = (
            point[0] - model_point[0] * new_zoom,
            point[1] - model_point[1] * new_zoom,
        )
        self.zoom_button.configure(text=f"{round(new_zoom * 100):d}%")
        self._draw_graph()

    def _start_pan(self, event: Any) -> None:
        self._pan_anchor = self._canvas_point(event)
        self._pan_origin = self._pan

    def _drag_pan(self, event: Any) -> None:
        if self._pan_anchor is None or self._pan_origin is None:
            return
        point = self._canvas_point(event)
        self._pan = (
            self._pan_origin[0] + point[0] - self._pan_anchor[0],
            self._pan_origin[1] + point[1] - self._pan_anchor[1],
        )
        self._draw_graph()

    def _stop_pan(self, _event: Any) -> None:
        self._pan_anchor = None
        self._pan_origin = None

    def _node_id_at(self, event: Any) -> str | None:
        """Resolve a left-click to a node without relying on item bindings."""

        point = self._canvas_point(event)
        items = self.canvas.find_overlapping(
            point[0] - 2, point[1] - 2, point[0] + 2, point[1] + 2,
        )
        for item_id in reversed(items):
            for tag in self.canvas.gettags(item_id):
                if tag.startswith("node:"):
                    return tag[5:]
        return None

    def _on_canvas_left_down(self, event: Any) -> None:
        node_id = self._node_id_at(event)
        if node_id is not None:
            self._start_node_drag(event, node_id)

    def _start_node_drag(self, event: Any, node_id: str) -> None:
        self._select_node(node_id)
        self._drag_node = node_id
        self._drag_anchor = graph_inverse(self._canvas_point(event), self._zoom, self._pan)
        self._drag_origin = self._node_positions.get(node_id, self._drag_anchor)

    def _drag_node_motion(self, event: Any) -> None:
        if not self._drag_node or self._drag_anchor is None:
            return
        current = graph_inverse(self._canvas_point(event), self._zoom, self._pan)
        origin = self._drag_origin or self._drag_anchor
        self._node_positions[self._drag_node] = (
            origin[0] + current[0] - self._drag_anchor[0],
            origin[1] + current[1] - self._drag_anchor[1],
        )
        self._draw_graph()

    def _stop_node_drag(self, _event: Any) -> None:
        self._drag_node = None
        self._drag_anchor = None
        self._drag_origin = None

    def reset_zoom(self) -> None:
        self._zoom = 1.0
        self._pan = (24.0, 42.0)
        self.zoom_button.configure(text="100%")
        self._draw_graph()

    def fit_graph(self) -> None:
        if not self._node_positions:
            return
        width = max(1.0, float(self.canvas.winfo_width() or 680))
        height = max(1.0, float(self.canvas.winfo_height() or 560))
        min_x = min(point[0] for point in self._node_positions.values())
        min_y = min(point[1] for point in self._node_positions.values())
        max_x = max(point[0] + 245 for point in self._node_positions.values())
        max_y = max(point[1] + 82 for point in self._node_positions.values())
        self._zoom = max(0.35, min(2.5, min((width - 50) / (max_x - min_x), (height - 70) / (max_y - min_y))))
        self._pan = (
            (width - (max_x - min_x) * self._zoom) / 2 - min_x * self._zoom,
            (height - (max_y - min_y) * self._zoom) / 2 - min_y * self._zoom,
        )
        self.zoom_button.configure(text=f"{round(self._zoom * 100):d}%")
        self._draw_graph()

    def _draw_graph(self) -> None:
        self.canvas.delete("all")
        if not self._draft:
            self.graph_hint_var.set("Select a production flow")
            self.canvas.configure(scrollregion=(0, 0, 720, 600))
            return
        try:
            model = flow_graph_model(self._draft)
        except ValueError as error:
            self.graph_hint_var.set(str(error))
            self.canvas.configure(scrollregion=(0, 0, 720, 600))
            return

        display_name = flow_display_name(model["flowID"], self._draft)
        workflow = (
            f"  ·  {model['workflowKind']}"
            if model.get("generated") and model.get("workflowKind")
            else ""
        )
        self.graph_hint_var.set(
            f"{display_name}{workflow}  ·  triggers {len(model['triggers'])}  ·  "
            f"zoom {round(self._zoom * 100)}%  ·  left-drag nodes · middle-drag map"
        )
        nodes = model["nodes"]
        box_width = 245.0
        box_height = 82.0
        render_mode = graph_render_mode(self._zoom)
        # Geometry is zoomed, but text must remain legible and stay inside the
        # now-smaller node rectangle.  At low zoom the graph is intentionally
        # an overview: branches remain visible while secondary metadata is
        # omitted until the user zooms back in.
        font_size = max(7, min(16, int(round(11 * self._zoom))))
        small_font_size = max(6, font_size - 1)
        padding = max(4.0, 10.0 * self._zoom)
        title_gap = max(9.0, 34.0 * self._zoom)
        status_gap = max(18.0, 59.0 * self._zoom)
        edge_aliases = {
            "next": "N",
            "onMatch": "M",
            "onRefuse": "R",
            "onUnrelated": "U",
            "onPass": "P",
            "onFail": "F",
            "onUnknown": "?",
        }

        def edge_color(field: str) -> str:
            if field == "onPass":
                return "#78c091"
            if field == "onFail":
                return "#e18d83"
            if field == "onUnknown":
                return "#e7c56d"
            if field.startswith("result:"):
                outcome = field.split(":", 1)[1]
                return {
                    "queued": "#78c091",
                    "rejected": "#e18d83",
                    "failed": "#d99b7b",
                }.get(outcome, "#b58bd4")
            return "#6fa8dc"

        def compact_text(value: Any, max_chars: int) -> str:
            text = str(value)
            if len(text) <= max_chars:
                return text
            if max_chars <= 1:
                return "…"
            return text[:max_chars - 1] + "…"

        def text_capacity(width: float, size: int) -> int:
            # Tk's default font is approximately 0.6em wide for these labels.
            return max(1, int(max(1.0, width - (padding * 2)) / (size * 0.6)))

        positions: dict[str, tuple[float, float]] = {}
        for index, node in enumerate(nodes):
            if node["id"] in self._node_positions:
                positions[node["id"]] = self._node_positions[node["id"]]
            else:
                positions[node["id"]] = (70 + (index % 3) * 330, 82 + (index // 3) * 150)
        self._node_positions = positions

        def screen(point: tuple[float, float]) -> tuple[float, float]:
            return graph_transform(point, self._zoom, self._pan)

        for edge_index, edge in enumerate(model["edges"]):
            source = positions.get(edge["fromNodeID"])
            target = positions.get(edge["toNodeID"])
            color = edge_color(edge["field"])
            if source and target:
                if target[0] >= source[0]:
                    start = (source[0] + box_width, source[1] + box_height / 2)
                    finish = (target[0], target[1] + box_height / 2)
                else:
                    start = (source[0], source[1] + box_height / 2)
                    finish = (target[0] + box_width, target[1] + box_height / 2)
                sx, sy = screen(start)
                tx, ty = screen(finish)
                lane = (edge_index % 3 - 1) * 10 * self._zoom
                self.canvas.create_line(
                    sx, sy, (sx + tx) / 2 + lane, (sy + ty) / 2 + lane, tx, ty,
                    fill=color, arrow="last", width=max(1, int(2 * self._zoom)),
                )
                if render_mode != "overview":
                    label = edge["field"] if render_mode == "detail" else edge_aliases.get(edge["field"], "R")
                    self.canvas.create_text(
                        (sx + tx) / 2 + lane, (sy + ty) / 2 + lane,
                        fill=color, text=label, font=("TkDefaultFont", small_font_size),
                    )
            elif source:
                # Exit branches leave the card in their own vertical lane so
                # their labels never sit on top of a neighboring node.
                source_exits = sum(
                    1 for prior in model["edges"][:edge_index]
                    if prior["fromNodeID"] == edge["fromNodeID"]
                    and not prior["internal"]
                )
                lane_offset = (-1 if source_exits % 2 == 0 else 1) * (
                    box_height / 2 + 24 + (source_exits // 2) * 26
                )
                start = (source[0] + box_width, source[1] + box_height / 2)
                end = (
                    source[0] + box_width + 90,
                    source[1] + box_height / 2 + lane_offset,
                )
                sx, sy = screen(start)
                tx, ty = screen(end)
                self.canvas.create_line(
                    sx, sy, tx, ty, fill="#ffb4ab",
                    arrow="last", width=max(1, int(2 * self._zoom)),
                )
                if render_mode != "overview":
                    field = edge["field"] if render_mode == "detail" else edge_aliases.get(edge["field"], "R")
                    target = compact_text(edge["toNodeID"], 12 if render_mode == "compact" else 24)
                    self.canvas.create_text(
                        tx + max(4.0, 8.0 * self._zoom), ty, anchor="w", fill="#ffb4ab",
                        text=f"{field} → {target}", font=("TkDefaultFont", small_font_size),
                    )

        for node in nodes:
            x, y = screen(positions[node["id"]])
            width = box_width * self._zoom
            height = box_height * self._zoom
            selected = node["id"] == self._selected_node
            fill = "#604d2a" if selected else "#202b36"
            outline = "#f0c674" if selected else "#6fa8dc"
            if node["terminal"] and not selected:
                fill = "#1f473d"
            tag = f"node:{node['id']}"
            self.canvas.create_rectangle(
                x, y, x + width, y + height,
                fill=fill, outline=outline, width=max(1, int(2 * self._zoom)),
                tags=(tag,),
            )
            gate = node.get("gate") or {}
            gate_label = gate.get("fact") or gate.get("type") or "no gate"
            suffix = "terminal" if node["terminal"] else f"accepts {len(node['accepts'])}"
            title_chars = text_capacity(width, font_size)
            self.canvas.create_text(
                x + padding, y + padding, anchor="nw", fill="#ffffff",
                text=compact_text(node["id"], title_chars),
                font=("TkDefaultFont", font_size), width=max(1, width - padding * 2),
                tags=(tag,),
            )
            if render_mode == "overview":
                status = "T" if node["terminal"] else f"A{len(node['accepts'])}"
                if gate:
                    status += " · G"
                self.canvas.create_text(
                    x + padding, y + status_gap, anchor="nw", fill="#9bd3ae",
                    text=status, font=("TkDefaultFont", small_font_size),
                    width=max(1, width - padding * 2), tags=(tag,),
                )
            else:
                pool = node.get("responsePool") or node.get("responseTemplate") or "no response pool"
                pool_chars = text_capacity(width, small_font_size)
                self.canvas.create_text(
                    x + padding, y + title_gap, anchor="nw", fill="#b9c8d6",
                    text=compact_text(pool, pool_chars),
                    font=("TkDefaultFont", small_font_size), width=max(1, width - padding * 2),
                    tags=(tag,),
                )
                action = node.get("action") if isinstance(node.get("action"), dict) else {}
                action_label = action.get("capabilityID") or action.get("route")
                suffix = f"{suffix} · {action_label}" if action_label else suffix
                suffix_chars = text_capacity(width, small_font_size)
                self.canvas.create_text(
                    x + padding, y + status_gap, anchor="nw", fill="#9bd3ae",
                    text=compact_text(f"{suffix} · {gate_label}", suffix_chars),
                    font=("TkDefaultFont", small_font_size), width=max(1, width - padding * 2),
                    tags=(tag,),
                )
            if node["id"] == model["initial"]:
                self.canvas.create_text(
                    x - max(5.0, 10.0 * self._zoom), y + max(8.0, 16.0 * self._zoom),
                    anchor="e", fill="#f0c674", text="I" if render_mode == "overview" else "initial",
                    font=("TkDefaultFont", small_font_size),
                )

        width = max(720, int(max((screen((x + box_width, y + box_height))[0] for x, y in positions.values()), default=720) + 80))
        height = max(600, int(max((screen((x + box_width, y + box_height))[1] for x, y in positions.values()), default=600) + 80))
        self.canvas.configure(scrollregion=(-500, -300, width, height))
