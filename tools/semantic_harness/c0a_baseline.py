"""C0A characterization projections backed by the production Lua worker.

This module is deliberately an observer.  It sends fixture text and typed
frames to the existing ``LuaSemanticWorker`` and projects bounded fields from
the returned production records.  It does not normalize text, select an
intent, rank a candidate, or decide a safety policy in Python.
"""

from __future__ import annotations

import argparse
import json
import re
from copy import deepcopy
from pathlib import Path
from typing import Any, Iterable

from tools.semantic_harness.codebuilder.conversation_compiler import (
    CONVERSATION_MANIFEST_RELATIVE,
    CONVERSATION_RUNTIME_RELATIVE,
    CONVERSATION_SOURCE_RELATIVE,
    compile_conversation_sources,
    render_conversation_runtime_plan,
)
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[2]
FIXTURE_ROOT = REPOSITORY / "tools/semantic_harness/fixtures/c0a"
SCHEMA_VERSION = "projecthoomans.c0a.current.v1"
STATIC_SOURCE_KINDS = frozenset({
    "conversation_root",
    "conversation_registry",
    "typed_input",
})
DERIVED_SOURCE_KINDS = frozenset({
    "active_flow",
    "npc_response_plan",
    "social_context",
    "permitted_capability",
})


def load_fixture(name: str) -> dict[str, Any]:
    return json.loads((FIXTURE_ROOT / name).read_text(encoding="utf-8"))


def _pick(value: Any, keys: Iterable[str]) -> dict[str, Any]:
    if not isinstance(value, dict):
        return {}
    return {key: value[key] for key in keys if key in value}


def _context_view(value: Any) -> dict[str, Any] | None:
    if not isinstance(value, dict):
        return None
    state = value.get("state") if isinstance(value.get("state"), dict) else {}
    dialogue = value.get("dialogue")
    if not isinstance(dialogue, dict):
        dialogue = state.get("dialogue") if isinstance(state.get("dialogue"), dict) else {}
    view = {
        "stateSequence": state.get("sequence"),
        "dialogue": _pick(
            dialogue,
            (
                "sequence",
                "currentTopic",
                "previousTopic",
                "lastSpeaker",
                "pendingFollowUp",
                "priorTopics",
            ),
        ),
    }
    recent_turns = dialogue.get("recentTurns")
    if isinstance(recent_turns, list):
        view["dialogue"]["recentTurnCount"] = len(recent_turns)
        view["dialogue"]["recentTurnTail"] = [
            _pick(item, ("sequence", "speaker", "topic", "intent", "speechAct"))
            for item in recent_turns[-4:]
            if isinstance(item, dict)
        ]
    flow_sessions = dialogue.get("flowSessions")
    if isinstance(flow_sessions, list):
        view["dialogue"]["flowSessionCount"] = len(flow_sessions)
        view["dialogue"]["flowSessionIDs"] = [
            item.get("id") or item.get("flowID")
            for item in flow_sessions[-4:]
            if isinstance(item, dict)
        ]
    return view


def _ir_view(ir: Any) -> dict[str, Any]:
    if not isinstance(ir, dict):
        return {}
    diagnostics = ir.get("diagnostics") if isinstance(ir.get("diagnostics"), dict) else {}
    metrics = diagnostics.get("matchMetrics") if isinstance(diagnostics.get("matchMetrics"), dict) else {}
    return {
        "intent": ir.get("intent"),
        "speechAct": ir.get("speechAct"),
        "subject": ir.get("subject"),
        "normalizedText": ir.get("normalizedText"),
        "rawText": ir.get("rawText"),
        "confidence": ir.get("confidence"),
        "confidenceBand": ir.get("confidenceBand"),
        "provenance": _pick(
            ir.get("provenance"),
            ("provider", "parser", "pattern", "candidatePass", "candidateEligibility"),
        ),
        "diagnostics": {
            "candidatePass": diagnostics.get("candidatePass"),
            "parser": diagnostics.get("parser"),
            "matchedPattern": diagnostics.get("matchedPattern"),
            "recommendedRoute": diagnostics.get("recommendedRoute"),
            "noMatch": diagnostics.get("noMatch"),
            "ambiguous": diagnostics.get("ambiguous"),
            "truncated": diagnostics.get("truncated"),
            "exactMatch": diagnostics.get("exactMatch"),
            "fuzzyMatch": diagnostics.get("fuzzyMatch"),
            "unmatchedTokens": diagnostics.get("unmatchedTokens", []),
            "unresolvedEntity": diagnostics.get("unresolvedEntity"),
            "correctedTokens": diagnostics.get("correctedTokens", []),
            "contextResolvedReferences": diagnostics.get("contextResolvedReferences", []),
            "contextUnresolvedReferences": diagnostics.get("contextUnresolvedReferences", []),
            "entityResolutionFailures": diagnostics.get("entityResolutionFailures", []),
            "candidateSelection": _pick(
                diagnostics.get("candidateSelection"),
                ("reason", "candidateCount", "eligibleCount", "rejectedCount", "tiedEligibleCount"),
            ),
            "matchMetrics": _pick(
                metrics,
                ("consumed", "fullCoverage", "fuzzyCount", "skipped", "unmatchedCount", "unresolvedCount"),
            ),
        },
    }


