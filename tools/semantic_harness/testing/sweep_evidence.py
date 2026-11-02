"""Compact per-rendered-sentence evidence schema and serializer.

Represents one rendered NPC sentence/response occurrence with triggering
parameters, semantic/realization paths, translation identity, persona/relationship
context, selection provenance, and bounded authority/effect evidence.
Full traces remain lazy rather than being duplicated into every row.
"""

from __future__ import annotations

from copy import deepcopy
from dataclasses import asdict, dataclass, field
import hashlib
import json
from typing import Any, Mapping

from ..inspection.conversation_inspector import build_conversation_inspector
from ..inspection.conversation_inspector_support import bounded

EVIDENCE_SCHEMA_V1 = "pnc.semantic-dialogue-quality-evidence.v1"
ALLOWED_EVIDENCE_SCHEMAS = frozenset({EVIDENCE_SCHEMA_V1})


@dataclass(frozen=True)
class QualityFlag:
    """A deterministic or review quality flag."""

    name: str
    severity: str  # "CRITICAL", "HIGH", "MEDIUM", "LOW", "INFO"
    confidence: str  # "DEFINITE", "SUSPECT", "REVIEW"
    detail: str = ""

    def to_dict(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "severity": self.severity,
            "confidence": self.confidence,
            "detail": self.detail,
        }


def _bound_str(val: Any, max_len: int = 500) -> str:
    if val is None:
        return ""
    s = str(val)
    if len(s) > max_len:
        return s[:max_len] + "…"
    return s


def _bound_dict(d: Any, limit: int = 16) -> dict[str, Any]:
    if not isinstance(d, dict):
        return {}
    res = {}
    for i, (k, v) in enumerate(d.items()):
        if i >= limit:
            break
        if isinstance(v, (int, float, bool, str)) or v is None:
            res[str(k)] = v
        elif isinstance(v, (list, tuple)):
            res[str(k)] = [x for x in v[:8] if isinstance(x, (int, float, bool, str))]
        elif isinstance(v, dict):
            res[str(k)] = {str(sk): sv for j, (sk, sv) in enumerate(v.items()) if j < 4 and isinstance(sv, (int, float, bool, str))}
    return res


