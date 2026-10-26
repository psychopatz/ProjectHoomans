"""Build the consolidated Simulation graph and comparison surfaces."""

from __future__ import annotations

from typing import Any

from .conversation_graph import ConversationGraphPane


def build_conversation_trace(
    app: Any, right: Any, ttk: Any, scrolled_text: Any
) -> None:
    """Create the graph and comparison homes of Simulation diagnostics."""

    app.trace_tabs = ttk.Notebook(right)
    app.trace_tabs.configure(width=420)
    app.trace_tabs.grid(row=0, column=0, sticky="nsew", padx=6, pady=6)

    app.inspect_frame = ttk.Frame(app.trace_tabs, padding=6)
    app.inspect_frame.rowconfigure(0, weight=1)
    app.inspect_frame.columnconfigure(0, weight=1)
    app.trace_tabs.add(app.inspect_frame, text="Inspect")

    graph_frame = ttk.Frame(app.trace_tabs, padding=4)
    graph_frame.rowconfigure(0, weight=1)
    graph_frame.columnconfigure(0, weight=1)
    app.graph_frame = graph_frame
    app.graph_tabs = ttk.Notebook(graph_frame)
    app.graph_tabs.grid(row=0, column=0, sticky="nsew")
    dialogue_graph_frame = ttk.Frame(app.graph_tabs)
    dialogue_graph_frame.rowconfigure(0, weight=1)
    dialogue_graph_frame.columnconfigure(0, weight=1)
    app.dialogue_graph_pane = ConversationGraphPane(
        dialogue_graph_frame,
        app._tk,
        ttk,
        on_click=app.click_graph_frame,
        on_diagnostics=app.show_conversation_graph_diagnostics,
    )
    app.graph_tabs.add(dialogue_graph_frame, text="Dialogue graph")
    app.dialogue_graph_frame = dialogue_graph_frame

    graph_detail_frame = ttk.Frame(app.graph_tabs)
    graph_detail_frame.rowconfigure(0, weight=1)
    graph_detail_frame.columnconfigure(0, weight=1)
    app.graph_detail_tabs = ttk.Notebook(graph_detail_frame)
    app.graph_detail_tabs.grid(row=0, column=0, sticky="nsew")
    hub_diagnostics_frame = ttk.Frame(app.graph_detail_tabs)
    hub_diagnostics_frame.rowconfigure(0, weight=1)
    hub_diagnostics_frame.columnconfigure(0, weight=1)
    app.hub_diagnostics = scrolled_text(
        hub_diagnostics_frame, wrap="none", state="disabled"
    )
    app.hub_diagnostics.grid(row=0, column=0, sticky="nsew")
    app.graph_detail_tabs.add(hub_diagnostics_frame, text="Hub diagnostics")
    app.hub_diagnostics_frame = hub_diagnostics_frame
    dialogue_diagnostics_frame = ttk.Frame(app.graph_detail_tabs)
    dialogue_diagnostics_frame.rowconfigure(0, weight=1)
    dialogue_diagnostics_frame.columnconfigure(0, weight=1)
    app.dialogue_diagnostics = scrolled_text(
        dialogue_diagnostics_frame, wrap="none", state="disabled"
    )
    app.dialogue_diagnostics.grid(row=0, column=0, sticky="nsew")
    app.graph_detail_tabs.add(
        dialogue_diagnostics_frame, text="Dialogue diagnostics"
    )
    app.dialogue_diagnostics_frame = dialogue_diagnostics_frame
    app.graph_tabs.add(graph_detail_frame, text="Runtime details")
    app.graph_detail_frame = graph_detail_frame
    app.trace_tabs.add(graph_frame, text="Graph")

    compare_frame = ttk.Frame(app.trace_tabs, padding=4)
    compare_frame.rowconfigure(0, weight=1)
    compare_frame.columnconfigure(0, weight=1)
    app.compare_frame = compare_frame
    app.compare_tabs = ttk.Notebook(compare_frame)
    app.compare_tabs.grid(row=0, column=0, sticky="nsew")

    context_compare_frame = ttk.Frame(app.compare_tabs, padding=6)
    context_compare_frame.rowconfigure(1, weight=1)
    context_compare_frame.columnconfigure(0, weight=1)
    compare_controls = ttk.Frame(context_compare_frame)
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
        values=(
            "persona",
            "approval",
            "respect",
            "familiarity",
            "bond",
            "language",
        ),
        width=16,
        state="readonly",
    )
    app.matrix_dimension_box.grid(row=2, column=1, sticky="w", pady=(6, 0))
    app.capture_baseline_button = ttk.Button(
        compare_controls, text="Capture baseline", command=app.capture_baseline
    )
    app.capture_baseline_button.grid(
        row=2, column=2, sticky="w", padx=(8, 0), pady=(6, 0)
    )
    app.persona_matrix_button = ttk.Button(
        compare_controls, text="Run comparison", command=app.inspect_persona_matrix
    )
    app.persona_matrix_button.grid(
        row=2, column=3, sticky="w", padx=(8, 0), pady=(6, 0)
    )
    app.compare_output = scrolled_text(
        context_compare_frame, wrap="none", state="disabled"
    )
    app.compare_output.grid(row=1, column=0, sticky="nsew")
    app.compare_tabs.add(context_compare_frame, text="Context comparison")
    app.compare_context_frame = context_compare_frame

    talk_frame = ttk.Frame(app.compare_tabs, padding=6)
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
    app.talk_choices_frame.grid(row=1, column=0, sticky="ew", pady=(0, 6))
    for column in range(3):
        app.talk_choices_frame.columnconfigure(column, weight=1)
    app.talk_choice_buttons: list[Any] = []
    app.talk_output = scrolled_text(talk_frame, wrap="none", state="disabled")
    app.talk_output.grid(row=2, column=0, sticky="nsew")
    app.compare_tabs.add(talk_frame, text="Talk parity")
    app.talk_parity_frame = talk_frame

    regression_frame = ttk.Frame(app.compare_tabs, padding=6)
    regression_frame.rowconfigure(1, weight=1)
    regression_frame.columnconfigure(0, weight=1)
    regression_toolbar = ttk.Frame(regression_frame)
    regression_toolbar.grid(row=0, column=0, sticky="ew", pady=(0, 6))
    app.regression_greeting_button = ttk.Button(
        regression_toolbar,
        text="Greeting + companion",
        command=app.run_regression,
    )
    app.regression_greeting_button.grid(row=0, column=0, sticky="w")
    app.regression_lifecycle_button = ttk.Button(
        regression_toolbar,
        text="Farewell lifecycle",
        command=app.run_regression_lifecycle,
    )
    app.regression_lifecycle_button.grid(row=0, column=1, padx=(6, 0), sticky="w")
    app.regression_rejection_button = ttk.Button(
        regression_toolbar,
        text="Authority rejection",
        command=app.run_regression_command_rejections,
    )
    app.regression_rejection_button.grid(row=0, column=2, padx=(6, 0), sticky="w")
    app.regression_selection_button = ttk.Button(
        regression_toolbar,
        text="Explain selection matrix",
        command=app.run_regression_selection,
    )
    app.regression_selection_button.grid(row=0, column=3, padx=(6, 0), sticky="w")
    app.regression_status_var = app._tk.StringVar(
        value="Bounded production-Lua fixtures · no native SP/MP claim"
    )
    ttk.Label(
        regression_toolbar, textvariable=app.regression_status_var
    ).grid(row=0, column=4, padx=(12, 0), sticky="w")
    app.regression_output = scrolled_text(
        regression_frame, wrap="none", state="disabled"
    )
    app.regression_output.grid(row=1, column=0, sticky="nsew")
    app.compare_tabs.add(regression_frame, text="Regression")
    app.regression_frame = regression_frame
    app.regression_buttons = (
        app.regression_greeting_button,
        app.regression_lifecycle_button,
        app.regression_rejection_button,
        app.regression_selection_button,
    )

    app.trace_tabs.add(compare_frame, text="Compare / Regression")


__all__ = ["build_conversation_trace"]
