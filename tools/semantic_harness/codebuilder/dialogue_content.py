"""Bounded Dialogue Content Registry compiler and artifact renderer.

The response catalog remains the owner of semantic/context variants and
SpeechRealization remains the owner of style selection.  This module owns the
small post-style phrase layer and the player-facing, verified content records
that Studio is allowed to edit.
"""

from __future__ import annotations

import hashlib
import json
import math
import re
from pathlib import Path
from typing import Any

from .lexicon_compiler import CompileError, _lua_string
from .translation_support import DEFAULT_LANGUAGE, normalize_translations, pretty_json


CONTENT_SCHEMA = "pnc.semantic_dialogue_content.v2"
CONTENT_SOURCE_NAME = "semantic_dialogue_content.json"
CONTENT_SOURCE_RELATIVE = Path(
    "tools/semantic_harness/codebuilder/sources/semantic_dialogue_content.json"
)
CONTENT_RUNTIME_RELATIVE = Path(
    "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/"
    "Semantics/Generated/DialogueContent/Registry.lua"
)
CONTENT_TRANSLATION_RELATIVE = Path(
    "Contents/mods/ProjectHoomans/common/media/translation"
)
CONTENT_TRANSLATION_STEM = "DialogueContent"
STYLES = ("neutral", "warm", "terse", "guarded")
ID_PATTERN = re.compile(r"^[a-z][a-z0-9_.:-]{0,127}$")
TRANSLATION_KEY_PATTERN = re.compile(r"^[A-Za-z][A-Za-z0-9_.-]{0,127}$")
MAX_FAMILIES = 256
MAX_PHRASES_PER_STYLE = 6
MAX_PLAYER_CONTENT = 32
MAX_TEXT = 256
CONVERSATION_CONTENT_MAX_SHARD_BYTES = 64 * 1024
CONVERSATION_CONTENT_MAX_FAMILIES_PER_SHARD = 48


def _canonical_json(value: Any) -> str:
    return json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )


def content_fingerprint(document: dict[str, Any]) -> str:
    return hashlib.sha256(_canonical_json(document).encode("utf-8")).hexdigest()


