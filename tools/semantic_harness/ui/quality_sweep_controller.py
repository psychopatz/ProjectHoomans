"""Controller logic for the dedicated Quality Sweep workbench."""

from __future__ import annotations

import json
from pathlib import Path
import queue
import threading
from typing import Any, Mapping, Sequence

from ..testing.sweep_dimensions import DiscoveredSurface, SweepDimensionInventory, discover_interaction_surfaces, extract_dimension_inventory
from ..testing.sweep_planner import CoveragePlan
from ..testing.sweep_reachability import ReachabilityReport
from ..testing.sweep_service import DialogueQualitySweepService


def init_quality_sweep_state(app: Any) -> None:
    """Initialize state variables and attributes on app for Quality Sweep."""
    if hasattr(app, "_qs_initialized") and app._qs_initialized:
        return
    app._qs_initialized = True

    app.quality_sweep_strategy_var = app._tk.StringVar(value="smoke")
    app.quality_sweep_id_var = app._tk.StringVar(value="dialogue_sweep_v1")
    app.quality_sweep_languages_var = app._tk.StringVar(value="EN,TL")
    app.quality_sweep_max_cases_var = app._tk.IntVar(value=512)
    app.quality_sweep_batch_size_var = app._tk.IntVar(value=64)
    app.quality_sweep_status_var = app._tk.StringVar(value="Status: Ready")
    app.quality_sweep_summary_var = app._tk.StringVar(value="Plan: No plan generated yet")
    app.quality_sweep_progress_var = app._tk.DoubleVar(value=0.0)

    # Filter variables
    app.qs_filter_text_var = app._tk.StringVar(value="")
    app.qs_filter_severity_var = app._tk.StringVar(value="ALL")
    app.qs_filter_flag_var = app._tk.StringVar(value="ALL")
    app.qs_filter_lang_var = app._tk.StringVar(value="ALL")
    app.qs_filter_surface_var = app._tk.StringVar(value="ALL")
    app.qs_filter_reachability_var = app._tk.StringVar(value="ALL")
    app.qs_filter_invalid_only_var = app._tk.BooleanVar(value=False)
    app.qs_filter_duplicate_only_var = app._tk.BooleanVar(value=False)
    app.qs_filter_count_var = app._tk.StringVar(value="0 rows")

    # State stores
    app.quality_sweep_is_running = False
    app.quality_sweep_cancel_requested = False
    app.quality_sweep_plan: CoveragePlan | None = None
    app.quality_sweep_manifest: Any | None = None
    app.quality_sweep_cluster_report: Any | None = None
    app.quality_sweep_reachability_report: ReachabilityReport | None = None
    app.quality_sweep_inventory: SweepDimensionInventory | None = None
    app.quality_sweep_evidence_rows: list[dict[str, Any]] = []
    app.quality_sweep_filtered_rows: list[dict[str, Any]] = []
    app.selected_quality_sweep_row: dict[str, Any] | None = None
    app.selected_quality_sweep_cluster: Any | None = None
    app.quality_sweep_event_queue: queue.Queue = queue.Queue()


