"""Compatibility facade for Semantic Lab compiler pipelines.

The concrete WordNet, dialogue, and typed semantic pipelines live in
purpose-specific modules. This facade preserves the established CodeBuilder
namespace and legacy import compatibility.
"""

from __future__ import annotations

import json
import math
import re
from pathlib import Path
from typing import Any

from .lexicon_compiler import (
    CANONICAL_SOURCE_ROOT,
    DEFAULT_ALLOWLIST,
    REQUIRED_FILES,
    VOWELS,
    CONCEPT_ID,
    WORDNET_OFFSET,
    CompileError,
    Synset,
    CompiledLexicon,
    _read_index,
    _read_synsets,
    _read_exceptions,
    _is_consonant_y,
    _is_cvc,
    _form_kind,
    _regular_verb_forms,
    _lemma_surfaces,
    _lua_string,
    load_allowlist,
    compile_wordnet,
    render_lua,
)

DIALOGUE_ID = re.compile(r"^[a-z][a-z0-9_.-]{0,95}$")
DIALOGUE_TEMPLATE_ID = re.compile(r"^[A-Za-z][A-Za-z0-9_.-]{0,95}$")
DIALOGUE_UTTERANCE = re.compile(r"^[a-z0-9']+(?: [a-z0-9']+)*$")
DIALOGUE_PATTERN_SUBJECTS = frozenset({
    "ACTIVITY", "IDENTITY", "WELLBEING", "WEATHER",
    "NPC_BACKSTORY", "CONTEXT_REFERENCE",
})
DIALOGUE_BACKSTORY_KINDS = frozenset({
    "former_job", "hometown", "education", "hobby",
    "family_background", "value", "survival_origin", "fear",
    "tragedy", "date_of_birth",
})
DIALOGUE_BACKSTORY_EXTENSIONS = frozenset({
    "factProvider", "topicID", "disclosure", "dialogueFollowUp",
    "responsePoolID",
})
DIALOGUE_BACKSTORY_DISCLOSURES = frozenset({
    "server_authorized", "confirmed", "suspected", "refused",
})
DIALOGUE_CONTEXT_REFERENCE_EXTENSIONS = frozenset({
    "dialogueFollowUp", "topic", "contextQuestion",
})
DIALOGUE_PROMISE_SUBJECTS = frozenset({"NEEDS"})
DIALOGUE_PROMISE_EXTENSIONS = frozenset({"topic", "dialogueFollowUp"})
DIALOGUE_MAPPING_FIELDS = frozenset({
    "canonicalConcept", "dialogueState", "sourceRefs",
})
DIALOGUE_MAPPING_CONCEPTS = frozenset({
    "ANY_ITEM", "FETCH", "WEATHER", "WELLBEING", "NPC_BACKSTORY",
    "CONTEXT_REFERENCE",
})
DIALOGUE_MAPPING_STATES = frozenset({
    "NEEDS_PROPOSAL", "NEEDS_QUANTITY", "WEATHER_TOPIC",
    "WELLBEING_FOLLOW_UP", "BACKSTORY_QUESTION", "BACKSTORY_FOLLOW_UP",
})
DIALOGUE_TRANSLATION_ARG_TYPES = frozenset({
    "string", "number", "boolean", "identifier", "fact_content",
})
DIALOGUE_PLAN_UNCERTAINTIES = frozenset({
    "known", "unknown", "ambiguous", "pending",
})
DIALOGUE_RESPONSE_CONDITIONS = frozenset({
    "topic", "previousTopic", "intent", "action", "subject",
    "pattern", "lastIntent", "relationshipState", "identityTrust",
    "timeBand", "raining", "foggy", "snowing", "indoors",
    "hasPendingRequest", "npcID", "activity", "busy", "needType",
    "needUrgency", "relationshipAttitude", "healthState", "socialStyle",
    "emotionType", "emotionUrgency", "hostilityCount", "insultCount",
    "lastSpeechAct",
})
DIALOGUE_MAX_PATTERNS = 128
DIALOGUE_MAX_POOLS = 32
DIALOGUE_MAX_VARIANTS_PER_POOL = 6
DIALOGUE_MAX_VARIANTS = 16
DIALOGUE_MAX_PATTERN_TOKENS = 16
DIALOGUE_MATCH_CONCEPTS = frozenset({"WEATHER"})
DIALOGUE_LUA_CHUNK_MAX_CHARS = 14000
SEMANTIC_SCHEMA = "pnc.semantic_authoring.v1"
SEMANTIC_FRAME_FIELDS = frozenset({
    "intent", "speechAct", "action", "subject", "target", "reference",
    "identityClaim", "selfDirected", "stateType", "stateValue", "pattern",
})
DEFAULT_REGISTERED_CAPABILITY_IDS = frozenset({
    "pnc:companion.follow", "pnc:companion.stop", "pnc:companion.stay",
    "pnc:companion.return_home", "pnc:companion.camp", "pnc:task.wait_at",
    "pnc:gift.offer",
})
DEFAULT_RESERVED_UTTERANCES = frozenset({
    "follow", "follow me", "stop", "wait", "wait here",
})


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
        license_name = reference.get("license")
        reviewed_on = reference.get("reviewedOn")
        if not all(isinstance(item, str) and item.strip()
                   for item in (reference_name, url, use, license_name,
                                reviewed_on)):
            raise CompileError(
                "each dialogue reference requires name, url, use, license, and reviewedOn")
        if (len(reference_name) > 128 or len(url) > 512 or len(use) > 256
                or len(license_name) > 128 or len(reviewed_on) > 32):
            raise CompileError("dialogue dataset reference exceeds its length limit")
        normalized_references.append({
            "name": reference_name.strip(),
            "url": url.strip(),
            "use": use.strip(),
            "license": license_name.strip(),
            "reviewedOn": reviewed_on.strip(),
        })
    return {
        "name": name.strip(),
        "version": version.strip(),
        "contentLicense": content_license.strip(),
        "references": normalized_references,
    }


def _validate_source_refs(
    value: Any,
    available: set[str],
    label: str,
) -> list[str]:
    if not isinstance(value, list) or not value or len(value) > 4:
        raise CompileError(f"{label} requires 1 to 4 source references")
    normalized = []
    for item in value:
        if not isinstance(item, str) or not item.strip():
            raise CompileError(f"{label} contains an invalid source reference")
        item = item.strip()
        if item not in available:
            raise CompileError(f"{label} references unknown source {item!r}")
        if item not in normalized:
            normalized.append(item)
    return normalized


