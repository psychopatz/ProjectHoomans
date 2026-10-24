"""Build conversation-oriented trace tabs for the semantic harness UI."""

from __future__ import annotations

from typing import Any

from .conversation_graph import ConversationGraphPane


def build_conversation_trace(
    app: Any, right: Any, ttk: Any, scrolled_text: Any
) -> None:
    """Build dialogue graph, comparison, and Talk parity tabs."""

    app.trace_tabs = ttk.Notebook(right)
    app.trace_tabs.configure(width=420)
    app.trace_tabs.grid(row=0, column=0, sticky="nsew", padx=6, pady=6)
    dialogue_graph_frame = ttk.Frame(app.trace_tabs)
    dialogue_graph_frame.rowconfigure(0, weight=1)
    dialogue_graph_frame.columnconfigure(0, weight=1)
    app.dialogue_graph_pane = ConversationGraphPane(
        dialogue_graph_frame, app._tk, ttk,
        on_click=app.click_graph_frame,
        on_diagnostics=app.show_conversation_graph_diagnostics,
    )
    app.trace_tabs.add(dialogue_graph_frame, text="Dialogue graph")
    app.dialogue_graph_frame = dialogue_graph_frame
    hub_diagnostics_frame = ttk.Frame(app.trace_tabs)
    hub_diagnostics_frame.rowconfigure(0, weight=1)
    hub_diagnostics_frame.columnconfigure(0, weight=1)
    app.hub_diagnostics = scrolled_text(
        hub_diagnostics_frame, wrap="none", state="disabled"
    )
    app.hub_diagnostics.grid(row=0, column=0, sticky="nsew")
    app.trace_tabs.add(hub_diagnostics_frame, text="Hub diagnostics")
    app.hub_diagnostics_frame = hub_diagnostics_frame
    dialogue_diagnostics_frame = ttk.Frame(app.trace_tabs)
    dialogue_diagnostics_frame.rowconfigure(0, weight=1)
    dialogue_diagnostics_frame.columnconfigure(0, weight=1)
    app.dialogue_diagnostics = scrolled_text(
        dialogue_diagnostics_frame, wrap="none", state="disabled"
    )
    app.dialogue_diagnostics.grid(row=0, column=0, sticky="nsew")
    app.trace_tabs.add(
        dialogue_diagnostics_frame, text="Dialogue diagnostics"
    )
    app.dialogue_diagnostics_frame = dialogue_diagnostics_frame
    compare_frame = ttk.Frame(app.trace_tabs, padding=6)
    compare_frame.rowconfigure(1, weight=1)
    compare_frame.columnconfigure(0, weight=1)
    compare_controls = ttk.Frame(compare_frame)
    compare_controls.grid(row=0, column=0, sticky="ew", pady=(0, 6))
    compare_controls.columnconfigure(1, weight=1)
    ttk.Label(
        compare_controls,
        text="Run the same utterance through current, low, and high production contexts.",
    ).grid(row=0, column=0, columnspan=4, sticky="w", pady=(0, 6))
    ttk.Label(compare_controls, text="Utterance").grid(
        row=1, column=0, sticky="w", padx=(0, 6)
    )
    app.compare_utterance_box = ttk.Entry(
        compare_controls, textvariable=app.compare_utterance_var
    )
    app.compare_utterance_box.grid(row=1, column=1, columnspan=3, sticky="ew")
    ttk.Label(compare_controls, text="Compare by").grid(
        row=2, column=0, sticky="w", padx=(0, 6), pady=(6, 0)
    )
    app.matrix_dimension_box = ttk.Combobox(
        compare_controls,
        textvariable=app.matrix_dimension_var,
        values=("persona", "approval", "respect", "familiarity", "bond", "language"),
        width=16,
        state="readonly",
    )
    app.matrix_dimension_box.grid(row=2, column=1, sticky="w", pady=(6, 0))
    app.capture_baseline_button = ttk.Button(
        compare_controls, text="Capture baseline", command=app.capture_baseline
    )
    app.capture_baseline_button.grid(row=2, column=2, sticky="w", padx=(8, 0), pady=(6, 0))
    app.persona_matrix_button = ttk.Button(
        compare_controls, text="Run comparison", command=app.inspect_persona_matrix
    )
    app.persona_matrix_button.grid(row=2, column=3, sticky="w", padx=(8, 0), pady=(6, 0))
    app.compare_output = scrolled_text(compare_frame, wrap="none", state="disabled")
    app.compare_output.grid(row=1, column=0, sticky="nsew")
    app.trace_tabs.add(compare_frame, text="Compare")
    app.compare_frame = compare_frame
    talk_frame = ttk.Frame(app.trace_tabs, padding=6)
    talk_frame.rowconfigure(2, weight=1)
    talk_frame.columnconfigure(0, weight=1)
    talk_controls = ttk.Frame(talk_frame)
    talk_controls.grid(row=0, column=0, sticky="ew", pady=(0, 6))
    talk_controls.columnconfigure(0, weight=1)
    app.talk_utterance_box = ttk.Entry(
        talk_controls, textvariable=app.talk_utterance_var
    )
    app.talk_utterance_box.grid(row=0, column=0, sticky="ew", padx=(0, 6))
    app.talk_target_box = ttk.Combobox(
        talk_controls,
        textvariable=app.talk_target_var,
        values=("Current target",),
        width=14,
        state="readonly",
    )
    app.talk_target_box.grid(row=0, column=1, sticky="w")
    app.talk_start_button = ttk.Button(
        talk_controls, text="Start", command=app.start_talk_parity
    )
    app.talk_start_button.grid(row=0, column=2, sticky="w", padx=(6, 0))
    app.talk_matrix_button = ttk.Button(
        talk_controls, text="All types", command=app.run_talk_matrix
    )
    app.talk_matrix_button.grid(row=0, column=3, sticky="w", padx=(6, 0))
    app.talk_choices_frame = ttk.LabelFrame(
        talk_frame, text="Current Talk choices"
    )
    app.talk_choices_frame.grid(
        row=1, column=0, sticky="ew", pady=(0, 6)
    )
    for column in range(3):
        app.talk_choices_frame.columnconfigure(column, weight=1)
    app.talk_choice_buttons: list[Any] = []
    app.talk_output = scrolled_text(talk_frame, wrap="none", state="disabled")
    app.talk_output.grid(row=2, column=0, sticky="nsew")
    app.trace_tabs.add(talk_frame, text="Talk parity")
    app.talk_parity_frame = talk_frame
