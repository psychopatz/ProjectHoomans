"""Developer-side acceptance for the production Lua lifecycle worker."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class SemanticInteractionLifecycleAcceptanceTests(unittest.TestCase):
    def test_registered_gestures_and_grounded_events_use_one_envelope(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            gestures = (
                "wavehi",
                "wavebye",
                "thankyou",
                "thumbsup",
                "thumbsdown",
                "insult",
                "clap",
                "salute",
            )
            envelopes = [
                worker.interaction_envelope(
                    {"source": "emote", "emote": {"id": gesture}}
                )["envelope"]
                for gesture in gestures
            ]
            headless = worker.interaction_envelope(
                {
                    "source": "headless",
                    "ir": {"speechAct": "ACK", "topic": "camp"},
                }
            )["envelope"]
            lifecycle = worker.interaction_envelope(
                {
                    "source": "lifecycle",
                    "eventType": "conversation_close",
                }
            )["envelope"]
            grounded = worker.interaction_envelope(
                {
                    "source": "event",
                    "event": {
                        "id": "world:medical:1",
                        "type": "treated_wound",
                    },
                }
            )["envelope"]

        self.assertEqual(envelopes[0]["act"], "GREET")
        self.assertEqual(envelopes[1]["act"], "FAREWELL")
        self.assertTrue(all(item["source"] == "emote" for item in envelopes))
        self.assertEqual(headless["source"], "typed_text")
        self.assertEqual(lifecycle["act"], "FAREWELL")
        self.assertEqual(grounded["source"], "world_event")
        self.assertEqual(grounded["act"], "REACT")

    def test_worker_snapshot_exposes_bounded_window_and_source_boundary(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            source_before = deepcopy(worker.source_snapshot.to_dict())
            speech = worker.interaction_npc_speech(
                {
                    "npcID": "npc_mara",
                    "act": "REQUEST",
                    "topic": "water",
                    "beatID": "beat:water",
                    "responsePlanID": "plan:water",
                    "realizationID": "realization:water:1",
                    "expectedReplies": ["ACK", "REQUEST"],
                }
            )
            self.assertTrue(speech["result"]["persisted"])
            snapshot = worker.snapshot()
            lifecycle = snapshot["interactionLifecycle"]

            self.assertTrue(snapshot["sourceSnapshot"]["immutable"])
            self.assertEqual(
                lifecycle["responseWindow"]["activeBeat"]["id"],
                "beat:water",
            )
            self.assertNotIn("rawText", str(lifecycle))
            self.assertNotIn("renderedText", str(lifecycle))

            changed = deepcopy(DEFAULT_SCENARIO)
            changed["world"]["worldAgeHours"] = 88.0
            worker.configure(changed)
            worker.interaction_apply(
                {
                    "source": "typed_text",
                    "ir": {"speechAct": "QUESTION", "topic": "water"},
                    "options": {
                        "meaningful": True,
                        "openQuestion": "question:water",
                    },
                }
            )
            worker.reset_working_world()

            self.assertEqual(worker.source_snapshot.to_dict(), source_before)
            self.assertEqual(
                worker.snapshot()["sourceSnapshot"]["metadata"]["sourceKind"],
                "FIXTURE",
            )

    def test_export_import_preserves_compact_semantic_state_only(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.interaction_npc_speech(
                {
                    "npcID": "npc_mara",
                    "act": "REQUEST",
                    "topic": "shelter",
                    "beatID": "beat:shelter",
                    "responsePlanID": "plan:shelter",
                    "realizationID": "variant:shelter:1",
                }
            )
            exported = worker.interaction_export()["result"]
            self.assertNotIn("transcript", str(exported))
            self.assertNotIn("rawText", str(exported))
            self.assertNotIn("renderedText", str(exported))

            worker.interaction_close({"worldHour": 51.0})
            imported = worker.interaction_import(exported)
            window = worker.interaction_response_window()["result"]

            self.assertTrue(imported["result"]["accepted"])
            self.assertEqual(window["activeBeat"]["id"], "beat:shelter")
            self.assertEqual(window["status"], "ACTIVE")

    def test_compaction_removes_resolved_trivial_pair_capsule(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.interaction_npc_speech(
                {
                    "npcID": "npc_mara",
                    "act": "ACK",
                    "topic": "camp",
                    "beatID": "beat:trivial",
                }
            )
            compacted = worker.interaction_compact(
                {
                    "options": {
                        "resolveBeat": True,
                        "clearTrivial": True,
                    }
                }
            )
            metrics = worker.interaction_metrics()["result"]

        self.assertEqual(compacted["result"]["reason"], "empty_after_compaction")
        self.assertEqual(metrics["pairRecords"], 0)

    def test_residue_and_realization_history_remain_lazy_and_bounded(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            for index in range(24):
                worker.interaction_apply(
                    {
                        "source": "typed_text",
                        "ir": {"speechAct": "ACK", "topic": "camp"},
                        "options": {
                            "meaningful": True,
                            "residue": {"kind": "short-lived", "index": index},
                            "residueTTLHours": 1,
                            "realizationID": f"variant:camp:{index}",
                            "worldHour": 10.0 + index / 24.0,
                        },
                    }
                )

            before = worker.interaction_response_window()["result"]
            self.assertLessEqual(len(before["recentRealizations"]), 8)
            self.assertEqual(len(before["recentTurns"]), 12)

            worker.interaction_advance_time(20.0)
            after = worker.interaction_project()["result"]["thread"]
            metrics = worker.interaction_metrics()["result"]

            self.assertIn(after.get("residue", {}), ({}, []))
            self.assertLessEqual(metrics["maxRecentTurns"], 12)
            self.assertEqual(metrics["dormantTickWork"], 0)


if __name__ == "__main__":
    unittest.main()
