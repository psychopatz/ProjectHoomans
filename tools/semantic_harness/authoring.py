"""Pure Semantic Lab adapter for previewing canonical semantic source."""

from __future__ import annotations

import hashlib
import difflib
import json
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

from tools.semantic_harness.codebuilder.compiler import (
    CompileError,
    compile_dialogue_dataset,
    compile_semantic_definitions,
    discover_registered_capability_ids,
    render_dialogue_lua,
    render_dialogue_lua_shards,
    render_dialogue_translation,
    load_semantic_source,
    render_semantic_lua_shards,
)
from tools.semantic_harness.codebuilder.compiler import load_dialogue_dataset
from tools.semantic_harness.codebuilder.build import (
    write_dialogue_output,
    write_semantic_output,
)


REPOSITORY = Path(__file__).resolve().parents[2]
SEMANTIC_RELATIVE_ROOT = Path(
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics"
)
TRANSLATION_RELATIVE_ROOT = Path(
    "Contents/mods/ProjectHoomans/common/media/translation"
)
DIALOGUE_RELATIVE_ROOT = Path(
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics"
)
DIALOGUE_TRANSLATION_RELATIVE_ROOT = Path(
    "Contents/mods/ProjectHoomans/common/media/translation"
)
DIALOGUE_OUTPUT_RELATIVE_PATH = (
    DIALOGUE_RELATIVE_ROOT / "PNC_SemanticGeneratedDialogue.lua"
)
MAX_DATASET_REVIEW_ROWS = 64
MAX_DATASET_COLLISIONS = 16
MAX_ARTIFACT_DIFF_LINES = 96
MAX_ARTIFACT_DIFF_CHARS = 12_000
INTEGRATION_STATUS_FIELDS = (
    "imported",
    "mapped",
    "approved",
    "compiled",
    "workerVerified",
)


def _planned_paths(compiled: dict[str, Any]) -> list[str]:
    base_name = "PNC_SemanticGeneratedDefinitions"
    rendered = render_semantic_lua_shards(compiled, "PNC/Semantics/" + base_name)
    paths = [str(SEMANTIC_RELATIVE_ROOT / (base_name + ".lua"))]
    paths.extend(
        str(SEMANTIC_RELATIVE_ROOT / (Path(module).name + ".lua"))
        for module, _source in rendered
    )
    paths.extend([
        str(TRANSLATION_RELATIVE_ROOT / "EN/Conversation/Semantic/Generated.json"),
        str(TRANSLATION_RELATIVE_ROOT / "TL/Conversation/Semantic/Generated.json"),
        str(TRANSLATION_RELATIVE_ROOT / "manifests/Conversation.json"),
    ])
    return paths


def preview_semantic_source(
    source_path: Path,
    *,
    repository: Path | None = None,
    runtime_root: Path | None = None,
) -> dict[str, Any]:
    """Compile canonical source in memory and return an effect-free report."""
    repository = (repository or REPOSITORY).expanduser().resolve()
    runtime_root = (runtime_root or repository).expanduser().resolve()
    source_path = source_path.expanduser().resolve()
    try:
        source = load_semantic_source(source_path)
        compiled = compile_semantic_definitions(
            source,
            discover_registered_capability_ids(runtime_root),
        )
    except (CompileError, OSError, ValueError) as error:
        return {
            "ok": False,
            "type": "semantic_compile_preview",
            "sourcePath": str(source_path),
            "previewOnly": True,
            "effectFree": True,
            "diagnostics": [{"severity": "error", "message": str(error)}],
            "generatedPaths": [],
            "writes": [],
        }

    definitions = source.get("definitions", [])
    return {
        "ok": True,
        "type": "semantic_compile_preview",
        "schema": compiled["schema"],
        "sourcePath": str(source_path),
        "source": compiled["source"],
        "previewOnly": True,
        "effectFree": True,
        "diagnostics": [],
        "definitionIDs": [definition["id"] for definition in definitions],
        "capabilityIDs": sorted({
            definition["capability"] for definition in definitions
            if isinstance(definition, dict) and isinstance(definition.get("capability"), str)
        }),
        "patternIDs": [pattern["id"] for pattern in compiled["patterns"]],
        "flowIDs": [flow["id"] for flow in compiled["flows"]],
        "responsePoolIDs": [pool["id"] for pool in compiled["responsePools"]],
        "translationKeys": {
            language: sorted(values)
            for language, values in compiled["translations"].items()
        },
        "generatedPaths": _planned_paths(compiled),
        "writes": [],
    }