def on_qs_plan(app: Any) -> None:
    """Generate and display a coverage plan."""
    strategy = str(app.quality_sweep_strategy_var.get() or "smoke")
    sweep_id = str(app.quality_sweep_id_var.get() or "dialogue_sweep_v1")
    max_cases = int(app.quality_sweep_max_cases_var.get() or 512)
    langs_str = str(app.quality_sweep_languages_var.get() or "EN,TL")
    languages = [l.strip().upper() for l in langs_str.split(",") if l.strip()]

    active_worker = app.worker if getattr(app, "worker_ready", False) and getattr(app, "worker", None) else None
    service = DialogueQualitySweepService()

    try:
        inventory = None
        if hasattr(app, "simulation_control_catalog") and app.simulation_control_catalog:
            inventory = extract_dimension_inventory(
                control_catalog=app.simulation_control_catalog,
                persona_catalog=getattr(app, "persona_catalog", None),
            )
        elif active_worker is not None:
            inventory = extract_dimension_inventory(active_worker)

        plan = service.plan_sweep(
            strategy=strategy,
            sweep_id=sweep_id,
            languages=languages,
            max_cases=max_cases,
            inventory=inventory,
            worker=active_worker,
        )
        app.quality_sweep_plan = plan
        app.quality_sweep_inventory = inventory or service.get_dimension_inventory(active_worker)

        # Update summary label
        surface_count = len(plan.planned_surfaces)
        dim_count = len(plan.dimension_summary)
        app.quality_sweep_summary_var.set(
            f"Planned {plan.total_cases} cases in {plan.estimated_batches} batch(es) "
            f"({surface_count} surfaces, {dim_count} dimensions, {len(languages)} langs). "
            f"Digest: {plan.plan_digest[:8]}"
        )
        app.quality_sweep_status_var.set(f"Plan ready: {plan.total_cases} cases")

        # Populate Coverage Explorer
        _populate_surfaces_tree(app, plan)
        _populate_dimensions_tree(app, app.quality_sweep_inventory)
        _populate_batches_tree_from_plan(app, plan)

        if hasattr(app, "_refresh_sweep_feedback"):
            app._refresh_sweep_feedback(f"Plan generated: {plan.total_cases} cases.")
    except Exception as exc:
        app.quality_sweep_status_var.set(f"Plan error: {exc}")
        if hasattr(app, "_messagebox"):
            app._messagebox.showerror("Quality Sweep", f"Planning failed: {exc}")


def on_qs_run(app: Any) -> None:
    """Execute or resume sweep batches in a responsive background worker thread."""
    if getattr(app, "quality_sweep_is_running", False):
        return
    if getattr(app, "quality_sweep_plan", None) is None:
        on_qs_plan(app)
        if getattr(app, "quality_sweep_plan", None) is None:
            return

    plan = app.quality_sweep_plan
    batch_size = int(app.quality_sweep_batch_size_var.get() or 64)
    service = DialogueQualitySweepService()

    app.quality_sweep_is_running = True
    app.quality_sweep_cancel_requested = False
    if hasattr(app, "qs_run_button"):
        app.qs_run_button.configure(state="disabled")
    if hasattr(app, "qs_cancel_button"):
        app.qs_cancel_button.configure(state="normal")
    app.quality_sweep_status_var.set("Running batches…")

    event_queue: queue.Queue = queue.Queue()
    app.quality_sweep_event_queue = event_queue

    def worker_thread_fn() -> None:
        try:
            def is_cancelled() -> bool:
                return getattr(app, "quality_sweep_cancel_requested", False)

            def progress_callback(batch: Any, manifest: Any) -> None:
                event_queue.put(("progress", batch, manifest))

            manifest = service.run_sweep(
                plan,
                batch_size=batch_size,
                inventory=app.quality_sweep_inventory,
                is_cancelled=is_cancelled,
                progress_callback=progress_callback,
            )
            event_queue.put(("done", manifest))
        except Exception as exc:
            event_queue.put(("error", str(exc)))

    thread = threading.Thread(target=worker_thread_fn, daemon=True)
    thread.start()

    def poll_sweep() -> None:
        while True:
            try:
                event = event_queue.get_nowait()
            except queue.Empty:
                break

            kind = event[0]
            if kind == "progress":
                batch, manifest = event[1], event[2]
                app.quality_sweep_manifest = manifest
                pct = (manifest.completed_cases / max(1, manifest.total_cases)) * 100.0
                app.quality_sweep_progress_var.set(pct)
                app.quality_sweep_status_var.set(
                    f"Batch {batch.batch_id} {batch.status} "
                    f"({manifest.completed_cases}/{manifest.total_cases} cases, "
                    f"{getattr(manifest, 'invalid_surface_cases', 0)} invalid)"
                )
                _refresh_batches_tree(app, manifest)
            elif kind == "done":
                manifest = event[1]
                app.quality_sweep_manifest = manifest
                app.quality_sweep_is_running = False
                if hasattr(app, "qs_run_button"):
                    app.qs_run_button.configure(state="normal")
                if hasattr(app, "qs_cancel_button"):
                    app.qs_cancel_button.configure(state="disabled")
                app.quality_sweep_status_var.set(
                    f"{manifest.status}: {manifest.completed_cases} completed "
                    f"({getattr(manifest, 'invalid_surface_cases', 0)} invalid, "
                    f"{manifest.failed_cases} failed)"
                )
                on_qs_refresh(app)
                return
            elif kind == "error":
                err = event[1]
                app.quality_sweep_is_running = False
                if hasattr(app, "qs_run_button"):
                    app.qs_run_button.configure(state="normal")
                if hasattr(app, "qs_cancel_button"):
                    app.qs_cancel_button.configure(state="disabled")
                app.quality_sweep_status_var.set(f"Run error: {err}")
                return

        if getattr(app, "quality_sweep_is_running", False):
            if hasattr(app, "root"):
                app.root.after(100, poll_sweep)

    if hasattr(app, "root"):
        app.root.after(100, poll_sweep)


