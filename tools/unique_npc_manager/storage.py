"""Safe filesystem CRUD for Hoomans drafts and generated runtime files."""

from __future__ import annotations

import json
import os
import tempfile
from pathlib import Path
from typing import Any, Iterable, Optional

from .runtime_export import (
    GENERATED_MARKER,
    LOADER_NAME,
    DefinitionExportError,
    export_catalog,
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
    DEFINITION_DIR = "NPC Definitions"

    def __init__(self, root: Path):
        self.root = root.expanduser().resolve()
        self.root.mkdir(parents=True, exist_ok=True)
        self.definition_root = self.root / self.DEFINITION_DIR
        self.definition_root.mkdir(parents=True, exist_ok=True)

    def _path(self, filename: str) -> Path:
        if not filename or Path(filename).name != filename or not filename.endswith(".txt"):
            raise StorageError(f"invalid Hoomans filename: {filename!r}")
        if filename == self.INDEX_NAME:
            raise StorageError("the index is not an NPC definition")
        return within(self.definition_root, self.definition_root / filename)

    def _legacy_path(self, filename: str) -> Path:
        if not filename or Path(filename).name != filename or not filename.endswith(".txt"):
            raise StorageError(f"invalid Hoomans filename: {filename!r}")
        if filename == self.INDEX_NAME:
            raise StorageError("the index is not an NPC definition")
        return within(self.root, self.root / filename)

    def _index_path(self) -> Path:
        return self.root / self.INDEX_NAME

    def _read_index_payload(self) -> dict[str, Any]:
        try:
            payload = json.loads(self._index_path().read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return {}
        return payload if isinstance(payload, dict) else {}

    @staticmethod
    def _safe_filename(value: Any, index_name: str) -> Optional[str]:
        if not isinstance(value, str):
            return None
        if not value.endswith(".txt") or Path(value).name != value:
            return None
        if value == index_name:
            return None
        return value

    def _read_index(self) -> list[str]:
        payload = self._read_index_payload()
        values: set[str] = set()
        for value in payload.get("files", []):
            filename = self._safe_filename(value, self.INDEX_NAME)
            if filename:
                values.add(filename)
        for entry in payload.get("entries", []):
            if not isinstance(entry, dict):
                continue
            if str(entry.get("definitionType") or entry.get("kind") or "") != "npc":
                continue
            filename = self._safe_filename(
                entry.get("fileName") or entry.get("file"), self.INDEX_NAME
            )
            if filename:
                values.add(filename)
        return sorted(values)

    def _write_index(self, filenames: Iterable[str]) -> None:
        values = sorted(
            {
                filename
                for filename in filenames
                if self._safe_filename(filename, self.INDEX_NAME)
            }
        )
        existing = self._read_index_payload()
        other_entries: list[dict[str, Any]] = []
        metadata_by_name: dict[str, dict[str, Any]] = {}
        for entry in existing.get("entries", []):
            if not isinstance(entry, dict):
                continue
            definition_type = str(
                entry.get("definitionType") or entry.get("kind") or ""
            )
            filename = self._safe_filename(
                entry.get("fileName") or entry.get("file"), self.INDEX_NAME
            )
            if definition_type != "npc" and filename:
                other_entries.append(dict(entry))
            elif definition_type == "npc" and filename:
                metadata_by_name[filename] = dict(entry)
        entries = other_entries
        for filename in values:
            metadata = metadata_by_name.get(filename, {})
            entries.append(
                {
                    **metadata,
                    "definitionType": "npc",
                    "fileName": filename,
                    "path": f"Hoomans/{self.DEFINITION_DIR}/{filename}",
                    "schemaVersion": int(metadata.get("schemaVersion") or 2),
                }
            )
        entries.sort(
            key=lambda entry: (
                str(entry.get("definitionType") or ""),
                str(entry.get("fileName") or ""),
            )
        )
        payload = {
            "schemaVersion": 2,
            "kind": "ProjectHoomans.DefinitionIndex",
            "entries": entries,
            # Compatibility view consumed by older Unique NPC tooling.
            "files": values,
        }
        atomic_write(self._index_path(), encode(payload))

    def list_files(self) -> list[str]:
        indexed = set(self._read_index())
        discovered = {
            path.name
            for path in self.definition_root.glob("*.txt")
            if path.name != self.INDEX_NAME
        }
        # Read legacy flat files during migration. New saves always go to the
        # namespaced directory, so an Opera file can never collide with one.
        discovered.update(
            path.name
            for path in self.root.glob("*.txt")
            if path.name != self.INDEX_NAME
        )
        return sorted(indexed | discovered)

    def load(self, filename: str) -> dict[str, Any]:
        path = self._path(filename)
        if not path.exists():
            path = self._legacy_path(filename)
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
            source = self._legacy_path(filename)
        if not source.exists():
            raise StorageError(f"Hoomans file does not exist: {filename}")
        source.unlink()
        self._write_index(set(self.list_files()) - {filename})
        return source

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
    """Export facade for the self-contained runtime definition catalog."""

    def __init__(self, root: Path):
        self.root = root.expanduser().resolve()
        self.root.mkdir(parents=True, exist_ok=True)

    def catalog_path(self) -> Path:
        return within(self.root, self.root / LOADER_NAME)

    @staticmethod
    def _definition_id(definition: dict[str, Any]) -> str:
        identifier = definition.get("uniqueDefinitionId") or definition.get("id")
        if not identifier:
            raise StorageError("unique definition ID is required")
        return str(identifier)

    def _remove_legacy_modules(self) -> None:
        """Permanently remove child modules from the pre-catalog format."""

        candidates = list(self.root.glob("*.lua"))
        legacy_root = self.root / ".trash"
        if legacy_root.is_dir():
            candidates.extend(path for path in legacy_root.iterdir() if path.is_file())
        for path in candidates:
            if path.name == LOADER_NAME:
                continue
            try:
                content = path.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            if GENERATED_MARKER in content:
                path.unlink()
        if legacy_root.is_dir():
            try:
                legacy_root.rmdir()
            except OSError:
                pass

    def export_all(self, definitions: Iterable[dict[str, Any]]) -> Path:
        try:
            content = export_catalog(definitions)
        except DefinitionExportError as exc:
            raise StorageError(str(exc)) from exc
        path = self.catalog_path()
        atomic_write(path, content)
        self._remove_legacy_modules()
        return path

    def export(self, definition: dict[str, Any]) -> Path:
        """Compatibility entry point for a one-definition catalog export."""

        return self.export_all([build_payload(definition)["definition"]])

    def rebuild(self, definitions: Iterable[dict[str, Any]] = ()) -> Path:
        return self.export_all(definitions)

    def has_generated(self, definition: dict[str, Any]) -> bool:
        path = self.catalog_path()
        if not path.exists():
            return False
        try:
            identifier = self._definition_id(definition)
            content = path.read_text(encoding="utf-8", errors="replace")
        except (OSError, StorageError):
            return False
        marker = f'["uniqueDefinitionId"] = "{identifier}"'
        return marker in content

    def catalog_contains_all(self, definitions: Iterable[dict[str, Any]]) -> bool:
        return all(self.has_generated(definition) for definition in definitions)
