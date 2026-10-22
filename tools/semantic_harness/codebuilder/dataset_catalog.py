"""Canonical Semantic Lab dataset catalog and source lifecycle boundary."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from . import authoring

from .lexicon_compiler import CompileError

DATASET_SOURCE_SPECS = (
    {
        "id": "semantic_definitions",
        "label": "Semantic definitions",
        "kind": "semantic",
        "path": Path(
            "tools/semantic_harness/codebuilder/sources/semantic_definitions.json"
        ),
    },
    {
        "id": "common_interactions",
        "label": "Conversation interactions",
        "kind": "dialogue",
        "path": Path(
            "tools/semantic_harness/codebuilder/sources/common_interactions.json"
        ),
    },
    {
        "id": "grounded_personal_dialogue",
        "label": "Grounded personal dialogue",
        "kind": "dialogue",
        "path": Path(
            "tools/semantic_harness/codebuilder/sources/grounded_personal_dialogue.json"
        ),
    },
    {
        "id": "wordnet_concepts",
        "label": "Reviewed WordNet concepts",
        "kind": "lexicon",
        "path": Path(
            "tools/semantic_harness/codebuilder/sources/wordnet_concepts.json"
        ),
    },
)

WORKFLOW_DATASET_KINDS = frozenset(("semantic", "dialogue"))


class SemanticDatasetCatalog:
    """Own canonical dataset discovery, validation, and explicit source writes."""

    def __init__(self, repository: Path, runtime_root: Path) -> None:
        self.repository = repository
        self.runtime_root = runtime_root

    def list_dataset_sources(self) -> list[dict[str, Any]]:
        """Return the bounded canonical dataset catalog for the UI/CLI."""
        return [
            {
                "id": spec["id"],
                "label": spec["label"],
                "kind": spec["kind"],
                "path": str(spec["path"]),
                "exists": (self.repository / spec["path"]).is_file(),
                "editable": True,
            }
            for spec in DATASET_SOURCE_SPECS
        ]

    def list_workflow_datasets(self) -> list[dict[str, Any]]:
        """Return canonical sources that have an existing Lua generation path."""
        return [
            {
                **source,
                "generationKind": source["kind"],
                "workflowReady": True,
            }
            for source in self.list_dataset_sources()
            if source["kind"] in WORKFLOW_DATASET_KINDS
        ]

    def _dataset_spec(self, source_id: str) -> dict[str, Any]:
        for spec in DATASET_SOURCE_SPECS:
            if spec["id"] == source_id:
                return spec
        raise ValueError(f"unknown canonical dataset source: {source_id}")

    def _dataset_path(self, source_id: str) -> Path:
        return self.repository / self._dataset_spec(source_id)["path"]

    def load_dataset_document(self, source_id: str) -> dict[str, Any]:
        """Load one canonical JSON source selected by stable catalog ID."""
        path = self._dataset_path(source_id)
        try:
            document = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, UnicodeError, json.JSONDecodeError) as error:
            raise CompileError(f"cannot read dataset source {path}: {error}") from error
        if not isinstance(document, dict):
            raise CompileError(f"dataset source {source_id} must contain an object")
        return document

    def search_dataset(
        self,
        query: str = "",
        *,
        source_id: str | None = None,
        limit: int = 64,
    ) -> list[dict[str, Any]]:
        """Search bounded entries without exposing raw corpus or file pickers."""
        if limit < 1:
            return []
        specs = [self._dataset_spec(source_id)] if source_id else DATASET_SOURCE_SPECS
        needle = str(query or "").strip().lower()
        rows_by_source: dict[str, list[dict[str, Any]]] = {
            spec["id"]: [] for spec in specs
        }
        for spec in specs:
            document = self.load_dataset_document(spec["id"])
            entries: list[tuple[str, str, Any]] = []
            if spec["kind"] == "semantic":
                entries = [
                    ("definition", str(item.get("id", "<missing>")), item)
                    for item in document.get("definitions", [])
                    if isinstance(item, dict)
                ]
            elif spec["kind"] == "dialogue":
                entries = [
                    ("pattern", str(item.get("id", "<missing>")), item)
                    for item in document.get("patterns", [])
                    if isinstance(item, dict)
                ]
                for pool in document.get("responsePools", []):
                    if not isinstance(pool, dict):
                        continue
                    entries.extend(
                        ("response", str(item.get("id", "<missing>")), item)
                        for item in pool.get("variants", [])
                        if isinstance(item, dict)
                    )
            else:
                concepts = document.get("concepts", {})
                entries = [
                    ("concept", str(concept_id), {"id": concept_id, **value})
                    for concept_id, value in concepts.items()
                    if isinstance(value, dict)
                ]
            for entry_kind, entry_id, entry in entries:
                serialized = json.dumps(entry, ensure_ascii=False, sort_keys=True)
                if needle and needle not in serialized.lower():
                    continue
                rows_by_source[spec["id"]].append({
                    "sourceID": spec["id"],
                    "sourceLabel": spec["label"],
                    "kind": entry_kind,
                    "id": entry_id,
                    "path": str(spec["path"]),
                    "summary": serialized[:512],
                })

        # Keep the bounded authoring search useful after new canonical
        # sources are registered: expose one deterministic match per source
        # before filling the remaining slots in catalog order. A source-
        # specific search retains its original order and limit semantics.
        if source_id is not None:
            return rows_by_source[source_id][:limit]
        rows: list[dict[str, Any]] = []
        for spec in specs:
            candidates = rows_by_source[spec["id"]]
            if candidates:
                rows.append(candidates.pop(0))
                if len(rows) >= limit:
                    return rows[:limit]
        for spec in specs:
            for candidate in rows_by_source[spec["id"]]:
                rows.append(candidate)
                if len(rows) >= limit:
                    return rows[:limit]
        return rows

    def preview_dataset_edit(
        self,
        source_id: str,
        document: dict[str, Any],
    ) -> dict[str, Any]:
        """Validate an edited canonical document without writing or generating."""
        spec = self._dataset_spec(source_id)
        report: dict[str, Any] = {
            "ok": False,
            "type": "dataset_edit_preview",
            "sourceID": source_id,
            "sourcePath": str(spec["path"]),
            "previewOnly": True,
            "effectFree": True,
            "writes": [],
        }
        if not isinstance(document, dict):
            report["diagnostics"] = [{"severity": "error", "message": "dataset root must be an object"}]
            return report
        try:
            if spec["kind"] == "semantic":
                compiled = authoring.compile_semantic_definitions(
                    document,
                    authoring.discover_registered_capability_ids(self.runtime_root),
                )
                summary = {
                    "definitions": len(document.get("definitions", [])),
                    "patterns": len(compiled["patterns"]),
                    "flows": len(compiled["flows"]),
                }
            elif spec["kind"] == "dialogue":
                compiled = authoring.compile_dialogue_dataset(document)
                summary = {
                    "patterns": len(compiled["patterns"]),
                    "responsePools": len(compiled["responsePools"]),
                    "responseVariants": sum(
                        len(pool["variants"]) for pool in compiled["responsePools"]
                    ),
                }
            else:
                concepts = document.get("concepts")
                if not isinstance(concepts, dict):
                    raise CompileError("wordnet concepts requires a concepts object")
                if any(not isinstance(value, dict) for value in concepts.values()):
                    raise CompileError("wordnet concepts values must be objects")
                summary = {
                    "concepts": len(concepts),
                    "sourceVersion": document.get("source", {}).get("version")
                    if isinstance(document.get("source", {}), dict)
                    else None,
                }
        except (CompileError, OSError, ValueError, TypeError) as error:
            report["diagnostics"] = [{"severity": "error", "message": str(error)}]
            return report
        report.update({"ok": True, "diagnostics": [], "summary": summary})
        return report

    def write_dataset_document(
        self,
        source_id: str,
        document: dict[str, Any],
    ) -> dict[str, Any]:
        """Explicitly write a validated canonical source; never auto-generates Lua."""
        report = self.preview_dataset_edit(source_id, document)
        if report.get("ok") is not True:
            return report
        path = self._dataset_path(source_id)
        path.write_text(
            json.dumps(document, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
            newline="\n",
        )
        return {
            **report,
            "previewOnly": False,
            "effectFree": False,
            "writes": [str(path)],
        }
