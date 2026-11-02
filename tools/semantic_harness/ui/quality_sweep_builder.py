"""Build the dedicated Quality Sweep workbench UI."""

from __future__ import annotations

from typing import Any

from .quality_sweep_controller import (
    init_quality_sweep_state,
    on_qs_apply_filter,
    on_qs_cancel,
    on_qs_clear_filter,
    on_qs_cluster_select,
    on_qs_copy_evidence,
    on_qs_evidence_select,
    on_qs_export_bundle,
    on_qs_locate_source,
    on_qs_open_full_inspector,
    on_qs_plan,
    on_qs_reachability_scan,
    on_qs_refresh,
    on_qs_replay_case,
    on_qs_replay_cluster,
    on_qs_run,
)


def build_quality_sweep_workbench(app: Any, parent: Any) -> None:
    """Build the dedicated Quality Sweep tab as a top-level surface."""
    ttk = app._ttk
    scrolled_text = app._ScrolledText

    init_quality_sweep_state(app)

    parent.rowconfigure(1, weight=1)
    parent.columnconfigure(0, weight=1)

    # 1. Header Frame: Configuration & Actions
    header_frame = ttk.LabelFrame(parent, text="Sweep Configuration & Batch Control", padding=6)
    header_frame.grid(row=0, column=0, sticky="ew", pady=(0, 6))
    header_frame.columnconfigure(10, weight=1)

    ttk.Label(header_frame, text="Strategy:").grid(row=0, column=0, sticky="w", padx=(0, 4))
    strategy_combo = ttk.Combobox(
        header_frame,
        textvariable=app.quality_sweep_strategy_var,
        values=["smoke", "boundary", "pairwise", "persona", "reachability", "full"],
        width=11,
        state="readonly",
    )
    strategy_combo.grid(row=0, column=1, sticky="w", padx=(0, 8))

    ttk.Label(header_frame, text="Sweep ID:").grid(row=0, column=2, sticky="w", padx=(0, 4))
    id_entry = ttk.Entry(header_frame, textvariable=app.quality_sweep_id_var, width=16)
    id_entry.grid(row=0, column=3, sticky="w", padx=(0, 8))

    ttk.Label(header_frame, text="Languages:").grid(row=0, column=4, sticky="w", padx=(0, 4))
    lang_entry = ttk.Entry(header_frame, textvariable=app.quality_sweep_languages_var, width=8)
    lang_entry.grid(row=0, column=5, sticky="w", padx=(0, 8))

    ttk.Label(header_frame, text="Max Cases:").grid(row=0, column=6, sticky="w", padx=(0, 4))
    max_cases_entry = ttk.Entry(header_frame, textvariable=app.quality_sweep_max_cases_var, width=6)
    max_cases_entry.grid(row=0, column=7, sticky="w", padx=(0, 8))

    app.qs_plan_button = ttk.Button(
        header_frame, text="Plan", command=lambda: on_qs_plan(app)
    )
    app.qs_plan_button.grid(row=0, column=8, sticky="w", padx=(0, 4))

    app.qs_run_button = ttk.Button(
        header_frame, text="Run / Resume", command=lambda: on_qs_run(app)
    )
    app.qs_run_button.grid(row=0, column=9, sticky="w", padx=(0, 4))

    app.qs_cancel_button = ttk.Button(
        header_frame, text="Cancel", command=lambda: on_qs_cancel(app), state="disabled"
    )
    app.qs_cancel_button.grid(row=0, column=10, sticky="w", padx=(0, 4))

    app.qs_refresh_button = ttk.Button(
        header_frame, text="Refresh", command=lambda: on_qs_refresh(app)
    )
    app.qs_refresh_button.grid(row=0, column=11, sticky="w", padx=(0, 4))

    app.qs_export_bundle_button = ttk.Button(
        header_frame, text="Export Review Bundle", command=lambda: on_qs_export_bundle(app)
    )
    app.qs_export_bundle_button.grid(row=0, column=12, sticky="e", padx=(4, 0))

    # Header Row 1: Summary & Status
    status_subframe = ttk.Frame(header_frame, padding=(0, 4, 0, 0))
    status_subframe.grid(row=1, column=0, columnspan=13, sticky="ew")
    status_subframe.columnconfigure(0, weight=1)

    ttk.Label(status_subframe, textvariable=app.quality_sweep_summary_var, anchor="w").grid(
        row=0, column=0, sticky="w"
    )
    ttk.Label(status_subframe, textvariable=app.quality_sweep_status_var, anchor="w").grid(
        row=1, column=0, sticky="w"
    )
    app.qs_progressbar = ttk.Progressbar(
        status_subframe,
        variable=app.quality_sweep_progress_var,
        maximum=100.0,
        mode="determinate",
    )
    app.qs_progressbar.grid(row=2, column=0, sticky="ew", pady=(2, 0))

    # 2. Main PanedWindow (Horizontal split: Left explorer/results, Right structured inspector)
    panes = ttk.PanedWindow(parent, orient="horizontal")
    panes.grid(row=1, column=0, sticky="nsew")

    left_frame = ttk.Frame(panes)
    left_frame.rowconfigure(0, weight=1)
    left_frame.columnconfigure(0, weight=1)

    right_frame = ttk.Frame(panes)
    right_frame.rowconfigure(1, weight=1)
    right_frame.columnconfigure(0, weight=1)

    panes.add(left_frame, weight=3)
    panes.add(right_frame, weight=2)

    # Left Notebook
    app.qs_notebook = ttk.Notebook(left_frame)
    app.qs_notebook.grid(row=0, column=0, sticky="nsew")

    # --- TAB 1: Evidence Rows ---
    evidence_tab = ttk.Frame(app.qs_notebook, padding=4)
    evidence_tab.rowconfigure(1, weight=1)
    evidence_tab.columnconfigure(0, weight=1)
    app.qs_notebook.add(evidence_tab, text="Evidence Rows")

    # Filter Bar
    filter_bar = ttk.LabelFrame(evidence_tab, text="Filter Evidence", padding=4)
    filter_bar.grid(row=0, column=0, sticky="ew", pady=(0, 4))
    filter_bar.columnconfigure(10, weight=1)

    ttk.Label(filter_bar, text="Text:").grid(row=0, column=0, sticky="w")
    ttk.Entry(filter_bar, textvariable=app.qs_filter_text_var, width=12).grid(row=0, column=1, sticky="w", padx=(2, 6))

    ttk.Label(filter_bar, text="Sev:").grid(row=0, column=2, sticky="w")
    ttk.Combobox(
        filter_bar,
        textvariable=app.qs_filter_severity_var,
        values=["ALL", "CRITICAL", "HIGH", "MEDIUM", "LOW", "INFO", "CLEAN"],
        width=8,
        state="readonly",
    ).grid(row=0, column=3, sticky="w", padx=(2, 6))

    ttk.Label(filter_bar, text="Flag:").grid(row=0, column=4, sticky="w")
    ttk.Combobox(
        filter_bar,
        textvariable=app.qs_filter_flag_var,
        values=[
            "ALL",
            "FALLBACK_SATURATION",
            "UNSUPPORTED_FAMILY_REFERENCE",
            "VARIANT_COLLAPSE",
            "GENERIC_ACKNOWLEDGEMENT_CONCENTRATION",
            "DUPLICATE_RENDERED_TEXT",
            "ONE_WORD_RESPONSE",
            "PLACEHOLDER_LEAK",
            "TRANSLATION_KEY_LEAK",
            "RELATIONSHIP_TERM_WITHOUT_BOND",
        ],
        width=16,
    ).grid(row=0, column=5, sticky="w", padx=(2, 6))

    ttk.Checkbutton(
        filter_bar, text="Invalid surfaces only", variable=app.qs_filter_invalid_only_var
    ).grid(row=0, column=6, sticky="w", padx=(2, 4))

    ttk.Checkbutton(
        filter_bar, text="Duplicates only", variable=app.qs_filter_duplicate_only_var
    ).grid(row=0, column=7, sticky="w", padx=(2, 6))

    ttk.Button(
        filter_bar, text="Apply", command=lambda: on_qs_apply_filter(app)
    ).grid(row=0, column=8, sticky="w", padx=(0, 4))

    ttk.Button(
        filter_bar, text="Clear", command=lambda: on_qs_clear_filter(app)
    ).grid(row=0, column=9, sticky="w", padx=(0, 4))

    ttk.Label(filter_bar, textvariable=app.qs_filter_count_var, anchor="e").grid(
        row=0, column=10, sticky="e"
    )

    # Evidence Treeview
    ev_cols = (
        "severity",
        "flag",
        "text",
        "planned_surface",
        "reached_route",
        "lang",
        "template",
        "variant",
        "case_id",
        "source",
    )
    app.qs_evidence_tree = ttk.Treeview(
        evidence_tab, columns=ev_cols, show="headings", height=14
    )
    app.qs_evidence_tree.heading("severity", text="Severity")
    app.qs_evidence_tree.heading("flag", text="Flag")
    app.qs_evidence_tree.heading("text", text="Rendered Text")
    app.qs_evidence_tree.heading("planned_surface", text="Planned Surface")
    app.qs_evidence_tree.heading("reached_route", text="Reached Route")
    app.qs_evidence_tree.heading("lang", text="Lang")
    app.qs_evidence_tree.heading("template", text="Template")
    app.qs_evidence_tree.heading("variant", text="Variant")
    app.qs_evidence_tree.heading("case_id", text="Case ID")
    app.qs_evidence_tree.heading("source", text="Canonical Source")

    app.qs_evidence_tree.column("severity", width=70, anchor="center")
    app.qs_evidence_tree.column("flag", width=140)
    app.qs_evidence_tree.column("text", width=220)
    app.qs_evidence_tree.column("planned_surface", width=110)
    app.qs_evidence_tree.column("reached_route", width=110)
    app.qs_evidence_tree.column("lang", width=45, anchor="center")
    app.qs_evidence_tree.column("template", width=120)
    app.qs_evidence_tree.column("variant", width=100)
    app.qs_evidence_tree.column("case_id", width=90)
    app.qs_evidence_tree.column("source", width=130)

    app.qs_evidence_tree.grid(row=1, column=0, sticky="nsew")
    app.qs_evidence_tree.bind("<<TreeviewSelect>>", lambda _e: on_qs_evidence_select(app))

    # --- TAB 2: Defect Clusters ---
    cluster_tab = ttk.Frame(app.qs_notebook, padding=4)
    cluster_tab.rowconfigure(1, weight=1)
    cluster_tab.rowconfigure(2, weight=1)
    cluster_tab.columnconfigure(0, weight=1)
    app.qs_notebook.add(cluster_tab, text="Defect Clusters")

    cl_bar = ttk.Frame(cluster_tab)
    cl_bar.grid(row=0, column=0, sticky="ew", pady=(0, 4))
    cl_bar.columnconfigure(0, weight=1)
    ttk.Label(cl_bar, text="Canonical Root-Cause Defect Clusters", font=("TkDefaultFont", 9, "bold")).grid(
        row=0, column=0, sticky="w"
    )
    ttk.Button(
        cl_bar, text="Replay Selected Cluster", command=lambda: on_qs_replay_cluster(app)
    ).grid(row=0, column=1, sticky="e")

    cl_cols = ("severity", "flag", "count", "source", "phrase", "cluster_id")
    app.qs_cluster_tree = ttk.Treeview(
        cluster_tab, columns=cl_cols, show="headings", height=8
    )
    app.qs_cluster_tree.heading("severity", text="Severity")
    app.qs_cluster_tree.heading("flag", text="Primary Flag")
    app.qs_cluster_tree.heading("count", text="Count")
    app.qs_cluster_tree.heading("source", text="Canonical Source")
    app.qs_cluster_tree.heading("phrase", text="Phrase / Template")
    app.qs_cluster_tree.heading("cluster_id", text="Cluster ID")

    app.qs_cluster_tree.column("severity", width=80, anchor="center")
    app.qs_cluster_tree.column("flag", width=180)
    app.qs_cluster_tree.column("count", width=60, anchor="center")
    app.qs_cluster_tree.column("source", width=150)
    app.qs_cluster_tree.column("phrase", width=140)
    app.qs_cluster_tree.column("cluster_id", width=160)

    app.qs_cluster_tree.grid(row=1, column=0, sticky="nsew", pady=(0, 4))
    app.qs_cluster_tree.bind("<<TreeviewSelect>>", lambda _e: on_qs_cluster_select(app))

    app.qs_cluster_details_text = scrolled_text(
        cluster_tab, wrap="word", state="disabled", height=8
    )
    app.qs_cluster_details_text.grid(row=2, column=0, sticky="nsew")

    # --- TAB 3: Coverage: Surfaces ---
    surfaces_tab = ttk.Frame(app.qs_notebook, padding=4)
    surfaces_tab.rowconfigure(0, weight=1)
    surfaces_tab.columnconfigure(0, weight=1)
    app.qs_notebook.add(surfaces_tab, text="Coverage: Surfaces")

    surf_cols = ("surface_id", "provider", "type", "executable", "planned", "reached", "status", "last_route")
    app.qs_surfaces_tree = ttk.Treeview(
        surfaces_tab, columns=surf_cols, show="headings", height=12
    )
    for c in surf_cols:
        app.qs_surfaces_tree.heading(c, text=c.replace("_", " ").title())
    app.qs_surfaces_tree.grid(row=0, column=0, sticky="nsew")

    # --- TAB 4: Coverage: Dimensions ---
    dims_tab = ttk.Frame(app.qs_notebook, padding=4)
    dims_tab.rowconfigure(0, weight=1)
    dims_tab.columnconfigure(0, weight=1)
    app.qs_notebook.add(dims_tab, text="Coverage: Dimensions")

    dim_cols = ("dimension_id", "type", "source", "buckets", "prerequisite", "selected")
    app.qs_dimensions_tree = ttk.Treeview(
        dims_tab, columns=dim_cols, show="headings", height=12
    )
    for c in dim_cols:
        app.qs_dimensions_tree.heading(c, text=c.replace("_", " ").title())
    app.qs_dimensions_tree.column("buckets", width=220)
    app.qs_dimensions_tree.grid(row=0, column=0, sticky="nsew")

    # --- TAB 5: Coverage: Pools & Variants ---
    pools_tab = ttk.Frame(app.qs_notebook, padding=4)
    pools_tab.rowconfigure(1, weight=1)
    pools_tab.columnconfigure(0, weight=1)
    app.qs_notebook.add(pools_tab, text="Coverage: Pools & Variants")

    pool_bar = ttk.Frame(pools_tab)
    pool_bar.grid(row=0, column=0, sticky="ew", pady=(0, 4))
    pool_bar.columnconfigure(0, weight=1)
    ttk.Label(pool_bar, text="Full Paginated Response Pools & Reachability Frontier", font=("TkDefaultFont", 9, "bold")).grid(
        row=0, column=0, sticky="w"
    )
    ttk.Button(
        pool_bar, text="Scan Reachability", command=lambda: on_qs_reachability_scan(app)
    ).grid(row=0, column=1, sticky="e")

    pool_cols = ("pool_id", "variant_id", "reachability_state", "conditions", "selected_count", "source")
    app.qs_pools_tree = ttk.Treeview(
        pools_tab, columns=pool_cols, show="headings", height=12
    )
    for c in pool_cols:
        app.qs_pools_tree.heading(c, text=c.replace("_", " ").title())
    app.qs_pools_tree.column("reachability_state", width=140, anchor="center")
    app.qs_pools_tree.column("conditions", width=200)
    app.qs_pools_tree.grid(row=1, column=0, sticky="nsew")

    # --- TAB 6: Batches ---
    batches_tab = ttk.Frame(app.qs_notebook, padding=4)
    batches_tab.rowconfigure(0, weight=1)
    batches_tab.columnconfigure(0, weight=1)
    app.qs_notebook.add(batches_tab, text="Batches")

    batch_cols = ("batch_id", "status", "cases", "invalid", "failed", "duration")
    app.qs_batches_tree = ttk.Treeview(
        batches_tab, columns=batch_cols, show="headings", height=12
    )
    for c in batch_cols:
        app.qs_batches_tree.heading(c, text=c.replace("_", " ").title())
    app.qs_batches_tree.grid(row=0, column=0, sticky="nsew")

    # Right Side: Evidence Detail Inspector
    insp_box = ttk.LabelFrame(right_frame, text="Evidence Detail Inspector", padding=6)
    insp_box.grid(row=0, column=0, sticky="nsew")
    insp_box.rowconfigure(1, weight=1)
    insp_box.columnconfigure(0, weight=1)

    insp_actions = ttk.Frame(insp_box)
    insp_actions.grid(row=0, column=0, sticky="ew", pady=(0, 6))

    ttk.Button(
        insp_actions,
        text="Open Full Conversation Inspector",
        command=lambda: on_qs_open_full_inspector(app),
    ).pack(side="left", padx=(0, 4))

    ttk.Button(
        insp_actions,
        text="Replay Case",
        command=lambda: on_qs_replay_case(app),
    ).pack(side="left", padx=(0, 4))

    ttk.Button(
        insp_actions,
        text="Locate Source",
        command=lambda: on_qs_locate_source(app),
    ).pack(side="left", padx=(0, 4))

    ttk.Button(
        insp_actions,
        text="Copy Evidence",
        command=lambda: on_qs_copy_evidence(app),
    ).pack(side="left", padx=(0, 4))

    app.qs_inspector_text = scrolled_text(
        insp_box, wrap="word", state="disabled", height=20
    )
    app.qs_inspector_text.grid(row=1, column=0, sticky="nsew")
