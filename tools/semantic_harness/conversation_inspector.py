"""Bounded Conversation State Inspector projection for Semantic Lab.

The inspector is a read-only view over a real worker turn or snapshot. It
does not retain a transcript or create a second context store.
"""

from __future__ import annotations

from typing import Any


MAX_ITEMS = 8
MAX_TRACE_ITEMS = 16
MAX_DEPTH = 5
MAX_TEXT = 512


def _bounded(value: Any, depth: int = 0, limit: int = MAX_ITEMS) -> Any:
    if depth >= MAX_DEPTH:
        return "<depth limit>"
    if isinstance(value, str):
        return value if len(value) <= MAX_TEXT else value[:MAX_TEXT] + "…"
    if isinstance(value, (int, float, bool)) or value is None:
        return value
    if isinstance(value, list):
        result = [_bounded(item, depth + 1) for item in value[:limit]]
        if len(value) > limit:
            result.append(f"<{len(value) - limit} more>")
        return result
    if isinstance(value, dict):
        keys = sorted(value, key=str)
        result = {
            str(key): _bounded(value[key], depth + 1)
            for key in keys[:limit]
        }
        if len(keys) > limit:
            result["_truncatedKeys"] = len(keys) - limit
        return result
    return str(value)


def _context(record: dict[str, Any]) -> dict[str, Any]:
    context = record.get("contextAfter") or record.get("context") or {}
    return context if isinstance(context, dict) else {}


def _dialogue(context: dict[str, Any]) -> dict[str, Any]:
    dialogue = context.get("dialogue", {})
    return dialogue if isinstance(dialogue, dict) else {}


def _observation(record: dict[str, Any]) -> dict[str, Any]:
    observation = record.get("observation", {})
    return observation if isinstance(observation, dict) else {}


def _response(record: dict[str, Any], observation: dict[str, Any]) -> dict[str, Any]:
    response = observation.get("response")
    if isinstance(response, dict):
        return response
    result = record.get("result", {})
    if isinstance(result, dict):
        decision = result.get("decision", {})
        if isinstance(decision, dict) and isinstance(decision.get("response"), dict):
            return decision["response"]
    return {}


def _plan(response: dict[str, Any]) -> dict[str, Any] | None:
    plan = response.get("plan")
    return plan if isinstance(plan, dict) else None


def _visible_text(record: dict[str, Any], response: dict[str, Any]) -> dict[str, Any]:
    messages = record.get("messages", [])
    npc_message = next(
        (
            message for message in messages
            if isinstance(message, dict) and message.get("speaker") == "npc"
        ),
        {},
    )
    payload = npc_message.get("payload", {}) if isinstance(npc_message, dict) else {}
    payload = payload if isinstance(payload, dict) else {}
    return {
        "text": payload.get("text") or response.get("text") or response.get("fallback"),
        "fallback": payload.get("fallback") or response.get("fallback"),
        "translationKey": payload.get("translationKey") or response.get("templateID"),
        "language": (record.get("translation") or {}).get("language")
        if isinstance(record.get("translation"), dict) else None,
    }