def on_qs_cancel(app: Any) -> None:
    """Request non-blocking cancellation of running sweep."""
    app.quality_sweep_cancel_requested = True
    app.quality_sweep_status_var.set("Cancellation requested… waiting for batch boundary")
    if hasattr(app, "qs_cancel_button"):
        app.qs_cancel_button.configure(state="disabled")


def on_qs_refresh(app: Any) -> None:
    """Reload manifest, evidence rows, defect clusters, and reachability report from disk."""
    sweep_id = str(app.quality_sweep_id_var.get() or "dialogue_sweep_v1")
    service = DialogueQualitySweepService()

    try:
        # Load manifest
        try:
            manifest = service.load_manifest(sweep_id)
            app.quality_sweep_manifest = manifest
            _refresh_batches_tree(app, manifest)
        except Exception:
            pass

        # Load evidence rows
        rows = service.load_evidence_rows(sweep_id)
        app.quality_sweep_evidence_rows = rows

        # Load clusters
        if rows:
            report = service.generate_cluster_report(sweep_id)
            app.quality_sweep_cluster_report = report
            _populate_clusters_tree(app, report)
        else:
            if hasattr(app, "qs_cluster_tree"):
                for item in app.qs_cluster_tree.get_children():
                    app.qs_cluster_tree.delete(item)

        # Apply filters to evidence rows
        on_qs_apply_filter(app)

        # Refresh response pools reachability if requested or available
        on_qs_reachability_scan(app)

    except Exception as exc:
        app.quality_sweep_status_var.set(f"Refresh error: {exc}")


def on_qs_reachability_scan(app: Any) -> None:
    """Enumerate response pools and variants with multi-context reachability states."""
    active_worker = app.worker if getattr(app, "worker_ready", False) and getattr(app, "worker", None) else None
    sweep_id = str(app.quality_sweep_id_var.get() or "dialogue_sweep_v1")
    service = DialogueQualitySweepService()

    try:
        report = service.generate_reachability_report(sweep_id, worker=active_worker)
        app.quality_sweep_reachability_report = report
        _populate_pools_tree(app, report)
    except Exception as exc:
        app.quality_sweep_status_var.set(f"Reachability scan error: {exc}")


def on_qs_apply_filter(app: Any) -> None:
    """Filter evidence rows based on filter controls and refresh the treeview."""
    rows = app.quality_sweep_evidence_rows or []
    search_text = str(app.qs_filter_text_var.get() or "").lower().strip()
    sev_filter = str(app.qs_filter_severity_var.get() or "ALL").upper()
    flag_filter = str(app.qs_filter_flag_var.get() or "ALL")
    lang_filter = str(app.qs_filter_lang_var.get() or "ALL").upper()
    surface_filter = str(app.qs_filter_surface_var.get() or "ALL")
    invalid_only = bool(app.qs_filter_invalid_only_var.get())
    dup_only = bool(app.qs_filter_duplicate_only_var.get())

    filtered = []
    for r in rows:
        final_text = str(r.get("output", {}).get("finalText") or "")
        flags = r.get("quality", {}).get("flags", [])
        flag_names = [f.get("name") for f in flags]

        # Invalid surface filter
        if invalid_only and r.get("identity", {}).get("surfaceStatus") != "INVALID_SURFACE":
            continue

        # Duplicate filter
        if dup_only and "DUPLICATE_RENDERED_TEXT" not in flag_names and "FALLBACK_SATURATION" not in flag_names:
            continue

        # Severity filter
        if sev_filter != "ALL":
            if not any(f.get("severity") == sev_filter for f in flags):
                continue

        # Flag filter
        if flag_filter != "ALL":
            if flag_filter not in flag_names:
                continue

        # Language filter
        if lang_filter != "ALL":
            if str(r.get("identity", {}).get("language") or "").upper() != lang_filter:
                continue

        # Surface filter
        if surface_filter != "ALL":
            planned = str(r.get("identity", {}).get("plannedSurface") or "")
            reached = str(r.get("identity", {}).get("reachedSurface") or "")
            if surface_filter not in (planned, reached):
                continue

        # Search text
        if search_text:
            text_match = (
                search_text in final_text.lower()
                or search_text in str(r.get("identity", {}).get("caseID") or "").lower()
                or search_text in str(r.get("semanticPath", {}).get("semanticTemplateID") or "").lower()
                or search_text in str(r.get("semanticPath", {}).get("phraseID") or "").lower()
            )
            if not text_match:
                continue

        filtered.append(r)

    app.quality_sweep_filtered_rows = filtered
    app.qs_filter_count_var.set(f"Showing {len(filtered)} of {len(rows)} row(s)")
    _populate_evidence_tree(app, filtered)


