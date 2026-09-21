"""Compile reviewed WordNet lemmas and verb morphology into compact Lua data.

Only base lemmas become aliases for existing Hoomans concepts. Inflected
forms stay in a separate morphology index so tense/aspect information does not
turn statements into executable commands.
"""

from __future__ import annotations

import hashlib
import json
import math
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any


DEFAULT_ALLOWLIST = Path(__file__).with_name("wordnet_concepts.json")
REQUIRED_FILES = ("index.verb", "data.verb", "verb.exc")
VOWELS = frozenset("aeiou")
CONCEPT_ID = re.compile(r"^[A-Z][A-Z0-9_]*$")
WORDNET_OFFSET = re.compile(r"^\d{8}$")
DIALOGUE_ID = re.compile(r"^[a-z][a-z0-9_.-]{0,95}$")
DIALOGUE_UTTERANCE = re.compile(r"^[a-z0-9']+(?: [a-z0-9']+)*$")
DIALOGUE_PATTERN_SUBJECTS = frozenset({"ACTIVITY", "IDENTITY", "WELLBEING"})
DIALOGUE_RESPONSE_CONDITIONS = frozenset({
    "topic", "previousTopic", "intent", "action", "subject",
    "relationshipState", "identityTrust", "timeBand", "raining", "foggy",
    "snowing", "indoors", "hasPendingRequest", "npcID", "activity",
    "busy", "needType", "needUrgency", "relationshipAttitude",
    "healthState", "socialStyle", "emotionType", "emotionUrgency",
    "hostilityCount", "insultCount", "lastSpeechAct",
})
DIALOGUE_MAX_PATTERNS = 128
DIALOGUE_MAX_POOLS = 32
DIALOGUE_MAX_VARIANTS_PER_POOL = 6
DIALOGUE_MAX_VARIANTS = 16
DIALOGUE_MAX_PATTERN_TOKENS = 16


class CompileError(ValueError):
    """Raised when the source database or allowlist is incomplete or unsafe."""


@dataclass(frozen=True)
class Synset:
    offset: str
    pos: str
    lemmas: tuple[str, ...]


@dataclass(frozen=True)
class CompiledLexicon:
    aliases_by_concept: dict[str, tuple[str, ...]]
    verb_forms_by_surface: dict[str, tuple[str, str, str]]
    source_version: str
    source_url: str
    source_license: str
    source_hashes: dict[str, str]
    license_text: str


def load_allowlist(path: Path = DEFAULT_ALLOWLIST) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise CompileError(f"cannot read allowlist {path}: {error}") from error
    if not isinstance(document, dict):
        raise CompileError("allowlist root must be an object")
    return document


def _read_index(path: Path) -> dict[str, tuple[str, ...]]:
    index: dict[str, tuple[str, ...]] = {}
    for line_number, line in enumerate(path.read_text(encoding="ascii").splitlines(), 1):
        if not line or line[0].isspace():
            continue
        fields = line.split()
        if len(fields) < 6 or fields[1] != "v":
            raise CompileError(f"invalid verb index row at {path}:{line_number}")
        try:
            synset_count = int(fields[2])
            pointer_count = int(fields[3])
        except ValueError as error:
            raise CompileError(f"invalid verb index counts at {path}:{line_number}") from error
        offset_start = 6 + pointer_count
        offsets = fields[offset_start:offset_start + synset_count]
        if len(offsets) != synset_count:
            raise CompileError(f"truncated verb index row at {path}:{line_number}")
        index[fields[0].lower()] = tuple(offsets)
    return index


def _read_synsets(path: Path) -> dict[str, Synset]:
    synsets: dict[str, Synset] = {}
    for line_number, line in enumerate(path.read_text(encoding="ascii").splitlines(), 1):
        if not line or line[0].isspace():
            continue
        entry = line.split("|", 1)[0].split()
        if len(entry) < 4:
            raise CompileError(f"invalid verb synset row at {path}:{line_number}")
        offset, _lex_file, pos = entry[:3]
        try:
            word_count = int(entry[3], 16)
        except ValueError as error:
            raise CompileError(f"invalid synset word count at {path}:{line_number}") from error
        word_end = 4 + word_count * 2
        if len(entry) < word_end:
            raise CompileError(f"truncated verb synset row at {path}:{line_number}")
        lemmas = tuple(entry[4 + index * 2].lower() for index in range(word_count))
        if offset in synsets:
            raise CompileError(f"duplicate WordNet synset offset {offset}")
        synsets[offset] = Synset(offset=offset, pos=pos, lemmas=lemmas)
    return synsets


