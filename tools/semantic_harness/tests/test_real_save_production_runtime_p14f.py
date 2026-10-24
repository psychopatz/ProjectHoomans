"""P14F real-save production-runtime regression matrix."""

from __future__ import annotations

from copy import deepcopy
import hashlib
import io
import json
from pathlib import Path
import unittest
from contextlib import redirect_stdout

from tools.semantic_harness.cli import _parser, cli
from tools.semantic_harness.inspection.conversation_inspector import (
    build_conversation_inspector,
)
from tools.semantic_harness.runtime.save_import import SaveBackedImporter
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


CORE_REPOSITORY = Path("/home/psychopatz/Zomboid/Workshop/psychopatzCore")
REAL_SAVE = Path(
    "/home/psychopatz/Zomboid/Saves/Apocalypse/"
    "2026-10-14_13-57-03/global_mod_data.bin"
)


def _layer_signature(value: dict) -> dict:
    return {
        key: deepcopy(value.get(key))
        for key in (
            "personalRelationship",
            "factionRelationship",
            "tacticalHostility",
            "conversationAudience",
            "durableBond",
            "speechStyle",
        )
    }


class RealSaveProductionRuntimeP14FTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        if not REAL_SAVE.is_file():
            raise unittest.SkipTest("real local save is unavailable")
        cls.importer = SaveBackedImporter(core_repository=CORE_REPOSITORY)
        cls.reference = cls.importer.load(
            REAL_SAVE,
            npc_id="npcWilberDowns_R4XY",
        )
        registries = cls.reference.provider_payloads["ProjectHoomans"][
            "rawRegistries"
        ]
        factions = registries["factions"]["byID"]
        cls.player_faction_id = registries["factions"]["byPlayerKey"][
            cls.reference.player_entity_key
        ]
        cls.relation_present_npc = None
        for faction_id, faction in factions.items():
            if faction_id == cls.player_faction_id:
                continue
            if cls.player_faction_id not in (faction.get("relations") or {}):
                continue
            members = list((faction.get("memberIDs") or {}).keys())
            if members:
                cls.relation_present_npc = members[0]
                break
        if cls.relation_present_npc is None:
            raise unittest.SkipTest("real save has no directed faction relation")

    def _cli_social(self, npc_id: str, player_uuid: str) -> dict:
        arguments = _parser().parse_args(
            [
                "--no-gui",
                "--jsonl",
                "--save",
                str(REAL_SAVE),
                "--player",
                player_uuid,
                "--npc",
                npc_id,
                "--load-saved-pair",
                "--inspect-social-context",
            ]
        )
        output = io.StringIO()
        with redirect_stdout(output):
            self.assertEqual(cli(arguments), 0)
        rows = [
            json.loads(line)
            for line in output.getvalue().splitlines()
            if line.strip()
        ]
        inspection = next(
            row for row in rows if row.get("type") == "actor_inspection"
        )
        return inspection["socialContext"]

    def _exercise_actor(
        self,
        npc_id: str,
        *,
        expect_audience: str,
        expect_personal: str | None,
        expect_trader: bool = False,
        expect_faction_relation: bool | None = None,
        gift: bool = False,
    ) -> None:
        selection = self.importer.load(REAL_SAVE, npc_id=npc_id)
        raw = selection.provider_payloads["ProjectHoomans"]["rawRecords"][
            "npc"
        ]
        self.assertEqual(
            selection.provenance["paths"]["npc.inventory"]["source"],
            "SAVE",
        )
        self.assertEqual(
            raw["inventory"][1],
            "BASELINE_DELTA",
        )
        relationship = raw.get("social", {}).get("relationships", {})
        if expect_personal is not None:
            self.assertEqual(
                bool(relationship.get(selection.player_entity_key)),
                expect_personal != "unknown",
            )

        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            imported = worker.import_saved_selection(REAL_SAVE, npc_id=npc_id)
            source_snapshot = deepcopy(worker.source_snapshot.to_dict())
            self.assertEqual(imported["productionRehydration"]["status"], "HYDRATED")
            self.assertEqual(
                imported["productionRehydration"]["inventoryMode"],
                "BASELINE_DELTA",
            )
            self.assertGreater(
                imported["productionRehydration"]["inventoryItemCount"],
                0,
            )
            self.assertEqual(
                imported["context"]["socialContext"]["conversationAudience"][
                    "audience"
                ],
                expect_audience,
            )
            if expect_personal is not None:
                self.assertEqual(
                    imported["context"]["socialContext"][
                        "personalRelationship"
                    ]["state"],
                    expect_personal,
                )
            if expect_faction_relation is not None:
                faction = imported["context"]["socialContext"][
                    "factionRelationship"
                ]
                if expect_faction_relation:
                    self.assertEqual(
                        faction["effective"]["source"],
                        "PNC.Factions.GetRelation",
                    )
                    self.assertNotEqual(
                        faction["effective"]["state"],
                        "unknown",
                    )
                else:
                    self.assertEqual(
                        faction["effective"]["state"],
                        "unknown",
                    )
            self.assertEqual(
                imported["scenario"]["npc"].get("role") == "trader",
                expect_trader,
            )

            baseline = worker.inspect_actor_state()["scenario"]
            talk = worker.talk_start("current", "hello")
            self.assertEqual(talk["type"], "talk_start")
            self.assertEqual(
                talk["start"]["target"]["audience"],
                expect_audience,
            )
            hello = worker.input("hello")
            hello_social = hello["contextAfter"]["socialContext"]
            self.assertEqual(
                hello_social["conversationAudience"]["audience"],
                expect_audience,
            )
            if expect_personal is not None:
                self.assertEqual(
                    hello_social["personalRelationship"]["state"],
                    expect_personal,
                )
            inspector = build_conversation_inspector(hello)
            self.assertEqual(
                _layer_signature(inspector["socialContext"]),
                _layer_signature(hello_social),
            )

            if gift:
                gift_result = worker.input("here's 1 Bandage for you")
                action = (gift_result.get("result") or {}).get(
                    "actionResult"
                ) or {}
                self.assertEqual(action.get("action"), "GIFT")

            worker.reset_working_world()
            restored = worker.inspect_actor_state()["scenario"]
            self.assertEqual(restored["npc"], baseline["npc"])
            self.assertEqual(restored["player"], baseline["player"])
            self.assertEqual(
                worker.source_snapshot.to_dict(),
                source_snapshot,
            )

        self.assertEqual(
            hashlib.sha256(REAL_SAVE.read_bytes()).digest(),
            self.source_hash,
        )

    def setUp(self) -> None:
        self.source_hash = hashlib.sha256(REAL_SAVE.read_bytes()).digest()

    def test_real_saved_actor_matrix_and_reset(self) -> None:
        self._exercise_actor(
            "npcKentLangley_OWOJ",
            expect_audience="member",
            expect_personal="friend",
            gift=True,
        )
        self._exercise_actor(
            "npcAdrianMedina_8J7W",
            expect_audience="neutral",
            expect_personal="unknown",
            expect_faction_relation=False,
        )
        self._exercise_actor(
            "npcBarneyYamamoto_2OXA",
            expect_audience="hostile",
            expect_personal="unknown",
        )
        self._exercise_actor(
            "npcBrendonOakes_2ZOW",
            expect_audience="neutral",
            expect_personal="unknown",
            expect_trader=True,
        )
        self._exercise_actor(
            self.relation_present_npc,
            expect_audience="neutral",
            expect_personal=None,
            expect_trader=True,
            expect_faction_relation=True,
        )

    def test_cli_matches_worker_social_context_for_real_saved_hostile(self) -> None:
        selection = self.importer.load(
            REAL_SAVE,
            npc_id="npcBarneyYamamoto_2OXA",
        )
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            imported = worker.import_saved_selection(
                REAL_SAVE,
                player_uuid=selection.player_uuid,
                npc_id="npcBarneyYamamoto_2OXA",
            )
            worker_social = imported["context"]["socialContext"]
            worker.talk_start("current", "hello")
            gui_social = build_conversation_inspector(
                worker.input("hello")
            )["socialContext"]
        cli_social = self._cli_social(
            "npcBarneyYamamoto_2OXA",
            selection.player_uuid,
        )
        self.assertEqual(
            _layer_signature(cli_social),
            _layer_signature(worker_social),
        )
        self.assertEqual(
            _layer_signature(cli_social),
            _layer_signature(gui_social),
        )

    def test_production_dossier_and_interaction_history_are_explicitly_rehydratable(
        self,
    ) -> None:
        """Large player-scoped knowledge stays on the explicit inspector path."""

        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            imported = worker.import_saved_selection(
                REAL_SAVE,
                player_uuid="char_1791957489838_240087",
                npc_id="npcKentLangley_OWOJ",
            )
            self.assertEqual(
                imported["productionKnowledgeRehydration"]["status"],
                "HYDRATED",
            )
            source_snapshot = deepcopy(worker.source_snapshot.to_dict())

            before = worker.inspect_npc_dossier()
            dossier_before = before["npcDossier"]
            history_before = before["relationshipHistory"]
            self.assertEqual(dossier_before["status"], "HYDRATED")
            self.assertEqual(history_before["status"], "HYDRATED")
            self.assertEqual(
                dossier_before["snapshot"]["npcID"],
                "npcKentLangley_OWOJ",
            )
            self.assertGreater(
                len(history_before["snapshot"].get("interactionJournal") or []),
                0,
            )
            journal_before = len(
                history_before["snapshot"].get("interactionJournal") or []
            )

            insult = worker.input("fuck you")
            action = (insult.get("result") or {}).get("actionResult") or {}
            self.assertEqual(action.get("eventType"), "player_dialogue_insult")

            after = worker.inspect_npc_dossier()
            journal_after = after["relationshipHistory"]["snapshot"].get(
                "interactionJournal"
            ) or []
            self.assertGreater(len(journal_after), journal_before)
            self.assertEqual(
                journal_after[-1].get("eventType")
                or journal_after[-1].get("kind"),
                "player_dialogue_insult",
            )

            worker.reset_working_world()
            reset = worker.inspect_npc_dossier()
            self.assertEqual(
                reset["npcDossier"],
                dossier_before,
            )
            self.assertEqual(
                reset["relationshipHistory"],
                history_before,
            )
            self.assertEqual(worker.source_snapshot.to_dict(), source_snapshot)

        self.assertEqual(
            hashlib.sha256(REAL_SAVE.read_bytes()).digest(),
            self.source_hash,
        )


if __name__ == "__main__":
    unittest.main()
