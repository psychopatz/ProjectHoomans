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


CONTENT_SCHEMA = "pnc.semantic_dialogue_content.v2"
CONTENT_MANIFEST_SCHEMA = "pnc.conversation_content_manifest.v1"
CONTENT_SHARD_SCHEMA = "pnc.conversation_content_shard.v1"
CONTENT_SOURCE_NAME = "conversation/manifest.json"
CONTENT_SOURCE_RELATIVE = Path(
    "tools/semantic_harness/codebuilder/sources/conversation/manifest.json"
)
CONTENT_RUNTIME_RELATIVE = Path(
    "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/"
    "Semantics/Generated/DialogueContent/Registry.lua"
)
CONTENT_TRANSLATION_RELATIVE = Path(
    "Contents/mods/ProjectHoomans/common/media/translation"
)
CONTENT_TRANSLATION_STEM = "DialogueContent"
LANGUAGES = ("EN", "TL")
STYLES = ("neutral", "warm", "terse", "guarded")
ID_PATTERN = re.compile(r"^[a-z][a-z0-9_.:-]{0,127}$")
TRANSLATION_KEY_PATTERN = re.compile(r"^[A-Za-z][A-Za-z0-9_.-]{0,127}$")
MAX_FAMILIES = 512
MAX_PHRASES_PER_STYLE = 6
MAX_PLAYER_CONTENT = 32
MAX_RUNTIME_ALIASES = 512
MAX_TEXT = 256


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


def _read_json(path: Path, label: str) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise CompileError(f"cannot read {label} {path}: {error}") from error
    if not isinstance(value, dict):
        raise CompileError(f"{label} root must be an object: {path}")
    return value


def _shard_path(manifest_path: Path, value: Any) -> Path:
    if not isinstance(value, str) or not value.strip():
        raise CompileError("conversation content shard path must be a string")
    relative = Path(value)
    if relative.is_absolute() or ".." in relative.parts:
        raise CompileError(f"conversation content shard path escapes the manifest: {value}")
    return (manifest_path.parent / relative).resolve()


def load_dialogue_content_manifest(path: Path) -> dict[str, Any]:
    """Load the bounded authoring manifest without merging its shards."""
    manifest = _read_json(path, "dialogue content manifest")
    if manifest.get("schema") != CONTENT_MANIFEST_SCHEMA:
        raise CompileError("conversation content manifest schema is invalid")
    if manifest.get("schemaVersion") != 1:
        raise CompileError("conversation content manifest schemaVersion must be 1")
    source = manifest.get("source")
    groups = manifest.get("groups")
    shards = manifest.get("shards")
    if not isinstance(source, dict) or not isinstance(groups, dict):
        raise CompileError("conversation content manifest requires source and groups")
    if not isinstance(shards, list) or not shards:
        raise CompileError("conversation content manifest requires shards")
    seen_ids: set[str] = set()
    for index, shard in enumerate(shards, 1):
        if not isinstance(shard, dict):
            raise CompileError(f"conversation content manifest shard {index} must be an object")
        shard_id = shard.get("id")
        if not isinstance(shard_id, str) or not shard_id.strip():
            raise CompileError(f"conversation content manifest shard {index} requires an id")
        if shard_id in seen_ids:
            raise CompileError(f"duplicate conversation content shard id: {shard_id}")
        seen_ids.add(shard_id)
        _shard_path(path, shard.get("path"))
    return manifest


def _merge_dialogue_content_shards(path: Path, manifest: dict[str, Any]) -> dict[str, Any]:
    merged: dict[str, Any] = {
        "schemaVersion": 2,
        "source": manifest["source"],
        "groups": manifest["groups"],
        "phraseFamilies": [],
        "playerChoices": [],
        "runtimeAliases": [],
    }
    for index, descriptor in enumerate(manifest["shards"], 1):
        shard_path = _shard_path(path, descriptor.get("path"))
        shard = _read_json(shard_path, "dialogue content shard")
        if shard.get("schema") != CONTENT_SHARD_SCHEMA:
            raise CompileError(f"conversation content shard {shard_path} schema is invalid")
        if shard.get("schemaVersion") != 1:
            raise CompileError(f"conversation content shard {shard_path} schemaVersion must be 1")
        if shard.get("id") != descriptor.get("id"):
            raise CompileError(f"conversation content shard identity mismatch: {shard_path}")
        for key in ("phraseFamilies", "playerChoices", "runtimeAliases"):
            values = shard.get(key, [])
            if not isinstance(values, list):
                raise CompileError(f"{shard_path}: {key} must be a list")
            merged[key].extend(values)
    return merged


def load_dialogue_content_source(path: Path) -> dict[str, Any]:
    value = _read_json(path, "dialogue content source")
    if value.get("schema") == CONTENT_MANIFEST_SCHEMA:
        return _merge_dialogue_content_shards(
            path, load_dialogue_content_manifest(path)
        )
    return value


