"""Persist non-scenario UI selections and geometry."""

from __future__ import annotations

from typing import Any

from .state import save as persist_ui_state


def save_ui_state(app: Any) -> None:
    try:
        state = dict(app._ui_state)
        state["geometry"] = app.root.geometry()
        state["window_state"] = app.root.state()
        state["main_tab"] = app.main_tabs.index(app.main_tabs.select())
        state["studio_tab"] = app.studio_notebook.index(
            app.studio_notebook.select()
        )
        state["trace_tab"] = app.trace_tabs.index(app.trace_tabs.select())
        state["trace_panel_visible"] = app.trace_panel_visible
        state["advanced_controls_visible"] = app.advanced_controls_visible
        state["workbench_expanded"] = app.workbench_expanded
        selected_talk = app.talk_target_ids_by_label.get(
            app.talk_target_var.get(), "current"
        )
        state["talk_target"] = selected_talk
        state["talk_utterance"] = app.talk_utterance_var.get()
        selected_save = app._selected_saved_world_entry()
        if isinstance(selected_save, dict):
            state["saved_world_save_path"] = str(
                selected_save.get("path") or ""
            )
        selected_player = (
            getattr(app, "saved_world_player_labels", {}).get(
                app.saved_world_player_var.get(), {}
            )
            if hasattr(app, "saved_world_player_var")
            else {}
        )
        state["saved_world_player_id"] = str(
            selected_player.get("uuid")
            or selected_player.get("id")
            or ""
        )
        state["saved_world_npc_id"] = str(
            app.saved_world_npc_var.get()
            if hasattr(app, "saved_world_npc_var")
            else ""
        )
        state["saved_world_view"] = str(
            app.saved_world_view_var.get()
            if hasattr(app, "saved_world_view_var")
            else "Relationship to Player"
        )
        state["saved_world_lens_revision"] = 2
        state["saved_world_search"] = str(
            app.saved_world_search_var.get()
            if hasattr(app, "saved_world_search_var")
            else ""
        )
        state["saved_world_open_groups"] = [
            str(group.get("id") or "")
            for item, group in app.saved_world_tree_group_nodes.items()
            if hasattr(app, "saved_world_tree")
            and app.saved_world_tree.item(item, "open")
            and isinstance(group, dict)
            and group.get("id")
        ] if hasattr(app, "saved_world_tree") else []
        if hasattr(app, "saved_world_tree"):
            root_iid = getattr(
                app, "saved_world_tree_root_iid", "world-root"
            )
            state["saved_world_root_open"] = bool(
                app.saved_world_tree.exists(root_iid)
                and app.saved_world_tree.item(root_iid, "open")
            )
        if app.trace_panel_visible and app.simulation_panes.winfo_width() > 10:
            state["simulation_sash"] = app.simulation_panes.sashpos(0)
        if app.workflow_pane_split.winfo_height() > 10:
            state["workflow_sash"] = app.workflow_pane_split.sashpos(0)
        if app.workbench_notebook.tabs():
            state["workbench_panel"] = app.workbench_notebook.index(
                app.workbench_notebook.select()
            )
        state["workbench_tabs"] = {
            panel_name: notebook.index(notebook.select())
            for panel_name, notebook in app.workbench_panel_notebooks.items()
            if notebook.tabs()
        }
        app._ui_state.update(state)
        persist_ui_state(app.ui_state_path, state)
    except (OSError, app._tk.TclError, TypeError, ValueError):
        app.activity_log.record(
            "ui", "state_save_error", message="could not save window state"
        )