def extract_evidence_rows_from_turn(
    record: dict[str, Any],
    *,
    turn_index: int = 0,
    case_id: str = "case-1",
    sweep_id: str = "sweep-1",
    batch_id: str | None = None,
    strategy: str = "manual",
    parameters: Mapping[str, Any] | None = None,
    language: str = "EN",
    salt: str | None = None,
    history_mode: str | None = "isolated",
    input_spec: Mapping[str, Any] | None = None,
    worker: Any | None = None,
    lineage_cache: Mapping[str, str] | None = None,
) -> list[dict[str, Any]]:
    """Extract compact evidence rows for every rendered NPC sentence in a turn."""
    view = build_conversation_inspector(record)
    messages = record.get("messages", [])
    npc_messages = [
        m for m in messages
        if isinstance(m, dict) and m.get("speaker") == "npc"
    ]

    # Context extraction from inspector view
    semantic = view.get("semantic") or {}
    persona_choices = view.get("personaChoices") or {}
    response_trace = persona_choices.get("responseTrace") or {}
    context = view.get("context") or {}
    actor_context = persona_choices.get("actorConversationContext") or {}
    bond = response_trace.get("bond") or actor_context.get("bond") or {}
    execution = view.get("execution") or {}
    effects = view.get("effects") or {}
    visible_response = view.get("visibleResponse") or {}

    # Trigger parameter vector (normalized)
    params = dict(parameters or {})

    # State summaries
    obs = record.get("observation") or {}
    social_context = view.get("socialContext") or {}
    facts = view.get("facts") or {}

    player_needs = _bound_dict(context.get("playerNeeds") or obs.get("playerNeeds") or {})
    npc_needs = _bound_dict(context.get("npcNeeds") or obs.get("npcNeeds") or {})
    npc_health = _bound_dict(context.get("npcHealth") or obs.get("npcHealth") or {})

    personality = _bound_dict(persona_choices.get("npcPersonality") or context.get("personality") or {})
    social_style = context.get("socialStyle") or persona_choices.get("socialStyle")
    traits = list(context.get("traits") or obs.get("npcTraits") or [])[:12]
    archetype = context.get("archetype") or obs.get("npcArchetype")

    relationship_state = (
        bond.get("relationshipState")
        or context.get("relationshipState")
        or social_context.get("relationshipState")
    )
    bond_kind = bond.get("kind") or context.get("bondKind") or "none"
    bond_class = bond.get("class") or bond.get("bondClass")
    approval = context.get("approval") if context.get("approval") is not None else bond.get("approval")
    respect = context.get("respect") if context.get("respect") is not None else bond.get("respect")
    familiarity = context.get("familiarity") if context.get("familiarity") is not None else bond.get("familiarity")
    identity_trust = context.get("identityTrust") if context.get("identityTrust") is not None else bond.get("identityTrust")

    actor_summary = {
        "speakerID": _bound_str(record.get("speaker") or context.get("npcID") or "npc", 64),
        "listenerID": _bound_str(context.get("playerID") or "player", 64),
        "authorityFlags": _bound_dict(view.get("commandAuthority") or {}),
    }

    persona_summary = {
        "personality": personality,
        "socialStyle": str(social_style) if social_style else None,
        "traits": traits,
        "archetype": str(archetype) if archetype else None,
    }

    relationship_summary = {
        "bondKind": str(bond_kind),
        "bondClass": str(bond_class) if bond_class else None,
        "approval": approval,
        "respect": respect,
        "familiarity": familiarity,
        "identityTrust": identity_trust,
        "relationshipState": str(relationship_state) if relationship_state else None,
    }

    state_summary = {
        "playerNeeds": player_needs,
        "npcNeeds": npc_needs,
        "npcHealth": npc_health,
        "activity": _bound_str(context.get("activity"), 64) if context.get("activity") else None,
    }

    # Authority and effects
    actions = list(effects.get("actions") or [])[:4]
    authority_summary = {
        "actionCount": int(effects.get("actionCount", 0)),
        "transportCount": int(effects.get("transportCount", 0)),
        "actions": [_bound_dict(a) for a in actions if isinstance(a, dict)],
        "executionStatus": execution.get("status"),
        "executionAuthority": execution.get("authority"),
        "rejectionReason": execution.get("rejectionReason"),
    }

    # If no NPC messages occurred, emit one empty row to capture the failure/silence
    targets = npc_messages if npc_messages else [
        {
            "speaker": "npc",
            "payload": {
                "text": "",
                "key": visible_response.get("key"),
                "translationKey": visible_response.get("translationKey"),
            },
        }
    ]

    rows: list[dict[str, Any]] = []

    for msg_idx, msg in enumerate(targets):
        payload = msg.get("payload") if isinstance(msg.get("payload"), dict) else {}
        final_text = str(payload.get("text") or msg.get("text") or "")
        rendered_key = payload.get("key") or msg.get("key")
        translation_key = payload.get("translationKey") or response_trace.get("translationKey")

        # Semantic paths
        semantic_template_id = (
            payload.get("semanticTemplateID")
            or response_trace.get("semanticTemplateID")
            or rendered_key
        )
        render_template_id = payload.get("renderTemplateID") or response_trace.get("renderTemplateID")
        realization_family = (
            payload.get("realizationFamily")
            or response_trace.get("realizationFamily")
            or persona_choices.get("realizationFamily")
        )
        realization_variant = (
            payload.get("realizationVariant")
            or response_trace.get("realizationVariant")
            or persona_choices.get("realizationVariant")
        )
        semantic_variant_id = payload.get("semanticVariantID")
        phrase_id = payload.get("phraseID")
        fallback_reason = (
            payload.get("fallbackReason")
            or response_trace.get("fallbackReason")
            or persona_choices.get("realizationFallbackReason")
        )
        family_address = response_trace.get("familyAddress") or (payload.get("args") or {}).get("familyAddress")

        # Provenance resolution
        provenance = "UNKNOWN"
        selected_variant_id = None
        candidate_count = 0
        candidate_rejections: list[dict[str, Any]] = []

        if worker is not None and hasattr(worker, "response_key_lookup") and semantic_template_id:
            lookup = worker.response_key_lookup(str(semantic_template_id))
            matched = lookup.get("matches", [])
            candidate_count = lookup.get("matchCount", len(matched))
            direct = [
                row for row in matched
                if row.get("matchKind") == "REGISTERED_VARIANT_ID"
            ]
            if len(direct) == 1 and lookup.get("matchCount") == 1 and not lookup.get("truncated"):
                provenance = "EXACT_EMITTED_VARIANT_ID"
                selected_variant_id = direct[0].get("variantID")
            elif matched:
                provenance = "TEMPLATE_CANDIDATES_ONLY"
        elif semantic_variant_id:
            provenance = "EXACT_EMITTED_VARIANT_ID"
            selected_variant_id = semantic_variant_id

        # Canonical source ownership
        canonical_source = "UNKNOWN"
        if lineage_cache:
            cache_key = str(selected_variant_id or semantic_variant_id or semantic_template_id or "")
            if cache_key in lineage_cache:
                canonical_source = lineage_cache[cache_key]

        row_id = f"{case_id}:{turn_index}:{msg_idx}"

        row: dict[str, Any] = {
            "schema": EVIDENCE_SCHEMA_V1,
            "schemaVersion": 1,
            "rowID": row_id,
            "identity": {
                "sweepID": sweep_id,
                "caseID": case_id,
                "batchID": batch_id,
                "strategy": strategy,
                "turnIndex": turn_index,
                "messageIndex": msg_idx,
                "speaker": "npc",
                "language": language,
                "salt": salt,
                "historyMode": history_mode,
                "input": {
                    "text": input_spec.get("text") or record.get("input") if input_spec else record.get("input"),
                    "rootChoice": input_spec.get("rootChoice") if input_spec else None,
                    "suggestionClick": input_spec.get("suggestionClick") if input_spec else None,
                    "action": input_spec.get("action") if input_spec else None,
                },
            },
            "trigger": {
                "parameters": params,
                "personaSummary": persona_summary,
                "relationshipSummary": relationship_summary,
                "stateSummary": state_summary,
                "actorSummary": actor_summary,
            },
            "semanticPath": {
                "intent": semantic.get("intent"),
                "speechAct": semantic.get("speechAct"),
                "subject": semantic.get("subject"),
                "flowID": view.get("selectedFlow", {}).get("id") if isinstance(view.get("selectedFlow"), dict) else None,
                "policyBranch": view.get("dialoguePlan", {}).get("policyBranch") if isinstance(view.get("dialoguePlan"), dict) else None,
                "semanticTemplateID": str(semantic_template_id) if semantic_template_id else None,
                "renderTemplateID": str(render_template_id) if render_template_id else None,
                "semanticVariantID": str(semantic_variant_id) if semantic_variant_id else None,
                "realizationFamily": str(realization_family) if realization_family else None,
                "realizationVariant": str(realization_variant) if realization_variant else None,
                "phraseID": str(phrase_id) if phrase_id else None,
                "translationKey": str(translation_key) if translation_key else None,
                "familyAddress": str(family_address) if family_address else None,
            },
            "output": {
                "finalText": final_text,
                "renderedKey": str(rendered_key) if rendered_key else None,
                "fallbackReason": str(fallback_reason) if fallback_reason else None,
                "recentResponses": [str(rendered_key)] if rendered_key else [],
            },
            "selectionProvenance": {
                "provenance": provenance,
                "selectedVariantID": str(selected_variant_id) if selected_variant_id else None,
                "candidateCount": candidate_count,
                "candidateRejectionReasons": candidate_rejections,
                "canonicalSourceOwner": canonical_source,
                "fingerprints": {
                    "catalogFingerprint": record.get("catalogFingerprint"),
                    "revision": record.get("revision"),
                },
            },
            "authority": authority_summary,
            "quality": {
                "flags": [],
                "clusterKeys": [],
                "reviewState": "UNREVIEWED",
                "reviewNotes": None,
            },
            "traceHandle": {
                "caseID": case_id,
                "turnIndex": turn_index,
                "lazy": True,
            },
        }
        rows.append(row)

    return rows


def validate_evidence_row(row: Mapping[str, Any]) -> None:
    """Validate that an evidence row conforms to EVIDENCE_SCHEMA_V1."""
    if not isinstance(row, Mapping):
        raise ValueError("Evidence row must be a dictionary")
    schema = row.get("schema")
    if schema not in ALLOWED_EVIDENCE_SCHEMAS:
        raise ValueError(f"Evidence schema '{schema}' is not supported. Expected {EVIDENCE_SCHEMA_V1}")
    if row.get("schemaVersion") != 1:
        raise ValueError(f"Evidence schemaVersion must be 1, got {row.get('schemaVersion')}")
    if not row.get("rowID"):
        raise ValueError("Evidence row must have a non-empty rowID")

    for req_field in (
        "identity",
        "trigger",
        "semanticPath",
        "output",
        "selectionProvenance",
        "authority",
        "quality",
        "traceHandle",
    ):
        if req_field not in row or not isinstance(row[req_field], Mapping):
            raise ValueError(f"Evidence row missing or invalid required field '{req_field}'")

    if row["traceHandle"].get("lazy") is not True:
        raise ValueError("Evidence row traceHandle must have lazy=True")
