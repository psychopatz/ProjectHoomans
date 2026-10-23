"""P14A production Lua rehydration boundary acceptance coverage."""

from __future__ import annotations

from copy import deepcopy
import hashlib
from pathlib import Path
import tempfile
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.save_import import SaveBackedImporter
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.tests.test_save_catalog_p12b import pz_file


CORE_REPOSITORY = Path("/home/psychopatz/Zomboid/Workshop/psychopatzCore")


class ProductionRehydrationP14ATests(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.save_path = Path(self.directory.name) / "global_mod_data.bin"
        self.save_path.write_bytes(
            pz_file(
                [
                    (
                        "PNC_PlayerCharacters",
                        [
                            ("schemaVersion", 6),
                            (
                                "byUUID",
                                {
                                    "char_p14a": {
                                        "uuid": "char_p14a",
                                        "accountKey": "slot_p14a",
                                        "displayName": "P14A Player",
                                        "status": "active",
                                    }
                                },
                            ),
                        ],
                    ),
                    ("PNC_Core_Global", [("schemaVersion", 16)]),
                    (
                        "PNC_npcP14A",
                        [
                            ("schemaVersion", 16),
                            ("recordRevision", 4),
                            ("id", "npcP14A"),
                            (
                                "identity",
                                {
                                    "displayName": "Lua Rehydrated NPC",
                                    "isFemale": True,
                                    "archetypeID": "General",
                                    "seed": 1401,
                                    "survivor": {
                                        "forename": "Lua",
                                        "surname": "Rehydrated",
                                    },
                                },
                            ),
                            ("hostility", {"mode": "neutral"}),
                        ],
                    ),
                ]
            )
        )

    def test_raw_save_record_is_rehydrated_by_production_and_reset_isolated(self) -> None:
        source_bytes = hashlib.sha256(self.save_path.read_bytes()).digest()
        selection = SaveBackedImporter(
            core_repository=CORE_REPOSITORY,
        ).load(self.save_path, player_uuid="char_p14a", npc_id="npcP14A")
        raw = selection.provider_payloads["ProjectHoomans"]["rawRecords"]["npc"]
        self.assertEqual(raw["id"], "npcP14A")

        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            imported = worker.import_saved_selection(
                self.save_path,
                player_uuid="char_p14a",
                npc_id="npcP14A",
            )
            status = imported["productionRehydration"]
            self.assertEqual(status["status"], "HYDRATED")
            self.assertEqual(
                status["deserializer"],
                "PNC.Persistence.DeserializeRecord",
            )
            self.assertEqual(
                status["inventoryHydrator"],
                "PNC.Inventory.EnsureRecordInventory",
            )
            self.assertEqual(status["registry"], "isolated PNC.Registry")
            self.assertEqual(
                imported["scenario"]["npc"]["displayName"],
                "Lua Rehydrated NPC",
            )

            source_before = deepcopy(worker.source_snapshot.to_dict())
            worker.configure(deepcopy(worker.scenario))
            reset = worker.reset_working_world()
            self.assertEqual(reset["workingWorld"]["patches"], [])
            self.assertEqual(worker.source_snapshot.to_dict(), source_before)
            self.assertEqual(
                hashlib.sha256(self.save_path.read_bytes()).digest(),
                source_bytes,
            )

    def test_developer_fixture_mode_remains_explicit(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            snapshot = worker.snapshot()
            self.assertEqual(
                snapshot["productionRehydration"]["status"],
                "NOT_APPLICABLE",
            )


if __name__ == "__main__":
    unittest.main()
