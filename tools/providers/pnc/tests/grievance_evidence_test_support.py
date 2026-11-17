"""Shared grievance-evidence worker and serialization helpers for PNC tests."""

from __future__ import annotations

from copy import deepcopy
import json

from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO
from tools.providers.pnc.runtime.worker import LuaSemanticWorker


def saved_worker(raw=None):
    worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
    fixture = worker._request("TEST_PRODUCTION_INVENTORY_FIXTURE", {"mode": "SEED_ONLY"})
    if raw is not None:
        fixture["record"] = raw
    scenario = deepcopy(DEFAULT_SCENARIO)
    if raw is not None:
        scenario["conversation"]["id"] = "evidence-replay:" + str(raw.get("recordRevision", 1))
    scenario["npc"]["id"] = scenario["npc"]["npcID"] = fixture["record"]["id"]
    worker.import_source(
        scenario,
        source="SAVE",
        mode="offline_save",
        source_id="fixture:unified-evidence-e0",
        provider_payloads={
            "ProjectHoomans": {"rawRecords": {"npc": fixture["record"]}}
        },
    )
    return worker


def storage(worker, **payload):
    return worker._request("TEST_EVIDENCE_STORAGE", payload)


def byte_size(value):
    return len(json.dumps(value, sort_keys=True, separators=(",", ":")).encode())


def turn(worker, text):
    result = worker.input(text)
    observation = result["observation"]
    return {
        "intent": observation["ir"]["intent"],
        "confidence": observation["ir"]["confidence"],
        "response": observation["response"].get("text"),
        "pragmatic": (result["result"].get("decision") or {}).get("pragmatic"),
        "director": (observation.get("interactionPlan") or {}).get("behaviorID"),
        "action": observation.get("actionResult"),
        "sessionShape": {
            key: (len(value) if isinstance(value, (dict, list)) else value)
            for key, value in (
                (result["contextAfter"].get("dialogue") or {})
                .get("pragmaticSession") or {}
            ).items()
        },
    }


def admission(result):
    return result["observation"]["director"]["pragmatic"]["contextualAdmission"]