def on_qs_clear_filter(app: Any) -> None:
    """Reset all filter controls."""
    app.qs_filter_text_var.set("")
    app.qs_filter_severity_var.set("ALL")
    app.qs_filter_flag_var.set("ALL")
    app.qs_filter_lang_var.set("ALL")
    app.qs_filter_surface_var.set("ALL")
    app.qs_filter_invalid_only_var.set(False)
    app.qs_filter_duplicate_only_var.set(False)
    on_qs_apply_filter(app)


def on_qs_evidence_select(app: Any) -> None:
    """Handle selection of an evidence row to populate the structured inspector."""
    if not hasattr(app, "qs_evidence_tree"):
        return
    sel = app.qs_evidence_tree.selection()
    if not sel:
        return
    row_id = sel[0]
    matched = next((r for r in app.quality_sweep_filtered_rows if r.get("rowID") == row_id), None)
    if not matched:
        return
    app.selected_quality_sweep_row = matched
    _populate_evidence_inspector(app, matched)


def on_qs_cluster_select(app: Any) -> None:
    """Handle selection of a cluster to show examples and details."""
    if not hasattr(app, "qs_cluster_tree") or not app.quality_sweep_cluster_report:
        return
    sel = app.qs_cluster_tree.selection()
    if not sel:
        return
    cid = sel[0]
    cluster = next((c for c in app.quality_sweep_cluster_report.clusters if c.cluster_id == cid), None)
    if not cluster:
        return
    app.selected_quality_sweep_cluster = cluster

    lines = [
        f"Cluster ID: {cluster.cluster_id}",
        f"Primary Flag: {cluster.primary_flag} (Severity: {cluster.severity}, Confidence: {cluster.confidence})",
        f"Count: {cluster.count} defect instances across {len(cluster.affected_case_ids)} cases",
        f"Canonical Source: {cluster.canonical_source_owner}",
        f"Response Pool: {cluster.pool_id or '(none)'} · Phrase: {cluster.phrase_id or '(none)'}",
        f"Suggested Remedy: {cluster.suggested_remedy}",
        "",
        "--- Affected Context Ranges ---",
        json.dumps(cluster.affected_context_ranges, indent=2),
        "",
        "--- Representative Examples ---",
    ]
    for ex in cluster.representative_examples:
        lines.append(f"• Case {ex.get('caseID')}: \"{ex.get('finalText')}\" (Bond: {ex.get('bondKind')})")
        if ex.get("flagDetail"):
            lines.append(f"  Detail: {ex.get('flagDetail')}")

    if hasattr(app, "qs_cluster_details_text"):
        app.qs_cluster_details_text.configure(state="normal")
        app.qs_cluster_details_text.delete("1.0", "end")
        app.qs_cluster_details_text.insert("end", "\n".join(lines))
        app.qs_cluster_details_text.configure(state="disabled")


