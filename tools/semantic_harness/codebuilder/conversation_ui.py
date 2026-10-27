"""Canonical declarative Conversation UI registry compiler.

The registry owns presentation structure only: landing choices, hubs,
membership, order, and references to wording and registered semantic
providers. It deliberately does not contain eligibility logic, gameplay
effects, or response meaning.
"""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path
from typing import Any

from .lexicon_compiler import CompileError, _lua_string
from .dialogue_content import _shard_path, load_dialogue_content_manifest


UI_REGISTRY_SCHEMA = "pnc.conversation_ui_registry.v1"
UI_REGISTRY_SOURCE_RELATIVE = Path(
    "tools/semantic_harness/codebuilder/sources/conversation/ui_registry.json"
)
UI_REGISTRY_RUNTIME_RELATIVE = Path(
    "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/"
    "Semantics/Generated/ConversationUI/Registry.lua"
)
UI_REGISTRY_MAX_NODES = 128
UI_REGISTRY_MAX_CHILDREN = 32
UI_ID_PATTERN = re.compile(r"^[a-z][a-z0-9_.:-]{0,127}$")


def _canonical_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def _read_json(path: Path, label: str) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise CompileError(f"cannot read {label} {path}: {error}") from error
    if not isinstance(value, dict):
        raise CompileError(f"{label} root must be an object: {path}")
    return value


