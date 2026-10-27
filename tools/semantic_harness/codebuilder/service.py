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
    MAX_PHRASES_PER_STYLE,
    STYLES,
    compile_dialogue_content,
    dialogue_content_source_fingerprint,
    derived_canonical_concept,
    load_dialogue_content_source,
    write_dialogue_content_source,
)
from .conversation_ui import (
    UI_REGISTRY_RUNTIME_RELATIVE,
    compile_conversation_ui,
    conversation_ui_source_fingerprint,
    conversation_ui_source_path_from_manifest,
    load_conversation_ui_source,
    write_conversation_ui_output,
    write_conversation_ui_source,
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

    @property
    def conversation_ui_source_path(self) -> Path:
        return conversation_ui_source_path_from_manifest(
            self.dialogue_content_source_path
        )

    def inspect_conversation_ui(
        self,
        node_id: str | None = None,
    ) -> dict[str, Any]:
        """Return a bounded registry read for GUI and agent callers."""

        path = self.conversation_ui_source_path
        document = load_conversation_ui_source(path)
        compiled = compile_conversation_ui(document)
        if node_id is None:
            nodes = compiled["nodes"]
        else:
            nodes = [
                node for node in compiled["nodes"]
                if node["id"] == str(node_id)
            ]
            if not nodes:
                return {
                    "ok": False,
                    "type": "conversation_ui_inspect",
                    "nodeID": str(node_id),
                    "diagnostics": [{
                        "severity": "error",
                        "message": f"unknown Conversation UI node: {node_id}",
                    }],
                    "writes": [],
                    "effectFree": True,
                }
        return {
            "ok": True,
            "type": "conversation_ui_inspect",
            "sourcePath": str(path),
            "sourceFingerprint": conversation_ui_source_fingerprint(path),
            "schema": compiled["schema"],
            "nodeCount": len(compiled["nodes"]),
            "nodes": nodes,
            "generatedRuntimePath": str(
                self.repository / UI_REGISTRY_RUNTIME_RELATIVE
            ),
            "diagnostics": [],
            "writes": [],
            "effectFree": True,
        }

    @staticmethod
    def _conversation_ui_edit(
        document: dict[str, Any],
        operation: str,
        arguments: dict[str, Any],
    ) -> dict[str, Any]:
        updated = json.loads(json.dumps(document, ensure_ascii=False))
        raw_nodes = updated.get("nodes")
        if not isinstance(raw_nodes, list):
            raise CompileError("conversation UI registry nodes must be a list")
        by_id = {
            str(node.get("id")): node for node in raw_nodes
            if isinstance(node, dict)
        }

        def require_node(value: Any, label: str) -> dict[str, Any]:
            node_id = str(value or "")
            node = by_id.get(node_id)
            if node is None:
                raise CompileError(f"{label} references unknown node: {node_id}")
            return node

        def children(parent: dict[str, Any]) -> list[dict[str, Any]]:
            value = parent.setdefault("children", [])
            if not isinstance(value, list):
                raise CompileError(f"{parent.get('id')} children must be a list")
            return value

        operation = str(operation or "").strip().lower().replace("-", "_")
        if operation == "add_child":
            parent = require_node(arguments.get("parentID"), "parentID")
            child = require_node(arguments.get("childID"), "childID")
            if child.get("parentID") not in (None, ""):
                raise CompileError(
                    f"child {child.get('id')} is already attached; use move_child"
                )
            parent_children = children(parent)
            if any(item.get("nodeID") == child["id"] for item in parent_children):
                raise CompileError(f"child {child['id']} is already a member")
            order = arguments.get("order")
            if order is None:
                order = max(
                    [int(item.get("order", 0)) for item in parent_children] or [0]
                ) + 10
            if isinstance(order, bool) or not isinstance(order, int):
                raise CompileError("Conversation UI child order must be an integer")
            child["parentID"] = parent["id"]
            child["order"] = order
            parent_children.append({"nodeID": child["id"], "order": order})
        elif operation == "remove_child":
            child = require_node(arguments.get("childID"), "childID")
            parent_id = arguments.get("parentID") or child.get("parentID")
            parent = require_node(parent_id, "parentID")
            parent_children = children(parent)
            before = len(parent_children)
            parent["children"] = [
                item for item in parent_children
                if item.get("nodeID") != child["id"]
            ]
            if len(parent["children"]) == before:
                raise CompileError(f"child {child['id']} is not a member")
            child["parentID"] = None
        elif operation == "move_child":
            child = require_node(arguments.get("childID"), "childID")
            old_parent_id = child.get("parentID")
            old_parent = require_node(old_parent_id, "parentID")
            new_parent = require_node(arguments.get("newParentID"), "newParentID")
            old_parent["children"] = [
                item for item in children(old_parent)
                if item.get("nodeID") != child["id"]
            ]
            new_children = children(new_parent)
            if any(item.get("nodeID") == child["id"] for item in new_children):
                raise CompileError(f"child {child['id']} is already a member")
            order = arguments.get("order", child.get("order", 10))
            if isinstance(order, bool) or not isinstance(order, int):
                raise CompileError("Conversation UI child order must be an integer")
            child["parentID"] = new_parent["id"]
            child["order"] = order
            new_children.append({"nodeID": child["id"], "order": order})
        elif operation == "reorder_child":
            child = require_node(arguments.get("childID"), "childID")
            parent = require_node(
                arguments.get("parentID") or child.get("parentID"),
                "parentID",
            )
            order = arguments.get("order")
            if isinstance(order, bool) or not isinstance(order, int):
                raise CompileError("Conversation UI child order must be an integer")
            found = False
            for item in children(parent):
                if item.get("nodeID") == child["id"]:
                    item["order"] = order
                    found = True
                    break
            if not found:
                raise CompileError(f"child {child['id']} is not a member")
            child["order"] = order
        elif operation == "update_node":
            node = require_node(arguments.get("nodeID"), "nodeID")
            if any(key in arguments for key in ("providerRef", "semanticDestination")):
                raise CompileError(
                    "providerRef and semanticDestination are production-owned and locked"
                )
            if "contentID" in arguments:
                node["contentID"] = arguments["contentID"]
            if "order" in arguments:
                order = arguments["order"]
                if isinstance(order, bool) or not isinstance(order, int):
                    raise CompileError("Conversation UI node order must be an integer")
                node["order"] = order
                parent_id = node.get("parentID")
                if parent_id in by_id:
                    for item in children(by_id[parent_id]):
                        if item.get("nodeID") == node["id"]:
                            item["order"] = order
            if "presentationGroup" in arguments:
                node["presentationGroup"] = arguments["presentationGroup"]
        else:
            raise CompileError(f"unsupported Conversation UI operation: {operation}")
        return updated

    def preview_conversation_ui_operation(
        self,
        operation: str,
        *,
        expected_source_fingerprint: str | None = None,
        **arguments: Any,
    ) -> dict[str, Any]:
        """Preview a structural UI edit without writing source or runtime files."""

        path = self.conversation_ui_source_path
        actual_fingerprint = conversation_ui_source_fingerprint(path)
        base = {
            "ok": False,
            "type": "conversation_ui_edit_preview",
            "operation": operation,
            "sourcePath": str(path),
            "sourceFingerprint": actual_fingerprint,
            "writes": [],
            "previewOnly": True,
            "effectFree": True,
        }
        if (
            expected_source_fingerprint
            and expected_source_fingerprint != actual_fingerprint
        ):
            return {
                **base,
                "stale": True,
                "reason": "source_fingerprint_mismatch",
                "expectedSourceFingerprint": expected_source_fingerprint,
                "diagnostics": [{
                    "severity": "error",
                    "message": "Conversation UI source changed since it was inspected",
                }],
            }
        try:
            document = load_conversation_ui_source(path)
            updated = self._conversation_ui_edit(document, operation, arguments)
            compiled = compile_conversation_ui(updated)
        except (OSError, ValueError, TypeError, CompileError) as error:
            return {
                **base,
                "diagnostics": [{"severity": "error", "message": str(error)}],
            }
        return {
            **base,
            "ok": True,
            "stale": False,
            "diagnostics": [],
            "document": updated,
            "nodeCount": len(compiled["nodes"]),
            "newSourceFingerprint": compiled["contentFingerprint"],
            "generatedRuntimePath": str(
                self.repository / UI_REGISTRY_RUNTIME_RELATIVE
            ),
        }

    def write_conversation_ui_operation(
        self,
        operation: str,
        *,
        expected_source_fingerprint: str | None = None,
        **arguments: Any,
    ) -> dict[str, Any]:
        """Apply one explicit UI edit after the same preview/stale validation."""

        report = self.preview_conversation_ui_operation(
            operation,
            expected_source_fingerprint=expected_source_fingerprint,
            **arguments,
        )
        if not report.get("ok"):
            return report
        path = self.conversation_ui_source_path
        try:
            write_conversation_ui_source(path, report["document"])
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
            "writes": [str(path)],
            "reloadedBy": "caller_compile_required",
        }

    def validate_conversation_ui(
        self,
        document: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Return machine-readable validation without any side effects."""

        path = self.conversation_ui_source_path
        try:
            source = document if document is not None else load_conversation_ui_source(path)
            compiled = compile_conversation_ui(source)
        except (OSError, ValueError, TypeError, CompileError) as error:
            return {
                "ok": False,
                "type": "conversation_ui_validation",
                "diagnostics": [{"severity": "error", "message": str(error)}],
                "writes": [],
                "effectFree": True,
            }
        return {
            "ok": True,
            "type": "conversation_ui_validation",
            "nodeCount": len(compiled["nodes"]),
            "sourcePath": str(path),
            "sourceFingerprint": conversation_ui_source_fingerprint(path)
            if document is None else compiled["contentFingerprint"],
            "diagnostics": [],
            "writes": [],
            "effectFree": True,
        }

    def compile_conversation_ui(self) -> dict[str, Any]:
        """Explicitly compile the canonical UI source and generated runtime registry."""
        path = self.conversation_ui_source_path
        try:
            compiled = compile_conversation_ui(load_conversation_ui_source(path))
            output = write_conversation_ui_output(self.repository, compiled)
        except (OSError, ValueError, TypeError, CompileError) as error:
            return {
                "ok": False,
                "type": "conversation_ui_compile",
                "diagnostics": [{"severity": "error", "message": str(error)}],
                "writes": [],
                "effectFree": False,
            }
        return {
            "ok": True,
            "type": "conversation_ui_compile",
            "sourcePath": str(path),
            "runtimePath": str(output),
            "nodeCount": len(compiled["nodes"]),
            "sourceFingerprint": conversation_ui_source_fingerprint(path),
            "writes": [str(output)],
            "effectFree": False,
        }

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

    def inspect_dialogue_variants(
        self,
        content_id: str,
        *,
        limit: int = MAX_PHRASES_PER_STYLE,
    ) -> dict[str, Any]:
        """Return one bounded phrase-family variant page for GUI/agent callers."""
        if isinstance(limit, bool) or not isinstance(limit, int) or not 1 <= limit <= MAX_PHRASES_PER_STYLE:
            return {
                "ok": False,
                "type": "dialogue_variants_inspect",
                "contentID": str(content_id),
                "diagnostics": [{"severity": "error", "message": "variant limit is outside the bounded range"}],
                "writes": [],
                "effectFree": True,
            }
        try:
            item = self.load_dialogue_content(str(content_id))
        except (OSError, ValueError, KeyError) as error:
            return {
                "ok": False,
                "type": "dialogue_variants_inspect",
                "contentID": str(content_id),
                "diagnostics": [{"severity": "error", "message": str(error)}],
                "writes": [],
                "effectFree": True,
            }
        if item.get("kind") != "phraseFamily":
            return {
                "ok": False,
                "type": "dialogue_variants_inspect",
                "contentID": str(content_id),
                "diagnostics": [{"severity": "error", "message": "player choices do not have phrase variants"}],
                "writes": [],
                "effectFree": True,
            }
        variants: list[dict[str, Any]] = []
        for style in STYLES:
            phrases = item.get("styles", {}).get(style, [])
            for index, phrase in enumerate(phrases[:limit]):
                variants.append({
                    "style": style,
                    "index": index,
                    "translations": json.loads(json.dumps(phrase.get("translations", {}), ensure_ascii=False)),
                })
        return {
            "ok": True,
            "type": "dialogue_variants_inspect",
            "contentID": str(content_id),
            "semanticTemplateID": item.get("semanticTemplateID"),
            "sourcePath": item.get("sourcePath"),
            "sourceFingerprint": item.get("sourceFingerprint"),
            "variants": variants,
            "variantCount": len(variants),
            "diagnostics": [],
            "writes": [],
            "effectFree": True,
        }

    @staticmethod
    def _dialogue_content_operation(
        document: dict[str, Any],
        content_id: str,
        operation: str,
        arguments: dict[str, Any],
    ) -> dict[str, Any]:
        """Apply one bounded structural phrase operation to a copied document."""
        updated = json.loads(json.dumps(document, ensure_ascii=False))
        families = updated.get("phraseFamilies", [])
        family = next(
            (
                value for value in families
                if isinstance(value, dict)
                and SemanticLabAuthoringService._family_id(value) == str(content_id)
            ),
            None,
        )
        if not isinstance(family, dict):
            raise CompileError(f"unknown dialogue content id: {content_id}")
        if not family.get("styles"):
            raise CompileError(f"{content_id} is not a phrase family")

        style = str(arguments.get("style", "neutral"))
        if style not in STYLES:
            raise CompileError(f"unsupported phrase style: {style}")
        styles = family.setdefault("styles", {})
        phrases = styles.get(style)
        if phrases is not None and not isinstance(phrases, list):
            raise CompileError(f"{content_id}.{style} must be a phrase list")

        def integer(name: str, default: int | None = None) -> int:
            value = arguments.get(name, default)
            if isinstance(value, bool) or not isinstance(value, int):
                raise CompileError(f"{name} must be an integer")
            return value

        def translations() -> dict[str, str]:
            value = arguments.get("translations")
            if not isinstance(value, dict):
                raise CompileError("translations must contain EN and TL")
            return json.loads(json.dumps(value, ensure_ascii=False))

        if operation == "add_variant":
            if phrases is None:
                raise CompileError(f"style does not exist: {style}")
            value = {"translations": translations()}
            index = arguments.get("index")
            if index is None:
                phrases.append(value)
            else:
                index = integer("index")
                if index < 0 or index > len(phrases):
                    raise CompileError("variant index is outside the bounded phrase list")
                phrases.insert(index, value)
        elif operation == "duplicate_variant":
            if phrases is None:
                raise CompileError(f"style does not exist: {style}")
            index = integer("index")
            if index < 0 or index >= len(phrases):
                raise CompileError("variant index is outside the bounded phrase list")
            value = json.loads(json.dumps(phrases[index], ensure_ascii=False))
            target = arguments.get("targetIndex", index + 1)
            if isinstance(target, bool) or not isinstance(target, int) or target < 0 or target > len(phrases):
                raise CompileError("targetIndex is outside the bounded phrase list")
            phrases.insert(target, value)
        elif operation == "delete_variant":
            if phrases is None:
                raise CompileError(f"style does not exist: {style}")
            index = integer("index")
            if index < 0 or index >= len(phrases):
                raise CompileError("variant index is outside the bounded phrase list")
            phrases.pop(index)
        elif operation == "move_variant":
            if phrases is None:
                raise CompileError(f"style does not exist: {style}")
            index = integer("index")
            target = integer("targetIndex")
            if index < 0 or index >= len(phrases) or target < 0 or target >= len(phrases):
                raise CompileError("variant move index is outside the bounded phrase list")
            value = phrases.pop(index)
            phrases.insert(target, value)
        elif operation == "add_style":
            if style in styles:
                raise CompileError(f"style already exists: {style}")
            styles[style] = [{"translations": translations()}]
        elif operation == "remove_style":
            if style not in styles:
                raise CompileError(f"style does not exist: {style}")
            styles.pop(style)
        else:
            raise CompileError(f"unsupported dialogue content operation: {operation}")
        return updated

    def _prepare_dialogue_content_operation(
        self,
        content_id: str,
        operation: str,
        *,
        expected_source_fingerprint: str | None = None,
        **arguments: Any,
    ) -> tuple[dict[str, Any] | None, dict[str, Any]]:
        path = self.dialogue_content_source_path
        actual_fingerprint = dialogue_content_source_fingerprint(path)
        base = {
            "ok": False,
            "type": "dialogue_content_operation",
            "contentID": str(content_id),
            "operation": str(operation),
            "sourcePath": str(path),
            "sourceFingerprint": actual_fingerprint,
            "writes": [],
            "previewOnly": True,
            "effectFree": True,
        }
        if expected_source_fingerprint and expected_source_fingerprint != actual_fingerprint:
            return None, {
                **base,
                "stale": True,
                "reason": "source_fingerprint_mismatch",
                "expectedSourceFingerprint": expected_source_fingerprint,
                "diagnostics": [{"severity": "error", "message": "Dialogue Content source changed since inspection"}],
            }
        try:
            document = load_dialogue_content_source(path)
            updated = self._dialogue_content_operation(document, str(content_id), str(operation), arguments)
            compiled = compile_dialogue_content(updated)
        except (OSError, ValueError, TypeError, CompileError) as error:
            return None, {
                **base,
                "diagnostics": [{"severity": "error", "message": str(error)}],
            }
        return updated, {
            **base,
            "ok": True,
            "stale": False,
            "diagnostics": [],
            "contentFingerprint": compiled["contentFingerprint"],
            "generatedPaths": [
                str(self.repository / path)
                for path in (
                    "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/Semantics/Generated/DialogueContent/Registry.lua",
                    "Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/Semantic/DialogueContent.json",
                    "Contents/mods/ProjectHoomans/common/media/translation/TL/Conversation/Semantic/DialogueContent.json",
                )
            ],
        }

    def preview_dialogue_content_operation(
        self,
        content_id: str,
        operation: str,
        *,
        expected_source_fingerprint: str | None = None,
        **arguments: Any,
    ) -> dict[str, Any]:
        """Validate a structural content operation without writing any file."""
        _updated, report = self._prepare_dialogue_content_operation(
            content_id,
            operation,
            expected_source_fingerprint=expected_source_fingerprint,
            **arguments,
        )
        return report

    def write_dialogue_content_operation(
        self,
        content_id: str,
        operation: str,
        *,
        expected_source_fingerprint: str | None = None,
        **arguments: Any,
    ) -> dict[str, Any]:
        """Write a previously validated structural operation to its shard(s)."""
        updated, report = self._prepare_dialogue_content_operation(
            content_id,
            operation,
            expected_source_fingerprint=expected_source_fingerprint,
            **arguments,
        )
        if updated is None or report.get("ok") is not True:
            return report
        try:
            written = write_dialogue_content_source(self.dialogue_content_source_path, updated)
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
            "reloadedBy": "caller_compile_required",
        }

    def validate_dialogue_content(
        self,
        document: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Return machine-readable canonical content validation diagnostics."""
        try:
            source = document if document is not None else load_dialogue_content_source(
                self.dialogue_content_source_path
            )
            compiled = compile_dialogue_content(source)
        except (OSError, ValueError, TypeError, CompileError) as error:
            return {
                "ok": False,
                "type": "dialogue_content_validation",
                "diagnostics": [{"severity": "error", "message": str(error)}],
                "writes": [],
                "effectFree": True,
            }
        return {
            "ok": True,
            "type": "dialogue_content_validation",
            "phraseFamilyCount": len(compiled["phraseFamilies"]),
            "phraseCount": sum(
                len(phrases)
                for family in compiled["phraseFamilies"]
                for phrases in family["styles"].values()
            ),
            "contentFingerprint": compiled["contentFingerprint"],
            "diagnostics": [],
            "writes": [],
            "effectFree": True,
        }

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