def _candidate_view(candidate: Any) -> dict[str, Any]:
    if not isinstance(candidate, dict):
        return {}
    ir = candidate.get("ir") if isinstance(candidate.get("ir"), dict) else {}
    return {
        "patternID": candidate.get("patternID"),
        "pass": candidate.get("pass"),
        "score": candidate.get("score"),
        "selected": candidate.get("selected"),
        "exact": candidate.get("exact"),
        "fuzzy": candidate.get("fuzzy"),
        "intent": ir.get("intent"),
        "speechAct": ir.get("speechAct"),
        "subject": ir.get("subject"),
        "confidence": ir.get("confidence"),
        "diagnostics": _pick(
            ir.get("diagnostics"),
            (
                "matchedPattern",
                "candidatePass",
                "recommendedRoute",
                "unmatchedTokens",
                "unresolvedEntity",
                "correctedTokens",
                "matchMetrics",
            ),
        ),
    }


def _plan_view(plan: Any) -> dict[str, Any] | None:
    if not isinstance(plan, dict):
        return None
    turns = []
    for turn in plan.get("turns", [])[:4] if isinstance(plan.get("turns"), list) else []:
        if not isinstance(turn, dict):
            continue
        segments = []
        for segment in turn.get("segments", [])[:6] if isinstance(turn.get("segments"), list) else []:
            if not isinstance(segment, dict):
                continue
            segments.append(
                _pick(
                    segment,
                    ("kind", "templateID", "semanticTemplateID", "fallback", "realizationFamily", "phraseFamilyID"),
                )
            )
        offers = []
        for offer in turn.get("offers", [])[:8] if isinstance(turn.get("offers"), list) else []:
            if isinstance(offer, dict):
                offers.append(_pick(offer, ("id", "labelKey", "utteranceKey")))
        turns.append({
            **_pick(turn, ("id", "continuation", "separator")),
            "segments": segments,
            "offers": offers,
        })
    return {
        **_pick(plan, ("kind", "schemaVersion", "dialogueAct", "sourcePoolID", "sourceFlowID")),
        "turns": turns,
    }


def _response_view(response: Any) -> dict[str, Any]:
    if not isinstance(response, dict):
        return {}
    return {
        **_pick(
            response,
            (
                "templateID",
                "selectionID",
                "selectionSource",
                "sourcePoolID",
                "sourceFlowID",
                "fallback",
                "realizationFamily",
                "realizationVariant",
                "realizationFallbackReason",
                "phraseFamilyID",
                "phraseID",
                "phrasePoolSize",
                "phraseAntiRepeatReason",
                "phraseSemanticTemplateID",
            ),
        ),
        "plan": _plan_view(response.get("plan")),
    }


def _message_view(message: Any) -> dict[str, Any]:
    if not isinstance(message, dict):
        return {}
    payload = message.get("payload") if isinstance(message.get("payload"), dict) else {}
    realization = payload.get("realization") if isinstance(payload.get("realization"), dict) else {}
    return {
        "text": payload.get("text"),
        "renderTemplateID": payload.get("renderTemplateID"),
        "semanticTemplateID": payload.get("semanticTemplateID"),
        "phraseSemanticTemplateID": payload.get("phraseSemanticTemplateID"),
        "phraseFamilyID": payload.get("phraseFamilyID"),
        "phraseID": payload.get("phraseID"),
        "phrasePoolSize": payload.get("phrasePoolSize"),
        "realization": _pick(
            realization,
            ("family", "variant", "applied", "applicationCount", "neutralFallbackCount", "maxApplications"),
        ),
        "planTurn": payload.get("planTurn"),
        "planTurnID": payload.get("planTurnID"),
    }


