"""P13B native offline Player engine-state provider acceptance."""

from __future__ import annotations

import hashlib
from pathlib import Path
import sqlite3
import tempfile
import unittest

from tools.semantic_harness.runtime.player_engine_state import (
    OfflinePlayerEngineStateProvider,
    PLAYER_WORLD_VERSION,
)
from tools.semantic_harness.runtime.save_catalog import SaveCatalog
from tools.semantic_harness.runtime.save_import import SaveBackedImporter


CORE_REPOSITORY = Path("/home/psychopatz/Zomboid/Workshop/psychopatzCore")


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class PlayerEngineStateP13BTests(unittest.TestCase):
    def _real_save(self) -> tuple[Path, dict]:
        provider = OfflinePlayerEngineStateProvider()
        for path in sorted(Path.home().joinpath("Zomboid", "Saves").rglob("global_mod_data.bin")):
            result = provider.project(path)
            if (
                result.get("available")
                and result.get("playerUUID")
                and result.get("inventory", {}).get("items")
            ):
                return path, result
        self.skipTest("no compatible real Build 42.20 save with native Player inventory")

    def test_real_save_exposes_native_player_inventory_read_only(self) -> None:
        save_path, result = self._real_save()
        save_root = save_path.parent
        tracked = [
            save_path,
            save_root / "players.db",
            save_root / "WorldDictionaryReadable.lua",
        ]
        before = {path: _sha256(path) for path in tracked}

        self.assertEqual(result["source"], "SAVE")
        self.assertEqual(result["worldVersion"], PLAYER_WORLD_VERSION)
        self.assertEqual(result["provenance"]["table"], "players.db.localPlayers")
        self.assertGreater(len(result["inventory"]["items"]), 0)
        self.assertTrue(all(item["source"] == "SAVE" for item in result["inventory"]["items"]))

        after = {path: _sha256(path) for path in tracked}
        self.assertEqual(before, after)

    def test_importer_uses_native_inventory_for_real_player(self) -> None:
        save_path, native = self._real_save()
        candidate = SaveCatalog(core_repository=CORE_REPOSITORY).inspect(save_path)
        selection = SaveBackedImporter(
            core_repository=CORE_REPOSITORY,
        ).load(save_path, player_uuid=native["playerUUID"], npc_id=candidate.npc_tables[0][4:])

        self.assertEqual(selection.scenario["player"]["characterUUID"], native["playerUUID"])
        self.assertEqual(
            selection.scenario["player"]["inventory"]["items"],
            native["inventory"]["items"],
        )
        self.assertEqual(
            selection.provenance["paths"]["player.inventory"]["source"],
            "SAVE",
        )
        self.assertEqual(
            selection.provenance["paths"]["player.inventory"]["table"],
            "players.db.localPlayers",
        )
        self.assertTrue(selection.provider_payloads["ProjectZomboid"]["available"])

    def test_unsupported_native_world_version_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            db = root / "players.db"
            dictionary = root / "WorldDictionaryReadable.lua"
            dictionary.write_text(
                'items = {\n'
                '\t{\n'
                '\t\tregistryID = 1,\n'
                '\t\tfulltype = "Base.Apple",\n'
                '\t},\n'
                '}\n',
                encoding="utf-8",
            )
            connection = sqlite3.connect(db)
            try:
                connection.execute(
                    "CREATE TABLE localPlayers ("
                    "id INTEGER PRIMARY KEY, name STRING, wx INTEGER, wy INTEGER, "
                    "x FLOAT, y FLOAT, z FLOAT, worldversion INTEGER, data BLOB, isDead BOOLEAN)"
                )
                connection.execute(
                    "INSERT INTO localPlayers VALUES (1, 'Saved Player', 0, 0, 0, 0, 0, 248, ?, 0)",
                    (b"unsupported",),
                )
                connection.commit()
            finally:
                connection.close()
            before = _sha256(db)

            result = OfflinePlayerEngineStateProvider().project(root, player_uuid="char_saved")

            self.assertFalse(result["available"])
            self.assertEqual(result["source"], "MISSING")
            self.assertIn("unsupported native Player world version", result["reason"])
            self.assertEqual(_sha256(db), before)


if __name__ == "__main__":
    unittest.main()
