"""Production-flow graph model and the Semantic Lab visual editor pane."""

from __future__ import annotations

import copy
import json
from pathlib import Path
from typing import Any, Callable


TRANSITION_FIELDS = ("next", "onMatch", "onRefuse", "onUnrelated")


def flow_draft(flow: dict[str, Any]) -> dict[str, Any]:
    """Return an editable copy of one normalized production flow."""

    return copy.deepcopy(flow)


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
        node_rows.append({
            "id": node_id,
            "terminal": node.get("terminal") is True,
            "responsePool": node.get("responsePool"),
            "responseTemplate": node.get("responseTemplate"),
            "accepts": copy.deepcopy(node.get("accepts", [])),
            "slots": copy.deepcopy(node.get("slots", {})),
            "transitions": transitions,
        })
        for field, target in transitions.items():
            edges.append({
                "fromNodeID": node_id,
                "field": field,
                "toNodeID": target,
                "internal": target in nodes,
            })

    return {
        "schemaVersion": 1,
        "flowID": flow.get("id"),
        "owner": flow.get("owner"),
        "version": flow.get("version"),
        "initial": flow.get("initial"),
        "triggers": copy.deepcopy(flow.get("triggers", [])),
        "nodes": node_rows,
        "edges": edges,
    }


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
    ) -> None:
        self._tk = tk_module
        self._ttk = ttk
        self._ScrolledText = scrolled_text
        self._filedialog = filedialog
        self._messagebox = messagebox
        self._on_refresh = on_refresh
        self._on_validate = on_validate
        self._on_register = on_register
        self._catalog: dict[str, dict[str, Any]] = {}
        self._draft: dict[str, Any] | None = None
        self._selected_node: str | None = None
        self._node_positions: dict[str, tuple[float, float]] = {}

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
        toolbar.columnconfigure(1, weight=1)
        ttk.Label(toolbar, text="Production flow").grid(row=0, column=0, padx=(0, 6))
        self.flow_var = self._tk.StringVar()
        self.flow_box = ttk.Combobox(
            toolbar, textvariable=self.flow_var, state="readonly", width=22
        )
        self.flow_box.grid(row=0, column=1, sticky="w")
        self.flow_box.bind("<<ComboboxSelected>>", lambda _: self._select_flow())

        self.refresh_button = ttk.Button(
            toolbar, text="Refresh registry", command=self._on_refresh
        )
        self.refresh_button.grid(row=0, column=2, padx=(8, 0))
        self.validate_button = ttk.Button(
            toolbar, text="Validate draft", command=self.validate_draft
        )
        self.validate_button.grid(row=0, column=3, padx=(6, 0))
        self.register_button = ttk.Button(
            toolbar, text="Register draft", command=self.register_draft
        )
        self.register_button.grid(row=0, column=4, padx=(6, 0))
        self.load_button = ttk.Button(
            toolbar, text="Open draft", command=self.load_draft
        )
        self.load_button.grid(row=0, column=5, padx=(6, 0))
        self.save_button = ttk.Button(
            toolbar, text="Save draft", command=self.save_draft
        )
        self.save_button.grid(row=0, column=6, padx=(6, 0))
        self.status_var = self._tk.StringVar()
        ttk.Label(toolbar, textvariable=self.status_var).grid(
            row=0, column=7, sticky="e", padx=(10, 0)
        )
        toolbar.columnconfigure(7, weight=1)
        self._action_buttons = (
            self.refresh_button,
            self.validate_button,
            self.register_button,
            self.load_button,
            self.save_button,
        )

    def _build_body(self) -> None:
        ttk = self._ttk
        body = ttk.PanedWindow(self.frame, orient="horizontal")
        body.grid(row=1, column=0, sticky="nsew")

        graph_frame = ttk.LabelFrame(body, text="Flow graph · nodes and transitions")
        graph_frame.rowconfigure(0, weight=1)
        graph_frame.columnconfigure(0, weight=1)
        self.canvas = self._tk.Canvas(
            graph_frame,
            width=680,
            height=560,
            background="#10151b",
            highlightthickness=0,
        )
        self.canvas.grid(row=0, column=0, sticky="nsew")
        y_scroll = ttk.Scrollbar(
            graph_frame, orient="vertical", command=self.canvas.yview
        )
        y_scroll.grid(row=0, column=1, sticky="ns")
        x_scroll = ttk.Scrollbar(
            graph_frame, orient="horizontal", command=self.canvas.xview
        )
        x_scroll.grid(row=1, column=0, sticky="ew")
        self.canvas.configure(xscrollcommand=x_scroll.set, yscrollcommand=y_scroll.set)
        body.add(graph_frame, weight=3)

        form_frame = ttk.LabelFrame(body, text="Editable flow definition")
        form_frame.columnconfigure(1, weight=1)
        form_frame.rowconfigure(10, weight=1)
        body.add(form_frame, weight=2)

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

        transitions_frame = ttk.LabelFrame(form_frame, text="Transitions")
        transitions_frame.grid(row=9, column=0, columnspan=2, sticky="ew", padx=6, pady=6)
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
        accepts_frame.grid(row=10, column=0, columnspan=2, sticky="nsew", padx=6, pady=6)
        accepts_frame.rowconfigure(0, weight=1)
        accepts_frame.columnconfigure(0, weight=1)
        self.accepts_text = self._ScrolledText(accepts_frame, height=7, width=38, wrap="none")
        self.accepts_text.grid(row=0, column=0, sticky="nsew")

        self.apply_button = ttk.Button(
            form_frame, text="Apply node fields", command=self.apply_node_fields
        )
        self.apply_button.grid(row=11, column=1, sticky="e", padx=6, pady=(0, 6))
        self._action_buttons = self._action_buttons + (self.apply_button,)

    def _add_entry(self, parent: Any, row: int, label: str, variable: Any) -> None:
        self._ttk.Label(parent, text=label).grid(
            row=row, column=0, sticky="w", padx=(6, 6), pady=2
        )
        self._ttk.Entry(parent, textvariable=variable).grid(
            row=row, column=1, sticky="ew", padx=(0, 6), pady=2
        )

    def set_enabled(self, enabled: bool) -> None:
        state = "normal" if enabled else "disabled"
        for button in self._action_buttons:
            button.configure(state=state)
        self.flow_box.configure(state="readonly" if enabled else "disabled")
        self.node_box.configure(state="readonly" if enabled else "disabled")

    def set_status(self, value: str) -> None:
        self.status_var.set(value)

    def set_catalog(self, catalog: dict[str, Any] | list[dict[str, Any]]) -> None:
        flows = catalog.get("flows", []) if isinstance(catalog, dict) else catalog
        self._catalog = {
            str(flow.get("id")): flow_draft(flow)
            for flow in flows
            if isinstance(flow, dict) and flow.get("id")
        }
        flow_ids = sorted(self._catalog)
        self.flow_box.configure(values=flow_ids)
        if self.flow_var.get() not in self._catalog:
            self.flow_var.set(flow_ids[0] if flow_ids else "")
        self._select_flow()
        self.set_status(f"{len(flow_ids)} production flows loaded")

    def _select_flow(self) -> None:
        flow = self._catalog.get(self.flow_var.get())
        if flow is None:
            self._draft = None
            self._selected_node = None
            self._draw_graph()
            return
        self._draft = flow_draft(flow)
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

    def _populate_flow_fields(self) -> None:
        if not self._draft:
            return
        self.flow_id_var.set(str(self._draft.get("id", "")))
        self.owner_var.set(str(self._draft.get("owner", "")))
        self.initial_var.set(str(self._draft.get("initial", "")))
        self._write_text(self.triggers_text, _json_text(self._draft.get("triggers", [])))

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

    def _select_node(self, node_id: str | None = None) -> None:
        selected = node_id or self.node_var.get()
        nodes = self._draft.get("nodes", {}) if self._draft else {}
        if selected not in nodes:
            return
        self._selected_node = selected
        self._populate_node_fields()
        self._draw_graph()

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
        self._draft = draft
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
        if draft is not None:
            self._on_register(flow_draft(draft))

    def show_validation(self, response: dict[str, Any]) -> None:
        if response.get("valid") is True:
            normalized = response.get("definition")
            if isinstance(normalized, dict):
                self._draft = flow_draft(normalized)
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
            self.flow_var.set(str(definition.get("id", self.flow_var.get())))
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
        self.flow_var.set(str(loaded.get("id", "draft")))
        self._selected_node = loaded.get("initial")
        if self._selected_node not in loaded.get("nodes", {}):
            self._selected_node = next(iter(loaded.get("nodes", {})), None)
        self._populate_flow_fields()
        self._populate_node_fields()
        self._draw_graph()
        self.set_status(f"Opened draft {Path(filename).name}; validate before registering")

    def _draw_graph(self) -> None:
        self.canvas.delete("all")
        if not self._draft:
            self.canvas.create_text(24, 24, anchor="nw", fill="#c5d0dc", text="No flow selected")
            self.canvas.configure(scrollregion=(0, 0, 720, 600))
            return
        try:
            model = flow_graph_model(self._draft)
        except ValueError as error:
            self.canvas.create_text(24, 24, anchor="nw", fill="#ffb4ab", text=str(error))
            self.canvas.configure(scrollregion=(0, 0, 720, 600))
            return

        self.canvas.create_text(
            18, 16, anchor="nw", fill="#f0c674",
            text=f"{model['flowID']}  ·  trigger frames: {len(model['triggers'])}",
        )
        nodes = model["nodes"]
        positions: dict[str, tuple[float, float]] = {}
        box_width = 245
        box_height = 82
        for index, node in enumerate(nodes):
            column = index % 2
            row = index // 2
            positions[node["id"]] = (70 + column * 310, 82 + row * 138)
        self._node_positions = positions

        for edge in model["edges"]:
            source = positions.get(edge["fromNodeID"])
            target = positions.get(edge["toNodeID"])
            if source and target:
                self.canvas.create_line(
                    source[0] + box_width / 2,
                    source[1] + box_height,
                    target[0] + box_width / 2,
                    target[1],
                    fill="#6fa8dc",
                    arrow="last",
                    width=2,
                )
                self.canvas.create_text(
                    (source[0] + target[0] + box_width) / 2,
                    (source[1] + target[1] + box_height) / 2,
                    fill="#b9c8d6",
                    text=edge["field"],
                )
            elif source:
                self.canvas.create_text(
                    source[0] + box_width + 8,
                    source[1] + 26,
                    anchor="w",
                    fill="#ffb4ab",
                    text=f"{edge['field']} → {edge['toNodeID']}",
                )

        for node in nodes:
            x, y = positions[node["id"]]
            selected = node["id"] == self._selected_node
            fill = "#604d2a" if selected else "#202b36"
            outline = "#f0c674" if selected else "#6fa8dc"
            if node["terminal"] and not selected:
                fill = "#1f473d"
            self.canvas.create_rectangle(
                x, y, x + box_width, y + box_height,
                fill=fill, outline=outline, width=2,
                tags=(f"node:{node['id']}",),
            )
            self.canvas.create_text(
                x + 10, y + 10, anchor="nw", fill="#ffffff",
                text=node["id"], tags=(f"node:{node['id']}",),
            )
            pool = node.get("responsePool") or node.get("responseTemplate") or "no response pool"
            self.canvas.create_text(
                x + 10, y + 34, anchor="nw", fill="#b9c8d6",
                text=str(pool)[:30], tags=(f"node:{node['id']}",),
            )
            suffix = "terminal" if node["terminal"] else f"accepts {len(node['accepts'])}"
            self.canvas.create_text(
                x + 10, y + 59, anchor="nw", fill="#9bd3ae",
                text=suffix, tags=(f"node:{node['id']}",),
            )
            self.canvas.tag_bind(
                f"node:{node['id']}",
                "<Button-1>",
                lambda _event, node_id=node["id"]: self._select_node(node_id),
            )
            if node["id"] == model["initial"]:
                self.canvas.create_text(
                    x - 10, y + 16, anchor="e", fill="#f0c674",
                    text="initial",
                )

        width = max(720, 120 + ((len(nodes) + 1) // 2) * 310)
        height = max(600, 140 + ((len(nodes) + 1) // 2) * 138)
        self.canvas.configure(scrollregion=(0, 0, width, height))
