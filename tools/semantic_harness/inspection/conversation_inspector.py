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
        result = [_bounded(item, depth + 1, limit) for item in value[:limit]]
        if len(value) > limit:
            result.append(f"<{len(value) - limit} more>")
        return result
    if isinstance(value, dict):
        keys = sorted(value, key=str)
        result = {
            str(key): _bounded(value[key], depth + 1, limit)
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


def _trace_data(record: dict[str, Any]) -> dict[str, Any]:
    trace = record.get("trace", [])
    if not isinstance(trace, list):
        return {}
    for event in trace:
        if not isinstance(event, dict):
            continue
        data = event.get("data")
        if isinstance(data, dict):
            return data
    return {}


def _reference(target: Any) -> dict[str, Any] | None:
    if not isinstance(target, dict):
        return None
    return _bounded({
        "surface": target.get("text") or target.get("reference"),
        "reference": target.get("reference"),
        "resolvedReference": target.get("resolvedReference"),
        "unresolved": target.get("unresolved"),
        "concept": target.get("concept"),
        "value": target.get("value"),
        "entityType": target.get("entityType"),
        "resolution": target.get("resolution"),
    }, limit=16)


def _fact_providers(facts: dict[str, Any]) -> list[str]:
    providers = {
        str(fact.get("provider"))
        for fact in facts.values()
        if isinstance(fact, dict) and fact.get("provider")
    }
    return sorted(providers)


def _graph_projection(selected: dict[str, Any]) -> dict[str, Any]:
    metadata = selected.get("metadata")
    metadata = metadata if isinstance(metadata, dict) else {}
    graph_metadata = metadata.get("semanticLabGraph")
    graph_metadata = graph_metadata if isinstance(graph_metadata, dict) else {}
    graph = graph_metadata.get("graph")
    graph = graph if isinstance(graph, dict) else {}
    blocks = graph.get("blocks", [])
    blocks = blocks if isinstance(blocks, list) else []
    connections = graph.get("connections", [])
    connections = connections if isinstance(connections, list) else []
    compact_blocks = [
        {
            "id": block.get("id"),
            "type": block.get("type"),
        }
        for block in blocks
        if isinstance(block, dict)
    ]
    compact_connections = [
        {
            "from": connection.get("from"),
            "to": connection.get("to"),
            "type": connection.get("type"),
        }
        for connection in connections
        if isinstance(connection, dict)
    ]
    return {
        "available": bool(graph_metadata),
        "schema": graph_metadata.get("schema"),
        "fingerprint": graph_metadata.get("fingerprint"),
        "blocks": _bounded(compact_blocks, limit=16),
        "connections": _bounded(compact_connections, limit=24),
    }


def _dossier_entries(snapshot: Any) -> dict[str, dict[str, Any]]:
    if not isinstance(snapshot, dict):
        return {}
    knowledge = snapshot.get("knowledge") or snapshot.get("dossier")
    if not isinstance(knowledge, dict):
        return {}
    entries: dict[str, dict[str, Any]] = {}
    categories = knowledge.get("categories", [])
    if not isinstance(categories, list):
        return entries
    for category in categories:
        if not isinstance(category, dict):
            continue
        descriptors = category.get("descriptors", [])
        if not isinstance(descriptors, list):
            continue
        for descriptor in descriptors:
            if not isinstance(descriptor, dict):
                continue
            descriptor_id = str(descriptor.get("descriptorID") or "")
            if descriptor_id:
                entries[descriptor_id] = {
                    "status": descriptor.get("status"),
                    "value": descriptor.get("value"),
                    "evidenceCount": descriptor.get("evidenceCount"),
                    "category": descriptor.get("category") or category.get("id"),
                }
    return entries


def _dossier_changes(before: Any, after: Any) -> dict[str, Any]:
    before_entries = _dossier_entries(before)
    after_entries = _dossier_entries(after)
    added = sorted(set(after_entries) - set(before_entries))
    removed = sorted(set(before_entries) - set(after_entries))
    changed = sorted(
        key for key in set(before_entries) & set(after_entries)
        if before_entries[key] != after_entries[key]
    )
    after_knowledge = after.get("knowledge") if isinstance(after, dict) else None
    return {
        "scope": "player_scoped_npc_dossier",
        "beforeCount": len(before_entries),
        "afterCount": len(after_entries),
        "addedDescriptorIDs": added,
        "removedDescriptorIDs": removed,
        "changedDescriptorIDs": changed,
        "afterRevision": (
            after_knowledge.get("revision")
            if isinstance(after_knowledge, dict)
            else None
        ),
    }


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


def _persona_choice_projection(
    record: dict[str, Any], context: dict[str, Any], observation: dict[str, Any]
) -> dict[str, Any]:
    suggestions = observation.get("suggestions")
    suggestions = suggestions if isinstance(suggestions, dict) else {}
    rows = []
    for source in (
        suggestions.get("candidates") or [],
        suggestions.get("permittedCapabilities") or [],
    ):
        for candidate in source[:24]:
            if not isinstance(candidate, dict):
                continue
            display = candidate.get("display")
            display = display if isinstance(display, dict) else {}
            rows.append(
                {
                    "id": candidate.get("id"),
                    "action": candidate.get("action"),
                    "providerID": candidate.get("providerID"),
                    "source": candidate.get("source"),
                    "sources": candidate.get("sources"),
                    "eligibility": candidate.get("eligibility"),
                    "visibility": candidate.get("visibility"),
                    "ranking": candidate.get("ranking"),
                    "labelKey": display.get("labelKey"),
                    "label": display.get("label"),
                    "utteranceKey": display.get("utteranceKey"),
                    "utterance": display.get("utterance"),
                    "frame": candidate.get("frame"),
                }
            )
    result = record.get("result")
    result = result if isinstance(result, dict) else {}
    response = observation.get("response")
    response = response if isinstance(response, dict) else {}
    queued = (response.get("queued") or [response])[0]
    queued = queued if isinstance(queued, dict) else response
    args = queued.get("args") if isinstance(queued.get("args"), dict) else {}
    actor_context = context.get("actorConversationContext", {})
    actor_context = actor_context if isinstance(actor_context, dict) else {}
    return {
        "actorConversationContext": _bounded(
            context.get("actorConversationContext", {}), limit=32
        ),
        "speechStyleContext": _bounded(
            context.get("speechStyleContext", {}), limit=24
        ),
        "choiceRegistry": _bounded(suggestions.get("choiceRegistry", {}), limit=24),
        "candidates": _bounded(rows, limit=32),
        "ranking": _bounded(suggestions.get("ranking", {}), limit=24),
        "privacy": _bounded(suggestions.get("privacy", {}), limit=16),
        "realization": _bounded(response.get("realization", {}), limit=24),
        "realizationFamily": response.get("realizationFamily"),
        "realizationVariant": response.get("realizationVariant"),
        "realizationFallbackReason": response.get("realizationFallbackReason"),
        "responseTrace": {
            "semanticTemplateID": response.get("templateID"),
            "renderTemplateID": response.get("renderTemplateID"),
            "realizationFamily": queued.get("realizationFamily")
            or response.get("realizationFamily"),
            "realizationVariant": queued.get("realizationVariant")
            or response.get("realizationVariant"),
            "fallbackReason": queued.get("realizationFallbackReason")
            or response.get("realizationFallbackReason"),
            "translationKey": queued.get("translationKey")
            or response.get("translationKey"),
            "familyAddress": args.get("familyAddress"),
            "bond": _bounded(actor_context.get("bond", {}), limit=16),
            "semanticFrame": _bounded(
                result.get("ir")
                or response.get("plan")
                or response.get("args")
                or {},
                limit=24,
            ),
        },
        "receipt": {
            "accepted": record.get("accepted") is True,
            "reason": record.get("reason") or result.get("reason"),
            "requestRevision": result.get("sequence"),
            "replaySafe": record.get("reason") in {
                "duplicate_suggestion", "stale_suggestion",
            },
        },
        "dialogueResult": _bounded(result, limit=24),
        "gameplayAction": _bounded(
            observation.get("actionResult") or result.get("actionResult") or {},
            limit=24,
        ),
    }


def build_conversation_inspector(record: dict[str, Any]) -> dict[str, Any]:
    """Return a bounded, read-only state/plan/trace view for the Lab UI."""

    if not isinstance(record, dict):
        record = {}
    context = _context(record)
    dialogue = _dialogue(context)
    observation = _observation(record)
    persona_choices = _persona_choice_projection(record, context, observation)
    catalog = record.get("personaCatalog")
    if isinstance(catalog, dict):
        persona_choices["speechRealizationCoverage"] = _bounded(
            catalog.get("speechRealization", {}), limit=32
        )
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
    diagnostics = ir.get("diagnostics", {})
    diagnostics = diagnostics if isinstance(diagnostics, dict) else {}
    trace_data = _trace_data(record)
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
    selected_binding = selected.get("binding")
    if not isinstance(selected_binding, dict):
        selected_binding = action_result.get("binding")
    effects = {
        "transportCount": len(record.get("transport", []))
        if isinstance(record.get("transport", []), list) else 0,
        "toolCallCount": len(record.get("toolCalls", []))
        if isinstance(record.get("toolCalls", []), list) else 0,
        "sideEffects": _bounded(observation.get("sideEffects", {})),
    }
    is_gameplay_action = bool(
        ir.get("action")
        or action_result
        or selected_binding
    )
    fact_status = diagnostics.get("factStatus")
    if fact_status is None:
        fact_status = response.get("uncertainty")
    understanding = {
        "classification": trace_data.get("classification"),
        "intent": ir.get("intent") or observation.get("ir", {}).get("intent"),
        "speechAct": ir.get("speechAct") or observation.get("ir", {}).get("speechAct"),
        "subject": ir.get("subject") or observation.get("ir", {}).get("subject"),
        "pattern": ir.get("provenance", {}).get("pattern")
        if isinstance(ir.get("provenance"), dict)
        else observation.get("ir", {}).get("pattern"),
        "confidence": ir.get("confidence") or observation.get("ir", {}).get("confidence"),
        "reference": _reference(ir.get("target")),
    }
    facts_view = {
        "status": fact_status,
        "providers": _fact_providers(facts),
        "groundedFactRefs": _bounded(response_refs),
        "entries": _bounded(facts, limit=32),
        "planFactRefs": _bounded(plan_refs),
    }
    graph_view = _graph_projection(selected)
    codeblock_view = {
        "patternID": selected.get("patternID"),
        "graphFingerprint": graph_view.get("fingerprint"),
        "blockIDs": [
            block.get("id")
            for block in graph_view.get("blocks", [])
            if isinstance(block, dict) and block.get("id")
        ],
        "blockTypes": [
            block.get("type")
            for block in graph_view.get("blocks", [])
            if isinstance(block, dict) and block.get("type")
        ],
    }
    knowledge_permission = {
        "status": fact_status,
        "reason": diagnostics.get("factReason") or diagnostics.get("reason"),
        "provider": diagnostics.get("factProvider") or facts_view["providers"],
        "scope": "player_scoped_npc_knowledge",
        "dossierPresent": bool(_dossier_entries(context)),
    }
    fact_provider = diagnostics.get("factProvider") or facts_view["providers"]
    if isinstance(fact_provider, str):
        fact_provider = [fact_provider]
    social_context = context.get("socialContext")
    if not isinstance(social_context, dict):
        actor_context = context.get("actorConversationContext")
        actor_context = actor_context if isinstance(actor_context, dict) else {}
        social_context = {
            "personalRelationship": actor_context.get(
                "personalRelationship", actor_context.get("relationship")
            ),
            "factionRelationship": actor_context.get("factionRelationship"),
            "tacticalHostility": actor_context.get("tacticalHostility"),
            "conversationAudience": actor_context.get("conversationAudience"),
            "durableBond": actor_context.get("bond"),
            "speechStyle": context.get("speechStyleContext"),
            "provenance": actor_context.get("provenance"),
        }
    translation_view = record.get("translation", {})
    translation_view = (
        translation_view if isinstance(translation_view, dict) else {}
    )
    acceptance_chain = {
        "utterance": record.get("input"),
        "selectedCodeBlock": _bounded(codeblock_view, limit=16),
        "selectedGraph": _bounded(graph_view, limit=24),
        "coreMeaning": _bounded(understanding, limit=16),
        "factProvider": fact_provider,
        "knowledgePermission": _bounded(knowledge_permission, limit=16),
        "translation": _bounded(translation_view, limit=24),
        "actualNPCResponse": _bounded(visible_response, limit=16),
        "gameplayEffects": _bounded(effects, limit=24),
        "dossierChanges": _bounded(
            _dossier_changes(record.get("contextBefore"), context),
            limit=24,
        ),
    }
    dialogue_planning = {
        "topic": (plan or {}).get("topic") or response.get("topic"),
        "dialogueAct": (plan or {}).get("dialogueAct")
        or response.get("dialogueAct"),
        "sourcePoolID": (plan or {}).get("sourcePoolID")
        or response.get("sourcePoolID"),
        "selectionSource": response.get("selectionSource"),
        "tone": (plan or {}).get("tone") or response.get("tone"),
        "uncertainty": (plan or {}).get("uncertainty")
        or response.get("uncertainty"),
        "groundedFactRefs": _bounded(
            (plan or {}).get("groundedFactRefs") or response_refs
        ),
        "turns": _bounded((plan or {}).get("turns", []), limit=8),
        "flow": _bounded(flow, limit=24),
    }
    command_authority = {
        "isGameplayAction": is_gameplay_action,
        "action": ir.get("action"),
        "route": decision.get("route"),
        "branch": decision.get("branch"),
        "accepted": action_result.get("accepted"),
        "status": action_result.get("status"),
        "authority": action_result.get("authority"),
        "capabilityID": action_result.get("capabilityID")
        or selected.get("capabilityID"),
        "binding": _bounded(selected_binding, limit=24),
        "effects": effects,
        "result": _bounded(action_result, limit=24),
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
        "understanding": _bounded(understanding, limit=16),
        "facts": _bounded(facts_view, limit=32),
        "socialContext": _bounded(social_context, limit=48),
        "acceptanceChain": acceptance_chain,
        "dialoguePlanning": _bounded(dialogue_planning, limit=24),
        "finalResponse": _bounded({
            **visible_response,
            "templateID": response.get("templateID"),
            "selectionSource": response.get("selectionSource"),
            "groundedFactRefs": response_refs,
        }, limit=16),
        "commandAuthority": _bounded(command_authority, limit=24),
        "personaChoices": persona_choices,
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