def _read_exceptions(path: Path) -> dict[str, tuple[str, ...]]:
    forms_by_lemma: dict[str, set[str]] = {}
    for line_number, line in enumerate(path.read_text(encoding="ascii").splitlines(), 1):
        fields = line.split()
        if not fields:
            continue
        if len(fields) < 2:
            raise CompileError(f"invalid verb exception row at {path}:{line_number}")
        surface = fields[0].lower()
        for lemma in fields[1:]:
            forms_by_lemma.setdefault(lemma.lower(), set()).add(surface)
    return {lemma: tuple(sorted(forms)) for lemma, forms in forms_by_lemma.items()}


def _is_consonant_y(lemma: str) -> bool:
    return (len(lemma) > 1 and lemma.endswith("y")
            and lemma[-2] not in VOWELS)


def _is_cvc(lemma: str) -> bool:
    """Return whether the last letters support a bounded CVC doubling rule."""
    return (len(lemma) >= 3
            and lemma[-3] not in VOWELS
            and lemma[-2] in VOWELS
            and lemma[-1] not in VOWELS
            and lemma[-1] not in "wxy")


def _form_kind(surface: str) -> str:
    if surface.endswith("ing"):
        return "PROGRESSIVE"
    if surface.endswith("s"):
        return "THIRD_PERSON"
    return "PAST"


def _regular_verb_forms(lemma: str, *, allow_past: bool) -> dict[str, str]:
    """Generate common inflections as morphology, never as action aliases."""
    forms: dict[str, str] = {}
    if _is_consonant_y(lemma):
        forms[lemma[:-1] + "ies"] = "THIRD_PERSON"
    elif lemma.endswith(("s", "x", "z", "ch", "sh", "o")):
        forms[lemma + "es"] = "THIRD_PERSON"
    else:
        forms[lemma + "s"] = "THIRD_PERSON"

    if allow_past:
        if lemma.endswith("e"):
            forms[lemma + "d"] = "PAST"
        elif _is_consonant_y(lemma):
            forms[lemma[:-1] + "ied"] = "PAST"
        elif _is_cvc(lemma):
            forms[lemma + lemma[-1] + "ed"] = "PAST"
        else:
            forms[lemma + "ed"] = "PAST"

    if lemma.endswith("ie"):
        forms[lemma[:-2] + "ying"] = "PROGRESSIVE"
    elif lemma.endswith("e") and not lemma.endswith("ee"):
        forms[lemma[:-1] + "ing"] = "PROGRESSIVE"
    elif _is_cvc(lemma):
        forms[lemma + lemma[-1] + "ing"] = "PROGRESSIVE"
    else:
        forms[lemma + "ing"] = "PROGRESSIVE"
    return forms


def _lemma_surfaces(
    lemma: str,
    exception_forms: dict[str, tuple[str, ...]],
) -> tuple[str, dict[str, str]]:
    """Return a normalized lemma and constrained forms of its verb head.

    WordNet's exception lists provide irregular/doubled forms. The regular
    rules apply only to the first token of a selected verb lemma. The returned
    forms are tagged separately, so ``pick up`` may normalize to ``pick up``
    while ``picked up`` retains its past-tense tag.
    """
    pieces = lemma.split("_")
    head = pieces[0]
    tail = " ".join(pieces[1:])
    irregular = set(exception_forms.get(head, ()))
    forms = _regular_verb_forms(head, allow_past=not irregular)
    for surface in irregular:
        forms.setdefault(surface, _form_kind(surface))
    if tail:
        forms = {f"{form} {tail}": kind for form, kind in forms.items()}
    return " ".join(pieces), forms


