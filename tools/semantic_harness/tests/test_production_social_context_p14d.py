"""P14D canonical social-layer and hostile speech parity coverage."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.inspection.conversation_inspector import (
    build_conversation_inspector,
)
from tools.semantic_harness.inspection.rendering import conversation_first
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
import tools.semantic_harness.tests.test_production_faction_rehydration_p14c as p14c_fixture


class ProductionSocialContextP14DTests(unittest.TestCase):
    def setUp(self) -> None:
        # Reuse the bounded P14C raw-save fixture without inheriting its tests.
        p14c_fixture.ProductionFactionRehydrationP14CTests.setUp(self)

    def test_saved_layers_share_production_context_and_hostile_talk(self) -> None:
        source_before = deepcopy(self.save_path.read_bytes())
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            imported = worker.import_saved_selection(
                self.save_path,
                player_uuid="char_p14c",
                npc_id="npcP14C",
            )
            source_snapshot_before = deepcopy(worker.source_snapshot.to_dict())
            imported_social = imported["context"]["socialContext"]
            turn = worker.input("hello")
            social = turn["contextAfter"]["socialContext"]

            personal = social["personalRelationship"]
            self.assertEqual(personal["state"], "unknown")
            self.assertEqual(personal["source"], "MISSING")
            self.assertEqual(
                personal["reason"],
                "no persisted NPC-to-Player relationship",
            )

            faction = social["factionRelationship"]
            self.assertEqual(faction["effective"]["state"], "war")
            self.assertEqual(faction["effective"]["standing"], -55)
            self.assertEqual(
                faction["effective"]["source"],
                "PNC.Factions.GetRelation",
            )

            tactical = social["tacticalHostility"]
            self.assertEqual(tactical["mode"], "hostile")
            self.assertTrue(tactical["attackPlayers"])
            self.assertEqual(tactical["source"], "SAVE")
            self.assertEqual(
                tactical["owner"],
                "PNC.Persistence.DeserializeRecord",
            )

            audience = social["conversationAudience"]
            self.assertEqual(audience["audience"], "hostile")
            self.assertEqual(audience["reason"], "player_hostile")
            self.assertEqual(
                audience["source"],
                "PNC.Conversation.TalkStart.Project",
            )
            self.assertEqual(audience["route"], "hostile_full_conversation")
            self.assertEqual(social["durableBond"]["status"], "absent")
            self.assertEqual(social["durableBond"]["source"], "MISSING")

            speech = social["speechStyle"]
            self.assertEqual(speech["variant"], "guarded")
            self.assertEqual(
                speech["reason"],
                "hostile_or_defensive_context",
            )
            self.assertIn("hostile_role", speech["provenance"]["roles"])

            response = turn["observation"]["response"]
            self.assertEqual(response["realizationVariant"], "guarded")
            self.assertIn("Keep your distance", response["text"])
            hostile_candidates = [
                candidate
                for row in turn["contextAfter"]["categoryDiagnostics"]
                for candidate in row.get("candidates", [])
                if isinstance(candidate, dict)
                and candidate.get("id") == "projecthoomans:hostile_parley"
            ]
            self.assertTrue(hostile_candidates)
            self.assertTrue(hostile_candidates[0].get("eligible"))

            talk = worker.talk_start("hostile", "hello")
            talk_target = talk["start"]["target"]
            self.assertEqual(talk_target["audience"], audience["audience"])
            self.assertEqual(talk_target["audienceReason"], audience["reason"])
            self.assertEqual(talk_target["route"], audience["route"])

            inspected = worker.inspect_actor_state()["scenario"]["npc"]
            self.assertEqual(
                inspected["socialContext"]["conversationAudience"]["audience"],
                "hostile",
            )

            reset = worker.reset_working_world()
            reset_social = reset["context"]["socialContext"]
            self.assertEqual(
                reset_social["conversationAudience"]["audience"],
                "hostile",
            )
            self.assertEqual(worker.source_snapshot.to_dict(), source_snapshot_before)

        self.assertEqual(self.save_path.read_bytes(), source_before)

    def test_gui_and_cli_expose_the_same_canonical_layers(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            worker.import_saved_selection(
                self.save_path,
                player_uuid="char_p14c",
                npc_id="npcP14C",
            )
            turn = worker.input("hello")

        view = build_conversation_inspector(turn)
        self.assertEqual(
            view["socialContext"]["conversationAudience"]["audience"],
            "hostile",
        )
        rendered = conversation_first(view)
        self.assertIn("SOCIAL CONTEXT", rendered)
        self.assertIn("Keep your distance", rendered)

        arguments = _parser().parse_args(
            ["--no-gui", "--inspect-social-context"]
        )
        self.assertTrue(arguments.inspect_social_context)


if __name__ == "__main__":
    unittest.main()
