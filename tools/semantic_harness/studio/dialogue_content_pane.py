"""Human-facing Dialogue Content Registry editor.

This pane is intentionally narrower than the Advanced authoring tools.  It
can edit only ordinary EN/TL wording and always shows the structural fields
that remain owned by ResponseCatalog, navigation, and authority services.
"""

from __future__ import annotations

import json
from typing import Any, Callable

from ..codebuilder.service import SemanticLabAuthoringService


class DialogueContentPane:
    """Browse and safely edit compiled phrase/player-facing content."""

    def __init__(
        self,
        parent: Any,
        tk: Any,
        ttk: Any,
        scrolled_text: Any,
        messagebox: Any,
        service: SemanticLabAuthoringService,
        *,
        on_preview_simulation: Callable[[dict[str, Any]], Any] | None = None,
        on_send_review: Callable[[dict[str, Any]], Any] | None = None,
    ) -> None:
        self._tk = tk
        self._ttk = ttk
        self._messagebox = messagebox
        self.service = service
        self.on_preview_simulation = on_preview_simulation
        self.on_send_review = on_send_review
        self.frame = ttk.Frame(parent)
        self.frame.grid(row=0, column=0, sticky="nsew")
        self.frame.rowconfigure(1, weight=1)
        self.frame.columnconfigure(0, weight=1)
        self.frame.columnconfigure(1, weight=3)
        self._status_var = tk.StringVar(value="Loading verified dialogue content…")
        self._items: list[dict[str, Any]] = []
        self._selected: dict[str, Any] | None = None
        self._source_fingerprint: str | None = None

        toolbar = ttk.Frame(self.frame)
        toolbar.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 6))
        toolbar.columnconfigure(0, weight=1)
        ttk.Label(
            toolbar,
            text="Phrase wording and verified player-facing labels only; routes, plans, and authority are locked.",
        ).grid(row=0, column=0, sticky="w")
        ttk.Button(toolbar, text="Refresh", command=self.refresh).grid(
            row=0, column=1, padx=(8, 0)
        )
        ttk.Label(toolbar, textvariable=self._status_var).grid(
            row=0, column=2, padx=(12, 0), sticky="e"
        )

        left = ttk.LabelFrame(self.frame, text="Verified content families")
        left.grid(row=1, column=0, sticky="nsew", padx=(0, 8))
        left.rowconfigure(0, weight=1)
        left.columnconfigure(0, weight=1)
        self._listbox = tk.Listbox(left, width=42, exportselection=False)
        self._listbox.grid(row=0, column=0, sticky="nsew")
        self._listbox.bind("<<ListboxSelect>>", lambda _event: self.load_selected())
        scrollbar = ttk.Scrollbar(left, orient="vertical", command=self._listbox.yview)
        scrollbar.grid(row=0, column=1, sticky="ns")
        self._listbox.configure(yscrollcommand=scrollbar.set)

        right = ttk.Frame(self.frame)
        right.grid(row=1, column=1, sticky="nsew")
        right.rowconfigure(1, weight=1)
        right.columnconfigure(0, weight=1)
        locked = ttk.LabelFrame(right, text="Locked semantic / gameplay invariants")
        locked.grid(row=0, column=0, sticky="ew", pady=(0, 6))
        locked.columnconfigure(0, weight=1)
        self._locked_text = scrolled_text(locked, height=8, wrap="word")
        self._locked_text.grid(row=0, column=0, sticky="ew")
        self._locked_text.configure(state="disabled")

        editable = ttk.LabelFrame(right, text="Editable EN/TL content draft")
        editable.grid(row=1, column=0, sticky="nsew")
        editable.rowconfigure(0, weight=1)
        editable.columnconfigure(0, weight=1)
        self._editor = scrolled_text(editable, wrap="none")
        self._editor.grid(row=0, column=0, sticky="nsew")
        buttons = ttk.Frame(editable)
        buttons.grid(row=1, column=0, sticky="ew", pady=(6, 0))
        ttk.Button(buttons, text="Validate content", command=self.validate_draft).pack(side="left")
        ttk.Button(buttons, text="Preview in Simulation", command=self.preview_in_simulation).pack(
            side="left", padx=6
        )
        ttk.Button(buttons, text="Send to Review", command=self.send_to_review).pack(side="left")
        ttk.Button(buttons, text="Write source…", command=self.write_content).pack(
            side="left", padx=6
        )
        ttk.Button(
            buttons,
            text="Compile artifacts",
            command=self.compile_artifacts,
        ).pack(side="left")
        self.refresh()

    @staticmethod
    def _display_label(item: dict[str, Any]) -> str:
        kind = "phrase family" if item.get("kind") == "phraseFamily" else "player choice"
        return f"{kind} · {item.get('id', '<missing>')}"

    def refresh(self) -> None:
        try:
            self._items = self.service.list_dialogue_content()
        except (OSError, ValueError, KeyError) as error:
            self._items = []
            self._status_var.set(f"Content load failed: {error}")
            return
        self._listbox.delete(0, "end")
        for item in self._items:
            self._listbox.insert("end", self._display_label(item))
        if self._items:
            self._listbox.selection_set(0)
            self.load_selected()
        self._status_var.set(f"{len(self._items)} verified content records")

    def _set_text(self, widget: Any, value: str, *, disabled: bool = False) -> None:
        widget.configure(state="normal")
        widget.delete("1.0", "end")
        widget.insert("1.0", value)
        if disabled:
            widget.configure(state="disabled")

    def _selected_id(self) -> str | None:
        selection = self._listbox.curselection()
        if not selection:
            return None
        return str(self._items[selection[0]].get("id"))

    def load_selected(self) -> None:
        content_id = self._selected_id()
        if not content_id:
            return
        try:
            item = self.service.load_dialogue_content(content_id)
        except (OSError, ValueError, KeyError) as error:
            self._status_var.set(f"Content load failed: {error}")
            return
        self._selected = item
        self._source_fingerprint = item.get("sourceFingerprint")
        locked = {
            key: value
            for key, value in item.items()
            if key in {
                "id", "kind", "semanticTemplateID", "canonicalConcept", "locked",
                "translationKeyPrefix", "labelKey", "choiceKey", "verifiedOwner",
                "contentOwner", "semanticAuthority", "responsePoolID",
                "semanticVariantID", "followUpEligibility", "legacySource",
            }
        }
        self._set_text(
            self._locked_text,
            json.dumps(locked, ensure_ascii=False, indent=2) + "\n",
            disabled=True,
        )
        self._set_text(
            self._editor,
            json.dumps(item, ensure_ascii=False, indent=2) + "\n",
        )
        self._status_var.set(
            f"Editing {content_id}; structural fields locked; source fingerprint guarded"
        )

    def _draft(self) -> dict[str, Any] | None:
        try:
            value = json.loads(self._editor.get("1.0", "end"))
        except json.JSONDecodeError as error:
            self._status_var.set(f"Invalid JSON draft: {error}")
            return None
        if not isinstance(value, dict):
            self._status_var.set("Content draft must be an object")
            return None
        return value

    def validate_draft(self) -> dict[str, Any] | None:
        content_id = self._selected_id()
        draft = self._draft()
        if not content_id or draft is None:
            return None
        report = self.service.preview_dialogue_content_edit(
            content_id,
            draft,
            expected_source_fingerprint=self._source_fingerprint,
        )
        if report.get("ok") is True:
            self._status_var.set("Content valid; no files written; stale guard passed")
        else:
            diagnostics = report.get("diagnostics") or []
            message = diagnostics[0].get("message") if diagnostics else report.get("reason", "invalid content")
            self._status_var.set(f"Content rejected: {message}")
        return report

    def preview_in_simulation(self) -> dict[str, Any] | None:
        report = self.validate_draft()
        if report and report.get("ok") is True:
            self._status_var.set("Preview delegated to Simulation; no Studio runner is owned here")
            if self.on_preview_simulation:
                self.on_preview_simulation(report)
        return report

    def send_to_review(self) -> dict[str, Any] | None:
        report = self.validate_draft()
        if report and report.get("ok") is True:
            self._status_var.set("Validated content proposal sent to Review")
            if self.on_send_review:
                self.on_send_review(report)
        return report

    def write_content(self) -> dict[str, Any] | None:
        content_id = self._selected_id()
        draft = self._draft()
        if not content_id or draft is None:
            return None
        report = self.validate_draft()
        if not report or report.get("ok") is not True:
            return report
        if not self._messagebox.askyesno(
            "Write dialogue content source",
            "Write only the validated EN/TL wording to the canonical content source?",
        ):
            self._status_var.set("Write cancelled; draft remains in the editor")
            return report
        written = self.service.write_dialogue_content_edit(
            content_id,
            draft,
            expected_source_fingerprint=self._source_fingerprint,
        )
        if written.get("ok") is True:
            self._status_var.set(
                "Canonical content source written; review it, then compile artifacts explicitly"
            )
            self.refresh()
        return written

    def compile_artifacts(self) -> dict[str, Any]:
        """Compile the reviewed canonical source through the shared CodeBuilder."""

        if not self._messagebox.askyesno(
            "Compile dialogue content",
            "Compile the current canonical EN/TL content source into runtime artifacts?",
        ):
            self._status_var.set("Compile cancelled; canonical source unchanged")
            return {"ok": False, "cancelled": True, "writes": []}
        report = self.service.generate_dialogue_content_source()
        if report.get("ok") is True:
            self._status_var.set(
                f"Compiled {len(report.get('writes', []))} Dialogue Content artifacts"
            )
        else:
            diagnostics = report.get("diagnostics") or []
            message = diagnostics[0].get("message") if diagnostics else "compile failed"
            self._status_var.set(f"Content compile rejected: {message}")
        return report
