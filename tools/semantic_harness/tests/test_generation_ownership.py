"""Cross-repository CodeBuilder ownership routing acceptance."""

from __future__ import annotations

import shutil
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.build import (
    DEFAULT_OUTPUT,
    default_lexicon_output,
    write_conversation_output,
)
from tools.semantic_harness.codebuilder.conversation_compiler import (
    CONVERSATION_SOURCE_RELATIVE,
    compile_conversation_sources,
    render_conversation_runtime_plan,
)


REPOSITORY = Path(__file__).resolve().parents[3]


class GenerationOwnershipTests(unittest.TestCase):
    def test_generic_parser_shards_route_to_core_namespace(self) -> None:
        model = compile_conversation_sources(REPOSITORY, runtime_root=REPOSITORY)
        modules, reports = render_conversation_runtime_plan(model)
        by_source = {
            report.get("sourceShard"): (module, report)
            for (module, _source), report in zip(modules, reports)
            if report.get("sourceShard")
        }

        module, report = by_source["patterns/common/identity.json"]
        self.assertEqual(report["owner"], "PsychopatzCore")
        self.assertTrue(
            module.startswith(
                "PsychopatzCore/Semantics/Generated/Conversation/Patterns/Common/"
            ),
            module,
        )

        module, report = by_source["content/command/player.json"]
        self.assertEqual(report["owner"], "ProjectHoomans")
        self.assertTrue(module.startswith("PNC/Semantics/Generated/Conversation/"), module)

    def test_writer_places_core_and_hoomans_modules_in_separate_repositories(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            hoomans = root / "ProjectHoomans"
            core = root / "psychopatzCore"
            shutil.copytree(
                REPOSITORY / CONVERSATION_SOURCE_RELATIVE,
                hoomans / CONVERSATION_SOURCE_RELATIVE,
            )
            model = compile_conversation_sources(
                hoomans,
                runtime_root=REPOSITORY,
            )
            paths = write_conversation_output(
                hoomans,
                model,
                core_repository=core,
            )

            core_identity = (
                core
                / "Contents/mods/PsychopatzCore/common/media/lua/shared/"
                / "PsychopatzCore/Semantics/Generated/Conversation/"
                / "Patterns/Common/Identity.lua"
            )
            stale_hoomans_identity = (
                hoomans
                / "Contents/mods/ProjectHoomans/common/media/lua/shared/"
                / "PNC/Semantics/Generated/Conversation/Patterns/Common/Identity.lua"
            )
            hoomans_content = (
                hoomans
                / "Contents/mods/ProjectHoomans/common/media/lua/shared/"
                / "PNC/Semantics/Generated/Conversation/Content/Command/Player.lua"
            )
            registry = (
                hoomans
                / "Contents/mods/ProjectHoomans/common/media/lua/shared/"
                / "PNC/Semantics/Generated/Conversation/Registry.lua"
            )

            self.assertTrue(core_identity.is_file())
            self.assertFalse(stale_hoomans_identity.exists())
            self.assertTrue(hoomans_content.is_file())
            self.assertIn(core_identity, paths)
            registry_text = registry.read_text(encoding="utf-8")
            self.assertIn(
                'require "PsychopatzCore/Semantics/Generated/Conversation/'
                'Patterns/Common/Identity"',
                registry_text,
            )

    def test_default_lexicon_output_is_core_owned(self) -> None:
        self.assertIn(
            "Contents/mods/PsychopatzCore/common/media/lua/shared/"
            "PsychopatzCore/Semantics/Generated/Lexicon/Catalog.lua",
            DEFAULT_OUTPUT.as_posix(),
        )

        custom = Path("/tmp/custom-core")
        self.assertTrue(
            default_lexicon_output(custom).is_relative_to(custom),
            default_lexicon_output(custom),
        )


if __name__ == "__main__":
    unittest.main()
