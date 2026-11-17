"""Shared faction/community save fixture helpers for PNC tests."""

from __future__ import annotations

from pathlib import Path
import tempfile
import unittest

from tools.providers.pnc.tests.save_test_support import pz_file

CORE_REPOSITORY = Path(__file__).resolve().parents[5] / "psychopatzCore"
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


def setup_faction_fixture(testcase: unittest.TestCase) -> None:
    testcase.directory = tempfile.TemporaryDirectory()
    testcase.addCleanup(testcase.directory.cleanup)
    testcase.save_path = Path(testcase.directory.name) / "global_mod_data.bin"
    player_key = "player:slot_faction_fixture:char_faction_fixture"
    npc_faction = "faction_faction_fixture_raiders"
    player_faction = "faction_faction_fixture_player"
    community_id = "community_faction_fixture_raiders"
    testcase.save_path.write_bytes(
        pz_file(
            [
                (
                    "PNC_PlayerCharacters",
                    [
                        ("schemaVersion", 6),
                        (
                            "byUUID",
                            {
                                "char_faction_fixture": {
                                    "uuid": "char_faction_fixture",
                                    "accountKey": "slot_faction_fixture",
                                    "displayName": "FactionFixture Player",
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
                                    "name": "FactionFixture Raiders",
                                    "archetypeID": "looter",
                                    "status": "active",
                                    "leaderNPCID": "npcFactionFixture",
                                    "memberIDs": {"npcFactionFixture": True},
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
                                    "name": "FactionFixture Fellowship",
                                    "archetypeID": "settler",
                                    "status": "active",
                                    "memberIDs": {},
                                    "ownerPlayerKey": player_key,
                                    "playerMemberKeys": {player_key: True},
                                    "tags": {"provisionalPlayerFaction": True},
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
                                    "name": "FactionFixture Raider Camp",
                                    "mode": "settled",
                                    "status": "active",
                                    "home": {"x": 100, "y": 200, "z": 0},
                                    "leaderNPCID": "npcFactionFixture",
                                    "memberIDs": {"npcFactionFixture": True},
                                }
                            },
                        ),
                        ("sitesByID", {}),
                    ],
                ),
                (
                    "PNC_npcFactionFixture",
                    [
                        ("schemaVersion", 16),
                        ("recordRevision", 5),
                        ("id", "npcFactionFixture"),
                        (
                            "identity",
                            {
                                "displayName": "FactionFixture Raider",
                                "isFemale": False,
                                "archetypeID": "General",
                                "seed": 1403,
                                "survivor": {
                                    "forename": "FactionFixture",
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
                        ("hostility", {"mode": "hostile", "attackPlayers": True}),
                    ],
                ),
            ]
        )
    )
