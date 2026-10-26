"""P2 production-worker coverage for NPC event follow-up authority."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class UnifiedAuthorityP2EventFollowUpTests(unittest.TestCase):
    @staticmethod
    def _event_payload(*, with_facts: bool = True) -> dict:
        payload = {
            "eventType": "zombie_horde_detected",
            "eventRef": "world:horde:worker-test",
            "npcID": "npc_mara",
            "factRefs": [
                "world:horde:worker-test",
                "world:horde:worker-test:location",
            ] if with_facts else [],
            "context": {
                "eventType": "zombie_horde_detected",
                "location": "the north road",
                "countBand": "many",
            },
        }
        if with_facts:
            payload["semanticEventFacts"] = {
                "world:horde:worker-test": {
                    "eventRef": "world:horde:worker-test",
                    "authoritative": True,
                    "disclosure": "player",
                    "location": "the north road",
                    "countBand": "many",
                    "summary": "A horde is moving along the north road.",
                }
            }
        return payload

    @staticmethod
    def _event_rows(suggestions: dict) -> dict[str, dict]:
        return {
            row["id"]: row
            for row in suggestions.get("candidates", [])
            if isinstance(row, dict)
            and str(row.get("id", "")).startswith("semantic.followup.event.")
        }

    @staticmethod
    def _response_identity(response: dict) -> dict:
        return {
            "templateID": response.get("templateID"),
            "fallback": response.get("fallback"),
            "args": response.get("args"),
            "selectionSource": response.get("selectionSource"),
            "referenceResolution": response.get("referenceResolution"),
            "eventRef": response.get("eventRef"),
            "groundedFactRefs": response.get("groundedFactRefs"),
            "uncertainty": response.get("uncertainty"),
        }

    def test_real_worker_event_window_projects_catalog_offers(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            event = worker.interaction_npc_event(self._event_payload())

            self.assertTrue(event["ok"])
            result = event["result"]
            realization = result["realization"]
            self.assertEqual(
                realization["selectionSource"],
                "semantic_response_catalog",
            )
            self.assertEqual(
                realization["responsePlanID"], "semantic.combat.reaction"
            )
            self.assertEqual(
                realization["realizationID"],
                "semantic.combat.reaction.threat",
            )
            self.assertEqual(
                result["responseWindow"]["activeBeat"]["eventRef"],
                "world:horde:worker-test",
            )
            self.assertEqual(
                result["responseWindow"]["activeBeat"]["realizationID"],
                realization["realizationID"],
            )

            rows = self._event_rows(result["suggestions"])
            self.assertEqual(
                set(rows),
                {
                    "semantic.followup.event.location",
                    "semantic.followup.event.quantity",
                    "semantic.followup.event.happened",
                },
            )
            location = rows["semantic.followup.event.location"]
            self.assertEqual(
                location["source"]["kind"], "npc_event_response_plan"
            )
            self.assertEqual(
                location["frame"]["eventRef"], "world:horde:worker-test"
            )

            clicked = worker.suggestion_click(location["frame"])
            self.assertTrue(clicked["accepted"], clicked.get("reason"))
            click_response = clicked["result"]["decision"]["response"]
            self.assertEqual(
                self._response_identity(click_response)["selectionSource"],
                "event_follow_up",
            )
            self.assertEqual(click_response["args"]["content"], "the north road")
            self.assertEqual(
                clicked["result"]["decision"]["branch"], "QUESTION_RECEIVED"
            )

        # Typed input is a separate worker session, proving the offer is an
        # affordance only and not a prerequisite for the same semantic route.
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.interaction_npc_event(self._event_payload())
            typed = worker.input("Where are they?")
            self.assertTrue(typed["accepted"], typed.get("reason"))
            typed_response = typed["result"]["decision"]["response"]
            self.assertEqual(
                self._response_identity(typed_response),
                self._response_identity(click_response),
            )
            self.assertEqual(
                typed["result"]["ir"]["provenance"]["pattern"],
                "pnc.question.context_reference.event_location",
            )

    def test_no_fact_refs_hide_followups_and_expire_the_window(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            event = worker.interaction_npc_event(
                self._event_payload(with_facts=False)
            )
            self.assertEqual(
                self._event_rows(event["result"]["suggestions"]), {}
            )
            unknown = worker.input("Where are they?")
            response = unknown["result"]["decision"]["response"]
            self.assertNotEqual(response.get("selectionSource"), "event_follow_up")
            self.assertEqual(response.get("uncertainty"), "unknown")

            worker.interaction_advance_time(200.0)
            self.assertEqual(
                worker.interaction_response_window()["result"]["status"],
                "EMPTY",
            )


if __name__ == "__main__":
    unittest.main()
