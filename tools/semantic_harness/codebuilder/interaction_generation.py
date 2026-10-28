"""Typed interaction preview and generation orchestration for Semantic Lab."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

from . import authoring

from .blocks import SemanticBlockRegistry
from .lexicon_compiler import CompileError
from .translation_support import pretty_json
from .semantic_definition_compiler import discover_registered_capability_ids
from .conversation_compiler import (
    CONVERSATION_RUNTIME_RELATIVE,
    CONVERSATION_SOURCE_RELATIVE,
    CONVERSATION_UI_RUNTIME_RELATIVE,
    compile_conversation_sources,
    conversation_translation_bundles,
    render_conversation_manifest_lua,
    render_conversation_registry,
    render_conversation_runtime_plan,
    render_conversation_ui_module,
)
from .dataset_catalog import WORKFLOW_DATASET_KINDS, SemanticDatasetCatalog
from .interaction_spec import (
    compile_interaction_collection,
    compile_interaction_spec,
    edit_interaction_graph,
    validate_interaction_spec,
)


class SemanticInteractionAuthoring:
    """Own typed graph validation, effect-free previews, and approved writes."""

    def __init__(
        self,
        dataset_catalog: SemanticDatasetCatalog,
        block_registry: SemanticBlockRegistry,
        repository: Path,
        runtime_root: Path,
    ) -> None:
        self.dataset_catalog = dataset_catalog
        self.block_registry = block_registry
        self.repository = repository
        self.runtime_root = runtime_root

    def _dataset_spec(self, source_id: str) -> dict[str, Any]:
        return self.dataset_catalog._dataset_spec(source_id)

    def _dataset_path(self, source_id: str) -> Path:
        return self.dataset_catalog._dataset_path(source_id)

    def load_dataset_document(self, source_id: str) -> dict[str, Any]:
        return self.dataset_catalog.load_dataset_document(source_id)

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
                "sourcePath": ", ".join(
                    str(path)
                    for path in self.dataset_catalog._spec_paths(spec)
                ),
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

    def validate_interaction_spec(
        self,
        spec: dict[str, Any],
        *,
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        return validate_interaction_spec(spec, production_catalog=production_catalog)

    def edit_interaction_graph(
        self,
        spec: dict[str, Any],
        operation: str,
        *,
        production_catalog: dict[str, Any] | None = None,
        **kwargs: Any,
    ) -> dict[str, Any]:
        """Apply one declarative graph edit through the shared authoring API."""

        try:
            edited = edit_interaction_graph(spec, operation, **kwargs)
        except (TypeError, ValueError) as error:
            return {
                "ok": False,
                "valid": False,
                "type": "semantic_interaction_graph_edit",
                "operation": operation,
                "spec": None,
                "diagnostics": [{"severity": "error", "message": str(error)}],
                "previewOnly": True,
                "effectFree": True,
                "writes": [],
            }
        validation = self.validate_interaction_spec(
            edited,
            production_catalog=production_catalog,
        )
        return {
            "ok": validation.get("ok") is True,
            "valid": validation.get("valid") is True,
            "type": "semantic_interaction_graph_edit",
            "operation": operation,
            "spec": edited,
            "validation": validation,
            "diagnostics": validation.get("diagnostics", []),
            "previewOnly": True,
            "effectFree": True,
            "writes": [],
        }

    def _conversation_preview_artifacts(
        self,
        source_id: str,
        source_document: dict[str, Any],
    ) -> dict[str, Any]:
        """Preview one logical dataset edit through the canonical Conversation compiler."""

        overrides = self.dataset_catalog.conversation_source_overrides(
            source_id, source_document
        )
        model = compile_conversation_sources(
            self.repository,
            runtime_root=self.runtime_root,
            source_overrides=overrides,
        )
        rendered, reports = render_conversation_runtime_plan(model)
        shared_root = Path(
            "Contents/mods/ProjectHoomans/common/media/lua/shared"
        )
        expected_sources: dict[str, str] = {
            str(shared_root / (module + ".lua")): source
            for module, source in rendered
        }
        expected_sources[
            str(CONVERSATION_RUNTIME_RELATIVE / "Registry.lua")
        ] = render_conversation_registry(model, reports)
        expected_sources[
            str(CONVERSATION_RUNTIME_RELATIVE / "Manifest.lua")
        ] = render_conversation_manifest_lua(model, reports)
        expected_sources[
            str(CONVERSATION_UI_RUNTIME_RELATIVE)
        ] = render_conversation_ui_module(model)

        translation_root = Path(
            "Contents/mods/ProjectHoomans/common/media/translation"
        )
        for language, domains in sorted(
            conversation_translation_bundles(model).items()
        ):
            for domain, values in sorted(domains.items()):
                expected_sources[
                    str(
                        translation_root
                        / language
                        / "Conversation"
                        / f"{domain}.json"
                    )
                ] = pretty_json(values)

        source_diffs = [
            authoring._artifact_diff(
                self.repository,
                str(CONVERSATION_SOURCE_RELATIVE / Path(path)),
                pretty_json(document),
            )
            for path, document in sorted(overrides.items())
        ]
        generated_diffs = [
            authoring._artifact_diff(self.repository, path, expected)
            for path, expected in sorted(expected_sources.items())
        ]
        generated_lua = [
            {
                "module": path[
                    len(str(shared_root)) + 1 : -4
                ].replace("\\", "/"),
                "sha256": hashlib.sha256(source.encode("utf-8")).hexdigest(),
                "source": source,
            }
            for path, source in sorted(expected_sources.items())
            if path.startswith(str(shared_root) + "/") and path.endswith(".lua")
        ]
        fingerprint_payload = "\n".join(
            f"{path}\0{expected_sources[path]}"
            for path in sorted(expected_sources)
        )
        return {
            "canonicalSourceDiff": source_diffs[0] if source_diffs else None,
            "canonicalSourceDiffs": source_diffs,
            "generatedArtifactDiffs": generated_diffs,
            "generatedPaths": sorted(expected_sources),
            "generatedLua": generated_lua,
            "generatedSourceFingerprint": hashlib.sha256(
                fingerprint_payload.encode("utf-8")
            ).hexdigest(),
            "conversationFingerprint": model["wholeModelFingerprint"],
        }

    def preview_interaction_spec(
        self,
        spec: dict[str, Any],
        *,
        source_id: str = "semantic_flows",
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Compile one canonical typed spec without writing or reloading Lua."""

        source_spec = self._dataset_spec(source_id)
        if source_spec["kind"] not in {"semantic", "dialogue"}:
            return {
                "ok": False,
                "valid": False,
                "type": "semantic_interaction_spec_preview",
                "sourceID": source_id,
                "diagnostics": [{
                    "severity": "error",
                    "message": f"interaction specs require a generated semantic/dialogue source, not {source_id}",
                }],
                "previewOnly": True,
                "effectFree": True,
                "writes": [],
            }
        base_document = self.load_dataset_document(source_id)
        registered = discover_registered_capability_ids(self.runtime_root)
        report = compile_interaction_spec(
            spec,
            base_document,
            production_catalog=production_catalog,
            registered_capability_ids=registered,
        )
        report.update({
            "type": (
                "semantic_interaction_spec_preview"
                if source_spec["kind"] == "semantic"
                else "dialogue_interaction_spec_preview"
            ),
            "sourceID": source_id,
            "sourcePath": ", ".join(
                str(path)
                for path in self.dataset_catalog._spec_paths(source_spec)
            ),
            "previewOnly": True,
            "effectFree": True,
            "writes": [],
        })
        compiled = report.get("compiled")
        if not isinstance(compiled, dict):
            return report
        report.update(
            self._conversation_preview_artifacts(
                source_id,
                report["sourceDocument"],
            )
        )
        report["compiledSummary"] = {
            "patternIDs": [item["id"] for item in compiled["patterns"]],
            "flowIDs": [item["id"] for item in compiled.get("flows", [])],
            "responsePoolIDs": [item["id"] for item in compiled["responsePools"]],
        }
        return report

    def generate_interaction_spec(
        self,
        spec: dict[str, Any],
        *,
        approved: bool,
        source_id: str = "semantic_flows",
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Write an approved spec through the existing canonical Lua writer."""

        if approved is not True:
            return {
                "ok": False,
                "valid": False,
                "type": "semantic_interaction_spec_generation",
                "generationApproved": False,
                "previewOnly": True,
                "effectFree": True,
                "writes": [],
                "diagnostics": [{
                    "severity": "error",
                    "message": "interaction spec generation requires explicit approval",
                }],
            }
        preview = self.preview_interaction_spec(
            spec,
            source_id=source_id,
            production_catalog=production_catalog,
        )
        if preview.get("ok") is not True:
            return {
                **preview,
                "type": "semantic_interaction_spec_generation",
                "generationApproved": False,
            }
        from .build import write_conversation_output

        canonical = self.write_dataset_document(source_id, preview["sourceDocument"])
        if canonical.get("ok") is not True:
            return {
                **preview,
                "type": "semantic_interaction_spec_generation",
                "generationApproved": True,
                "ok": False,
                "diagnostics": canonical.get("diagnostics", []),
                "writes": [],
            }
        writes = [Path(path) for path in canonical.get("writes", [])]
        model = compile_conversation_sources(
            self.repository,
            runtime_root=self.runtime_root,
        )
        writes.extend(write_conversation_output(self.repository, model))
        post_write = self.preview_interaction_spec(
            spec,
            source_id=source_id,
            production_catalog=production_catalog,
        )
        return {
            **post_write,
            "type": "semantic_interaction_spec_generation",
            "generationApproved": True,
            "previewOnly": False,
            "effectFree": False,
            "writes": [str(path) for path in writes],
            "reloadedBy": "caller_restart_required",
        }

    def preview_interaction_collection(
        self,
        collection: dict[str, Any],
        *,
        source_id: str = "semantic_flows",
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Preview several specs that reuse shared typed block instances."""

        source_spec = self._dataset_spec(source_id)
        if source_spec["kind"] != "semantic":
            return {
                "ok": False,
                "valid": False,
                "type": "semantic_interaction_collection_preview",
                "diagnostics": [{
                    "severity": "error",
                    "message": f"interaction collections require a semantic source, not {source_id}",
                }],
                "previewOnly": True,
                "effectFree": True,
                "writes": [],
            }
        base_document = self.load_dataset_document(source_id)
        registered = discover_registered_capability_ids(self.runtime_root)
        report = compile_interaction_collection(
            collection,
            base_document,
            production_catalog=production_catalog,
            registered_capability_ids=registered,
        )
        report.update({
            "type": "semantic_interaction_collection_preview",
            "sourceID": source_id,
            "sourcePath": ", ".join(
                str(path)
                for path in self.dataset_catalog._spec_paths(source_spec)
            ),
            "previewOnly": True,
            "effectFree": True,
            "writes": [],
        })
        compiled = report.get("compiled")
        if not isinstance(compiled, dict):
            return report
        report.update(
            self._conversation_preview_artifacts(
                source_id,
                report["sourceDocument"],
            )
        )
        report["compiledSummary"] = {
            "patternIDs": [item["id"] for item in compiled["patterns"]],
            "flowIDs": [item["id"] for item in compiled["flows"]],
            "responsePoolIDs": [item["id"] for item in compiled["responsePools"]],
        }
        return report

    def generate_interaction_collection(
        self,
        collection: dict[str, Any],
        *,
        approved: bool,
        source_id: str = "semantic_flows",
        production_catalog: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Write an approved shared-block collection through the canonical writer."""

        if approved is not True:
            return {
                "ok": False,
                "valid": False,
                "type": "semantic_interaction_collection_generation",
                "generationApproved": False,
                "previewOnly": True,
                "effectFree": True,
                "writes": [],
                "diagnostics": [{
                    "severity": "error",
                    "message": "interaction collection generation requires explicit approval",
                }],
            }
        preview = self.preview_interaction_collection(
            collection,
            source_id=source_id,
            production_catalog=production_catalog,
        )
        if preview.get("ok") is not True:
            return {
                **preview,
                "type": "semantic_interaction_collection_generation",
                "generationApproved": False,
            }
        from .build import write_conversation_output

        canonical = self.write_dataset_document(source_id, preview["sourceDocument"])
        if canonical.get("ok") is not True:
            return {
                **preview,
                "type": "semantic_interaction_collection_generation",
                "generationApproved": True,
                "ok": False,
                "diagnostics": canonical.get("diagnostics", []),
                "writes": [],
            }
        writes = [Path(path) for path in canonical.get("writes", [])]
        model = compile_conversation_sources(
            self.repository,
            runtime_root=self.runtime_root,
        )
        writes.extend(write_conversation_output(self.repository, model))
        post_write = self.preview_interaction_collection(
            collection,
            source_id=source_id,
            production_catalog=production_catalog,
        )
        return {
            **post_write,
            "type": "semantic_interaction_collection_generation",
            "generationApproved": True,
            "previewOnly": False,
            "effectFree": False,
            "writes": [str(path) for path in writes],
            "reloadedBy": "caller_restart_required",
        }

    def preview_workflow(
        self,
        source_id: str,
        block_ids: list[str],
        *,
        production_catalog: dict[str, Any] | None = None,
        interaction_spec: dict[str, Any] | None = None,
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
        if interaction_spec is not None:
            composition = self.preview_interaction_spec(
                interaction_spec,
                source_id=source_id,
                production_catalog=production_catalog,
            )
            report.update({
                "ok": composition.get("ok") is True,
                "composition": composition,
                "sourcePreview": composition,
                "diagnostics": composition.get("diagnostics", []),
                "readyForApproval": composition.get("ok") is True,
            })
            return report
        document = self.load_dataset_document(source_id)
        source_preview = self.preview_dataset_edit(source_id, document)
        if source_preview.get("ok") is True:
            source_preview.update(
                self._conversation_preview_artifacts(source_id, document)
            )
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
        interaction_spec: dict[str, Any] | None = None,
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
            interaction_spec=interaction_spec,
        )
        if preview.get("ok") is not True:
            return {
                **preview,
                "type": "semantic_lab_workflow_generation",
                "generationApproved": False,
            }
        if interaction_spec is not None:
            generation = self.generate_interaction_spec(
                interaction_spec,
                approved=True,
                source_id=source_id,
                production_catalog=production_catalog,
            )
            return {
                **generation,
                "type": "semantic_lab_workflow_generation",
                "workflow": preview["workflow"],
                "selection": preview["selection"],
                "sourcePreview": preview.get("sourcePreview"),
            }
        from .build import write_conversation_output

        document = self.load_dataset_document(source_id)
        canonical = self.write_dataset_document(source_id, document)
        if canonical.get("ok") is not True:
            generation = canonical
        else:
            model = compile_conversation_sources(
                self.repository,
                runtime_root=self.runtime_root,
            )
            written = [Path(path) for path in canonical.get("writes", [])]
            written.extend(write_conversation_output(self.repository, model))
            generation = {
                **canonical,
                "generationApproved": True,
                "writes": [str(path) for path in written],
                "reloadedBy": "caller_restart_required",
            }
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
