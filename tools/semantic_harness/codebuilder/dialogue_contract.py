"""Dialogue dataset contracts and bounded pattern-match validation."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from .lexicon_compiler import CompileError

DIALOGUE_ID = re.compile(r"^[a-z][a-z0-9_.-]{0,95}$")
DIALOGUE_TEMPLATE_ID = re.compile(r"^[A-Za-z][A-Za-z0-9_.-]{0,95}$")
DIALOGUE_UTTERANCE = re.compile(r"^[a-z0-9']+(?: [a-z0-9']+)*$")
DIALOGUE_PATTERN_SUBJECTS = frozenset({
    "ACTIVITY", "IDENTITY", "WELLBEING", "WEATHER",
    "NPC_BACKSTORY", "CONTEXT_REFERENCE", "CONVERSATION_TOPIC",
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
DIALOGUE_CONVERSATION_TOPIC_EXTENSIONS = frozenset({
    "topic", "hubID", "route",
})
DIALOGUE_PROMISE_SUBJECTS = frozenset({"NEEDS"})
DIALOGUE_PROMISE_EXTENSIONS = frozenset({"topic", "dialogueFollowUp"})
DIALOGUE_MAPPING_FIELDS = frozenset({
    "canonicalConcept", "dialogueState", "sourceRefs",
})
DIALOGUE_MAPPING_CONCEPTS = frozenset({
    "ANY_ITEM", "FETCH", "WEATHER", "WELLBEING", "NPC_BACKSTORY",
    "CONTEXT_REFERENCE", "WHATS_UP",
})
DIALOGUE_MAPPING_STATES = frozenset({
    "NEEDS_PROPOSAL", "NEEDS_QUANTITY", "WEATHER_TOPIC",
    "WELLBEING_FOLLOW_UP", "BACKSTORY_QUESTION", "BACKSTORY_FOLLOW_UP",
    "WHATS_UP_HUB",
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
DIALOGUE_MAX_BRANCH_OFFERS = 8
DIALOGUE_MATCH_CONCEPTS = frozenset({"WEATHER"})
DIALOGUE_LUA_CHUNK_MAX_CHARS = 10000
DIALOGUE_BRANCH_FRAME_FIELDS = frozenset({
    "intent", "speechAct", "action", "subject", "target", "reference",
    "identityClaim", "selfDirected", "stateType", "stateValue", "pattern",
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


def _validate_branch_constraint(value: Any, label: str, depth: int = 0) -> Any:
    """Validate the bounded all/any/not predicate AST used by branch offers."""
    if depth > 6 or not isinstance(value, dict):
        raise CompileError(f"{label} must be a bounded predicate object")
    allowed = {"all", "any", "not", "path", "field", "op", "value", "values"}
    unsupported = set(value) - allowed
    if unsupported:
        raise CompileError(
            f"{label} contains unsupported predicate fields: "
            + ", ".join(sorted(unsupported))
        )
    structural = [key for key in ("all", "any", "not") if key in value]
    has_leaf = "path" in value or "field" in value
    if len(structural) > 1 or (structural and has_leaf) or (
        not structural and not has_leaf
    ):
        raise CompileError(f"{label} has an invalid predicate shape")
    if structural and any(
        key in value for key in ("path", "field", "op", "value", "values")
    ):
        raise CompileError(f"{label} combines a group with a leaf predicate")
    for key in ("all", "any"):
        if key in value:
            items = value[key]
            if not isinstance(items, list) or not items or len(items) > 8:
                raise CompileError(f"{label}.{key} must contain 1..8 predicates")
            value[key] = [
                _validate_branch_constraint(item, f"{label}.{key}[{index}]", depth + 1)
                for index, item in enumerate(items)
            ]
    if "not" in value:
        value["not"] = _validate_branch_constraint(
            value["not"], f"{label}.not", depth + 1
        )
    if "path" in value and "field" in value:
        raise CompileError(f"{label} cannot contain both path and field")
    for key in ("path", "field", "op"):
        if key in value and (not isinstance(value[key], str) or not value[key]):
            raise CompileError(f"{label}.{key} must be a non-empty string")
    if "values" in value:
        values = value["values"]
        if not isinstance(values, list) or len(values) > 8:
            raise CompileError(f"{label}.values must contain at most 8 values")
        if any(not isinstance(item, (str, int, float, bool)) or item is None
               for item in values):
            raise CompileError(f"{label}.values must contain scalar values")
    if "value" in value and (
        not isinstance(value["value"], (str, int, float, bool))
        or value["value"] is None
    ):
        raise CompileError(f"{label}.value must be a scalar value")
    return value


def validate_branch_offers(
    value: Any,
    label: str,
    maximum: int = DIALOGUE_MAX_BRANCH_OFFERS,
) -> list[dict[str, Any]]:
    """Validate public, non-executing semantic branch offer descriptors."""
    if value is None:
        return []
    if not isinstance(value, list) or len(value) > maximum:
        raise CompileError(f"{label} must contain at most {maximum} offers")
    output: list[dict[str, Any]] = []
    seen: set[str] = set()
    allowed = {
        "id", "labelKey", "labelFallback", "utteranceKey",
        "utteranceFallback", "frame", "constraints", "visibility", "priority",
    }
    for index, offer in enumerate(value):
        offer_label = f"{label}[{index}]"
        if not isinstance(offer, dict) or set(offer) - allowed:
            raise CompileError(f"{offer_label} contains unsupported fields")
        offer_id = offer.get("id")
        if not isinstance(offer_id, str) or not DIALOGUE_ID.fullmatch(offer_id):
            raise CompileError(f"{offer_label}.id is invalid")
        if offer_id in seen:
            raise CompileError(f"{offer_label}.id is duplicated")
        seen.add(offer_id)
        for key in ("labelKey", "utteranceKey"):
            item = offer.get(key)
            if not isinstance(item, str) or not DIALOGUE_TEMPLATE_ID.fullmatch(item):
                raise CompileError(f"{offer_label}.{key} is invalid")
        for key in ("labelFallback", "utteranceFallback"):
            item = offer.get(key)
            if not isinstance(item, str) or not item.strip() or len(item) > 256:
                raise CompileError(f"{offer_label}.{key} is invalid")
        frame = offer.get("frame")
        if not isinstance(frame, dict) or not frame:
            raise CompileError(f"{offer_label}.frame must be a non-empty object")
        for key, item in frame.items():
            if key not in DIALOGUE_BRANCH_FRAME_FIELDS:
                raise CompileError(f"{offer_label}.frame.{key} is unsupported")
            if not isinstance(item, (str, int, float, bool)) or item is None:
                raise CompileError(f"{offer_label}.frame.{key} must be scalar")
        constraints = offer.get("constraints")
        if constraints is not None:
            constraints = _validate_branch_constraint(
                dict(constraints), f"{offer_label}.constraints"
            ) if isinstance(constraints, dict) else _validate_branch_constraint(
                constraints, f"{offer_label}.constraints"
            )
        visibility = offer.get("visibility")
        if visibility is not None and visibility != "player":
            raise CompileError(f"{offer_label}.visibility must be 'player'")
        priority = offer.get("priority", 0)
        if isinstance(priority, bool) or not isinstance(priority, (int, float)):
            raise CompileError(f"{offer_label}.priority must be numeric")
        output.append({
            "id": offer_id,
            "labelKey": offer["labelKey"],
            "labelFallback": offer["labelFallback"].strip(),
            "utteranceKey": offer["utteranceKey"],
            "utteranceFallback": offer["utteranceFallback"].strip(),
            "frame": dict(frame),
            "constraints": constraints,
            "visibility": visibility,
            "priority": priority,
        })
    return output


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
