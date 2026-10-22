"""P2 canonical actor-context contracts through the production Lua worker."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class ContextualActorContextP2Tests(unittest.TestCase):
    def _turn(self, scenario: dict) -> dict:
        with LuaSemanticWorker(deepcopy(scenario)) as worker:
            return worker.input("hello")

    def test_context_projects_existing_identity_traits_personality_relationship_roles_and_situation(
        self,
    ) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"].update(
            {
                "identityState": "known",
                "identity": {"isFemale": True, "identitySource": "registry"},
                "traits": ["reserved", "friendly"],
                "npcTraitFingerprint": "friendly|reserved",
                "personality": {
                    "socialStyle": "withdrawn",
                    "compassion": 0.8,
                    "sociability": 0.2,
                    "orientation": "private-value",
                    "romanceStyle": "private-value",
                    "jealousyStyle": "private-value",
                },
                "role": "trader",
                "healthState": "wounded",
                "activeBehavior": "searching",
                "hostility": {"attackPlayers": False},
                "relationship": {
                    "approval": 42,
                    "respect": 17,
                    "familiarity": 61,
                    "revision": 9,
                    "relationshipState": "friend",
                    "identityTrust": "trusted",
                },
            }
        )

        turn = self._turn(scenario)
        context = turn["contextAfter"]["actorConversationContext"]

        self.assertEqual(context["schema"], "actor.conversation.context.v1")
        self.assertEqual(context["actorID"], "npc_mara")
        self.assertEqual(context["identity"]["state"], "known")
        self.assertTrue(context["identity"]["isFemale"])
        self.assertEqual(context["traits"], ["friendly", "reserved"])
        self.assertEqual(context["personality"]["socialStyle"], "withdrawn")
        self.assertEqual(context["personality"]["compassion"], 0.8)
        self.assertNotIn("orientation", context["personality"])
        self.assertNotIn("romanceStyle", context["personality"])
        self.assertNotIn("jealousyStyle", context["personality"])
        self.assertEqual(context["relationship"]["approval"], 42)
        self.assertEqual(context["relationship"]["state"], "friend")
        self.assertTrue(context["roles"]["trader"])
        self.assertTrue(context["roles"]["companion"])
        self.assertEqual(context["situation"]["healthState"], "wounded")
        self.assertEqual(context["situation"]["activeBehavior"], "searching")
        self.assertTrue(context["privacy"]["undiscoveredFactsExcluded"])
        self.assertEqual(
            context["provenance"]["relationship"], "directed_relationship"
        )

        public = turn["observation"]["suggestions"]["actorConversationContext"]
        self.assertNotIn("gender", public["identity"])
        self.assertNotIn("traits", public)
        self.assertNotIn("personality", public)
        self.assertNotIn("relationship", public)

    def test_context_changes_are_transient_and_do_not_change_semantic_authority(self) -> None:
        baseline = self._turn(deepcopy(DEFAULT_SCENARIO))
        changed_scenario = deepcopy(DEFAULT_SCENARIO)
        changed_scenario["npc"].update(
            {
                "personality": {"socialStyle": "friendly", "compassion": 0.9},
                "relationship": {
                    "approval": 90,
                    "respect": 80,
                    "familiarity": 90,
                    "revision": 4,
                    "relationshipState": "friend",
                },
                "healthState": "critical",
                "activeBehavior": "fleeing",
            }
        )
        changed = self._turn(changed_scenario)

        baseline_context = baseline["contextAfter"]["actorConversationContext"]
        changed_context = changed["contextAfter"]["actorConversationContext"]
        self.assertNotEqual(
            baseline_context["relationship"], changed_context["relationship"]
        )
        self.assertNotEqual(
            baseline_context["situation"], changed_context["situation"]
        )
        self.assertNotEqual(
            baseline_context["personality"], changed_context["personality"]
        )
        self.assertEqual(
            [row["id"] for row in baseline["observation"]["suggestions"]["candidates"]],
            [row["id"] for row in changed["observation"]["suggestions"]["candidates"]],
        )

    def test_projection_does_not_persist_persona_or_choice_state(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        with LuaSemanticWorker(scenario) as worker:
            worker.input("hello")
            snapshot = worker.snapshot()

        self.assertNotIn("actorConversationContext", snapshot.get("scenario", {}))
        self.assertNotIn("choiceRegistry", snapshot.get("scenario", {}))
        self.assertNotIn("speechStyle", snapshot.get("scenario", {}))


if __name__ == "__main__":
    unittest.main()