def _interaction_view(observation: Any, decision: Any) -> dict[str, Any]:
    observation = observation if isinstance(observation, dict) else {}
    decision = decision if isinstance(decision, dict) else {}
    director = observation.get("director") if isinstance(observation.get("director"), dict) else {}
    plan = observation.get("interactionPlan")
    if not isinstance(plan, dict):
        plan = decision.get("interactionPlan") if isinstance(decision.get("interactionPlan"), dict) else {}
    selected_beat = director.get("selectedBeat") if isinstance(director.get("selectedBeat"), dict) else {}
    selected_behavior = director.get("selectedBehavior") if isinstance(director.get("selectedBehavior"), dict) else {}
    stimulus = director.get("stimulus") if isinstance(director.get("stimulus"), dict) else {}
    semantic = stimulus.get("semantic") if isinstance(stimulus.get("semantic"), dict) else {}
    source = stimulus.get("source") if isinstance(stimulus.get("source"), dict) else {}
    metrics = director.get("metrics") if isinstance(director.get("metrics"), dict) else {}
    return {
        "stimulus": {
            **_pick(stimulus, ("type", "text", "targets")),
            "semantic": _pick(semantic, ("intent", "speechAct", "subject", "topic", "confidence")),
            "source": _pick(source, ("providerID", "kind", "actorID")),
        },
        "selectedBeat": _pick(selected_beat, ("id", "group", "baseRelevance")),
        "selectedBehavior": _pick(selected_behavior, ("id", "act", "mode", "score", "contentTemplateID", "dialogueAct")),
        "interactionPlan": _pick(
            plan,
            (
                "beatID",
                "behaviorID",
                "dialogueAct",
                "contentTemplateID",
                "sourceIntent",
                "sourceSpeechAct",
                "subject",
                "topic",
                "sourceStimulusType",
            ),
        ),
        "metrics": _pick(
            metrics,
            (
                "stimulusType",
                "catalogBeatCount",
                "canonicalBeatCount",
                "indexedBeatCandidateCount",
                "beatCandidatesEvaluated",
                "catalogBehaviorCount",
                "canonicalBehaviorCount",
                "predicateTraceRows",
            ),
        ),
    }


def _authority_view(record: dict[str, Any]) -> dict[str, Any]:
    observation = record.get("observation") if isinstance(record.get("observation"), dict) else {}
    side_effects = observation.get("sideEffects") if isinstance(observation.get("sideEffects"), dict) else {}
    transport = record.get("transport") if isinstance(record.get("transport"), list) else []
    tool_calls = record.get("toolCalls") if isinstance(record.get("toolCalls"), list) else []
    relationship_before = record.get("relationshipBefore")
    relationship_after = record.get("relationshipAfter")
    relationship_changed = relationship_before != relationship_after
    return {
        "permitted": [
            _pick(call, ("name", "status", "accepted", "authority", "capabilityID", "reason"))
            for call in tool_calls
            if isinstance(call, dict)
        ],
        "attempted": bool(transport or tool_calls),
        "transportCommands": [
            _pick(event, ("direction", "command", "mode"))
            for event in transport
            if isinstance(event, dict)
        ],
        "toolCalls": [
            _pick(call, ("name", "status", "accepted", "authority", "capabilityID", "reason"))
            for call in tool_calls
            if isinstance(call, dict)
        ],
        "sideEffects": _pick(
            side_effects,
            ("none", "transportCount", "actionCount", "transportTruncated", "actionsTruncated"),
        ),
        "relationshipChanged": relationship_changed,
        "relationshipBefore": _pick(
            relationship_before,
            ("approval", "respect", "familiarity", "revision", "state"),
        ),
        "relationshipAfter": _pick(
            relationship_after,
            ("approval", "respect", "familiarity", "revision", "state"),
        ),
    }


