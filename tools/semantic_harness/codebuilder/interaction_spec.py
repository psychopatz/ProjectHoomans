"""Canonical typed InteractionSpec composition for Semantic Lab."""

from __future__ import annotations

import copy
import re
from typing import Any

from .compiler import (
    CompileError,
    DIALOGUE_BACKSTORY_KINDS,
    DIALOGUE_ID,
    compile_dialogue_dataset,
    compile_semantic_definitions,
)


SCHEMA = "semantic.interaction_spec.v1"
COLLECTION_SCHEMA = "semantic.interaction_collection.v1"
BLOCK_TYPES = frozenset({
    "language.trigger",
    "language.backstory_subject",
    "gameplay_actions.capability",
    "dialogue_responses.response_pool",
    "world_facts.engine_fact",
    "conditions.gate",
    "context.conversation_state",
    "memory.knowledge",
    "memory.backstory_fact",
})
CONNECTION_TYPES = frozenset({
    "semantic", "capability", "response", "fact", "gate", "context", "knowledge",
})
BACKSTORY_DISCLOSURES = frozenset({
    "server_authorized", "confirmed", "suspected", "refused",
})


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


def _known_facts(production_catalog: dict[str, Any] | None) -> set[str]:
    catalog = production_catalog if isinstance(production_catalog, dict) else {}
    return {
        str(fact["id"])
        for fact in catalog.get("factCatalog", [])
        if isinstance(fact, dict) and fact.get("id")
    }


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
        elif block_type == "language.backstory_subject":
            kind = parameters.get("backstoryKind")
            if kind not in DIALOGUE_BACKSTORY_KINDS:
                diagnostics.append({
                    "severity": "error", "blockID": block_id,
                    "message": "backstory subject requires a registered backstoryKind",
                })
            if parameters.get("factProvider") != "npc_backstory":
                diagnostics.append({
                    "severity": "error", "blockID": block_id,
                    "message": "backstory subject requires factProvider npc_backstory",
                })
            if parameters.get("topicID") != f"backstory.{kind}":
                diagnostics.append({
                    "severity": "error", "blockID": block_id,
                    "message": "backstory subject topicID must match backstoryKind",
                })
            if parameters.get("disclosure") not in BACKSTORY_DISCLOSURES:
                diagnostics.append({
                    "severity": "error", "blockID": block_id,
                    "message": "backstory subject requires a supported disclosure state",
                })
            follow_up = parameters.get("dialogueFollowUp")
            if follow_up is not None and follow_up != "CONTEXT_REFERENCE":
                diagnostics.append({
                    "severity": "error", "blockID": block_id,
                    "message": "backstory subject has an unsupported follow-up contract",
                })
        elif block_type == "memory.backstory_fact":
            if parameters.get("providerID") != "npc_backstory":
                diagnostics.append({
                    "severity": "error", "blockID": block_id,
                    "message": "backstory fact requires providerID npc_backstory",
                })
            if parameters.get("subject") != "NPC_BACKSTORY":
                diagnostics.append({
                    "severity": "error", "blockID": block_id,
                    "message": "backstory fact requires subject NPC_BACKSTORY",
                })
            if parameters.get("authority") not in {"server", "server_authorized"}:
                diagnostics.append({
                    "severity": "error", "blockID": block_id,
                    "message": "backstory fact requires server authority",
                })
            if parameters.get("immutable") is not True:
                diagnostics.append({
                    "severity": "error", "blockID": block_id,
                    "message": "backstory fact must be immutable",
                })
            if parameters.get("privacy") != "private":
                diagnostics.append({
                    "severity": "error", "blockID": block_id,
                    "message": "backstory fact must use private privacy",
                })
        elif block_type in {"context.conversation_state", "memory.knowledge"}:
            # These are explicit, reusable edges when an authored interaction
            # opts into follow-up or dossier context.  The production runtime
            # owns their contents; the spec only records their presence.
            pass
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
        elif block_type == "world_facts.engine_fact":
            fact_id = parameters.get("factID")
            if not isinstance(fact_id, str) or not fact_id:
                diagnostics.append({"severity": "error", "blockID": block_id, "message": "engine-fact block requires factID"})
            known_facts = _known_facts(production_catalog)
            if known_facts and fact_id not in known_facts:
                diagnostics.append({"severity": "error", "blockID": block_id, "message": f"fact is not registered: {fact_id}"})
        elif block_type == "conditions.gate":
            fact_block_id = parameters.get("factBlockID")
            if not isinstance(fact_block_id, str) or not fact_block_id:
                diagnostics.append({"severity": "error", "blockID": block_id, "message": "gate requires factBlockID"})
            if parameters.get("type") not in {"pnc:fact", "pnc:relationship", "pnc:time", "pnc:weather"}:
                diagnostics.append({"severity": "error", "blockID": block_id, "message": "gate requires a supported production gate type"})
            if not isinstance(parameters.get("operator"), str) or not parameters.get("operator"):
                diagnostics.append({"severity": "error", "blockID": block_id, "message": "gate requires operator"})
            if "value" not in parameters:
                diagnostics.append({"severity": "error", "blockID": block_id, "message": "gate requires value"})
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
    if typed["language.trigger"] != 1:
        diagnostics.append({"severity": "error", "message": "spec requires exactly one a trigger block"})
    if typed["dialogue_responses.response_pool"] != 1:
        diagnostics.append({"severity": "error", "message": "spec requires exactly one a response-pool block"})
    has_backstory = typed["language.backstory_subject"] or typed["memory.backstory_fact"]
    has_action = typed["gameplay_actions.capability"]
    if has_backstory and has_action:
        diagnostics.append({
            "severity": "error",
            "message": "action and NPC backstory blocks cannot share one interaction spec",
        })
    elif has_backstory:
        if typed["language.backstory_subject"] != 1:
            diagnostics.append({"severity": "error", "message": "backstory spec requires exactly one backstory subject block"})
        if typed["memory.backstory_fact"] != 1:
            diagnostics.append({"severity": "error", "message": "backstory spec requires exactly one backstory fact block"})
    elif has_action:
        if has_action != 1:
            diagnostics.append({"severity": "error", "message": "spec requires exactly one capability block"})
    else:
        diagnostics.append({"severity": "error", "message": "spec requires a capability or NPC backstory block"})
    if typed["conditions.gate"] > 1 or typed["world_facts.engine_fact"] > 1:
        diagnostics.append({"severity": "error", "message": "spec supports at most one gate and one engine-fact block"})
    if typed["conditions.gate"] != typed["world_facts.engine_fact"]:
        diagnostics.append({"severity": "error", "message": "gate and engine-fact blocks must be provided together"})

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
                ("language.trigger", "language.backstory_subject"): "semantic",
                ("language.backstory_subject", "memory.backstory_fact"): "fact",
                ("memory.backstory_fact", "dialogue_responses.response_pool"): "response",
                ("language.backstory_subject", "context.conversation_state"): "context",
                ("language.backstory_subject", "memory.knowledge"): "knowledge",
                ("world_facts.engine_fact", "conditions.gate"): "fact",
                ("conditions.gate", "gameplay_actions.capability"): "gate",
            }.get((block_map[source]["type"], block_map[target]["type"]))
            if expected_type and connection_type != expected_type:
                diagnostics.append({
                    "severity": "error",
                    "message": f"typed connection requires {expected_type}: {source} -> {target}",
                })

    if has_backstory and all(
        typed[block_type] == 1
        for block_type in (
            "language.trigger", "language.backstory_subject",
            "memory.backstory_fact", "dialogue_responses.response_pool",
        )
    ):
        required_edges = {
            (next(block["id"] for block in blocks if block.get("type") == "language.trigger"),
             next(block["id"] for block in blocks if block.get("type") == "language.backstory_subject"),
             "semantic"),
            (next(block["id"] for block in blocks if block.get("type") == "language.backstory_subject"),
             next(block["id"] for block in blocks if block.get("type") == "memory.backstory_fact"),
             "fact"),
            (next(block["id"] for block in blocks if block.get("type") == "memory.backstory_fact"),
             next(block["id"] for block in blocks if block.get("type") == "dialogue_responses.response_pool"),
             "response"),
        }
        for edge in required_edges:
            if edge not in seen_connections:
                diagnostics.append({
                    "severity": "error",
                    "message": f"backstory composition is missing typed connection: {edge[0]} -> {edge[1]} ({edge[2]})",
                })
    elif not has_backstory and has_action and all(
        typed[block_type] == 1
        for block_type in (
            "language.trigger", "gameplay_actions.capability",
            "dialogue_responses.response_pool",
        )
    ):
        required_edges = {
            (next(block["id"] for block in blocks if block.get("type") == "language.trigger"),
             next(block["id"] for block in blocks if block.get("type") == "gameplay_actions.capability"),
             "semantic"),
            (next(block["id"] for block in blocks if block.get("type") == "gameplay_actions.capability"),
             next(block["id"] for block in blocks if block.get("type") == "dialogue_responses.response_pool"),
             "response"),
        }
        for edge in required_edges:
            if edge not in seen_connections:
                diagnostics.append({
                    "severity": "error",
                    "message": f"action composition is missing typed connection: {edge[0]} -> {edge[1]} ({edge[2]})",
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
    response = next(block for block in spec["blocks"] if block["type"] == "dialogue_responses.response_pool")
    backstory = next(
        (block for block in spec["blocks"] if block["type"] == "language.backstory_subject"),
        None,
    )
    backstory_fact = next(
        (block for block in spec["blocks"] if block["type"] == "memory.backstory_fact"),
        None,
    )
    if backstory is not None and backstory_fact is not None:
        return _compile_backstory_interaction(spec, base_document, trigger, backstory, backstory_fact, response)
    capability = next(block for block in spec["blocks"] if block["type"] == "gameplay_actions.capability")
    fact_block = next(
        (block for block in spec["blocks"] if block["type"] == "world_facts.engine_fact"),
        None,
    )
    gate_block = next(
        (block for block in spec["blocks"] if block["type"] == "conditions.gate"),
        None,
    )
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
    if fact_block is not None and gate_block is not None:
        fact_parameters = _parameters(fact_block)
        gate_parameters = _parameters(gate_block)
        definition["flow"]["nodes"]["accepted"]["gate"] = {
            "type": gate_parameters["type"],
            "fact": fact_parameters["factID"],
            "operator": gate_parameters["operator"],
            "value": copy.deepcopy(gate_parameters["value"]),
            "unknownPolicy": gate_parameters.get("unknownPolicy", "tri_state"),
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


def _compile_backstory_interaction(
    spec: dict[str, Any],
    base_document: dict[str, Any],
    trigger: dict[str, Any],
    subject: dict[str, Any],
    fact_block: dict[str, Any],
    response: dict[str, Any],
) -> dict[str, Any]:
    """Compile typed backstory blocks into the existing dialogue dataset."""

    trigger_parameters = _parameters(trigger)
    subject_parameters = _parameters(subject)
    fact_parameters = _parameters(fact_block)
    response_parameters = _parameters(response)
    definition_id = _text(spec["id"], "spec id")
    utterance = _text(trigger_parameters["utterance"], "utterance")
    slug = re.sub(r"[^a-z0-9]+", "_", utterance.lower()).strip("_") or "utterance"
    pattern_id = f"{definition_id}.{slug}"
    pool_id = _text(response_parameters["poolID"], "response poolID")
    kind = subject_parameters["backstoryKind"]
    frame = {
        "intent": "QUESTION",
        "speechAct": "QUESTION",
        "subject": "NPC_BACKSTORY",
        "slots": {"backstoryKind": kind},
        "extensions": {
            "disclosure": subject_parameters["disclosure"],
            "factProvider": fact_parameters["providerID"],
            "topicID": subject_parameters["topicID"],
            "responsePoolID": pool_id,
        },
    }
    follow_up = subject_parameters.get("dialogueFollowUp")
    if follow_up:
        frame["extensions"]["dialogueFollowUp"] = follow_up

    source_document = copy.deepcopy(base_document)

    variants: list[dict[str, Any]] = []
    for raw_variant in response_parameters["variants"]:
        variant_id = _text(raw_variant.get("id"), "response variant id")
        safe_variant_id = re.sub(r"[^a-z0-9_.-]+", "_", variant_id.lower()).strip("_.-") or "response"
        canonical_variant_id = (
            safe_variant_id if safe_variant_id.startswith(pool_id + ".")
            else f"{pool_id}.{safe_variant_id}"
        )
        template_id = _text(
            raw_variant.get("key") or raw_variant.get("templateID"),
            "response variant key",
        )
        english = _text(raw_variant.get("en"), "response variant en")
        tagalog = _text(raw_variant.get("tl"), "response variant tl")
        translation_args = raw_variant.get("translationArgs")
        if translation_args is None:
            translation_args = {"content": "fact_content"}
        variants.append({
            "id": canonical_variant_id,
            "templateID": template_id,
            "fallback": english,
            "en": english,
            "tl": tagalog,
            "translationArgs": copy.deepcopy(translation_args),
        })

    source_name = str(
        ((source_document.get("source") or {}).get("references") or [{}])[0].get(
            "name", "Semantic Lab Authoring"
        )
    )
    pattern = {
        "id": pattern_id,
        "utterance": utterance,
        "emit": frame,
        "reviewed": True,
        "sourceRefs": [source_name],
        "confidence": spec.get("confidence", 0.99),
        "priority": spec.get("priority", 150),
        "mapping": {
            "canonicalConcept": "NPC_BACKSTORY",
            "dialogueState": "BACKSTORY_QUESTION",
            "sourceRefs": [source_name],
        },
        "negatives": [_text(trigger_parameters["negativeUtterance"], "negativeUtterance")],
    }
    patterns = [
        item for item in source_document.get("patterns", [])
        if isinstance(item, dict) and item.get("id") != pattern_id
    ]
    patterns.append(pattern)
    pools = [
        item for item in source_document.get("responsePools", [])
        if isinstance(item, dict) and item.get("id") != pool_id
    ]
    pools.append({"id": pool_id, "variants": variants})
    source_document["patterns"] = patterns
    source_document["responsePools"] = pools
    try:
        compiled = compile_dialogue_dataset(source_document)
    except CompileError as error:
        return {
            "ok": False,
            "valid": False,
            "compiled": None,
            "sourceDocument": source_document,
            "diagnostics": [{"severity": "error", "message": str(error)}],
            "writes": [],
        }
    return {
        "ok": True,
        "valid": True,
        "compiled": compiled,
        "sourceDocument": source_document,
        "definitionID": definition_id,
        "patternID": pattern_id,
        "responsePoolID": pool_id,
        "typedSubject": kind,
        "factProvider": fact_parameters["providerID"],
        "writes": [],
    }


def _materialize_shared_blocks(
    spec: dict[str, Any],
    shared_blocks: dict[str, dict[str, Any]],
) -> dict[str, Any]:
    materialized = copy.deepcopy(spec)
    blocks: list[dict[str, Any]] = []
    for block in materialized.get("blocks", []):
        if not isinstance(block, dict) or not block.get("use"):
            blocks.append(block)
            continue
        shared = shared_blocks.get(str(block["use"]))
        if not isinstance(shared, dict):
            blocks.append(block)
            continue
        resolved = copy.deepcopy(shared)
        resolved["id"] = block.get("id", resolved.get("id"))
        parameters = copy.deepcopy(resolved.get("parameters", {}))
        parameters.update(copy.deepcopy(block.get("parameters", {})))
        resolved["parameters"] = parameters
        blocks.append(resolved)
    materialized["blocks"] = blocks
    return materialized


def compile_interaction_collection(
    collection: dict[str, Any],
    base_document: dict[str, Any],
    *,
    production_catalog: dict[str, Any] | None = None,
    registered_capability_ids: set[str] | frozenset[str] | None = None,
) -> dict[str, Any]:
    """Compile multiple specs that may reuse canonical typed block instances."""

    diagnostics: list[dict[str, str]] = []
    if not isinstance(collection, dict) or collection.get("schema") != COLLECTION_SCHEMA:
        return {
            "ok": False,
            "valid": False,
            "schema": COLLECTION_SCHEMA,
            "diagnostics": [{"severity": "error", "message": f"collection requires schema {COLLECTION_SCHEMA}"}],
            "writes": [],
        }
    shared_blocks = {
        str(block.get("id")): block
        for block in collection.get("sharedBlocks", [])
        if isinstance(block, dict) and block.get("id")
    }
    interactions = collection.get("interactions")
    if not isinstance(interactions, list) or not interactions:
        return {
            "ok": False,
            "valid": False,
            "schema": COLLECTION_SCHEMA,
            "diagnostics": [{"severity": "error", "message": "collection requires interactions"}],
            "writes": [],
        }
    source_document = copy.deepcopy(base_document)
    reports: list[dict[str, Any]] = []
    compiled: dict[str, Any] | None = None
    for spec in interactions:
        if not isinstance(spec, dict):
            diagnostics.append({"severity": "error", "message": "collection interactions must be objects"})
            continue
        resolved = _materialize_shared_blocks(spec, shared_blocks)
        report = compile_interaction_spec(
            resolved,
            source_document,
            production_catalog=production_catalog,
            registered_capability_ids=registered_capability_ids,
        )
        reports.append(report)
        if report.get("ok") is not True:
            diagnostics.extend(report.get("diagnostics", []))
            continue
        source_document = report["sourceDocument"]
        compiled = report.get("compiled")
    return {
        "ok": not diagnostics and compiled is not None,
        "valid": not diagnostics and compiled is not None,
        "schema": COLLECTION_SCHEMA,
        "sharedBlockIDs": sorted(shared_blocks),
        "interactionReports": reports,
        "compiled": compiled,
        "sourceDocument": source_document if compiled is not None else None,
        "diagnostics": diagnostics,
        "previewOnly": True,
        "effectFree": True,
        "writes": [],
    }
