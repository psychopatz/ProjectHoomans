"""Build diagnostics and inspection trace tabs for the semantic harness UI."""

from __future__ import annotations

from typing import Any


def build_diagnostic_trace(app: Any, ttk: Any, scrolled_text: Any) -> None:
    """Build worker, semantic, provenance, and knowledge inspectors."""

    diagnostics_frame = ttk.Frame(app.trace_tabs, padding=6)
    diagnostics_frame.columnconfigure(0, weight=1)
    ttk.Label(
        diagnostics_frame,
        text="Worker and maintenance diagnostics",
        font=("TkDefaultFont", 10, "bold"),
    ).grid(row=0, column=0, sticky="w")
    diagnostics_actions = ttk.Frame(diagnostics_frame)
    diagnostics_actions.grid(row=1, column=0, sticky="w", pady=(6, 6))
    app.snapshot_button = ttk.Button(
        diagnostics_actions, text="Snapshot", command=app.show_snapshot
    )
    app.snapshot_button.pack(side="left")
    app.restart_button = ttk.Button(
        diagnostics_actions, text="Restart worker", command=app.restart
    )
    app.restart_button.pack(side="left", padx=(6, 0))
    ttk.Label(
        diagnostics_frame,
        text="Raw worker records remain available in the Raw worker record tab.",
    ).grid(row=2, column=0, sticky="w")
    app.trace_tabs.add(diagnostics_frame, text="Diagnostics / Worker")
    app.diagnostics_frame = diagnostics_frame
    conversation_frame = ttk.Frame(app.trace_tabs)
    conversation_frame.rowconfigure(0, weight=1)
    conversation_frame.columnconfigure(0, weight=1)
    app.inspector = scrolled_text(
        conversation_frame, wrap="word", state="disabled"
    )
    app.inspector.grid(row=0, column=0, sticky="nsew")
    app.trace_tabs.add(conversation_frame, text="Conversation understanding")
    authority_frame = ttk.Frame(app.trace_tabs)
    authority_frame.rowconfigure(0, weight=1)
    authority_frame.columnconfigure(0, weight=1)
    app.authority = scrolled_text(
        authority_frame, wrap="word", state="disabled"
    )
    app.authority.grid(row=0, column=0, sticky="nsew")
    app.trace_tabs.add(authority_frame, text="Command authority")
    raw_frame = ttk.Frame(app.trace_tabs)
    raw_frame.rowconfigure(0, weight=1)
    raw_frame.columnconfigure(0, weight=1)
    app.trace = scrolled_text(raw_frame, wrap="none", state="disabled")
    app.trace.grid(row=0, column=0, sticky="nsew")
    app.trace_tabs.add(raw_frame, text="Raw worker record")
    suggestion_trace_frame = ttk.Frame(app.trace_tabs)
    suggestion_trace_frame.rowconfigure(0, weight=1)
    suggestion_trace_frame.columnconfigure(0, weight=1)
    app.suggestion_inspector = scrolled_text(
        suggestion_trace_frame, wrap="none", state="disabled"
    )
    app.suggestion_inspector.grid(row=0, column=0, sticky="nsew")
    app.trace_tabs.add(suggestion_trace_frame, text="Suggestions + predicates")
    provenance_frame = ttk.Frame(app.trace_tabs)
    provenance_frame.rowconfigure(0, weight=1)
    provenance_frame.columnconfigure(0, weight=1)
    app.provenance_inspector = scrolled_text(
        provenance_frame, wrap="none", state="disabled"
    )
    app.provenance_inspector.grid(row=0, column=0, sticky="nsew")
    app.trace_tabs.add(provenance_frame, text="Provenance")
    world_knowledge_frame = ttk.Frame(app.trace_tabs)
    app.world_knowledge_frame = world_knowledge_frame
    world_knowledge_frame.rowconfigure(1, weight=1)
    world_knowledge_frame.columnconfigure(0, weight=1)
    world_knowledge_toolbar = ttk.Frame(world_knowledge_frame)
    world_knowledge_toolbar.grid(row=0, column=0, sticky="ew", padx=6, pady=(6, 0))
    app.world_knowledge_button = ttk.Button(
        world_knowledge_toolbar,
        text="Refresh world knowledge",
        command=app.inspect_world_knowledge,
    )
    app.world_knowledge_button.pack(side="left")
    app.world_knowledge_inspector = scrolled_text(
        world_knowledge_frame, wrap="none", state="disabled"
    )
    app.world_knowledge_inspector.grid(row=1, column=0, sticky="nsew", padx=6, pady=6)
    app.trace_tabs.add(world_knowledge_frame, text="World Knowledge")
