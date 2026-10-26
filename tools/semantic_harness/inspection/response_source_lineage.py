"""Verify canonical CodeBuilder inputs against the actual loaded Lua registry.

This is a *read-only* cross-check, not a second Lua parser or a guess from a
registration source path. Only canonical datasets discovered through the
existing authoring service, its compiler and its preview parity can qualify.
"""
from __future__ import annotations

import hashlib
from typing import Any

from ..codebuilder.dialogue_dataset import compile_dialogue_dataset
from ..codebuilder.semantic_definition_compiler import compile_semantic_definitions
from ..codebuilder.service import SemanticLabAuthoringService
from ..runtime.worker import LuaSemanticWorker


def _condition(value: Any) -> Any:
    # Empty Lua arrays and Python JSON objects both represent unkeyed Lua {}.
    if value == [] or value == {} or value is None:
        return {}
    return value


def _matches(authored: dict[str, Any], loaded: dict[str, Any]) -> bool:
    return (
        authored.get("id") == loaded.get("id")
        and authored.get("templateID") == loaded.get("templateID")
        and authored.get("fallback") == loaded.get("fallback")
        and _condition(authored.get("when")) == _condition(loaded.get("when"))
        and int(authored.get("priority", 0)) == int(loaded.get("priority", 0))
    )


def inspect_codebuilder_lineage(
    worker: LuaSemanticWorker,
    pool_id: str,
    *,
    authoring_service: SemanticLabAuthoringService | None = None,
) -> dict[str, Any]:
    """Return verified per-variant source ownership; unresolved stays UNKNOWN."""
    service = authoring_service or SemanticLabAuthoringService(
        repository=worker.config.repository,
        runtime_root=worker.config.repository,
    )
    detail = worker.response_pool_detail(pool_id, limit=16)
    loaded = detail.get("variants", [])
    if detail.get("hasMore"):
        return {
            "ok": False, "type": "response_codebuilder_lineage",
            "schemaVersion": 1, "poolID": pool_id, "reason": "pool_exceeds_detail_bound",
            "sourceKind": "UNKNOWN", "sourceOwners": [],
        }
    by_id = {variant["id"]: variant for variant in loaded}
    matches: dict[str, list[dict[str, Any]]] = {variant_id: [] for variant_id in by_id}
    checked_sources = []
    for source in service.list_dataset_sources():
        kind = source.get("kind")
        if kind not in ("dialogue", "semantic") or not source.get("exists"):
            continue
        source_id = source["id"]
        path = service._dataset_path(source_id)
        # Reuse CodeBuilder's own validation and deterministic rendered-artifact
        # comparison. Generated Lua files are never edited or used as input.
        preview = (service.preview_dialogue_source(path) if kind == "dialogue"
                   else service.preview_semantic_source(path))
        if not preview.get("ok"):
            checked_sources.append({"sourceID": source_id, "verified": False,
                                    "reason": "canonical_codebuilder_preview_failed"})
            continue
        diffs = preview.get("artifactDiffs") or []
        artifacts_current = (kind == "semantic"
                             or bool(diffs) and all(
                                 row.get("status") == "unchanged" for row in diffs))
        if not artifacts_current:
            checked_sources.append({"sourceID": source_id, "verified": False,
                                    "reason": "generated_artifact_differs_from_source"})
            continue
        source_document = service.load_dataset_document(source_id)
        compiled = (compile_dialogue_dataset(source_document) if kind == "dialogue"
                    else compile_semantic_definitions(source_document))
        for pool in compiled.get("responsePools", []):
            if pool["id"] != pool_id:
                continue
            for variant in pool.get("variants", []):
                loaded_variant = by_id.get(variant.get("id"))
                if loaded_variant is not None and _matches(variant, loaded_variant):
                    matches[loaded_variant["id"]].append({
                        "sourceID": source_id,
                        "sourcePath": str(path.relative_to(service.repository)),
                        "sourceSHA256": hashlib.sha256(path.read_bytes()).hexdigest(),
                        "validatedBy": "existing_CodeBuilder_preview_and_compiler",
                        "generatedArtifactParity": (
                            "unchanged" if kind == "dialogue"
                            else "not_reported_by_semantic_preview"
                        ),
                    })
        checked_sources.append({
            "sourceID": source_id, "verified": True,
            "generatedArtifactParity": "unchanged" if kind == "dialogue"
                else "not_reported_by_semantic_preview",
        })
    owners = []
    for variant in loaded:
        candidates = matches[variant["id"]]
        unique = candidates[0] if len(candidates) == 1 else None
        owners.append({
            "variantID": variant["id"],
            "sourceKind": "CODEBUILDER_CANONICAL" if unique else "UNKNOWN",
            "verifiedCanonicalSource": bool(unique),
            "reason": ("matched_compiled_variant_and_loaded_registry"
                       if unique else "ambiguous_canonical_matches"
                       if len(candidates) > 1 else "no_verified_canonical_match"),
            "canonicalSource": unique,
        })
    verified = sum(bool(row["verifiedCanonicalSource"]) for row in owners)
    return {
        "ok": True, "type": "response_codebuilder_lineage",
        "schemaVersion": 1, "poolID": pool_id,
        "sourceKind": "FIXTURE",
        "registryRevision": detail["registryRevision"],
        "contentFingerprint": detail["contentFingerprint"],
        "variantCount": detail["variantCount"],
        "verifiedVariantCount": verified,
        "unverifiedVariantCount": len(owners) - verified,
        "fullPoolCanonicalOwnershipVerified": verified == len(owners),
        "sourceOwners": owners, "checkedCanonicalSources": checked_sources,
        "selectionAuthority": "production_lua",
        "approvalRequired": True, "writes": 0,
    }
