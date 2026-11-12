"""Cross-repository CodeBuilder ownership routing acceptance."""

from __future__ import annotations

import json
import shutil
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.build import (
    DEFAULT_OUTPUT,
    _write_routed_modules,
    default_lexicon_output,
    write_conversation_output,
)
from tools.semantic_harness.codebuilder.conversation_compiler import (
    CONVERSATION_SOURCE_RELATIVE,
    compile_conversation_sources,
    conversation_translation_catalogs_by_owner,
    render_conversation_runtime_plan,
)
from tools.semantic_harness.codebuilder.generation_ownership import (
    CORE_OWNER,
    DT_COMMON_OWNER,
    HOOMANS_OWNER,
    OwnerConfigurationError,
    module_owner,
    module_target,
    normalize_owner,
    owner_repository,
    package_descriptor,
    resolve_core_repository,
    shared_lua_root,
    translation_root,
)


REPOSITORY = Path(__file__).resolve().parents[4]
CORE_REPOSITORY = REPOSITORY.parent / "psychopatzCore"
PNC_PSDL_DIALOGUE_RELATIVE = Path(
    "tools/providers/pnc/codebuilder/sources/conversation/psdl/dialogue"
)


def copy_pnc_psdl_sources(repository: Path) -> None:
    target = repository / PNC_PSDL_DIALOGUE_RELATIVE
    target.mkdir(parents=True, exist_ok=True)
    source_root = REPOSITORY / PNC_PSDL_DIALOGUE_RELATIVE
    for source in source_root.glob("*.json"):
        shutil.copy2(source, target / source.name)