def on_qs_open_full_inspector(app: Any) -> None:
    """Resolve lazy trace handle and show the full Conversation Inspector."""
    row = getattr(app, "selected_quality_sweep_row", None)
    if not row:
        if hasattr(app, "_messagebox"):
            app._messagebox.showinfo("Quality Sweep", "Please select an evidence row first.")
        return

    trace_handle = row.get("traceHandle")
    if not trace_handle:
        if hasattr(app, "_messagebox"):
            app._messagebox.showwarning("Quality Sweep", "Row does not contain a trace handle.")
        return

    service = DialogueQualitySweepService()
    active_worker = app.worker if getattr(app, "worker_ready", False) and getattr(app, "worker", None) else None
    turn_input = {
        "text": row.get("trigger", {}).get("parameters", {}).get("utterance") or "hello",
        "rootChoice": row.get("trigger", {}).get("parameters", {}).get("rootChoice"),
    }
    lang = str(row.get("identity", {}).get("language") or "EN")

    try:
        resolved = service.resolve_trace(
            trace_handle,
            worker=active_worker,
            turn_input_spec=turn_input,
            language=lang,
        )

        if resolved.get("stale"):
            msg = f"Trace is stale: {resolved.get('staleReason')}"
            if hasattr(app, "_messagebox"):
                app._messagebox.showwarning("Stale Trace", msg)
            return

        # Show full inspector in a modal dialog or update inspector view
        _show_inspector_dialog(app, row, resolved)
    except Exception as exc:
        if hasattr(app, "_messagebox"):
            app._messagebox.showerror("Inspector Error", f"Failed to resolve trace: {exc}")


def on_qs_replay_case(app: Any) -> None:
    """Replay single selected case."""
    row = getattr(app, "selected_quality_sweep_row", None)
    if not row:
        return
    case_id = row.get("identity", {}).get("caseID")
    if not case_id or not app.quality_sweep_plan:
        return

    service = DialogueQualitySweepService()
    replay_plan = service.plan_replay(app.quality_sweep_plan, [case_id])
    app.quality_sweep_plan = replay_plan
    on_qs_run(app)


def on_qs_replay_cluster(app: Any) -> None:
    """Replay all cases affected by selected cluster."""
    cluster = getattr(app, "selected_quality_sweep_cluster", None)
    if not cluster or not cluster.affected_case_ids:
        if hasattr(app, "_messagebox"):
            app._messagebox.showinfo("Quality Sweep", "Please select a cluster with affected cases.")
        return
    if not app.quality_sweep_plan:
        return

    service = DialogueQualitySweepService()
    replay_plan = service.plan_replay(app.quality_sweep_plan, cluster.affected_case_ids)
    app.quality_sweep_plan = replay_plan
    on_qs_run(app)


def on_qs_locate_source(app: Any) -> None:
    """Locate canonical source owner and file in Studio or display info."""
    row = getattr(app, "selected_quality_sweep_row", None)
    if not row:
        return
    sel_prov = row.get("selectionProvenance", {})
    owner = sel_prov.get("canonicalSourceOwner") or "UNKNOWN"
    phrase_id = row.get("semanticPath", {}).get("phraseID") or "(none)"

    msg = f"Canonical Source Owner: {owner}\nPhrase ID: {phrase_id}"
    if hasattr(app, "_messagebox"):
        app._messagebox.showinfo("Source Lineage", msg)


def on_qs_copy_evidence(app: Any) -> None:
    """Copy selected evidence row JSON to clipboard."""
    row = getattr(app, "selected_quality_sweep_row", None)
    if not row:
        return
    text = json.dumps(row, indent=2)
    if hasattr(app, "root"):
        app.root.clipboard_clear()
        app.root.clipboard_append(text)
    app.quality_sweep_status_var.set("Evidence JSON copied to clipboard")


def on_qs_export_bundle(app: Any) -> None:
    """Export compact LLM review bundle to disk."""
    sweep_id = str(app.quality_sweep_id_var.get() or "dialogue_sweep_v1")
    service = DialogueQualitySweepService()
    try:
        bundle = service.generate_review_bundle(sweep_id)
        out_path = service.base_dir / sweep_id / "review_bundle.json"
        out_path.parent.mkdir(parents=True, exist_ok=True)
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(bundle, f, indent=2)
        app.quality_sweep_status_var.set(f"Exported bundle to {out_path.name}")
        if hasattr(app, "_messagebox"):
            app._messagebox.showinfo("Review Bundle", f"Saved review bundle to:\n{out_path}")
    except Exception as exc:
        app.quality_sweep_status_var.set(f"Export error: {exc}")


