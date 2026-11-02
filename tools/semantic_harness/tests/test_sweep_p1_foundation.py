"""P1A/P1B foundation tests for compact evidence schema and production dimension discovery."""

from __future__ import annotations

from copy import deepcopy
import json
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.testing.sweep_dimensions import (
    EXPLICIT_SCENARIO_ADAPTERS,
    InvalidDimensionValueError,
    PrerequisiteDimensionError,
    ReadOnlyDimensionError,
    SweepDimensionInventory,
    UnsupportedDimensionError,
    extract_dimension_inventory,
)
from tools.semantic_harness.testing.sweep_evidence import (
    EVIDENCE_SCHEMA_V1,
    extract_evidence_rows_from_turn,
    validate_evidence_row,
)


class SweepP1FoundationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.mock_control_catalog = {
            "controls": [
                {
                    "id": "player.hunger",
                    "path": "player.stats.hunger",
                    "label": "Hunger",
                    "valueType": "number",
                    "control": "slider",
                    "min": 0.0,
                    "max": 1.0,
                    "step": 0.05,
                    "workbenchPanel": "Player",
                },
                {
                    "id": "npc.hunger",
                    "path": "npc.stats.hunger",
                    "label": "NPC Hunger",
                    "valueType": "number",
                    "control": "slider",
                    "min": 0.0,
                    "max": 1.0,
                    "step": 0.05,
                    "workbenchPanel": "NPC Target",
                },
                {
                    "id": "player.characterUUID",
                    "path": "player.characterUUID",
                    "label": "Player UUID",
                    "valueType": "text",
                    "control": "read_only",
                    "derivedFrom": ["player.forename", "player.surname"],
                },
                {
                    "id": "npc.personalityOverride",
                    "path": "npc.personalityOverride",
                    "label": "Personality Override",
                    "valueType": "boolean",
                    "control": "boolean",
                    "workbenchPanel": "NPC Target",
                },
                {
                    "id": "persona.personality.aggression",
                    "path": "npc.personality.aggression",
                    "label": "Aggression",
                    "valueType": "number",
                    "control": "slider",
                    "min": 0.0,
                    "max": 1.0,
                    "requiresOverride": "npc.personalityOverride",
                    "workbenchPanel": "NPC Target",
                },
                {
                    "id": "persona.bondKind",
                    "path": "npc.startingRelationship",
                    "label": "Bond kind",
                    "valueType": "enum",
                    "control": "combobox",
                    "options": ["none", "friend"],
                    "noneValue": "none",
                    "clearPath": "npc.startingRelationship",
                    "workbenchPanel": "Relationship",
                },
                {
                    "id": "relationship.approval",
                    "path": "npc.standing.approval",
                    "label": "Approval",
                    "valueType": "number",
                    "control": "slider",
                    "min": -100.0,
                    "max": 100.0,
                    "workbenchPanel": "Relationship",
                },
                {
                    "id": "runtime.language",
                    "path": "runtime.language",
                    "label": "Language",
                    "valueType": "enum",
                    "control": "combobox",
                    "options": ["EN", "TL"],
                    "workbenchPanel": "World",
                },
            ]
        }
        self.mock_persona_catalog = {
            "relationshipKinds": [
                {"kind": "friend"},
                {"kind": "lover"},
                {"kind": "sister"},
                {"kind": "brother"},
            ]
        }

    def test_dimension_inventory_extraction_and_enrichment(self) -> None:
        inventory = extract_dimension_inventory(
            control_catalog=self.mock_control_catalog,
            persona_catalog=self.mock_persona_catalog,
        )
        self.assertIn("player.hunger", inventory)
        self.assertIn("npc.personalityOverride", inventory)
        self.assertIn("persona.personality.aggression", inventory)
        self.assertIn("persona.bondKind", inventory)
        self.assertIn("scenario.utterance", inventory)
        self.assertIn("scenario.rootChoice", inventory)

        bond_dim = inventory.get("persona.bondKind")
        self.assertIsNotNone(bond_dim)
        self.assertIn("lover", bond_dim.options)
        self.assertIn("none", bond_dim.options)

    def test_read_only_dimension_rejection(self) -> None:
        inventory = extract_dimension_inventory(
            control_catalog=self.mock_control_catalog,
            persona_catalog=self.mock_persona_catalog,
        )
        dim = inventory.get("player.characterUUID")
        self.assertIsNotNone(dim)
        self.assertTrue(dim.read_only)
        self.assertFalse(dim.sweepable)

        with self.assertRaises(ReadOnlyDimensionError):
            inventory.validate_parameter_vector({"player.characterUUID": "custom-uuid"})

    def test_unsupported_dimension_diagnostic(self) -> None:
        inventory = extract_dimension_inventory(
            control_catalog=self.mock_control_catalog,
            persona_catalog=self.mock_persona_catalog,
        )
        with self.assertRaises(UnsupportedDimensionError) as ctx:
            inventory.validate_parameter_vector({"unknown.parameter": 123})
        self.assertIn("Unknown sweep dimension 'unknown.parameter'", str(ctx.exception))

    def test_prerequisite_dimension_handling(self) -> None:
        inventory = extract_dimension_inventory(
            control_catalog=self.mock_control_catalog,
            persona_catalog=self.mock_persona_catalog,
        )
        # With auto_enable_prerequisites=True (default), setting aggression enables npc.personalityOverride
        norm = inventory.validate_parameter_vector({"persona.personality.aggression": 0.8})
        self.assertEqual(norm.get("persona.personality.aggression"), 0.8)
        self.assertTrue(norm.get("npc.personalityOverride"))

        # With auto_enable_prerequisites=False, error is raised
        with self.assertRaises(PrerequisiteDimensionError):
            inventory.validate_parameter_vector(
                {"persona.personality.aggression": 0.8},
                auto_enable_prerequisites=False,
            )

        # If override is explicitly False, error is raised
        with self.assertRaises(PrerequisiteDimensionError):
            inventory.validate_parameter_vector(
                {"persona.personality.aggression": 0.8, "npc.personalityOverride": False}
            )

    def test_invalid_dimension_values(self) -> None:
        inventory = extract_dimension_inventory(
            control_catalog=self.mock_control_catalog,
            persona_catalog=self.mock_persona_catalog,
        )
        # Out of bounds
        with self.assertRaises(InvalidDimensionValueError):
            inventory.validate_parameter_vector({"player.hunger": 2.5})

        # Invalid enum option
        with self.assertRaises(InvalidDimensionValueError):
            inventory.validate_parameter_vector({"runtime.language": "FR"})

    def test_project_to_scenario(self) -> None:
        inventory = extract_dimension_inventory(
            control_catalog=self.mock_control_catalog,
            persona_catalog=self.mock_persona_catalog,
        )
        sc = inventory.project_to_scenario(
            {
                "player.hunger": 0.75,
                "persona.personality.aggression": 0.9,
                "persona.bondKind": "friend",
                "runtime.language": "TL",
            }
        )
        self.assertEqual(sc["player"]["stats"]["hunger"], 0.75)
        self.assertEqual(sc["npc"]["personality"]["aggression"], 0.9)
        self.assertTrue(sc["npc"]["personalityOverride"])
        self.assertEqual(sc["npc"]["startingRelationship"]["kind"], "friend")
        self.assertEqual(sc["runtime"]["language"], "TL")

    def test_evidence_row_structure_and_boundedness(self) -> None:
        # Mock turn record
        turn_record = {
            "speaker": "player",
            "input": "how are you?",
            "accepted": True,
            "messages": [
                {
                    "speaker": "player",
                    "payload": {"text": "how are you?"},
                },
                {
                    "speaker": "npc",
                    "payload": {
                        "text": "I'm holding together. Barely.",
                        "key": "wellbeing.weary",
                        "semanticTemplateID": "wellbeing.weary",
                        "translationKey": "IGUI_PH_Wellbeing_Weary",
                        "realizationFamily": "weary",
                        "realizationVariant": "short",
                        "semanticVariantID": "v_weary_01",
                        "phraseID": "phrase_weary_01",
                    },
                },
            ],
            "observation": {
                "playerNeeds": {"hunger": 0.2, "thirst": 0.1},
                "npcNeeds": {"hunger": 0.4, "fatigue": 0.6},
                "response": {
                    "templateID": "wellbeing.weary",
                    "realizationFamily": "weary",
                    "realizationVariant": "short",
                    "translationKey": "IGUI_PH_Wellbeing_Weary",
                },
            },
        }

        rows = extract_evidence_rows_from_turn(
            turn_record,
            turn_index=0,
            case_id="case-wellbeing-01",
            sweep_id="sweep-demo",
            strategy="smoke",
            parameters={"player.hunger": 0.2},
            language="EN",
        )
        self.assertEqual(len(rows), 1)
        row = rows[0]

        validate_evidence_row(row)
        self.assertEqual(row["schema"], EVIDENCE_SCHEMA_V1)
        self.assertEqual(row["rowID"], "case-wellbeing-01:0:0")
        self.assertEqual(row["output"]["finalText"], "I'm holding together. Barely.")
        self.assertEqual(row["semanticPath"]["realizationFamily"], "weary")
        self.assertEqual(row["semanticPath"]["semanticVariantID"], "v_weary_01")
        self.assertEqual(row["selectionProvenance"]["provenance"], "EXACT_EMITTED_VARIANT_ID")
        self.assertEqual(row["selectionProvenance"]["canonicalSourceOwner"], "UNKNOWN")
        self.assertTrue(row["traceHandle"]["lazy"])

        # Check serialization boundedness
        encoded = json.dumps(row)
        self.assertLess(len(encoded.encode("utf-8")), 4096)

    def test_real_lua_worker_dimension_and_evidence_projection(self) -> None:
        """Integration with real LuaSemanticWorker."""
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            inventory = extract_dimension_inventory(worker)
            self.assertIn("player.hunger", inventory)
            self.assertIn("npc.hunger", inventory)
            self.assertIn("persona.personality.aggression", inventory)
            self.assertIn("persona.bondKind", inventory)
            self.assertIn("runtime.language", inventory)

            # Check that bond kinds were enriched from persona catalog
            bond_dim = inventory.get("persona.bondKind")
            self.assertIsNotNone(bond_dim)
            self.assertIn("sister", bond_dim.options)

            # Project modified scenario
            modified_scenario = inventory.project_to_scenario(
                {
                    "player.hunger": 0.5,
                    "npc.personalityOverride": True,
                    "persona.personality.aggression": 0.85,
                    "persona.bondKind": "sister",
                }
            )

        # Run modified scenario through real LuaSemanticWorker
        with LuaSemanticWorker(modified_scenario) as worker:
            record = worker.input("how are you?")
            rows = extract_evidence_rows_from_turn(
                record,
                turn_index=0,
                case_id="case-real-lua-01",
                sweep_id="sweep-p1",
                strategy="boundary",
                parameters={
                    "player.hunger": 0.5,
                    "persona.personality.aggression": 0.85,
                    "persona.bondKind": "sister",
                },
                language="EN",
                worker=worker,
            )
            self.assertGreaterEqual(len(rows), 1)
            row = rows[0]
            validate_evidence_row(row)
            self.assertEqual(row["identity"]["caseID"], "case-real-lua-01")
            self.assertEqual(row["trigger"]["relationshipSummary"]["bondKind"], "sister")
            self.assertIsNotNone(row["output"]["finalText"])
            self.assertTrue(row["traceHandle"]["lazy"])


if __name__ == "__main__":
    unittest.main()