def generate_semantic_source(
    source_path: Path,
    *,
    repository: Path | None = None,
    runtime_root: Path | None = None,
) -> dict[str, Any]:
    """Write approved generated artifacts through the existing compiler writer."""
    repository = (repository or REPOSITORY).expanduser().resolve()
    runtime_root = (runtime_root or repository).expanduser().resolve()
    preview = preview_semantic_source(
        source_path, repository=repository, runtime_root=runtime_root
    )
    if preview.get("ok") is not True:
        return preview
    try:
        source = load_semantic_source(source_path.expanduser().resolve())
        compiled = compile_semantic_definitions(
            source,
            discover_registered_capability_ids(runtime_root),
        )
        written = write_semantic_output(repository, compiled)
    except (CompileError, OSError, ValueError) as error:
        return {
            **preview,
            "ok": False,
            "generationApproved": True,
            "diagnostics": [{"severity": "error", "message": str(error)}],
            "writes": [],
        }
    return {
        **preview,
        "generationApproved": True,
        "generatedPaths": [str(path) for path in preview["generatedPaths"]],
        "writes": [str(path) for path in written],
        "reloadedBy": "caller_restart_required",
    }


def _normalize_dialogue_text(value: Any) -> str | None:
    """Mirror the compiler's bounded literal normalization for review only."""

    if not isinstance(value, str):
        return None
    text = value.lower()
    text = re.sub(r"[\x00-\x1f\x7f]", " ", text)
    text = re.sub(r'[, .!?;:()\[\]{}"]', " ", text)
    return re.sub(r"\s+", " ", text).strip() or None


def _bounded_text(value: Any, limit: int = 256) -> str:
    text = str(value or "")
    return text[:limit]


def _bounded_record_refs(value: Any) -> list[dict[str, Any]]:
    if not isinstance(value, list):
        return []
    rows: list[dict[str, Any]] = []
    for record in value[:8]:
        if not isinstance(record, dict):
            continue
        row: dict[str, Any] = {}
        for key, item in record.items():
            if not isinstance(key, str):
                continue
            if isinstance(item, (str, int, float, bool)):
                row[_bounded_text(key, 64)] = _bounded_text(item, 256)
        if row:
            rows.append(row)
    return rows


def _bounded_integration_status(value: Any) -> dict[str, int]:
    status = {
        field: 0
        for field in INTEGRATION_STATUS_FIELDS
    }
    if not isinstance(value, dict):
        return status
    for field in INTEGRATION_STATUS_FIELDS:
        item = value.get(field)
        if isinstance(item, int) and not isinstance(item, bool) and item >= 0:
            status[field] = item
    return status


def _integration_status(references: list[dict[str, Any]]) -> dict[str, int]:
    totals = {
        field: 0
        for field in INTEGRATION_STATUS_FIELDS
    }
    for reference in references:
        status = _bounded_integration_status(reference.get("importStatus"))
        for field in INTEGRATION_STATUS_FIELDS:
            totals[field] += status[field]
    return totals


def _source_reference_rows(document: dict[str, Any]) -> tuple[list[dict[str, Any]], set[str]]:
    source = document.get("source") if isinstance(document.get("source"), dict) else {}
    references = source.get("references") if isinstance(source.get("references"), list) else []
    rows: list[dict[str, Any]] = []
    names: set[str] = set()
    for reference in references[:8]:
        if not isinstance(reference, dict):
            rows.append({"name": "<invalid>", "valid": False})
            continue
        name = _bounded_text(reference.get("name"), 128)
        if name:
            names.add(name)
        rows.append({
            "name": name or "<missing>",
            "version": _bounded_text(
                reference.get("sourceVersion") or source.get("version"), 64
            ),
            "url": _bounded_text(reference.get("url"), 512),
            "license": _bounded_text(reference.get("license"), 128),
            "use": _bounded_text(reference.get("use"), 256),
            "reviewedOn": _bounded_text(reference.get("reviewedOn"), 32),
            "sourceSha256": _bounded_text(reference.get("sourceSha256"), 128),
            "recordRefs": _bounded_record_refs(reference.get("recordRefs")),
            "integrationStatus": _bounded_integration_status(
                reference.get("importStatus")
            ),
            "valid": all(
                isinstance(reference.get(field), str) and reference[field].strip()
                for field in ("name", "url", "license", "use", "reviewedOn")
            ),
        })
    return rows, names