def source_fingerprint(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_dialogue_content_source(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise CompileError(f"cannot read dialogue content source {path}: {error}") from error
    if not isinstance(value, dict):
        raise CompileError("dialogue content source root must be an object")
    return value


def _text(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise CompileError(f"{label} must be a non-empty string")
    value = value.strip()
    if len(value) > MAX_TEXT:
        raise CompileError(f"{label} exceeds the {MAX_TEXT}-character limit")
    if any(ord(char) < 32 for char in value):
        raise CompileError(f"{label} contains a control character")
    return value


def _id(value: Any, label: str) -> str:
    value = _text(value, label)
    if not ID_PATTERN.fullmatch(value):
        raise CompileError(f"{label} has an invalid bounded ID: {value!r}")
    return value


def _translation_key(value: Any, label: str) -> str:
    value = _text(value, label)
    if not TRANSLATION_KEY_PATTERN.fullmatch(value):
        raise CompileError(f"{label} has an invalid translation key: {value!r}")
    return value


def _translations(value: Any, label: str) -> dict[str, str]:
    """Validate one locale map; EN is the only required fallback locale."""
    return normalize_translations(value, label)


def _metadata(value: Any) -> dict[str, str]:
    if not isinstance(value, dict):
        raise CompileError("dialogue content source requires source metadata")
    return {
        "name": _text(value.get("name"), "source.name"),
        "version": _text(value.get("version"), "source.version"),
        "contentLicense": _text(value.get("contentLicense"), "source.contentLicense"),
    }


def derived_canonical_concept(semantic_id: str) -> str:
    pieces = [piece for piece in re.split(r"[^A-Za-z0-9]+", semantic_id) if piece]
    return "_".join(piece.upper() for piece in pieces)


def _derived_translation_prefix(semantic_id: str) -> str:
    pieces = [piece for piece in re.split(r"[^A-Za-z0-9]+", semantic_id) if piece]
    return "UI_PNC_Conversation_Content_" + "".join(
        piece[:1].upper() + piece[1:] for piece in pieces
    )


def _phrase_family(
    value: Any,
    groups: dict[str, Any],
    phrase_ids: set[str],
    translation_keys: set[str],
) -> tuple[dict[str, Any], dict[str, str]]:
    if not isinstance(value, dict):
        raise CompileError("phraseFamilies entries must be objects")
    semantic_id = _id(value.get("semanticTemplateID"), "semanticTemplateID")
    group = _id(value.get("group"), f"{semantic_id}.group")
    group_metadata = groups.get(group)
    if not isinstance(group_metadata, dict):
        raise CompileError(f"{semantic_id}.group is not declared: {group}")
    family_id = "phrase." + semantic_id
    concept = derived_canonical_concept(semantic_id)
    prefix = _derived_translation_prefix(semantic_id)
    styles = value.get("styles")
    if not isinstance(styles, dict) or not styles:
        raise CompileError(f"{family_id}.styles requires at least one style")
    unsupported_styles = set(styles) - set(STYLES)
    if unsupported_styles:
        raise CompileError(
            f"{family_id}.styles contains unsupported styles: "
            + ", ".join(sorted(unsupported_styles))
        )

    compiled_styles: dict[str, list[dict[str, str]]] = {}
    translations: dict[str, str] = {}
    for style in STYLES:
        raw_phrases = styles.get(style)
        if raw_phrases is None:
            continue
        if not isinstance(raw_phrases, list) or not raw_phrases:
            raise CompileError(f"{family_id}.styles.{style} requires 1..{MAX_PHRASES_PER_STYLE} phrases")
        if len(raw_phrases) > MAX_PHRASES_PER_STYLE:
            raise CompileError(f"{family_id}.styles.{style} exceeds the phrase bound")
        compiled_phrases: list[dict[str, str]] = []
        for index, raw_phrase in enumerate(raw_phrases, 1):
            if not isinstance(raw_phrase, dict):
                raise CompileError(f"{family_id}.styles.{style}[{index}] must be an object")
            phrase_id = f"{family_id}.{style}.{index:02d}"
            if phrase_id in phrase_ids:
                raise CompileError(f"duplicate phrase id: {phrase_id}")
            phrase_ids.add(phrase_id)
            key = f"{prefix}{style.title()}{index:02d}"
            if key in translation_keys:
                raise CompileError(f"duplicate generated translation key: {key}")
            translation_keys.add(key)
            values = _translations(
                raw_phrase.get("translations"), f"{phrase_id}.translations"
            )
            compiled_phrases.append({
                "id": phrase_id,
                "key": key,
                # Keep the authored English fallback beside the key so a
                # missing/late translation never exposes a key to players.
                "fallback": values[DEFAULT_LANGUAGE],
            })
            translations.update({f"{key}:{language}": text for language, text in values.items()})
        compiled_styles[style] = compiled_phrases

    if not compiled_styles:
        raise CompileError(f"{family_id} has no compiled style phrases")
    content_owner = _text(
        group_metadata.get("contentOwner"), f"groups.{group}.contentOwner"
    )
    return {
        "id": family_id,
        "semanticTemplateID": semantic_id,
        "canonicalConcept": concept,
        "group": group,
        "styles": compiled_styles,
        "contentOwner": content_owner,
    }, translations


def _player_content(
    value: Any,
    translation_keys: set[str],
) -> tuple[dict[str, Any], dict[str, str]]:
    if not isinstance(value, dict):
        raise CompileError("playerChoices entries must be objects")
    content_id = _id(value.get("id"), "player choice id")
    kind = _text(value.get("kind"), f"{content_id}.kind")
    label_key = "UI_PNC_Conversation_Content_" + "".join(
        piece[:1].upper() + piece[1:]
        for piece in re.split(r"[^A-Za-z0-9]+", content_id) if piece
    ) + "_Label"
    choice_key = label_key[:-6] + "Choice"
    if label_key == choice_key or label_key in translation_keys or choice_key in translation_keys:
        raise CompileError(f"duplicate player-content translation key: {content_id}")
    translation_keys.update((label_key, choice_key))
    label_values = _translations(value.get("labelTranslations"), f"{content_id}.labelTranslations")
    choice_values = _translations(value.get("choiceTranslations"), f"{content_id}.choiceTranslations")
    translations: dict[str, str] = {}
    for language in sorted(set(label_values) | set(choice_values)):
        if language in label_values:
            translations[f"{label_key}:{language}"] = label_values[language]
        if language in choice_values:
            translations[f"{choice_key}:{language}"] = choice_values[language]
    return {
        "id": content_id,
        "kind": kind,
        "labelKey": label_key,
        "choiceKey": choice_key,
        "route": _text(value.get("route"), f"{content_id}.route"),
        "hubID": _text(value.get("hubID"), f"{content_id}.hubID"),
        "canonicalConcept": derived_canonical_concept(content_id),
    }, translations


def compile_dialogue_content(document: dict[str, Any]) -> dict[str, Any]:
    """Validate and compile content without producing any files."""
    if not isinstance(document, dict):
        raise CompileError("dialogue content source root must be an object")
    if document.get("schemaVersion") != 2:
        raise CompileError("dialogue content source schemaVersion must be 2")
    source = _metadata(document.get("source"))
    groups = document.get("groups")
    if not isinstance(groups, dict) or not groups:
        raise CompileError("dialogue content source requires groups")
    raw_families = document.get("phraseFamilies")
    if not isinstance(raw_families, list) or not raw_families:
        raise CompileError("dialogue content source requires phraseFamilies")
    if len(raw_families) > MAX_FAMILIES:
        raise CompileError(f"dialogue content source exceeds {MAX_FAMILIES} phrase families")
    raw_player = document.get("playerChoices", [])
    if not isinstance(raw_player, list) or len(raw_player) > MAX_PLAYER_CONTENT:
        raise CompileError(f"playerChoices must contain at most {MAX_PLAYER_CONTENT} records")

    family_ids: set[str] = set()
    semantic_ids: set[str] = set()
    player_ids: set[str] = set()
    phrase_ids: set[str] = set()
    translation_keys: set[str] = set()
    compiled_families: list[dict[str, Any]] = []
    translations_by_language: dict[str, dict[str, str]] = {}
    for raw_family in raw_families:
        family, values = _phrase_family(
            raw_family, groups, phrase_ids, translation_keys
        )
        if family["id"] in family_ids:
            raise CompileError(f"duplicate phrase family id: {family['id']}")
        if family["semanticTemplateID"] in semantic_ids:
            raise CompileError(f"duplicate phrase semanticTemplateID: {family['semanticTemplateID']}")
        family_ids.add(family["id"])
        semantic_ids.add(family["semanticTemplateID"])
        compiled_families.append(family)
        for compound_key, text in values.items():
            key, language = compound_key.rsplit(":", 1)
            translations_by_language.setdefault(language, {})[key] = text

    compiled_player: list[dict[str, Any]] = []
    for raw_choice in raw_player:
        choice, values = _player_content(raw_choice, translation_keys)
        if choice["id"] in player_ids:
            raise CompileError(f"duplicate player choice id: {choice['id']}")
        player_ids.add(choice["id"])
        compiled_player.append(choice)
        for compound_key, text in values.items():
            key, language = compound_key.rsplit(":", 1)
            translations_by_language.setdefault(language, {})[key] = text

    # Translation output is deliberately a flat string map.  Arrays here
    # would turn equivalent wording into a different runtime contract.
    for language, values in translations_by_language.items():
        if any(not isinstance(value, str) for value in values.values()):
            raise CompileError(f"{language} content translations must be ordinary strings")

    compiled = {
        "schema": CONTENT_SCHEMA,
        "schemaVersion": 2,
        "source": source,
        "phraseFamilies": compiled_families,
        "playerChoices": compiled_player,
        "translations": translations_by_language,
    }
    compiled["contentFingerprint"] = content_fingerprint(document)
    return compiled


def _lua_value(value: Any, indent: int = 0) -> str:
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, str):
        return _lua_string(value)
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        if not math.isfinite(value):
            raise CompileError("cannot render non-finite dialogue content number")
        return format(value, ".15g")
    if isinstance(value, list):
        lines = ["{"]
        for item in value:
            lines.append(" " * (indent + 4) + _lua_value(item, indent + 4) + ",")
        lines.append(" " * indent + "}")
        return "\n".join(lines)
    if isinstance(value, dict):
        lines = ["{"]
        for key in sorted(value):
            lines.append(
                " " * (indent + 4)
                + f"[{_lua_string(str(key))}] = "
                + _lua_value(value[key], indent + 4)
                + ","
            )
        lines.append(" " * indent + "}")
        return "\n".join(lines)
    raise CompileError(f"cannot render dialogue content value {type(value).__name__}")


def render_dialogue_content_registry(compiled: dict[str, Any]) -> str:
    """Render the data-only Lua registry and its tiny lookup API."""
    families = {
        family["semanticTemplateID"]: {
            "id": family["id"],
            "semanticTemplateID": family["semanticTemplateID"],
            "canonicalConcept": family["canonicalConcept"],
            "contentOwner": family.get("contentOwner"),
            "styles": family["styles"],
        }
        for family in compiled["phraseFamilies"]
    }
    choices = {choice["id"]: choice for choice in compiled["playerChoices"]}
    lines = [
        "-- Generated by tools/semantic_harness/codebuilder/build.py; do not edit by hand.",
        "-- Dialogue Content Registry: bounded post-style phrases and player content.",
        "PNC = PNC or {}",
        "PNC.Semantics = PNC.Semantics or {}",
        "local Registry = PNC.Semantics.DialogueContentRegistry or {}",
        "PNC.Semantics.DialogueContentRegistry = Registry",
        f"Registry.SCHEMA = {_lua_string(CONTENT_SCHEMA)}",
        "Registry.VERSION = 2",
        f"Registry.CONTENT_FINGERPRINT = {_lua_string(compiled['contentFingerprint'])}",
        f"Registry.PHRASE_FAMILIES = {_lua_value(families, 0)}",
        f"Registry.PLAYER_CHOICES = {_lua_value(choices, 0)}",
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
    ]
    return "\n".join(lines)


def _runtime_family(family: dict[str, Any]) -> dict[str, Any]:
    """Strip compiler provenance before a family enters a runtime shard."""
    return {
        "id": family["id"],
        "semanticTemplateID": family["semanticTemplateID"],
        "canonicalConcept": family["canonicalConcept"],
        "contentOwner": family.get("contentOwner"),
        "styles": family["styles"],
    }


def _content_shard_source(families: list[dict[str, Any]]) -> str:
    payload = {
        family["semanticTemplateID"]: _runtime_family(family)
        for family in sorted(families, key=lambda item: item["semanticTemplateID"])
    }
    return (
        "-- Generated by the manifest-backed Conversation compiler; do not edit by hand.\n"
        "return " + _lua_value(payload, 0) + "\n"
    )


def render_dialogue_content_compatibility_shim() -> str:
    """Keep existing runtime callers on the new Conversation registry hub."""
    return (
        "-- Generated compatibility shim; edit manifest-backed Conversation shards.\n"
        'return require "PNC/Semantics/Generated/Conversation/Registry"\n'
    )


def render_dialogue_content_shard_plan(
    compiled: dict[str, Any],
    module_prefix: str,
    *,
    max_bytes: int = CONVERSATION_CONTENT_MAX_SHARD_BYTES,
    max_families: int = CONVERSATION_CONTENT_MAX_FAMILIES_PER_SHARD,
) -> tuple[list[tuple[str, str]], list[dict[str, Any]]]:
    """Render bounded content and player-choice modules by semantic domain."""
    grouped: dict[str, list[dict[str, Any]]] = {}
    for family in compiled.get("phraseFamilies", []):
        grouped.setdefault(str(family.get("conversationDomain") or family.get("group") or "general"), []).append(family)
    modules: list[tuple[str, str]] = []
    reports: list[dict[str, Any]] = []
    for domain in sorted(grouped):
        families = sorted(grouped[domain], key=lambda item: item["semanticTemplateID"])
        part = 0
        current: list[dict[str, Any]] = []
        for family in families:
            candidate = current + [family]
            candidate_source = _content_shard_source(candidate)
            if current and (
                len(candidate) > max_families
                or len(candidate_source.encode("utf-8")) > max_bytes
            ):
                part += 1
                name = domain.title().replace("_", "") + (f"Part{part:02d}" if part > 1 else "")
                module = f"{module_prefix}/Content/{name}"
                source = _content_shard_source(current)
                modules.append((module, source))
                reports.append({
                    "module": module,
                    "kind": "Content",
                    "domain": domain,
                    "recordCount": len(current),
                    "bytes": len(source.encode("utf-8")),
                })
                current = [family]
            else:
                current = candidate
        if current:
            part += 1
            name = domain.title().replace("_", "") + (f"Part{part:02d}" if part > 1 else "")
            module = f"{module_prefix}/Content/{name}"
            source = _content_shard_source(current)
            size = len(source.encode("utf-8"))
            if size > max_bytes:
                raise CompileError(f"generated Conversation content shard exceeds {max_bytes} bytes: {module}")
            modules.append((module, source))
            reports.append({
                "module": module,
                "kind": "Content",
                "domain": domain,
                "recordCount": len(current),
                "bytes": size,
            })

    choices = compiled.get("playerChoices", [])
    if choices:
        payload = {
            choice["id"]: {
                key: value for key, value in choice.items()
                if key not in ("conversationDomain", "sourceShard")
            }
            for choice in sorted(choices, key=lambda item: item["id"])
        }
        source = (
            "-- Generated by the manifest-backed Conversation compiler; do not edit by hand.\n"
            "return " + _lua_value(payload, 0) + "\n"
        )
        if len(source.encode("utf-8")) > max_bytes:
            raise CompileError("generated Conversation player-choice shard exceeds its byte bound")
        module = f"{module_prefix}/Content/PlayerChoices"
        modules.append((module, source))
        reports.append({
            "module": module,
            "kind": "ContentChoices",
            "domain": "greeting",
            "recordCount": len(choices),
            "bytes": len(source.encode("utf-8")),
        })
    return modules, reports


def render_dialogue_content_hub(
    compiled: dict[str, Any],
    content_reports: list[dict[str, Any]],
    *,
    whole_model_fingerprint: str = "",
) -> str:
    """Render a small registry hub that loads bounded content modules."""
    lines = [
        "-- Generated by the manifest-backed Conversation compiler; do not edit by hand.",
        "PNC = PNC or {}",
        "PNC.Semantics = PNC.Semantics or {}",
        "local Registry = PNC.Semantics.ConversationRegistry or {}",
        "PNC.Semantics.ConversationRegistry = Registry",
        f"Registry.SCHEMA = {_lua_string(CONTENT_SCHEMA)}",
        "Registry.VERSION = 3",
        f"Registry.CONTENT_FINGERPRINT = {_lua_string(compiled['contentFingerprint'])}",
        f"Registry.WHOLE_MODEL_FINGERPRINT = {_lua_string(whole_model_fingerprint)}",
        "Registry.PHRASE_FAMILIES = {}",
        "Registry.PLAYER_CHOICES = {}",
        "local function loadFamilies(moduleName)",
        "    local loaded = require(moduleName)",
        "    if type(loaded) ~= \"table\" then return end",
        "    for key, value in pairs(loaded) do Registry.PHRASE_FAMILIES[key] = value end",
        "end",
        "local function loadChoices(moduleName)",
        "    local loaded = require(moduleName)",
        "    if type(loaded) ~= \"table\" then return end",
        "    for key, value in pairs(loaded) do Registry.PLAYER_CHOICES[key] = value end",
        "end",
    ]
    for report in content_reports:
        if report["kind"] == "Content":
            lines.append(f"loadFamilies({_lua_string(report['module'])})")
        elif report["kind"] == "ContentChoices":
            lines.append(f"loadChoices({_lua_string(report['module'])})")
    lines.extend([
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


def render_dialogue_content_manifest(
    reports: list[dict[str, Any]],
    *,
    whole_model_fingerprint: str,
) -> str:
    """Render a small generated runtime manifest with no phrase content."""
    payload = {
        "schema": "pnc.conversation.runtime-manifest.v1",
        "wholeModelFingerprint": whole_model_fingerprint,
        "shards": reports,
    }
    return (
        "-- Generated by the manifest-backed Conversation compiler; do not edit by hand.\n"
        "return " + _lua_value(payload, 0) + "\n"
    )


def render_dialogue_content_translation(compiled: dict[str, Any], language: str) -> str:
    language = str(language).strip().upper()
    values = compiled.get("translations", {}).get(language)
    if not isinstance(values, dict):
        raise CompileError(f"unsupported dialogue content language: {language}")
    return pretty_json({key: values[key] for key in sorted(values)})


def dialogue_content_artifact_paths(
    repository: Path,
    compiled: dict[str, Any] | None = None,
) -> list[Path]:
    languages: list[str]
    if isinstance(compiled, dict):
        languages = sorted(compiled.get("translations", {}))
    else:
        manifest_path = repository / CONTENT_TRANSLATION_RELATIVE / "manifests/Conversation.json"
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            languages = sorted((manifest.get("languages") or {}).keys())
        except (OSError, UnicodeError, json.JSONDecodeError, AttributeError):
            languages = [DEFAULT_LANGUAGE]
    return [
        repository / CONTENT_RUNTIME_RELATIVE,
        *[
            repository / CONTENT_TRANSLATION_RELATIVE / language
            / "Conversation/Semantic" / f"{CONTENT_TRANSLATION_STEM}.json"
            for language in languages
        ],
        repository / CONTENT_TRANSLATION_RELATIVE / "manifests/Conversation.json",
    ]


def write_dialogue_content_output(
    repository: Path,
    compiled: dict[str, Any],
) -> list[Path]:
    """Write only the registry, translation shards, and manifest entry."""
    repository = repository.expanduser().resolve()
    runtime_path = repository / CONTENT_RUNTIME_RELATIVE
    runtime_path.parent.mkdir(parents=True, exist_ok=True)
    runtime_path.write_text(
        render_dialogue_content_registry(compiled),
        encoding="utf-8",
        newline="\n",
    )
    written = [runtime_path]
    translation_root = repository / CONTENT_TRANSLATION_RELATIVE
    manifest_path = translation_root / "manifests/Conversation.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8")) if manifest_path.is_file() else {
        "version": 1,
        "languages": {},
    }
    for language in sorted(compiled.get("translations", {})):
        relative = f"{language}/Conversation/Semantic/{CONTENT_TRANSLATION_STEM}.json"
        path = translation_root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            render_dialogue_content_translation(compiled, language),
            encoding="utf-8",
            newline="\n",
        )
        written.append(path)
        entries = manifest.setdefault("languages", {}).setdefault(language, [])
        if relative not in entries:
            entries.append(relative)
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(
        pretty_json(manifest),
        encoding="utf-8",
        newline="\n",
    )
    written.append(manifest_path)
    return written
