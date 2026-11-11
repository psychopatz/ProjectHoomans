"""tests for semantic bucket policies and deterministic coverage planner."""

from __future__ import annotations

import unittest

from tools.semantic_harness.testing.sweep_buckets import (
    RELATIONSHIP_BUCKETS,
    NEED_BUCKETS,
    build_bucket_inventory,
    get_bucket_policy,
)
from tools.semantic_harness.testing.sweep_dimensions import extract_dimension_inventory
from tools.semantic_harness.testing.sweep_planner import (
    CoveragePlan,
    CoveragePlanner,
    PlannedCase,
)


class SweepPlannerTests(unittest.TestCase):
    def setUp(self) -> None:
        self.mock_control_catalog = {
            "controls": [
                {
                    "id": "player.needs.hunger",
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
                    "id": "npc.needs.hunger",
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
                    "id": "persona.personality.compassion",
                    "path": "npc.personality.compassion",
                    "label": "Compassion",
                    "valueType": "number",
                    "control": "slider",
                    "min": 0.0,
                    "max": 1.0,
                    "requiresOverride": "npc.personalityOverride",
                    "workbenchPanel": "NPC Target",
                },
                {
                    "id": "persona.personality.bravery",
                    "path": "npc.personality.bravery",
                    "label": "Bravery",
                    "valueType": "number",
                    "control": "slider",
                    "min": 0.0,
                    "max": 1.0,
                    "requiresOverride": "npc.personalityOverride",
                    "workbenchPanel": "NPC Target",
                },
                {
                    "id": "persona.personality.loyalty",
                    "path": "npc.personality.loyalty",
                    "label": "Loyalty",
                    "valueType": "number",
                    "control": "slider",
                    "min": 0.0,
                    "max": 1.0,
                    "requiresOverride": "npc.personalityOverride",
                    "workbenchPanel": "NPC Target",
                },
                {
                    "id": "persona.personality.sociability",
                    "path": "npc.personality.sociability",
                    "label": "Sociability",
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
                    "id": "relationship.respect",
                    "path": "npc.standing.respect",
                    "label": "Respect",
                    "valueType": "number",
                    "control": "slider",
                    "min": -100.0,
                    "max": 100.0,
                    "workbenchPanel": "Relationship",
                },
                {
                    "id": "relationship.familiarity",
                    "path": "npc.standing.familiarity",
                    "label": "Familiarity",
                    "valueType": "number",
                    "control": "slider",
                    "min": 0.0,
                    "max": 100.0,
                    "workbenchPanel": "Relationship",
                },
                {
                    "id": "relationship.identityTrust",
                    "path": "npc.standing.identityTrust",
                    "label": "Identity Trust",
                    "valueType": "number",
                    "control": "slider",
                    "min": 0.0,
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
        self.inventory = extract_dimension_inventory(
            control_catalog=self.mock_control_catalog,
            persona_catalog=self.mock_persona_catalog,
        )
        self.planner = CoveragePlanner(self.inventory, sweep_id="test_sweep")

    def test_bucket_policies_include_production_thresholds(self) -> None:
        approval_policy = RELATIONSHIP_BUCKETS["relationship.approval"]
        self.assertIn(-60.0, approval_policy.values)
        self.assertIn(-25.0, approval_policy.values)
        self.assertIn(35.0, approval_policy.values)
        self.assertIn(85.0, approval_policy.values)
        self.assertEqual(approval_policy.provenance, "PNC_RelationshipConstants.lua")

        hunger_policy = NEED_BUCKETS["player.needs.hunger"]
        self.assertIn(0.15, hunger_policy.values)
        self.assertIn(0.25, hunger_policy.values)
        self.assertIn(0.45, hunger_policy.values)
        self.assertEqual(hunger_policy.provenance, "PNC_ColonyUIShared.lua")

    def test_smoke_strategy(self) -> None:
        plan = self.planner.plan_smoke(
            surfaces=("scenario.rootChoice:wellbeing", "scenario.utterance:hello"),
            languages=("EN", "TL"),
        )
        self.assertEqual(plan.strategy, "smoke")
        self.assertEqual(plan.total_cases, 4)
        self.assertEqual(plan.estimated_batches, 1)
        self.assertTrue(all(c.parameters == {} for c in plan.cases))
        self.assertTrue(all(c.case_id.startswith("test_sweep:smoke:") for c in plan.cases))

    def test_boundary_strategy(self) -> None:
        plan = self.planner.plan_boundary(
            surfaces=("scenario.rootChoice:wellbeing",),
            dimensions=("relationship.approval", "persona.bondKind"),
            languages=("EN",),
        )
        self.assertEqual(plan.strategy, "boundary")
        self.assertGreater(plan.total_cases, 10)
        self.assertLessEqual(plan.total_cases, 64)

        # Confirm threshold values exist in cases
        approval_vals = [
            c.parameters.get("relationship.approval")
            for c in plan.cases
            if "relationship.approval" in c.parameters
        ]
        self.assertIn(35.0, approval_vals)
        self.assertIn(-60.0, approval_vals)

    def test_pairwise_strategy_covering_array(self) -> None:
        # Select 4 dimensions for pairwise
        target_dims = [
            "relationship.approval",
            "relationship.respect",
            "persona.bondKind",
            "persona.personality.aggression",
        ]
        plan = self.planner.plan_pairwise(
            dimensions=target_dims,
            surfaces=("scenario.rootChoice:wellbeing",),
            languages=("EN",),
            max_cases=128,
        )
        self.assertEqual(plan.strategy, "pairwise")
        self.assertGreater(plan.total_cases, 0)
        self.assertLessEqual(plan.total_cases, 64)

        # Verify that all uncovered pairs is empty (100% 2-way coverage)
        self.assertEqual(len(plan.uncovered_pairs), 0)

    def test_persona_strategy(self) -> None:
        plan = self.planner.plan_persona(
            surfaces=("scenario.rootChoice:wellbeing",),
            languages=("EN",),
            max_cases=64,
        )
        self.assertEqual(plan.strategy, "persona")
        self.assertGreater(plan.total_cases, 5)
        self.assertLessEqual(plan.total_cases, 64)

        # Confirm personalityOverride prerequisite is satisfied
        for c in plan.cases:
            if any(k.startswith("persona.personality.") for k in c.parameters):
                self.assertTrue(c.parameters.get("npc.personalityOverride"))

    def test_full_bounded_strategy_and_determinism(self) -> None:
        plan1 = self.planner.plan_full(
            surfaces=("scenario.rootChoice:wellbeing", "scenario.utterance:hello"),
            languages=("EN", "TL"),
            max_cases=128,
        )
        self.assertEqual(plan1.strategy, "full")
        self.assertGreater(plan1.total_cases, 10)
        self.assertLessEqual(plan1.total_cases, 128)

        # Determinism check: running again with same inputs gives identical plan
        plan2 = self.planner.plan_full(
            surfaces=("scenario.rootChoice:wellbeing", "scenario.utterance:hello"),
            languages=("EN", "TL"),
            max_cases=128,
        )
        self.assertEqual(plan1.plan_digest, plan2.plan_digest)
        self.assertEqual([c.case_id for c in plan1.cases], [c.case_id for c in plan2.cases])


    def test_full_bounded_balances_parameterized_cases_across_surfaces(self) -> None:
        surfaces = (
            "scenario.rootChoice:ask_name",
            "scenario.rootChoice:recruit",
            "scenario.utterance:hello",
            "scenario.utterance:how are you?",
        )
        plan = self.planner.plan_full(
            surfaces=surfaces,
            languages=("EN",),
            max_cases=64,
        )
        parameterized = {
            surface: sum(
                1 for case in plan.cases
                if case.surface == surface and bool(case.parameters)
            )
            for surface in surfaces
        }
        self.assertTrue(all(count > 0 for count in parameterized.values()), parameterized)
        self.assertLessEqual(
            max(parameterized.values()) - min(parameterized.values()),
            3,
            parameterized,
        )

    def test_batch_estimation(self) -> None:
        plan = self.planner.plan_smoke(
            surfaces=["scenario.rootChoice:ask_name"] * 10,
            languages=("EN", "TL"),
        )
        # 20 cases, batch size 64 -> 1 batch
        self.assertEqual(plan.total_cases, 20)
        self.assertEqual(plan.estimated_batches, 1)

    def test_surface_distribution_and_metadata(self) -> None:
        """Verify plans distribute cases across valid root choices and utterances."""
        plan = self.planner.plan_full(
            surfaces=(
                "scenario.rootChoice:ask_name",
                "scenario.rootChoice:recruit",
                "scenario.utterance:how are you?",
                "scenario.utterance:hello",
            ),
            languages=("EN", "TL"),
            max_cases=64,
        )
        surfaces_in_plan = set(c.surface for c in plan.cases)
        # Both root choices and utterance surfaces must be present
        self.assertTrue(any("rootChoice" in s for s in surfaces_in_plan))
        self.assertTrue(any("utterance" in s for s in surfaces_in_plan))
        self.assertIn("scenario.rootChoice:ask_name", plan.planned_surfaces)
        self.assertIn("scenario.utterance:how are you?", plan.planned_surfaces)
        self.assertEqual(plan.languages, ["EN", "TL"])
        self.assertIn("relationship.approval", plan.dimension_summary)


if __name__ == "__main__":
    unittest.main()
