"""P12J save-backed Talk and semantic workflow acceptance coverage."""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path
import tempfile
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.tests.test_save_catalog_p12b import pz_file


CORE_REPOSITORY = Path("/home/psychopatz/Zomboid/Workshop/psychopatzCore")


class SaveBackedConversationP12JTests(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.save_path = Path(self.directory.name) / "global_mod_data.bin"
        player_key = "player:slot_saved:char_saved"
        relationship = {
            "baselineApproval": 91,
            "baselineRespect": 88,
            "approval": 96,
            "respect": 94,
            "familiarity": 100,
            "state": "friend",
            "previousState": "acquaintance",
            "bond": {"class": "friend", "establishedAt": 3},
            "memories": {},
            "saturation": {},
            "cooldowns": {},
            "interactionJournal": {"revision": 4},
            "interactionRevision": 4,
            "revision": 7,
        }
        saved_inventory = {
            "revision": 4,
            "items": {
                "saved_apple": {
                    "itemID": "saved_apple",
                    "fullType": "Base.Apple",
                    "displayName": "Saved Apple",
                    "stack": 2,
                }
            },
            "containers": {},
        }
        tables = [
            (
                "PNC_PlayerCharacters",
                [
                    ("schemaVersion", 6),
                    (
                        "byUUID",
                        {
                            "char_saved": {
                                "uuid": "char_saved",
                                "accountKey": "slot_saved",
                                "forename": "Saved",
                                "surname": "Player",
                                "displayName": "Saved Player",
                                "gender": "male",
                                "status": "active",
                                "socialProfile": {
                                    "orientation": "bisexual",
                                    "romanceStyle": "flirty",
                                },
                                "inventory": saved_inventory,
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
                            "faction_saved": {
                                "id": "faction_saved",
                                "name": "Saved Fellowship",
                                "memberIDs": {"npcSaved": True},
                            }
                        },
                    ),
                ],
            ),
            (
                "PNC_Communities",
                [
                    ("schemaVersion", 3),
                    (
                        "byID",
                        {
                            "community_saved": {
                                "id": "community_saved",
                                "name": "Saved Camp",
                                "memberIDs": {"npcSaved": True},
                            }
                        },
                    ),
                ],
            ),
            (
                "PNC_npcSaved",
                [
                    ("schemaVersion", 16),
                    ("recordRevision", 7),
                    ("id", "npcSaved"),
                    ("tacticalClass", "neutral"),
                    (
                        "identity",
                        {
                            "displayName": "Saved Companion",
                            "isFemale": True,
                            "archetypeID": "General",
                            "seed": 90210,
                            "survivor": {
                                "forename": "Saved",
                                "surname": "Companion",
                            },
                        },
                    ),
                    ("orderSpec", {"kind": "roam"}),
                    ("hostility", {"mode": "neutral", "attackPlayers": False}),
                    (
                        "affiliation",
                        {
                            "factionID": "faction_saved",
                            "communityID": "community_saved",
                            "membershipStatus": "member",
                        },
                    ),
                    ("inventory", {"revision": 2, "items": {}, "containers": {}}),
                    (
                        "social",
                        {
                            "personality": {
                                "orientation": "bisexual",
                                "romanceStyle": "flirty",
                            },
                            "relationships": {player_key: relationship},
                        },
                    ),
                ],
            ),
            (
                "PNC_npcTrader",
                [
                    ("schemaVersion", 16),
                    ("id", "npcTrader"),
                    ("tacticalClass", "neutral"),
                    (
                        "identity",
                        {
                            "displayName": "Saved Trader",
                            "isFemale": True,
                            "archetypeID": "General",
                            "seed": 90211,
                        },
                    ),
                    ("orderSpec", {"kind": "roam"}),
                    ("hostility", {"mode": "neutral", "attackPlayers": False}),
                    ("affiliation", {"originArchetypeID": "trader"}),
                    ("generation", {"source": "dynamic_trading"}),
                    ("social", {"relationships": {player_key: {}}}),
                ],
            ),
        ]
        self.save_path.write_bytes(pz_file(tables))

    @staticmethod
    def _candidate(snapshot: dict, candidate_id: str) -> dict | None:
        suggestions = snapshot.get("suggestions") or {}
        rows = list(suggestions.get("candidates") or [])
        for group in suggestions.get("groups") or []:
            rows.extend(group.get("candidates") or [])
        return next(
            (row for row in rows if row.get("id") == candidate_id),
            None,
        )

    def _worker(self) -> LuaSemanticWorker:
        return LuaSemanticWorker(
            merge({}, DEFAULT_SCENARIO),
            core_repository=CORE_REPOSITORY,
        )

    def test_saved_pair_runs_talk_semantics_graph_replay_and_compare(self) -> None:
        with self._worker() as worker:
            imported = worker.import_saved_selection(
                self.save_path,
                player_uuid="char_saved",
                npc_id="npcSaved",
            )
            source_before = deepcopy(worker.source_snapshot.to_dict())
            scenario = imported["scenario"]
            self.assertEqual(
                imported["sourceSnapshot"]["metadata"]["sourceKind"], "SAVE"
            )
            self.assertEqual(scenario["player"]["entityKey"], "player:slot_saved:char_saved")
            self.assertEqual(scenario["npc"]["tacticalClass"], "neutral")
            self.assertFalse(scenario["npc"]["actorAuthority"]["owned"])
            self.assertEqual(scenario["player"]["inventory"]["revision"], 4)
            self.assertEqual(
                imported["sourceSnapshot"]["provenance"]["paths"][
                    "npc.inventory"
                ]["source"],
                "SAVE",
            )

            talk = worker.talk_start("current", "who are you")
            self.assertEqual(talk["type"], "talk_start")
            self.assertEqual(talk["start"]["target"]["tacticalClass"], "neutral")
            self.assertEqual(talk["start"]["route"], "full_conversation")
            self.assertIn("conversationGraph", talk["snapshot"])

            identity = worker.input("who are you")
            self.assertEqual(identity["type"], "turn")
            self.assertIn("relationshipAfter", identity)
            inventory = worker.input("what do you have")
            self.assertEqual(inventory["result"]["ir"]["subject"], "INVENTORY")

            snapshot = worker.snapshot()
            relationship = snapshot["scenario"]["npc"]["relationship"]
            self.assertEqual(relationship["baselineApproval"], 91)
            self.assertEqual(relationship["interactionRevision"], 4)
            self.assertEqual(snapshot["scenario"]["npc"]["factionID"], "faction_saved")
            self.assertEqual(snapshot["scenario"]["npc"]["communityID"], "community_saved")

            graph = worker.conversation_graph()
            self.assertEqual(graph["type"], "conversation_graph")
            self.assertTrue(talk["snapshot"].get("conversationGraph"))
            baseline = worker.capture_baseline("how are you doing?")
            replay = worker.apply_and_replay("how are you doing?")
            compare = worker.context_matrix(
                [deepcopy(worker.scenario)], text="how are you doing?", maximum=1
            )
            self.assertEqual(baseline["schema"], "semantic.persona.baseline.v1")
            self.assertEqual(replay["schema"], "semantic.persona.apply_replay.v1")
            self.assertEqual(compare["schema"], "semantic.persona.matrix.v1")

            knowledge = worker.knowledge_bootstrap("p12j-saved-pair")
            metrics = worker.knowledge_metrics()
            self.assertEqual(knowledge["type"], "knowledge_bootstrap")
            self.assertEqual(metrics["type"], "knowledge_metrics")
            self.assertEqual(worker.source_snapshot.to_dict(), source_before)

    def test_saved_pair_uses_normal_proposal_recruitment_and_trader_overlay(self) -> None:
        with self._worker() as worker:
            worker.import_saved_selection(
                self.save_path,
                player_uuid="char_saved",
                npc_id="npcSaved",
            )
            proposal = self._candidate(
                worker.snapshot(), "social.relationship_proposal"
            )
            self.assertIsNotNone(proposal)
            clicked = worker.suggestion_click(proposal["frame"])
            self.assertIn(clicked.get("accepted"), {True, False})
            self.assertEqual(
                clicked.get("result", {}).get("actionResult", {}).get("action"),
                "RELATIONSHIP_PROPOSAL",
            )
            self.assertEqual(
                clicked.get("result", {}).get("actionResult", {}).get("status"),
                "relationship_proposal_applied",
            )
            self.assertEqual(
                worker.snapshot()["scenario"]["npc"]["relationship"]["bond"]["class"],
                "lover",
            )
            self.assertEqual(
                worker.snapshot()["sourceSnapshot"]["metadata"]["sourceKind"],
                "SAVE",
            )

        with self._worker() as worker:
            worker.import_saved_selection(
                self.save_path,
                player_uuid="char_saved",
                npc_id="npcSaved",
            )
            recruitment = worker.input("Would you like to join us?")
            self.assertEqual(recruitment["type"], "turn")
            self.assertEqual(
                recruitment.get("result", {}).get("actionResult", {}).get("action"),
                "RECRUIT",
            )
            self.assertTrue(worker.snapshot()["scenario"]["npc"]["recruited"])

        with self._worker() as worker:
            worker.import_saved_selection(
                self.save_path,
                player_uuid="char_saved",
                npc_id="npcTrader",
            )
            trader_talk = worker.talk_start("current", "hello")
            integration = trader_talk["start"]["integration"]
            self.assertTrue(integration["traderOverlay"]["enabled"])
            self.assertEqual(
                integration["traderOverlay"]["providerID"],
                "dynamictrading.trader",
            )
            self.assertTrue(integration["dynamicTrading"]["loaded"])


if __name__ == "__main__":
    unittest.main()
