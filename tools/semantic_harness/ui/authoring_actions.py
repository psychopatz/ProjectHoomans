"""Coordinate Code Builder previews and approved artifact generation."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from ..inspection.rendering import pretty


def compile_semantic_source(app: Any, source_path: Path) -> None:
    """Preview canonical source offline; do not mutate the Lua worker."""

    report = app.authoring_service.preview_semantic_source(source_path)
    app.flow_editor.show_source_report(report)
    app._set_text(app.inspector, pretty(report))
    app._set_text(app.trace, pretty(report))
    if report.get("ok") is True:
        app._append(
            "SYSTEM",
            f"Compiler preview valid; no files written: {source_path.name}",
        )
    else:
        diagnostics = report.get("diagnostics") or []
        message = diagnostics[0].get("message") if diagnostics else "invalid source"
        app._append("SYSTEM", f"Compiler preview rejected: {message}")


def review_dialogue_source(app: Any, source_path: Path) -> None:
    """Review the canonical dialogue dataset through the existing Code Builder."""

    report = app.authoring_service.preview_dialogue_source(source_path)
    app.flow_editor.show_dataset_report(report)
    app._set_text(app.inspector, pretty(report))
    app._set_text(app.trace, pretty(report))
    review = report.get("candidateReview") or {}
    summary = review.get("summary") or {}
    collisions = review.get("collisions") or []
    artifact_diffs = report.get("artifactDiffs") or []
    changed = sum(
        1
        for row in artifact_diffs
        if isinstance(row, dict) and row.get("status") != "unchanged"
    )
    if report.get("ok") is True:
        app._append(
            "SYSTEM",
            f"Dataset review valid; {summary.get('approved', 0)} approved, "
            f"{summary.get('rejected', 0)} rejected, {len(collisions)} collisions, "
            f"{changed} artifact diffs; no files written.",
        )
    else:
        diagnostics = report.get("diagnostics") or []
        message = diagnostics[0].get("message") if diagnostics else "invalid dataset"
        app._append("SYSTEM", f"Dataset review rejected: {message}")


def generate_dialogue_source(app: Any, source_path: Path) -> None:
    """Write approved dialogue artifacts through the existing Code Builder writer."""

    report = app.authoring_service.generate_dialogue_source(source_path)
    app.flow_editor.show_dataset_report(report)
    app._set_text(app.inspector, pretty(report))
    app._set_text(app.trace, pretty(report))
    if report.get("ok") is not True:
        diagnostics = report.get("diagnostics") or []
        message = diagnostics[0].get("message") if diagnostics else "generation failed"
        app._append("SYSTEM", f"Dialogue generation rejected: {message}")
        return
    writes = report.get("writes") or []
    app._append(
        "SYSTEM",
        f"Generated {len(writes)} dialogue artifacts; restarting Lua worker.",
    )
    app.restart()


def generate_semantic_source(app: Any, source_path: Path) -> None:
    """Generate approved artifacts, then restart the existing worker."""

    report = app.authoring_service.generate_semantic_source(source_path)
    app.flow_editor.show_source_report(report)
    app._set_text(app.inspector, pretty(report))
    app._set_text(app.trace, pretty(report))
    if report.get("ok") is not True:
        diagnostics = report.get("diagnostics") or []
        message = diagnostics[0].get("message") if diagnostics else "generation failed"
        app._append("SYSTEM", f"Source generation rejected: {message}")
        return
    app._append(
        "SYSTEM",
        f"Generated {len(report.get('writes', []))} files; restarting Lua worker.",
    )
    app.restart()


def preview_interaction_spec(app: Any, spec: dict[str, Any]) -> dict[str, Any]:
    """Preview a configured Studio interaction through the embedded builder."""

    report = app.authoring_service.preview_interaction_spec(
        spec,
        production_catalog=app._production_catalog,
    )
    app._set_text(app.inspector, pretty(report))
    app._set_text(app.trace, pretty(report))
    return report


def generate_interaction_spec(app: Any, spec: dict[str, Any]) -> None:
    """Write an approved InteractionSpec, then restart the real Lua worker."""

    report = app.authoring_service.generate_interaction_spec(
        spec,
        approved=True,
        production_catalog=app._production_catalog,
    )
    app.interaction_composer.show_generation(report)
    app._set_text(app.inspector, pretty(report))
    app._set_text(app.trace, pretty(report))
    if report.get("ok") is not True:
        diagnostics = report.get("diagnostics") or []
        message = diagnostics[0].get("message") if diagnostics else "generation failed"
        app._append("SYSTEM", f"Interaction generation rejected: {message}")
        return
    app._append(
        "SYSTEM",
        f"Generated {len(report.get('writes', []))} interaction artifacts; restarting Lua worker.",
    )
    app.restart()


def generate_workflow(
    app: Any,
    source_id: str,
    block_ids: list[str],
    interaction_spec: dict[str, Any] | None = None,
) -> None:
    """Generate the approved in-app workflow through the shared service."""

    report = app.authoring_service.generate_workflow(
        source_id,
        block_ids,
        approved=True,
        production_catalog=app._production_catalog,
        interaction_spec=interaction_spec,
    )
    app.workflow_pane.show_generation(report)
    app._set_text(app.inspector, pretty(report))
    app._set_text(app.trace, pretty(report))
    if report.get("ok") is not True:
        diagnostics = report.get("diagnostics") or []
        message = diagnostics[0].get("message") if diagnostics else "workflow generation failed"
        app._append("SYSTEM", f"Workflow generation rejected: {message}")
        return
    app._append(
        "SYSTEM",
        f"Generated {len(report.get('writes', []))} artifacts; restarting Lua worker.",
    )
    app.restart()