def _candidate_review_row(
    kind: str,
    candidate_id: str,
    value: Any,
    source_names: set[str],
) -> dict[str, Any]:
    row: dict[str, Any] = {
        "kind": kind,
        "id": _bounded_text(candidate_id, 192),
        "status": "not_candidate",
        "reason": "not_marked_for_dataset_review",
    }
    if not isinstance(value, dict):
        row.update(status="rejected", reason="candidate_is_not_an_object")
        return row

    utterance = value.get("utterance")
    if utterance is not None:
        row["utterance"] = _bounded_text(utterance)
    candidate_reviewed = value.get("reviewed")
    if candidate_reviewed is False:
        row.update(status="rejected", reason="explicitly_rejected")
        return row
    if candidate_reviewed is not True:
        return row

    source_refs = value.get("sourceRefs")
    if not isinstance(source_refs, list) or not source_refs:
        row.update(status="rejected", reason="missing_provenance")
        return row
    normalized_refs = [item for item in source_refs if isinstance(item, str) and item.strip()]
    unknown_refs = sorted(set(normalized_refs) - source_names)
    if len(normalized_refs) != len(source_refs) or unknown_refs:
        row.update(
            status="rejected",
            reason="unknown_or_invalid_provenance",
            sourceRefs=normalized_refs[:4],
        )
        if unknown_refs:
            row["unknownSourceRefs"] = unknown_refs[:4]
        return row
    row["sourceRefs"] = normalized_refs[:4]

    if kind == "pattern":
        mapping = value.get("mapping")
        if not isinstance(mapping, dict):
            row.update(status="rejected", reason="missing_canonical_mapping")
            return row
        mapping_refs = mapping.get("sourceRefs")
        if mapping_refs != source_refs:
            row.update(status="rejected", reason="mapping_provenance_mismatch")
            return row
        row["canonicalConcept"] = _bounded_text(mapping.get("canonicalConcept"), 96)
        row["dialogueState"] = _bounded_text(mapping.get("dialogueState"), 96)
    elif not isinstance(value.get("plan"), dict):
        row.update(status="rejected", reason="missing_dialogue_plan")
        return row

    row.update(status="approved", reason="reviewed_with_provenance")
    return row


def _dataset_collisions(document: dict[str, Any]) -> tuple[list[dict[str, Any]], dict[str, set[str]]]:
    positives: dict[str, list[str]] = defaultdict(list)
    negatives: dict[str, list[str]] = defaultdict(list)
    collisions: list[dict[str, Any]] = []
    patterns = document.get("patterns") if isinstance(document.get("patterns"), list) else []
    for pattern in patterns:
        if not isinstance(pattern, dict):
            continue
        pattern_id = _bounded_text(pattern.get("id"), 192) or "<missing>"
        positive = _normalize_dialogue_text(pattern.get("utterance"))
        if positive:
            positives[positive].append(pattern_id)
        negatives_raw = pattern.get("negatives", [])
        if isinstance(negatives_raw, list):
            for negative in negatives_raw:
                normalized = _normalize_dialogue_text(negative)
                if normalized:
                    negatives[normalized].append(pattern_id)

    for normalized, ids in sorted(positives.items()):
        if len(ids) > 1:
            collisions.append({
                "kind": "positive_duplicate",
                "utterance": normalized,
                "patternIDs": sorted(set(ids))[:4],
            })
    for normalized, ids in sorted(negatives.items()):
        positive_ids = positives.get(normalized, [])
        if positive_ids:
            collisions.append({
                "kind": "positive_negative",
                "utterance": normalized,
                "patternIDs": sorted(set(ids + positive_ids))[:4],
            })
        if len(ids) > 1:
            collisions.append({
                "kind": "negative_duplicate",
                "utterance": normalized,
                "patternIDs": sorted(set(ids))[:4],
            })

    collision_ids: dict[str, set[str]] = defaultdict(set)
    for collision in collisions[:MAX_DATASET_COLLISIONS]:
        for pattern_id in collision.get("patternIDs", []):
            collision_ids[pattern_id].add(collision["kind"])
    return collisions[:MAX_DATASET_COLLISIONS], collision_ids


