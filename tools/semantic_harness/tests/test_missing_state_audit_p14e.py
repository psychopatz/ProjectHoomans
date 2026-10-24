"""P14E audit for honest and classified missing values."""

from __future__ import annotations

import unittest

from tools.semantic_harness.runtime.save_import import SaveBackedImporter
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
import tools.semantic_harness.tests.test_production_faction_rehydration_p14c as p14c_fixture


CORE_REPOSITORY = p14c_fixture.CORE_REPOSITORY


class MissingStateAuditP14ETests(unittest.TestCase):
    def setUp(self) -> None:
        p14c_fixture.ProductionFactionRehydrationP14CTests.setUp(self)

    def test_missing_values_have_explicit_provenance_class(self) -> None:
        selection = SaveBackedImporter(
            core_repository=CORE_REPOSITORY,
        ).load(
            self.save_path,
            player_uuid="char_p14c",
            npc_id="npcP14C",
        )
        paths = selection.provenance["paths"]

        self.assertEqual(paths["npc.inventory"]["source"], "MISSING")
        self.assertEqual(
            paths["npc.inventory"]["missingClass"],
            "LEGITIMATE_ABSENCE",
        )
        self.assertEqual(paths["npc.relationship"]["source"], "MISSING")
        self.assertEqual(
            paths["npc.relationship"]["missingClass"],
            "LEGITIMATE_ABSENCE",
        )
        self.assertEqual(paths["npc.faction"]["source"], "SAVE")
        self.assertEqual(paths["npc.community"]["source"], "SAVE")

    def test_engine_only_and_provider_missing_values_are_classified(self) -> None:
        from tools.semantic_harness.runtime.player_engine_state import (
            OfflinePlayerEngineStateProvider,
        )

        missing = OfflinePlayerEngineStateProvider().project(
            self.save_path / "missing-save",
            player_uuid="char_p14c",
        )
        self.assertEqual(missing["source"], "MISSING")
        self.assertEqual(missing["missingClass"], "ENGINE_ONLY")
        self.assertEqual(missing["worn"]["missingClass"], "ENGINE_ONLY")

    def test_fixture_mode_marks_fixture_and_absence_without_save_claims(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            social = worker.snapshot()["context"]["socialContext"]

        self.assertEqual(
            social["personalRelationship"]["source"],
            "FIXTURE",
        )
        self.assertEqual(
            social["factionRelationship"]["missingClass"],
            "LEGITIMATE_ABSENCE",
        )
        self.assertEqual(
            social["durableBond"]["missingClass"],
            "LEGITIMATE_ABSENCE",
        )


if __name__ == "__main__":
    unittest.main()