def _compile_dialogue_match(value: Any, pattern_id: str) -> list[dict[str, str]]:
    if not isinstance(value, list) or not value:
        raise CompileError(
            f"dialogue pattern {pattern_id} match must be a non-empty list"
        )
    if len(value) > DIALOGUE_MAX_PATTERN_TOKENS:
        raise CompileError(
            f"dialogue pattern {pattern_id} match exceeds the token limit"
        )
    compiled: list[dict[str, str]] = []
    for rule in value:
        if not isinstance(rule, dict) or set(rule) - {
            "kind", "value", "id", "capture", "minTokens", "maxTokens",
        }:
            raise CompileError(
                f"dialogue pattern {pattern_id} match contains an invalid rule"
            )
        kind = rule.get("kind")
        if kind == "literal":
            normalized, tokens = _normalize_dialogue_utterance(rule.get("value"))
            if len(tokens) != 1:
                raise CompileError(
                    f"dialogue pattern {pattern_id} literal match rules must contain one token"
                )
            compiled_rule: dict[str, Any] = {
                "kind": "literal", "value": normalized,
            }
            if "capture" in rule:
                capture = rule.get("capture")
                if (not isinstance(capture, str) or not re.fullmatch(
                    r"[a-z][a-zA-Z0-9_]{0,31}", capture
                )):
                    raise CompileError(
                        f"dialogue pattern {pattern_id} literal capture is invalid"
                    )
                compiled_rule["capture"] = capture
            compiled.append(compiled_rule)
            continue
        if kind == "concept":
            concept_id = rule.get("id")
            if concept_id not in DIALOGUE_MATCH_CONCEPTS:
                raise CompileError(
                    f"dialogue pattern {pattern_id} references an unsupported match concept"
                )
            compiled_rule = {"kind": "concept", "id": concept_id}
            if "capture" in rule:
                capture = rule.get("capture")
                if (not isinstance(capture, str) or not re.fullmatch(
                    r"[a-z][a-zA-Z0-9_]{0,31}", capture
                )):
                    raise CompileError(
                        f"dialogue pattern {pattern_id} concept capture is invalid"
                    )
                compiled_rule["capture"] = capture
            compiled.append(compiled_rule)
            continue
        if kind == "any_phrase":
            capture = rule.get("capture")
            minimum = rule.get("minTokens", 1)
            maximum = rule.get("maxTokens", 4)
            if (not isinstance(capture, str) or not re.fullmatch(
                r"[a-z][a-zA-Z0-9_]{0,31}", capture
            ) or isinstance(minimum, bool) or not isinstance(minimum, int)
                    or isinstance(maximum, bool) or not isinstance(maximum, int)
                    or minimum < 1 or maximum < minimum
                    or maximum > DIALOGUE_MAX_PATTERN_TOKENS):
                raise CompileError(
                    f"dialogue pattern {pattern_id} any_phrase capture bounds are invalid"
                )
            compiled.append({
                "kind": "any_phrase",
                "capture": capture,
                "minTokens": minimum,
                "maxTokens": maximum,
            })
            continue
        raise CompileError(
            f"dialogue pattern {pattern_id} match kind must be literal, concept, or any_phrase"
        )
    return compiled


