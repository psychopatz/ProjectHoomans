"""Observability-first Studio surface; production Lua remains the only selector."""
from __future__ import annotations

from typing import Any, Callable

from ..inspection.response_observatory import run_quality_matrix
from ..runtime.worker import LuaSemanticWorker


class SemanticObservatoryPane:
    """Read-only catalog/trace with explicit disposable-fixture test actions."""

    def __init__(
        self, parent: Any, tk: Any, ttk: Any, scrolled_text: Any,
        run_worker: Callable[[Callable, Callable], bool],
    ) -> None:
        self._tk, self._ttk = tk, ttk
        self._run_worker = run_worker
        self.frame = ttk.Frame(parent, padding=6)
        self.frame.grid(row=0, column=0, sticky="nsew")
        self.frame.rowconfigure(1, weight=1)
        self.frame.columnconfigure(0, weight=1)
        self.filter_var = tk.StringVar(value="")
        self.status_var = tk.StringVar(
            value="Production Lua catalog · choose Search to inspect")
        self.context_var = tk.StringVar(value="Default (unknown conditions)")
        self.utterance_var = tk.StringVar(value="hello")
        self.selected_pool = ""
        self._page_offset = 0
        self._has_more = False
        toolbar = ttk.Frame(self.frame)
        toolbar.grid(row=0, column=0, sticky="ew")
        ttk.Label(toolbar, text="Response pools").pack(side="left")
        ttk.Entry(toolbar, textvariable=self.filter_var, width=24).pack(
            side="left", padx=6)
        ttk.Button(toolbar, text="Search", command=self.search).pack(side="left")
        self._previous = ttk.Button(
            toolbar, text="Previous", command=self.previous_page)
        self._previous.pack(side="left", padx=(8, 0))
        self._next = ttk.Button(toolbar, text="Next", command=self.next_page)
        self._next.pack(side="left", padx=4)
        self._previous.configure(state="disabled")
        self._next.configure(state="disabled")
        ttk.Label(toolbar, textvariable=self.status_var).pack(
            side="left", padx=12)

        content = ttk.Panedwindow(self.frame, orient="horizontal")
        content.grid(row=1, column=0, sticky="nsew")
        left = ttk.Frame(content)
        left.rowconfigure(0, weight=1)
        left.columnconfigure(0, weight=1)
        self.pools = ttk.Treeview(
            left, columns=("variants",), show="tree headings", selectmode="browse")
        self.pools.heading("#0", text="Registered pool")
        self.pools.heading("variants", text="Variants")
        self.pools.column("#0", width=360)
        self.pools.column("variants", width=80, stretch=False)
        self.pools.grid(row=0, column=0, sticky="nsew")
        scroll = ttk.Scrollbar(left, orient="vertical", command=self.pools.yview)
        scroll.grid(row=0, column=1, sticky="ns")
        self.pools.configure(yscrollcommand=scroll.set)
        self.pools.bind("<<TreeviewSelect>>", self._selected)
        content.add(left, weight=2)

        right = ttk.Frame(content)
        right.rowconfigure(0, weight=1)
        right.columnconfigure(0, weight=1)
        self.tabs = ttk.Notebook(right)
        self.tabs.grid(row=0, column=0, sticky="nsew")
        self.views: dict[str, Any] = {}
        for name in ("Catalog", "Test Lab", "Coverage", "Review"):
            panel = ttk.Frame(self.tabs, padding=6)
            panel.rowconfigure(1, weight=1)
            panel.columnconfigure(0, weight=1)
            self.tabs.add(panel, text=name)
            controls = ttk.Frame(panel)
            controls.grid(row=0, column=0, sticky="ew", pady=(0, 4))
            viewer = scrolled_text(panel, wrap="word", state="disabled", height=14)
            viewer.grid(row=1, column=0, sticky="nsew")
            self.views[name] = viewer
            if name == "Catalog":
                ttk.Label(controls, text="Actual registered variant data").pack(side="left")
                ttk.Button(controls, text="Explain selection",
                           command=self.explain).pack(side="right")
                self.context_box = ttk.Combobox(
                    controls, textvariable=self.context_var, state="readonly",
                    values=(
                        "Default (unknown conditions)", "Rainy fixture",
                        "Friendly fixture", "Injured fixture",
                        "Thirsty fixture", "Trusted fixture",
                    ), width=26)
                self.context_box.pack(side="right", padx=4)
            elif name == "Test Lab":
                ttk.Label(controls, text="Fixture utterance").pack(side="left")
                ttk.Entry(controls, textvariable=self.utterance_var,
                          width=36).pack(side="left", padx=6)
                ttk.Button(controls, text="Run real Lua",
                           command=self.test_utterance).pack(side="left")
            elif name == "Coverage":
                ttk.Button(controls, text="Run EN/TL greeting + follow probes",
                           command=self.coverage).pack(side="left")
            elif name == "Review":
                ttk.Label(controls, text="Read-only source / variant review").pack(
                    side="left")
        content.add(right, weight=3)
        self._display("Review", "Candidate edits are not applied here. "
                      "Proposals must go through canonical Lua / CodeBuilder "
                      "review and isolated Lua replay.")

    def _display(self, view: str, value: str) -> None:
        widget = self.views[view]
        widget.configure(state="normal")
        widget.delete("1.0", "end")
        widget.insert("1.0", value)
        widget.configure(state="disabled")

    def _submit(self, operation: Callable, callback: Callable) -> None:
        if not self._run_worker(operation, callback):
            self.status_var.set("Worker busy or not initialized")

    def search(self) -> None:
        self._page_offset = 0
        self.refresh()

    def previous_page(self) -> None:
        self._page_offset = max(0, self._page_offset - 64)
        self.refresh()

    def next_page(self) -> None:
        if self._has_more:
            self._page_offset += 64
            self.refresh()

    def refresh(self) -> None:
        query = self.filter_var.get().strip()
        self._submit(
            lambda worker: worker.response_pool_list(
                filter=query, offset=self._page_offset, limit=64),
            self._on_list,
        )

    def _on_list(self, result: dict[str, Any]) -> None:
        self._has_more = bool(result.get("hasMore"))
        self._previous.configure(
            state="normal" if self._page_offset > 0 else "disabled")
        self._next.configure(state="normal" if self._has_more else "disabled")
        self.pools.delete(*self.pools.get_children())
        for pool in result.get("pools", []):
            self.pools.insert("", "end", iid=pool["id"],
                              text=pool["id"], values=(pool["variantCount"],))
        self.status_var.set(
            f"{len(result.get('pools', []))}/{result.get('total', 0)} pools "
            f"(revision {result.get('registryRevision', '?')})"
            + (" · filtered/page-limited" if result.get("hasMore") else "")
        )

    def _selected(self, _event: Any = None) -> None:
        selection = self.pools.selection()
        if not selection:
            return
        self.selected_pool = selection[0]
        self._submit(
            lambda worker: worker.response_pool_detail(
                self.selected_pool, limit=16),
            self._on_detail,
        )

    def _on_detail(self, result: dict[str, Any]) -> None:
        lines = [
            f"Pool: {result['poolID']}",
            f"Loaded variants: {result['variantCount']}",
            f"Registration revision: {result.get('registryRevision', '?')}",
            f"Registry content marker: {result.get('contentFingerprint', 'UNKNOWN')}",
            f"Owning source: {result.get('sourcePath', 'UNKNOWN')}",
            "",
        ]
        for variant in result.get("variants", []):
            checks = variant.get("when") or {}
            lines += [
                f"{variant['id']} · priority {variant.get('priority', 0)}",
                f"  Template: {variant.get('templateID', 'UNKNOWN')}",
                f"  Conditions: {checks if checks else 'none'}",
                f"  Fallback: {variant.get('fallback', '')}",
                f"  Plan: {variant.get('planSummary', {})}",
                "",
            ]
        self._display("Catalog", "\n".join(lines))
        self._display("Review",
                      "Source path: " + str(result.get("sourcePath", "UNKNOWN"))
                      + "\nCanonical owner must be verified before any patch.\n"
                      + "No edits or game commands are issued by inspection.")

    def _context(self) -> dict[str, Any]:
        label = self.context_var.get()
        contexts = {
            "Rainy fixture": {"worldContext": {"weather": {"raining": True}}},
            "Friendly fixture": {"socialStyle": "friendly"},
            "Injured fixture": {"healthState": "injured"},
            "Thirsty fixture": {"needType": "thirst", "needUrgency": "severe"},
            "Trusted fixture": {"relationshipState": "Trusted"},
        }
        return dict(contexts.get(label, {}), npcID="observatory-fixture")

    def explain(self) -> None:
        if not self.selected_pool:
            self.status_var.set("Select a registered pool first")
            return
        pool = self.selected_pool
        context = self._context()
        self._submit(
            lambda worker: worker.explain_response_selection(pool, context),
            self._on_explain,
        )

    def _on_explain(self, result: dict[str, Any]) -> None:
        lines = [
            f"Read-only production Lua explanation: {result.get('poolID')}",
            f"Selected: {result.get('selectedID')} "
            f"(score {result.get('bestScore')})",
            f"Tie count: {result.get('tieCount', 0)} · "
            f"Anti-repeat rotated: {result.get('rotated', False)}",
            "",
        ]
        for row in result.get("candidates", []):
            lines.append(
                f"{'ELIGIBLE' if row.get('eligible') else 'EXCLUDED'} "
                f"{row.get('id')}: {row.get('reason')} "
                f"(score={row.get('score')})"
            )
            for check in row.get("checks", []):
                lines.append(
                    f"   {'✓' if check.get('matched') else '×'} "
                    f"{check.get('field')}: expected={check.get('expected')!s}, "
                    f"actual={'UNKNOWN' if not check.get('actualKnown') else check.get('actual')!s}"
                )
        self._display("Catalog", "\n".join(lines))
        self.tabs.select(0)

    def test_utterance(self) -> None:
        utterance = self.utterance_var.get().strip()
        if not 1 <= len(utterance) <= 200:
            self.status_var.set("Enter 1–200 characters")
            return
        self._submit(lambda worker: worker.input(utterance), self._on_test)

    def _on_test(self, result: dict[str, Any]) -> None:
        npc = [
            row.get("payload", {}) for row in result.get("messages", [])
            if row.get("speaker") == "npc"
        ]
        lines = ["Actual production Lua, disposable worker fixture:",
                 f"Accepted: {result.get('accepted')}", ""]
        for entry in npc[-4:]:
            lines.extend((str(entry.get("key") or "UNKNOWN"),
                          str(entry.get("text") or ""), ""))
        self._display("Test Lab", "\n".join(lines))
        self.tabs.select(1)

    def coverage(self) -> None:
        cases = [
            {"label": "Greeting EN", "language": "EN", "utterance": "hello",
             "expected": {"maxActions": 0}},
            {"label": "Greeting TL", "language": "TL", "utterance": "hello",
             "expected": {"maxActions": 0}},
            {"label": "Follow EN", "language": "EN", "utterance": "follow me",
             "expected": {"minActions": 1}},
            {"label": "Follow TL", "language": "TL", "utterance": "follow me",
             "expected": {"minActions": 1}},
        ]
        self._submit(
            lambda worker: run_quality_matrix(
                cases,
                worker_factory=lambda scenario: LuaSemanticWorker(
                    scenario, config=worker.config,
                ),
            ),
            self._on_coverage,
        )

    def _on_coverage(self, result: dict[str, Any]) -> None:
        lines = [
            f"Production Lua matrix: {result['caseCount']} fixture cases",
            f"Assertions PASS={result['passed']} FAIL={result['failed']} "
            f"OBSERVED={result['observedOnly']}",
            "Not a native SP/MP test or global proof of reachability.",
            "",
        ]
        for row in result["cases"]:
            lines.extend((
                f"{row['label']} · {row['status']} · {row['language']}",
                f"  Selected keys: {', '.join(row['responseKeys'])}",
                f"  Last NPC text: {row['responseTexts'][-1] if row['responseTexts'] else 'NONE'}",
                f"  Action count: {row['actions']}",
                "",
            ))
        self._display("Coverage", "\n".join(lines))
        self.tabs.select(2)
