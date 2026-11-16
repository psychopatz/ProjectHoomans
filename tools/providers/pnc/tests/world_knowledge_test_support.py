"""Shared scenario helper for World Knowledge inspector/GUI/hub tests."""

from __future__ import annotations

from copy import deepcopy

from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO


def scenario_for(actor: str, language: str, acquisitions: list[dict]) -> dict:
    scenario = deepcopy(DEFAULT_SCENARIO)
    npc_id = f"npc_{actor}"
    scenario["npc"].update(
        {
            "npcID": npc_id,
            "id": npc_id,
            "coreActorID": f"actor:{actor}",
            "name": actor.title(),
            "forename": actor.title(),
            "affiliation": {"factionID": "faction:one"},
        }
    )
    scenario["runtime"]["language"] = language
    scenario["runtime"]["semanticCognitionResponses"] = {
        "GOSSIP": {"targetID": "self"}
    }
    scenario["runtime"]["worldKnowledge"] = {
        "actors": [
            {
                "id": "npc_alice",
                "coreActorID": "actor:alice",
                "name": "Alice",
                "alive": True,
            },
            {
                "id": "npc_bob",
                "coreActorID": "actor:bob",
                "name": "Bob",
                "alive": True,
            },
        ],
        "facts": [
            {
                "producer": "semantic_lab:scenario",
                "kind": "zombie.pressure",
                "eventID": "lab:zombie:episode:1",
                "subject": {"id": "actor:alice", "kind": "npc"},
                "occurredAt": 50,
                "observedAt": 50,
                "severity": 0.8,
                "retention": "historical",
                "payload": {"band": "heavy", "scenarioOwned": True},
            }
        ],
        "acquisitions": acquisitions,
    }
    return scenario
