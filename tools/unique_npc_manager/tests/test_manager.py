from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import sys

TOOLS = Path(__file__).resolve().parents[2]
if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))

from unique_npc_manager.runtime_export import (  # noqa: E402
    GENERATED_ID_MARKER,
    GENERATED_MARKER,
    export_definition_module,
    module_stem,
)
from unique_npc_manager.schema import build_payload, read_definition  # noqa: E402
from unique_npc_manager.storage import DraftStore, RuntimeDefinitionStore  # noqa: E402


SAMPLE = {
    "displayName": "Gorgon Ramsee",
    "name": "Gorgon Ramsee",
    "isFemale": False,
    "identity": {"survivor": {"forename": "Gorgon", "surname": "Ramsee"}},
    "id": "unique:gorgonramsee",
    "uniqueDefinitionId": "unique:gorgonramsee",
    "skillLevels": {"Cooking": 10},
    "startingItems": [
        {
            "type": "Base.Shirt_FormalTartan",
            "stack": 1,
            "itemState": {
                "visualColorR": 0.2,
                "visualColorG": 0.4,
                "visualColorB": 0.8,
                "modData": {"customMarker": "preserve-me"},
            },
        }
    ],
}


class ManagerTests(unittest.TestCase):
    def test_normalization_preserves_item_metadata(self) -> None:
        definition = build_payload(SAMPLE)["definition"]
        item = definition["startingItems"][0]
        self.assertEqual(item["itemState"]["modData"]["customMarker"], "preserve-me")
        self.assertNotIn("identitySeed", definition)

    def test_generated_module_imports_registrar(self) -> None:
        output = export_definition_module(SAMPLE)
        self.assertIn(GENERATED_MARKER, output)
        self.assertIn(f"{GENERATED_ID_MARKER}unique:gorgonramsee", output)
        self.assertIn('require "PNC/Generated/PNC_UniqueNPCRegistrar"', output)
        self.assertIn('["Cooking"] = 10', output)
        self.assertIn('["customMarker"] = "preserve-me"', output)

    def test_module_name_uses_canonical_survivor_name(self) -> None:
        self.assertEqual(module_stem(SAMPLE), "GorgonRamsee")

    def test_storage_crud_and_loader(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "Hoomans"
            runtime = Path(directory) / "Runtime"
            drafts = DraftStore(root)
            definitions = RuntimeDefinitionStore(runtime)

            saved = drafts.save(SAMPLE)
            self.assertTrue(saved.exists())
            loaded = drafts.load(saved.name)
            normalized = build_payload(loaded)["definition"]
            generated = definitions.export(normalized)
            self.assertTrue(generated.exists())
            loader = runtime / "PNC_UniqueNPCDefinitions.lua"
            self.assertIn(module_stem(normalized), loader.read_text(encoding="utf-8"))

            backup = definitions.delete(normalized)
            self.assertTrue(backup.exists())
            drafts.delete(saved.name)
            self.assertFalse(saved.exists())

    def test_legacy_module_is_migrated_and_duplicate_names_are_safe(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            runtime = Path(directory) / "Runtime"
            definitions = RuntimeDefinitionStore(runtime)
            legacy = runtime / "unique_unique_x3agorgonramsee.lua"
            legacy.write_text(
                export_definition_module(SAMPLE).replace(
                    f"{GENERATED_ID_MARKER}unique:gorgonramsee\n", ""
                ),
                encoding="utf-8",
            )

            first = definitions.export(SAMPLE)
            self.assertEqual(first.name, "GorgonRamsee.lua")
            self.assertFalse(legacy.exists())
            self.assertTrue(any((runtime / ".trash").iterdir()))

            duplicate = dict(SAMPLE)
            duplicate["id"] = "unique:othergorgon"
            duplicate["uniqueDefinitionId"] = "unique:othergorgon"
            second = definitions.export(duplicate)
            self.assertEqual(second.name, "GorgonRamsee__uniqueothergorgon.lua")
            loader = runtime / "PNC_UniqueNPCDefinitions.lua"
            loader_text = loader.read_text(encoding="utf-8")
            self.assertIn('GorgonRamsee"', loader_text)
            self.assertIn('GorgonRamsee__uniqueothergorgon"', loader_text)

    def test_real_creator_file_can_be_loaded_when_present(self) -> None:
        path = Path.home() / "Zomboid" / "Lua" / "Hoomans" / "RobertFurhrer.txt"
        if not path.exists():
            self.skipTest("local Hoomans sample is unavailable")
        definition = build_payload(read_definition(path))["definition"]
        self.assertEqual(definition["identity"]["survivor"]["forename"], "Robert")
        self.assertGreaterEqual(len(definition.get("startingItems", [])), 1)


if __name__ == "__main__":
    unittest.main()