def _artifact_diff(
    repository: Path,
    relative_path: str,
    expected: str,
) -> dict[str, Any]:
    target = repository / relative_path
    current: str | None = None
    read_error: str | None = None
    try:
        if target.is_file():
            current = target.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        read_error = str(error)
    if read_error:
        status = "unreadable"
    elif current is None:
        status = "added"
    elif current == expected:
        status = "unchanged"
    else:
        status = "changed"
    diff_lines = list(difflib.unified_diff(
        (current or "").splitlines(keepends=True),
        expected.splitlines(keepends=True),
        fromfile=f"current/{relative_path}",
        tofile=f"preview/{relative_path}",
    ))
    diff_truncated = len(diff_lines) > MAX_ARTIFACT_DIFF_LINES
    diff = "".join(diff_lines[:MAX_ARTIFACT_DIFF_LINES])
    if len(diff) > MAX_ARTIFACT_DIFF_CHARS:
        diff = diff[:MAX_ARTIFACT_DIFF_CHARS]
        diff_truncated = True
    row: dict[str, Any] = {
        "path": relative_path,
        "status": status,
        "expectedChars": len(expected),
        "expectedSha256": hashlib.sha256(expected.encode("utf-8")).hexdigest(),
        "currentChars": len(current) if current is not None else 0,
        "currentSha256": hashlib.sha256(current.encode("utf-8")).hexdigest()
        if current is not None else None,
        "diff": diff,
        "diffTruncated": diff_truncated,
    }
    if read_error:
        row["readError"] = _bounded_text(read_error)
    return row


def _dialogue_preview_paths(
    compiled: dict[str, Any],
    repository: Path,
) -> tuple[list[str], list[dict[str, Any]], list[dict[str, Any]]]:
    module_prefix = "PNC/Semantics/PNC_SemanticGeneratedDialogue"
    rendered = render_dialogue_lua_shards(compiled, module_prefix)
    pattern_modules = [module for module, _source in rendered if "_Patterns_" in module]
    response_modules = [module for module, _source in rendered if "_Responses_" in module]
    entry = render_dialogue_lua(compiled, pattern_modules, response_modules)
    entry_path = DIALOGUE_RELATIVE_ROOT / "PNC_SemanticGeneratedDialogue.lua"
    expected_sources: dict[str, str] = {str(entry_path): entry}
    expected_sources.update({
        str(DIALOGUE_RELATIVE_ROOT / (Path(module).name + ".lua")): source
        for module, source in rendered
    })
    expected_sources.update({
        str(DIALOGUE_TRANSLATION_RELATIVE_ROOT / language / "Conversation/Semantic/GeneratedDialogue.json"):
        render_dialogue_translation(compiled, language)
        for language in ("EN", "TL")
    })
    manifest_relative_path = (
        "Contents/mods/ProjectHoomans/common/media/translation/manifests/Conversation.json"
    )
    manifest_path = repository / manifest_relative_path
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8")) \
            if manifest_path.is_file() else {"version": 1, "languages": {}}
    except (OSError, UnicodeError, json.JSONDecodeError):
        manifest = {"version": 1, "languages": {}}
    for language in ("EN", "TL"):
        relative_path = f"{language}/Conversation/Semantic/GeneratedDialogue.json"
        entries = manifest.setdefault("languages", {}).setdefault(language, [])
        if relative_path not in entries:
            entries.append(relative_path)
    expected_sources[manifest_relative_path] = (
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n"
    )
    artifact_diffs = [
        _artifact_diff(repository, path, expected)
        for path, expected in expected_sources.items()
    ]
    summary_fields = (
        "path", "status", "expectedChars", "currentChars",
        "expectedSha256", "currentSha256", "diffTruncated",
    )
    artifacts = [
        {field: row[field] for field in summary_fields}
        for row in artifact_diffs
    ]
    return list(expected_sources), artifacts, artifact_diffs


