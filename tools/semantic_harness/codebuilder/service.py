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

from tools.semantic_harness.studio import authoring
from .dataset_catalog import (
    DATASET_SOURCE_SPECS,
    WORKFLOW_DATASET_KINDS,
    SemanticDatasetCatalog,
)
from .interaction_generation import SemanticInteractionAuthoring
from .blocks import SemanticBlockRegistry
from .codeblocks import validate_codeblock_document
from .dataset_adapters import preview_dataset_adapter, promote_reviewed_candidates
from ..studio.interaction_explorer import build_interaction_rows, search_interactions


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
        self.dataset_catalog = SemanticDatasetCatalog(
            self.repository,
            self.runtime_root,
        )
        self.block_registry = SemanticBlockRegistry(
            self.repository,
            DATASET_SOURCE_SPECS,
        )
        self.interaction_authoring = SemanticInteractionAuthoring(
            self.dataset_catalog,
            self.block_registry,
            self.repository,
            self.runtime_root,
        )

    def list_dataset_sources(self) -> list[dict[str, Any]]:
        return self.dataset_catalog.list_dataset_sources()

    def list_workflow_datasets(self) -> list[dict[str, Any]]:
        return self.dataset_catalog.list_workflow_datasets()

    def _dataset_spec(self, source_id: str) -> dict[str, Any]:
        return self.dataset_catalog._dataset_spec(source_id)

    def _dataset_path(self, source_id: str) -> Path:
        return self.dataset_catalog._dataset_path(source_id)

    def load_dataset_document(self, source_id: str) -> dict[str, Any]:
        return self.dataset_catalog.load_dataset_document(source_id)

    def search_dataset(
        self,
        query: str = "",
        *,
        source_id: str | None = None,
        limit: int = 64,
    ) -> list[dict[str, Any]]:
        return self.dataset_catalog.search_dataset(
            query,
            source_id=source_id,
            limit=limit,
        )

    def preview_dataset_edit(
        self,
        source_id: str,
        document: dict[str, Any],
    ) -> dict[str, Any]:
        return self.dataset_catalog.preview_dataset_edit(source_id, document)

    def write_dataset_document(
        self,
        source_id: str,
        document: dict[str, Any],
    ) -> dict[str, Any]:
        return self.dataset_catalog.write_dataset_document(source_id, document)
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
        return self.interaction_authoring.validate_workflow_selection(
            source_id,
            block_ids,
            production_catalog=production_catalog,
        )

    def validate_interaction_spec(
        self,
        spec: dict[str, Any],
        *,
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.interaction_authoring.validate_interaction_spec(
            spec,
            production_catalog=production_catalog,
        )

    def edit_interaction_graph(
        self,
        spec: dict[str, Any],
        operation: str,
        *,
        production_catalog: dict[str, Any] | None = None,
        **kwargs: Any,
    ) -> dict[str, Any]:
        return self.interaction_authoring.edit_interaction_graph(
            spec,
            operation,
            production_catalog=production_catalog,
            **kwargs,
        )

    def _semantic_preview_artifacts(
        self,
        compiled: dict[str, Any],
        source_document: dict[str, Any],
        source_path: Path,
    ) -> dict[str, Any]:
        return self.interaction_authoring._semantic_preview_artifacts(
            compiled, source_document, source_path
        )

    def _dialogue_preview_artifacts(
        self,
        compiled: dict[str, Any],
        source_document: dict[str, Any],
        source_path: Path,
    ) -> dict[str, Any]:
        return self.interaction_authoring._dialogue_preview_artifacts(
            compiled, source_document, source_path
        )

    def preview_interaction_spec(
        self,
        spec: dict[str, Any],
        *,
        source_id: str = "semantic_definitions",
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.interaction_authoring.preview_interaction_spec(
            spec,
            source_id=source_id,
            production_catalog=production_catalog,
        )

    def generate_interaction_spec(
        self,
        spec: dict[str, Any],
        *,
        approved: bool,
        source_id: str = "semantic_definitions",
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.interaction_authoring.generate_interaction_spec(
            spec,
            approved=approved,
            source_id=source_id,
            production_catalog=production_catalog,
        )

    def preview_interaction_collection(
        self,
        collection: dict[str, Any],
        *,
        source_id: str = "semantic_definitions",
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.interaction_authoring.preview_interaction_collection(
            collection,
            source_id=source_id,
            production_catalog=production_catalog,
        )

    def generate_interaction_collection(
        self,
        collection: dict[str, Any],
        *,
        approved: bool,
        source_id: str = "semantic_definitions",
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.interaction_authoring.generate_interaction_collection(
            collection,
            approved=approved,
            source_id=source_id,
            production_catalog=production_catalog,
        )

    def preview_workflow(
        self,
        source_id: str,
        block_ids: list[str],
        *,
        production_catalog: dict[str, Any] | None = None,
        interaction_spec: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.interaction_authoring.preview_workflow(
            source_id,
            block_ids,
            production_catalog=production_catalog,
            interaction_spec=interaction_spec,
        )

    def generate_workflow(
        self,
        source_id: str,
        block_ids: list[str],
        *,
        approved: bool,
        production_catalog: dict[str, Any] | None = None,
        interaction_spec: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        return self.interaction_authoring.generate_workflow(
            source_id,
            block_ids,
            approved=approved,
            production_catalog=production_catalog,
            interaction_spec=interaction_spec,
        )
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
