"""Apply worker capabilities to the GUI after startup."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from ..inspection.rendering import pretty
from ..runtime.worker_session import WorkerReady


def worker_ready(app: Any, result: WorkerReady) -> None:
    app._worker_initialized = True
    app._workbench_initializing = True
    app.persona_catalog = result.capabilities.get("personaCatalog") or {}
    app.simulation_control_catalog = (
        result.capabilities.get("simulationControlCatalog") or {}
    )
    app.talk_catalog = result.capabilities.get("talkCatalog") or {}
    app._set_talk_catalog()
    app._update_simulation_projection(result.capabilities)
    app._build_simulation_workbench()
    app._set_status(f"Ready · Lua PID {result.status.get('pid')}")
    app._set_controls(True)
    app.root.update_idletasks()
    app._restore_splitters()
    app._clear_workbench_pending()
    app._workbench_initializing = False
    app._append("SYSTEM", "Lua worker ready. Production semantic modules are loaded.")
    if not app.save_backed_mode and app._initial_saved_pair_requested():
        app._append(
            "SYSTEM",
            "Explicit saved pair requested. Loading the read-only source save…",
        )
    elif not app.save_backed_mode:
        app._append(
            "SYSTEM",
            "Fixture mode is active. Load a saved Player/NPC pair from "
            "Load saved NPC to exercise production rehydration.",
        )
    initial_suggestions = result.capabilities.get("suggestions") or {}
    if initial_suggestions:
        app._render_suggestions(
            {
                "type": "turn",
                "accepted": True,
                "conversationPresentation": result.capabilities.get(
                    "conversationPresentation"
                ),
            },
            initial_suggestions,
        )
    capabilities = result.capabilities or {}
    flow_catalog = capabilities.get("flowCatalog", {})
    app._set_text(
        app.inspector,
        pretty(
            {
                "state": "ready",
                "worker": result.status,
                "flows": flow_catalog.get("flowCount", 0),
                "engineFacts": len(flow_catalog.get("factCatalog", [])),
                "engineEvents": len(flow_catalog.get("eventCatalog", [])),
                "commands": len(flow_catalog.get("commandCatalog", [])),
                "hint": "Use Studio → Advanced → Flow editor to build and validate production branches.",
            }
        ),
    )
    app._set_text(app.trace, pretty(capabilities))
    app.flow_editor.set_catalog(flow_catalog)
    app.interaction_explorer.set_catalog(flow_catalog)
    app.interaction_composer.set_production_catalog(flow_catalog)
    app.block_registry.set_catalog(flow_catalog)
    app._production_catalog = flow_catalog
    app.workflow_pane.set_production_catalog(flow_catalog)
    if app._initial_saved_pair_requested():
        app.root.after_idle(app._load_initial_saved_pair)


def set_talk_catalog(app: Any) -> None:
    """Populate the Talk parity selector from the production catalog."""

    rows = app.talk_catalog.get("targets", [])
    if not isinstance(rows, list):
        rows = []
    labels: list[str] = []
    app.talk_target_ids_by_label = {}
    for row in rows:
        if not isinstance(row, dict):
            continue
        target_id = str(row.get("id") or "")
        label = str(row.get("label") or target_id)
        if not target_id or label in app.talk_target_ids_by_label:
            continue
        labels.append(label)
        app.talk_target_ids_by_label[label] = target_id
    if not labels:
        labels = ["Current target"]
        app.talk_target_ids_by_label[labels[0]] = "current"
    app.talk_target_box.configure(values=tuple(labels))
    wanted = str(app._ui_state.get("talk_target") or "current")
    selected = next(
        (
            label
            for label, target_id in app.talk_target_ids_by_label.items()
            if target_id == wanted
        ),
        labels[0],
    )
    app.talk_target_var.set(selected)


def initial_saved_pair_requested(app: Any) -> bool:
    return bool(
        getattr(app.arguments, "gui", False)
        and app.arguments.save
        and app.arguments.player
        and app.arguments.npc
    )


def load_initial_saved_pair(app: Any) -> None:
    """Load an explicit GUI ``--save --player --npc`` pair."""

    if not app._initial_saved_pair_requested() or not app.worker_ready:
        return
    save_path = Path(str(app.arguments.save)).expanduser().resolve()
    if save_path.is_dir():
        save_path = save_path / "global_mod_data.bin"
    player_uuid = str(app.arguments.player)
    npc_id = str(app.arguments.npc)
    app.saved_world_target_var.set(
        f"Loading saved Player {player_uuid} → NPC {npc_id}"
    )

    def finish(result: dict[str, Any]) -> None:
        scenario = result.get("scenario") if isinstance(result, dict) else None
        if isinstance(scenario, dict):
            app.scenario = scenario
            app._sync_workbench_from_scenario(scenario)
        app._update_simulation_projection(result)
        app._set_save_backed_mode(True)
        app._refresh_npc_dossier_if_selected()
        player = app.scenario.get("player", {})
        npc = app.scenario.get("npc", {})
        player_label = (
            str(
                player.get("displayName")
                or player.get("characterUUID")
                or player_uuid
            )
            if isinstance(player, dict)
            else player_uuid
        )
        npc_label = (
            str(npc.get("displayName") or npc.get("npcID") or npc_id)
            if isinstance(npc, dict)
            else npc_id
        )
        app.saved_world_target_var.set(
            f"Loaded Player {player_label} → NPC {npc_label}"
        )
        source = (result.get("sourceSnapshot") or {}).get("metadata", {})
        app.saved_world_status_var.set(
            "Imported saved target: "
            f"{player_label} → {npc_label} · "
            f"source {source.get('sourceKind', 'SAVE')}"
        )
        app._set_text(app.trace, pretty(result))
        app._append(
            "SYSTEM",
            f"Imported saved target {npc_label} from read-only source save.",
        )
        app.main_tabs.select(app.simulation_tab)

    app._start_operation(
        lambda worker: worker.import_saved_selection(
            save_path,
            player_uuid=player_uuid,
            npc_id=npc_id,
        ),
        finish,
    )
