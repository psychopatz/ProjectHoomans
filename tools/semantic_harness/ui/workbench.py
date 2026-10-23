"""Reusable layout components for the Simulation workbench."""

from __future__ import annotations

from typing import Any

from .dialogs.catalog_control import CatalogControlField


class WorkbenchPage:
    """Place catalog fields with predictable spacing and page-specific density."""

    def __init__(
        self,
        parent: Any,
        tk: Any,
        ttk: Any,
        scrolled_text: Any,
        host: Any,
        *,
        layout: str = "two_column",
    ) -> None:
        self.tk = tk
        self.ttk = ttk
        self.scrolled_text = scrolled_text
        self.host = host
        self.layout = layout
        self.frame = ttk.Frame(parent)
        self.frame.rowconfigure(0, weight=1)
        self.frame.columnconfigure(0, weight=1)
        self.canvas = tk.Canvas(
            self.frame,
            borderwidth=0,
            highlightthickness=0,
        )
        self.canvas.grid(row=0, column=0, sticky="nsew")
        self.scrollbar = ttk.Scrollbar(
            self.frame,
            orient="vertical",
            command=self.canvas.yview,
        )
        self.scrollbar.grid(row=0, column=1, sticky="ns")
        self.canvas.configure(yscrollcommand=self.scrollbar.set)
        self.content = ttk.Frame(self.canvas, padding=(6, 4))
        self.content.columnconfigure(0, minsize=124)
        self.content.columnconfigure(1, weight=1, minsize=110)
        self.content.columnconfigure(2, minsize=124)
        self.content.columnconfigure(3, weight=1, minsize=110)
        self._canvas_window = self.canvas.create_window(
            (0, 0),
            window=self.content,
            anchor="nw",
        )
        self.content.bind("<Configure>", self._update_scroll_region)
        self.canvas.bind("<Configure>", self._resize_content)
        self._row = 0
        self._pair_column = 0
        self._section: str | None = None

    def _update_scroll_region(self, _event: Any | None = None) -> None:
        self.canvas.configure(scrollregion=self.canvas.bbox("all"))

    def _resize_content(self, event: Any) -> None:
        self.canvas.itemconfigure(
            self._canvas_window,
            width=max(1, int(event.width)),
        )
        self._update_scroll_region()

    def _finish_pair(self) -> None:
        if self._pair_column:
            self._row += 1
            self._pair_column = 0

    def add_section(self, title: str | None) -> None:
        value = str(title or "").strip()
        if not value or value == self._section:
            return
        self._finish_pair()
        if self._section is not None:
            self.ttk.Separator(self.content, orient=self.tk.HORIZONTAL).grid(
                row=self._row,
                column=0,
                columnspan=4,
                sticky="ew",
                pady=(5, 3),
            )
            self._row += 1
        self.ttk.Label(
            self.content,
            text=value,
            font=("TkDefaultFont", 9, "bold"),
        ).grid(
            row=self._row,
            column=0,
            columnspan=4,
            sticky="w",
            pady=(2, 2),
        )
        self._row += 1
        self._section = value

    def add_control(self, control: dict[str, Any], initial: Any) -> CatalogControlField:
        kind = str(control.get("control") or "text")
        full_width = self.layout == "stacked" or (
            self.layout == "personality"
            and kind in {"boolean", "multi_select", "structured_collection", "advanced_json"}
        )
        if full_width:
            self._finish_pair()
            field = CatalogControlField(
                self.content,
                self.tk,
                self.ttk,
                self.scrolled_text,
                self.host,
                control,
                initial,
                row=self._row,
                label_column=0,
                value_column=1,
                value_columnspan=3,
                label_padx=(0, 8),
                value_padx=(0, 0),
                width=24,
            )
            self._row += 1
            return field

        if self._pair_column == 0:
            label_column = 0
            value_column = 1
            label_padx = (0, 8)
            value_padx = (0, 14)
        else:
            label_column = 2
            value_column = 3
            label_padx = (16, 8)
            value_padx = (0, 0)
        field = CatalogControlField(
            self.content,
            self.tk,
            self.ttk,
            self.scrolled_text,
            self.host,
            control,
            initial,
            row=self._row,
            label_column=label_column,
            value_column=value_column,
            label_padx=label_padx,
            value_padx=value_padx,
            width=18,
        )
        self._pair_column = 2 if self._pair_column == 0 else 0
        if self._pair_column == 0:
            self._row += 1
        return field

    def add_summary(
        self,
        title: str,
        *,
        height: int = 4,
        width: int = 72,
    ) -> Any:
        """Add a bounded read-only summary below the current field row."""

        self._finish_pair()
        self.ttk.Label(
            self.content,
            text=title,
            anchor="w",
        ).grid(
            row=self._row,
            column=0,
            columnspan=4,
            sticky="w",
            pady=(2, 1),
        )
        self._row += 1
        widget = self.scrolled_text(
            self.content,
            height=height,
            width=width,
            wrap="word",
            state="disabled",
        )
        widget.grid(
            row=self._row,
            column=0,
            columnspan=4,
            sticky="ew",
            pady=(0, 5),
        )
        self._row += 1
        return widget

    def add_widget(
        self,
        widget: Any,
        *,
        column: int = 0,
        columnspan: int = 4,
        sticky: str = "ew",
        pady: tuple[int, int] = (2, 4),
    ) -> Any:
        """Place a host-owned widget after the current field row."""

        self._finish_pair()
        widget.grid(
            row=self._row,
            column=column,
            columnspan=columnspan,
            sticky=sticky,
            pady=pady,
        )
        self._row += 1
        return widget

    def finish(self) -> None:
        self._finish_pair()
        self.content.rowconfigure(self._row, weight=1)
        self._update_scroll_region()
