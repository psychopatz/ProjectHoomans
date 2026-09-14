"""Safe filesystem CRUD for Hoomans drafts and generated runtime files."""

from __future__ import annotations

import json
import os
import re
import shutil
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Optional

from .runtime_export import (
    GENERATED_MARKER,
    DefinitionExportError,
    export_definition_module,
    generated_definition_id,
    module_stem,
    rebuild_loader,
)
from .schema import (
    ConversionError,
    build_payload,
    encode,
    output_name,
    read_definition,
)


class StorageError(RuntimeError):
    """Raised when a managed file cannot be safely changed."""


def atomic_write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    handle = tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", dir=str(path.parent), delete=False
    )
    temporary = Path(handle.name)
    try:
        with handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        if temporary.exists():
            temporary.unlink()


def within(root: Path, candidate: Path) -> Path:
    root = root.expanduser().resolve()
    candidate = candidate.expanduser().resolve()
    try:
        candidate.relative_to(root)
    except ValueError as exc:
        raise StorageError(f"path escapes managed root: {candidate}") from exc
    return candidate


class DraftStore:
    """CRUD for the JSON wrapper files written by the in-game creator."""

    INDEX_NAME = "UniqueNPCIndex.txt"

    def __init__(self, root: Path):
        self.root = root.expanduser().resolve()
        self.root.mkdir(parents=True, exist_ok=True)
        self.trash = self.root / ".trash"

    def _path(self, filename: str) -> Path:
        if not filename or Path(filename).name != filename or not filename.endswith(".txt"):
            raise StorageError(f"invalid Hoomans filename: {filename!r}")
        if filename == self.INDEX_NAME:
            raise StorageError("the index is not an NPC definition")
        return within(self.root, self.root / filename)

    def _index_path(self) -> Path:
        return self.root / self.INDEX_NAME

    def _read_index(self) -> list[str]:
        try:
            payload = json.loads(self._index_path().read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return []
        values = payload.get("files", []) if isinstance(payload, dict) else []
        return sorted(
            {
                str(value)
                for value in values
                if isinstance(value, str)
                and value.endswith(".txt")
                and Path(value).name == value
                and value != self.INDEX_NAME
            }
        )

    def _write_index(self, filenames: Iterable[str]) -> None:
        values = sorted(set(filenames))
        payload = {
            "schemaVersion": 1,
            "kind": "ProjectHoomans.UniqueNPCIndex",
            "files": values,
        }
        atomic_write(self._index_path(), encode(payload))

    def list_files(self) -> list[str]:
        indexed = set(self._read_index())
        discovered = {
            path.name
            for path in self.root.glob("*.txt")
            if path.name != self.INDEX_NAME
        }
        return sorted(indexed | discovered)

    def load(self, filename: str) -> dict[str, Any]:
        path = self._path(filename)
        if not path.exists():
            raise StorageError(f"Hoomans file does not exist: {filename}")
        try:
            return read_definition(path)
        except ConversionError as exc:
            raise StorageError(str(exc)) from exc

    def save(self, definition: dict[str, Any], filename: Optional[str] = None) -> Path:
        payload = build_payload(definition, produced=True)
        target_name = filename or output_name(payload["definition"])
        target = self._path(target_name)
        atomic_write(target, encode(payload))
        self._write_index(set(self.list_files()) | {target.name})
        return target

    def import_file(self, source: Path, filename: Optional[str] = None) -> Path:
        definition = read_definition(source.expanduser().resolve())
        return self.save(definition, filename or output_name(definition))

    def delete(self, filename: str) -> Path:
        source = self._path(filename)
        if not source.exists():
            raise StorageError(f"Hoomans file does not exist: {filename}")
        self.trash.mkdir(parents=True, exist_ok=True)
        stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        destination = self.trash / f"{stamp}_{source.name}"
        shutil.move(str(source), str(destination))
        self._write_index(set(self.list_files()) - {filename})
        return destination

    def rebuild_index(self) -> Path:
        valid: list[str] = []
        for filename in self.list_files():
            try:
                self.load(filename)
            except StorageError:
                continue
            valid.append(filename)
        self._write_index(valid)
        return self._index_path()


class RuntimeDefinitionStore:
    """CRUD/export facade for generated Lua runtime definitions."""

    def __init__(self, root: Path):
        self.root = root.expanduser().resolve()
        self.root.mkdir(parents=True, exist_ok=True)
        self.trash = self.root / ".trash"

    def _generated_modules(self) -> list[Path]:
        output: list[Path] = []
        for path in sorted(self.root.glob("*.lua")):
            if path.name == "PNC_UniqueNPCDefinitions.lua" or ".bak." in path.name:
                continue
            try:
                content = path.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            if GENERATED_MARKER in content:
                output.append(path)
        return output

    @staticmethod
    def _definition_id(definition: dict[str, Any]) -> str:
        identifier = definition.get("uniqueDefinitionId") or definition.get("id")
        if not identifier:
            raise StorageError("unique definition ID is required")
        return str(identifier)

    def _find_existing(self, definition: dict[str, Any]) -> Optional[Path]:
        identifier = self._definition_id(definition)
        for path in self._generated_modules():
            if generated_definition_id(path) == identifier:
                return path
        return None

    def _available_path(self, definition: dict[str, Any]) -> Path:
        identifier = self._definition_id(definition)
        preferred = module_stem(definition)
        candidate = self.root / f"{preferred}.lua"
        if not candidate.exists():
            return candidate
        if generated_definition_id(candidate) == identifier:
            return candidate

        token = re.sub(r"[^A-Za-z0-9]+", "", identifier).lower() or "id"
        candidate = self.root / f"{preferred}__{token[:24]}.lua"
        suffix = 2
        while candidate.exists():
            if generated_definition_id(candidate) == identifier:
                return candidate
            candidate = self.root / f"{preferred}__{token[:24]}_{suffix}.lua"
            suffix += 1
        return candidate

    def _backup(self, path: Path) -> Path:
        self.trash.mkdir(parents=True, exist_ok=True)
        stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        destination = self.trash / f"{stamp}_{path.name}"
        counter = 2
        while destination.exists():
            destination = self.trash / f"{stamp}_{counter}_{path.name}"
            counter += 1
        shutil.move(str(path), str(destination))
        return destination

    def module_path(self, definition: dict[str, Any]) -> Path:
        # Always prefer the canonical human-readable name.  An existing
        # legacy module is discovered separately by export() and moved to
        # the managed trash directory before the canonical file is written.
        return within(self.root, self._available_path(definition))

    def export(self, definition: dict[str, Any]) -> Path:
        try:
            normalized = build_payload(definition)["definition"]
            path = self.module_path(normalized)
            identifier = self._definition_id(normalized)
            for old_path in self._generated_modules():
                if old_path != path and generated_definition_id(old_path) == identifier:
                    self._backup(old_path)
            atomic_write(path, export_definition_module(normalized))
            rebuild_loader(self.root)
            return path
        except DefinitionExportError as exc:
            raise StorageError(str(exc)) from exc

    def delete(self, definition: dict[str, Any]) -> Path:
        path = self._find_existing(definition) or self.module_path(definition)
        return self.delete_module(path.name)

    def delete_module(self, filename: str) -> Path:
        if (not filename or Path(filename).name != filename
                or filename == "PNC_UniqueNPCDefinitions.lua"
                or not filename.endswith(".lua")):
            raise StorageError(f"invalid generated module filename: {filename!r}")
        path = within(self.root, self.root / filename)
        if not path.exists():
            raise StorageError(f"generated definition does not exist: {path.name}")
        content = path.read_text(encoding="utf-8", errors="replace")
        if GENERATED_MARKER not in content:
            raise StorageError(f"refusing to delete non-generated Lua: {path.name}")
        backup = self._backup(path)
        rebuild_loader(self.root)
        return backup

    def has_generated(self, definition: dict[str, Any]) -> bool:
        return self._find_existing(definition) is not None

    def rebuild(self) -> Path:
        return rebuild_loader(self.root)
