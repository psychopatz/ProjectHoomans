"""Shared Semantic Lab authoring/build service.

The service is the single boundary used by the Tk editor, headless CLI, and
direct Python/Codex callers. The lower-level compiler and writer remain in the
embedded CodeBuilder; the existing authoring module remains the compatibility
implementation for its report shapes and public helper functions.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from tools.semantic_harness import authoring
from .blocks import SemanticBlockRegistry
from .codeblocks import validate_codeblock_document
from .compiler import CompileError
from .dataset_adapters import preview_dataset_adapter, promote_reviewed_candidates
from ..interaction_explorer import build_interaction_rows, search_interactions


DATASET_SOURCE_SPECS = (
    {
        "id": "semantic_definitions",
        "label": "Semantic definitions",
        "kind": "semantic",
        "path": Path("tools/semantic_compiler/semantic_definitions.json"),
    },
    {
        "id": "common_interactions",
        "label": "Conversation interactions",
        "kind": "dialogue",
        "path": Path("tools/semantic_compiler/common_interactions.json"),
    },
    {
        "id": "wordnet_concepts",
        "label": "Reviewed WordNet concepts",
        "kind": "lexicon",
        "path": Path("tools/semantic_compiler/wordnet_concepts.json"),
    },
)

WORKFLOW_DATASET_KINDS = frozenset(("semantic", "dialogue"))


class SemanticLabAuthoringService:
    """Bind one repository/runtime configuration to all authoring operations."""

    def __init__(
        self,
        repository: Path | None = None,
        *,
        runtime_root: Path | None = None,
    ) -> None:
        self.repository = (repository or authoring.REPOSITORY).expanduser().resolve()
        self.runtime_root = (
            runtime_root or self.repository
        ).expanduser().resolve()
        self.block_registry = SemanticBlockRegistry(
            self.repository,
            DATASET_SOURCE_SPECS,
        )

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
        rows: list[dict[str, Any]] = []
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
                rows.append({
                    "sourceID": spec["id"],
                    "sourceLabel": spec["label"],
                    "kind": entry_kind,
                    "id": entry_id,
                    "path": str(spec["path"]),
                    "summary": serialized[:512],
                })
                if len(rows) >= limit:
                    return rows
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

    def list_semantic_blocks(
        self,
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Return reusable blocks over the supplied live production catalog."""
        return self.block_registry.catalog(production_catalog)

    def search_semantic_blocks(
        self,
        query: str = "",
        *,
        category: str | None = None,
        production_catalog: dict[str, Any] | None = None,
        limit: int = 64,
    ) -> list[dict[str, Any]]:
        return self.block_registry.search(
            query,
            category=category,
            production_catalog=production_catalog,
            limit=limit,
        )

    @staticmethod
    def list_interactions(
        production_catalog: dict[str, Any] | None,
    ) -> list[dict[str, Any]]:
        """Return searchable rows from the live production interaction catalog."""

        return build_interaction_rows(production_catalog)

    @staticmethod
    def search_interactions(
        query: str = "",
        *,
        production_catalog: dict[str, Any] | None = None,
        limit: int = 128,
    ) -> list[dict[str, Any]]:
        return search_interactions(production_catalog, query, limit=limit)

    def validate_semantic_blocks(
        self,
        block_ids: list[str],
        *,
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.block_registry.validate_selection(
            block_ids,
            production_catalog=production_catalog,
        )

    def validate_workflow_selection(
        self,
        source_id: str,
        block_ids: list[str],
        *,
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Validate a selected canonical source and composed blocks without writing."""
        spec = self._dataset_spec(source_id)
        selection: dict[str, Any] = {
            "ok": False,
            "type": "semantic_lab_workflow_selection",
            "workflow": {
                "datasetID": source_id,
                "sourcePath": str(spec["path"]),
                "generationKind": spec["kind"],
                "blockIDs": [str(block_id) for block_id in block_ids],
            },
            "previewOnly": True,
            "effectFree": True,
            "writes": [],
        }
        if spec["kind"] not in WORKFLOW_DATASET_KINDS:
            selection["diagnostics"] = [{
                "severity": "error",
                "message": f"dataset {source_id} has no modular Lua generation path",
            }]
            return selection
        try:
            document = self.load_dataset_document(source_id)
            dataset_report = self.preview_dataset_edit(source_id, document)
        except (CompileError, OSError, ValueError, TypeError) as error:
            dataset_report = {
                "ok": False,
                "type": "dataset_edit_preview",
                "sourceID": source_id,
                "diagnostics": [{"severity": "error", "message": str(error)}],
                "previewOnly": True,
                "effectFree": True,
                "writes": [],
            }
        block_report = self.validate_semantic_blocks(
            block_ids,
            production_catalog=production_catalog,
        )
        diagnostics = list(dataset_report.get("diagnostics") or [])
        diagnostics.extend(block_report.get("diagnostics") or [])
        selection.update({
            "ok": dataset_report.get("ok") is True and block_report.get("ok") is True,
            "dataset": dataset_report,
            "blocks": block_report,
            "diagnostics": diagnostics,
        })
        return selection

    def preview_workflow(
        self,
        source_id: str,
        block_ids: list[str],
        *,
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Preview the complete select → compose → validate → source-build plan."""
        selection = self.validate_workflow_selection(
            source_id,
            block_ids,
            production_catalog=production_catalog,
        )
        report: dict[str, Any] = {
            "ok": False,
            "type": "semantic_lab_workflow_preview",
            "workflow": selection["workflow"],
            "selection": selection,
            "previewOnly": True,
            "effectFree": True,
            "writes": [],
        }
        if selection.get("ok") is not True:
            report["diagnostics"] = selection.get("diagnostics", [])
            return report
        spec = self._dataset_spec(source_id)
        source_path = self._dataset_path(source_id)
        if spec["kind"] == "semantic":
            source_preview = self.preview_semantic_source(source_path)
        else:
            source_preview = self.preview_dialogue_source(source_path)
        report.update({
            "ok": source_preview.get("ok") is True,
            "sourcePreview": source_preview,
            "diagnostics": source_preview.get("diagnostics", []),
            "readyForApproval": source_preview.get("ok") is True,
        })
        return report

    def generate_workflow(
        self,
        source_id: str,
        block_ids: list[str],
        *,
        approved: bool,
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Generate through the existing writer after explicit workflow approval."""
        if approved is not True:
            return {
                "ok": False,
                "type": "semantic_lab_workflow_generation",
                "generationApproved": False,
                "diagnostics": [{
                    "severity": "error",
                    "message": "workflow generation requires explicit approval",
                }],
                "previewOnly": True,
                "effectFree": True,
                "writes": [],
            }
        preview = self.preview_workflow(
            source_id,
            block_ids,
            production_catalog=production_catalog,
        )
        if preview.get("ok") is not True:
            return {
                **preview,
                "type": "semantic_lab_workflow_generation",
                "generationApproved": False,
            }
        spec = self._dataset_spec(source_id)
        source_path = self._dataset_path(source_id)
        if spec["kind"] == "semantic":
            generation = self.generate_semantic_source(source_path)
        else:
            generation = self.generate_dialogue_source(source_path)
        return {
            "ok": generation.get("ok") is True,
            "type": "semantic_lab_workflow_generation",
            "workflow": preview["workflow"],
            "selection": preview["selection"],
            "sourcePreview": preview.get("sourcePreview"),
            "generation": generation,
            "generationApproved": True,
            "restartRequired": generation.get("ok") is True,
            "diagnostics": generation.get("diagnostics", []),
            "writes": generation.get("writes", []),
        }

    def validate_codeblock_source(self, source_path: Path) -> dict[str, Any]:
        """Validate a declarative codeblock file without writing or dispatching."""
        source_path = source_path.expanduser().resolve()
        try:
            document = json.loads(source_path.read_text(encoding="utf-8"))
        except (OSError, UnicodeError, json.JSONDecodeError) as error:
            return {
                "ok": False,
                "type": "codeblock_validation",
                "valid": False,
                "sourcePath": str(source_path),
                "diagnostics": [{"severity": "error", "message": str(error)}],
                "effectFree": True,
                "writes": [],
            }
        report = validate_codeblock_document(document)
        report["sourcePath"] = str(source_path)
        return report

    def preview_external_dataset(
        self,
        adapter: str,
        source_path: Path,
        manifest_path: Path,
        *,
        max_records: int = 128,
    ) -> dict[str, Any]:
        """Review one external source without touching canonical or runtime files."""
        return preview_dataset_adapter(
            adapter,
            source_path,
            manifest_path,
            max_records=max_records,
        )

    def promote_external_candidates(
        self,
        report: dict[str, Any],
        decisions: list[dict[str, Any]],
    ) -> dict[str, Any]:
        """Convert explicit license-cleared review decisions to canonical records."""
        return promote_reviewed_candidates(report, decisions)

    def preview_semantic_source(self, source_path: Path) -> dict[str, Any]:
        return authoring.preview_semantic_source(
            source_path,
            repository=self.repository,
            runtime_root=self.runtime_root,
        )

    def generate_semantic_source(self, source_path: Path) -> dict[str, Any]:
        return authoring.generate_semantic_source(
            source_path,
            repository=self.repository,
            runtime_root=self.runtime_root,
        )

    def preview_dialogue_source(self, source_path: Path) -> dict[str, Any]:
        return authoring.preview_dialogue_source(
            source_path,
            repository=self.repository,
        )

    def generate_dialogue_source(self, source_path: Path) -> dict[str, Any]:
        return authoring.generate_dialogue_source(
            source_path,
            repository=self.repository,
        )
