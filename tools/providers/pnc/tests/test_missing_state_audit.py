"""audit for honest and classified missing values."""

from __future__ import annotations

import unittest

from tools.semantic_harness.runtime.save_import import SaveBackedImporter
from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.providers.pnc.tests.worker_reuse import WarmWorkerTestMixin
from tools.providers.pnc.tests.faction_rehydration_test_support import (
    CORE_REPOSITORY,
    setup_faction_fixture,
)


class MissingStateAuditTests(WarmWorkerTestMixin, unittest.TestCase):
    def setUp(self) -> None:
        setup_faction_fixture(self)

    def test_missing_values_have_explicit_provenance_class(self) -> None:
        selection = SaveBackedImporter(
            core_repository=CORE_REPOSITORY,
        ).load(
            self.save_path,
            player_uuid="char_faction_fixture",
            npc_id="npcFactionFixture",
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
        from tools.providers.pnc.runtime.player_engine_state import (
            OfflinePlayerEngineStateProvider,
        )

        missing = OfflinePlayerEngineStateProvider().project(
            self.save_path / "missing-save",
            player_uuid="char_faction_fixture",
        )
        self.assertEqual(missing["source"], "MISSING")
        self.assertEqual(missing["missingClass"], "ENGINE_ONLY")
        self.assertEqual(missing["worn"]["missingClass"], "ENGINE_ONLY")

    def test_fixture_mode_marks_fixture_and_absence_without_save_claims(self) -> None:
        with self.warm_worker(merge({}, DEFAULT_SCENARIO)) as worker:
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
