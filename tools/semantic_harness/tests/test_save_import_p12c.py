"""P12C saved Player/NPC import and relationship isolation tests."""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path
import tempfile
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.save_import import SaveBackedImporter
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.tests.test_save_catalog_p12b import pz_file


CORE_REPOSITORY = Path("/home/psychopatz/Zomboid/Workshop/psychopatzCore")


class SaveImportTests(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.save_path = Path(self.directory.name) / "global_mod_data.bin"
        player_key = "player:slot_0:char_saved"
        relationship = {
            "baselineApproval": 73,
            "baselineRespect": 41,
            "approval": 90,
            "respect": 55,
            "familiarity": 88,
            "state": "friend",
            "previousState": "acquaintance",
            "bond": {"kind": "friend", "createdAt": 44},
            "memories": {"memory-1": {"type": "shared_meal"}},
            "saturation": {"gift": 2},
            "cooldowns": {"proposal": 0},
            "interactionJournal": {"revision": 12},
            "interactionRevision": 12,
            "revision": 29,
        }
        tables = [
            (
                "PNC_PlayerCharacters",
                [
                    ("schemaVersion", 6),
                    ("revision", 4),
                    (
                        "byUUID",
                        {
                            "char_saved": {
                                "uuid": "char_saved",
                                "accountKey": "slot_0",
                                "accountIdentity": "SavedPlayer",
                                "forename": "Saved",
                                "surname": "Player",
                                "displayName": "Saved Player",
                                "status": "active",
                                "socialProfile": {
                                    "orientation": "bisexual",
                                    "romanceStyle": "flirty",
                                    "sourceTraits": {"kind": True},
                                    "revision": 7,
                                },
                            }
                        },
                    ),
                ],
            ),
            ("PNC_Core_Global", [("schemaVersion", 16), ("layoutVersion", 2)]),
            (
                "PNC_npcMara",
                [
                    ("schemaVersion", 16),
                    ("recordRevision", 31),
                    ("id", "npcMara"),
                    (
                        "identity",
                        {
                            "displayName": "Mara Vale",
                            "isFemale": True,
                            "archetypeID": "General",
                            "seed": 42,
                            "survivor": {
                                "forename": "Mara",
                                "surname": "Vale",
                            },
                        },
                    ),
                    ("social", {"relationships": {player_key: relationship}}),
                ],
            ),
        ]
        self.save_path.write_bytes(pz_file(tables))

    def test_import_preserves_saved_entity_key_relationship_and_provenance(self) -> None:
        selection = SaveBackedImporter(
            core_repository=CORE_REPOSITORY,
        ).load(self.save_path, player_uuid="char_saved", npc_id="npcMara")

        self.assertEqual(selection.player_entity_key, "player:slot_0:char_saved")
        self.assertEqual(selection.scenario["npc"]["relationship"]["approval"], 90)
        self.assertEqual(
            selection.scenario["player"]["socialProfile"]["orientation"],
            "bisexual",
        )
        self.assertEqual(
            selection.scenario["npc"]["relationship"]["bond"],
            {"kind": "friend", "createdAt": 44},
        )
        self.assertEqual(
            selection.provenance["paths"]["npc.relationship"]["source"],
            "SAVE",
        )
        self.assertEqual(
            selection.provenance["paths"]["npc.needs"]["source"],
            "FIXTURE",
        )
        self.assertEqual(
            selection.provenance["paths"]["player.socialProfile"]["source"],
            "SAVE",
        )
        self.assertEqual(
            selection.provider_payloads["ProjectHoomans"]["PNC_npcMara"][
                "recordRevision"
            ],
            31,
        )

    def test_saved_relationship_mutates_only_detached_world(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            worker.import_saved_selection(
                self.save_path,
                player_uuid="char_saved",
                npc_id="npcMara",
            )
            source_before = deepcopy(worker.source_snapshot.to_dict())
            imported = worker.snapshot()
            self.assertEqual(
                imported["sourceSnapshot"]["metadata"]["sourceKind"],
                "SAVE",
            )
            self.assertEqual(
                imported["scenario"]["player"]["entityKey"],
                "player:slot_0:char_saved",
            )
            self.assertEqual(
                imported["scenario"]["npc"]["relationship"]["approval"],
                90,
            )

            worker.input("here's an apple for you")
            mutated = worker.snapshot()
            self.assertTrue(mutated["workingWorld"]["patches"])
            self.assertEqual(worker.source_snapshot.to_dict(), source_before)

            worker.reset_working_world()
            reset = worker.snapshot()
            self.assertEqual(reset["workingWorld"]["patches"], [])
            self.assertEqual(
                reset["scenario"]["npc"]["relationship"]["approval"],
                90,
            )
            self.assertEqual(worker.source_snapshot.to_dict(), source_before)


if __name__ == "__main__":
    unittest.main()