def build_conversation_inspector(record: dict[str, Any]) -> dict[str, Any]:
    """Return a bounded, read-only state/plan/trace view for the Lab UI."""

    if not isinstance(record, dict):
        record = {}
    context = _context(record)
    dialogue = _dialogue(context)
    observation = _observation(record)
    response = _response(record, observation)
    plan = _plan(response)
    result = record.get("result", {})
    result = result if isinstance(result, dict) else {}
    ir = result.get("ir", {})
    ir = ir if isinstance(ir, dict) else {}
    flow = observation.get("flow", {})
    flow = flow if isinstance(flow, dict) else {}
    selected = observation.get("selectedCandidate", {})
    selected = selected if isinstance(selected, dict) else {}
    if not selected:
        selected = observation.get("candidates", {})
        selected = selected if isinstance(selected, dict) else {}
    extensions = ir.get("extensions", {})
    extensions = extensions if isinstance(extensions, dict) else {}
    facts = extensions.get("facts", {})
    facts = facts if isinstance(facts, dict) else {}
    plan_refs = plan.get("groundedFactRefs", []) if plan else []
    response_refs = response.get("groundedFactRefs", [])
    if not isinstance(plan_refs, list):
        plan_refs = []
    if not isinstance(response_refs, list):
        response_refs = []

    action_result = observation.get("actionResult")
    if not isinstance(action_result, dict):
        action_result = result.get("actionResult")
    if not isinstance(action_result, dict):
        action_result = {}
    decision = result.get("decision", {})
    decision = decision if isinstance(decision, dict) else {}
    visible_response = _visible_text(record, response)
    flow_owner = "flow" if flow.get("matched") is True else "policy"
    execution = {
        "route": decision.get("route"),
        "branch": decision.get("branch"),
        "owner": flow_owner,
        "status": action_result.get("status"),
        "accepted": action_result.get("accepted"),
        "requestID": action_result.get("requestID"),
        "npcID": action_result.get("npcID"),
        "speechAct": action_result.get("speechAct") or ir.get("speechAct"),
        "authority": action_result.get("authority"),
        "result": _bounded(action_result, limit=24),
        "rejectionReason": action_result.get("reason"),
        "finalText": visible_response.get("text"),
        "responseTemplate": response.get("templateID"),
        "responsePool": response.get("sourcePoolID"),
    }

    return {
        "schemaVersion": 1,
        "source": "real_lua_worker",
        "input": record.get("input"),
        "turn": {
            "type": record.get("type"),
            "accepted": record.get("accepted") is True,
            "sequence": dialogue.get("sequence"),
            "lastIntent": dialogue.get("lastIntent"),
            "lastSpeaker": dialogue.get("lastSpeaker"),
            "llmCalls": record.get("llmCalls", 0),
        },
        "context": {
            "currentTopic": dialogue.get("currentTopic"),
            "previousTopic": dialogue.get("previousTopic"),
            "priorTopics": _bounded(dialogue.get("priorTopics", []), limit=16),
            "focus": _bounded(dialogue.get("focus", []), limit=16),
            "mentions": _bounded(dialogue.get("mentions", []), limit=16),
            "pendingObligation": _bounded(dialogue.get("pendingFollowUp"), limit=32),
            "agenda": _bounded(dialogue.get("agenda", []), limit=16),
            "flowSessions": _bounded(dialogue.get("flowSessions", []), limit=16),
            "engineFacts": _bounded(context.get("engineFacts", {}), limit=32),
            "engineEvents": _bounded(context.get("engineEvents", []), limit=16),
        },
        "memoryProvenance": {
            "planFactRefs": _bounded(plan_refs),
            "responseFactRefs": _bounded(response_refs),
            "irFacts": _bounded(facts),
            "uncertainty": plan.get("uncertainty") if plan else response.get("uncertainty"),
        },
        "semantic": {
            "intent": ir.get("intent") or observation.get("ir", {}).get("intent"),
            "speechAct": ir.get("speechAct") or observation.get("ir", {}).get("speechAct"),
            "subject": ir.get("subject") or observation.get("ir", {}).get("subject"),
            "pattern": ir.get("provenance", {}).get("pattern")
            if isinstance(ir.get("provenance"), dict)
            else observation.get("ir", {}).get("pattern"),
            "confidence": ir.get("confidence") or observation.get("ir", {}).get("confidence"),
            "selectedCandidate": _bounded(selected),
        },
        "dialoguePlan": _bounded(plan, limit=32),
        "selectedFlow": _bounded(flow, limit=32),
        "visibleResponse": _bounded(visible_response),
        "execution": _bounded(execution, limit=24),
        "workerTrace": _bounded(record.get("trace", []), limit=MAX_TRACE_ITEMS),
        "effects": _bounded({
            "transport": record.get("transport", []),
            "toolCalls": record.get("toolCalls", []),
            "sideEffects": observation.get("sideEffects", {}),
        }),
    }


__all__ = ["build_conversation_inspector"]
