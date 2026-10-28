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
    compile_dialogue_content,
    derived_canonical_concept,
)
from .conversation_compiler import (
    CONVERSATION_MANIFEST_RELATIVE,
    CONVERSATION_SOURCE_RELATIVE,
    compile_conversation_sources,
    conversation_record,
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

    def preview_dataset_generation(self, source_id: str) -> dict[str, Any]:
        """Validate a logical canonical dataset through the full Conversation plan."""
        document = self.load_dataset_document(source_id)
        report = self.preview_dataset_edit(source_id, document)
        if report.get("ok") is True and self._dataset_spec(source_id)["kind"] in {
            "semantic", "dialogue"
        }:
            report.update(
                self.interaction_authoring._conversation_preview_artifacts(
                    source_id, document
                )
            )
        return report

    @property
    def dialogue_content_source_path(self) -> Path:
        """Return the manifest, never a generated compatibility snapshot."""
        return self.repository / CONVERSATION_MANIFEST_RELATIVE

    def _conversation_model(self) -> dict[str, Any]:
        return compile_conversation_sources(
            self.repository,
            runtime_root=self.runtime_root,
        )

    @staticmethod
    def _content_shard_report(model: dict[str, Any], source_shard: str) -> dict[str, Any]:
        for report in model.get("shards", []):
            if report.get("path") == source_shard:
                return report
        raise KeyError(f"unknown Conversation content shard: {source_shard}")

    def _content_source_path(self, source_shard: str) -> Path:
        return self.repository / CONVERSATION_SOURCE_RELATIVE / Path(source_shard)

    def _conversation_content_document(self, model: dict[str, Any]) -> dict[str, Any]:
        """Merge authored content shards in memory without creating an aggregate file."""
        groups: dict[str, Any] = {}
        phrase_families: list[dict[str, Any]] = []
        player_choices: list[dict[str, Any]] = []
        source_metadata: dict[str, Any] | None = None

        for source_path, document in sorted(
            model.get("_source_documents", {}).items()
        ):
            if not str(source_path).startswith("content/"):
                continue
            if not isinstance(document, dict):
                continue
            if source_metadata is None and isinstance(document.get("source"), dict):
                source_metadata = json.loads(
                    json.dumps(document["source"], ensure_ascii=False)
                )
            for group_id, definition in (document.get("groups") or {}).items():
                existing = groups.get(group_id)
                if existing is not None and existing != definition:
                    raise CompileError(
                        f"Conversation content group {group_id} conflicts across shards"
                    )
                groups[group_id] = json.loads(
                    json.dumps(definition, ensure_ascii=False)
                )
            phrase_families.extend(
                json.loads(
                    json.dumps(document.get("phraseFamilies", []), ensure_ascii=False)
                )
            )
            player_choices.extend(
                json.loads(
                    json.dumps(document.get("playerChoices", []), ensure_ascii=False)
                )
            )

        phrase_families.sort(
            key=lambda item: str(item.get("semanticTemplateID") or item.get("id") or "")
        )
        player_choices.sort(key=lambda item: str(item.get("id") or ""))
        return {
            "schemaVersion": 2,
            "source": source_metadata or {"owner": "ProjectHoomans"},
            "groups": {key: groups[key] for key in sorted(groups)},
            "phraseFamilies": phrase_families,
            "playerChoices": player_choices,
        }

    def _raw_content_item(
        self,
        model: dict[str, Any],
        content_id: str,
    ) -> tuple[dict[str, Any], dict[str, Any], dict[str, Any]] | None:
        location = conversation_record(model, content_id)
        if not isinstance(location, dict) or location.get("kind") != "content":
            return None
        source_shard = str(location["sourceShard"])
        source_document = model.get("_source_documents", {}).get(source_shard)
        if not isinstance(source_document, dict):
            return None
        item = self._content_item(source_document, content_id)
        if item is None:
            return None
        return item, source_document, location

    def preview_dialogue_content_source(self) -> dict[str, Any]:
        try:
            model = self._conversation_model()
        except (OSError, ValueError, TypeError, CompileError) as error:
            return {
                "ok": False,
                "type": "conversation_compile_preview",
                "previewOnly": True,
                "effectFree": True,
                "sourcePath": str(self.dialogue_content_source_path),
                "diagnostics": [{"severity": "error", "message": str(error)}],
                "writes": [],
            }
        return {
            "ok": True,
            "type": "conversation_compile_preview",
            "schema": model["schema"],
            "repository": str(self.repository),
            "sourcePath": str(self.dialogue_content_source_path),
            "previewOnly": True,
            "effectFree": True,
            "wholeModelFingerprint": model["wholeModelFingerprint"],
            "phraseFamilyCount": len(model["content"]["phraseFamilies"]),
            "phraseCount": sum(
                len(phrases)
                for family in model["content"]["phraseFamilies"]
                for phrases in family["styles"].values()
            ),
            "playerChoiceCount": len(model["content"]["playerChoices"]),
            "patternCount": len(model["dialogue"]["patterns"]),
            "flowCount": len(model["semantic"]["flows"]),
            "uiSuggestionCount": len(model["ui"]),
            "shards": model["shards"],
            "writes": [],
        }

    def generate_dialogue_content_source(self) -> dict[str, Any]:
        preview = self.preview_dialogue_content_source()
        if preview.get("ok") is not True:
            return preview
        try:
            from .build import write_conversation_output

            model = self._conversation_model()
            written = write_conversation_output(self.repository, model)
        except (OSError, ValueError, TypeError, CompileError) as error:
            return {
                **preview,
                "ok": False,
                "generationApproved": True,
                "diagnostics": [{"severity": "error", "message": str(error)}],
                "writes": [],
            }
        return {
            **self.preview_dialogue_content_source(),
            "generationApproved": True,
            "writes": [str(path) for path in written],
            "reloadedBy": "caller_restart_required",
        }

    def _dialogue_content_document(self) -> dict[str, Any]:
        return self._conversation_content_document(self._conversation_model())

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
        for metadata_key in (
            "sourcePath",
            "sourceShard",
            "sourceFingerprint",
            "generatedModule",
            "verifiedOwner",
        ):
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
        model = self._conversation_model()
        document = self._conversation_content_document(model)
        groups = document.get("groups") or {}
        rows: list[dict[str, Any]] = []
        for family in document.get("phraseFamilies", []):
            if not isinstance(family, dict):
                continue
            location = conversation_record(
                model, self._family_id(family)
            ) or {}
            source_shard = str(location.get("sourceShard") or "")
            report = self._content_shard_report(model, source_shard)
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
                "sourcePath": str(self._content_source_path(source_shard)),
                "sourceShard": source_shard,
                "sourceFingerprint": report["fingerprint"],
                "generatedModule": "PNC/Semantics/Generated/Conversation/Content",
                "verifiedOwner": "CodeBuilder → Conversation Registry",
            })
        for choice in document.get("playerChoices", []):
            if not isinstance(choice, dict):
                continue
            location = conversation_record(model, str(choice.get("id") or "")) or {}
            source_shard = str(location.get("sourceShard") or "")
            report = self._content_shard_report(model, source_shard)
            rows.append({
                "id": choice.get("id"),
                "kind": "playerChoice",
                "canonicalConcept": choice.get("canonicalConcept")
                or derived_canonical_concept(str(choice.get("id") or "unknown")),
                "route": choice.get("route"),
                "hubID": choice.get("hubID"),
                "sourcePath": str(self._content_source_path(source_shard)),
                "sourceShard": source_shard,
                "sourceFingerprint": report["fingerprint"],
                "generatedModule": "PNC/Semantics/Generated/Conversation/Content/PlayerChoices",
                "verifiedOwner": "CodeBuilder → Conversation Registry",
            })
        return sorted(rows, key=lambda item: str(item.get("id") or ""))

    def load_dialogue_content(self, content_id: str) -> dict[str, Any]:
        model = self._conversation_model()
        result = self._raw_content_item(model, str(content_id))
        if result is None:
            raise KeyError(f"unknown dialogue content id: {content_id}")
        item, _source_document, location = result
        source_shard = str(location["sourceShard"])
        report = self._content_shard_report(model, source_shard)
        item["sourcePath"] = str(self.dialogue_content_source_path)
        item["sourceShard"] = source_shard
        item["sourcePath"] = str(self._content_source_path(source_shard))
        item["sourceFingerprint"] = report["fingerprint"]
        item["generatedModule"] = "PNC/Semantics/Generated/Conversation/Content"
        item["verifiedOwner"] = "CodeBuilder → Conversation Registry"
        return item

    def _apply_dialogue_content_edit(
        self,
        content_id: str,
        edited_item: dict[str, Any],
        *,
        expected_source_fingerprint: str | None = None,
    ) -> tuple[dict[str, Any] | None, dict[str, Any]]:
        model = self._conversation_model()
        result = self._raw_content_item(model, str(content_id))
        if result is None:
            return None, {
                "ok": False,
                "type": "dialogue_content_edit_preview",
                "contentID": content_id,
                "diagnostics": [{"severity": "error", "message": "unknown dialogue content id"}],
                "writes": [],
            }
        current, source_document, location = result
        source_shard = str(location["sourceShard"])
        shard_report = self._content_shard_report(model, source_shard)
        actual_fingerprint = str(shard_report["fingerprint"])
        if expected_source_fingerprint and expected_source_fingerprint != actual_fingerprint:
            return None, {
                "ok": False,
                "type": "dialogue_content_edit_preview",
                "contentID": content_id,
                "stale": True,
                "reason": "source_fingerprint_mismatch",
                "expectedSourceFingerprint": expected_source_fingerprint,
                "sourceFingerprint": actual_fingerprint,
                "sourceShard": source_shard,
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
        updated_shard = json.loads(json.dumps(source_document, ensure_ascii=False))
        if current.get("kind") == "phraseFamily":
            target = next(
                item for item in updated_shard["phraseFamilies"]
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
            target = next(item for item in updated_shard["playerChoices"] if item["id"] == content_id)
            target["labelTranslations"] = edited_item.get("labelTranslations")
            target["choiceTranslations"] = edited_item.get("choiceTranslations")
        aggregate = self._conversation_content_document(model)
        if current.get("kind") == "phraseFamily":
            aggregate_target = next(
                item for item in aggregate["phraseFamilies"]
                if self._family_id(item) == content_id
            )
            aggregate_target.clear()
            aggregate_target.update(json.loads(json.dumps(target, ensure_ascii=False)))
        else:
            aggregate_target = next(
                item for item in aggregate["playerChoices"]
                if item["id"] == content_id
            )
            aggregate_target.clear()
            aggregate_target.update(json.loads(json.dumps(target, ensure_ascii=False)))
        compiled_aggregate = compile_dialogue_content(aggregate)
        return aggregate, {
            "ok": True,
            "type": "dialogue_content_edit_preview",
            "contentID": content_id,
            "kind": current.get("kind"),
            "stale": False,
            "structuralLocked": True,
            "sourceShard": source_shard,
            "sourceFingerprint": actual_fingerprint,
            "newContentFingerprint": compiled_aggregate["contentFingerprint"],
            "contentBefore": json.loads(json.dumps(current, ensure_ascii=False)),
            "contentAfter": json.loads(json.dumps(edited_item, ensure_ascii=False)),
            "_updatedShard": updated_shard,
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
            **{
                key: value for key, value in report.items()
                if not key.startswith("_")
            },
            "diagnostics": [],
            "contentFingerprint": compiled["contentFingerprint"],
            "generatedPaths": [
                str(self.repository / path)
                for path in (
                    "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/"
                    "Semantics/Generated/Conversation/Registry.lua",
                    "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/"
                    "Semantics/Generated/Conversation/Manifest.lua",
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
            updated_shard = report.get("_updatedShard")
            source_shard = str(report.get("sourceShard") or "")
            if not isinstance(updated_shard, dict) or not source_shard:
                raise CompileError("Conversation edit did not resolve an owning source shard")
            source_path = self._content_source_path(source_shard)
            source_path.write_text(
                json.dumps(updated_shard, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
                encoding="utf-8",
                newline="\n",
            )
            from .build import write_conversation_output

            model = self._conversation_model()
            generated = write_conversation_output(self.repository, model)
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
            "writes": [str(source_path), *(str(path) for path in generated)],
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

    def preview_interaction_spec(
        self,
        spec: dict[str, Any],
        *,
        source_id: str = "semantic_flows",
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
        source_id: str = "semantic_flows",
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
        source_id: str = "semantic_flows",
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
        source_id: str = "semantic_flows",
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