def _compile_dialogue_pattern(
    value: Any,
    source_names: set[str],
) -> tuple[dict[str, Any], list[str]]:
    if not isinstance(value, dict):
        raise CompileError("dialogue patterns must be objects")
    allowed_fields = {
        "id", "utterance", "emit", "confidence", "priority", "negatives",
        "reviewed", "sourceRefs", "mapping", "match",
    }
    if set(value) - allowed_fields:
        raise CompileError("dialogue pattern contains unsupported fields")
    pattern_id = value.get("id")
    if not isinstance(pattern_id, str) or not DIALOGUE_ID.fullmatch(pattern_id):
        raise CompileError(f"invalid dialogue pattern id: {pattern_id!r}")
    _normalized, tokens = _normalize_dialogue_utterance(value.get("utterance"))
    compiled_match = _compile_dialogue_match(
        value["match"], pattern_id
    ) if "match" in value else [
        {"kind": "literal", "value": token} for token in tokens
    ]

    emit = value.get("emit")
    if not isinstance(emit, dict):
        raise CompileError(f"dialogue pattern {pattern_id} requires an emit object")
    intent = emit.get("intent")
    speech_act = emit.get("speechAct")
    if intent == "QUESTION":
        subject = emit.get("subject")
        if (speech_act != "QUESTION" or not isinstance(subject, str)):
            raise CompileError(
                f"dialogue pattern {pattern_id} must target an existing safe question subject")
        if subject in {"ACTIVITY", "IDENTITY", "WELLBEING", "WEATHER"}:
            if set(emit) != {"intent", "speechAct", "subject"}:
                raise CompileError(
                    f"dialogue question pattern {pattern_id} contains unsupported semantic fields")
            normalized_emit = {
                "intent": "QUESTION",
                "speechAct": "QUESTION",
                "subject": subject,
            }
        elif subject == "NPC_BACKSTORY":
            slots = emit.get("slots")
            extensions = emit.get("extensions")
            if (set(emit) != {
                    "intent", "speechAct", "subject", "slots", "extensions",
                }
                    or not isinstance(slots, dict)
                    or set(slots) != {"backstoryKind"}
                    or slots.get("backstoryKind") not in DIALOGUE_BACKSTORY_KINDS
                    or not isinstance(extensions, dict)
                    or set(extensions) - DIALOGUE_BACKSTORY_EXTENSIONS
                    or extensions.get("factProvider") != "npc_backstory"
                    or extensions.get("topicID") != (
                        "backstory." + str(slots.get("backstoryKind"))
                    )
                    or extensions.get("disclosure")
                    not in DIALOGUE_BACKSTORY_DISCLOSURES):
                raise CompileError(
                    f"dialogue backstory pattern {pattern_id} requires a typed fact provider, kind, topic, and disclosure"
                )
            if ("dialogueFollowUp" in extensions
                    and extensions["dialogueFollowUp"] != "CONTEXT_REFERENCE"):
                raise CompileError(
                    f"dialogue backstory pattern {pattern_id} has an unsupported follow-up contract"
                )
            normalized_emit = {
                "intent": "QUESTION",
                "speechAct": "QUESTION",
                "subject": "NPC_BACKSTORY",
                "slots": {"backstoryKind": slots["backstoryKind"]},
                "extensions": {
                    key: extensions[key] for key in sorted(extensions)
                },
            }
        elif subject == "CONTEXT_REFERENCE":
            extensions = emit.get("extensions")
            if (set(emit) - {
                    "intent", "speechAct", "subject", "target", "extensions",
                }
                    or not isinstance(extensions, dict)
                    or set(extensions) != DIALOGUE_CONTEXT_REFERENCE_EXTENSIONS
                    or extensions.get("dialogueFollowUp") != "CONTEXT_REFERENCE"
                    or not isinstance(emit.get("target"), str)
                    or not emit["target"].startswith("$capture.")):
                raise CompileError(
                    f"dialogue context-reference pattern {pattern_id} requires a capture target and follow-up metadata"
                )
            normalized_emit = {
                "intent": "QUESTION",
                "speechAct": "QUESTION",
                "subject": "CONTEXT_REFERENCE",
                "target": emit["target"],
                "extensions": {
                    key: extensions[key] for key in sorted(extensions)
                },
            }
        elif subject == "QUANTITY":
            extensions = emit.get("extensions")
            if (set(emit) != {
                    "intent", "speechAct", "subject", "extensions",
                }
                    or not isinstance(extensions, dict)
                    or set(extensions) != DIALOGUE_PROMISE_EXTENSIONS
                    or extensions.get("topic") != "NEEDS"
                    or extensions.get("dialogueFollowUp") != "NEEDS_QUANTITY"):
                raise CompileError(
                    f"dialogue quantity clarification pattern {pattern_id} must target the existing needs flow")
            normalized_emit = {
                "intent": "QUESTION",
                "speechAct": "QUESTION",
                "subject": "QUANTITY",
                "extensions": {
                    "topic": "NEEDS",
                    "dialogueFollowUp": "NEEDS_QUANTITY",
                },
            }
        else:
            raise CompileError(
                f"dialogue pattern {pattern_id} must target an existing safe question subject")
    elif intent == "GREET":
        if speech_act != "GREET" or set(emit) != {"intent", "speechAct"}:
            raise CompileError(
                f"dialogue greeting pattern {pattern_id} has an unsupported emit")
        normalized_emit = {"intent": "GREET", "speechAct": "GREET"}
    elif intent == "CLARIFY":
        extensions = emit.get("extensions")
        if (speech_act != "CLARIFY"
                or emit.get("subject") != "NEEDS"
                or set(emit) != {
                    "intent", "speechAct", "subject", "extensions",
                }
                or not isinstance(extensions, dict)
                or set(extensions) != DIALOGUE_PROMISE_EXTENSIONS
                or extensions.get("topic") != "NEEDS"
                or extensions.get("dialogueFollowUp") != "NEEDS_QUANTITY"):
            raise CompileError(
                f"dialogue clarification pattern {pattern_id} must target the existing needs flow")
        normalized_emit = {
            "intent": "CLARIFY",
            "speechAct": "CLARIFY",
            "subject": "NEEDS",
            "extensions": {
                "topic": "NEEDS",
                "dialogueFollowUp": "NEEDS_QUANTITY",
            },
        }
    elif intent == "PROMISE":
        extensions = emit.get("extensions")
        if (speech_act != "PROMISE"
                or emit.get("subject") not in DIALOGUE_PROMISE_SUBJECTS
                or set(emit) != {
                    "intent", "speechAct", "subject", "extensions",
                }
                or not isinstance(extensions, dict)
                or set(extensions) != DIALOGUE_PROMISE_EXTENSIONS
                or extensions.get("topic") != "NEEDS"
                or extensions.get("dialogueFollowUp") != "NEEDS_PROPOSAL"):
            raise CompileError(
                f"dialogue promise pattern {pattern_id} must target the existing needs proposal flow")
        normalized_emit = {
            "intent": "PROMISE",
            "speechAct": "PROMISE",
            "subject": "NEEDS",
            "extensions": {
                "topic": "NEEDS",
                "dialogueFollowUp": "NEEDS_PROPOSAL",
            },
        }
    else:
        raise CompileError(
            f"dialogue pattern {pattern_id} targets an unsupported interaction")

    reviewed = value.get("reviewed", False)
    if not isinstance(reviewed, bool):
        raise CompileError(f"dialogue pattern {pattern_id} reviewed must be boolean")
    source_refs = []
    if "sourceRefs" in value:
        source_refs = _validate_source_refs(
            value["sourceRefs"], source_names,
            f"dialogue pattern {pattern_id} sourceRefs",
        )
    mapping = value.get("mapping")
    normalized_mapping = None
    if mapping is not None:
        if not isinstance(mapping, dict) or set(mapping) - DIALOGUE_MAPPING_FIELDS:
            raise CompileError(f"dialogue pattern {pattern_id} has invalid mapping")
        concept = mapping.get("canonicalConcept")
        state = mapping.get("dialogueState")
        mapping_refs = _validate_source_refs(
            mapping.get("sourceRefs"), source_names,
            f"dialogue pattern {pattern_id} mapping sourceRefs",
        )
        if concept not in DIALOGUE_MAPPING_CONCEPTS:
            raise CompileError(
                f"dialogue pattern {pattern_id} maps to an unsupported canonical concept")
        if state not in DIALOGUE_MAPPING_STATES:
            raise CompileError(
                f"dialogue pattern {pattern_id} maps to an unsupported dialogue state")
        if source_refs and mapping_refs != source_refs:
            raise CompileError(
                f"dialogue pattern {pattern_id} mapping/sourceRefs disagree")
        source_refs = mapping_refs
        normalized_mapping = {
            "canonicalConcept": concept,
            "dialogueState": state,
            "sourceRefs": mapping_refs,
        }
    if ((intent in {"PROMISE", "CLARIFY"} or normalized_mapping is not None)
            and (not reviewed or not source_refs or not normalized_mapping)):
        raise CompileError(
            f"dialogue promise pattern {pattern_id} requires reviewed canonical mapping metadata")

    negatives = value.get("negatives", [])
    if not isinstance(negatives, list) or len(negatives) > 8:
        raise CompileError(f"dialogue pattern {pattern_id} negatives must be bounded")
    normalized_negatives = []
    for negative in negatives:
        normalized_negative, _negative_tokens = _normalize_dialogue_utterance(negative)
        if normalized_negative == _normalized:
            raise CompileError(
                f"dialogue pattern {pattern_id} has a positive/negative collision")
        if normalized_negative not in normalized_negatives:
            normalized_negatives.append(normalized_negative)

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

    compiled = {
        "id": pattern_id,
        "match": compiled_match,
        "emit": normalized_emit,
        "confidence": float(confidence),
        "priority": priority,
    }
    if reviewed:
        compiled["metadata"] = {
            "reviewed": True,
            "sourceRefs": source_refs,
        }
    if normalized_mapping is not None:
        compiled.setdefault("metadata", {})["mapping"] = normalized_mapping
    return compiled, normalized_negatives


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


def _validate_translation_args(value: Any, label: str) -> dict[str, str]:
    """Validate typed argument declarations without evaluating them."""
    if value is None:
        return {}
    if not isinstance(value, dict) or len(value) > 8:
        raise CompileError(f"{label} must contain at most 8 typed arguments")
    output: dict[str, str] = {}
    for name, argument_type in value.items():
        if (not isinstance(name, str)
                or not re.fullmatch(r"[a-z][a-zA-Z0-9_]{0,31}", name)
                or argument_type not in DIALOGUE_TRANSLATION_ARG_TYPES):
            raise CompileError(
                f"{label} contains an invalid typed argument {name!r}"
            )
        output[name] = argument_type
    return {name: output[name] for name in sorted(output)}