def compile_wordnet(
    wordnet_home: Path,
    allowlist: dict[str, Any] | None = None,
) -> CompiledLexicon:
    """Compile the configured WordNet 3.0 synsets into Hoomans aliases."""
    document = allowlist if allowlist is not None else load_allowlist()
    source = document.get("source")
    concepts = document.get("concepts")
    if not isinstance(source, dict) or not isinstance(concepts, dict) or not concepts:
        raise CompileError("allowlist requires source metadata and concept mappings")
    version = str(source.get("version", ""))
    if version != "3.0":
        raise CompileError(f"unsupported WordNet version {version!r}; expected 3.0")

    license_path = wordnet_home / "LICENSE"
    try:
        license_text = license_path.read_text(encoding="utf-8")
    except OSError as error:
        raise CompileError(f"WordNet LICENSE not found under {wordnet_home}") from error
    if "WordNet Release 3.0" not in license_text:
        raise CompileError("WordNet LICENSE does not identify release 3.0")

    dictionary = wordnet_home / "dict"
    paths = {name: dictionary / name for name in REQUIRED_FILES}
    missing = [str(path) for path in paths.values() if not path.is_file()]
    if missing:
        raise CompileError("WordNet dictionary is missing: " + ", ".join(missing))

    source_hashes = {
        name: hashlib.sha256(path.read_bytes()).hexdigest()
        for name, path in paths.items()
    }
    source_hashes["LICENSE"] = hashlib.sha256(license_path.read_bytes()).hexdigest()
    expected_hashes = source.get("expected_sha256")
    if not isinstance(expected_hashes, dict):
        raise CompileError("allowlist must pin the WordNet 3.0 source file hashes")
    for name in (*REQUIRED_FILES, "LICENSE"):
        expected = expected_hashes.get(name)
        if not isinstance(expected, str) or source_hashes[name] != expected.lower():
            raise CompileError(f"WordNet source hash mismatch for {name}")
    verb_index = _read_index(paths["index.verb"])
    synsets = _read_synsets(paths["data.verb"])
    exception_forms = _read_exceptions(paths["verb.exc"])

    excluded_by_concept = document.get("excluded_forms", {})
    if not isinstance(excluded_by_concept, dict):
        raise CompileError("excluded_forms must be an object")

    aliases_by_concept: dict[str, set[str]] = {}
    verb_forms_by_surface: dict[str, tuple[str, str, str]] = {}
    surface_owners: dict[str, str] = {}
    for concept_id in sorted(concepts):
        if not isinstance(concept_id, str) or not CONCEPT_ID.fullmatch(concept_id):
            raise CompileError(f"invalid Hoomans concept id: {concept_id!r}")
        definition = concepts[concept_id]
        mappings = definition.get("synsets") if isinstance(definition, dict) else None
        if not isinstance(mappings, list) or not mappings:
            raise CompileError(f"{concept_id} must have at least one synset mapping")
        excluded = {
            phrase.strip().lower().replace("_", " ")
            for phrase in excluded_by_concept.get(concept_id, [])
            if isinstance(phrase, str)
        }
        aliases = aliases_by_concept.setdefault(concept_id, set())
        seen_mappings: set[tuple[str, str]] = set()
        for mapping in mappings:
            if not isinstance(mapping, dict):
                raise CompileError(f"invalid synset mapping for {concept_id}")
            pos = mapping.get("pos")
            offset = str(mapping.get("offset", ""))
            if pos != "v":
                raise CompileError(f"{concept_id} currently supports WordNet verbs only")
            if not WORDNET_OFFSET.fullmatch(offset):
                raise CompileError(f"invalid WordNet verb offset {offset!r}")
            if (pos, offset) in seen_mappings:
                raise CompileError(f"duplicate WordNet mapping {pos}:{offset} for {concept_id}")
            seen_mappings.add((pos, offset))
            synset = synsets.get(offset)
            if synset is None or synset.pos != "v":
                raise CompileError(f"WordNet verb synset {offset} was not found")
            lemmas = mapping.get("lemmas")
            if not isinstance(lemmas, list) or not lemmas:
                raise CompileError(f"{concept_id} synset {offset} needs explicit lemmas")
            for lemma in lemmas:
                if not isinstance(lemma, str) or not lemma:
                    raise CompileError(f"invalid selected lemma in {concept_id}:{offset}")
                lemma = lemma.lower()
                if lemma not in synset.lemmas:
                    raise CompileError(
                        f"{lemma!r} is not a member of WordNet verb synset {offset}")
                if offset not in verb_index.get(lemma, ()):
                    raise CompileError(
                        f"WordNet index does not map {lemma!r} to synset {offset}")
                head = lemma.split("_", 1)[0]
                if "_" in lemma and head not in verb_index:
                    raise CompileError(
                        f"WordNet verb head {head!r} for {lemma!r} is not indexed")
                lemma_surface, inflected_forms = _lemma_surfaces(
                    lemma, exception_forms)
                normalized_lemma = lemma_surface.lower().strip()
                if normalized_lemma and normalized_lemma not in excluded:
                    existing_owner = surface_owners.get(normalized_lemma)
                    if existing_owner and existing_owner != concept_id:
                        raise CompileError(
                            f"generated surface {normalized_lemma!r} maps to both "
                            f"{existing_owner} and {concept_id}")
                    surface_owners[normalized_lemma] = concept_id
                    aliases.add(normalized_lemma)

                for phrase, form_kind in inflected_forms.items():
                    normalized = phrase.lower().replace("_", " ").strip()
                    if not normalized or normalized in excluded:
                        continue
                    existing_owner = surface_owners.get(normalized)
                    if existing_owner and existing_owner != concept_id:
                        raise CompileError(
                            f"generated surface {normalized!r} maps to both "
                            f"{existing_owner} and {concept_id}")
                    surface_owners[normalized] = concept_id
                    form = (concept_id, normalized_lemma, form_kind)
                    existing_form = verb_forms_by_surface.get(normalized)
                    if existing_form is not None and existing_form != form:
                        raise CompileError(
                            f"generated verb form {normalized!r} maps to multiple lemmas")
                    verb_forms_by_surface[normalized] = form

    return CompiledLexicon(
        aliases_by_concept={
            concept: tuple(sorted(aliases))
            for concept, aliases in sorted(aliases_by_concept.items())
        },
        verb_forms_by_surface={
            surface: form
            for surface, form in sorted(verb_forms_by_surface.items())
        },
        source_version=version,
        source_url=str(source.get("url", "")),
        source_license=str(source.get("license", "")),
        source_hashes=source_hashes,
        license_text=license_text.rstrip(),
    )


