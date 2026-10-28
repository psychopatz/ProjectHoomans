"""Manifest-backed Conversation source compiler and generated artifact plan.

Conversation authoring is deliberately compiled through this module instead of
adding another source loader beside CodeBuilder.  The manifest is the only
filesystem discovery boundary; all runtime and authoring consumers receive the
same merged, validated model.
"""

from __future__ import annotations

import copy
import hashlib
import json
import re
from pathlib import Path, PurePosixPath
from typing import Any, Iterable

from .dialogue_content import (
    _lua_value,
    _lua_string,
    compile_dialogue_content,
    render_dialogue_content_shard_plan,
)
from .dialogue_dataset import compile_dialogue_dataset
from .lexicon_compiler import CompileError
from .translation_support import DEFAULT_LANGUAGE, merge_language_sets, normalize_language
from .semantic_definition_compiler import (
    compile_semantic_definitions,
    discover_registered_capability_ids,
)


CONVERSATION_MANIFEST_SCHEMA = "pnc.conversation.manifest.v1"
CONVERSATION_SHARD_SCHEMA = "pnc.conversation.shard.v1"
CONVERSATION_MODEL_SCHEMA = "pnc.conversation.model.v1"
CONVERSATION_SOURCE_RELATIVE = Path(
    "tools/semantic_harness/codebuilder/sources/conversation"
)
CONVERSATION_MANIFEST_RELATIVE = CONVERSATION_SOURCE_RELATIVE / "manifest.json"
CONVERSATION_RUNTIME_RELATIVE = Path(
    "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/"
    "Semantics/Generated/Conversation"
)
CONVERSATION_UI_RUNTIME_RELATIVE = CONVERSATION_RUNTIME_RELATIVE / "UI/StaticSuggestions.lua"
CONVERSATION_MAX_SHARD_BYTES = 32 * 1024
CONVERSATION_MAX_RECORDS_PER_SHARD = 48
_ID = re.compile(r"^[a-z][a-z0-9_.:-]{0,127}$")
_SHARD_KINDS = frozenset(("content", "patterns", "responses", "flows", "ui"))


def _canonical_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def _fingerprint(value: Any) -> str:
    return hashlib.sha256(_canonical_json(value).encode("utf-8")).hexdigest()


def _read_json(path: Path, label: str) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise CompileError(f"cannot read {label} {path}: {error}") from error
    if not isinstance(value, dict):
        raise CompileError(f"{label} must contain an object: {path}")
    return value


def _copy_json(value: Any) -> Any:
    return copy.deepcopy(value)


def _source_metadata(documents: Iterable[dict[str, Any]]) -> dict[str, Any]:
    """Merge source provenance without silently dropping reviewed references."""
    first: dict[str, Any] | None = None
    references: dict[str, dict[str, Any]] = {}
    for document in documents:
        source = document.get("source")
        if not isinstance(source, dict):
            raise CompileError("Conversation shards require source metadata")
        if first is None:
            first = _copy_json(source)
        for reference in source.get("references", []):
            if not isinstance(reference, dict) or not isinstance(reference.get("name"), str):
                raise CompileError("Conversation source references require a name")
            name = reference["name"]
            previous = references.get(name)
            if previous is not None and _canonical_json(previous) != _canonical_json(reference):
                raise CompileError(f"conflicting source reference metadata: {name}")
            references[name] = _copy_json(reference)
    if first is None:
        raise CompileError("Conversation manifest has no source metadata")
    if references:
        first["references"] = [references[name] for name in sorted(references)]
    return first