def project_turn(record: dict[str, Any]) -> dict[str, Any]:
    result = record.get("result") if isinstance(record.get("result"), dict) else {}
    ir = result.get("ir") if isinstance(result.get("ir"), dict) else {}
    candidates = result.get("candidates") if isinstance(result.get("candidates"), dict) else {}
    decision = result.get("decision") if isinstance(result.get("decision"), dict) else {}
    response = decision.get("response") if isinstance(decision.get("response"), dict) else {}
    candidate_rows = candidates.get("candidates") if isinstance(candidates.get("candidates"), list) else []
    candidate_diagnostics = result.get("candidateDiagnostics")
    if not isinstance(candidate_diagnostics, dict):
        candidate_diagnostics = candidates.get("diagnostics") if isinstance(candidates.get("diagnostics"), dict) else {}
    flow = result.get("flow") if isinstance(result.get("flow"), dict) else {}
    decision_diagnostics = decision.get("diagnostics") if isinstance(decision.get("diagnostics"), dict) else {}
    flow_diagnostics = decision_diagnostics.get("flow") if isinstance(decision_diagnostics.get("flow"), dict) else {}
    return {
        "rawInput": record.get("input"),
        "accepted": record.get("accepted"),
        "reason": record.get("reason"),
        "normalizedInput": ir.get("normalizedText") or candidates.get("normalizedText"),
        "currentSemantic": {
            "candidates": [_candidate_view(item) for item in candidate_rows[:16]],
            "candidateDiagnostics": _pick(
                candidate_diagnostics,
                (
                    "candidateCount",
                    "eligibleCount",
                    "rejectedCount",
                    "reason",
                    "selectedConfidence",
                    "selectedPass",
                    "selectedPattern",
                    "tiedEligibleCount",
                ),
            ),
            "selected": _ir_view(ir),
        },
        "policy": {
            **_pick(decision, ("branch", "route", "intent", "speechAct", "confidence")),
            "clarification": decision.get("branch") == "ASK_CLARIFICATION",
            "reason": decision_diagnostics.get("reason"),
            "llmEligible": decision_diagnostics.get("llmEligible"),
            "flow": _pick(flow_diagnostics, ("reason", "topic", "key", "registryRevision")),
        },
        "interactionDirector": _interaction_view(record.get("observation"), decision),
        "flow": _pick(
            flow,
            ("status", "transition", "topic", "nodeId", "toNodeId", "pendingFollowUp", "matched", "generated"),
        ),
        "responseLineage": {
            "decision": _response_view(response),
            "messages": [
                _message_view(message)
                for message in (record.get("messages") or [])[:8]
            ],
        },
        "authority": _authority_view(record),
        "contextBefore": _context_view(record.get("contextBefore")),
        "contextAfter": _context_view(record.get("contextAfter")),
        "contextResolution": {
            "resolvedReferences": ir.get("diagnostics", {}).get("contextResolvedReferences", []) if isinstance(ir.get("diagnostics"), dict) else [],
            "unresolvedReferences": ir.get("diagnostics", {}).get("contextUnresolvedReferences", []) if isinstance(ir.get("diagnostics"), dict) else [],
            "flowReason": flow_diagnostics.get("reason"),
        },
    }


def capture_semantic_corpus(fixture: dict[str, Any] | None = None) -> dict[str, Any]:
    fixture = fixture or load_fixture("semantic_corpus.json")
    cases = []
    for case in fixture["cases"]:
        scenario = merge(DEFAULT_SCENARIO, case.get("scenario", {}))
        with LuaSemanticWorker(deepcopy(scenario)) as worker:
            current = project_turn(worker.input(case["rawInput"]))
        cases.append({"id": case["id"], **current})
    return {"schema": SCHEMA_VERSION, "concern": "semantic_corpus", "cases": cases}


def capture_multi_turn(fixture: dict[str, Any] | None = None) -> dict[str, Any]:
    fixture = fixture or load_fixture("multi_turn_scenarios.json")
    scenarios = []
    for case in fixture["scenarios"]:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            turns = [project_turn(worker.input(text)) for text in case["inputs"]]
        scenarios.append({"id": case["id"], "inputs": case["inputs"], "turns": turns})
    return {"schema": SCHEMA_VERSION, "concern": "multi_turn", "scenarios": scenarios}