class GenerationOwnershipTests(unittest.TestCase):
    def test_package_owners_are_explicit_and_unknown_values_fail_closed(self) -> None:
        self.assertEqual(normalize_owner("core"), "PsychopatzCore")
        self.assertEqual(normalize_owner("dynamic-trading"), DT_COMMON_OWNER)
        self.assertEqual(
            normalize_owner(None, default=HOOMANS_OWNER),
            HOOMANS_OWNER,
        )
        self.assertEqual(
            package_descriptor(DT_COMMON_OWNER).registry_namespace,
            "DTCommon.Semantics.ConversationRegistry",
        )
        with self.assertRaises(OwnerConfigurationError):
            normalize_owner("some-unregistered-addon")
        with self.assertRaises(OwnerConfigurationError):
            normalize_owner(None)

    def test_three_package_routes_use_their_own_repository_and_prefix(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            hoomans = root / "ProjectHoomans"
            core = root / "psychopatzCore"
            dynamic_trading = root / "DynamicTrading"

            self.assertEqual(
                shared_lua_root(hoomans, "ProjectHoomans"),
                hoomans / "Contents/mods/ProjectHoomans/common/media/lua/shared",
            )
            self.assertEqual(
                shared_lua_root(hoomans, "core", core_repository=core),
                core / "Contents/mods/PsychopatzCore/common/media/lua/shared",
            )
            self.assertEqual(
                translation_root(
                    hoomans,
                    DT_COMMON_OWNER,
                    dynamic_trading_repository=dynamic_trading,
                ),
                dynamic_trading / "Contents/mods/DTCommon/common/media/translation",
            )

            dt_module = (
                "DTCommon/Semantics/Generated/Conversation/Trader/Offer"
            )
            repository, target = module_target(
                hoomans,
                dt_module,
                dynamic_trading_repository=dynamic_trading,
            )
            self.assertEqual(repository, dynamic_trading.resolve())
            self.assertEqual(
                target,
                dynamic_trading
                / "Contents/mods/DTCommon/common/media/lua/shared"
                / (dt_module + ".lua"),
            )
            with self.assertRaises(OwnerConfigurationError):
                owner_repository(hoomans, DT_COMMON_OWNER)

    def test_module_owner_does_not_guess_project_hoomans_for_unknown_modules(self) -> None:
        self.assertEqual(
            module_owner("DTCommon/Semantics/Generated/Conversation/Registry"),
            DT_COMMON_OWNER,
        )
        with self.assertRaises(OwnerConfigurationError):
            module_owner("PNC/SomeOtherGeneratedModule")

    def test_writer_routes_synthetic_dtcommon_module_to_dynamic_trading(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            hoomans = root / "ProjectHoomans"
            dynamic_trading = root / "DynamicTrading"
            module = "DTCommon/Semantics/Generated/Conversation/Trader/Offer"
            paths = _write_routed_modules(
                hoomans,
                None,
                dynamic_trading,
                [(module, "return true\n")],
            )
            expected = (
                dynamic_trading
                / "Contents/mods/DTCommon/common/media/lua/shared"
                / (module + ".lua")
            )
            self.assertEqual(paths, [expected])
            self.assertEqual(expected.read_text(encoding="utf-8"), "return true\n")

    def test_generic_parser_shards_route_to_core_namespace(self) -> None:
        model = compile_conversation_sources(
            REPOSITORY,
            runtime_root=REPOSITORY,
            package_repositories={"DTCommon": REPOSITORY.parent / "DynamicTrading"},
        )
        modules, reports = render_conversation_runtime_plan(model)
        by_source = {
            (report.get("sourceShard"), report.get("kind")): (module, report)
            for (module, _source), report in zip(modules, reports)
            if report.get("sourceShard")
        }

        module, report = by_source[("patterns/common/identity.json", "Patterns")]
        self.assertEqual(report["owner"], CORE_OWNER)
        self.assertEqual(report["shardOwner"], CORE_OWNER)
        self.assertEqual(report["registryOwner"], "ProjectHoomans")
        self.assertEqual(report["sourceOwner"], CORE_OWNER)
        self.assertEqual(
            Path(report["sourceRepository"]),
            resolve_core_repository(REPOSITORY, runtime_root=REPOSITORY),
        )
        self.assertEqual(
            report["sourcePath"],
            "tools/semantic_harness/codebuilder/sources/conversation/"
            "patterns/common/identity.json",
        )
        self.assertTrue(
            module.startswith(
                "PsychopatzCore/Semantics/Generated/Conversation/Patterns/Common/"
            ),
            module,
        )

        _, facet_report = by_source[("patterns/common/identity_facets.json", "Patterns")]
        self.assertEqual(facet_report["owner"], CORE_OWNER)
        self.assertEqual(facet_report["registryOwner"], "ProjectHoomans")
        self.assertEqual(facet_report["sourceOwner"], CORE_OWNER)

        pack_module, pack_report = by_source[("psdl/dialogue/trading.json", "Packs")]
        self.assertEqual(pack_report["owner"], "DTCommon")
        self.assertEqual(pack_report["kind"], "Packs")
        self.assertTrue(
            pack_module.startswith(
                "DTCommon/Semantics/Generated/Conversation/Packs/Psdl/Dialogue/"
            ),
            pack_module,
        )

        module, report = by_source[
            ("psdl/dialogue/companion_commands_player.json", "PSDL")
        ]
        self.assertEqual(report["owner"], "ProjectHoomans")
        self.assertTrue(module.startswith("PNC/Semantics/Generated/Conversation/"), module)

    def test_dtcommon_registry_fixture_uses_package_namespace_and_paths(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            hoomans = root / "ProjectHoomans"
            core = root / "psychopatzCore"
            dynamic_trading = root / "DynamicTrading"
            source_root = hoomans / CONVERSATION_SOURCE_RELATIVE
            shutil.copytree(CORE_REPOSITORY / CONVERSATION_SOURCE_RELATIVE, source_root)
            copy_pnc_psdl_sources(hoomans)

            manifest_path = source_root / "manifest.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            manifest["registryOwner"] = "DTCommon"
            routed_paths = {
                "patterns/common/greeting_whats_up.json",
                "content/greeting.json",
                "behaviors/social",
            }
            for entry in [*manifest["shards"], *manifest["sourceRoots"]]:
                if entry["path"] not in routed_paths:
                    continue
                entry["owner"] = "DTCommon"
                shard_paths = [source_root / entry["path"]]
                if entry["path"] == "behaviors/social":
                    shard_paths = sorted(
                        (source_root / entry["path"]).glob("*.json")
                    )
                for shard_path in shard_paths:
                    shard = json.loads(shard_path.read_text(encoding="utf-8"))
                    shard["owner"] = "DTCommon"
                    profile_id = shard.get("sourceProfile") or entry.get("sourceProfile")
                    if profile_id in manifest["sourceProfiles"]:
                        manifest["sourceProfiles"][profile_id]["owner"] = "DTCommon"
                    shard_path.write_text(
                        json.dumps(shard, indent=2) + "\n",
                        encoding="utf-8",
                    )
            manifest_path.write_text(
                json.dumps(manifest, indent=2) + "\n",
                encoding="utf-8",
            )

            model = compile_conversation_sources(
                hoomans,
                runtime_root=REPOSITORY,
                package_repositories={
                    "DTCommon": REPOSITORY.parent / "DynamicTrading"
                },
            )
            behavior_record = next(
                item
                for item in model["behaviors"]
                if item["id"] == "behavior.acknowledge_memory"
            )
            self.assertEqual(behavior_record["owner"], "DTCommon")
            catalogs = conversation_translation_catalogs_by_owner(
                model,
                package_repositories={"DTCommon": dynamic_trading},
            )
            self.assertIn("DTCommon", catalogs)
            self.assertTrue(
                any(
                    values
                    for domains in catalogs["DTCommon"].values()
                    for values in domains.values()
                )
            )
            modules, reports = render_conversation_runtime_plan(model)
            by_source = {
                report.get("sourceShard"): (module, report)
                for (module, _source), report in zip(modules, reports)
                if report.get("sourceShard")
            }
            pattern_module, pattern_report = by_source[
                "patterns/common/greeting_whats_up.json"
            ]
            self.assertTrue(
                pattern_module.startswith(
                    "DTCommon/Semantics/Generated/Conversation/"
                ),
                pattern_module,
            )
            self.assertEqual(pattern_report["shardOwner"], "DTCommon")
            self.assertEqual(pattern_report["registryOwner"], "DTCommon")

            paths = write_conversation_output(
                hoomans,
                model,
                core_repository=core,
                dynamic_trading_repository=dynamic_trading,
            )
            registry = (
                dynamic_trading
                / "Contents/mods/DTCommon/common/media/lua/shared/"
                / "DTCommon/Semantics/Generated/Conversation/Registry.lua"
            )
            pack_module = (
                dynamic_trading
                / "Contents/mods/DTCommon/common/media/lua/shared/"
                / "DTCommon/Semantics/Generated/Conversation/Packs/"
                "Psdl/Dialogue/Trading.lua"
            )
            manifest_lua = registry.with_name("Manifest.lua")
            self.assertTrue(registry.is_file())
            self.assertTrue(pack_module.is_file())
            self.assertTrue(manifest_lua.is_file())
            self.assertTrue(
                any(
                    path.name == "Greeting.json"
                    and "DTCommon/common/media/translation" in str(path)
                    for path in paths
                )
            )
            self.assertIn("DTCommon.Semantics.ConversationRegistry", registry.read_text())
            self.assertIn('Registry.OWNER = "DTCommon"', registry.read_text())
            registry_text = registry.read_text(encoding="utf-8")
            self.assertIn("Registry.PACKS = {}", registry_text)
            self.assertIn(
                'DTCommon/Semantics/Generated/Conversation/Packs/Psdl/Dialogue/Trading',
                registry_text,
            )
            self.assertIn(
                '["registryOwner"] = "DTCommon"',
                manifest_lua.read_text(),
            )
            self.assertIn(registry, paths)
            self.assertFalse(
                (
                    hoomans
                    / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/"
                    "Semantics/Generated/Conversation/Registry.lua"
                ).exists()
            )

    def test_writer_places_core_and_hoomans_modules_in_separate_repositories(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            hoomans = root / "ProjectHoomans"
            core = root / "psychopatzCore"
            shutil.copytree(
                CORE_REPOSITORY / CONVERSATION_SOURCE_RELATIVE,
                hoomans / CONVERSATION_SOURCE_RELATIVE,
            )
            copy_pnc_psdl_sources(hoomans)
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
            core_foundation_registry = (
                core
                / "Contents/mods/PsychopatzCore/common/media/lua/shared/"
                / "PsychopatzCore/Semantics/Generated/Conversation/"
                "FoundationRegistry.lua"
            )
            core_check_in = (
                core
                / "Contents/mods/PsychopatzCore/common/media/lua/shared/"
                / "PsychopatzCore/Semantics/Generated/Conversation/UI/"
                "Psdl/Dialogue/CoreCheckIn.lua"
            )
            core_identity_dialogue = (
                core
                / "Contents/mods/PsychopatzCore/common/media/lua/shared/"
                / "PsychopatzCore/Semantics/Generated/Conversation/UI/"
                "Psdl/Dialogue/CoreIdentity.lua"
            )
            stale_hoomans_identity = (
                hoomans
                / "Contents/mods/ProjectHoomans/common/media/lua/shared/"
                / "PNC/Semantics/Generated/Conversation/Patterns/Common/Identity.lua"
            )
            hoomans_psdl = (
                hoomans
                / "Contents/mods/ProjectHoomans/common/media/lua/shared/"
                / "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/"
                "semantic_command_player_follow.lua"
            )
            registry = (
                hoomans
                / "Contents/mods/ProjectHoomans/common/media/lua/shared/"
                / "PNC/Semantics/Generated/Conversation/Registry.lua"
            )

            self.assertTrue(core_identity.is_file())
            self.assertTrue(core_foundation_registry.is_file())
            self.assertTrue(core_check_in.is_file())
            self.assertTrue(core_identity_dialogue.is_file())
            self.assertFalse(stale_hoomans_identity.exists())
            self.assertTrue(hoomans_psdl.is_file())
            self.assertIn(core_identity, paths)
            self.assertIn(core_foundation_registry, paths)
            self.assertIn(core_check_in, paths)
            self.assertIn(core_identity_dialogue, paths)
            foundation_text = core_foundation_registry.read_text(encoding="utf-8")
            self.assertIn(
                'Registry.REGISTRY_MODULE = '
                '"PsychopatzCore/Semantics/Generated/Conversation/FoundationRegistry"',
                foundation_text,
            )
            self.assertIn(
                '"PsychopatzCore/Semantics/Generated/Conversation/UI/Psdl/Dialogue/CoreCheckIn"',
                foundation_text,
            )
            self.assertIn(
                '"PsychopatzCore/Semantics/Generated/Conversation/UI/Psdl/Dialogue/CoreIdentity"',
                foundation_text,
            )
            registry_text = registry.read_text(encoding="utf-8")
            self.assertIn(
                'require "PsychopatzCore/Semantics/Generated/Conversation/'
                'Patterns/Common/Identity"',
                registry_text,
            )
            self.assertIn(
                'appendPSDL(require "PNC/Semantics/Generated/Conversation/'
                'PSDL/Dialogue/semantic_command_player_follow")',
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
