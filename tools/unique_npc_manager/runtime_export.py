"""Deterministic Lua output for Project Hoomans unique NPC definitions."""

from __future__ import annotations

import math
from numbers import Real
from pathlib import Path
from typing import Any, Iterable

from .schema import ConversionError, file_part, name_parts, normalize_definition


GENERATED_MARKER = "-- PNC_GENERATED_UNIQUE_NPC"
GENERATED_ID_MARKER = "-- uniqueDefinitionId: "
REGISTRAR_REQUIRE = "PNC/Generated/PNC_UniqueNPCRegistrar"
LOADER_NAME = "PNC_UniqueNPCDefinitions.lua"


class DefinitionExportError(ConversionError):
    """Raised when a normalized definition cannot be emitted as Lua."""


def _lua_string(value: str) -> str:
    output: list[str] = ['"']
    for character in str(value):
        code = ord(character)
        if character == "\\":
            output.append("\\\\")
        elif character == '"':
            output.append('\\"')
        elif character == "\n":
            output.append("\\n")
        elif character == "\r":
            output.append("\\r")
        elif character == "\t":
            output.append("\\t")
        elif code < 32 or code == 127:
            output.append(f"\\{code:03d}")
        else:
            output.append(character)
    output.append('"')
    return "".join(output)


def _is_array(value: dict[Any, Any]) -> bool:
    if not value:
        return False
    numeric: list[int] = []
    for key in value:
        if isinstance(key, int) and key >= 1:
            numeric.append(key)
        elif isinstance(key, str) and key.isdigit() and int(key) >= 1:
            numeric.append(int(key))
        else:
            return False
    return sorted(numeric) == list(range(1, len(numeric) + 1))


def _key_sort(key: Any) -> tuple[int, str]:
    if isinstance(key, int):
        return 0, f"{key:020d}"
    return 1, str(key)


def _lua_value(value: Any, level: int = 0) -> str:
    indent = "    " * level
    child_indent = "    " * (level + 1)
    if value is None:
        return "nil"
    if value is True:
        return "true"
    if value is False:
        return "false"
    if isinstance(value, str):
        return _lua_string(value)
    if isinstance(value, Real) and not isinstance(value, bool):
        number = float(value)
        if not math.isfinite(number):
            raise DefinitionExportError("definition contains a non-finite number")
        if isinstance(value, int) or number.is_integer():
            return str(int(number))
        return format(number, ".15g")
    if isinstance(value, list):
        entries = [_lua_value(item, level + 1) for item in value]
        if not entries:
            return "{}"
        return "{\n" + ",\n".join(
            child_indent + entry for entry in entries
        ) + "\n" + indent + "}"
    if isinstance(value, dict):
        if _is_array(value):
            entries = [value.get(index, value.get(str(index))) for index in range(1, len(value) + 1)]
            return _lua_value(entries, level)
        entries = []
        for key in sorted(value, key=_key_sort):
            if not isinstance(key, (str, int, float)):
                raise DefinitionExportError(f"unsupported Lua table key: {key!r}")
            rendered_key = _lua_string(str(key))
            entries.append(
                f"{child_indent}[{rendered_key}] = {_lua_value(value[key], level + 1)}"
            )
        if not entries:
            return "{}"
        return "{\n" + ",\n".join(entries) + "\n" + indent + "}"
    raise DefinitionExportError(f"unsupported Lua value: {type(value).__name__}")


def module_stem(definition: dict[str, Any]) -> str:
    try:
        first, surname = name_parts(definition)
        return file_part(first) + file_part(surname)
    except ConversionError as exc:
        raise DefinitionExportError(str(exc)) from exc


def module_name(definition: dict[str, Any]) -> str:
    return module_stem(definition)


def export_definition_module(definition: dict[str, Any]) -> str:
    """Render one definition using the aggregate catalog format.

    The manager no longer writes one Lua file per NPC.  This compatibility
    helper remains available to callers that used the old exporter, but it
    deliberately returns a self-contained catalog fragment without manager
    comments or child-module loader metadata.
    """

    return export_catalog([definition])


def _normalized_definitions(definitions: Iterable[dict[str, Any]]) -> list[dict[str, Any]]:
    normalized: list[dict[str, Any]] = []
    seen: set[str] = set()
    for definition in definitions:
        try:
            value = normalize_definition(definition)
        except ConversionError as exc:
            raise DefinitionExportError(str(exc)) from exc
        identifier = str(value["uniqueDefinitionId"])
        if identifier in seen:
            raise DefinitionExportError(
                f"duplicate unique definition ID: {identifier}"
            )
        seen.add(identifier)
        normalized.append(value)
    normalized.sort(key=lambda value: str(value["uniqueDefinitionId"]))
    return normalized


def export_catalog(definitions: Iterable[dict[str, Any]]) -> str:
    """Render the complete self-registering unique NPC catalog.

    The generated file has exactly one stable dependency: the shared
    registrar.  Every definition is embedded directly in this file so the
    composition root never needs to know individual NPC filenames.
    """

    normalized = _normalized_definitions(definitions)
    lines = [f'local register = require "{REGISTRAR_REQUIRE}"', ""]
    for definition in normalized:
        lines.extend(["register(", _lua_value(definition), ")", ""])
    lines.extend(["return true", ""])
    return "\n".join(lines)


def _generated_module_paths(root: Path) -> Iterable[Path]:
    for path in sorted(root.glob("*.lua")):
        if path.name == LOADER_NAME:
            continue
        if ".bak." in path.name:
            continue
        try:
            content = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        if GENERATED_MARKER in content:
            yield path


def rebuild_loader(
    root: Path,
    definitions: Iterable[dict[str, Any]] = (),
) -> Path:
    """Write the single aggregate runtime catalog.

    The historical function name is retained so older manager integrations
    continue to import cleanly; it no longer creates a require-based loader.
    """

    root.mkdir(parents=True, exist_ok=True)
    path = root / LOADER_NAME
    path.write_text(export_catalog(definitions), encoding="utf-8")
    return path


def generated_definition_id(path: Path) -> str | None:
    """Read the stable definition ID embedded in a generated module."""

    try:
        content = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None
    for line in content.splitlines():
        if line.startswith(GENERATED_ID_MARKER):
            value = line[len(GENERATED_ID_MARKER):].strip()
            return value or None
    # Modules generated before the marker was added can still be migrated by
    # reading the serialized ID from their register payload.
    marker = '["uniqueDefinitionId"] = "'
    start = content.find(marker)
    if start < 0:
        return None
    start += len(marker)
    end = content.find('"', start)
    return content[start:end] if end > start else None