def _source_classification(source: Any) -> str:
    kind = source.get("kind") if isinstance(source, dict) else None
    if kind in STATIC_SOURCE_KINDS:
        return "authored_or_static"
    if kind in DERIVED_SOURCE_KINDS:
        return "derived"
    return "unclassified"


def _frame_view(frame: Any) -> dict[str, Any]:
    if not isinstance(frame, dict):
        return {}
    extensions = frame.get("extensions") if isinstance(frame.get("extensions"), dict) else {}
    origin = frame.get("origin") if isinstance(frame.get("origin"), dict) else {}
    return {
        **_pick(
            frame,
            (
                "kind",
                "candidateID",
                "intent",
                "speechAct",
                "subject",
                "target",
                "topic",
                "patternID",
                "actionID",
                "stateValue",
                "stateType",
                "selfDirected",
                "textKey",
                "textFallback",
                "labelKey",
            ),
        ),
        "extensions": _pick(
            extensions,
            (
                "route",
                "providerID",
                "authority",
                "categoryID",
                "actionID",
                "origin",
                "groupID",
            ),
        ),
        "origin": _pick(origin, ("kind", "providerID", "flowID", "nodeID", "sourcePoolID", "turnID")),
    }


def _suggestion_view(candidate: Any) -> dict[str, Any]:
    if not isinstance(candidate, dict):
        return {}
    display = candidate.get("display") if isinstance(candidate.get("display"), dict) else {}
    source = candidate.get("source") if isinstance(candidate.get("source"), dict) else {}
    sources = candidate.get("sources") if isinstance(candidate.get("sources"), list) else []
    return {
        "id": candidate.get("id"),
        "providerID": candidate.get("providerID"),
        "providerOrder": candidate.get("providerOrder"),
        "rank": candidate.get("rank"),
        "groupID": candidate.get("groupID"),
        "topic": candidate.get("topic"),
        "visibility": candidate.get("visibility"),
        "source": {
            **_pick(source, ("kind", "reason", "providerID", "revision")),
            "classification": _source_classification(source),
        },
        "sourceEvidence": {
            "count": len(sources),
            "kinds": sorted({item.get("kind") for item in sources if isinstance(item, dict) and item.get("kind")}),
            "reasons": sorted({item.get("reason") for item in sources if isinstance(item, dict) and item.get("reason")}),
        },
        "display": _pick(
            display,
            (
                "label",
                "utterance",
                "labelFallback",
                "utteranceFallback",
                "labelKey",
                "utteranceKey",
            ),
        ),
        "labelUtteranceDependency": {
            "hasLabelKey": bool(display.get("labelKey")),
            "hasUtteranceKey": bool(display.get("utteranceKey")),
            "hasLabelFallback": bool(display.get("labelFallback")),
            "hasUtteranceFallback": bool(display.get("utteranceFallback")),
        },
        "ranking": _pick(
            candidate.get("ranking"),
            ("class", "classOrder", "order", "orderHint", "stableTieBreak", "schema"),
        ),
        "frame": _frame_view(candidate.get("frame") or candidate.get("semanticFrame")),
    }


def _suggestions_view(suggestions: Any) -> dict[str, Any]:
    if not isinstance(suggestions, dict):
        return {}
    rows = [
        _suggestion_view(candidate)
        for candidate in suggestions.get("candidates", [])[:32]
        if isinstance(candidate, dict)
    ]
    ids = [row.get("id") for row in rows]
    frame_values = {
        key: sorted({row["frame"].get(key) for row in rows if row.get("frame", {}).get(key) is not None})
        for key in ("intent", "speechAct", "subject", "topic")
    }
    source_kinds = sorted({row.get("source", {}).get("kind") for row in rows if row.get("source", {}).get("kind")})
    return {
        "currentTopic": suggestions.get("currentTopic"),
        "currentGroupID": suggestions.get("currentGroupID"),
        "rootGroupID": suggestions.get("rootGroupID"),
        "revision": suggestions.get("revision"),
        "turnID": suggestions.get("turnID"),
        "providers": suggestions.get("choiceRegistry", {}).get("providers", []) if isinstance(suggestions.get("choiceRegistry"), dict) else [],
        "candidates": rows,
        "groups": [
            {
                "id": group.get("id"),
                "candidateIDs": [item.get("id") for item in group.get("candidates", []) if isinstance(item, dict)],
            }
            for group in suggestions.get("groups", [])[:16]
            if isinstance(group, dict)
        ],
        "ranking": _pick(suggestions.get("ranking"), ("candidateCount", "classOrder", "schema")),
        "deduplication": {
            "candidateCount": len(rows),
            "uniqueIDCount": len(set(ids)),
            "duplicateIDs": sorted({item for item in ids if ids.count(item) > 1 and item is not None}),
            "rankSequence": [row.get("rank") for row in rows],
        },
        "diversityObserved": {
            "providerIDs": sorted({row.get("providerID") for row in rows if row.get("providerID")}),
            "sourceKinds": source_kinds,
            "frameValues": frame_values,
            "stanceFields": sorted(
                {
                    key
                    for row in rows
                    for key in ("polarity", "stance", "valence", "sentiment")
                    if key in row.get("frame", {})
                }
            ),
        },
    }


