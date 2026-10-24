"""P14C production-owned faction/community rehydration coverage."""

from __future__ import annotations

from copy import deepcopy
import hashlib
from pathlib import Path
import tempfile
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.save_catalog import SaveCatalog
from tools.semantic_harness.runtime.save_import import SaveBackedImporter
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.tests.test_save_catalog_p12b import pz_file


CORE_REPOSITORY = Path("/home/psychopatz/Zomboid/Workshop/psychopatzCore")
REAL_SAVE = Path(
    "/home/psychopatz/Zomboid/Saves/Apocalypse/"
    "2026-10-14_13-57-03/global_mod_data.bin"
)


def relation(source: str, target: str, *, standing: int, state: str) -> dict:
    return {
        "schemaVersion": 1,
        "targetFactionID": target,
        "standing": standing,
        "trust": -20,
        "fear": 70,
        "grievance": 40,
        "state": state,
        "previousState": "neutral",
        "atWar": True,
        "allied": False,
        "truceUntil": 0,
        "warStartedAt": 12,
        "warEndedAt": 0,
        "warReason": "scripted",
        "initiatingFactionID": source,
        "incidents": {},
        "recentIncidentIDs": {},
        "lastEvaluatedAt": 12,
        "revision": 3,
    }


class ProductionFactionRehydrationP14CTests(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.save_path = Path(self.directory.name) / "global_mod_data.bin"
        player_key = "player:slot_p14c:char_p14c"
        npc_faction = "faction_p14c_raiders"
        player_faction = "faction_p14c_player"
        community_id = "community_p14c_raiders"
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
                                    "char_p14c": {
                                        "uuid": "char_p14c",
                                        "accountKey": "slot_p14c",
                                        "displayName": "P14C Player",
                                        "status": "active",
                                    }
                                },
                            ),
                        ],
                    ),
                    ("PNC_Core_Global", [("schemaVersion", 16)]),
                    (
                        "PNC_Factions",
                        [
                            ("schemaVersion", 6),
                            (
                                "byID",
                                {
                                    npc_faction: {
                                        "id": npc_faction,
                                        "name": "P14C Raiders",
                                        "archetypeID": "looter",
                                        "status": "active",
                                        "leaderNPCID": "npcP14C",
                                        "memberIDs": {"npcP14C": True},
                                        "playerMemberKeys": {},
                                        "relations": {
                                            player_faction: relation(
                                                npc_faction,
                                                player_faction,
                                                standing=-55,
                                                state="war",
                                            )
                                        },
                                    },
                                    player_faction: {
                                        "id": player_faction,
                                        "name": "P14C Fellowship",
                                        "archetypeID": "settler",
                                        "status": "active",
                                        "memberIDs": {},
                                        "ownerPlayerKey": player_key,
                                        "playerMemberKeys": {player_key: True},
                                        "tags": {
                                            "provisionalPlayerFaction": True
                                        },
                                        "relations": {
                                            npc_faction: relation(
                                                player_faction,
                                                npc_faction,
                                                standing=-45,
                                                state="war",
                                            )
                                        },
                                    },
                                },
                            ),
                        ],
                    ),
                    (
                        "PNC_Communities",
                        [
                            ("schemaVersion", 2),
                            (
                                "byID",
                                {
                                    community_id: {
                                        "id": community_id,
                                        "factionID": npc_faction,
                                        "name": "P14C Raider Camp",
                                        "mode": "settled",
                                        "status": "active",
                                        "home": {"x": 100, "y": 200, "z": 0},
                                        "leaderNPCID": "npcP14C",
                                        "memberIDs": {"npcP14C": True},
                                    }
                                },
                            ),
                            ("sitesByID", {}),
                        ],
                    ),
                    (
                        "PNC_npcP14C",
                        [
                            ("schemaVersion", 16),
                            ("recordRevision", 5),
                            ("id", "npcP14C"),
                            (
                                "identity",
                                {
                                    "displayName": "P14C Raider",
                                    "isFemale": False,
                                    "archetypeID": "General",
                                    "seed": 1403,
                                    "survivor": {
                                        "forename": "P14C",
                                        "surname": "Raider",
                                    },
                                },
                            ),
                            (
                                "affiliation",
                                {
                                    "factionID": npc_faction,
                                    "communityID": community_id,
                                    "membershipStatus": "member",
                                    "role": "member",
                                    "rank": "member",
                                },
                            ),
                            (
                                "hostility",
                                {"mode": "hostile", "attackPlayers": True},
                            ),
                        ],
                    ),
                ]
            )
        )

    def test_raw_registries_use_production_loaders_and_survive_reset(self) -> None:
        selection = SaveBackedImporter(
            core_repository=CORE_REPOSITORY,
        ).load(self.save_path, player_uuid="char_p14c", npc_id="npcP14C")
        raw_registries = selection.provider_payloads["ProjectHoomans"][
            "rawRegistries"
        ]
        self.assertIn("factions", raw_registries)
        self.assertIn("communities", raw_registries)

        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            imported = worker.import_saved_selection(
                self.save_path,
                player_uuid="char_p14c",
                npc_id="npcP14C",
            )
            faction_status = imported["productionFactionRehydration"]
            self.assertEqual(faction_status["status"], "HYDRATED")
            self.assertEqual(
                faction_status["factionLoadOwner"],
                "PNC.Factions.LoadRaw",
            )
            self.assertEqual(
                faction_status["communityLoadOwner"],
                "PNC.Communities.LoadRaw",
            )

            context = imported["productionFactionContext"]
            self.assertEqual(context["npcFaction"]["id"], "faction_p14c_raiders")
            self.assertEqual(
                context["playerDiplomacyFaction"]["id"],
                "faction_p14c_player",
            )
            self.assertTrue(
                context["playerDiplomacyFaction"]["provisionalPlayerFaction"]
            )
            self.assertEqual(context["directedRelation"]["standing"], -55)
            self.assertTrue(context["directedRelation"]["atWar"])
            self.assertEqual(context["effective"]["state"], "war")
            self.assertEqual(context["community"]["id"], "community_p14c_raiders")
            self.assertEqual(context["community"]["leaderNPCID"], "npcP14C")
            self.assertEqual(context["community"]["memberCount"], 1)

            self.assertEqual(
                imported["scenario"]["npc"]["factionContext"]["effective"][
                    "state"
                ],
                "war",
            )
            source_before = deepcopy(worker.source_snapshot.to_dict())
            lifecycle_turn = worker.interaction_npc_speech(
                {
                    "npcID": "npcP14C",
                    "act": "QUESTION",
                    "topic": "faction",
                    "beatID": "beat:save:faction",
                    "responsePlanID": "plan:save:faction",
                    "meaningful": True,
                }
            )
            self.assertTrue(lifecycle_turn["result"]["persisted"])
            self.assertEqual(
                worker.snapshot()["interactionLifecycle"]["responseWindow"]
                    ["activeBeat"]["id"],
                "beat:save:faction",
            )
            worker.reset_working_world()
            reset = worker.snapshot()
            self.assertEqual(reset["workingWorld"]["patches"], [])
            self.assertEqual(
                reset["productionFactionContext"]["directedRelation"]["standing"],
                -55,
            )
            self.assertEqual(worker.source_snapshot.to_dict(), source_before)

    def test_fixture_mode_does_not_use_saved_faction_state(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            snapshot = worker.snapshot()
            self.assertEqual(
                snapshot["productionFactionRehydration"]["status"],
                "NOT_APPLICABLE",
            )

    def test_real_saved_player_faction_and_directed_relation_rehydrate(self) -> None:
        if not REAL_SAVE.is_file():
            self.skipTest("real local save is unavailable")
        selection = SaveBackedImporter(
            core_repository=CORE_REPOSITORY,
        ).load(REAL_SAVE, npc_id="npcWilberDowns_R4XY")
        raw = selection.provider_payloads["ProjectHoomans"]
        registries = raw["rawRegistries"]
        factions = registries["factions"]["byID"]
        player_faction_id = registries["factions"]["byPlayerKey"][
            selection.player_entity_key
        ]
        target_id = next(
            faction_id
            for faction_id, faction in factions.items()
            if faction_id != player_faction_id
            and player_faction_id in (faction.get("relations") or {})
        )
        npc_id = next(iter(factions[target_id]["memberIDs"]))
        before = hashlib.sha256(REAL_SAVE.read_bytes()).digest()
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            imported = worker.import_saved_selection(REAL_SAVE, npc_id=npc_id)
            context = imported["productionFactionContext"]
            self.assertEqual(
                context["playerDiplomacyFaction"]["id"],
                player_faction_id,
            )
            self.assertEqual(context["npcFaction"]["id"], target_id)
            self.assertIsNotNone(context["directedRelation"])
            self.assertEqual(
                imported["productionFactionRehydration"]["status"],
                "HYDRATED",
            )
        self.assertEqual(hashlib.sha256(REAL_SAVE.read_bytes()).digest(), before)


if __name__ == "__main__":
    unittest.main()