def _validate_dialogue_plan(
    value: Any,
    pool_id: str,
    variant_id: str,
    template_id: str,
    fallback: str,
) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} must be an object")
    allowed = {
        "dialogueAct", "sourcePoolID", "topic", "groundedFactRefs",
        "uncertainty", "tone", "personalityStyle", "referenceTopic",
        "referenceSubject", "turns",
    }
    if set(value) - allowed:
        raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has unsupported fields")
    dialogue_act = value.get("dialogueAct")
    if not isinstance(dialogue_act, str) or not dialogue_act.strip():
        raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} requires dialogueAct")
    source_pool = value.get("sourcePoolID", pool_id)
    if not isinstance(source_pool, str) or not DIALOGUE_TEMPLATE_ID.fullmatch(source_pool):
        raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid sourcePoolID")
    topic = value.get("topic")
    if topic is not None and (not isinstance(topic, str) or not topic.strip()):
        raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid topic")
    reference_topic = value.get("referenceTopic")
    reference_subject = value.get("referenceSubject")
    for field, item in (("referenceTopic", reference_topic),
                        ("referenceSubject", reference_subject)):
        if item is not None and (
            not isinstance(item, str) or not DIALOGUE_TEMPLATE_ID.fullmatch(item)
        ):
            raise CompileError(
                f"dialogue response plan for {pool_id}:{variant_id} has invalid {field}"
            )
    refs = value.get("groundedFactRefs", value.get("sourceFactRefs", []))
    if not isinstance(refs, list) or len(refs) > 8:
        raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid fact refs")
    normalized_refs = []
    for ref in refs:
        if not isinstance(ref, str) or not ref or len(ref) > 128:
            raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid fact ref")
        if not re.fullmatch(r"[A-Za-z0-9_.:-]+", ref):
            raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid fact ref")
        if ref not in normalized_refs:
            normalized_refs.append(ref)
    uncertainty = value.get("uncertainty")
    if uncertainty not in DIALOGUE_PLAN_UNCERTAINTIES:
        raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid uncertainty")
    normalized = {
        "dialogueAct": dialogue_act.strip(),
        "sourcePoolID": source_pool,
        "topic": topic.strip() if isinstance(topic, str) else None,
        "referenceTopic": reference_topic,
        "referenceSubject": reference_subject,
        "groundedFactRefs": normalized_refs,
        "uncertainty": uncertainty,
        "tone": value.get("tone"),
        "personalityStyle": value.get("personalityStyle"),
        "turns": [],
    }
    for field in ("tone", "personalityStyle"):
        item = normalized[field]
        if item is not None and (not isinstance(item, str) or not item.strip()):
            raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid {field}")
        if isinstance(item, str):
            normalized[field] = item.strip()
    turns = value.get("turns")
    if not isinstance(turns, list) or not turns or len(turns) > 4:
        raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} requires 1 to 4 turns")
    for turn in turns:
        if not isinstance(turn, dict) or set(turn) - {"id", "continuation", "segments"}:
            raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid turn")
        segments = turn.get("segments")
        if not isinstance(segments, list) or not segments or len(segments) > 6:
            raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid segments")
        normalized_segments = []
        for segment in segments:
            if not isinstance(segment, dict):
                raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid segment")
            kind = segment.get("kind")
            if kind == "translation":
                segment_template = segment.get("templateID", template_id)
                segment_fallback = segment.get("fallback", fallback)
                if (not isinstance(segment_template, str)
                        or not DIALOGUE_TEMPLATE_ID.fullmatch(segment_template)
                        or not isinstance(segment_fallback, str)
                        or not segment_fallback.strip()
                        or len(segment_fallback) > 256):
                    raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid translation segment")
                normalized_segments.append({
                    "kind": "translation",
                    "templateID": segment_template,
                    "fallback": segment_fallback.strip(),
                    "translationArgs": _validate_translation_args(
                        segment.get("translationArgs"),
                        f"dialogue response plan for {pool_id}:{variant_id} translationArgs",
                    ),
                })
            elif kind == "literal":
                segment_text = segment.get("text")
                if not isinstance(segment_text, str) or not segment_text.strip() or len(segment_text) > 256:
                    raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has invalid literal segment")
                normalized_segments.append({"kind": "literal", "text": segment_text.strip()})
            else:
                raise CompileError(f"dialogue response plan for {pool_id}:{variant_id} has unsupported segment kind")
        normalized["turns"].append({
            "id": str(turn.get("id", len(normalized["turns"]) + 1)),
            "continuation": str(turn.get("continuation", "end")),
            "segments": normalized_segments,
        })
    return normalized


