"""Pure graph-model and coverage projections used by the Flow Editor."""

from __future__ import annotations

import copy
import json
from typing import Any

from ...codebuilder.blocks import TRANSITION_FIELDS

def graph_transform(point: tuple[float, float], zoom: float, pan: tuple[float, float]) -> tuple[float, float]:
    """Transform model coordinates into canvas coordinates."""

    return point[0] * zoom + pan[0], point[1] * zoom + pan[1]


def graph_inverse(point: tuple[float, float], zoom: float, pan: tuple[float, float]) -> tuple[float, float]:
    """Transform canvas coordinates into model coordinates."""

    return (point[0] - pan[0]) / zoom, (point[1] - pan[1]) / zoom


def graph_render_mode(zoom: float) -> str:
    """Return the amount of detail that remains readable at ``zoom``."""

    if zoom < 0.55:
        return "overview"
    if zoom < 0.8:
        return "compact"
    return "detail"


def flow_draft(flow: dict[str, Any]) -> dict[str, Any]:
    """Return an editable copy of one normalized production flow."""

    return copy.deepcopy(flow)


def _title_identifier(value: str) -> str:
    """Turn a bounded registry identifier segment into a UI label."""

    words = str(value).replace("_", " ").replace("-", " ").split()
    return " ".join(word[:1].upper() + word[1:] for word in words)


def flow_display_name(
    flow_id: str,
    flow: dict[str, Any] | None = None,
) -> str:
    """Return a compact label while preserving the canonical flow ID."""

    flow_id = str(flow_id)
    flow = flow if isinstance(flow, dict) else {}
    workflow_kind = str(flow.get("workflowKind") or "")
    capability_id = str(flow.get("capabilityID") or "")
    generated = workflow_kind != "" or flow_id.startswith("pnc.generated.")
    if not generated:
        return flow_id

    if not capability_id:
        generated_parts = flow_id.split(".")
        if len(generated_parts) >= 4:
            capability_id = ".".join(generated_parts[3:])
            if capability_id.startswith("pnc."):
                capability_id = "pnc:" + capability_id[4:]
    if capability_id.startswith("pnc:"):
        capability_id = capability_id[4:]
    segments = [
        _title_identifier(segment)
        for segment in capability_id.split(".")
        if segment
    ]
    if segments:
        return " / ".join(segments)
    return flow_id


def flow_graph_model(flow: dict[str, Any]) -> dict[str, Any]:
    """Build deterministic nodes/edges for the visual graph and tests."""

    if not isinstance(flow, dict):
        raise ValueError("flow must be an object")
    nodes = flow.get("nodes")
    if not isinstance(nodes, dict) or not nodes:
        raise ValueError("flow.nodes must be a non-empty object")

    node_rows: list[dict[str, Any]] = []
    edges: list[dict[str, Any]] = []
    for node_id in sorted(nodes):
        node = nodes[node_id]
        if not isinstance(node, dict):
            raise ValueError(f"flow node {node_id!r} must be an object")
        transitions = {
            field: node[field]
            for field in TRANSITION_FIELDS
            if node.get(field) not in (None, "")
        }
        action = node.get("action") if isinstance(node.get("action"), dict) else {}
        raw_result_transitions = node.get("resultTransitions")
        if not isinstance(raw_result_transitions, dict):
            raw_result_transitions = action.get("resultTransitions", {})
        result_transitions = {
            str(outcome): target
            for outcome, target in raw_result_transitions.items()
            if target not in (None, "")
        }
        node_rows.append({
            "id": node_id,
            "terminal": node.get("terminal") is True,
            "action": copy.deepcopy(action) if action else None,
            "responsePool": node.get("responsePool"),
            "responseTemplate": node.get("responseTemplate"),
            "accepts": copy.deepcopy(node.get("accepts", [])),
            "branchOffers": copy.deepcopy(node.get("branchOffers", [])),
            "slots": copy.deepcopy(node.get("slots", {})),
            "gate": copy.deepcopy(node.get("gate")),
            "transitions": transitions,
            "resultTransitions": result_transitions,
        })
        for field, target in transitions.items():
            edges.append({
                "fromNodeID": node_id,
                "field": field,
                "toNodeID": target,
                "internal": target in nodes,
            })
        for outcome, target in result_transitions.items():
            edges.append({
                "fromNodeID": node_id,
                "field": f"result:{outcome}",
                "toNodeID": target,
                "internal": target in nodes,
            })

    return {
        "schemaVersion": 1,
        "flowID": flow.get("id"),
        "owner": flow.get("owner"),
        "version": flow.get("version"),
        "workflowKind": flow.get("workflowKind"),
        "capabilityID": flow.get("capabilityID"),
        "generated": flow.get("workflowKind") is not None,
        "initial": flow.get("initial"),
        "triggers": copy.deepcopy(flow.get("triggers", [])),
        "nodes": node_rows,
        "edges": edges,
    }


def coverage_summary(coverage: list[dict[str, Any]]) -> dict[str, int]:
    """Count live capability classifications shown by Semantic Lab."""

    summary: dict[str, int] = {}
    for row in coverage:
        if not isinstance(row, dict):
            continue
        classification = str(row.get("classification") or "unknown")
        summary[classification] = summary.get(classification, 0) + 1
    return summary


def coverage_lines(coverage: list[dict[str, Any]]) -> list[str]:
    """Render exact bounded coverage reasons for the visual coverage view."""

    lines: list[str] = []
    for row in sorted(
        (item for item in coverage if isinstance(item, dict)),
        key=lambda item: str(item.get("id") or ""),
    ):
        capability = str(row.get("id") or "<unknown>")
        classification = str(row.get("classification") or "unknown")
        reason = str(row.get("reason") or "unspecified")
        flow_id = row.get("flowID")
        suffix = f" -> {flow_id}" if flow_id else ""
        lines.append(f"{capability}: {classification} ({reason}){suffix}")
    return lines


def _json_text(value: Any) -> str:
    return json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True)