def _validate_relative_json_path(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise CompileError(f"{label} must be a relative JSON path")
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts or "\\" in value:
        raise CompileError(f"{label} must stay below the Conversation source root")
    normalized = path.as_posix()
    if normalized != value or path.suffix.lower() != ".json":
        raise CompileError(f"{label} must be a normalized .json path")
    if normalized == "manifest.json":
        raise CompileError("manifest.json cannot also be a Conversation shard")
    return normalized


def _validate_id(value: Any, label: str) -> str:
    if not isinstance(value, str) or not _ID.fullmatch(value):
        raise CompileError(f"{label} must be a bounded canonical ID")
    return value


def _load_manifest(repository: Path, manifest_path: Path) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    manifest = _read_json(manifest_path, "Conversation manifest")
    if manifest.get("schema") != CONVERSATION_MANIFEST_SCHEMA:
        raise CompileError(
            f"Conversation manifest requires schema {CONVERSATION_MANIFEST_SCHEMA}"
        )
    shards = manifest.get("shards")
    if not isinstance(shards, list) or not shards:
        raise CompileError("Conversation manifest requires at least one shard")
    root = manifest_path.parent
    entries: list[dict[str, Any]] = []
    seen_paths: set[str] = set()
    for index, raw in enumerate(shards):
        if not isinstance(raw, dict):
            raise CompileError(f"Conversation manifest shard {index} must be an object")
        path_value = _validate_relative_json_path(raw.get("path"), f"shards[{index}].path")
        if path_value in seen_paths:
            raise CompileError(f"duplicate Conversation shard path: {path_value}")
        seen_paths.add(path_value)
        kind = raw.get("kind")
        if kind not in _SHARD_KINDS:
            raise CompileError(f"unsupported Conversation shard kind: {kind!r}")
        domain = _validate_id(raw.get("domain"), f"shards[{index}].domain")
        order = raw.get("order")
        if isinstance(order, bool) or not isinstance(order, int) or order < 0:
            raise CompileError(f"shards[{index}].order must be a non-negative integer")
        path = root / Path(*PurePosixPath(path_value).parts)
        if not path.is_file():
            raise CompileError(f"Conversation manifest shard is missing: {path_value}")
        entries.append({**_copy_json(raw), "path": path_value, "kind": kind, "domain": domain, "order": order})

    canonical_entries = sorted(entries, key=lambda item: (item["order"], item["path"]))
    if [item["path"] for item in entries] != [item["path"] for item in canonical_entries]:
        raise CompileError("Conversation manifest shards must use canonical order")

    discovered = {
        path.relative_to(root).as_posix()
        for path in root.rglob("*.json")
        if path.is_file() and path.name != "manifest.json"
    }
    unregistered = sorted(discovered - seen_paths)
    if unregistered:
        raise CompileError(
            "unregistered Conversation shards: " + ", ".join(unregistered)
        )
    return manifest, entries


def _validate_ui_shard(document: dict[str, Any], path: str) -> list[dict[str, Any]]:
    suggestions = document.get("suggestions")
    if not isinstance(suggestions, list):
        raise CompileError(f"UI shard {path} requires a suggestions list")
    seen: set[str] = set()
    result: list[dict[str, Any]] = []
    for index, suggestion in enumerate(suggestions):
        if not isinstance(suggestion, dict):
            raise CompileError(f"UI shard {path} suggestion {index} must be an object")
        suggestion_id = _validate_id(suggestion.get("id"), f"{path}.suggestions[{index}].id")
        if suggestion_id in seen:
            raise CompileError(f"duplicate UI suggestion id: {suggestion_id}")
        seen.add(suggestion_id)
        for field in ("topic", "patternID", "labelKey", "utteranceKey"):
            if not isinstance(suggestion.get(field), str) or not suggestion[field].strip():
                raise CompileError(f"{path}.{suggestion_id} requires {field}")
        order = suggestion.get("order")
        if isinstance(order, bool) or not isinstance(order, int):
            raise CompileError(f"{path}.{suggestion_id}.order must be an integer")
        result.append(_copy_json(suggestion))
    return result


def _compile_shard(
    document: dict[str, Any],
    entry: dict[str, Any],
    *,
    runtime_root: Path,
) -> dict[str, Any]:
    kind = entry["kind"]
    path = entry["path"]
    if document.get("schema") != CONVERSATION_SHARD_SCHEMA:
        raise CompileError(f"Conversation shard {path} requires schema {CONVERSATION_SHARD_SCHEMA}")
    if document.get("kind") != kind or document.get("domain") != entry["domain"]:
        raise CompileError(f"Conversation shard {path} does not match its manifest entry")
    source = document.get("source")
    if not isinstance(source, dict):
        raise CompileError(f"Conversation shard {path} requires source metadata")
    if kind == "content":
        compiled = compile_dialogue_content({
            "schemaVersion": 2,
            "source": source,
            "groups": document.get("groups"),
            "phraseFamilies": document.get("phraseFamilies"),
            "playerChoices": document.get("playerChoices", []),
        })
    elif kind in ("patterns", "responses"):
        compiled = compile_dialogue_dataset({
            "schemaVersion": 1,
            "source": source,
            "patterns": document.get("patterns", []) if kind == "patterns" else [],
            "responsePools": document.get("responsePools", []) if kind == "responses" else [],
        })
    elif kind == "flows":
        compiled = compile_semantic_definitions(
            {
                "schema": "pnc.semantic_authoring.v1",
                "source": source,
                "definitions": document.get("definitions"),
            },
            registered_capability_ids=discover_registered_capability_ids(runtime_root),
        )
    else:
        compiled = {"suggestions": _validate_ui_shard(document, path)}
    return compiled


def _merge_dialogue_sources(
    shards: list[tuple[dict[str, Any], dict[str, Any], str]],
) -> tuple[dict[str, Any], dict[str, Any]]:
    pattern_documents = [document for document, entry, _ in shards if entry["kind"] == "patterns"]
    response_documents = [document for document, entry, _ in shards if entry["kind"] == "responses"]
    all_documents = pattern_documents + response_documents
    if not all_documents:
        return {
            "source": {"name": "Project Hoomans Conversation", "version": "1", "references": []},
            "patterns": [],
            "responsePools": [],
        }, {}
    source = _source_metadata(all_documents)
    patterns = [item for document in pattern_documents for item in document.get("patterns", [])]
    pools = [item for document in response_documents for item in document.get("responsePools", [])]
    patterns.sort(key=lambda item: str(item.get("id", "")))
    pools.sort(key=lambda item: str(item.get("id", "")))
    compiled = compile_dialogue_dataset({
        "schemaVersion": 1,
        "source": source,
        "patterns": patterns,
        "responsePools": pools,
    })
    return compiled, compiled["translations"]


def _merge_semantic_sources(
    shards: list[tuple[dict[str, Any], dict[str, Any], str]],
    runtime_root: Path,
) -> dict[str, Any]:
    documents = [document for document, entry, _ in shards if entry["kind"] == "flows"]
    if not documents:
        return {"patterns": [], "flows": [], "responsePools": [], "translations": {}}
    source = _source_metadata(documents)
    source_owner = source.get("owner") or "ProjectHoomans"
    source_version = source.get("version") or "1"
    definitions = [item for document in documents for item in document.get("definitions", [])]
    definitions.sort(key=lambda item: str(item.get("id", "")))
    return compile_semantic_definitions(
        {
            "schema": "pnc.semantic_authoring.v1",
            "source": {"owner": source_owner, "version": source_version},
            "definitions": definitions,
        },
        registered_capability_ids=discover_registered_capability_ids(runtime_root),
    )


def _content_source(
    shards: list[tuple[dict[str, Any], dict[str, Any], str]],
) -> tuple[dict[str, Any], dict[str, str]]:
    documents = [document for document, entry, _ in shards if entry["kind"] == "content"]
    if not documents:
        raise CompileError("Conversation manifest requires at least one content shard")
    groups: dict[str, Any] = {}
    families: list[dict[str, Any]] = []
    choices: list[dict[str, Any]] = []
    for document in documents:
        for group, metadata in (document.get("groups") or {}).items():
            existing = groups.get(group)
            if existing is not None and _canonical_json(existing) != _canonical_json(metadata):
                raise CompileError(f"conflicting content group metadata: {group}")
            groups[group] = _copy_json(metadata)
        families.extend(_copy_json(document.get("phraseFamilies", [])))
        choices.extend(_copy_json(document.get("playerChoices", [])))
    families.sort(key=lambda item: str(item.get("semanticTemplateID", "")))
    choices.sort(key=lambda item: str(item.get("id", "")))
    source = _source_metadata(documents)
    compiled = compile_dialogue_content({
        "schemaVersion": 2,
        "source": source,
        "groups": {key: groups[key] for key in sorted(groups)},
        "phraseFamilies": families,
        "playerChoices": choices,
    })
    return compiled, source


def _add_global_id(
    locations: dict[str, dict[str, Any]],
    record_id: Any,
    *,
    kind: str,
    shard: dict[str, Any],
    path: str,
) -> None:
    if not isinstance(record_id, str) or not record_id:
        return
    previous = locations.get(record_id)
    if previous is not None:
        raise CompileError(
            f"duplicate global Conversation ID {record_id!r}: "
            f"{previous['sourceShard']} and {path}"
        )
    locations[record_id] = {
        "id": record_id,
        "kind": kind,
        "sourceShard": path,
        "domain": shard["domain"],
    }


def _ui_translations(ui: list[dict[str, Any]]) -> dict[str, dict[str, str]]:
    languages: set[str] = {DEFAULT_LANGUAGE}
    for suggestion in ui:
        raw = suggestion.get("translations")
        if isinstance(raw, dict):
            for raw_language in raw:
                languages.add(normalize_language(raw_language, "UI translation language"))
    translations = {language: {} for language in sorted(languages)}
    for suggestion in ui:
        raw = suggestion.get("translations")
        for language in sorted(languages):
            values = raw.get(language, {}) if isinstance(raw, dict) else {}
            for field, key in (
                ("label", suggestion.get("labelKey")),
                ("utterance", suggestion.get("utteranceKey")),
            ):
                value = values.get(field) if isinstance(values, dict) else None
                if not isinstance(value, str) or not value.strip():
                    if language == DEFAULT_LANGUAGE:
                        value = suggestion.get(
                            "labelFallback" if field == "label" else "utteranceFallback"
                        )
                    else:
                        continue
                if isinstance(key, str) and isinstance(value, str):
                    translations[language][key] = value
    return {
        language: {key: values[key] for key in sorted(values)}
        for language, values in sorted(translations.items())
        if values
    }


def compile_conversation_sources(
    repository: Path,
    *,
    manifest_path: Path | None = None,
    runtime_root: Path | None = None,
    source_overrides: dict[str, dict[str, Any]] | None = None,
) -> dict[str, Any]:
    """Load, validate, merge, sort, fingerprint, and index Conversation shards.

    source_overrides is an effect-free preview hook keyed by manifest-relative
    shard path. It never writes to disk and is used by the shared authoring
    service to validate edits against the complete Conversation model.
    """
    repository = repository.expanduser().resolve()
    manifest_path = (manifest_path or repository / CONVERSATION_MANIFEST_RELATIVE).expanduser().resolve()
    runtime_root = (runtime_root or repository).expanduser().resolve()
    manifest, entries = _load_manifest(repository, manifest_path)
    overrides = source_overrides or {}
    unknown_overrides = set(overrides) - {entry["path"] for entry in entries}
    if unknown_overrides:
        raise CompileError(
            "Conversation source override targets unknown shard(s): "
            + ", ".join(sorted(unknown_overrides))
        )
    loaded: list[tuple[dict[str, Any], dict[str, Any], str]] = []
    shard_reports: list[dict[str, Any]] = []
    for entry in entries:
        path = manifest_path.parent / Path(*PurePosixPath(entry["path"]).parts)
        if entry["path"] in overrides:
            document = _copy_json(overrides[entry["path"]])
            if not isinstance(document, dict):
                raise CompileError(
                    f"Conversation source override must be an object: {entry['path']}"
                )
        else:
            document = _read_json(path, "Conversation shard")
        compiled = _compile_shard(document, entry, runtime_root=runtime_root)
        record_ids: list[str] = []
        if entry["kind"] == "content":
            record_ids.extend(str(item["semanticTemplateID"]) for item in document.get("phraseFamilies", []))
            record_ids.extend(str(item["id"]) for item in document.get("playerChoices", []))
        elif entry["kind"] == "patterns":
            record_ids.extend(str(item["id"]) for item in document.get("patterns", []))
        elif entry["kind"] == "responses":
            record_ids.extend(str(item["id"]) for item in document.get("responsePools", []))
        elif entry["kind"] == "flows":
            record_ids.extend(str(item["id"]) for item in document.get("definitions", []))
        else:
            record_ids.extend(str(item["id"]) for item in document.get("suggestions", []))
        record_ids.sort()
        report = {
            "path": entry["path"],
            "kind": entry["kind"],
            "domain": entry["domain"],
            "order": entry["order"],
            "fingerprint": _fingerprint(document),
            "recordIDs": record_ids,
        }
        loaded.append((document, entry, report["fingerprint"]))
        shard_reports.append(report)

    content, content_source = _content_source(loaded)
    dialogue, _dialogue_translations = _merge_dialogue_sources(loaded)
    semantic = _merge_semantic_sources(loaded, runtime_root)
    ui = sorted(
        [item for document, entry, _ in loaded if entry["kind"] == "ui" for item in document.get("suggestions", [])],
        key=lambda item: (item.get("order", 0), item.get("id", "")),
    )

    locations: dict[str, dict[str, Any]] = {}
    for document, entry, _fingerprint_value in loaded:
        path = entry["path"]
        if entry["kind"] == "content":
            for family in document.get("phraseFamilies", []):
                _add_global_id(
                    locations,
                    "phrase." + str(family.get("semanticTemplateID")),
                    kind="content",
                    shard=entry,
                    path=path,
                )
            for choice in document.get("playerChoices", []):
                _add_global_id(locations, choice.get("id"), kind="content", shard=entry, path=path)
        elif entry["kind"] == "patterns":
            for pattern in document.get("patterns", []):
                _add_global_id(locations, pattern.get("id"), kind="pattern", shard=entry, path=path)
        elif entry["kind"] == "responses":
            for pool in document.get("responsePools", []):
                _add_global_id(locations, pool.get("id"), kind="responsePool", shard=entry, path=path)
        elif entry["kind"] == "flows":
            for definition in document.get("definitions", []):
                _add_global_id(locations, definition.get("id"), kind="flowDefinition", shard=entry, path=path)
                flow = definition.get("flow") if isinstance(definition, dict) else None
                if isinstance(flow, dict):
                    _add_global_id(locations, flow.get("id"), kind="flow", shard=entry, path=path)
                responses = definition.get("responses") if isinstance(definition, dict) else None
                if isinstance(responses, dict):
                    _add_global_id(locations, responses.get("poolID"), kind="responsePool", shard=entry, path=path)
        else:
            for suggestion in document.get("suggestions", []):
                _add_global_id(locations, suggestion.get("id"), kind="ui", shard=entry, path=path)

    available_patterns = {
        str(item.get("id")) for item in dialogue.get("patterns", [])
    } | {str(item.get("id")) for item in semantic.get("patterns", [])}
    external_pattern_ids = set(
        (manifest.get("externalReferences") or {}).get("patternIDs", [])
    )
    for suggestion in ui:
        pattern_id = suggestion.get("patternID")
        if pattern_id not in available_patterns and pattern_id not in external_pattern_ids:
            raise CompileError(
                f"UI suggestion {suggestion.get('id')} references unregistered pattern {pattern_id}"
            )

    for family in content["phraseFamilies"]:
        owner = locations.get("phrase." + str(family["semanticTemplateID"]))
        if owner is not None:
            family["conversationDomain"] = owner["domain"]
            family["sourceShard"] = owner["sourceShard"]
    for choice in content["playerChoices"]:
        owner = locations.get(choice["id"])
        if owner is not None:
            choice["conversationDomain"] = owner["domain"]
            choice["sourceShard"] = owner["sourceShard"]

    # Semantic-authoring patterns are generated from the flow definitions but
    # are still canonical runtime IDs. Register them globally so a later
    # shard cannot accidentally mint an ID already used by a data pattern.
    for pattern in semantic.get("patterns", []):
        pattern_id = pattern.get("id")
        if not isinstance(pattern_id, str):
            continue
        definition_id = ".".join(pattern_id.split(".")[:3])
        owner = locations.get(definition_id)
        if owner is not None:
            _add_global_id(
                locations,
                pattern_id,
                kind="pattern",
                shard={"domain": owner["domain"]},
                path=owner["sourceShard"],
            )

    identity_content = _copy_json(content)
    for family in identity_content.get("phraseFamilies", []):
        family.pop("conversationDomain", None)
        family.pop("sourceShard", None)
    for choice in identity_content.get("playerChoices", []):
        choice.pop("conversationDomain", None)
        choice.pop("sourceShard", None)
    semantic_payload = {
        "content": {
            key: value for key, value in identity_content.items()
            if key not in ("contentFingerprint",)
        },
        "dialogue": dialogue,
        "semantic": semantic,
        "ui": ui,
    }
    whole_fingerprint = _fingerprint(semantic_payload)
    locations = {key: locations[key] for key in sorted(locations)}
    model = {
        "schema": CONVERSATION_MODEL_SCHEMA,
        "manifestPath": str(manifest_path.relative_to(repository)),
        "manifest": manifest,
        "source": content_source,
        "content": content,
        "dialogue": dialogue,
        "semantic": semantic,
        "ui": ui,
        "uiTranslations": _ui_translations(ui),
        "shards": shard_reports,
        "locations": locations,
        "wholeModelFingerprint": whole_fingerprint,
        # Private build-time provenance used for shard-targeted authoring.
        # Private fields are never written into generated runtime artifacts.
        "_repository": repository,
        "_source_documents": {
            entry["path"]: document for document, entry, _ in loaded
        },
    }
    return model


def conversation_record(model: dict[str, Any], canonical_id: str) -> dict[str, Any] | None:
    location = (model.get("locations") or {}).get(str(canonical_id))
    if not isinstance(location, dict):
        return None
    return _copy_json(location)


def conversation_languages(model: dict[str, Any]) -> tuple[str, ...]:
    """Return locale codes present in the merged canonical Conversation model."""
    languages = merge_language_sets(
        model.get("content", {}).get("translations", {}),
        model.get("uiTranslations", {}),
        model.get("dialogue", {}).get("translations", {}),
        model.get("semantic", {}).get("translations", {}),
    )
    if DEFAULT_LANGUAGE not in languages:
        raise CompileError(f"Conversation content requires {DEFAULT_LANGUAGE} fallback translations")
    return languages


def conversation_translation_bundles(model: dict[str, Any]) -> dict[str, dict[str, dict[str, str]]]:
    """Partition generated translations by Conversation domain, not history."""
    languages = conversation_languages(model)
    bundles = {language: {} for language in languages}

    def add(language: str, domain: str, key: str, value: Any) -> None:
        if language not in bundles or not isinstance(key, str) or not isinstance(value, str):
            return
        bundles[language].setdefault(domain, {})[key] = value

    for family in model["content"].get("phraseFamilies", []):
        domain = str(family.get("conversationDomain") or family.get("group") or "general").title()
        keys = [
            phrase["key"]
            for phrases in family.get("styles", {}).values()
            for phrase in phrases
            if isinstance(phrase, dict) and isinstance(phrase.get("key"), str)
        ]
        for language in languages:
            values = model["content"].get("translations", {}).get(language, {})
            for key in keys:
                add(language, domain, key, values.get(key))
    for choice in model["content"].get("playerChoices", []):
        domain = str(choice.get("conversationDomain") or "greeting").title()
        for language in languages:
            values = model["content"].get("translations", {}).get(language, {})
            add(language, domain, choice.get("labelKey"), values.get(choice.get("labelKey")))
            add(language, domain, choice.get("choiceKey"), values.get(choice.get("choiceKey")))
    repository = model.get("_repository")
    for language in languages:
        for key, value in model.get("uiTranslations", {}).get(language, {}).items():
            add(language, "UI", key, value)
        if isinstance(repository, Path):
            suggestions_path = (
                repository
                / "Contents/mods/ProjectHoomans/common/media/translation"
                / language
                / "Conversation/Semantic/Suggestions.json"
            )
            if suggestions_path.is_file():
                try:
                    suggestions = json.loads(
                        suggestions_path.read_text(encoding="utf-8")
                    )
                except (OSError, UnicodeError, json.JSONDecodeError):
                    suggestions = {}
                if isinstance(suggestions, dict):
                    for key, value in suggestions.items():
                        add(language, "UI", key, value)
        for key, value in model.get("dialogue", {}).get("translations", {}).get(language, {}).items():
            add(language, "Patterns", key, value)
        for key, value in model.get("semantic", {}).get("translations", {}).get(language, {}).items():
            add(language, "Flows", key, value)
        bundles[language] = {
            domain: {key: values[key] for key in sorted(values)}
            for domain, values in sorted(bundles[language].items())
            if values
        }
    return bundles


def render_conversation_ui_module(model: dict[str, Any]) -> str:
    """Render the canonical generated static Conversation UI list."""
    return (
        "-- Generated by the manifest-backed Conversation compiler; do not edit by hand.\n"
        "return " + _lua_value(model["ui"], 0) + "\n"
    )



def render_conversation_lua_records(records: list[dict[str, Any]]) -> str:
    return "-- Generated; do not edit by hand.\nreturn " + _lua_value(records, 0) + "\n"


def _chunk_records(
    records: list[dict[str, Any]],
    *,
    kind: str,
    module_prefix: str,
    max_bytes: int = CONVERSATION_MAX_SHARD_BYTES,
) -> tuple[list[tuple[str, str]], list[dict[str, Any]]]:
    modules: list[tuple[str, str]] = []
    reports: list[dict[str, Any]] = []
    grouped: dict[str, list[dict[str, Any]]] = {}
    for record in records:
        domain = str(record.get("conversationDomain") or record.get("domain") or "general")
        grouped.setdefault(domain, []).append(record)
    for domain in sorted(grouped):
        items = sorted(grouped[domain], key=lambda item: str(item.get("id", "")))
        part = 0
        current: list[dict[str, Any]] = []
        for item in items:
            candidate = current + [item]
            rendered = render_conversation_lua_records(candidate)
            if current and (len(candidate) > CONVERSATION_MAX_RECORDS_PER_SHARD or len(rendered.encode("utf-8")) > max_bytes):
                part += 1
                name = domain.title().replace("_", "") + (f"Part{part:02d}" if part > 1 else "")
                module = f"{module_prefix}/{kind}/{name}"
                source = render_conversation_lua_records(current)
                modules.append((module, source))
                reports.append({"module": module, "kind": kind, "domain": domain, "recordCount": len(current), "bytes": len(source.encode("utf-8"))})
                current = [item]
            else:
                current = candidate
        if current:
            part += 1
            name = domain.title().replace("_", "") + (f"Part{part:02d}" if part > 1 else "")
            module = f"{module_prefix}/{kind}/{name}"
            source = render_conversation_lua_records(current)
            size = len(source.encode("utf-8"))
            if size > max_bytes:
                raise CompileError(f"generated Conversation {kind} shard exceeds {max_bytes} bytes: {module}")
            modules.append((module, source))
            reports.append({"module": module, "kind": kind, "domain": domain, "recordCount": len(current), "bytes": size})
    return modules, reports


def render_conversation_runtime_plan(model: dict[str, Any]) -> tuple[list[tuple[str, str]], list[dict[str, Any]]]:
    """Render bounded data modules for all merged Conversation domains."""
    prefix = "PNC/Semantics/Generated/Conversation"
    content_modules, content_reports = render_dialogue_content_shard_plan(
        model["content"], prefix, max_bytes=CONVERSATION_MAX_SHARD_BYTES
    )
    patterns = [*model["dialogue"].get("patterns", []), *model["semantic"].get("patterns", [])]
    patterns = [{**item, "domain": str(item.get("id", "general")).split(".")[2] if len(str(item.get("id", "")).split(".")) > 2 else "general"} for item in patterns]
    response_pools = [*model["dialogue"].get("responsePools", []), *model["semantic"].get("responsePools", [])]
    response_pools = [{**item, "domain": str(item.get("id", "general")).split(".")[1] if len(str(item.get("id", "")).split(".")) > 1 else "general"} for item in response_pools]
    flow_records = [{**item, "domain": "semantic"} for item in model["semantic"].get("flows", [])]
    ui_records = [{**item, "domain": str(item.get("topic") or "general")} for item in model["ui"]]
    pattern_modules, pattern_reports = _chunk_records(patterns, kind="Patterns", module_prefix=prefix)
    response_modules, response_reports = _chunk_records(response_pools, kind="Responses", module_prefix=prefix)
    flow_modules, flow_reports = _chunk_records(flow_records, kind="Flows", module_prefix=prefix)
    ui_modules, ui_reports = _chunk_records(ui_records, kind="UI", module_prefix=prefix)
    modules = [*content_modules, *pattern_modules, *response_modules, *flow_modules, *ui_modules]
    reports = [*content_reports, *pattern_reports, *response_reports, *flow_reports, *ui_reports]
    return modules, reports


def render_conversation_registry(model: dict[str, Any], reports: list[dict[str, Any]]) -> str:
    lines = [
        "-- Generated by the manifest-backed Conversation compiler; do not edit by hand.",
        "PNC = PNC or {}",
        "PNC.Semantics = PNC.Semantics or {}",
        "local Registry = PNC.Semantics.ConversationRegistry or {}",
        "PNC.Semantics.ConversationRegistry = Registry",
        f"Registry.SCHEMA = {_lua_string(CONVERSATION_MODEL_SCHEMA)}",
        "Registry.VERSION = 1",
        f"Registry.CONTENT_FINGERPRINT = {_lua_string(model['content']['contentFingerprint'])}",
        f"Registry.WHOLE_MODEL_FINGERPRINT = {_lua_string(model['wholeModelFingerprint'])}",
        "Registry.PHRASE_FAMILIES = {}",
        "Registry.PLAYER_CHOICES = {}",
        "Registry.PATTERNS = {}",
        "Registry.RESPONSE_POOLS = {}",
        "Registry.FLOWS = {}",
        "Registry.UI = {}",
    ]
    lines.extend([
        "local function appendContent(loaded)",
        "    if type(loaded) ~= \"table\" then return end",
        "    for key, value in pairs(loaded) do Registry.PHRASE_FAMILIES[key] = value end",
        "end",
        "local function appendContentChoices(loaded)",
        "    if type(loaded) ~= \"table\" then return end",
        "    for key, value in pairs(loaded) do Registry.PLAYER_CHOICES[key] = value end",
        "end",
        "local function appendPatterns(loaded)",
        "    if type(loaded) ~= \"table\" then return end",
        "    for _, value in ipairs(loaded) do Registry.PATTERNS[#Registry.PATTERNS + 1] = value end",
        "end",
        "local function appendResponses(loaded)",
        "    if type(loaded) ~= \"table\" then return end",
        "    for _, value in ipairs(loaded) do Registry.RESPONSE_POOLS[#Registry.RESPONSE_POOLS + 1] = value end",
        "end",
        "local function appendFlows(loaded)",
        "    if type(loaded) ~= \"table\" then return end",
        "    for _, value in ipairs(loaded) do Registry.FLOWS[#Registry.FLOWS + 1] = value end",
        "end",
        "local function appendUI(loaded)",
        "    if type(loaded) ~= \"table\" then return end",
        "    for _, value in ipairs(loaded) do Registry.UI[#Registry.UI + 1] = value end",
        "end",
    ])
    loaded_index = 0
    for report in reports:
        name = report["module"]
        loaded_index += 1
        loaded_name = f"loaded{loaded_index:02d}"
        lines.append(f"local {loaded_name} = require {_lua_string(name)}")
        if report["kind"] == "Content":
            lines.append(f"appendContent({loaded_name})")
        elif report["kind"] == "ContentChoices":
            lines.append(f"appendContentChoices({loaded_name})")
        elif report["kind"] == "Patterns":
            lines.append(f"appendPatterns({loaded_name})")
        elif report["kind"] == "Responses":
            lines.append(f"appendResponses({loaded_name})")
        elif report["kind"] == "Flows":
            lines.append(f"appendFlows({loaded_name})")
        elif report["kind"] == "UI":
            lines.append(f"appendUI({loaded_name})")
    lines.extend([
        "for key, family in pairs(Registry.PHRASE_FAMILIES) do",
        "    if type(family) == \"table\" and family.id then Registry.PHRASE_FAMILIES[key] = family end",
        "end",
        "function Registry.FamilyFor(templateID, style)",
        "    local family = Registry.PHRASE_FAMILIES[tostring(templateID or \"\")]",
        "    if type(family) ~= \"table\" then return nil end",
        "    local selectedStyle = tostring(style or \"neutral\")",
        "    local phrases = family.styles and family.styles[selectedStyle]",
        "    if type(phrases) ~= \"table\" then",
        "        selectedStyle = \"neutral\"",
        "        phrases = family.styles and family.styles[selectedStyle]",
        "    end",
        "    return family, type(phrases) == \"table\" and phrases or nil, selectedStyle",
        "end",
        "function Registry.PlayerChoice(contentID)",
        "    return Registry.PLAYER_CHOICES[tostring(contentID or \"\")]",
        "end",
        "return Registry",
        "",
    ])
    return "\n".join(lines)


def render_conversation_manifest_lua(model: dict[str, Any], reports: list[dict[str, Any]]) -> str:
    payload = {
        "schema": "pnc.conversation.runtime-manifest.v1",
        "wholeModelFingerprint": model["wholeModelFingerprint"],
        "shards": reports,
    }
    return (
        "-- Generated by the manifest-backed Conversation compiler; do not edit by hand.\n"
        "return " + _lua_value(payload, 0) + "\n"
    )