def capture_suggestions(fixture: dict[str, Any] | None = None) -> dict[str, Any]:
    fixture = fixture or load_fixture("suggestion_cases.json")
    cases = []
    for case in fixture["cases"]:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            reply = worker.input(case["rawInput"])
            suggestions = _suggestions_view(reply.get("observation", {}).get("suggestions"))
            click = None
            click_id = case.get("clickCandidateID")
            if click_id:
                candidate = next(
                    item
                    for item in reply["observation"]["suggestions"]["candidates"]
                    if item.get("id") == click_id
                )
                clicked = worker.suggestion_click(candidate["frame"])
                clicked_turn = project_turn(clicked)
                click = {
                    "candidateID": click_id,
                    "typedFrameKind": candidate.get("frame", {}).get("kind"),
                    "accepted": clicked.get("accepted"),
                    "input": clicked.get("input"),
                    "reenteredPattern": (
                        clicked.get("result", {}).get("ir", {}).get("provenance", {}).get("pattern")
                        if isinstance(clicked.get("result"), dict)
                        else None
                    ),
                    "turnEvidence": {
                        "normalizedInput": clicked_turn.get("normalizedInput"),
                        "selected": _pick(clicked_turn.get("currentSemantic", {}).get("selected"), ("intent", "speechAct", "subject", "confidence", "provenance")),
                        "policy": clicked_turn.get("policy"),
                        "responseTemplate": clicked_turn.get("responseLineage", {}).get("decision", {}).get("templateID"),
                        "authority": clicked_turn.get("authority"),
                    },
                }
        cases.append({"id": case["id"], "rawInput": case["rawInput"], "suggestions": suggestions, "click": click})
    return {"schema": SCHEMA_VERSION, "concern": "dynamic_suggestions", "cases": cases}


def capture_reply_realization(fixture: dict[str, Any] | None = None) -> dict[str, Any]:
    fixture = fixture or load_fixture("reply_realization_cases.json")
    cases = []
    for case in fixture["cases"]:
        scenario = merge(DEFAULT_SCENARIO, case.get("scenario", {}))
        with LuaSemanticWorker(deepcopy(scenario)) as worker:
            turn = project_turn(worker.input(case["rawInput"]))
        messages = turn["responseLineage"]["messages"]
        response = turn["responseLineage"]["decision"]
        segment_count = sum(
            len(item.get("segments", []))
            for item in (response.get("plan", {}).get("turns", []) if response.get("plan") else [])
        )
        cases.append({
            "id": case["id"],
            "rawInput": case["rawInput"],
            "current": {
                "selectedIntent": turn["currentSemantic"]["selected"].get("intent"),
                "selectedSpeechAct": turn["currentSemantic"]["selected"].get("speechAct"),
                "response": response,
                "evidence": {
                    "messageCount": len(messages),
                    "planTurnCount": len(response.get("plan", {}).get("turns", []) if response.get("plan") else []),
                    "planSegmentCount": segment_count,
                    "messagePhraseFamilies": [item.get("phraseFamilyID") for item in messages],
                    "messagePhraseIDs": [item.get("phraseID") for item in messages],
                    "messageRealization": [item.get("realization") for item in messages],
                    "messageTexts": [item.get("text") for item in messages],
                },
            },
        })
    return {"schema": SCHEMA_VERSION, "concern": "reply_realization", "cases": cases}


