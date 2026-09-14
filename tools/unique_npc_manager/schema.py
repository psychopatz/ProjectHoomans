"""Shared Hoomans definition normalization used by the CLI and GUI.

The game-facing representation is Lua, but the creator's local files are
JSON wrappers.  Keeping this boundary in one module prevents the desktop
tool and the existing command-line converter from drifting apart.
"""

from __future__ import annotations

import json
import re
from copy import deepcopy
from pathlib import Path
from typing import Any, Iterable, Optional, Tuple


SAFE_ID = re.compile(r"^[A-Za-z0-9_.:-]{3,128}$")
EDITOR_ONLY_KEYS = {
    "appearanceAuthored",
    "authoredFields",
    "previewSeed",
    "identityIDLocked",
    "fileName",
    "originalDisplayName",
    "runtimeRecord",
    "_dirty",
}


class ConversionError(ValueError):
    """Raised when a creator payload cannot become a runtime definition."""


def text(value: Any) -> Optional[str]:
    if value is None:
        return None
    value = str(value).strip()
    return value or None


def name_parts(definition: dict[str, Any]) -> Tuple[str, str]:
    identity = definition.get("identity")
    survivor = identity.get("survivor") if isinstance(identity, dict) else {}
    survivor = survivor if isinstance(survivor, dict) else {}
    display = text(definition.get("displayName") or definition.get("name"))
    first = text(survivor.get("forename"))
    surname = text(survivor.get("surname"))
    pieces = display.split() if display else []
    first = first or (pieces[0] if pieces else None)
    surname = surname or (" ".join(pieces[1:]) if len(pieces) > 1 else None)
    if not first or not surname:
        raise ConversionError(
            "a first name and surname are required for the creator filename"
        )
    return first, surname


def file_part(value: str) -> str:
    result = re.sub(r"[^A-Za-z0-9]+", "", value)
    if not result:
        raise ConversionError(f"name component has no filename-safe text: {value!r}")
    return result


def definition_id(definition: dict[str, Any], first: str, surname: str) -> str:
    candidate = text(definition.get("uniqueDefinitionId") or definition.get("id"))
    candidate = candidate or "unique:" + re.sub(
        r"[^a-z0-9]", "", (first + surname).lower()
    )
    if not SAFE_ID.fullmatch(candidate):
        raise ConversionError(f"invalid unique definition id: {candidate!r}")
    return candidate


def normalize_definition(source: dict[str, Any]) -> dict[str, Any]:
    """Return a canonical runtime definition while preserving nested metadata."""

    if not isinstance(source, dict):
        raise ConversionError("definition must be an object")
    definition = deepcopy(source)
    first, surname = name_parts(definition)
    display = text(definition.get("displayName") or definition.get("name"))
    if not display:
        display = f"{first} {surname}"
    if not isinstance(definition.get("isFemale"), bool):
        raise ConversionError("isFemale must be a JSON boolean")

    definition["displayName"] = display
    definition["name"] = display
    definition["isFemale"] = definition["isFemale"] is True
    definition["id"] = definition_id(definition, first, surname)
    definition["uniqueDefinitionId"] = definition["id"]
    try:
        definition["version"] = max(1, int(definition.get("version") or 1))
    except (TypeError, ValueError) as exc:
        raise ConversionError("version must be an integer") from exc

    identity = definition.setdefault("identity", {})
    if not isinstance(identity, dict):
        raise ConversionError("identity must be an object when present")
    survivor = identity.setdefault("survivor", {})
    if not isinstance(survivor, dict):
        raise ConversionError("identity.survivor must be an object")
    survivor["forename"] = text(survivor.get("forename")) or first
    survivor["surname"] = text(survivor.get("surname")) or surname

    for key in EDITOR_ONLY_KEYS | {"identitySeed"}:
        definition.pop(key, None)

    faction = definition.get("factionID")
    if faction is None or (
        isinstance(faction, str)
        and (not faction.strip() or faction.strip().lower() == "random")
    ):
        definition.pop("factionID", None)

    starting_items = definition.get("startingItems")
    if starting_items is not None and not isinstance(starting_items, list):
        raise ConversionError("startingItems must be an array when present")
    for index, item in enumerate(starting_items or [], start=1):
        if not isinstance(item, dict):
            raise ConversionError(f"startingItems[{index}] must be an object")
        if not text(item.get("type")):
            raise ConversionError(f"startingItems[{index}] is missing type")

    return definition


def read_definition(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ConversionError(f"cannot read JSON from {path}: {exc}") from exc
    if not isinstance(payload, dict):
        raise ConversionError(f"{path} must contain a JSON object")
    definition = payload.get("definition", payload)
    if not isinstance(definition, dict):
        raise ConversionError(f"{path} does not contain a definition object")
    return definition


def build_payload(definition: dict[str, Any], produced: bool = True) -> dict[str, Any]:
    return {
        "schemaVersion": 2,
        "kind": "ProjectHoomans.UniqueNPC",
        "produced": produced is True,
        "definition": normalize_definition(definition),
    }


def output_name(definition: dict[str, Any]) -> str:
    first, surname = name_parts(definition)
    return file_part(first) + file_part(surname) + ".txt"


def encode(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def update_index(directory: Path, file_names: Iterable[str]) -> Path:
    index_path = directory / "UniqueNPCIndex.txt"
    existing: list[str] = []
    if index_path.exists():
        try:
            payload = json.loads(index_path.read_text(encoding="utf-8"))
            existing = payload.get("files", []) if isinstance(payload, dict) else []
        except (OSError, json.JSONDecodeError):
            existing = []
    names = sorted(
        {str(name) for name in existing if isinstance(name, str)}
        | {str(name) for name in file_names}
    )
    payload = {
        "schemaVersion": 1,
        "kind": "ProjectHoomans.UniqueNPCIndex",
        "files": names,
    }
    index_path.write_text(encode(payload), encoding="utf-8")
    return index_path