def dialogue_content_source_fingerprint(path: Path) -> str:
    """Fingerprint the manifest and every declared shard for stale guards."""
    manifest = load_dialogue_content_manifest(path)
    digest = hashlib.sha256()
    digest.update(path.read_bytes())
    for descriptor in manifest["shards"]:
        shard_path = _shard_path(path, descriptor.get("path"))
        digest.update(str(descriptor["id"]).encode("utf-8"))
        digest.update(shard_path.read_bytes())
    return digest.hexdigest()


def write_dialogue_content_source(path: Path, document: dict[str, Any]) -> list[Path]:
    """Write only shard records changed through the authoring service."""
    manifest = load_dialogue_content_manifest(path)
    family_by_id = {
        str(item.get("id") or "phrase." + str(item.get("semanticTemplateID") or "")): item
        for item in document.get("phraseFamilies", [])
        if isinstance(item, dict)
    }
    choice_by_id = {
        str(item.get("id")): item
        for item in document.get("playerChoices", [])
        if isinstance(item, dict) and item.get("id") is not None
    }
    alias_by_key = {
        str(item.get("runtimeKey")): item
        for item in document.get("runtimeAliases", [])
        if isinstance(item, dict) and item.get("runtimeKey") is not None
    }
    written: list[Path] = []
    for descriptor in manifest["shards"]:
        shard_path = _shard_path(path, descriptor.get("path"))
        shard = _read_json(shard_path, "dialogue content shard")
        for family in shard.get("phraseFamilies", []):
            if isinstance(family, dict):
                family_id = str(
                    family.get("id")
                    or "phrase." + str(family.get("semanticTemplateID") or "")
                )
                if family_id not in family_by_id:
                    raise CompileError(f"updated content lost family {family_id}")
                family.clear()
                family.update(family_by_id[family_id])
        for choice in shard.get("playerChoices", []):
            if isinstance(choice, dict):
                choice_id = str(choice.get("id"))
                if choice_id not in choice_by_id:
                    raise CompileError(f"updated content lost player choice {choice_id}")
                choice.clear()
                choice.update(choice_by_id[choice_id])
        for alias in shard.get("runtimeAliases", []):
            if isinstance(alias, dict):
                runtime_key = str(alias.get("runtimeKey"))
                if runtime_key not in alias_by_key:
                    raise CompileError(f"updated content lost runtime alias {runtime_key}")
                alias.clear()
                alias.update(alias_by_key[runtime_key])
        shard_path.write_text(
            json.dumps(shard, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
            newline="\n",
        )
        written.append(shard_path)
    return written


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
    if not isinstance(value, dict):
        raise CompileError(f"{label} requires EN and TL string values")
    output: dict[str, str] = {}
    for language in LANGUAGES:
        output[language] = _text(value.get(language), f"{label}.{language}")
    unsupported = set(value) - set(LANGUAGES)
    if unsupported:
        raise CompileError(
            f"{label} contains unsupported languages: {', '.join(sorted(unsupported))}"
        )
    return output


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
                "fallback": values["EN"],
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
    for language in LANGUAGES:
        translations[f"{label_key}:{language}"] = label_values[language]
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


def _runtime_alias(value: Any, semantic_ids: set[str], alias_keys: set[str]) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise CompileError("runtimeAliases entries must be objects")
    semantic_id = _id(value.get("semanticTemplateID"), "runtimeAlias.semanticTemplateID")
    if semantic_id not in semantic_ids:
        raise CompileError(
            f"runtime alias references an unknown semanticTemplateID: {semantic_id}"
        )
    runtime_key = _translation_key(value.get("runtimeKey"), "runtimeAlias.runtimeKey")
    if runtime_key in alias_keys:
        raise CompileError(f"duplicate runtime alias key: {runtime_key}")
    alias_keys.add(runtime_key)
    style = value.get("style", "neutral")
    if style not in STYLES:
        raise CompileError(f"runtime alias {runtime_key} has an invalid style: {style!r}")
    phrase_index = value.get("phraseIndex", 1)
    if not isinstance(phrase_index, int) or isinstance(phrase_index, bool):
        raise CompileError(f"runtime alias {runtime_key} phraseIndex must be an integer")
    if phrase_index < 1 or phrase_index > MAX_PHRASES_PER_STYLE:
        raise CompileError(
            f"runtime alias {runtime_key} phraseIndex is outside the bounded phrase range"
        )
    return {
        "runtimeKey": runtime_key,
        "semanticTemplateID": semantic_id,
        "style": style,
        "phraseIndex": phrase_index,
    }


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
    raw_aliases = document.get("runtimeAliases", [])
    if not isinstance(raw_aliases, list) or len(raw_aliases) > MAX_RUNTIME_ALIASES:
        raise CompileError(
            f"runtimeAliases must contain at most {MAX_RUNTIME_ALIASES} records"
        )

    family_ids: set[str] = set()
    semantic_ids: set[str] = set()
    player_ids: set[str] = set()
    phrase_ids: set[str] = set()
    translation_keys: set[str] = set()
    compiled_families: list[dict[str, Any]] = []
    translations_by_language = {language: {} for language in LANGUAGES}
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
            translations_by_language[language][key] = text

    compiled_player: list[dict[str, Any]] = []
    for raw_choice in raw_player:
        choice, values = _player_content(raw_choice, translation_keys)
        if choice["id"] in player_ids:
            raise CompileError(f"duplicate player choice id: {choice['id']}")
        player_ids.add(choice["id"])
        compiled_player.append(choice)
        for compound_key, text in values.items():
            key, language = compound_key.rsplit(":", 1)
            translations_by_language[language][key] = text

    aliases: list[dict[str, Any]] = []
    alias_keys: set[str] = set()
    family_by_semantic = {
        family["semanticTemplateID"]: family for family in compiled_families
    }
    for raw_alias in raw_aliases:
        alias = _runtime_alias(raw_alias, semantic_ids, alias_keys)
        family = family_by_semantic[alias["semanticTemplateID"]]
        phrases = family["styles"].get(alias["style"])
        if not phrases:
            phrases = family["styles"].get("neutral")
            alias["style"] = "neutral"
        phrase_index = min(alias["phraseIndex"], len(phrases))
        alias["phraseIndex"] = phrase_index
        phrase = phrases[phrase_index - 1]
        alias["canonicalKey"] = phrase["key"]
        for language in LANGUAGES:
            canonical_key = phrase["key"]
            translations_by_language[language][alias["runtimeKey"]] = (
                translations_by_language[language][canonical_key]
            )
        aliases.append(alias)

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
        "runtimeAliases": aliases,
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
    aliases = {
        alias["runtimeKey"]: {
            "semanticTemplateID": alias["semanticTemplateID"],
            "style": alias["style"],
            "phraseIndex": alias["phraseIndex"],
            "canonicalKey": alias["canonicalKey"],
        }
        for alias in compiled.get("runtimeAliases", [])
    }
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
        f"Registry.RUNTIME_ALIASES = {_lua_value(aliases, 0)}",
        "function Registry.ResolveTemplate(templateID, style)",
        "    local alias = Registry.RUNTIME_ALIASES[tostring(templateID or \"\")]",
        "    if type(alias) == \"table\" then",
        "        return alias.semanticTemplateID, alias.style or style or \"neutral\"",
        "    end",
        "    return tostring(templateID or \"\"), style or \"neutral\"",
        "end",
        "function Registry.FamilyFor(templateID, style)",
        "    local alias = Registry.RUNTIME_ALIASES[tostring(templateID or \"\")]",
        "    local resolvedID, resolvedStyle = Registry.ResolveTemplate(templateID, style)",
        "    local family = Registry.PHRASE_FAMILIES[resolvedID]",
        "    if type(family) ~= \"table\" then return nil end",
        "    local selectedStyle = tostring(resolvedStyle or \"neutral\")",
        "    local phrases = family.styles and family.styles[selectedStyle]",
        "    if type(phrases) ~= \"table\" then",
        "        selectedStyle = \"neutral\"",
        "        phrases = family.styles and family.styles[selectedStyle]",
        "    end",
        "    if type(alias) == \"table\" and type(phrases) == \"table\" then",
        "        local selected = phrases[tonumber(alias.phraseIndex) or 1]",
        "        phrases = selected and { selected } or phrases",
        "    end",
        "    return family, type(phrases) == \"table\" and phrases or nil, selectedStyle",
        "end",
        "function Registry.KeyFor(templateID, style)",
        "    local family, phrases = Registry.FamilyFor(templateID, style)",
        "    local first = phrases and phrases[1] or nil",
        "    return first and first.key or nil",
        "end",
        "function Registry.PlayerChoice(contentID)",
        "    return Registry.PLAYER_CHOICES[tostring(contentID or \"\")]",
        "end",
        "return Registry",
        "",
    ]
    return "\n".join(lines)


def render_dialogue_content_translation(compiled: dict[str, Any], language: str) -> str:
    language = str(language).upper()
    if language not in LANGUAGES:
        raise CompileError(f"unsupported dialogue content language: {language}")
    return json.dumps(
        compiled["translations"][language],
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ) + "\n"


def dialogue_content_artifact_paths(repository: Path) -> list[Path]:
    return [
        repository / CONTENT_RUNTIME_RELATIVE,
        *[
            repository / CONTENT_TRANSLATION_RELATIVE / language
            / "Conversation/Semantic" / f"{CONTENT_TRANSLATION_STEM}.json"
            for language in LANGUAGES
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
    for language in LANGUAGES:
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
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    written.append(manifest_path)
    return written
