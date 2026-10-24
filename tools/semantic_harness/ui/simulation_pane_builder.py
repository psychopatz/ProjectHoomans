"""Build the simulation tab's pane topology and toolbar."""

from __future__ import annotations

from typing import Any


def build_simulation_panes(
    app: Any, simulation_tab: Any, ttk: Any
) -> tuple[Any, Any]:
    """Create the simulation toolbar and workflow pane hierarchy."""

    simulation_toolbar = ttk.Frame(simulation_tab)
    simulation_toolbar.grid(row=0, column=0, sticky="ew", pady=(0, 6))
    simulation_toolbar.columnconfigure(0, weight=1)
    app.simulation_context_var = app._tk.StringVar(
        value=(
            "Source FIXTURE · no saved target loaded · "
            "click Load saved NPC to run production rehydration"
        )
    )
    app.simulation_context_label = ttk.Label(
        simulation_toolbar,
        textvariable=app.simulation_context_var,
        anchor="w",
        justify="left",
        wraplength=720,
    )
    app.simulation_context_label.grid(
        row=0, column=0, sticky="ew", padx=(2, 8)
    )
    ttk.Button(
        simulation_toolbar,
        text="Load saved NPC",
        command=app._open_saved_world_browser,
    ).grid(row=0, column=1, sticky="e", padx=(0, 4))
    app.diagnostics_toggle_button = ttk.Button(
        simulation_toolbar,
        text="Hide diagnostics",
        command=app._toggle_trace_panel,
    )
    app.diagnostics_toggle_button.grid(
        row=0, column=2, sticky="e", padx=(0, 4)
    )
    app.advanced_toggle_button = ttk.Button(
        simulation_toolbar,
        text="Hide advanced",
        command=app._toggle_advanced_controls,
    )
    app.advanced_toggle_button.grid(row=0, column=3, sticky="e", padx=(0, 4))
    app.reset_layout_button = ttk.Button(
        simulation_toolbar,
        text="Reset layout",
        command=app._reset_ui_state,
    )
    app.reset_layout_button.grid(row=0, column=4, sticky="e")
    app.simulation_toolbar = simulation_toolbar

    container = ttk.Frame(simulation_tab)
    container.grid(row=1, column=0, sticky="nsew")
    container.rowconfigure(0, weight=1)
    container.columnconfigure(0, weight=1)
    app.simulation_panes = ttk.PanedWindow(container, orient="horizontal")
    app.simulation_panes.grid(row=0, column=0, sticky="nsew")
    workflow_pane = ttk.Frame(app.simulation_panes)
    app.simulation_workflow_pane = workflow_pane
    workflow_pane.rowconfigure(0, weight=1)
    workflow_pane.columnconfigure(0, weight=1)
    app.workflow_pane_split = ttk.PanedWindow(
        workflow_pane, orient="vertical"
    )
    app.workflow_pane_split.grid(row=0, column=0, sticky="nsew")
    conversation_pane = ttk.Frame(app.workflow_pane_split)
    conversation_pane.rowconfigure(0, weight=1)
    conversation_pane.columnconfigure(0, weight=1)
    workbench_pane = ttk.Frame(app.workflow_pane_split)
    workbench_pane.rowconfigure(0, weight=1)
    workbench_pane.columnconfigure(0, weight=1)
    app.simulation_panes.add(workflow_pane, weight=3)

    return conversation_pane, workbench_pane
