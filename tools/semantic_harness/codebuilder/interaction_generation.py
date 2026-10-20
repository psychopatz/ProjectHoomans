"""Typed interaction preview and generation orchestration for Semantic Lab."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

from tools.semantic_harness import authoring

from .blocks import SemanticBlockRegistry
from .compiler import CompileError
from .compiler import (
    discover_registered_capability_ids,
    render_dialogue_lua,
    render_dialogue_lua_shards,
    render_semantic_lua_shards,
    render_semantic_manifest,
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

    def _semantic_preview_artifacts(
        self,
        compiled: dict[str, Any],
        source_document: dict[str, Any],
        source_path: Path,
    ) -> dict[str, Any]:
        """Expose canonical-source and generated Lua/translation diffs effect-free."""

        source_text = json.dumps(source_document, ensure_ascii=False, indent=2) + "\n"
        source_relative = str(source_path.resolve().relative_to(self.repository))
        rendered = render_semantic_lua_shards(
            compiled,
            "PNC/Semantics/PNC_SemanticGeneratedDefinitions",
        )
        pattern_modules = [module for module, _source in rendered if "_Patterns_" in module]
        flow_modules = [module for module, _source in rendered if "_Flows_" in module]
        response_modules = [module for module, _source in rendered if "_Responses_" in module]
        translation_paths = {
            "EN": ["EN/Conversation/Semantic/Generated.json"],
            "TL": ["TL/Conversation/Semantic/Generated.json"],
        }
        semantic_root = Path(
            "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics"
        )
        expected_sources: dict[str, str] = {
            str(semantic_root / "PNC_SemanticGeneratedDefinitions.lua"):
                render_semantic_manifest(
                    compiled,
                    pattern_modules,
                    flow_modules,
                    response_modules,
                    translation_paths,
                ),
        }
        expected_sources.update({
            str(semantic_root / (Path(module).name + ".lua")): source
            for module, source in rendered
        })
        translation_root = Path(
            "Contents/mods/ProjectHoomans/common/media/translation"
        )
        expected_sources.update({
            str(translation_root / language / "Conversation/Semantic/Generated.json"):
                json.dumps(
                    compiled["translations"][language],
                    ensure_ascii=False,
                    sort_keys=True,
                    separators=(",", ":"),
                ) + "\n"
            for language in ("EN", "TL")
        })
        return {
            "canonicalSourceDiff": authoring._artifact_diff(
                self.repository,
                source_relative,
                source_text,
            ),
            "generatedArtifactDiffs": [
                authoring._artifact_diff(self.repository, path, expected)
                for path, expected in expected_sources.items()
            ],
            "generatedPaths": list(expected_sources),
        }

    def _dialogue_preview_artifacts(
        self,
        compiled: dict[str, Any],
        source_document: dict[str, Any],
        source_path: Path,
    ) -> dict[str, Any]:
        """Expose grounded-dialogue source and real asset diffs effect-free."""

        source_relative = str(source_path.resolve().relative_to(self.repository))
        source_text = json.dumps(source_document, ensure_ascii=False, indent=2) + "\n"
        generated_paths, artifacts, artifact_diffs = authoring._dialogue_preview_paths(
            compiled,
            self.repository,
            source_path,
        )
        asset_stem = authoring._dialogue_asset_stem(source_path)
        module_prefix = "PNC/Semantics/PNC_Semantic" + asset_stem
        rendered = render_dialogue_lua_shards(compiled, module_prefix)
        pattern_modules = [module for module, _source in rendered if "_Patterns_" in module]
        response_modules = [module for module, _source in rendered if "_Responses_" in module]
        entry_module = module_prefix
        generated_lua = [{
            "module": entry_module,
            "sha256": hashlib.sha256(
                render_dialogue_lua(compiled, pattern_modules, response_modules).encode("utf-8")
            ).hexdigest(),
            "source": render_dialogue_lua(compiled, pattern_modules, response_modules),
        }]
        generated_lua.extend({
            "module": module,
            "sha256": hashlib.sha256(source.encode("utf-8")).hexdigest(),
            "source": source,
        } for module, source in rendered)
        return {
            "canonicalSourceDiff": authoring._artifact_diff(
                self.repository,
                source_relative,
                source_text,
            ),
            "generatedArtifactDiffs": artifact_diffs,
            "generatedArtifacts": artifacts,
            "generatedPaths": generated_paths,
            "generatedLua": generated_lua,
        }

    def preview_interaction_spec(
        self,
        spec: dict[str, Any],
        *,
        source_id: str = "semantic_definitions",
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
            "sourcePath": str(source_spec["path"]),
            "previewOnly": True,
            "effectFree": True,
            "writes": [],
        })
        compiled = report.get("compiled")
        if not isinstance(compiled, dict):
            return report
        if source_spec["kind"] == "semantic":
            rendered = render_semantic_lua_shards(
                compiled,
                "PNC/Semantics/PNC_SemanticGeneratedDefinitions",
            )
            report["generatedLua"] = [
                {
                    "module": module,
                    "sha256": hashlib.sha256(source.encode("utf-8")).hexdigest(),
                    "source": source,
                }
                for module, source in rendered
            ]
            report["generatedSourceFingerprint"] = hashlib.sha256(
                "\n".join(source for _module, source in rendered).encode("utf-8")
            ).hexdigest()
            report.update(
                self._semantic_preview_artifacts(
                    compiled,
                    report["sourceDocument"],
                    self._dataset_path(source_id),
                )
            )
        else:
            artifact_report = self._dialogue_preview_artifacts(
                compiled,
                report["sourceDocument"],
                self._dataset_path(source_id),
            )
            report.update(artifact_report)
            report["generatedSourceFingerprint"] = hashlib.sha256(
                "\n".join(item["source"] for item in artifact_report["generatedLua"]).encode("utf-8")
            ).hexdigest()
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
        source_id: str = "semantic_definitions",
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
        from .build import write_dialogue_output, write_semantic_output

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
        if self._dataset_spec(source_id)["kind"] == "semantic":
            writes.extend(write_semantic_output(self.repository, preview["compiled"]))
        else:
            output = authoring._dialogue_output_path(
                self._dataset_path(source_id),
                self.repository,
            )
            output.parent.mkdir(parents=True, exist_ok=True)
            writes.extend(write_dialogue_output(output, preview["compiled"]))
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
        source_id: str = "semantic_definitions",
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
            "sourcePath": str(source_spec["path"]),
            "previewOnly": True,
            "effectFree": True,
            "writes": [],
        })
        compiled = report.get("compiled")
        if not isinstance(compiled, dict):
            return report
        rendered = render_semantic_lua_shards(
            compiled,
            "PNC/Semantics/PNC_SemanticGeneratedDefinitions",
        )
        report["generatedLua"] = [
            {
                "module": module,
                "sha256": hashlib.sha256(source.encode("utf-8")).hexdigest(),
                "source": source,
            }
            for module, source in rendered
        ]
        report["generatedSourceFingerprint"] = hashlib.sha256(
            "\n".join(source for _module, source in rendered).encode("utf-8")
        ).hexdigest()
        report["compiledSummary"] = {
            "patternIDs": [item["id"] for item in compiled["patterns"]],
            "flowIDs": [item["id"] for item in compiled["flows"]],
            "responsePoolIDs": [item["id"] for item in compiled["responsePools"]],
        }
        report.update(
            self._semantic_preview_artifacts(
                compiled,
                report["sourceDocument"],
                self._dataset_path(source_id),
            )
        )
        return report

    def generate_interaction_collection(
        self,
        collection: dict[str, Any],
        *,
        approved: bool,
        source_id: str = "semantic_definitions",
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
        from .build import write_semantic_output

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
        writes.extend(write_semantic_output(self.repository, preview["compiled"]))
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
