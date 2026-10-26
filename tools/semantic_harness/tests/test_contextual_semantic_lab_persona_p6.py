"""P6 contracts for the production-backed Semantic Lab persona surface."""

from __future__ import annotations

from copy import deepcopy
import json
import unittest

from tools.semantic_harness.inspection.conversation_inspector import build_conversation_inspector
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.ui.dialogs.settings import collect_scenario_settings


class ContextualSemanticLabPersonaP6Tests(unittest.TestCase):
    def test_catalog_reads_registered_traits_and_social_profile_dimensions(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            catalog = worker.persona_catalog()

        self.assertEqual(catalog["schema"], "semantic.persona.catalog.v1")
        trait_ids = {row["id"] for row in catalog["traits"]}
        self.assertGreaterEqual(len(trait_ids), 10)
        self.assertIn("pnc_friendly", trait_ids)
        self.assertIn("pnc_reserved", trait_ids)
        self.assertEqual(
            set(catalog["personality"]["dimensions"]),
            {
                "compassion",
                "sociability",
                "forgiveness",
                "bravery",
                "materialism",
                "aggression",
                "loyalty",
            },
        )
        self.assertEqual(
            set(catalog["personality"]["enums"]["socialStyle"]),
            {"neutral", "friendly", "withdrawn"},
        )

    def test_matrix_changes_production_style_and_restores_original_scenario(self) -> None:
        baseline = deepcopy(DEFAULT_SCENARIO)
        warm = deepcopy(baseline)
        warm["runtime"]["semanticLabMatrixLabel"] = "warm / familiar"
        warm["npc"]["traits"] = ["pnc_friendly"]
        warm["npc"]["personality"] = {
            "socialStyle": "friendly",
            "compassion": 0.9,
            "sociability": 0.9,
        }
        warm["npc"]["relationship"] = {
            "approval": 80,
            "respect": 70,
            "familiarity": 80,
            "identityTrust": "trusted",
        }
        guarded = deepcopy(baseline)
        guarded["runtime"]["semanticLabMatrixLabel"] = "guarded / hostile"
        guarded["npc"]["traits"] = ["pnc_reserved"]
        guarded["npc"]["personality"] = {
            "socialStyle": "withdrawn",
            "aggression": 0.9,
            "sociability": 0.2,
        }
        guarded["npc"]["relationship"] = {
            "approval": -80,
            "respect": -60,
            "familiarity": 5,
            "identityTrust": "untrustworthy",
        }
        guarded["npc"]["activeBehavior"] = "hostile"

        with LuaSemanticWorker(baseline) as worker:
            original = deepcopy(worker.scenario)
            matrix = worker.context_matrix(
                [baseline, warm, guarded], text="hello", maximum=3
            )
            restored = deepcopy(worker.scenario)

        self.assertEqual(matrix["schema"], "semantic.persona.matrix.v1")
        self.assertEqual(len(matrix["rows"]), 3)
        variants = [
            row["context"]["speechStyleContext"]["variant"]
            for row in matrix["rows"]
        ]
        self.assertEqual(variants, ["neutral", "warm", "guarded"])
        self.assertNotEqual(
            matrix["rows"][1]["context"]["speechStyleContext"]["dimensions"],
            matrix["rows"][2]["context"]["speechStyleContext"]["dimensions"],
        )
        self.assertEqual(restored, original)
        for row in matrix["rows"]:
            self.assertTrue(row["suggestions"]["candidates"])
            actor = row["context"]["actorConversationContext"]
            personality = actor["personality"]
            self.assertNotIn("orientation", personality)
            self.assertNotIn("romanceStyle", personality)
            self.assertNotIn("jealousyStyle", personality)

    def test_inspector_exposes_choice_realization_and_replay_trace(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            record = worker.input("hello")

        view = build_conversation_inspector(record)
        persona = view["personaChoices"]
        self.assertIn("actorConversationContext", persona)
        self.assertIn("speechStyleContext", persona)
        self.assertIn("choiceRegistry", persona)
        self.assertIn("ranking", persona)
        self.assertIn("privacy", persona)
        self.assertIn("realizationVariant", persona)
        self.assertIn("realizationFamily", persona)
        self.assertIn("receipt", persona)
        candidate = persona["candidates"][0]
        for key in (
            "providerID",
            "source",
            "eligibility",
            "ranking",
            "labelKey",
            "label",
            "utteranceKey",
            "utterance",
            "frame",
        ):
            self.assertIn(key, candidate)
        self.assertIn("replaySafe", persona["receipt"])

    def test_settings_collector_writes_lab_controls_into_existing_scenario(self) -> None:
        values = {
            "runtime.mode": "singleplayer",
            "runtime.language": "TL",
            "runtime.llmEnabled": True,
            "runtime.providerAvailable": False,
            "world.hunger": "0.3",
            "world.thirst": "0.5",
            "world.fatigue": "0.2",
            "world.stress": "0.1",
            "world.boredom": "0",
            "world.panic": "0",
            "world.timeOfDay": "14.5",
            "world.worldAgeHours": "50.5",
            "world.zombieKills": "4",
            "world.weather": "clear",
            "player.characterUUID": "char_patrick",
            "player.forename": "Patrick",
            "player.surname": "Patz",
            "player.displayName": "Patrick Patz",
            "player.inventory": json.dumps(DEFAULT_SCENARIO["player"]["inventory"]),
            "npc.npcID": "npc_mara",
            "npc.forename": "Mara",
            "npc.surname": "Vale",
            "npc.identityState": "unknown",
            "npc.relationshipState": "Member",
            "npc.gender": "female",
            "npc.role": "trader",
            "npc.health.state": "normal",
            "npc.health.current": 95,
            "npc.health.max": 100,
            "npc.health.body.overallPercent": 95,
            "npc.activeBehavior": "idle",
            "persona.traits": ["pnc_friendly"],
            "persona.socialStyle": "friendly",
            "persona.personality.compassion": 0.9,
            "persona.personality.sociability": 0.8,
            "relationship.approval": 80,
            "relationship.respect": 70,
            "relationship.familiarity": 60,
            "relationship.revision": 8,
            "relationship.identityTrust": "trusted",
            "persona.authority.companion": False,
            "persona.authority.owned": False,
            "persona.authority.eligible": False,
            "runtime.DTHoomans": True,
            "npc.inventory": json.dumps(DEFAULT_SCENARIO["npc"]["inventory"]),
            "conversation.topic": "greeting",
            "conversation.token": "settings-contract-p6",
            "runtime.commandResponses": json.dumps(
                DEFAULT_SCENARIO["runtime"]["commandResponses"]
            ),
            "runtime.nativeTranslations": "{}",
        }
        updated = collect_scenario_settings(deepcopy(DEFAULT_SCENARIO), values)
        self.assertEqual(updated["npc"]["identity"]["gender"], "female")
        self.assertEqual(updated["npc"]["role"], "trader")
        self.assertEqual(updated["npc"]["traits"], ["pnc_friendly"])
        self.assertEqual(updated["npc"]["personality"]["socialStyle"], "friendly")
        self.assertEqual(updated["npc"]["personality"]["compassion"], 0.9)
        self.assertEqual(updated["npc"]["actorAuthority"]["eligible"], False)
        self.assertEqual(updated["runtime"]["availableMods"]["DTHoomans"], True)


if __name__ == "__main__":
    unittest.main()
