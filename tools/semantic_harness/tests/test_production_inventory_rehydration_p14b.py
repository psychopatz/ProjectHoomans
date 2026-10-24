"""P14B production-owned NPC inventory rehydration coverage."""

from __future__ import annotations

from copy import deepcopy
import hashlib
from pathlib import Path
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.save_catalog import SaveCatalog
from tools.semantic_harness.runtime.save_import import SaveBackedImporter
from tools.semantic_harness.runtime.state import Provenance
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


CORE_REPOSITORY = Path("/home/psychopatz/Zomboid/Workshop/psychopatzCore")


class ProductionInventoryRehydrationP14BTests(unittest.TestCase):
    def test_all_production_inventory_persistence_modes_rehydrate(self) -> None:
        for mode in ("SEED_ONLY", "BASELINE_DELTA", "FULL"):
            with self.subTest(mode=mode):
                with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
                    # The worker asks production Lua to serialize the record.
                    # Python only transports the resulting raw saved record.
                    fixture = worker._request(
                        "TEST_PRODUCTION_INVENTORY_FIXTURE",
                        {"mode": mode},
                    )
                    self.assertEqual(fixture["mode"], mode)
                    self.assertEqual(fixture["roundTripMode"], mode)
                    raw_record = fixture["record"]
                    self.assertEqual(raw_record["inventory"][1], mode)

                    scenario = merge({}, DEFAULT_SCENARIO)
                    scenario["npc"]["npcID"] = raw_record["id"]
                    scenario["npc"]["id"] = raw_record["id"]
                    imported = worker.import_source(
                        scenario,
                        source=Provenance.SAVE,
                        source_id=f"save:p14b:{mode.lower()}",
                        mode="offline_save",
                        provider_payloads={
                            "ProjectHoomans": {
                                "rawRecords": {"npc": raw_record},
                            }
                        },
                    )

                    status = imported["productionRehydration"]
                    self.assertEqual(status["status"], "HYDRATED")
                    self.assertEqual(status["inventoryMode"], mode)
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
                        status["inventoryItemCount"],
                        fixture["runtimeItemCount"],
                    )

                    transported = worker.source_snapshot.to_dict()[
                        "providerPayloads"
                    ]["ProjectHoomans"]["rawRecords"]["npc"]
                    self.assertEqual(transported, raw_record)

                    inventory = imported["scenario"]["npc"]["inventory"]
                    self.assertEqual(
                        len(inventory["items"]), fixture["runtimeItemCount"]
                    )
                    marker_id = fixture.get("markerID")
                    if marker_id:
                        marker = inventory["items"].get(marker_id)
                        self.assertIsNotNone(marker)
                        self.assertEqual(marker["type"], fixture["markerType"])

                    # The semantic inventory query consumes the hydrated
                    # production record, not a Python-generated item list.
                    turn = worker.input("what do you have")
                    self.assertEqual(turn["result"]["ir"]["subject"], "INVENTORY")

                    # Replace the public projection with an empty working
                    # draft.  SAVE rehydration must restore the production
                    # inventory from the immutable raw record.
                    draft = deepcopy(worker.scenario)
                    draft["npc"]["inventory"] = {
                        "revision": 0,
                        "items": {},
                        "containers": {},
                    }
                    configured = worker.configure(draft)
                    self.assertEqual(
                        configured["productionRehydration"]["inventoryMode"],
                        mode,
                    )
                    self.assertEqual(
                        configured["productionRehydration"]["inventoryItemCount"],
                        fixture["runtimeItemCount"],
                    )

                    source_before_reset = deepcopy(
                        worker.source_snapshot.to_dict()
                    )
                    reset = worker.reset_working_world()
                    self.assertEqual(reset["workingWorld"]["patches"], [])
                    self.assertEqual(
                        worker.source_snapshot.to_dict(), source_before_reset
                    )
                    self.assertEqual(
                        reset["productionRehydration"]["inventoryMode"], mode
                    )

    def test_real_saved_npc_inventory_missing_projection_is_rehydrated(self) -> None:
        report = SaveCatalog(core_repository=CORE_REPOSITORY).discover()
        preferred = {
            "npcWilberDowns_R4XY",
            "npcKentLangley_OWOJ",
        }
        selected: tuple[Path, str] | None = None
        for save in report.get("saves", []):
            for npc in save.get("npcs", []):
                if npc.get("id") in preferred:
                    selected = Path(save["path"]), str(npc["id"])
                    break
            if selected:
                break
        if selected is None:
            self.skipTest("no preferred real compact-inventory save is available")

        save_path, npc_id = selected
        source_hash = hashlib.sha256(save_path.read_bytes()).digest()
        selection = SaveBackedImporter(
            core_repository=CORE_REPOSITORY,
        ).load(save_path, npc_id=npc_id)
        raw_inventory = selection.provider_payloads["ProjectHoomans"][
            "rawRecords"
        ]["npc"]["inventory"]
        self.assertEqual(raw_inventory[1], "BASELINE_DELTA")
        # This is the false diagnostic that motivated P14B: the compact raw
        # save envelope is not a legacy runtime inventory projection.
        self.assertEqual(
            selection.provenance["paths"]["npc.inventory"]["source"],
            "SAVE",
        )
        self.assertIn(
            "PNC.Inventory.EnsureRecordInventory",
            selection.provenance["paths"]["npc.inventory"]["owner"],
        )

        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            imported = worker.import_saved_selection(save_path, npc_id=npc_id)
            status = imported["productionRehydration"]
            self.assertEqual(status["status"], "HYDRATED")
            self.assertEqual(status["inventoryMode"], "BASELINE_DELTA")
            self.assertGreater(status["inventoryItemCount"], 0)
            self.assertGreater(status["engineItemTypeFixtureCount"], 0)
            self.assertEqual(
                len(imported["scenario"]["npc"]["inventory"]["items"]),
                status["inventoryItemCount"],
            )

            source_before_reset = deepcopy(worker.source_snapshot.to_dict())
            reset = worker.reset_working_world()
            self.assertEqual(reset["workingWorld"]["patches"], [])
            self.assertEqual(
                reset["productionRehydration"]["inventoryMode"],
                "BASELINE_DELTA",
            )
            self.assertEqual(
                worker.source_snapshot.to_dict(), source_before_reset
            )
            self.assertEqual(
                hashlib.sha256(save_path.read_bytes()).digest(), source_hash
            )


if __name__ == "__main__":
    unittest.main()