def _text(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise CompileError(f"{label} must be a non-empty string")
    value = value.strip()
    if len(value) > 256:
        raise CompileError(f"{label} exceeds the 256-character limit")
    if any(ord(char) < 32 for char in value):
        raise CompileError(f"{label} contains a control character")
    return value


def _id(value: Any, label: str) -> str:
    value = _text(value, label)
    if not UI_ID_PATTERN.fullmatch(value):
        raise CompileError(f"{label} has an invalid bounded ID: {value!r}")
    return value


def conversation_ui_source_path_from_manifest(manifest_path: Path) -> Path:
    """Resolve the UI registry declared by the canonical content manifest."""

    manifest = load_dialogue_content_manifest(manifest_path)
    descriptor = manifest.get("conversationUI")
    if not isinstance(descriptor, dict):
        raise CompileError("conversation content manifest requires conversationUI")
    if descriptor.get("schema") != UI_REGISTRY_SCHEMA:
        raise CompileError("conversation content manifest conversationUI schema is invalid")
    return _shard_path(manifest_path, descriptor.get("path"))


def load_conversation_ui_source(path: Path) -> dict[str, Any]:
    """Load the bounded declarative UI registry source."""

    document = _read_json(path, "conversation UI registry")
    if document.get("schema") != UI_REGISTRY_SCHEMA:
        raise CompileError("conversation UI registry schema is invalid")
    if document.get("schemaVersion") != 1:
        raise CompileError("conversation UI registry schemaVersion must be 1")
    if not isinstance(document.get("source"), dict):
        raise CompileError("conversation UI registry requires source metadata")
    nodes = document.get("nodes")
    if not isinstance(nodes, list) or not nodes:
        raise CompileError("conversation UI registry requires nodes")
    return document


def conversation_ui_source_fingerprint(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _provider_reference(value: Any, label: str) -> dict[str, Any] | None:
    if value is None:
        return None
    if not isinstance(value, dict):
        raise CompileError(f"{label} must be an object")
    provider_id = _id(value.get("id"), f"{label}.id")
    if value.get("locked") is not True:
        raise CompileError(f"{label}.locked must be true")
    return {
        "id": provider_id,
        "ownership": _text(value.get("ownership"), f"{label}.ownership"),
        "source": _text(value.get("source"), f"{label}.source"),
        "locked": True,
    }


def _semantic_destination(value: Any, label: str) -> dict[str, Any] | None:
    if value is None:
        return None
    if not isinstance(value, dict):
        raise CompileError(f"{label} must be an object")
    output = {
        "candidateID": _id(value.get("candidateID"), f"{label}.candidateID"),
        "providerID": _id(value.get("providerID"), f"{label}.providerID"),
        "route": _text(value.get("route"), f"{label}.route"),
    }
    for key in ("topic", "hubID", "canonicalConcept"):
        if value.get(key) is not None:
            output[key] = _text(value[key], f"{label}.{key}")
    return output


def compile_conversation_ui(document: dict[str, Any]) -> dict[str, Any]:
    """Validate the registry and return a deterministic runtime projection."""

    if not isinstance(document, dict):
        raise CompileError("conversation UI registry root must be an object")
    if document.get("schema") != UI_REGISTRY_SCHEMA:
        raise CompileError("conversation UI registry schema is invalid")
    if document.get("schemaVersion") != 1:
        raise CompileError("conversation UI registry schemaVersion must be 1")
    source = document.get("source")
    if not isinstance(source, dict):
        raise CompileError("conversation UI registry requires source metadata")
    for key in ("name", "version", "owner"):
        _text(source.get(key), f"source.{key}")
    raw_nodes = document.get("nodes")
    if not isinstance(raw_nodes, list) or not raw_nodes:
        raise CompileError("conversation UI registry requires nodes")
    if len(raw_nodes) > UI_REGISTRY_MAX_NODES:
        raise CompileError(f"conversation UI registry exceeds {UI_REGISTRY_MAX_NODES} nodes")

    node_ids: set[str] = set()
    compiled_nodes: list[dict[str, Any]] = []
    for index, raw in enumerate(raw_nodes, 1):
        if not isinstance(raw, dict):
            raise CompileError(f"conversation UI node {index} must be an object")
        node_id = _id(raw.get("id"), f"conversation UI node {index}.id")
        if node_id in node_ids:
            raise CompileError(f"duplicate conversation UI node id: {node_id}")
        node_ids.add(node_id)
        kind = _text(raw.get("kind"), f"{node_id}.kind")
        if kind not in {"landing", "landing_choice", "hub", "choice"}:
            raise CompileError(f"{node_id}.kind is not a supported Conversation UI kind")
        parent_id = raw.get("parentID")
        if parent_id is not None:
            parent_id = _id(parent_id, f"{node_id}.parentID")
        order = raw.get("order")
        if isinstance(order, bool) or not isinstance(order, int):
            raise CompileError(f"{node_id}.order must be an integer")
        content_id = raw.get("contentID")
        if content_id is not None:
            content_id = _id(content_id, f"{node_id}.contentID")
        provider = _provider_reference(raw.get("providerRef"), f"{node_id}.providerRef")
        destination = _semantic_destination(
            raw.get("semanticDestination"), f"{node_id}.semanticDestination"
        )
        children = raw.get("children", [])
        if not isinstance(children, list) or len(children) > UI_REGISTRY_MAX_CHILDREN:
            raise CompileError(
                f"{node_id}.children must contain at most {UI_REGISTRY_MAX_CHILDREN} entries"
            )
        compiled_children: list[dict[str, Any]] = []
        child_ids: set[str] = set()
        for child_index, child in enumerate(children, 1):
            if not isinstance(child, dict):
                raise CompileError(f"{node_id}.children[{child_index}] must be an object")
            child_id = _id(child.get("nodeID"), f"{node_id}.children[{child_index}].nodeID")
            if child_id in child_ids:
                raise CompileError(f"{node_id} contains duplicate child {child_id}")
            child_ids.add(child_id)
            child_order = child.get("order")
            if isinstance(child_order, bool) or not isinstance(child_order, int):
                raise CompileError(f"{node_id}.children[{child_index}].order must be an integer")
            compiled_children.append({"nodeID": child_id, "order": child_order})
        compiled_children.sort(key=lambda child: (child["order"], child["nodeID"]))
        compiled_nodes.append({
            "id": node_id,
            "kind": kind,
            "parentID": parent_id,
            "order": order,
            "contentID": content_id,
            "providerRef": provider,
            "semanticDestination": destination,
            "children": compiled_children,
        })

    by_id = {node["id"]: node for node in compiled_nodes}
    root_nodes = 0
    for node in compiled_nodes:
        parent_id = node["parentID"]
        if parent_id is None:
            root_nodes += 1
        elif parent_id not in by_id:
            raise CompileError(f"{node['id']} references unknown parent {parent_id}")
        for child in node["children"]:
            child_node = by_id.get(child["nodeID"])
            if child_node is None:
                raise CompileError(
                    f"{node['id']} references unknown child {child['nodeID']}"
                )
            if child_node["parentID"] != node["id"]:
                raise CompileError(
                    f"{child['nodeID']} parentID does not match {node['id']}"
                )
    if root_nodes == 0:
        raise CompileError("conversation UI registry requires a root node")

    compiled_nodes.sort(key=lambda node: (node["order"], node["id"]))
    return {
        "schema": UI_REGISTRY_SCHEMA,
        "schemaVersion": 1,
        "source": {
            "name": _text(source.get("name"), "source.name"),
            "version": _text(source.get("version"), "source.version"),
            "owner": _text(source.get("owner"), "source.owner"),
        },
        "nodes": compiled_nodes,
        "contentFingerprint": hashlib.sha256(
            _canonical_json(document).encode("utf-8")
        ).hexdigest(),
    }


def _lua_value(value: Any, indent: int = 0) -> str:
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, str):
        return _lua_string(value)
    if isinstance(value, list):
        lines = ["{"]
        for item in value:
            lines.append(" " * (indent + 4) + _lua_value(item, indent + 4) + ",")
        lines.append(" " * indent + "}")
        return chr(10).join(lines)
    if isinstance(value, dict):
        lines = ["{"]
        for key in sorted(value):
            lines.append(
                " " * (indent + 4)
                + f"[{_lua_string(str(key))}] = "
                + _lua_value(value[key], indent + 4)
                + ","
            )
        lines.append(" " * indent + "}")
        return chr(10).join(lines)
    raise CompileError(f"cannot render Conversation UI value {type(value).__name__}")


def render_conversation_ui_registry(compiled: dict[str, Any]) -> str:
    """Render the generated PZ-safe registry and bounded lookup functions."""

    nodes = {node["id"]: node for node in compiled["nodes"]}
    children = {
        node["id"]: node["children"]
        for node in compiled["nodes"]
        if node["children"]
    }
    lines = [
        "-- Generated by tools/semantic_harness/codebuilder/build.py; do not edit by hand.",
        "-- Canonical Conversation UI navigation/presentation registry.",
        "PNC = PNC or {}",
        "PNC.Semantics = PNC.Semantics or {}",
        "local Registry = PNC.Semantics.ConversationUIRegistry or {}",
        "PNC.Semantics.ConversationUIRegistry = Registry",
        f"Registry.SCHEMA = {_lua_string(UI_REGISTRY_SCHEMA)}",
        "Registry.VERSION = 1",
        f"Registry.SOURCE_FINGERPRINT = {_lua_string(compiled['contentFingerprint'])}",
        f"Registry.NODES = {_lua_value(nodes, 0)}",
        f"Registry.CHILDREN = {_lua_value(children, 0)}",
        "function Registry.Node(nodeID)",
        '    return Registry.NODES[tostring(nodeID or "")]',
        "end",
        "function Registry.Children(nodeID)",
        '    return Registry.CHILDREN[tostring(nodeID or "")] or {}',
        "end",
        "function Registry.StaticChoices(hubID)",
        '    local target = tostring(hubID or "")',
        '    local children = Registry.Children("conversation.hub:" .. target)',
        "    local output = {}",
        "    for index = 1, #children do",
        "        local node = Registry.Node(children[index].nodeID)",
        '        if type(node) == "table" and node.kind == "choice" then',
        "            output[#output + 1] = node",
        "        end",
        "    end",
        "    return output",
        "end",
        "return Registry",
        "",
    ]
    return chr(10).join(lines)


def write_conversation_ui_source(path: Path, document: dict[str, Any]) -> Path:
    """Write one canonical source document after validation."""

    compile_conversation_ui(document)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(document, ensure_ascii=False, indent=2) + chr(10),
        encoding="utf-8",
        newline=chr(10),
    )
    return path


def write_conversation_ui_output(repository: Path, compiled: dict[str, Any]) -> Path:
    path = repository.expanduser().resolve() / UI_REGISTRY_RUNTIME_RELATIVE
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        render_conversation_ui_registry(compiled),
        encoding="utf-8",
        newline=chr(10),
    )
    return path


__all__ = [
    "UI_REGISTRY_SCHEMA",
    "UI_REGISTRY_SOURCE_RELATIVE",
    "UI_REGISTRY_RUNTIME_RELATIVE",
    "compile_conversation_ui",
    "conversation_ui_source_fingerprint",
    "conversation_ui_source_path_from_manifest",
    "load_conversation_ui_source",
    "render_conversation_ui_registry",
    "write_conversation_ui_output",
    "write_conversation_ui_source",
]
