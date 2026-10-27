"""Contextual, structured Conversation authoring controls.

The pane deliberately talks only to :class:`SemanticLabAuthoringService`.
It never edits generated Lua/translation output or exposes a raw source editor
for ordinary wording and navigation work.
"""

from __future__ import annotations

import copy
import json
from typing import Any, Callable


class ConversationAuthoringPane:
    """Edit the currently selected content family or Conversation UI node."""

    def __init__(
        self,
        parent: Any,
        tk: Any,
        ttk: Any,
        scrolled_text: Any,
        messagebox: Any,
        service: Any,
        *,
        on_preview_simulation: Callable[[dict[str, Any]], Any] | None = None,
        on_send_review: Callable[[dict[str, Any]], Any] | None = None,
    ) -> None:
        self._tk = tk
        self._ttk = ttk
        self._scrolled_text = scrolled_text
        self._messagebox = messagebox
        self.service = service
        self.on_preview_simulation = on_preview_simulation
        self.on_send_review = on_send_review
        self._selected_id = ""
        self._selected_item: dict[str, Any] | None = None
        self._source_fingerprint = ""
        self._variants: list[dict[str, Any]] = []
        self._pending_variant_operation: tuple[str, dict[str, Any]] | None = None
        self._ui_nodes: list[dict[str, Any]] = []
        self._ui_source_fingerprint = ""
        self._pending_ui_operation: tuple[str, dict[str, Any]] | None = None
        self._node_content_item: dict[str, Any] | None = None
        self._node_content_fingerprint = ""

        self.frame = self._ttk.Frame(parent, padding=6)
        self.frame.grid(row=0, column=0, sticky="nsew")
        self.frame.rowconfigure(1, weight=1)
        self.frame.columnconfigure(0, weight=1)
        self._status = self._tk.StringVar(value="Select a Conversation item from Explore")
        self._ttk.Label(self.frame, textvariable=self._status).grid(
            row=0, column=0, sticky="ew", pady=(0, 6)
        )
        self._tabs = self._ttk.Notebook(self.frame)
        self._tabs.grid(row=1, column=0, sticky="nsew")

        wording = self._ttk.Frame(self._tabs, padding=6)
        navigation = self._ttk.Frame(self._tabs, padding=6)
        self._tabs.add(wording, text="Wording variants")
        self._tabs.add(navigation, text="Conversation UI")
        self._build_wording(wording)
        self._build_navigation(navigation)
        self.refresh_navigation()

    def _build_wording(self, parent: Any) -> None:
        parent.rowconfigure(2, weight=1)
        parent.columnconfigure(1, weight=1)
        self._content_label = self._tk.StringVar(value="No phrase family selected")
        self._ttk.Label(parent, textvariable=self._content_label).grid(
            row=0, column=0, columnspan=3, sticky="w", pady=(0, 6)
        )
        self._style_var = self._tk.StringVar(value="neutral")
        self._ttk.Label(parent, text="Style").grid(row=1, column=0, sticky="w")
        self._style_box = self._ttk.Combobox(
            parent, textvariable=self._style_var, state="readonly", width=16
        )
        self._style_box.grid(row=1, column=1, sticky="w", padx=6)
        self._style_box.bind("<<ComboboxSelected>>", lambda _event: self._render_variants())

        left = self._ttk.LabelFrame(parent, text="Variants")
        left.grid(row=2, column=0, rowspan=4, sticky="nsew", padx=(0, 8))
        left.rowconfigure(0, weight=1)
        left.columnconfigure(0, weight=1)
        self._variant_list = self._tk.Listbox(left, width=28, exportselection=False)
        self._variant_list.grid(row=0, column=0, sticky="nsew")
        self._variant_list.bind("<<ListboxSelect>>", lambda _event: self._load_variant())

        editor = self._ttk.LabelFrame(parent, text="EN/TL wording")
        editor.grid(row=2, column=1, columnspan=2, sticky="nsew")
        editor.columnconfigure(1, weight=1)
        self._en_var = self._tk.StringVar()
        self._tl_var = self._tk.StringVar()
        self._ttk.Label(editor, text="EN").grid(row=0, column=0, sticky="w", padx=6, pady=6)
        self._ttk.Entry(editor, textvariable=self._en_var, width=72).grid(
            row=0, column=1, sticky="ew", padx=6, pady=6
        )
        self._ttk.Label(editor, text="TL").grid(row=1, column=0, sticky="w", padx=6, pady=6)
        self._ttk.Entry(editor, textvariable=self._tl_var, width=72).grid(
            row=1, column=1, sticky="ew", padx=6, pady=6
        )

        actions = self._ttk.Frame(parent)
        actions.grid(row=3, column=1, columnspan=2, sticky="ew", pady=(6, 0))
        self._ttk.Button(actions, text="Add variant", command=self.add_variant).pack(side="left")
        self._ttk.Button(actions, text="Duplicate", command=self.duplicate_variant).pack(side="left", padx=4)
        self._ttk.Button(actions, text="Delete", command=self.delete_variant).pack(side="left", padx=4)
        self._ttk.Button(actions, text="Move up", command=lambda: self.move_variant(-1)).pack(side="left", padx=4)
        self._ttk.Button(actions, text="Move down", command=lambda: self.move_variant(1)).pack(side="left", padx=4)
        self._ttk.Button(actions, text="Add style", command=self.add_style).pack(side="left", padx=4)
        self._ttk.Button(actions, text="Remove style", command=self.remove_style).pack(side="left", padx=4)
        self._ttk.Button(actions, text="Preview", command=self.preview_wording).pack(side="left", padx=4)
        self._ttk.Button(actions, text="Review", command=self.review_wording).pack(side="left", padx=4)
        self._ttk.Button(actions, text="Review variant", command=self.review_variant_operation).pack(side="left", padx=4)
        self._ttk.Button(actions, text="Write…", command=self.write_wording).pack(side="left", padx=4)
        self._ttk.Button(actions, text="Write variant…", command=self.write_variant_operation).pack(side="left", padx=4)
        self._ttk.Button(actions, text="Compile", command=self.compile_content).pack(side="right")

    def _build_navigation(self, parent: Any) -> None:
        parent.rowconfigure(1, weight=1)
        parent.columnconfigure(0, weight=1)
        parent.columnconfigure(1, weight=2)
        toolbar = self._ttk.Frame(parent)
        toolbar.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 6))
        self._ttk.Button(toolbar, text="Refresh UI registry", command=self.refresh_navigation).pack(side="left")
        self._ttk.Button(toolbar, text="Preview UI edit", command=self.preview_ui_edit).pack(side="left", padx=4)
        self._ttk.Button(toolbar, text="Review UI edit", command=self.review_ui_edit).pack(side="left", padx=4)
        self._ttk.Button(toolbar, text="Write UI…", command=self.write_ui_edit).pack(side="left", padx=4)
        self._ttk.Button(toolbar, text="Compile UI", command=self.compile_ui).pack(side="right")

        left = self._ttk.LabelFrame(parent, text="Registered Conversation UI nodes")
        left.grid(row=1, column=0, sticky="nsew", padx=(0, 8))
        left.rowconfigure(0, weight=1)
        left.columnconfigure(0, weight=1)
        self._node_list = self._tk.Listbox(left, width=42, exportselection=False)
        self._node_list.grid(row=0, column=0, sticky="nsew")
        self._node_list.bind("<<ListboxSelect>>", lambda _event: self._show_node())

        right = self._ttk.LabelFrame(parent, text="Navigation membership and production authority")
        right.grid(row=1, column=1, sticky="nsew")
        right.rowconfigure(0, weight=1)
        right.columnconfigure(0, weight=1)
        self._node_detail = self._scrolled_text(right, wrap="word", state="disabled", height=12)
        self._node_detail.grid(row=0, column=0, sticky="nsew")
        controls = self._ttk.Frame(right)
        controls.grid(row=1, column=0, sticky="ew", pady=(6, 0))
        self._parent_var = self._tk.StringVar()
        self._child_var = self._tk.StringVar()
        self._parent_box = self._ttk.Combobox(controls, textvariable=self._parent_var, state="readonly", width=30)
        self._child_box = self._ttk.Combobox(controls, textvariable=self._child_var, state="readonly", width=30)
        self._parent_box.pack(side="left")
        self._child_box.pack(side="left", padx=4)
        self._ttk.Button(controls, text="Add child", command=self.add_ui_child).pack(side="left", padx=2)
        self._ttk.Button(controls, text="Remove child", command=self.remove_ui_child).pack(side="left", padx=2)
        self._ttk.Button(controls, text="Move child", command=self.move_ui_child).pack(side="left", padx=2)
        self._ttk.Button(controls, text="Move up", command=lambda: self.reorder_ui_child(-10)).pack(side="left", padx=2)
        self._ttk.Button(controls, text="Edit wording", command=self.edit_selected_node_wording).pack(side="right", padx=2)

        wording = self._ttk.LabelFrame(right, text="Selected node EN/TL label and player utterance")
        wording.grid(row=2, column=0, sticky="ew", pady=(6, 0))
        wording.columnconfigure(1, weight=1)
        self._node_label_en = self._tk.StringVar()
        self._node_label_tl = self._tk.StringVar()
        self._node_choice_en = self._tk.StringVar()
        self._node_choice_tl = self._tk.StringVar()
        for row, label, variable in (
            (0, "EN label", self._node_label_en),
            (1, "TL label", self._node_label_tl),
            (2, "EN player utterance", self._node_choice_en),
            (3, "TL player utterance", self._node_choice_tl),
        ):
            self._ttk.Label(wording, text=label).grid(row=row, column=0, sticky="w", padx=4, pady=2)
            self._ttk.Entry(wording, textvariable=variable, width=72).grid(
                row=row, column=1, sticky="ew", padx=4, pady=2
            )
        wording_actions = self._ttk.Frame(wording)
        wording_actions.grid(row=4, column=0, columnspan=2, sticky="ew", pady=4)
        self._ttk.Button(wording_actions, text="Preview wording", command=self.preview_node_wording).pack(side="left")
        self._ttk.Button(wording_actions, text="Review wording", command=self.review_node_wording).pack(side="left", padx=4)
        self._ttk.Button(wording_actions, text="Write wording…", command=self.write_node_wording).pack(side="left", padx=4)

    def _set_status(self, message: str) -> None:
        self._status.set(str(message)[:400])

    def select_content(self, content_id: str) -> None:
        try:
            item = self.service.load_dialogue_content(str(content_id))
            variants = self.service.inspect_dialogue_variants(str(content_id))
        except (OSError, ValueError, KeyError) as error:
            self._set_status(f"Conversation item unavailable: {error}")
            return
        self._selected_id = str(content_id)
        self._selected_item = item
        self._source_fingerprint = str(item.get("sourceFingerprint", ""))
        self._variants = variants.get("variants", []) if variants.get("ok") else []
        styles = sorted({str(row.get("style")) for row in self._variants})
        self._style_box.configure(values=styles or ["neutral"])
        self._style_var.set(styles[0] if styles else "neutral")
        self._content_label.set(f"{item.get('semanticTemplateID', item.get('id'))} · Dialogue Content")
        self._render_variants()
        self._set_status("Selected Conversation content; edit a structured EN/TL variant, then Preview or Review")

    def _style_variants(self) -> list[dict[str, Any]]:
        return [row for row in self._variants if row.get("style") == self._style_var.get()]

    def _render_variants(self) -> None:
        self._variant_list.delete(0, "end")
        for row in self._style_variants():
            self._variant_list.insert("end", f"{row.get('style')} · variant {int(row.get('index', 0)) + 1}")
        if self._style_variants():
            self._variant_list.selection_set(0)
            self._load_variant()

    def _current_variant(self) -> dict[str, Any] | None:
        selection = self._variant_list.curselection()
        rows = self._style_variants()
        return rows[selection[0]] if selection and selection[0] < len(rows) else None

    def _load_variant(self) -> None:
        variant = self._current_variant()
        translations = variant.get("translations", {}) if variant else {}
        self._en_var.set(str(translations.get("EN", "")))
        self._tl_var.set(str(translations.get("TL", "")))

    def _content_draft(self) -> dict[str, Any] | None:
        if not self._selected_item:
            self._set_status("Select a phrase family first")
            return None
        draft = copy.deepcopy(self._selected_item)
        draft.pop("kind", None)
        draft.pop("sourcePath", None)
        draft.pop("sourceFingerprint", None)
        draft.pop("verifiedOwner", None)
        variant = self._current_variant()
        if variant:
            style = str(variant["style"])
            index = int(variant["index"])
            draft.setdefault("styles", {}).setdefault(style, [])[index]["translations"] = {
                "EN": self._en_var.get(),
                "TL": self._tl_var.get(),
            }
        return draft

    def preview_wording(self) -> dict[str, Any] | None:
        draft = self._content_draft()
        if draft is None:
            return None
        report = self.service.preview_dialogue_content_edit(
            self._selected_id,
            draft,
            expected_source_fingerprint=self._source_fingerprint,
        )
        self._set_status("Wording preview valid; no files written" if report.get("ok") else self._diagnostic(report))
        return report

    def review_wording(self) -> dict[str, Any] | None:
        report = self.preview_wording()
        if report and report.get("ok") and self.on_send_review:
            self.on_send_review(report)
        return report

    def write_wording(self) -> dict[str, Any] | None:
        draft = self._content_draft()
        if draft is None:
            return None
        if self._messagebox is not None and not self._messagebox.askyesno(
            "Write Conversation wording", "Write this explicit EN/TL wording change to the canonical shard?"
        ):
            return None
        report = self.service.write_dialogue_content_edit(
            self._selected_id,
            draft,
            expected_source_fingerprint=self._source_fingerprint,
        )
        self._set_status("Wording written; compile artifacts explicitly" if report.get("ok") else self._diagnostic(report))
        if report.get("ok"):
            self.select_content(self._selected_id)
        return report

    def _variant_operation(self, operation: str, **arguments: Any) -> dict[str, Any] | None:
        if not self._selected_id:
            self._set_status("Select a phrase family first")
            return None
        report = self.service.preview_dialogue_content_operation(
            self._selected_id,
            operation,
            expected_source_fingerprint=self._source_fingerprint,
            **arguments,
        )
        if report.get("ok"):
            self._pending_variant_operation = (operation, dict(arguments))
        self._set_status("Variant operation valid; Review or Write explicitly" if report.get("ok") else self._diagnostic(report))
        return report

    def write_variant_operation(self) -> dict[str, Any] | None:
        if not self._pending_variant_operation or not self._selected_id:
            self._set_status("Preview a variant operation first")
            return None
        if self._messagebox is not None and not self._messagebox.askyesno(
            "Write Conversation variant", "Write this explicit variant/style operation to the canonical shard?"
        ):
            return None
        operation, arguments = self._pending_variant_operation
        report = self.service.write_dialogue_content_operation(
            self._selected_id,
            operation,
            expected_source_fingerprint=self._source_fingerprint,
            **arguments,
        )
        self._set_status("Variant operation written; compile artifacts explicitly" if report.get("ok") else self._diagnostic(report))
        if report.get("ok"):
            self._pending_variant_operation = None
            self.select_content(self._selected_id)
        return report

    def review_variant_operation(self) -> dict[str, Any] | None:
        operation = self._pending_variant_operation
        if not operation:
            index = self._current_index()
            if index is None:
                self._set_status("Preview a variant operation first")
                return None
            self._set_status("Choose Add, Duplicate, Delete, Move, or Style first")
            return None
        report = self.service.preview_dialogue_content_operation(
            self._selected_id,
            operation[0],
            expected_source_fingerprint=self._source_fingerprint,
            **operation[1],
        )
        if report.get("ok") and self.on_send_review:
            self.on_send_review(report)
        return report

    def _current_index(self) -> int | None:
        variant = self._current_variant()
        return int(variant["index"]) if variant else None

    def add_variant(self) -> dict[str, Any] | None:
        return self._variant_operation(
            "add_variant", style=self._style_var.get(),
            translations={"EN": self._en_var.get() or "New phrase.", "TL": self._tl_var.get() or "Bagong parirala."},
        )

    def duplicate_variant(self) -> dict[str, Any] | None:
        index = self._current_index()
        return self._variant_operation("duplicate_variant", style=self._style_var.get(), index=index) if index is not None else None

    def delete_variant(self) -> dict[str, Any] | None:
        index = self._current_index()
        return self._variant_operation("delete_variant", style=self._style_var.get(), index=index) if index is not None else None

    def move_variant(self, delta: int) -> dict[str, Any] | None:
        index = self._current_index()
        if index is None:
            return None
        return self._variant_operation(
            "move_variant", style=self._style_var.get(), index=index, targetIndex=index + int(delta)
        )

    def add_style(self) -> dict[str, Any] | None:
        return self._variant_operation(
            "add_style", style=self._style_var.get(),
            translations={"EN": self._en_var.get() or "New phrase.", "TL": self._tl_var.get() or "Bagong parirala."},
        )

    def remove_style(self) -> dict[str, Any] | None:
        return self._variant_operation("remove_style", style=self._style_var.get())

    def compile_content(self) -> dict[str, Any]:
        report = self.service.generate_dialogue_content_source()
        self._set_status("Dialogue Content compiled explicitly" if report.get("ok") else self._diagnostic(report))
        return report

    def refresh_navigation(self) -> None:
        report = self.service.inspect_conversation_ui()
        if not report.get("ok"):
            self._set_status(self._diagnostic(report))
            return
        self._ui_nodes = [node for node in report.get("nodes", []) if isinstance(node, dict)]
        self._ui_source_fingerprint = str(report.get("sourceFingerprint", ""))
        self._node_list.delete(0, "end")
        ids = [str(node.get("id")) for node in self._ui_nodes]
        self._parent_box.configure(values=ids)
        self._child_box.configure(values=ids)
        for node in self._ui_nodes:
            self._node_list.insert("end", f"{node.get('kind', 'node')} · {node.get('id')}")
        if ids:
            self._node_list.selection_set(0)
            self._show_node()

    def _selected_node(self) -> dict[str, Any] | None:
        selection = self._node_list.curselection()
        return self._ui_nodes[selection[0]] if selection and selection[0] < len(self._ui_nodes) else None

    def _show_node(self) -> None:
        node = self._selected_node()
        if not node:
            return
        self._set_text(self._node_detail, {
            "canonicalID": node.get("id"),
            "kind": node.get("kind"),
            "parentID": node.get("parentID"),
            "children": node.get("children", []),
            "semanticDestination": node.get("semanticDestination", "PRODUCTION LOCKED"),
            "providerRef": node.get("providerRef", "PRODUCTION LOCKED"),
            "contentID": node.get("contentID"),
            "sourceFingerprint": self._ui_source_fingerprint,
        })
        self._parent_var.set(str(node.get("parentID") or node.get("id")))
        self._child_var.set("")
        self._load_node_wording(node)

    def _load_node_wording(self, node: dict[str, Any]) -> None:
        self._node_content_item = None
        self._node_content_fingerprint = ""
        content_id = str(node.get("contentID") or "")
        if not content_id:
            return
        try:
            item = self.service.load_dialogue_content(content_id)
        except (OSError, ValueError, KeyError):
            return
        if not isinstance(item.get("labelTranslations"), dict) or not isinstance(
            item.get("choiceTranslations"), dict
        ):
            return
        self._node_content_item = item
        self._node_content_fingerprint = str(item.get("sourceFingerprint", ""))
        label = item.get("labelTranslations") or {}
        choice = item.get("choiceTranslations") or {}
        self._node_label_en.set(str(label.get("EN", "")))
        self._node_label_tl.set(str(label.get("TL", "")))
        self._node_choice_en.set(str(choice.get("EN", "")))
        self._node_choice_tl.set(str(choice.get("TL", "")))

    def _node_content_draft(self) -> dict[str, Any] | None:
        if not self._node_content_item:
            self._set_status("Selected UI node has no Project Hoomans-owned player wording")
            return None
        draft = copy.deepcopy(self._node_content_item)
        draft.pop("kind", None)
        draft.pop("sourcePath", None)
        draft.pop("sourceFingerprint", None)
        draft.pop("verifiedOwner", None)
        draft["labelTranslations"] = {
            "EN": self._node_label_en.get(),
            "TL": self._node_label_tl.get(),
        }
        draft["choiceTranslations"] = {
            "EN": self._node_choice_en.get(),
            "TL": self._node_choice_tl.get(),
        }
        return draft

    def preview_node_wording(self) -> dict[str, Any] | None:
        draft = self._node_content_draft()
        if draft is None:
            return None
        report = self.service.preview_dialogue_content_edit(
            str(self._node_content_item.get("id")),
            draft,
            expected_source_fingerprint=self._node_content_fingerprint,
        )
        self._set_status("UI wording preview valid; no files written" if report.get("ok") else self._diagnostic(report))
        return report

    def review_node_wording(self) -> dict[str, Any] | None:
        report = self.preview_node_wording()
        if report and report.get("ok") and self.on_send_review:
            self.on_send_review(report)
        return report

    def write_node_wording(self) -> dict[str, Any] | None:
        draft = self._node_content_draft()
        if draft is None:
            return None
        if self._messagebox is not None and not self._messagebox.askyesno(
            "Write Conversation UI wording", "Write this explicit EN/TL label and utterance change?"
        ):
            return None
        report = self.service.write_dialogue_content_edit(
            str(self._node_content_item.get("id")),
            draft,
            expected_source_fingerprint=self._node_content_fingerprint,
        )
        self._set_status("UI wording written; compile artifacts explicitly" if report.get("ok") else self._diagnostic(report))
        if report.get("ok"):
            self._load_node_wording(self._selected_node() or {})
        return report

    def _ui_operation(self, operation: str, **arguments: Any) -> dict[str, Any]:
        report = self.service.preview_conversation_ui_operation(
            operation,
            expected_source_fingerprint=self._ui_source_fingerprint,
            **arguments,
        )
        if report.get("ok"):
            self._pending_ui_operation = (operation, dict(arguments))
        self._set_status("Conversation UI operation valid; write explicitly" if report.get("ok") else self._diagnostic(report))
        return report

    def add_ui_child(self) -> dict[str, Any]:
        return self._ui_operation("add_child", parentID=self._parent_var.get(), childID=self._child_var.get())

    def remove_ui_child(self) -> dict[str, Any]:
        return self._ui_operation("remove_child", parentID=self._parent_var.get(), childID=self._child_var.get())

    def move_ui_child(self) -> dict[str, Any]:
        return self._ui_operation(
            "move_child",
            childID=self._child_var.get(),
            newParentID=self._parent_var.get(),
        )

    def reorder_ui_child(self, delta: int) -> dict[str, Any]:
        node = next((item for item in self._ui_nodes if item.get("id") == self._child_var.get()), None)
        order = int(node.get("order", 0)) + int(delta) if node else 0
        return self._ui_operation("reorder_child", parentID=self._parent_var.get(), childID=self._child_var.get(), order=order)

    def preview_ui_edit(self) -> dict[str, Any]:
        return self._ui_operation("update_node", nodeID=self._parent_var.get(), presentationGroup="conversation")

    def review_ui_edit(self) -> dict[str, Any]:
        report = self.preview_ui_edit()
        if report.get("ok") and self.on_send_review:
            self.on_send_review(report)
        return report

    def write_ui_edit(self) -> dict[str, Any]:
        if self._messagebox is not None and not self._messagebox.askyesno(
            "Write Conversation UI", "Write this explicit navigation presentation change to the canonical UI registry?"
        ):
            return {"ok": False, "cancelled": True, "writes": []}
        operation, arguments = self._pending_ui_operation or (
            "update_node",
            {"nodeID": self._parent_var.get(), "presentationGroup": "conversation"},
        )
        report = self.service.write_conversation_ui_operation(
            operation,
            expected_source_fingerprint=self._ui_source_fingerprint,
            **arguments,
        )
        self._set_status("Conversation UI written; compile explicitly" if report.get("ok") else self._diagnostic(report))
        if report.get("ok"):
            self._pending_ui_operation = None
            self.refresh_navigation()
        return report

    def edit_selected_node_wording(self) -> None:
        node = self._selected_node()
        content_id = node.get("contentID") if node else None
        if content_id and content_id.startswith("phrase."):
            self.select_content(content_id)
            self._tabs.select(0)
        elif self._node_content_item:
            self._tabs.select(1)
            self._set_status("Editing selected Conversation UI label and player utterance")
        else:
            self._set_status("This node has no Project Hoomans-owned editable content")

    def compile_ui(self) -> dict[str, Any]:
        report = self.service.compile_conversation_ui()
        self._set_status("Conversation UI compiled explicitly" if report.get("ok") else self._diagnostic(report))
        return report

    @staticmethod
    def _diagnostic(report: dict[str, Any]) -> str:
        diagnostics = report.get("diagnostics") or []
        if diagnostics and isinstance(diagnostics[0], dict):
            return str(diagnostics[0].get("message", "operation rejected"))
        return str(report.get("reason") or "operation rejected")

    @staticmethod
    def _set_text(widget: Any, value: Any) -> None:
        widget.configure(state="normal")
        widget.delete("1.0", "end")
        widget.insert("1.0", json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True) + "\n")
        widget.configure(state="disabled")

    def set_enabled(self, enabled: bool) -> None:
        state = "normal" if enabled else "disabled"
        self._variant_list.configure(state=state)
        self._node_list.configure(state=state)


__all__ = ["ConversationAuthoringPane"]
