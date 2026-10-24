"""P1 production-Lua semantic interaction lifecycle coverage."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class SemanticInteractionLifecycleP1Tests(unittest.TestCase):
    def test_input_adapters_converge_in_the_production_worker(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            typed = worker.interaction_envelope(
                {
                    "source": "typed_text",
                    "ir": {"speechAct": "greeting", "topic": "camp"},
                }
            )
            button = worker.interaction_envelope(
                {
                    "source": "semantic_choice",
                    "frame": {"semantic": {"act": "GREET", "topic": "camp"}},
                }
            )
            emote = worker.interaction_envelope(
                {
                    "source": "emote",
                    "topic": "camp",
                    "emote": {"id": "wavehi"},
                }
            )
            farewell = worker.interaction_envelope(
                {
                    "source": "conversation_lifecycle",
                    "eventType": "conversation_close",
                }
            )
            farewell_emote = worker.interaction_envelope(
                {
                    "source": "emote",
                    "emote": {"id": "wavebye"},
                }
            )

        self.assertEqual(typed["envelope"]["source"], "typed_text")
        self.assertEqual(button["envelope"]["source"], "semantic_choice")
        self.assertEqual(emote["envelope"]["source"], "emote")
        self.assertEqual(typed["meaningKey"], button["meaningKey"])
        self.assertEqual(button["meaningKey"], emote["meaningKey"])
        self.assertEqual(farewell["envelope"]["act"], "FAREWELL")
        self.assertEqual(
            farewell["meaningKey"], farewell_emote["meaningKey"]
        )

    def test_npc_provenance_close_resume_and_200_turn_bound(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            speech = worker.interaction_npc_speech(
                {
                    "npcID": "npc_mara",
                    "act": "REQUEST",
                    "topic": "water",
                    "beatID": "beat:water",
                    "responsePlanID": "plan:water",
                    "expectedReplies": ["yes", "no"],
                }
            )
            thread = speech["result"]["thread"]
            self.assertEqual(thread["activeBeat"]["id"], "beat:water")
            self.assertNotIn("renderedText", thread)
            window = worker.interaction_response_window()
            self.assertEqual(
                window["result"]["activeBeat"]["id"], "beat:water"
            )
            self.assertNotIn("rawText", str(window["result"]))

            closed = worker.interaction_close({"worldHour": 51.0})
            self.assertEqual(closed["result"]["reason"], "suspended")
            resumed = worker.interaction_resume({"worldHour": 120.0})
            self.assertEqual(resumed["result"]["thread"]["status"], "ACTIVE")

            for index in range(200):
                worker.interaction_apply(
                    {
                        "source": "typed_text",
                        "ir": {"speechAct": "ACK", "topic": "water"},
                        "options": {"meaningful": True, "worldHour": 72 + index / 24},
                    }
                )
            metrics = worker.interaction_metrics()["result"]

        self.assertEqual(metrics["maxRecentTurns"], 12)
        self.assertEqual(metrics["pairRecords"], 1)
        self.assertLess(metrics["pairCapsuleBytes"], 12000)
        self.assertEqual(metrics["dormantTickWork"], 0)

    def test_trivial_interaction_does_not_materialize_pair_state(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            result = worker.interaction_apply(
                {
                    "source": "emote",
                    "emote": {"id": "wavehi"},
                }
            )
            metrics = worker.interaction_metrics()["result"]

        self.assertFalse(result["result"]["persisted"])
        self.assertEqual(metrics["pairRecords"], 0)

    def test_sparse_multiplayer_pairs_and_shared_event_references(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            for player_id in ("player-one", "player-two"):
                worker.interaction_apply(
                    {
                        "source": "world_event",
                        "playerUUID": player_id,
                        "actorID": player_id,
                        "targetID": "npc_mara",
                        "event": {
                            "id": "world:helicopter:1",
                            "type": "aircraft",
                        },
                        "options": {"meaningful": True},
                    }
                )
            first = worker.interaction_project(
                {"playerUUID": "player-one", "npcID": "npc_mara"}
            )
            second = worker.interaction_project(
                {"playerUUID": "player-two", "npcID": "npc_mara"}
            )
            metrics = worker.interaction_metrics()["result"]

        self.assertIsNotNone(first["result"]["thread"])
        self.assertIsNotNone(second["result"]["thread"])
        self.assertEqual(metrics["pairRecords"], 2)
        self.assertEqual(metrics["sharedEventRefs"], 1)

    def test_hundreds_of_npcs_and_thousands_of_trivial_turns_stay_sparse(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            for index in range(400):
                worker.interaction_apply(
                    {
                        "source": "emote",
                        "playerUUID": "player-one",
                        "actorID": "player-one",
                        "targetID": f"npc_{index}",
                        "emote": {"id": "wavehi"},
                    }
                )
            for index in range(2000):
                worker.interaction_apply(
                    {
                        "source": "emote",
                        "playerUUID": "player-one",
                        "actorID": "player-one",
                        "targetID": "npc_trivial",
                        "emote": {"id": "wavehi"},
                    }
                )
            metrics = worker.interaction_metrics()["result"]

        self.assertEqual(metrics["pairRecords"], 0)
        self.assertEqual(metrics["dormantTickWork"], 0)


if __name__ == "__main__":
    unittest.main()