def preview_dialogue_source(
    source_path: Path,
    *,
    repository: Path | None = None,
) -> dict[str, Any]:
    """Review and compile the canonical dialogue source without writing files."""

    repository = (repository or REPOSITORY).expanduser().resolve()
    source_path = source_path.expanduser().resolve()
    base: dict[str, Any] = {
        "ok": False,
        "type": "dialogue_dataset_compile_preview",
        "repository": str(repository),
        "sourcePath": str(source_path),
        "previewOnly": True,
        "effectFree": True,
        "writes": [],
        "generatedPaths": [],
    }
    try:
        document = load_dialogue_dataset(source_path)
    except (CompileError, OSError, ValueError) as error:
        return {
            **base,
            "diagnostics": [{"severity": "error", "message": str(error)}],
            "candidateReview": {"candidates": [], "collisions": []},
        }

    references, source_names = _source_reference_rows(document)
    candidates: list[dict[str, Any]] = []
    raw_patterns = document.get("patterns") if isinstance(document.get("patterns"), list) else []
    for pattern in raw_patterns[:MAX_DATASET_REVIEW_ROWS]:
        pattern_id = pattern.get("id") if isinstance(pattern, dict) else "<invalid>"
        candidates.append(_candidate_review_row("pattern", pattern_id, pattern, source_names))
    raw_pools = document.get("responsePools") if isinstance(document.get("responsePools"), list) else []
    for pool in raw_pools:
        if not isinstance(pool, dict):
            continue
        pool_id = _bounded_text(pool.get("id"), 192) or "<missing>"
        variants = pool.get("variants") if isinstance(pool.get("variants"), list) else []
        for variant in variants:
            variant_id = variant.get("id") if isinstance(variant, dict) else "<invalid>"
            candidates.append(_candidate_review_row("response", f"{pool_id}:{variant_id}", variant, source_names))
            if len(candidates) >= MAX_DATASET_REVIEW_ROWS:
                break
        if len(candidates) >= MAX_DATASET_REVIEW_ROWS:
            break

    collisions, collision_ids = _dataset_collisions(document)
    for candidate in candidates:
        pattern_id = candidate.get("id")
        if candidate.get("kind") != "pattern" or pattern_id not in collision_ids:
            continue
        candidate["status"] = "rejected"
        candidate["reason"] = "collision:" + ",".join(sorted(collision_ids[pattern_id]))

    counts = Counter(candidate["status"] for candidate in candidates)
    source = document.get("source") if isinstance(document.get("source"), dict) else {}
    source_references = (
        source.get("references")
        if isinstance(source.get("references"), list)
        else []
    )
    candidate_review = {
        "candidates": candidates,
        "summary": {key: counts[key] for key in ("approved", "rejected", "not_candidate")},
        "collisions": collisions,
        "provenance": {
            "sourceCount": len(references),
            "sourceNames": sorted(source_names),
            "approvedCount": counts["approved"],
            "approvedWithProvenance": sum(
                1 for candidate in candidates
                if candidate.get("status") == "approved" and candidate.get("sourceRefs")
            ),
            "integrationStatus": _integration_status(
                [reference for reference in source_references
                 if isinstance(reference, dict)]
            ),
        },
    }
    base["sourceMetadata"] = {
        "name": _bounded_text(source.get("name"), 128),
        "version": _bounded_text(source.get("version"), 32),
        "contentLicense": _bounded_text(source.get("contentLicense"), 128),
        "references": references,
        "integrationStatus": _integration_status(
            [reference for reference in source_references
             if isinstance(reference, dict)]
        ),
    }
    base["candidateReview"] = candidate_review

    try:
        compiled = compile_dialogue_dataset(document)
    except (CompileError, OSError, ValueError) as error:
        base["diagnostics"] = [{"severity": "error", "message": str(error)}]
        return base

    generated_paths, artifacts, artifact_diffs = _dialogue_preview_paths(compiled, repository)
    variant_count = sum(len(pool["variants"]) for pool in compiled["responsePools"])
    base.update({
        "ok": True,
        "diagnostics": [],
        "schema": document.get("schemaVersion"),
        "patternCount": len(compiled["patterns"]),
        "responsePoolCount": len(compiled["responsePools"]),
        "responseVariantCount": variant_count,
        "translationCounts": {
            language: len(values) for language, values in compiled["translations"].items()
        },
        "generatedPaths": generated_paths,
        "artifacts": artifacts,
        "artifactDiffs": artifact_diffs,
        "writes": [],
    })
    return base


def generate_dialogue_source(
    source_path: Path,
    *,
    repository: Path | None = None,
) -> dict[str, Any]:
    """Write approved dialogue artifacts through the existing Code Builder writer."""

    repository = (repository or REPOSITORY).expanduser().resolve()
    source_path = source_path.expanduser().resolve()
    preview = preview_dialogue_source(source_path, repository=repository)
    if preview.get("ok") is not True:
        return preview
    rejected = (preview.get("candidateReview") or {}).get("summary", {}).get("rejected", 0)
    if rejected:
        return {
            **preview,
            "ok": False,
            "generationApproved": False,
            "diagnostics": [{
                "severity": "error",
                "message": f"dialogue source contains {rejected} rejected dataset candidates",
            }],
            "writes": [],
        }
    try:
        source = load_dialogue_dataset(source_path)
        compiled = compile_dialogue_dataset(source)
        output = repository / DIALOGUE_OUTPUT_RELATIVE_PATH
        output.parent.mkdir(parents=True, exist_ok=True)
        written = write_dialogue_output(
            output,
            compiled,
        )
    except (CompileError, OSError, ValueError) as error:
        return {
            **preview,
            "ok": False,
            "generationApproved": True,
            "diagnostics": [{"severity": "error", "message": str(error)}],
            "writes": [],
        }
    post_write = preview_dialogue_source(source_path, repository=repository)
    return {
        **post_write,
        "generationApproved": True,
        "writes": [str(path) for path in written],
        "reloadedBy": "caller_restart_required",
    }
