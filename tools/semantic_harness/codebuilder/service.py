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

from . import authoring
from .dataset_catalog import (
    DATASET_SOURCE_SPECS,
    WORKFLOW_DATASET_KINDS,
    SemanticDatasetCatalog,
)
from .interaction_generation import SemanticInteractionAuthoring
from .blocks import SemanticBlockRegistry
from .codeblocks import validate_codeblock_document
from .dataset_adapters import preview_dataset_adapter, promote_reviewed_candidates
from .interaction_explorer import build_interaction_rows, search_interactions
from .dialogue_content import (
    CONTENT_SOURCE_RELATIVE,
    compile_dialogue_content,
    dialogue_content_source_fingerprint,
    derived_canonical_concept,
    load_dialogue_content_source,
    write_dialogue_content_source,
)
from .lexicon_compiler import CompileError


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

    @property
    def dialogue_content_source_path(self) -> Path:
        return self.repository / CONTENT_SOURCE_RELATIVE

    def preview_dialogue_content_source(self) -> dict[str, Any]:
        return authoring.preview_dialogue_content_source(
            self.dialogue_content_source_path,
            repository=self.repository,
        )

    def generate_dialogue_content_source(self) -> dict[str, Any]:
        return authoring.generate_dialogue_content_source(
            self.dialogue_content_source_path,
            repository=self.repository,
        )

    def _dialogue_content_document(self) -> dict[str, Any]:
        return load_dialogue_content_source(self.dialogue_content_source_path)

    @staticmethod
    def _family_id(family: dict[str, Any]) -> str:
        return str(
            family.get("id")
            or "phrase." + str(family.get("semanticTemplateID") or "unknown")
        )

    @classmethod
    def _content_item(
        cls, document: dict[str, Any], content_id: str
    ) -> dict[str, Any] | None:
        for family in document.get("phraseFamilies", []):
            if isinstance(family, dict) and cls._family_id(family) == content_id:
                item = {"kind": "phraseFamily", **family}
                item["id"] = cls._family_id(family)
                item["canonicalConcept"] = item.get("canonicalConcept") or derived_canonical_concept(
                    str(item.get("semanticTemplateID") or item["id"])
                )
                if not item.get("contentOwner"):
                    groups = document.get("groups") or {}
                    group = groups.get(item.get("group"))
                    if isinstance(group, dict):
                        item["contentOwner"] = group.get("contentOwner")
                return item
        for choice in document.get("playerChoices", []):
            if isinstance(choice, dict) and choice.get("id") == content_id:
                item = {"kind": "playerChoice", **choice}
                item["canonicalConcept"] = item.get("canonicalConcept") or derived_canonical_concept(
                    str(item["id"])
                )
                return item
        return None

    @staticmethod
    def _content_structure(item: dict[str, Any]) -> dict[str, Any]:
        """Return the fields that Dialogue Content is never allowed to edit."""
        value = json.loads(json.dumps(item, ensure_ascii=False))
        kind = value.get("kind")
        value.pop("kind", None)
        for metadata_key in ("sourcePath", "sourceFingerprint", "verifiedOwner"):
            value.pop(metadata_key, None)
        if kind == "phraseFamily":
            for phrases in value.get("styles", {}).values():
                for phrase in phrases:
                    if isinstance(phrase, dict):
                        phrase.pop("translations", None)
        else:
            value.pop("labelTranslations", None)
            value.pop("choiceTranslations", None)
        return value

    def list_dialogue_content(self) -> list[dict[str, Any]]:
        document = self._dialogue_content_document()
        fingerprint = dialogue_content_source_fingerprint(
            self.dialogue_content_source_path
        )
        groups = document.get("groups") or {}
        rows: list[dict[str, Any]] = []
        for family in document.get("phraseFamilies", []):
            if not isinstance(family, dict):
                continue
            rows.append({
                "id": self._family_id(family),
                "kind": "phraseFamily",
                "semanticTemplateID": family.get("semanticTemplateID"),
                "canonicalConcept": family.get("canonicalConcept")
                or derived_canonical_concept(str(family.get("semanticTemplateID") or "unknown")),
                "group": family.get("group"),
                "contentOwner": family.get("contentOwner")
                or (
                    groups.get(family.get("group"), {}).get("contentOwner")
                    if isinstance(groups.get(family.get("group")), dict)
                    else None
                ),
                "styles": sorted(family.get("styles", {})),
                "sourcePath": str(self.dialogue_content_source_path),
                "sourceFingerprint": fingerprint,
                "verifiedOwner": "CodeBuilder → Dialogue Content Registry",
            })
        for choice in document.get("playerChoices", []):
            if not isinstance(choice, dict):
                continue
            rows.append({
                "id": choice.get("id"),
                "kind": "playerChoice",
                "canonicalConcept": choice.get("canonicalConcept")
                or derived_canonical_concept(str(choice.get("id") or "unknown")),
                "route": choice.get("route"),
                "hubID": choice.get("hubID"),
                "sourcePath": str(self.dialogue_content_source_path),
                "sourceFingerprint": fingerprint,
                "verifiedOwner": "CodeBuilder → Dialogue Content Registry",
            })
        return rows

    def load_dialogue_content(self, content_id: str) -> dict[str, Any]:
        document = self._dialogue_content_document()
        item = self._content_item(document, str(content_id))
        if item is None:
            raise KeyError(f"unknown dialogue content id: {content_id}")
        item["sourcePath"] = str(self.dialogue_content_source_path)
        item["sourceFingerprint"] = dialogue_content_source_fingerprint(
            self.dialogue_content_source_path
        )
        item["verifiedOwner"] = "CodeBuilder → Dialogue Content Registry"
        return item

    def _apply_dialogue_content_edit(
        self,
        content_id: str,
        edited_item: dict[str, Any],
        *,
        expected_source_fingerprint: str | None = None,
    ) -> tuple[dict[str, Any] | None, dict[str, Any]]:
        path = self.dialogue_content_source_path
        actual_fingerprint = dialogue_content_source_fingerprint(path)
        if expected_source_fingerprint and expected_source_fingerprint != actual_fingerprint:
            return None, {
                "ok": False,
                "type": "dialogue_content_edit_preview",
                "contentID": content_id,
                "stale": True,
                "reason": "source_fingerprint_mismatch",
                "expectedSourceFingerprint": expected_source_fingerprint,
                "sourceFingerprint": actual_fingerprint,
                "writes": [],
            }
        if not isinstance(edited_item, dict):
            return None, {
                "ok": False,
                "type": "dialogue_content_edit_preview",
                "contentID": content_id,
                "diagnostics": [{"severity": "error", "message": "content edit must be an object"}],
                "writes": [],
            }
        document = self._dialogue_content_document()
        current = self._content_item(document, content_id)
        if current is None:
            return None, {
                "ok": False,
                "type": "dialogue_content_edit_preview",
                "contentID": content_id,
                "diagnostics": [{"severity": "error", "message": "unknown dialogue content id"}],
                "writes": [],
            }
        if self._content_structure(current) != self._content_structure(edited_item):
            return None, {
                "ok": False,
                "type": "dialogue_content_edit_preview",
                "contentID": content_id,
                "structuralChange": True,
                "diagnostics": [{
                    "severity": "error",
                    "message": "structural fields are locked; edit phrase or verified player-facing wording only",
                }],
                "writes": [],
            }
        updated = json.loads(json.dumps(document, ensure_ascii=False))
        if current.get("kind") == "phraseFamily":
            target = next(
                item for item in updated["phraseFamilies"]
                if self._family_id(item) == content_id
            )
            edited_styles = edited_item.get("styles", {})
            for style, phrases in target.get("styles", {}).items():
                edited_phrases = edited_styles.get(style, [])
                for index, phrase in enumerate(phrases):
                    if index < len(edited_phrases):
                        edited_phrase = edited_phrases[index]
                        if isinstance(edited_phrase, dict):
                            phrase["translations"] = edited_phrase.get("translations")
        else:
            target = next(item for item in updated["playerChoices"] if item["id"] == content_id)
            target["labelTranslations"] = edited_item.get("labelTranslations")
            target["choiceTranslations"] = edited_item.get("choiceTranslations")
        return updated, {
            "ok": True,
            "type": "dialogue_content_edit_preview",
            "contentID": content_id,
            "kind": current.get("kind"),
            "stale": False,
            "structuralLocked": True,
            "sourceFingerprint": actual_fingerprint,
            "newContentFingerprint": compile_dialogue_content(updated)["contentFingerprint"],
            "contentBefore": json.loads(json.dumps(current, ensure_ascii=False)),
            "contentAfter": json.loads(json.dumps(edited_item, ensure_ascii=False)),
            "writes": [],
        }

    def preview_dialogue_content_edit(
        self,
        content_id: str,
        edited_item: dict[str, Any],
        *,
        expected_source_fingerprint: str | None = None,
    ) -> dict[str, Any]:
        try:
            updated, report = self._apply_dialogue_content_edit(
                content_id,
                edited_item,
                expected_source_fingerprint=expected_source_fingerprint,
            )
            if updated is None or report.get("ok") is not True:
                return report
            compiled = compile_dialogue_content(updated)
        except (OSError, ValueError, TypeError, CompileError) as error:
            return {
                "ok": False,
                "type": "dialogue_content_edit_preview",
                "contentID": content_id,
                "diagnostics": [{"severity": "error", "message": str(error)}],
                "writes": [],
            }
        return {
            **report,
            "diagnostics": [],
            "previewOnly": True,
            "effectFree": True,
            "contentFingerprint": compiled["contentFingerprint"],
            "generatedPaths": [
                str(self.repository / path)
                for path in (
                    "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/"
                    "Semantics/Generated/DialogueContent/Registry.lua",
                    "Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/Semantic/DialogueContent.json",
                    "Contents/mods/ProjectHoomans/common/media/translation/TL/Conversation/Semantic/DialogueContent.json",
                )
            ],
        }

    def write_dialogue_content_edit(
        self,
        content_id: str,
        edited_item: dict[str, Any],
        *,
        expected_source_fingerprint: str | None = None,
    ) -> dict[str, Any]:
        updated, report = self._apply_dialogue_content_edit(
            content_id,
            edited_item,
            expected_source_fingerprint=expected_source_fingerprint,
        )
        if updated is None or report.get("ok") is not True:
            return report
        try:
            compile_dialogue_content(updated)
            written = write_dialogue_content_source(
                self.dialogue_content_source_path,
                updated,
            )
        except (OSError, ValueError, TypeError, CompileError) as error:
            return {
                **report,
                "ok": False,
                "diagnostics": [{"severity": "error", "message": str(error)}],
                "writes": [],
            }
        return {
            **report,
            "previewOnly": False,
            "effectFree": False,
            "writes": [str(path) for path in written],
            "reloadedBy": "caller_restart_required",
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
