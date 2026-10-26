"""P4A production-worker Leave Group lifecycle acceptance coverage."""

from __future__ import annotations

from copy import deepcopy
import hashlib
from pathlib import Path
import tempfile
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.save_import import SaveBackedImporter
from tools.semantic_harness.runtime.save_catalog import _load_core_reader
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.tests.test_save_catalog_p12b import pz_file


CORE_REPOSITORY = Path("/home/psychopatz/Zomboid/Workshop/psychopatzCore")


class ProductionLeaveGroupP4ATests(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.save_path = Path(self.directory.name) / "global_mod_data.bin"
        self.player_key = "player:slot_p4a:char_p4a"
        self.player_faction = "faction_p4a_player"
        self.npc_id = "npcP4A"
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
                                    "char_p4a": {
                                        "uuid": "char_p4a",
                                        "accountKey": "slot_p4a",
                                        "displayName": "P4A Player",
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
                                    self.player_faction: {
                                        "id": self.player_faction,
                                        "name": "P4A Fellowship",
                                        "archetypeID": "settler",
                                        "status": "active",
                                        "memberIDs": {self.npc_id: True},
                                        "ownerPlayerKey": self.player_key,
                                        "playerMemberKeys": {
                                            self.player_key: True
                                        },
                                        "tags": {
                                            "provisionalPlayerFaction": True
                                        },
                                        "relations": {},
                                    }
                                },
                            ),
                        ],
                    ),
                    (
                        "PNC_Communities",
                        [
                            ("schemaVersion", 2),
                            ("byID", {}),
                            ("sitesByID", {}),
                        ],
                    ),
                    (
                        "PNC_" + self.npc_id,
                        [
                            ("schemaVersion", 16),
                            ("recordRevision", 5),
                            ("id", self.npc_id),
                            ("name", "P4A Companion"),
                            ("x", 100),
                            ("y", 200),
                            ("z", 0),
                            ("recruited", True),
                            ("companion", True),
                            ("ownerPlayerKey", self.player_key),
                            ("tacticalClass", "neutral"),
                            (
                                "identity",
                                {
                                    "displayName": "P4A Companion",
                                    "isFemale": False,
                                    "archetypeID": "General",
                                    "seed": 1404,
                                    "survivor": {
                                        "forename": "P4A",
                                        "surname": "Companion",
                                    },
                                },
                            ),
                            (
                                "affiliation",
                                {
                                    "factionID": self.player_faction,
                                    "membershipStatus": "member",
                                    "role": "member",
                                    "rank": "member",
                                    "ownerPlayerKey": self.player_key,
                                },
                            ),
                            (
                                "orderSpec",
                                {
                                    "kind": "follow",
                                    "ownerPlayerKey": self.player_key,
                                },
                            ),
                            ("hostility", {"mode": "neutral"}),
                            (
                                "inventory",
                                {"revision": 1, "items": {}, "containers": {}},
                            ),
                            (
                                "social",
                                {
                                    "relationships": {
                                        self.player_key: {
                                            "baselineApproval": 10,
                                            "baselineRespect": 15,
                                            "approval": 10,
                                            "respect": 15,
                                            "familiarity": 4,
                                            "state": "acquaintance",
                                            "revision": 2,
                                            "memories": {},
                                            "interactionJournal": {},
                                        }
                                    }
                                },
                            ),
                        ],
                    ),
                ]
            )
        )

    @staticmethod
    def _candidate(snapshot: dict, candidate_id: str) -> dict | None:
        suggestions = snapshot.get("suggestions") or {}
        rows = list(suggestions.get("candidates") or [])
        for group in suggestions.get("groups") or []:
            rows.extend(group.get("candidates") or [])
        presentation = snapshot.get("conversationPresentation") or {}
        channel = presentation.get("responseChannel") or {}
        rows.extend(channel.get("rows") or [])
        return next(
            (
                row
                for row in rows
                if row.get("id") == candidate_id
                or row.get("id") == "conversation.root:menu:" + candidate_id
                or (row.get("frame") or {}).get("candidateID")
                == "conversation.root:menu:" + candidate_id
            ),
            None,
        )

    def _worker(self) -> LuaSemanticWorker:
        return LuaSemanticWorker(
            merge({}, DEFAULT_SCENARIO),
            core_repository=CORE_REPOSITORY,
        )

    def _departure_payload(self, response: dict) -> dict:
        events = [
            event
            for event in response.get("transport", [])
            if event.get("command") == "ConversationDepartureResult"
        ]
        self.assertEqual(len(events), 1, response)
        return events[0]["payload"]

    def _message_text(self, response: dict, key: str) -> str:
        messages = [
            message
            for message in response.get("messages", []) or []
            if message.get("payload", {}).get("key") == key
        ]
        self.assertEqual(len(messages), 1, response)
        text = messages[0]["payload"].get("text")
        self.assertIsInstance(text, str)
        self.assertTrue(text)
        return text

    def _variant_save(self, filename: str, mutate) -> Path:
        Reader, _reader_error = _load_core_reader(CORE_REPOSITORY)
        table_names = [
            "PNC_PlayerCharacters",
            "PNC_Core_Global",
            "PNC_Factions",
            "PNC_Communities",
            "PNC_" + self.npc_id,
        ]
        with Reader(self.save_path) as reader:
            tables = {
                table_name: SaveBackedImporter._read_full(reader, table_name)
                for table_name in table_names
            }
        mutate(tables)
        variant_path = Path(self.directory.name) / filename
        variant_path.write_bytes(
            pz_file(
                [
                    (table_name, list(table.items()))
                    for table_name, table in tables.items()
                ]
            )
        )
        return variant_path

    def _assert_rejected(self, save_path: Path, expected_reason: str) -> None:
        source_hash = hashlib.sha256(save_path.read_bytes()).digest()
        with self._worker() as worker:
            imported = worker.import_saved_selection(
                save_path,
                player_uuid="char_p4a",
                npc_id=self.npc_id,
            )
            self.assertEqual(
                imported["productionPlayerRehydration"]["status"],
                "HYDRATED",
            )
            opened = worker.open_conversation()
            self.assertEqual(
                opened["presentation"]["lifecycle"]["state"],
                "active",
                opened,
            )
            disband = self._candidate(worker.snapshot(), "disband")
            self.assertIsNotNone(disband, worker.snapshot())
            before = worker.snapshot()
            source_before = worker.source_snapshot.to_dict()

            response = worker.suggestion_click(disband["frame"])
            payload = self._departure_payload(response)
            self.assertTrue(response["accepted"], response)
            self.assertEqual(payload["responseKey"], "response.departure.rejected")
            self.assertFalse(payload["success"])
            self.assertEqual(payload["reason"], expected_reason)

            after = worker.snapshot()
            self.assertEqual(
                after["scenario"]["npc"], before["scenario"]["npc"]
            )
            lifecycle = after["conversationPresentation"]["lifecycle"]
            self.assertEqual(lifecycle["state"], "active")
            self.assertFalse(lifecycle["closed"])
            self.assertEqual(worker.source_snapshot.to_dict(), source_before)
        self.assertEqual(hashlib.sha256(save_path.read_bytes()).digest(), source_hash)

    def test_positive_warning_and_confirmation_use_production_worker_route(self) -> None:
        before_hash = hashlib.sha256(self.save_path.read_bytes()).digest()
        with self._worker() as worker:
            imported = worker.import_saved_selection(
                self.save_path,
                player_uuid="char_p4a",
                npc_id=self.npc_id,
            )
            self.assertEqual(
                imported["productionPlayerRehydration"]["status"],
                "HYDRATED",
            )
            self.assertEqual(
                imported["productionPlayerRehydration"]["entityKey"],
                self.player_key,
            )
            self.assertEqual(
                imported["productionFactionRehydration"]["status"],
                "HYDRATED",
            )
            self.assertEqual(
                imported["productionFactionRehydration"]["factionLoadOwner"],
                "PNC.Factions.LoadRaw",
            )
            self.assertEqual(
                imported["productionFactionContext"]["playerDiplomacyFaction"]["id"],
                self.player_faction,
            )
            self.assertEqual(
                imported["scenario"]["npc"]["recruited"],
                True,
            )

            opened = worker.open_conversation()
            self.assertEqual(
                opened["presentation"]["lifecycle"]["state"],
                "active",
                opened,
            )
            disband = self._candidate(worker.snapshot(), "disband")
            self.assertIsNotNone(disband, worker.snapshot())
            source_before_warning = deepcopy(worker.source_snapshot.to_dict())
            working_before_warning = worker.snapshot()

            warning = worker.suggestion_click(disband["frame"])
            warning_snapshot = worker.snapshot()
            self.assertTrue(warning["accepted"], warning)
            warning_payload = self._departure_payload(warning)
            self.assertEqual(
                warning_payload["responseKey"], "response.departure.warning"
            )
            self.assertTrue(warning_payload["warning"])
            self.assertEqual(
                warning_payload["reason"], "departure_confirmation_required"
            )
            self.assertEqual(
                warning_snapshot["scenario"]["npc"]["recruited"],
                working_before_warning["scenario"]["npc"]["recruited"],
            )
            self.assertEqual(
                warning_snapshot["scenario"]["npc"].get("ownerPlayerKey"),
                working_before_warning["scenario"]["npc"].get(
                    "ownerPlayerKey"
                ),
            )
            self.assertEqual(
                worker.source_snapshot.to_dict(), source_before_warning
            )
            self.assertEqual(
                hashlib.sha256(self.save_path.read_bytes()).digest(), before_hash
            )

            confirm = self._candidate(warning_snapshot, "disband_confirm")
            self.assertIsNotNone(confirm, warning_snapshot)
            confirmed = worker.suggestion_click(confirm["frame"])
            self.assertTrue(confirmed["accepted"], confirmed)
            confirmed_payload = self._departure_payload(confirmed)
            self.assertEqual(
                confirmed_payload["responseKey"],
                "response.departure.confirmed",
            )
            self.assertTrue(confirmed_payload["success"])
            self.assertEqual(
                confirmed_payload["reason"],
                "colonist_departed",
            )
            post = worker.snapshot()
            post_presentation = post.get("conversationPresentation") or {}
            post_npc = post.get("scenario", {}).get("npc", {})
            self.assertEqual(post_presentation["lifecycle"]["state"], "closed")
            self.assertTrue(post_presentation["lifecycle"]["closed"])
            self.assertFalse(post_presentation["lifecycle"]["closing"])
            self.assertTrue(confirmed_payload["close"])
            self.assertEqual(confirmed_payload["closeReason"], "colonist_departed")
            confirmed_transcript = [
                message
                for message in post.get("transcript", [])
                if message.get("payload", {}).get("key")
                == "response.departure.confirmed"
            ]
            self.assertEqual(len(confirmed_transcript), 1, post["transcript"])

            destination_id = confirmed_payload["factionID"]
            self.assertNotEqual(destination_id, self.player_faction)
            self.assertEqual(
                confirmed_payload["sourceFactionID"], self.player_faction
            )
            self.assertFalse(post_npc["recruited"])
            self.assertFalse(post_npc["ownedByPlayer"])
            self.assertFalse(post_npc["companion"])
            self.assertEqual(post_npc["factionID"], destination_id)
            self.assertEqual(
                post_npc["affiliation"]["factionID"], destination_id
            )
            former_factions = post_npc["affiliation"].get("formerFactionIDs")
            if isinstance(former_factions, dict):
                former_factions = list(former_factions.values())
            self.assertTrue(
                any(
                    (
                        entry.get("factionID")
                        if isinstance(entry, dict)
                        else entry
                    )
                    == self.player_faction
                    for entry in former_factions or []
                )
            )

            production_context = post["productionFactionContext"]
            destination = production_context["npcFaction"]
            self.assertEqual(destination["id"], destination_id)
            self.assertEqual(destination["archetypeID"], "refugee")
            self.assertTrue(destination["tags"]["mobileGroup"])
            self.assertTrue(destination["tags"]["colonistDeparture"])
            self.assertEqual(destination["tags"]["departureCause"], "manual")
            self.assertEqual(
                destination["tags"]["originFactionID"], self.player_faction
            )
            self.assertEqual(
                destination["tags"]["originPlayerKey"], self.player_key
            )
            self.assertTrue(destination["mobile"]["active"])
            self.assertIsInstance(destination["mobile"].get("site"), dict)
            source = production_context["playerDiplomacyFaction"]
            self.assertEqual(source["id"], self.player_faction)
            self.assertEqual(source["ownerPlayerKey"], self.player_key)
            self.assertEqual(source["memberCount"], 0)

            before_relationship = confirmed_payload["relationshipBefore"]
            after_relationship = confirmed_payload["relationshipAfter"]
            relationship_delta = confirmed_payload["relationshipDelta"]
            self.assertEqual(before_relationship["approval"], 10)
            self.assertEqual(before_relationship["respect"], 15)
            self.assertEqual(after_relationship["approval"], -40)
            self.assertEqual(after_relationship["respect"], -35)
            self.assertEqual(relationship_delta["approval"], -50)
            self.assertEqual(relationship_delta["respect"], -50)
            relationship = post_npc["relationship"]
            self.assertEqual(relationship["approval"], -40)
            self.assertEqual(relationship["respect"], -35)
            memory_id = (
                "conversation:colonist_expelled:"
                + self.npc_id
                + ":"
                + self.player_faction
            )
            memories = [
                memory
                for memory in relationship["memories"]
                if memory.get("id") == memory_id
            ]
            self.assertEqual(len(memories), 1, relationship)
            self.assertEqual(memories[0]["type"], "colonist_expelled")
            self.assertEqual(memories[0]["approvalEffect"], -50)
            self.assertEqual(memories[0]["respectEffect"], -50)
            self.assertTrue(memories[0]["permanent"])
            journal = [
                entry
                for entry in relationship["interactionJournal"]
                if entry.get("choiceID") == "disband_confirm"
            ]
            self.assertEqual(len(journal), 1, relationship)
            self.assertEqual(journal[0]["source"], "colonist_departure")
            self.assertEqual(journal[0]["delta"]["approval"], -50)
            self.assertEqual(journal[0]["delta"]["respect"], -50)

    def test_other_owner_is_rejected_by_production_worker(self) -> None:
        other_key = "player:slot_o4a:char_o4a"

        def mutate(tables: dict) -> None:
            faction = tables["PNC_Factions"]["byID"][self.player_faction]
            faction["ownerPlayerKey"] = other_key
            faction["playerMemberKeys"] = {other_key: True}
            npc = tables["PNC_" + self.npc_id]
            npc["ownerPlayerKey"] = other_key
            npc["affiliation"]["ownerPlayerKey"] = other_key
            npc["orderSpec"]["ownerPlayerKey"] = other_key

        save_path = self._variant_save("other-owner.bin", mutate)
        self._assert_rejected(save_path, "not_colonist_owner")

    def test_unowned_is_rejected_by_production_worker(self) -> None:
        def mutate(tables: dict) -> None:
            faction = tables["PNC_Factions"]["byID"][self.player_faction]
            faction.pop("ownerPlayerKey", None)
            faction["playerMemberKeys"] = {}
            npc = tables["PNC_" + self.npc_id]
            npc.pop("ownerPlayerKey", None)
            npc["affiliation"].pop("ownerPlayerKey", None)
            npc["orderSpec"].pop("ownerPlayerKey", None)

        save_path = self._variant_save("unowned.bin", mutate)
        self._assert_rejected(save_path, "not_player_faction")

    def test_warning_and_confirmation_present_in_en_and_tl(self) -> None:
        for language in ("EN", "TL"):
            with self.subTest(language=language), self._worker() as worker:
                worker.import_saved_selection(
                    self.save_path,
                    player_uuid="char_p4a",
                    npc_id=self.npc_id,
                )
                worker.set_language(language)
                opened = worker.open_conversation()
                self.assertEqual(
                    opened["presentation"]["lifecycle"]["state"],
                    "active",
                )
                disband = self._candidate(worker.snapshot(), "disband")
                self.assertIsNotNone(disband, worker.snapshot())
                warning = worker.suggestion_click(disband["frame"])
                warning_payload = self._departure_payload(warning)
                self.assertEqual(
                    warning_payload["responseKey"], "response.departure.warning"
                )
                self._message_text(warning, "response.departure.warning")
                self.assertEqual(worker.snapshot()["translation"]["language"], language)

                confirm = self._candidate(worker.snapshot(), "disband_confirm")
                self.assertIsNotNone(confirm, worker.snapshot())
                confirmed = worker.suggestion_click(confirm["frame"])
                confirmed_payload = self._departure_payload(confirmed)
                self.assertEqual(
                    confirmed_payload["responseKey"],
                    "response.departure.confirmed",
                )
                self._message_text(confirmed, "response.departure.confirmed")
                self.assertEqual(worker.snapshot()["translation"]["language"], language)


if __name__ == "__main__":
    unittest.main()
