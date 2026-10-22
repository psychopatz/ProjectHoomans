"""P8A bond vocabulary and production-faithful relationship contracts."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.ui.dialogs.settings import collect_scenario_settings


class ContextualBondsP8ATests(unittest.TestCase):
    def _scenario(
        self,
        kind: str,
        *,
        approval: float = 80,
        respect: float = 70,
        familiarity: float = 100,
        language: str = "EN",
    ) -> dict:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["runtime"]["language"] = language
        scenario["npc"]["startingRelationship"] = {
            "kind": kind,
            "source": "starting_companion_trait",
        }
        scenario["npc"]["relationship"].update(
            {
                "approval": approval,
                "respect": respect,
                "familiarity": familiarity,
            }
        )
        return scenario

    def _context(self, scenario: dict) -> tuple[dict, dict]:
        with LuaSemanticWorker(scenario) as worker:
            turn = worker.input("hello")
            return (
                turn["contextAfter"]["actorConversationContext"],
                worker.snapshot(),
            )

    def test_required_kinds_map_to_coarse_classes_without_losing_detail(self) -> None:
        expected = {
            "friend": "friend",
            "lover": "lover",
            "mother": "family",
            "father": "family",
            "sister": "family",
            "brother": "family",
        }
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            catalog = worker.persona_catalog()
        classes = {row["kind"]: row["class"] for row in catalog["relationshipKinds"]}
        for kind, bond_class in expected.items():
            self.assertEqual(classes[kind], bond_class)
            context, _ = self._context(self._scenario(kind))
            self.assertEqual(context["bond"]["class"], bond_class)
            if bond_class == "family":
                self.assertEqual(context["bond"]["kind"], kind)
            else:
                self.assertIsNone(context["bond"].get("kind"))
            self.assertEqual(context["bond"]["source"], "starting_companion")

    def test_bond_is_independent_of_directed_relationship_standing(self) -> None:
        friendly, _ = self._context(self._scenario("mother"))
        hostile, _ = self._context(
            self._scenario("mother", approval=-80, respect=-20)
        )

        self.assertEqual(friendly["bond"]["class"], "family")
        self.assertEqual(friendly["bond"]["kind"], "mother")
        self.assertEqual(friendly["relationship"]["state"], "friend")
        self.assertEqual(hostile["bond"]["class"], "family")
        self.assertEqual(hostile["bond"]["kind"], "mother")
        self.assertEqual(hostile["relationship"]["state"], "enemy")

    def test_relationship_state_is_derived_by_production_thresholds(self) -> None:
        cases = (
            (4, 80, 70, "unknown"),
            (100, 40, 20, "friend"),
            (100, -30, 30, "rival"),
            (100, -80, -20, "enemy"),
        )
        for familiarity, approval, respect, expected in cases:
            context, _ = self._context(
                self._scenario(
                    "friend",
                    familiarity=familiarity,
                    approval=approval,
                    respect=respect,
                )
            )
            self.assertEqual(context["relationship"]["state"], expected)

        # Hysteresis remains production-owned: an existing friend stays friend
        # above the production exit thresholds even when the enter thresholds
        # are no longer met.
        scenario = self._scenario("friend", approval=30, respect=10)
        scenario["npc"]["relationship"]["state"] = "friend"
        context, _ = self._context(scenario)
        self.assertEqual(context["relationship"]["state"], "friend")

    def test_normal_lab_settings_do_not_edit_or_persist_derived_state_or_class(self) -> None:
        values = {
            "runtime.mode": "singleplayer",
            "runtime.language": "EN",
            "runtime.llmEnabled": False,
            "runtime.providerAvailable": False,
            "world.hunger": "0.2",
            "world.thirst": "0.4",
            "world.fatigue": "0.1",
            "world.stress": "0",
            "world.boredom": "0",
            "world.panic": "0",
            "world.timeOfDay": "13.5",
            "world.worldAgeHours": "49.5",
            "world.zombieKills": "0",
            "world.weather": "clear",
            "player.characterUUID": "char_patrick",
            "player.forename": "Patrick",
            "player.surname": "Patz",
            "player.displayName": "Patrick Patz",
            "player.inventory": "{}",
            "npc.npcID": "npc_mara",
            "npc.forename": "Mara",
            "npc.surname": "Vale",
            "npc.identityState": "unknown",
            "npc.relationshipState": "enemy",
            "npc.gender": "female",
            "npc.role": "none",
            "persona.bondKind": "mother",
            "npc.healthState": "healthy",
            "npc.activeBehavior": "idle",
            "persona.traits": ["reserved"],
            "persona.socialStyle": "neutral",
            "persona.personality.compassion": 0.5,
            "persona.personality.sociability": 0.5,
            "relationship.approval": "80",
            "relationship.respect": "70",
            "relationship.familiarity": "100",
            "relationship.revision": "1",
            "relationship.identityTrust": "unknown",
            "persona.authority.companion": True,
            "persona.authority.owned": True,
            "persona.authority.eligible": True,
            "runtime.DTHoomans": False,
            "npc.inventory": "{}",
            "conversation.topic": "greeting",
            "conversation.token": "p8a-settings",
            "runtime.commandResponses": "{}",
            "runtime.nativeTranslations": "{}",
        }
        updated = collect_scenario_settings(deepcopy(DEFAULT_SCENARIO), values)
        self.assertNotIn("relationshipState", updated["npc"])
        self.assertEqual(
            updated["npc"]["startingRelationship"],
            {"kind": "mother", "source": "starting_companion_trait"},
        )
        self.assertNotIn("class", updated["npc"]["startingRelationship"])

    def test_relationship_terms_are_language_localized_without_changing_kind_or_keys(self) -> None:
        en_context, _ = self._context(self._scenario("mother", language="EN"))
        tl_context, _ = self._context(self._scenario("mother", language="TL"))
        with LuaSemanticWorker(self._scenario("mother", language="EN")) as worker:
            en_row = next(
                row for row in worker.persona_catalog()["relationshipKinds"]
                if row["kind"] == "mother"
            )
            worker.set_language("TL")
            tl_row = next(
                row for row in worker.persona_catalog()["relationshipKinds"]
                if row["kind"] == "mother"
            )

        self.assertEqual(en_context["bond"]["kind"], tl_context["bond"]["kind"])
        self.assertEqual(en_context["bond"]["class"], tl_context["bond"]["class"])
        self.assertEqual(
            en_context["bond"]["term"], tl_context["bond"]["term"]
        )
        self.assertEqual(en_row["termKeys"], tl_row["termKeys"])
        self.assertEqual(en_row["terms"]["address"], "Mom")
        self.assertEqual(tl_row["terms"]["address"], "Nanay")

    def test_future_family_subtype_uses_registry_and_family_projection(self) -> None:
        scenario = self._scenario("grandmother", language="TL")
        with LuaSemanticWorker(scenario) as worker:
            catalog = worker.persona_catalog(
                {
                    "kind": "grandmother",
                    "class": "family",
                    "termKeys": {
                        "reference": "UI_PNC_Flavor_RelationshipTerm_Grandmother_Reference",
                        "address": "UI_PNC_Flavor_RelationshipTerm_Grandmother_Address",
                    },
                }
            )
            turn = worker.input("hello")
            snapshot = worker.snapshot()
            row = next(
                row for row in catalog["relationshipKinds"]
                if row["kind"] == "grandmother"
            )
            bond = turn["contextAfter"]["actorConversationContext"]["bond"]

        self.assertTrue(catalog["relationshipKindRegistration"]["registered"])
        self.assertEqual(row["class"], "family")
        self.assertEqual(row["terms"]["address"], "Lola")
        # Explicit registration permits a diagnostic fixture to inspect a
        # future registry definition, but current runtime production only
        # seeds the truthful family kinds. The relationship then follows the
        # normal durable friendship milestone.
        self.assertEqual(bond["class"], "friend")
        self.assertIsNone(bond.get("kind"))
        persisted_npc = snapshot["scenario"]["npc"]
        self.assertEqual(
            persisted_npc["startingRelationship"],
            {"kind": "grandmother", "source": "starting_companion_trait"},
        )
        self.assertEqual(
            persisted_npc["relationship"]["bond"]["class"], "friend"
        )
        self.assertNotIn("class", persisted_npc["startingRelationship"])


if __name__ == "__main__":
    unittest.main()