def _source_records(document: dict[str, Any], source_path: str) -> list[dict[str, Any]]:
    records = []
    for key, values in document.items():
        if key in {"schema", "kind", "domain", "source", "version", "playerChoices"}:
            continue
        if not isinstance(values, list):
            continue
        for index, item in enumerate(values):
            if not isinstance(item, dict):
                continue
            record_id = item.get("id") or item.get("semanticTemplateID") or item.get("hubID")
            if not record_id:
                continue
            records.append({
                "id": record_id,
                "sourceShard": source_path,
                "field": key,
                "index": index,
                "bytes": len(json.dumps(item, ensure_ascii=False, sort_keys=True).encode("utf-8")),
            })
    return records


def capture_storage(repository: Path = REPOSITORY) -> dict[str, Any]:
    model = compile_conversation_sources(repository)
    _, reports = render_conversation_runtime_plan(model)
    runtime_root = repository / CONVERSATION_RUNTIME_RELATIVE
    generated = []
    for report in reports:
        path = runtime_root.parents[3] / Path(*report["module"].split("/"))
        if path.suffix != ".lua":
            path = path.with_suffix(".lua")
        generated.append({
            **report,
            "path": str(path.relative_to(repository)),
            "actualBytes": path.stat().st_size if path.is_file() else None,
            "exists": path.is_file(),
        })

    source_records = []
    for source_path, document in model["_source_documents"].items():
        source_records.extend(_source_records(document, source_path))

    id_to_generated: dict[str, list[str]] = {key: [] for key in model["locations"]}
    id_to_definition: dict[str, list[str]] = {key: [] for key in model["locations"]}
    expected_report_kind = {
        "content": "Content",
        "contentChoices": "ContentChoices",
        "patterns": "Patterns",
        "pattern": "Patterns",
        "responses": "Responses",
        "responsePool": "Responses",
        "flows": "Flows",
        "flow": "Flows",
        "flowDefinition": "Flows",
        "behaviors": "Behaviors",
        "behavior": "Behaviors",
        "beats": "Beats",
        "beat": "Beats",
        "ui": "UI",
    }
    for path in sorted(runtime_root.rglob("*.lua")):
        text = path.read_text(encoding="utf-8")
        quoted = set(re.findall(r'"([^"\\]+)"', text))
        for record_id in id_to_generated:
            if record_id in quoted:
                id_to_generated[record_id].append(str(path.relative_to(repository)))
    for item in generated:
        path = repository / item["path"]
        text = path.read_text(encoding="utf-8") if path.is_file() else ""
        quoted = set(re.findall(r'"([^"\\]+)"', text))
        for record_id, location in model["locations"].items():
            expected_kind = expected_report_kind.get(location.get("kind"))
            kind_match = item["kind"] == expected_kind
            if location.get("kind") == "content" and item["kind"] == "ContentChoices":
                kind_match = True
            if record_id in quoted and kind_match:
                id_to_definition[record_id].append(item["path"])

    def module_name(path: str) -> str:
        return path[:-4].replace("/", "/") if path.endswith(".lua") else path

    overflow = [
        item for item in generated
        if re.search(r"Part\d+$", Path(item["module"]).name)
    ]
    opaque = [
        item for item in generated
        if Path(item["module"]).stem in {"Massive", "Sgd"}
    ]
    explicit_names = {"Massive", "Sgd"}
    explicit_prefixes = ("SocialPart", "CommandPart", "QuestionPart")
    explicit_cases = [
        item for item in generated
        if Path(item["module"]).stem in explicit_names
        or any(Path(item["module"]).stem.startswith(prefix) for prefix in explicit_prefixes)
    ]

    manifest_path = repository / CONVERSATION_MANIFEST_RELATIVE
    runtime_manifest = runtime_root / "Manifest.lua"
    registry = runtime_root / "Registry.lua"
    static_suggestions = runtime_root / "UI/StaticSuggestions.lua"
    source_missing = [
        key for key, location in model["locations"].items()
        if not (repository / CONVERSATION_SOURCE_RELATIVE / location["sourceShard"]).is_file()
    ]
    generated_missing = sorted(key for key, paths in id_to_generated.items() if not paths)
    generated_aliases = {
        key: id_to_generated.get(key + ".flow", [])
        for key in generated_missing
        if model["locations"].get(key, {}).get("kind") == "flowDefinition"
        and id_to_generated.get(key + ".flow")
    }
    unresolved_generated_missing = [
        key for key in generated_missing if key not in generated_aliases
    ]
    generated_reference_collisions = {
        key: paths for key, paths in id_to_generated.items() if len(paths) > 1
    }
    generated_definition_missing = sorted(
        key for key, paths in id_to_definition.items() if not paths
    )
    generated_definition_collisions = {
        key: paths for key, paths in id_to_definition.items() if len(paths) > 1
    }
    planned_modules = {item["module"] for item in reports}
    actual_modules = {
        str(path.relative_to(runtime_root))[:-4]
        for path in runtime_root.rglob("*.lua")
        if path.name not in {"Manifest.lua", "Registry.lua"}
        and path.name != "StaticSuggestions.lua"
    }
    actual_modules = {
        "PNC/Semantics/Generated/Conversation/" + item for item in actual_modules
    }
    registry_text = registry.read_text(encoding="utf-8") if registry.is_file() else ""
    required_modules = re.findall(r'require "([^"]+)"', registry_text)
    reference_failures = [
        module for module in required_modules
        if not (repository / "Contents/mods/ProjectHoomans/common/media/lua/shared" / (module + ".lua")).is_file()
    ]

    samples = {}
    for record_id in (
        "semantic.flow.greeting.opening.default",
        "phrase.semantic.social.acknowledged",
        "semantic.interaction.argument.retaliate",
        "behavior.retaliate_verbally",
        "beat.argument_escalation",
    ):
        if record_id in model["locations"]:
            samples[record_id] = {
                "source": model["locations"][record_id],
                "generated": id_to_generated.get(record_id, []),
                "generatedDefinitions": id_to_definition.get(record_id, []),
            }

    return {
        "schema": SCHEMA_VERSION,
        "concern": "storage_topology",
        "source": {
            "manifest": str(manifest_path.relative_to(repository)),
            "manifestBytes": manifest_path.stat().st_size,
            "sourceRoot": str((repository / CONVERSATION_SOURCE_RELATIVE).relative_to(repository)),
            "sourceFileCount": len(model["_source_documents"]),
            "locationCount": len(model["locations"]),
            "largestCanonicalRecords": sorted(source_records, key=lambda item: (-item["bytes"], item["sourceShard"], item["id"]))[:20],
        },
        "generated": {
            "runtimeRoot": str(runtime_root.relative_to(repository)),
            "shardCount": len(generated),
            "largestShards": sorted(generated, key=lambda item: (-item["bytes"], item["module"]))[:12],
            "numericOverflowShards": overflow,
            "opaqueNamedShards": opaque,
            "explicitCases": explicit_cases,
            "indexSizes": {
                "Manifest.lua": runtime_manifest.stat().st_size,
                "Registry.lua": registry.stat().st_size,
                "UI/StaticSuggestions.lua": static_suggestions.stat().st_size,
            },
        },
        "discoverability": {
            "idCount": len(model["locations"]),
            "sourceMissing": source_missing,
            "generatedMissing": generated_missing,
            "generatedAliasResolved": generated_aliases,
            "unresolvedGeneratedMissing": unresolved_generated_missing,
            "generatedDefinitionMissing": generated_definition_missing,
            "generatedReferenceCollisions": generated_reference_collisions,
            "generatedDefinitionCollisions": generated_definition_collisions,
            "referenceFailures": reference_failures,
            "registryRequireCount": len(required_modules),
            "registryRequireMissing": reference_failures,
            "plannedModuleCount": len(planned_modules),
            "unplannedRuntimeModules": sorted(actual_modules - planned_modules),
            "samples": samples,
        },
    }


def capture(kind: str) -> dict[str, Any]:
    if kind == "semantic":
        return capture_semantic_corpus()
    if kind == "multi_turn":
        return capture_multi_turn()
    if kind == "suggestions":
        return capture_suggestions()
    if kind == "reply_realization":
        return capture_reply_realization()
    if kind == "storage":
        return capture_storage()
    raise ValueError(f"unknown C0A capture kind: {kind}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("kind", choices=("semantic", "multi_turn", "suggestions", "reply_realization", "storage"))
    options = parser.parse_args()
    print(json.dumps(capture(options.kind), ensure_ascii=False, sort_keys=True, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