def _lua_string(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def render_lua(compiled: CompiledLexicon) -> str:
    """Render stable Lua source with provenance and the required license notice."""
    lines = [
        "-- Generated by tools/semantic_compiler/build.py; do not edit by hand.",
        "-- Selected lexical data is derived from Princeton WordNet.",
        "-- WordNet source: " + compiled.source_url,
        "-- WordNet license: " + compiled.source_license,
        "-- Morphology: WordNet verb.exc plus allowlist-scoped regular forms, kept separate from action aliases.",
    ]
    for name, digest in sorted(compiled.source_hashes.items()):
        lines.append(f"-- SHA256 {name}: {digest}")
    lines.append("-- Begin WordNet 3.0 license notice.")
    lines.extend("-- " + line if line else "--" for line in compiled.license_text.splitlines())
    lines.append("-- End WordNet 3.0 license notice.")
    lines.extend([
        "",
        "return {",
        "    source = {",
        "        name = \"Princeton WordNet\",",
        f"        version = {_lua_string(compiled.source_version)},",
        f"        license = {_lua_string(compiled.source_license)},",
        "    },",
        "    aliasesByConcept = {",
    ])
    for concept_id, aliases in compiled.aliases_by_concept.items():
        lines.append(f"        [{_lua_string(concept_id)}] = {{")
        for alias in aliases:
            lines.append(f"            {_lua_string(alias)},")
        lines.append("        },")
    lines.extend([
        "    },",
        "    verbFormsBySurface = {",
    ])
    for surface, (concept_id, lemma, form_kind) in compiled.verb_forms_by_surface.items():
        lines.extend([
            f"        [{_lua_string(surface)}] = {{",
            f"            concept = {_lua_string(concept_id)},",
            f"            lemma = {_lua_string(lemma)},",
            f"            form = {_lua_string(form_kind)},",
            "        },",
        ])
    lines.extend([
        "    },",
        "}",
        "",
    ])
    return "\n".join(lines)


def load_dialogue_dataset(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise CompileError(f"cannot read dialogue dataset {path}: {error}") from error
    if not isinstance(document, dict):
        raise CompileError("dialogue dataset root must be an object")
    return document


def _normalize_dialogue_utterance(value: Any) -> tuple[str, tuple[str, ...]]:
    if not isinstance(value, str):
        raise CompileError("dialogue pattern utterance must be a string")
    text = value.lower()
    text = re.sub(r"[\x00-\x1f\x7f]", " ", text)
    text = re.sub(r'[, .!?;:()\[\]{}"]', " ", text)
    normalized = re.sub(r"\s+", " ", text).strip()
    if not normalized or not DIALOGUE_UTTERANCE.fullmatch(normalized):
        raise CompileError(
            f"dialogue utterance is empty or unsupported after normalization: {value!r}")
    tokens = tuple(normalized.split(" "))
    if len(tokens) > DIALOGUE_MAX_PATTERN_TOKENS:
        raise CompileError(f"dialogue utterance is too long: {value!r}")
    return normalized, tokens


def _validate_dialogue_source(value: Any) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise CompileError("dialogue dataset requires source metadata")
    name = value.get("name")
    version = value.get("version")
    content_license = value.get("contentLicense")
    references = value.get("references")
    if not all(isinstance(item, str) and item.strip()
               for item in (name, version, content_license)):
        raise CompileError(
            "dialogue source requires non-empty name, version, and contentLicense")
    if len(name) > 128 or len(version) > 32 or len(content_license) > 128:
        raise CompileError("dialogue source metadata exceeds its length limit")
    if not isinstance(references, list) or not references or len(references) > 8:
        raise CompileError("dialogue source requires 1 to 8 dataset references")
    normalized_references = []
    for reference in references:
        if not isinstance(reference, dict):
            raise CompileError("dialogue dataset references must be objects")
        reference_name = reference.get("name")
        url = reference.get("url")
        use = reference.get("use")
        if not all(isinstance(item, str) and item.strip()
                   for item in (reference_name, url, use)):
            raise CompileError(
                "each dialogue reference requires name, url, and use")
        if len(reference_name) > 128 or len(url) > 512 or len(use) > 256:
            raise CompileError("dialogue dataset reference exceeds its length limit")
        normalized_references.append({
            "name": reference_name.strip(),
            "url": url.strip(),
            "use": use.strip(),
        })
    return {
        "name": name.strip(),
        "version": version.strip(),
        "contentLicense": content_license.strip(),
        "references": normalized_references,
    }


def _compile_dialogue_pattern(value: Any) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise CompileError("dialogue patterns must be objects")
    if set(value) - {"id", "utterance", "emit", "confidence", "priority"}:
        raise CompileError("dialogue pattern contains unsupported fields")
    pattern_id = value.get("id")
    if not isinstance(pattern_id, str) or not DIALOGUE_ID.fullmatch(pattern_id):
        raise CompileError(f"invalid dialogue pattern id: {pattern_id!r}")
    _normalized, tokens = _normalize_dialogue_utterance(value.get("utterance"))

    emit = value.get("emit")
    if not isinstance(emit, dict):
        raise CompileError(f"dialogue pattern {pattern_id} requires an emit object")
    intent = emit.get("intent")
    speech_act = emit.get("speechAct")
    if intent == "QUESTION":
        subject = emit.get("subject")
        if (speech_act != "QUESTION"
            or not isinstance(subject, str)
            or subject not in DIALOGUE_PATTERN_SUBJECTS):
            raise CompileError(
                f"dialogue pattern {pattern_id} must target an existing safe question subject")
        if set(emit) != {"intent", "speechAct", "subject"}:
            raise CompileError(
                f"dialogue question pattern {pattern_id} contains unsupported semantic fields")
        normalized_emit = {
            "intent": "QUESTION",
            "speechAct": "QUESTION",
            "subject": subject,
        }
    elif intent == "GREET":
        if speech_act != "GREET" or set(emit) != {"intent", "speechAct"}:
            raise CompileError(
                f"dialogue greeting pattern {pattern_id} has an unsupported emit")
        normalized_emit = {"intent": "GREET", "speechAct": "GREET"}
    else:
        raise CompileError(
            f"dialogue pattern {pattern_id} targets an unsupported interaction")

    confidence = value.get("confidence", 0.98)
    if (isinstance(confidence, bool)
        or not isinstance(confidence, (int, float))
        or not math.isfinite(confidence)
        or confidence < 0.95 or confidence > 1.0):
        raise CompileError(
            f"dialogue pattern {pattern_id} requires confidence between 0.95 and 1.0")
    priority = value.get("priority", 100)
    if isinstance(priority, bool) or not isinstance(priority, int) or not 0 <= priority <= 255:
        raise CompileError(
            f"dialogue pattern {pattern_id} priority must be an integer from 0 to 255")

    return {
        "id": pattern_id,
        "match": [{"kind": "literal", "value": token} for token in tokens],
        "emit": normalized_emit,
        "confidence": float(confidence),
        "priority": priority,
    }


def _validate_response_condition(value: Any, pool_id: str, variant_id: str) -> dict[str, Any]:
    if value is None:
        return {}
    if not isinstance(value, dict):
        raise CompileError(
            f"response condition for {pool_id}:{variant_id} must be an object")
    output: dict[str, Any] = {}
    for field, expected in value.items():
        if field not in DIALOGUE_RESPONSE_CONDITIONS:
            raise CompileError(
                f"unsupported response condition {field!r} for {pool_id}:{variant_id}")
        values = expected if isinstance(expected, list) else [expected]
        if not values or len(values) > 8:
            raise CompileError(
                f"response condition {field!r} for {pool_id}:{variant_id} is empty or too broad")
        for item in values:
            if isinstance(item, str):
                if not item or len(item) > 96:
                    raise CompileError(
                        f"response condition value for {pool_id}:{variant_id} is invalid")
            elif isinstance(item, bool):
                pass
            elif isinstance(item, (int, float)) and math.isfinite(item):
                pass
            else:
                raise CompileError(
                    f"response condition value for {pool_id}:{variant_id} must be scalar")
        output[field] = values if isinstance(expected, list) else expected
    return output


def _compile_dialogue_response_pool(value: Any) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise CompileError("dialogue response pools must be objects")
    pool_id = value.get("id")
    variants = value.get("variants")
    if (not isinstance(pool_id, str)
        or not DIALOGUE_ID.fullmatch(pool_id)
        or not pool_id.startswith("semantic.")):
        raise CompileError(f"invalid dialogue response pool id: {pool_id!r}")
    if not isinstance(variants, list) or not variants:
        raise CompileError(f"dialogue response pool {pool_id} requires variants")
    if len(variants) > DIALOGUE_MAX_VARIANTS_PER_POOL:
        raise CompileError(
            f"dialogue response pool {pool_id} exceeds the supplemental variant limit")

    compiled_variants = []
    seen_ids: set[str] = set()
    for index, variant in enumerate(variants, 1):
        if not isinstance(variant, dict):
            raise CompileError(f"dialogue response {pool_id}:{index} must be an object")
        variant_id = variant.get("id")
        fallback = variant.get("fallback")
        if not isinstance(variant_id, str) or not DIALOGUE_ID.fullmatch(variant_id):
            raise CompileError(f"invalid dialogue response id in {pool_id}:{index}")
        if variant_id in seen_ids:
            raise CompileError(f"duplicate dialogue response id {variant_id}")
        seen_ids.add(variant_id)
        if (not isinstance(fallback, str) or not fallback.strip()
            or len(fallback) > 256
            or re.search(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]", fallback)):
            raise CompileError(f"invalid fallback text for {pool_id}:{variant_id}")
        template_id = variant.get("templateID", variant_id)
        if not isinstance(template_id, str) or not DIALOGUE_ID.fullmatch(template_id):
            raise CompileError(f"invalid template id for {pool_id}:{variant_id}")
        priority = variant.get("priority", 0)
        if isinstance(priority, bool) or not isinstance(priority, int) or not -10 <= priority <= 10:
            raise CompileError(
                f"response priority for {pool_id}:{variant_id} must be from -10 to 10")
        allowed_keys = {"id", "templateID", "fallback", "when", "priority"}
        if set(variant) - allowed_keys:
            raise CompileError(
                f"unsupported fields for dialogue response {pool_id}:{variant_id}")
        compiled_variant = {
            "id": variant_id,
            "templateID": template_id,
            "fallback": fallback.strip(),
        }
        condition = _validate_response_condition(variant.get("when"), pool_id, variant_id)
        if condition:
            compiled_variant["when"] = condition
        if priority != 0:
            compiled_variant["priority"] = priority
        compiled_variants.append(compiled_variant)
    return {"id": pool_id, "variants": compiled_variants}


def compile_dialogue_dataset(document: dict[str, Any]) -> dict[str, Any]:
    """Compile reviewed Hoomans interactions into bounded Lua data.

    Dataset references supply coverage guidance. Packaged utterances and
    response lines remain Hoomans-authored, and corpus turns are not copied.
    """
    if not isinstance(document, dict) or document.get("schemaVersion") != 1:
        raise CompileError("dialogue dataset requires schemaVersion 1")
    source = _validate_dialogue_source(document.get("source"))
    patterns = document.get("patterns")
    response_pools = document.get("responsePools")
    if not isinstance(patterns, list) or len(patterns) > DIALOGUE_MAX_PATTERNS:
        raise CompileError(
            f"dialogue dataset requires at most {DIALOGUE_MAX_PATTERNS} exact patterns")
    if not isinstance(response_pools, list) or len(response_pools) > DIALOGUE_MAX_POOLS:
        raise CompileError(
            f"dialogue dataset requires at most {DIALOGUE_MAX_POOLS} response pools")

    compiled_patterns = []
    seen_pattern_ids: set[str] = set()
    seen_utterances: dict[str, str] = {}
    for pattern in patterns:
        compiled = _compile_dialogue_pattern(pattern)
        if compiled["id"] in seen_pattern_ids:
            raise CompileError(f"duplicate dialogue pattern id {compiled['id']}")
        seen_pattern_ids.add(compiled["id"])
        normalized_utterance = " ".join(
            rule["value"] for rule in compiled["match"])
        previous = seen_utterances.get(normalized_utterance)
        if previous is not None:
            raise CompileError(
                f"dialogue utterance {normalized_utterance!r} is mapped by both "
                f"{previous} and {compiled['id']}")
        seen_utterances[normalized_utterance] = compiled["id"]
        compiled_patterns.append(compiled)

    compiled_pools = []
    seen_pool_ids: set[str] = set()
    seen_response_ids: set[str] = set()
    for pool in response_pools:
        compiled = _compile_dialogue_response_pool(pool)
        if compiled["id"] in seen_pool_ids:
            raise CompileError(f"duplicate dialogue response pool {compiled['id']}")
        seen_pool_ids.add(compiled["id"])
        for variant in compiled["variants"]:
            if variant["id"] in seen_response_ids:
                raise CompileError(f"duplicate dialogue response id {variant['id']}")
            seen_response_ids.add(variant["id"])
        compiled_pools.append(compiled)

    compiled_patterns.sort(key=lambda item: item["id"])
    compiled_pools.sort(key=lambda item: item["id"])
    return {
        "source": source,
        "patterns": compiled_patterns,
        "responsePools": compiled_pools,
    }


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
            raise CompileError("cannot render non-finite dialogue number")
        return format(value, ".15g")
    if isinstance(value, list):
        if not value:
            return "{}"
        lines = ["{"]
        for item in value:
            lines.append(" " * (indent + 4) + _lua_value(item, indent + 4) + ",")
        lines.append(" " * indent + "}")
        return "\n".join(lines)
    if isinstance(value, dict):
        if not value:
            return "{}"
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
    raise CompileError(f"cannot render dialogue value of type {type(value).__name__}")


def render_dialogue_lua(compiled: dict[str, Any]) -> str:
    """Render the bounded interaction seed for the existing Lua registries."""
    lines = [
        "-- Generated by tools/semantic_compiler/build.py; do not edit by hand.",
        "-- Exact Hoomans-authored interaction patterns and response variants.",
        "-- Referenced dialogue corpora provide coverage labels only; no turns are copied.",
        "return " + _lua_value(compiled),
        "",
    ]
    return "\n".join(lines)