# --- Helper rendering functions ---

def _populate_evidence_tree(app: Any, rows: Sequence[dict[str, Any]]) -> None:
    if not hasattr(app, "qs_evidence_tree"):
        return
    for item in app.qs_evidence_tree.get_children():
        app.qs_evidence_tree.delete(item)

    for r in rows:
        row_id = r.get("rowID") or ""
        output_text = str(r.get("output", {}).get("finalText") or "")
        flags = r.get("quality", {}).get("flags", [])
        primary_flag = flags[0].get("name") if flags else "CLEAN"
        severity = flags[0].get("severity") if flags else "CLEAN"

        planned_surf = str(r.get("identity", {}).get("plannedSurface") or "")
        reached_surf = str(r.get("identity", {}).get("reachedSurface") or "")
        lang = str(r.get("identity", {}).get("language") or "EN")
        template = str(r.get("semanticPath", {}).get("semanticTemplateID") or "")
        variant = str(r.get("semanticPath", {}).get("semanticVariantID") or "")
        case_id = str(r.get("identity", {}).get("caseID") or "")
        source = str(r.get("selectionProvenance", {}).get("canonicalSourceOwner") or "")

        app.qs_evidence_tree.insert(
            "",
            "end",
            iid=row_id,
            values=(
                severity,
                primary_flag,
                output_text,
                planned_surf,
                reached_surf,
                lang,
                template,
                variant,
                case_id,
                source,
            ),
        )


def _populate_clusters_tree(app: Any, report: Any) -> None:
    if not hasattr(app, "qs_cluster_tree"):
        return
    for item in app.qs_cluster_tree.get_children():
        app.qs_cluster_tree.delete(item)

    for c in report.clusters:
        app.qs_cluster_tree.insert(
            "",
            "end",
            iid=c.cluster_id,
            values=(
                c.severity,
                c.primary_flag,
                c.count,
                c.canonical_source_owner,
                c.phrase_id or "",
                c.cluster_id,
            ),
        )


def _populate_surfaces_tree(app: Any, plan: CoveragePlan) -> None:
    if not hasattr(app, "qs_surfaces_tree"):
        return
    for item in app.qs_surfaces_tree.get_children():
        app.qs_surfaces_tree.delete(item)

    for s in plan.planned_surfaces:
        app.qs_surfaces_tree.insert(
            "",
            "end",
            iid=s,
            values=(
                s,
                "production" if not s.startswith("utterance:") else "dialogue_utterance",
                "choice" if not s.startswith("utterance:") else "free_text",
                "True",
                plan.total_cases // max(1, len(plan.planned_surfaces)),
                "-",
                "READY",
                "-",
            ),
        )


def _populate_dimensions_tree(app: Any, inventory: SweepDimensionInventory | None) -> None:
    if not hasattr(app, "qs_dimensions_tree") or not inventory:
        return
    for item in app.qs_dimensions_tree.get_children():
        app.qs_dimensions_tree.delete(item)

    for d in inventory.dimensions.values():
        labels_preview = ", ".join(d.option_labels.values()) if d.option_labels else ", ".join(d.options[:4])
        app.qs_dimensions_tree.insert(
            "",
            "end",
            iid=d.id,
            values=(
                d.id,
                d.value_type,
                d.production_source,
                labels_preview,
                d.requires_override or "(none)",
                "True",
            ),
        )


def _populate_batches_tree_from_plan(app: Any, plan: CoveragePlan) -> None:
    if not hasattr(app, "qs_batches_tree"):
        return
    for item in app.qs_batches_tree.get_children():
        app.qs_batches_tree.delete(item)

    for i in range(plan.estimated_batches):
        bid = f"batch_{i+1:04d}"
        app.qs_batches_tree.insert(
            "",
            "end",
            iid=bid,
            values=(bid, "PLANNED", min(plan.batch_size, plan.total_cases - i * plan.batch_size), 0, 0, "-"),
        )


