"""Dispatch bounded worker actions from the GUI controls."""

from __future__ import annotations

from typing import Any

from ..inspection.rendering import pretty


def show_snapshot(app: Any) -> None:
    if not app.session.ready:
        return
    app._start_operation(lambda worker: worker.snapshot(), app._show_response)


def preview(app: Any) -> None:
    """Inspect a production decision without recording or dispatching it."""

    value = app.input_var.get().strip()
    if not value or not app.session.ready or app.busy:
        return

    def finish(response: dict[str, Any]) -> None:
        app._show_response(response)
        app._append("SYSTEM", f"Preview only; no state or action mutation: {value}")

    app._start_operation(lambda worker: worker.preview(value), finish)


def propose_relationship(app: Any) -> None:
    """Submit the one canonical relationship proposal action."""

    if not app.session.ready or app.busy:
        return

    def finish(response: dict[str, Any]) -> None:
        app._show_response(response)
        proposal = response.get("proposal") or {}
        if response.get("accepted") is True:
            message = "NPC accepted the relationship proposal."
        elif response.get("reason"):
            message = f"Relationship proposal: {response['reason']}"
        else:
            message = "NPC rejected the relationship proposal."
        app._append("SYSTEM", message)
        app.workbench_status_var.set(message)

    app._start_operation(lambda worker: worker.relationship_proposal(), finish)


def capture_baseline(app: Any) -> None:
    """Capture the current utterance through the production preview path."""

    value = app._comparison_utterance()
    if not value or not app.session.ready or app.busy:
        return

    def finish(result: dict[str, Any]) -> None:
        app.baseline_record = result
        app._show_response(result.get("preview") or {})
        app._set_text(app.compare_output, pretty(result))
        app._append("SYSTEM", f"Captured production baseline: {value}")

    app._start_operation(lambda worker: worker.capture_baseline(value), finish)


def reset_working_world(app: Any) -> None:
    """Restore the imported source baseline without rereading disk."""

    if app.closed or not app.session.ready or app.busy:
        return

    def finish(response: dict[str, Any]) -> None:
        scenario = response.get("scenario") if isinstance(response, dict) else None
        if isinstance(scenario, dict):
            app.scenario = scenario
            app._sync_workbench_from_scenario(scenario)
        app._update_simulation_projection(response)
        app._set_text(
            app.inventory_gift_workbench.result,
            "Working world reset to the already-imported baseline.\n"
            "Source save: UNCHANGED · no disk reread.",
        )
        app._append("SYSTEM", "Reset working world to imported source baseline.")

    app._start_operation(lambda worker: worker.reset_working_world(), finish)


def set_language(app: Any) -> None:
    if not app.session.ready or app.busy:
        return
    selected = app.language_var.get().strip().upper()

    def finish(response: dict[str, Any]) -> None:
        app.scenario.setdefault("runtime", {})["language"] = selected
        app._set_status(f"Ready · language {response.get('language', selected)}")
        app._show_response(response)
        app._append("SYSTEM", f"Production translation language set to {selected}.")

    app._start_operation(lambda worker: worker.set_language(selected), finish)


def restart(app: Any) -> None:
    if not app.session.ready or app.busy:
        return

    def finish(response: dict[str, Any]) -> None:
        app._show_response(response)
        app._append("SYSTEM", "Lua worker restarted and the scenario was restored.")

    app._start_operation(lambda worker: worker.restart(), finish)
