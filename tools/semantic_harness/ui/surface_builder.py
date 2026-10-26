"""Compose the top-level notebooks and delegate each surface to its builder."""

from __future__ import annotations

from typing import Any

from .saved_world_browser_builder import build_saved_world_browser
from .simulation_conversation_builder import build_conversation_panel
from .simulation_pane_builder import build_simulation_panes
from .simulation_controls_builder import build_workbench_controls
from .studio_surface_builder import build_studio_editors
from .trace_conversation_builder import build_conversation_trace
from .trace_diagnostic_builder import build_diagnostic_trace


def build_ui(app: Any) -> None:
    ttk = app._ttk
    scrolled_text = app._ScrolledText
    app.main_tabs = ttk.Notebook(app.root)
    app.main_tabs.pack(fill="both", expand=True, padx=6, pady=6)

    studio_tab = ttk.Frame(app.main_tabs, padding=6)
    simulation_tab = ttk.Frame(app.main_tabs, padding=8)
    studio_tab.rowconfigure(0, weight=1)
    studio_tab.columnconfigure(0, weight=1)
    simulation_tab.rowconfigure(0, weight=0)
    simulation_tab.rowconfigure(1, weight=1)
    simulation_tab.columnconfigure(0, weight=1)
    studio_notebook = ttk.Notebook(studio_tab)
    app.studio_notebook = studio_notebook
    studio_notebook.grid(row=0, column=0, sticky="nsew")
    observatory_tab = ttk.Frame(studio_notebook, padding=8)
    workflow_tab = ttk.Frame(studio_notebook, padding=8)
    editor_tab = ttk.Frame(studio_notebook, padding=8)
    library_tab = ttk.Frame(studio_notebook, padding=8)
    blocks_tab = ttk.Frame(studio_notebook, padding=8)
    composer_tab = ttk.Frame(studio_notebook, padding=8)
    for panel in (observatory_tab, workflow_tab, editor_tab, library_tab, blocks_tab, composer_tab):
        panel.rowconfigure(0, weight=1)
        panel.columnconfigure(0, weight=1)
    studio_notebook.add(observatory_tab, text="Observatory")
    studio_notebook.add(workflow_tab, text="Build workflow")
    studio_notebook.add(editor_tab, text="Flow + interactions")
    studio_notebook.add(library_tab, text="Dataset library")
    studio_notebook.add(blocks_tab, text="Block palette")
    studio_notebook.add(composer_tab, text="Interaction composer")
    log_tab = ttk.Frame(app.main_tabs, padding=8)
    log_tab.rowconfigure(1, weight=1)
    log_tab.columnconfigure(0, weight=1)
    app.activity_log_status = app._tk.StringVar(
        value="Shared GUI/CLI activity timeline"
    )
    log_toolbar = ttk.Frame(log_tab)
    log_toolbar.grid(row=0, column=0, sticky="ew", pady=(0, 6))
    ttk.Label(
        log_toolbar,
        textvariable=app.activity_log_status,
        anchor="w",
    ).pack(side="left", fill="x", expand=True)
    ttk.Button(
        log_toolbar,
        text="Clear view",
        command=app.clear_activity_log,
    ).pack(side="right")
    app.activity_log_widget = scrolled_text(log_tab, wrap="none", state="disabled")
    app.activity_log_widget.grid(row=1, column=0, sticky="nsew")

    world_browser_tab = ttk.Frame(app.main_tabs, padding=10)
    world_browser_tab.rowconfigure(1, weight=1)
    world_browser_tab.columnconfigure(0, weight=1)
    app.main_tabs.add(simulation_tab, text="Simulation")
    app.main_tabs.add(studio_tab, text="Studio")
    app.main_tabs.add(log_tab, text="Log")
    app.main_tabs.add(world_browser_tab, text="World Browser")
    app.studio_tab = studio_tab
    app.log_tab = log_tab
    app.world_browser_tab = world_browser_tab
    build_saved_world_browser(app, world_browser_tab)

    conversation_pane, workbench_pane = build_simulation_panes(
        app, simulation_tab, ttk
    )
    build_conversation_panel(app, conversation_pane, ttk, scrolled_text)
    build_workbench_controls(app, workbench_pane, ttk)
    right = ttk.LabelFrame(app.simulation_panes, text="Semantic trace")
    right.rowconfigure(0, weight=1)
    right.columnconfigure(0, weight=1)
    right.configure(width=420)
    app.trace_pane = right
    app.simulation_panes.add(right, weight=2)
    app.workflow_pane_split.add(conversation_pane, weight=3)
    app.workflow_pane_split.add(workbench_pane, weight=2)
    build_conversation_trace(app, right, ttk, scrolled_text)
    build_diagnostic_trace(app, ttk, scrolled_text)
    build_studio_editors(
        app,
        observatory_tab=observatory_tab,
        workflow_tab=workflow_tab,
        editor_tab=editor_tab,
        library_tab=library_tab,
        blocks_tab=blocks_tab,
        composer_tab=composer_tab,
        ttk=ttk,
        scrolled_text=scrolled_text,
    )
    app.simulation_tab = simulation_tab
    app.main_tabs.bind(
        "<<NotebookTabChanged>>",
        lambda _event: app._on_main_tab_changed(),
    )
    app._restore_ui_state()
    app._schedule_activity_poll()
    app._append("SYSTEM", "Window ready. Starting the isolated Lua worker…")
    app._set_controls(False)
