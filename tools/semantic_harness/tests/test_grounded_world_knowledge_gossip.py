"""Production-worker acceptance for bounded grounded World Knowledge gossip."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.worker import LuaSemanticWorker


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


class GroundedWorldKnowledgeGossipTests(unittest.TestCase):
    def test_alice_bob_unknown_then_event_driven_told_provenance(self) -> None:
        with LuaSemanticWorker(
            scenario_for(
                "alice",
                "EN",
                [
                    {
                        "actorID": "actor:alice",
                        "factIndex": 1,
                        "provenance": "witnessed",
                        "confidence": 0.95,
                        "source": "scenario_authority",
                        "acquisitionPath": "scenario_authority",
                    }
                ],
            )
        ) as alice:
            response = alice.input("any gossip?")
            self.assertIn("I saw", response["messages"][0]["payload"]["text"])
            world_packet = next(
                event["payload"]
                for event in response["transport"]
                if event.get("command") == "SemanticCognition"
            )
            fact_id = world_packet["wk"]["factRefs"][0]
            self.assertEqual(world_packet["wk"]["scenarioOwned"], True)
            self.assertEqual(
                alice.world_knowledge_inspect("actor:alice", fact_id)[
                    "explanation"
                ]["provenance"],
                "witnessed",
            )
            self.assertEqual(
                alice.world_knowledge_inspect("actor:bob")["finalRealization"][
                    "statements"
                ],
                [],
            )
            transfer = alice.world_knowledge_propagate(
                "actor:alice", "actor:bob", channel="conversation"
            )
            self.assertEqual(transfer["transferred"][0]["factID"], fact_id)
            after = alice.world_knowledge_inspect("actor:bob", fact_id)
            self.assertEqual(
                after["explanation"]["provenance"],
                "told",
            )
            self.assertEqual(
                after["finalRealization"]["statements"],
                ["I heard there is heavy zombie pressure nearby."],
            )

        with LuaSemanticWorker(scenario_for("bob", "EN", [])) as bob:
            response = bob.input("any gossip?")
            self.assertEqual(
                response["result"]["decision"]["response"]["selectionID"],
                "semantic.gossip.unknown",
            )
            self.assertIn("haven't heard", response["messages"][0]["payload"]["text"])

    def test_observed_world_gossip_is_localized_in_tl(self) -> None:
        with LuaSemanticWorker(
            scenario_for(
                "alice",
                "TL",
                [
                    {
                        "actorID": "actor:alice",
                        "factIndex": 1,
                        "provenance": "witnessed",
                    }
                ],
            )
        ) as worker:
            response = worker.input("any gossip?")
            self.assertEqual(
                response["messages"][0]["payload"]["text"],
                "Nakakita ako ng malaking grupo ng mga zombie.",
            )


if __name__ == "__main__":
    unittest.main()
