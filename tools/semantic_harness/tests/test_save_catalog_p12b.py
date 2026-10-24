"""P12B offline save-catalog tests using the Core reader fixture format."""

from __future__ import annotations

import struct
from pathlib import Path
import tempfile
import unittest

from tools.semantic_harness.runtime.save_catalog import (
    SaveCatalog,
    SaveCatalogError,
)


def pz_string(value: str) -> bytes:
    raw = value.encode("utf-8")
    return struct.pack(">h", len(raw)) + raw


def pz_table(entries: list[tuple[object, object]]) -> bytes:
    output = [struct.pack(">i", len(entries))]
    for key, value in entries:
        if isinstance(key, str):
            output.extend((b"\x00", pz_string(key)))
        else:
            output.extend((b"\x01", struct.pack(">d", float(key))))
        if isinstance(value, str):
            output.extend((b"\x00", pz_string(value)))
        elif isinstance(value, bool):
            output.extend((b"\x03", bytes((1 if value else 0,))))
        elif isinstance(value, (int, float)):
            output.extend((b"\x01", struct.pack(">d", float(value))))
        elif isinstance(value, dict):
            output.extend((b"\x02", pz_table(list(value.items()))))
        else:
            raise TypeError(value)
    return b"".join(output)


def pz_file(
    tables: list[tuple[str, list[tuple[object, object]]]],
    *,
    world_version: int = 249,
) -> bytes:
    output = [struct.pack(">ii", world_version, len(tables))]
    for name, entries in tables:
        block = pz_string(name) + pz_table(entries)
        output.extend((struct.pack(">i", len(block)), block))
    return b"".join(output)


class SaveCatalogTests(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name) / "Saves"
        self.save_path = self.root / "Apocalypse" / "P12Slot" / "global_mod_data.bin"
        self.save_path.parent.mkdir(parents=True)

    def write_save(
        self,
        path: Path | None = None,
        *,
        world_version: int = 249,
        tables=None,
    ) -> Path:
        path = path or self.save_path
        path.parent.mkdir(parents=True, exist_ok=True)
        tables = tables or [
            ("PNC_PlayerCharacters", [("schemaVersion", 6), ("players", {})]),
            ("PNC_Core_Global", [("schemaVersion", 16)]),
            (
                "PNC_npc42",
                [("schemaVersion", 16), ("social", {"relationships": {"player": 73}})],
            ),
        ]
        path.write_bytes(
            pz_file(tables, world_version=world_version)
        )
        return path

    def catalog(self) -> SaveCatalog:
        return SaveCatalog(
            [self.root],
            core_repository=Path("/home/psychopatz/Zomboid/Workshop/psychopatzCore"),
        )

    def test_discover_reuses_core_reader_and_enumerates_required_roots(self) -> None:
        self.write_save()

        result = self.catalog().discover()

        self.assertEqual(result["schema"], "semantic.save_catalog.v1")
        self.assertEqual(len(result["saves"]), 1)
        self.assertEqual(result["rejected"], [])
        save = result["saves"][0]
        self.assertEqual(save["source"], "SAVE")
        self.assertEqual(save["mode"], "Apocalypse")
        self.assertEqual(save["saveName"], "P12Slot")
        self.assertEqual(
            {table["table"] for table in save["npcs"]},
            {"PNC_npc42"},
        )
        self.assertEqual(
            {table["name"] for table in save["tables"]},
            {"PNC_PlayerCharacters", "PNC_Core_Global", "PNC_npc42"},
        )

    def test_unsupported_and_missing_saves_are_rejected(self) -> None:
        self.write_save(world_version=248)
        missing_path = self.root / "Apocalypse" / "Missing" / "global_mod_data.bin"
        missing_path.parent.mkdir(parents=True)
        missing_path.write_bytes(
            pz_file([("PNC_Core_Global", [])])
        )

        result = self.catalog().discover()

        self.assertEqual(result["saves"], [])
        self.assertEqual(len(result["rejected"]), 2)
        reasons = " ".join(item["reason"] for item in result["rejected"])
        self.assertIn("unsupported save world version", reasons)
        self.assertIn("missing required ModData tables", reasons)

    def test_corrupt_save_fails_closed(self) -> None:
        self.save_path.write_bytes(b"not-a-global-mod-data-file")

        with self.assertRaises(SaveCatalogError):
            self.catalog().inspect(self.save_path)

    def test_discovery_orders_timestamped_saves_newest_first(self) -> None:
        older = self.root / "Apocalypse" / "2026-10-22_15-18-56" / "global_mod_data.bin"
        newer = self.root / "Sandbox" / "2026-10-24_12-26-00" / "global_mod_data.bin"
        legacy = self.root / "Apocalypse" / "Legacy" / "global_mod_data.bin"
        self.write_save(older)
        self.write_save(newer)
        self.write_save(legacy)

        result = self.catalog().discover()

        self.assertEqual(
            [entry["saveName"] for entry in result["saves"]],
            ["2026-10-24_12-26-00", "2026-10-22_15-18-56", "Legacy"],
        )

    def test_invalid_project_hoomans_schema_fails_closed(self) -> None:
        self.write_save(
            tables=[
                ("PNC_PlayerCharacters", [("schemaVersion", 6)]),
                ("PNC_Core_Global", [("schemaVersion", 999)]),
                ("PNC_npc42", [("schemaVersion", 16)]),
            ]
        )

        with self.assertRaisesRegex(SaveCatalogError, "unsupported schema"):
            self.catalog().inspect(self.save_path)


if __name__ == "__main__":
    unittest.main()
