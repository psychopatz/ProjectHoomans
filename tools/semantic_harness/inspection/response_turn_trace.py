"""Bounded observed-turn join from real Lua text, registry and authority effects."""
from __future__ import annotations

from typing import Any

from .conversation_inspector import build_conversation_inspector
from ..runtime.worker import LuaSemanticWorker


def inspect_response_turn(
    worker: LuaSemanticWorker, turn: dict[str, Any],
) -> dict[str, Any]:
    """Observe an already executed turn; no commands or selection are invoked."""
    view = build_conversation_inspector(turn)
    npc = [
        m.get("payload", {}) for m in turn.get("messages", [])
        if m.get("speaker") == "npc"
        and isinstance(m.get("payload"), dict)
    ]
    result = []
    for message in npc[-4:]:
        key = str(message.get("key") or "")
        lookup = worker.response_key_lookup(key) if key else {
            "matches": [], "truncated": False, "matchCount": 0,
        }
        matched = lookup.get("matches", [])
        direct = [
            row for row in matched
            if row.get("matchKind") == "REGISTERED_VARIANT_ID"
        ]
        verified = (
            len(direct) == 1 and lookup.get("matchCount") == 1
            and not lookup.get("truncated")
        )
        result.append({
            "observedKey": key,
            "translationKey": message.get("translationKey"),
            "finalText": message.get("text"),
            "registrationMatchCount": lookup.get("matchCount", 0),
            "registeredVariants": matched[:8],
            "registrationTruncated": lookup.get("truncated", False)
                or len(matched) > 8,
            "selectedVariantID": direct[0]["variantID"] if verified else None,
            "selectionProvenance": "EXACT_EMITTED_VARIANT_ID"
                if verified else "TEMPLATE_CANDIDATES_ONLY"
                if matched else "UNKNOWN",
        })
    looked_up = (turn.get("translation") or {}).get("lookups") or []
    translation = [
        {
            "key": item.get("key"), "language": item.get("language"),
            "fallbackUsed": item.get("fallbackUsed") is True,
        } for item in looked_up[-16:] if isinstance(item, dict)
    ]
    effects = (view.get("effects") or {}).get("sideEffects") or {}
    execution = view.get("execution") or {}
    return {
        "ok": True, "type": "response_turn_observatory",
        "schemaVersion": 1, "sourceKind": "FIXTURE",
        "workerKind": "production_lua",
        "accepted": turn.get("accepted"),
        "npcMessages": result,
        "messagesTruncated": len(npc) > 4,
        "translationLookups": translation,
        "translationLookupsTruncated": len(looked_up) > 16,
        "effects": {
            "actionCount": effects.get("actionCount", 0),
            "transportCount": effects.get("transportCount", 0),
            "none": effects.get("none", True),
            "actions": (effects.get("actions") or [])[:4],
        },
        "execution": {
            "owner": execution.get("owner"),
            "authority": execution.get("authority"),
            "status": execution.get("status"),
            "rejectionReason": execution.get("rejectionReason"),
        },
        "observedNotPreview": True,
    }