def _refresh_batches_tree(app: Any, manifest: Any) -> None:
    if not hasattr(app, "qs_batches_tree"):
        return
    for item in app.qs_batches_tree.get_children():
        app.qs_batches_tree.delete(item)

    for b in manifest.batches:
        app.qs_batches_tree.insert(
            "",
            "end",
            iid=b.batch_id,
            values=(
                b.batch_id,
                b.status,
                b.case_count,
                getattr(b, "invalid_surface_cases", 0),
                b.failed_cases,
                f"{b.duration:.2f}s" if b.duration else "-",
            ),
        )


def _populate_pools_tree(app: Any, report: ReachabilityReport) -> None:
    if not hasattr(app, "qs_pools_tree"):
        return
    for item in app.qs_pools_tree.get_children():
        app.qs_pools_tree.delete(item)

    for v in report.variants:
        app.qs_pools_tree.insert(
            "",
            "end",
            iid=f"{v.pool_id}:{v.variant_id}",
            values=(
                v.pool_id,
                v.variant_id,
                v.reachability_state,
                json.dumps(v.conditions) if v.conditions else "-",
                v.selected_count,
                v.canonical_source_owner,
            ),
        )


def _populate_evidence_inspector(app: Any, row: dict[str, Any]) -> None:
    if not hasattr(app, "qs_inspector_text"):
        return

    ident = row.get("identity", {})
    trig = row.get("trigger", {})
    actor = trig.get("actorConversationContext", {})
    rel = trig.get("relationshipSummary", {})
    sit = actor.get("situation", {})
    sem = row.get("semanticPath", {})
    real = row.get("output", {})
    sel = row.get("selectionProvenance", {})
    auth = row.get("authority", {})
    qual = row.get("quality", {})

    lines = [
        f"=== Evidence Row {row.get('rowID')} ===",
        f"Case ID: {ident.get('caseID')} · Surface: {ident.get('plannedSurface')} → {ident.get('reachedSurface')} ({ident.get('surfaceStatus')})",
        f"Final Text: \"{real.get('finalText')}\"",
        "",
        "--- Trigger Parameters ---",
        json.dumps(trig.get("parameters", {}), indent=2),
        "",
        "--- Persona & Relationship ---",
        f"Archetype: {actor.get('archetype')} · Traits: {actor.get('traits')}",
        f"Style: {actor.get('socialStyle')} · Personality: {actor.get('personality')}",
        f"Bond: {rel.get('bondKind')} (class: {rel.get('bondClass')})",
        f"Approval: {rel.get('approval')} · Respect: {rel.get('respect')} · Familiarity: {rel.get('familiarity')} · Trust: {rel.get('identityTrust')}",
        "",
        "--- Situation & Needs ---",
        f"Health: {sit.get('healthState')} · Activity: {sit.get('activity')} · Behavior: {sit.get('activeBehavior')}",
        f"Needs: {sit.get('needs')}",
        "",
        "--- Semantic Path & Realization ---",
        f"Template: {sem.get('semanticTemplateID')} · Variant: {sem.get('semanticVariantID')}",
        f"Phrase: {sem.get('phraseID')} · Speech Act: {sem.get('speechAct')} · Flow: {sem.get('flowState')}",
        f"Family: {real.get('realizationFamily')} · Variant: {real.get('realizationVariant')} · Language: {ident.get('language')}",
        "",
        "--- Selection Provenance ---",
        f"Canonical Source Owner: {sel.get('canonicalSourceOwner')}",
        f"Selected Variant: {sel.get('selectedVariantID')}",
        f"Fingerprint: {sel.get('catalogFingerprint')}",
        "",
        "--- Quality Flags ---",
        json.dumps(qual.get("flags", []), indent=2),
    ]

    app.qs_inspector_text.configure(state="normal")
    app.qs_inspector_text.delete("1.0", "end")
    app.qs_inspector_text.insert("end", "\n".join(lines))
    app.qs_inspector_text.configure(state="disabled")


def _show_inspector_dialog(app: Any, row: dict[str, Any], resolved: dict[str, Any]) -> None:
    """Open a modal dialog displaying resolved full Conversation Inspector details."""
    top = app._tk.Toplevel(app.root)
    top.title(f"Full Conversation Inspector · {row.get('identity', {}).get('caseID')}")
    top.geometry("800x600")

    text = app._ScrolledText(top, wrap="none")
    text.pack(fill="both", expand=True, padx=8, pady=8)
    text.insert("end", json.dumps(resolved, indent=2))
    text.configure(state="disabled")