def _compile_dialogue_response_pool(
    value: Any,
    source_names: set[str],
) -> tuple[dict[str, Any], dict[str, dict[str, str]]]:
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
        if (not isinstance(template_id, str)
                or not DIALOGUE_TEMPLATE_ID.fullmatch(template_id)):
            raise CompileError(f"invalid template id for {pool_id}:{variant_id}")
        priority = variant.get("priority", 0)
        if isinstance(priority, bool) or not isinstance(priority, int) or not -10 <= priority <= 10:
            raise CompileError(
                f"response priority for {pool_id}:{variant_id} must be from -10 to 10")
        allowed_keys = {
            "id", "templateID", "fallback", "when", "priority", "en", "tl",
            "plan", "reviewed", "sourceRefs", "translationArgs",
        }
        if set(variant) - allowed_keys:
            raise CompileError(
                f"unsupported fields for dialogue response {pool_id}:{variant_id}")
        if (not isinstance(template_id, str)
                or not DIALOGUE_TEMPLATE_ID.fullmatch(template_id)):
            raise CompileError(f"invalid template id for {pool_id}:{variant_id}")
        english = variant.get("en", fallback)
        tagalog = variant.get("tl")
        if "en" in variant or "tl" in variant:
            if (not isinstance(english, str) or not english.strip()
                    or not isinstance(tagalog, str) or not tagalog.strip()):
                raise CompileError(
                    f"dialogue response {pool_id}:{variant_id} requires both EN and TL text")
        reviewed = variant.get("reviewed", False)
        if not isinstance(reviewed, bool):
            raise CompileError(f"dialogue response {pool_id}:{variant_id} reviewed must be boolean")
        source_refs = []
        if "sourceRefs" in variant:
            source_refs = _validate_source_refs(
                variant["sourceRefs"], source_names,
                f"dialogue response {pool_id}:{variant_id} sourceRefs",
            )
        if "plan" in variant and (not reviewed or not source_refs):
            raise CompileError(
                f"dialogue response {pool_id}:{variant_id} plan requires reviewed source metadata")
        translation_args = _validate_translation_args(
            variant.get("translationArgs"),
            f"dialogue response {pool_id}:{variant_id} translationArgs",
        )
        compiled_variant = {
            "id": variant_id,
            "templateID": template_id,
            "fallback": fallback.strip(),
        }
        if translation_args:
            compiled_variant["translationArgs"] = translation_args
        condition = _validate_response_condition(variant.get("when"), pool_id, variant_id)
        if condition:
            compiled_variant["when"] = condition
        if priority != 0:
            compiled_variant["priority"] = priority
        if "plan" in variant:
            compiled_variant["plan"] = _validate_dialogue_plan(
                variant["plan"], pool_id, variant_id, template_id, fallback.strip()
            )
        if reviewed:
            compiled_variant["metadata"] = {
                "reviewed": True,
                "sourceRefs": source_refs,
            }
        if "en" in variant or "tl" in variant:
            compiled_variant.setdefault("metadata", {})["translationKey"] = template_id
        compiled_variants.append(compiled_variant)
    translations = {"EN": {}, "TL": {}}
    for variant in variants:
        if "en" not in variant and "tl" not in variant:
            continue
        variant_id = variant["id"]
        compiled_variant = next(item for item in compiled_variants if item["id"] == variant_id)
        key = compiled_variant["templateID"]
        if key in translations["EN"] or key in translations["TL"]:
            raise CompileError(f"duplicate dialogue translation key {key}")
        translations["EN"][key] = variant["en"].strip()
        translations["TL"][key] = variant["tl"].strip()
    return {"id": pool_id, "variants": compiled_variants}, translations


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

    source_names = {reference["name"] for reference in source["references"]}
    compiled_patterns = []
    seen_pattern_ids: set[str] = set()
    seen_utterances: dict[str, str] = {}
    seen_negatives: dict[str, str] = {}
    for pattern in patterns:
        compiled, negatives = _compile_dialogue_pattern(pattern, source_names)
        if compiled["id"] in seen_pattern_ids:
            raise CompileError(f"duplicate dialogue pattern id {compiled['id']}")
        seen_pattern_ids.add(compiled["id"])
        normalized_utterance, _ = _normalize_dialogue_utterance(
            pattern.get("utterance")
        )
        previous = seen_utterances.get(normalized_utterance)
        if previous is not None:
            raise CompileError(
                f"dialogue utterance {normalized_utterance!r} is mapped by both "
                f"{previous} and {compiled['id']}")
        previous = seen_negatives.get(normalized_utterance)
        if previous is not None:
            raise CompileError(
                f"dialogue positive {normalized_utterance!r} collides with negative pattern {previous}")
        seen_utterances[normalized_utterance] = compiled["id"]
        for negative in negatives:
            previous = seen_utterances.get(negative)
            if previous is not None:
                raise CompileError(
                    f"dialogue negative {negative!r} collides with positive pattern {previous}")
            previous = seen_negatives.get(negative)
            if previous is not None and previous != compiled["id"]:
                raise CompileError(
                    f"dialogue negative {negative!r} is repeated by {previous} and {compiled['id']}")
            seen_negatives[negative] = compiled["id"]
        compiled_patterns.append(compiled)

    compiled_pools = []
    translations = {"EN": {}, "TL": {}}
    seen_pool_ids: set[str] = set()
    seen_response_ids: set[str] = set()
    for pool in response_pools:
        compiled, pool_translations = _compile_dialogue_response_pool(
            pool, source_names
        )
        if compiled["id"] in seen_pool_ids:
            raise CompileError(f"duplicate dialogue response pool {compiled['id']}")
        seen_pool_ids.add(compiled["id"])
        for variant in compiled["variants"]:
            if variant["id"] in seen_response_ids:
                raise CompileError(f"duplicate dialogue response id {variant['id']}")
            seen_response_ids.add(variant["id"])
        for language in ("EN", "TL"):
            for key, text in pool_translations[language].items():
                if key in translations[language]:
                    raise CompileError(f"duplicate dialogue translation key {key}")
                translations[language][key] = text
        compiled_pools.append(compiled)

    compiled_patterns.sort(key=lambda item: item["id"])
    compiled_pools.sort(key=lambda item: item["id"])
    return {
        "source": source,
        "patterns": compiled_patterns,
        "responsePools": compiled_pools,
        "translations": {
            language: {
                key: translations[language][key]
                for key in sorted(translations[language])
            }
            for language in ("EN", "TL")
        },
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


def _render_dialogue_chunk(
    kind: str,
    index: int,
    records: list[dict[str, Any]],
) -> str:
    lines = [
        "-- Generated by tools/semantic_compiler/build.py; do not edit by hand.",
        f"-- Dialogue {kind} shard {index:02d}; keep this file data-only.",
        "return {",
    ]
    for record in records:
        rendered = _lua_value(record, 4)
        lines.append("    " + rendered.replace("\n", "\n    ") + ",")
    lines.extend(["}", ""])
    return "\n".join(lines)


def _split_dialogue_records(
    kind: str,
    records: list[dict[str, Any]],
    max_chars: int = DIALOGUE_LUA_CHUNK_MAX_CHARS,
) -> list[str]:
    shards: list[str] = []
    current: list[dict[str, Any]] = []
    for record in records:
        candidate = current + [record]
        rendered = _render_dialogue_chunk(kind, len(shards) + 1, candidate)
        if current and len(rendered) > max_chars:
            shards.append(_render_dialogue_chunk(kind, len(shards) + 1, current))
            current = [record]
        else:
            current = candidate
    if current or not shards:
        shards.append(_render_dialogue_chunk(kind, len(shards) + 1, current))
    if any(len(shard) > max_chars for shard in shards):
        raise CompileError(
            f"dialogue {kind} shard exceeds the {max_chars}-character output budget")
    return shards


def render_dialogue_lua_shards(
    compiled: dict[str, Any],
    module_prefix: str,
    max_chars: int = DIALOGUE_LUA_CHUNK_MAX_CHARS,
) -> list[tuple[str, str]]:
    """Render deterministic data shards for the stable dialogue entry module."""
    rendered: list[tuple[str, str]] = []
    for kind, key in (("patterns", "patterns"), ("responses", "responsePools")):
        shards = _split_dialogue_records(kind, compiled[key], max_chars)
        for index, shard in enumerate(shards, 1):
            module = f"{module_prefix}_{kind.title()}_{index:02d}"
            rendered.append((module, shard))
    return rendered


def render_dialogue_lua(
    compiled: dict[str, Any],
    pattern_modules: list[str] | None = None,
    response_modules: list[str] | None = None,
) -> str:
    """Render the bounded interaction seed for the existing Lua registries.

    With no shard module lists this keeps the original standalone renderer for
    callers that use the compiler as a library. The build command supplies
    deterministic shard modules so the packaged entry file stays small.
    """
    if pattern_modules is None and response_modules is None:
        return "\n".join([
            "-- Generated by tools/semantic_compiler/build.py; do not edit by hand.",
            "-- Exact Hoomans-authored interaction patterns and response variants.",
            "-- Referenced dialogue corpora provide coverage labels only; no turns are copied.",
            "return " + _lua_value(compiled),
            "",
        ])
    pattern_modules = pattern_modules or []
    response_modules = response_modules or []
    lines = [
        "-- Generated by tools/semantic_compiler/build.py; do not edit by hand.",
        "-- Stable entry point for deterministic dialogue data shards.",
        "local result = {",
        "    [\"source\"] = " + _lua_value(compiled["source"], 4) + ",",
        "    [\"patterns\"] = {},",
        "    [\"responsePools\"] = {},",
        "}",
        "local function append(target, shard)",
        "    for index = 1, #shard do",
        "        target[#target + 1] = shard[index]",
        "    end",
        "end",
    ]
    for module in pattern_modules:
        lines.append(
            f'append(result["patterns"], require "{module}")')
    for module in response_modules:
        lines.append(
            f'append(result["responsePools"], require "{module}")')
    lines.extend(["return result", ""])
    return "\n".join(lines)


def render_dialogue_translation(compiled: dict[str, Any], language: str) -> str:
    """Render the small localized shard emitted beside generated dialogue Lua."""
    if language not in ("EN", "TL"):
        raise CompileError(f"unsupported dialogue translation language {language}")
    translations = compiled.get("translations", {})
    values = translations.get(language, {})
    if not isinstance(values, dict):
        raise CompileError(f"dialogue translations for {language} must be an object")
    return json.dumps(
        {key: values[key] for key in sorted(values)},
        ensure_ascii=False,
        separators=(",", ":"),
    ) + "\n"


def load_semantic_source(path: Path) -> dict[str, Any]:
    """Load one reviewed declarative semantic-authoring source document."""
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise CompileError(f"cannot read semantic source {path}: {error}") from error
    if not isinstance(document, dict):
        raise CompileError("semantic source root must be an object")
    return document


def discover_registered_capability_ids(runtime_root: Path) -> set[str]:
    """Read capability IDs from existing production semantic descriptors."""
    pattern = re.compile(r'capabilityID\s*=\s*["\']([^"\']+)["\']')
    paths = runtime_root.glob(
        "Contents/mods/ProjectHoomans/*/media/lua/**/PNC_Semantic*.lua"
    )
    capabilities: set[str] = set()
    for path in sorted(paths):
        try:
            text = path.read_text(encoding="utf-8")
        except OSError:
            continue
        capabilities.update(pattern.findall(text))
    return capabilities


def _semantic_id(value: Any, label: str) -> str:
    if not isinstance(value, str) or not DIALOGUE_ID.fullmatch(value):
        raise CompileError(f"{label} must be a lowercase dotted identifier")
    return value


def _semantic_text(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip() or len(value) > 256:
        raise CompileError(f"{label} must be a non-empty bounded string")
    return value.strip()


def _semantic_frame(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict) or not value:
        raise CompileError(f"{label} must be a non-empty object")
    output: dict[str, Any] = {}
    for key, item in value.items():
        if key not in SEMANTIC_FRAME_FIELDS:
            raise CompileError(f"{label} contains unsupported field {key!r}")
        if not isinstance(item, (str, int, float, bool)):
            raise CompileError(f"{label}.{key} must be scalar")
        output[key] = item
    return output


def _semantic_match(utterance: str) -> list[dict[str, str]]:
    _normalized, tokens = _normalize_dialogue_utterance(utterance)
    return [{"kind": "literal", "value": token} for token in tokens]


def _semantic_slug(utterance: str) -> str:
    normalized, _tokens = _normalize_dialogue_utterance(utterance)
    slug = re.sub(r"[^a-z0-9]+", "_", normalized).strip("_")
    return slug or "utterance"


def _semantic_flow(
    value: Any,
    definition_id: str,
    response_pool_ids: set[str],
    pattern_ids: set[str],
) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise CompileError(f"semantic definition {definition_id} requires a flow")
    flow_id = _semantic_id(value.get("id"), f"flow for {definition_id}")
    version = value.get("version", 1)
    if isinstance(version, bool) or not isinstance(version, int) or version < 1:
        raise CompileError(f"flow {flow_id} requires a positive integer version")
    triggers = value.get("triggers")
    if not isinstance(triggers, list) or not triggers or len(triggers) > 8:
        raise CompileError(f"flow {flow_id} requires 1..8 triggers")
    normalized_triggers = [
        _semantic_frame(trigger, f"flow {flow_id} trigger")
        for trigger in triggers
    ]
    for trigger in normalized_triggers:
        if "pattern" in trigger and trigger["pattern"] not in pattern_ids:
            raise CompileError(
                f"flow {flow_id} trigger references unknown authored pattern "
                f"{trigger['pattern']}"
            )
    nodes = value.get("nodes")
    if not isinstance(nodes, dict) or not nodes or len(nodes) > 32:
        raise CompileError(f"flow {flow_id} requires 1..32 nodes")
    initial = value.get("initial")
    if not isinstance(initial, str) or initial not in nodes:
        raise CompileError(f"flow {flow_id} initial node is missing")

    normalized_nodes: dict[str, dict[str, Any]] = {}
    transition_fields = (
        "next", "onMatch", "onUnrelated", "onRefuse", "onPass", "onFail",
        "onUnknown",
    )
    special_targets = {"cancel", "resume", "suspend"}
    for node_id in sorted(nodes):
        if not isinstance(node_id, str) or not node_id:
            raise CompileError(f"flow {flow_id} contains an invalid node id")
        node = nodes[node_id]
        if not isinstance(node, dict):
            raise CompileError(f"flow {flow_id} node {node_id} must be an object")
        allowed = {
            "terminal", "responsePool", "responseTemplate", "gate", "slots",
            "accepts", *transition_fields,
        }
        unsupported = set(node) - allowed
        if unsupported:
            raise CompileError(
                f"flow {flow_id} node {node_id} contains unsupported fields: "
                + ", ".join(sorted(unsupported))
            )
        normalized: dict[str, Any] = {"id": node_id, "terminal": node.get("terminal", False) is True}
        for field in ("responsePool", "responseTemplate"):
            if field in node:
                if not isinstance(node[field], str) or not node[field]:
                    raise CompileError(f"flow {flow_id} node {node_id} has invalid {field}")
                if field == "responsePool" and node[field] not in response_pool_ids:
                    raise CompileError(
                        f"flow {flow_id} node {node_id} references missing response pool "
                        f"{node[field]}"
                    )
                normalized[field] = node[field]
        if "gate" in node:
            if not isinstance(node["gate"], dict) or not node["gate"].get("type"):
                raise CompileError(f"flow {flow_id} node {node_id} has invalid gate")
            normalized["gate"] = node["gate"]
        if "slots" in node:
            if not isinstance(node["slots"], dict):
                raise CompileError(f"flow {flow_id} node {node_id} slots must be an object")
            normalized["slots"] = node["slots"]
        accepts = node.get("accepts", [])
        if not isinstance(accepts, list) or len(accepts) > 16:
            raise CompileError(f"flow {flow_id} node {node_id} accepts must be bounded")
        normalized["accepts"] = [
            _semantic_frame(frame, f"flow {flow_id} node {node_id} accept")
            for frame in accepts
        ]
        for field in transition_fields:
            if field not in node:
                continue
            target = node[field]
            if not isinstance(target, str) or not target:
                raise CompileError(f"flow {flow_id} node {node_id} has invalid {field}")
            if target not in special_targets and target not in nodes:
                raise CompileError(
                    f"flow {flow_id} node {node_id} references unknown node {target}"
                )
            normalized[field] = target
        if not normalized["terminal"] and not normalized["accepts"]:
            raise CompileError(f"flow {flow_id} node {node_id} requires accepts")
        if not normalized["terminal"] and not any(
            field in normalized for field in transition_fields
        ):
            raise CompileError(f"flow {flow_id} node {node_id} requires a transition")
        normalized_nodes[node_id] = normalized

    seen: set[str] = set()
    pending = [initial]
    while pending:
        node_id = pending.pop(0)
        if node_id in seen or node_id in special_targets:
            continue
        seen.add(node_id)
        node = normalized_nodes[node_id]
        for field in transition_fields:
            target = node.get(field)
            if target and target not in seen and target not in special_targets:
                pending.append(target)
    unreachable = sorted(set(normalized_nodes) - seen)
    if unreachable:
        raise CompileError(
            f"flow {flow_id} contains unreachable nodes: {', '.join(unreachable)}"
        )
    return {
        "id": flow_id,
        "version": version,
        "owner": _semantic_text(value.get("owner", "ProjectHoomans"), f"flow {flow_id} owner"),
        "initial": initial,
        "triggers": normalized_triggers,
        "nodes": normalized_nodes,
    }


def _semantic_responses(
    value: Any,
    definition_id: str,
) -> tuple[dict[str, Any], dict[str, dict[str, str]]]:
    if not isinstance(value, dict):
        raise CompileError(f"semantic definition {definition_id} requires responses")
    pool_id = _semantic_id(value.get("poolID"), f"responses for {definition_id}")
    if not pool_id.startswith("semantic."):
        raise CompileError(f"response pool {pool_id} must use semantic.* namespace")
    variants = value.get("variants")
    if not isinstance(variants, list) or not variants or len(variants) > 16:
        raise CompileError(f"response pool {pool_id} requires 1..16 variants")
    compiled: list[dict[str, Any]] = []
    translations = {"EN": {}, "TL": {}}
    seen_ids: set[str] = set()
    for variant in variants:
        if not isinstance(variant, dict):
            raise CompileError(f"response variant in {pool_id} must be an object")
        variant_id = _semantic_id(variant.get("id"), f"response variant in {pool_id}")
        if variant_id in seen_ids:
            raise CompileError(f"duplicate response variant {pool_id}:{variant_id}")
        seen_ids.add(variant_id)
        key = variant.get("key")
        if not isinstance(key, str) or not key.startswith("UI_PNC_"):
            raise CompileError(f"response variant {pool_id}:{variant_id} requires UI_PNC key")
        english = _semantic_text(variant.get("en"), f"response {key} EN")
        tagalog = _semantic_text(variant.get("tl"), f"response {key} TL")
        if key in translations["EN"] or key in translations["TL"]:
            raise CompileError(f"duplicate translation key {key}")
        translations["EN"][key] = english
        translations["TL"][key] = tagalog
        compiled_variant: dict[str, Any] = {
            "id": variant_id,
            "templateID": key,
            "fallback": english,
        }
        if "when" in variant:
            compiled_variant["when"] = _validate_response_condition(
                variant["when"], pool_id, variant_id
            )
        priority = variant.get("priority", 0)
        if isinstance(priority, bool) or not isinstance(priority, int) or not -10 <= priority <= 10:
            raise CompileError(f"response priority {pool_id}:{variant_id} must be -10..10")
        if priority:
            compiled_variant["priority"] = priority
        compiled.append(compiled_variant)
    return {"id": pool_id, "variants": compiled}, translations


def compile_semantic_definitions(
    document: dict[str, Any],
    registered_capability_ids: set[str] | frozenset[str] | None = None,
    reserved_utterances: set[str] | frozenset[str] | None = None,
) -> dict[str, Any]:
    """Compile one canonical semantic-authoring document into data-only artifacts."""
    if not isinstance(document, dict) or document.get("schema") != SEMANTIC_SCHEMA:
        raise CompileError(f"semantic source requires schema {SEMANTIC_SCHEMA}")
    source = document.get("source")
    if not isinstance(source, dict):
        raise CompileError("semantic source requires source metadata")
    source_owner = _semantic_text(source.get("owner"), "semantic source owner")
    source_version = _semantic_text(source.get("version"), "semantic source version")
    definitions = document.get("definitions")
    if not isinstance(definitions, list) or not definitions or len(definitions) > 32:
        raise CompileError("semantic source requires 1..32 definitions")
    capabilities = set(registered_capability_ids or DEFAULT_REGISTERED_CAPABILITY_IDS)
    reserved = {
        _normalize_dialogue_utterance(item)[0]
        for item in (reserved_utterances or DEFAULT_RESERVED_UTTERANCES)
    }
    patterns: list[dict[str, Any]] = []
    flows: list[dict[str, Any]] = []
    response_pools: list[dict[str, Any]] = []
    translations = {"EN": {}, "TL": {}}
    seen_definition_ids: set[str] = set()
    seen_flow_ids: set[str] = set()
    seen_pool_ids: set[str] = set()
    seen_utterances: dict[str, str] = {}
    for definition in definitions:
        if not isinstance(definition, dict):
            raise CompileError("semantic definitions must be objects")
        definition_id = _semantic_id(definition.get("id"), "semantic definition id")
        if definition_id in seen_definition_ids:
            raise CompileError(f"duplicate semantic definition id {definition_id}")
        seen_definition_ids.add(definition_id)
        capability = definition.get("capability")
        if not isinstance(capability, str) or capability not in capabilities:
            raise CompileError(
                f"semantic definition {definition_id} references unregistered capability "
                f"{capability!r}"
            )
        emit = definition.get("emit")
        if not isinstance(emit, dict):
            raise CompileError(f"semantic definition {definition_id} requires emit")
        normalized_emit = _semantic_frame(emit, f"semantic definition {definition_id} emit")
        if normalized_emit.get("intent") != "REQUEST" or normalized_emit.get("speechAct") != "REQUEST":
            raise CompileError(f"semantic definition {definition_id} must emit REQUEST/REQUEST")
        action = normalized_emit.get("action")
        if not isinstance(action, str) or not action:
            raise CompileError(f"semantic definition {definition_id} requires an action")
        if capability.endswith(".follow") and action != "FOLLOW":
            raise CompileError(f"semantic definition {definition_id} action does not match FOLLOW capability")
        utterances = definition.get("utterances")
        if not isinstance(utterances, dict):
            raise CompileError(f"semantic definition {definition_id} requires utterances")
        positives = utterances.get("positives")
        negatives = utterances.get("negatives")
        if not isinstance(positives, list) or not positives or not isinstance(negatives, list) or not negatives:
            raise CompileError(f"semantic definition {definition_id} requires positive and negative examples")
        normalized_negatives = {
            _normalize_dialogue_utterance(item)[0] for item in negatives
        }
        for negative in normalized_negatives:
            if negative in reserved:
                continue
        definition_pattern_ids: set[str] = set()
        for utterance in positives:
            normalized, _tokens = _normalize_dialogue_utterance(utterance)
            if normalized in normalized_negatives:
                raise CompileError(
                    f"semantic definition {definition_id} has positive/negative collision: {normalized}"
                )
            if normalized in reserved:
                raise CompileError(
                    f"semantic definition {definition_id} collides with registered utterance: {normalized}"
                )
            if normalized in seen_utterances:
                raise CompileError(
                    f"semantic utterance collision {normalized} between "
                    f"{seen_utterances[normalized]} and {definition_id}"
                )
            if re.match(r"^(don't|do not|are you|is you|did you|i )\b", normalized):
                raise CompileError(
                    f"semantic positive example is not an executable imperative: {normalized}"
                )
            seen_utterances[normalized] = definition_id
            pattern_id = f"{definition_id}.{_semantic_slug(normalized)}"
            definition_pattern_ids.add(pattern_id)
            patterns.append({
                "id": pattern_id,
                "match": _semantic_match(normalized),
                "emit": normalized_emit,
                "confidence": definition.get("confidence", 0.99),
                "priority": definition.get("priority", 160),
            })
        response_pool, definition_translations = _semantic_responses(
            definition.get("responses"), definition_id
        )
        if response_pool["id"] in seen_pool_ids:
            raise CompileError(f"duplicate semantic response pool {response_pool['id']}")
        seen_pool_ids.add(response_pool["id"])
        for language in ("EN", "TL"):
            for key, text in definition_translations[language].items():
                if key in translations[language]:
                    raise CompileError(f"duplicate semantic translation key {key}")
                translations[language][key] = text
        flow = _semantic_flow(
            definition.get("flow"),
            definition_id,
            seen_pool_ids | {response_pool["id"]},
            definition_pattern_ids,
        )
        if flow["id"] in seen_flow_ids:
            raise CompileError(f"duplicate semantic flow id {flow['id']}")
        seen_flow_ids.add(flow["id"])
        for trigger in flow["triggers"]:
            if trigger.get("action") != action:
                raise CompileError(
                    f"flow {flow['id']} trigger action must match {definition_id} action"
                )
        response_pools.append(response_pool)
        flows.append(flow)
    patterns.sort(key=lambda item: item["id"])
    flows.sort(key=lambda item: item["id"])
    response_pools.sort(key=lambda item: item["id"])
    return {
        "schema": SEMANTIC_SCHEMA,
        "source": {"owner": source_owner, "version": source_version},
        "patterns": patterns,
        "flows": flows,
        "responsePools": response_pools,
        "translations": {
            language: {key: translations[language][key] for key in sorted(translations[language])}
            for language in ("EN", "TL")
        },
    }


def _render_semantic_chunk(kind: str, index: int, records: list[dict[str, Any]]) -> str:
    lines = [
        "-- Generated by tools/semantic_compiler/build.py; do not edit by hand.",
        f"-- Semantic {kind} shard {index:02d}; keep file data-only.",
        "return {",
    ]
    for record in records:
        rendered = _lua_value(record, 4)
        lines.append("    " + rendered.replace("\n", "\n    ") + ",")
    lines.extend(["}", ""])
    return "\n".join(lines)


def _split_semantic_records(
    kind: str,
    records: list[dict[str, Any]],
    max_chars: int = DIALOGUE_LUA_CHUNK_MAX_CHARS,
) -> list[str]:
    shards: list[str] = []
    current: list[dict[str, Any]] = []
    for record in records:
        candidate = current + [record]
        rendered = _render_semantic_chunk(kind, len(shards) + 1, candidate)
        if current and len(rendered) > max_chars:
            shards.append(_render_semantic_chunk(kind, len(shards) + 1, current))
            current = [record]
        else:
            current = candidate
    if current or not shards:
        shards.append(_render_semantic_chunk(kind, len(shards) + 1, current))
    if any(len(shard) > max_chars for shard in shards):
        raise CompileError(f"semantic {kind} shard exceeds the {max_chars}-character output budget")
    return shards


def render_semantic_lua_shards(
    compiled: dict[str, Any],
    module_prefix: str,
    max_chars: int = DIALOGUE_LUA_CHUNK_MAX_CHARS,
) -> list[tuple[str, str]]:
    rendered: list[tuple[str, str]] = []
    for kind, key in (("patterns", "patterns"), ("flows", "flows"), ("responses", "responsePools")):
        shards = _split_semantic_records(kind, compiled[key], max_chars)
        for index, shard in enumerate(shards, 1):
            rendered.append((f"{module_prefix}_{kind.title()}_{index:02d}", shard))
    return rendered


def render_semantic_manifest(
    compiled: dict[str, Any],
    pattern_modules: list[str],
    flow_modules: list[str],
    response_modules: list[str],
    translation_paths: dict[str, list[str]],
) -> str:
    lines = [
        "-- Generated by tools/semantic_compiler/build.py; do not edit by hand.",
        "-- Explicit manifest for one deterministic semantic-authoring build.",
        "local result = {",
        "    [\"schema\"] = " + _lua_string(compiled["schema"]) + ",",
        "    [\"source\"] = " + _lua_value(compiled["source"], 4) + ",",
        "    [\"patterns\"] = {},",
        "    [\"flows\"] = {},",
        "    [\"responsePools\"] = {},",
        "    [\"translationPaths\"] = " + _lua_value(translation_paths, 4) + ",",
        "}",
        "local function append(target, shard)",
        "    for index = 1, #shard do target[#target + 1] = shard[index] end",
        "end",
    ]
    for module in pattern_modules:
        lines.append(f'append(result["patterns"], require "{module}")')
    for module in flow_modules:
        lines.append(f'append(result["flows"], require "{module}")')
    for module in response_modules:
        lines.append(f'append(result["responsePools"], require "{module}")')
    lines.extend(["return result", ""])
    return "\n".join(lines)
