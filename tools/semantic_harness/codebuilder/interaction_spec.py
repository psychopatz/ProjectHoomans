"""Canonical typed InteractionSpec composition for Semantic Lab."""

from __future__ import annotations

import copy
import re
from typing import Any

from .compiler import CompileError, compile_semantic_definitions


SCHEMA = "semantic.interaction_spec.v1"
BLOCK_TYPES = frozenset({
    "language.trigger",
    "gameplay_actions.capability",
    "dialogue_responses.response_pool",
})
CONNECTION_TYPES = frozenset({"semantic", "capability", "response"})


def _text(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise CompileError(f"{label} must be a non-empty string")
    return value.strip()


def _parameters(block: dict[str, Any]) -> dict[str, Any]:
    parameters = block.get("parameters", {})
    if not isinstance(parameters, dict):
        raise CompileError(f"block {block.get('id', '<missing>')} parameters must be an object")
    return parameters


def _known_capabilities(production_catalog: dict[str, Any] | None) -> set[str]:
    catalog = production_catalog if isinstance(production_catalog, dict) else {}
    known: set[str] = set()
    for action in catalog.get("actionCatalog", []):
        if isinstance(action, dict):
            for key in ("id", "capabilityID", "bindingID"):
                value = action.get(key)
                if isinstance(value, str) and value:
                    known.add(value)
    return known


def validate_interaction_spec(
    spec: dict[str, Any],
    *,
    production_catalog: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Validate configured typed instances and connections without effects."""

    diagnostics: list[dict[str, str]] = []
    if not isinstance(spec, dict) or spec.get("schema") != SCHEMA:
        diagnostics.append({"severity": "error", "message": f"spec requires schema {SCHEMA}"})
        return {"ok": False, "valid": False, "schema": SCHEMA, "diagnostics": diagnostics}

    spec_id = spec.get("id")
    if not isinstance(spec_id, str) or not spec_id.startswith("pnc."):
        diagnostics.append({"severity": "error", "message": "spec id must use the pnc.* namespace"})
    blocks = spec.get("blocks")
    if not isinstance(blocks, list) or not blocks or len(blocks) > 16:
        diagnostics.append({"severity": "error", "message": "spec requires 1..16 typed block instances"})
        blocks = []

    block_map: dict[str, dict[str, Any]] = {}
    for block in blocks:
        if not isinstance(block, dict):
            diagnostics.append({"severity": "error", "message": "block instances must be objects"})
            continue
        block_id = block.get("id")
        block_type = block.get("type")
        if not isinstance(block_id, str) or not block_id:
            diagnostics.append({"severity": "error", "message": "block instance requires id"})
            continue
        if block_id in block_map:
            diagnostics.append({"severity": "error", "blockID": block_id, "message": "duplicate block instance"})
            continue
        if block_type not in BLOCK_TYPES:
            diagnostics.append({"severity": "error", "blockID": block_id, "message": f"unsupported block type: {block_type}"})
            continue
        block_map[block_id] = block
        parameters = _parameters(block)
        if block_type == "language.trigger":
            try:
                _text(parameters.get("utterance"), f"trigger {block_id} utterance")
                frame = parameters.get("frame")
                if not isinstance(frame, dict) or not frame.get("intent") or not frame.get("speechAct"):
                    raise CompileError(f"trigger {block_id} requires an intent and speechAct frame")
                _text(parameters.get("negativeUtterance"), f"trigger {block_id} negativeUtterance")
            except CompileError as error:
                diagnostics.append({"severity": "error", "blockID": block_id, "message": str(error)})
        elif block_type == "gameplay_actions.capability":
            capability_id = parameters.get("capabilityID")
            action = parameters.get("action")
            if not isinstance(capability_id, str) or not capability_id:
                diagnostics.append({"severity": "error", "blockID": block_id, "message": "capability block requires capabilityID"})
            if not isinstance(action, str) or not action:
                diagnostics.append({"severity": "error", "blockID": block_id, "message": "capability block requires action"})
            known = _known_capabilities(production_catalog)
            if known and capability_id not in known:
                diagnostics.append({"severity": "error", "blockID": block_id, "message": f"capability is not registered: {capability_id}"})
        elif block_type == "dialogue_responses.response_pool":
            try:
                _text(parameters.get("poolID"), f"response {block_id} poolID")
                variants = parameters.get("variants")
                if not isinstance(variants, list) or not variants:
                    raise CompileError(f"response {block_id} requires variants")
                for variant in variants:
                    if not isinstance(variant, dict):
                        raise CompileError(f"response {block_id} variants must be objects")
                    for key in ("id", "key", "en", "tl"):
                        _text(variant.get(key), f"response {block_id} variant {key}")
            except CompileError as error:
                diagnostics.append({"severity": "error", "blockID": block_id, "message": str(error)})

    typed = {block_type: 0 for block_type in BLOCK_TYPES}
    for block in block_map.values():
        typed[block["type"]] += 1
    required = {
        "language.trigger": "a trigger block",
        "gameplay_actions.capability": "a capability block",
        "dialogue_responses.response_pool": "a response-pool block",
    }
    for block_type, label in required.items():
        if typed[block_type] != 1:
            diagnostics.append({"severity": "error", "message": f"spec requires exactly one {label}"})

    connections = spec.get("connections")
    if not isinstance(connections, list):
        diagnostics.append({"severity": "error", "message": "spec connections must be a list"})
        connections = []
    seen_connections: set[tuple[str, str, str]] = set()
    for connection in connections:
        if not isinstance(connection, dict):
            diagnostics.append({"severity": "error", "message": "connections must be objects"})
            continue
        source = connection.get("from")
        target = connection.get("to")
        connection_type = connection.get("type")
        key = (str(source), str(target), str(connection_type))
        if key in seen_connections:
            diagnostics.append({"severity": "error", "message": "duplicate typed connection"})
        seen_connections.add(key)
        if source not in block_map or target not in block_map:
            diagnostics.append({"severity": "error", "message": f"connection references unknown block: {source} -> {target}"})
        if connection_type not in CONNECTION_TYPES:
            diagnostics.append({"severity": "error", "message": f"unsupported connection type: {connection_type}"})
        if source in block_map and target in block_map:
            expected_type = {
                ("language.trigger", "gameplay_actions.capability"): "semantic",
                ("gameplay_actions.capability", "dialogue_responses.response_pool"): "response",
            }.get((block_map[source]["type"], block_map[target]["type"]))
            if expected_type and connection_type != expected_type:
                diagnostics.append({
                    "severity": "error",
                    "message": f"typed connection requires {expected_type}: {source} -> {target}",
                })

    return {
        "ok": not diagnostics,
        "valid": not diagnostics,
        "schema": SCHEMA,
        "specID": spec_id,
        "blockIDs": sorted(block_map),
        "typedCounts": typed,
        "connectionCount": len(connections),
        "diagnostics": diagnostics,
        "previewOnly": True,
        "effectFree": True,
        "writes": [],
    }


def compile_interaction_spec(
    spec: dict[str, Any],
    base_document: dict[str, Any],
    *,
    production_catalog: dict[str, Any] | None = None,
    registered_capability_ids: set[str] | frozenset[str] | None = None,
) -> dict[str, Any]:
    """Compile one typed spec through the existing semantic CodeBuilder."""

    validation = validate_interaction_spec(spec, production_catalog=production_catalog)
    if not validation["valid"]:
        return {**validation, "compiled": None, "sourceDocument": None}
    trigger = next(block for block in spec["blocks"] if block["type"] == "language.trigger")
    capability = next(block for block in spec["blocks"] if block["type"] == "gameplay_actions.capability")
    response = next(block for block in spec["blocks"] if block["type"] == "dialogue_responses.response_pool")
    trigger_parameters = _parameters(trigger)
    capability_parameters = _parameters(capability)
    response_parameters = _parameters(response)
    definition_id = _text(spec["id"], "spec id")
    utterance = _text(trigger_parameters["utterance"], "utterance")
    slug = re.sub(r"[^a-z0-9]+", "_", utterance.lower()).strip("_") or "utterance"
    pattern_id = f"{definition_id}.{slug}"
    pool_id = _text(response_parameters["poolID"], "response poolID")
    action = _text(capability_parameters["action"], "capability action")
    frame = copy.deepcopy(trigger_parameters["frame"])
    frame["action"] = action
    definition = {
        "id": definition_id,
        "owner": spec.get("owner", "SemanticLab"),
        "capability": _text(capability_parameters["capabilityID"], "capabilityID"),
        "utterances": {
            "positives": [utterance],
            "negatives": [_text(trigger_parameters["negativeUtterance"], "negativeUtterance")],
        },
        "emit": frame,
        "confidence": spec.get("confidence", 0.99),
        "priority": spec.get("priority", 170),
        "flow": {
            "id": f"{definition_id}.flow",
            "version": 1,
            "owner": spec.get("owner", "SemanticLab"),
            "triggers": [{**copy.deepcopy(frame), "pattern": pattern_id}],
            "initial": "accepted",
            "nodes": {
                "accepted": {"terminal": True, "responsePool": pool_id},
            },
        },
        "responses": {
            "poolID": pool_id,
            "variants": copy.deepcopy(response_parameters["variants"]),
        },
    }
    source_document = copy.deepcopy(base_document)
    definitions = source_document.setdefault("definitions", [])
    definitions = [item for item in definitions if item.get("id") != definition_id]
    definitions.append(definition)
    source_document["definitions"] = definitions
    try:
        compiled = compile_semantic_definitions(
            source_document,
            registered_capability_ids=registered_capability_ids,
        )
    except CompileError as error:
        return {
            **validation,
            "valid": False,
            "ok": False,
            "compiled": None,
            "sourceDocument": source_document,
            "diagnostics": [{"severity": "error", "message": str(error)}],
        }
    return {
        **validation,
        "ok": True,
        "valid": True,
        "compiled": compiled,
        "sourceDocument": source_document,
        "definitionID": definition_id,
        "patternID": pattern_id,
        "flowID": f"{definition_id}.flow",
        "responsePoolID": pool_id,
        "writes": [],
    }
