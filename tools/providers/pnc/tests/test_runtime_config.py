"""Runtime-version discovery tests shared by the harness and Lua smoke runner."""

from __future__ import annotations

from pathlib import Path
import tempfile
import unittest

from tools.semantic_harness.runtime.config import (
    ConfigurationError,
    HarnessConfig,
    build_worker_launch_spec,
)
from tools.semantic_harness.discovery.runtime import (
    discover_newest_runtime,
    discover_shared_runtime,
)


REPOSITORY = Path(__file__).resolve().parents[4]
CORE_REPOSITORY = REPOSITORY.parent / "psychopatzCore"


class RuntimeConfigTests(unittest.TestCase):
    def test_discover_newest_runtime_uses_numeric_order(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("common", "42.9", "42.20", "42.21", "notes"):
                (root / name).mkdir()

            self.assertEqual(discover_newest_runtime(root), "42.21")

    def test_discover_newest_runtime_rejects_missing_numeric_directory(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "common").mkdir()

            with self.assertRaises(ConfigurationError):
                discover_newest_runtime(root)

    def test_dynamic_trading_uses_newest_shared_module_runtime(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for module in ("DTCommon", "DTHoomans"):
                module_root = root / "Contents/mods" / module
                (module_root / "42.20").mkdir(parents=True)
            (root / "Contents/mods/DTCommon/42.21").mkdir()

            self.assertEqual(
                discover_shared_runtime(root, ("DTCommon", "DTHoomans")),
                "42.20",
            )

    def test_core_profile_selects_core_worker_without_hoomans_runtime(self) -> None:
        config = HarnessConfig.discover(
            repository=REPOSITORY,
            core_repository=CORE_REPOSITORY,
            lua_bin="lua",
            profile="core",
        )

        self.assertEqual(config.profile, "core")
        self.assertNotIn("ProjectHoomans", config.provider_ids)
        self.assertNotIn(
            "ProjectHoomans",
            (config.activation_plan or {}).get("repositories", {}),
        )
        self.assertEqual(
            config.worker_script,
            (
            CORE_REPOSITORY
            / "tools/semantic_harness/lua/worker.lua"
            ).resolve(),
        )

    def test_pnc_profile_uses_core_launch_metadata(self) -> None:
        config = HarnessConfig.discover(
            repository=REPOSITORY,
            core_repository=CORE_REPOSITORY,
            lua_bin="lua",
            profile="pnc",
        )
        spec = build_worker_launch_spec(config)
        self.assertIn("PsychopatzCore", spec.provider_ids)
        self.assertIn("ProjectHoomans", spec.provider_ids)
        if "DTCommon" in config.provider_ids:
            self.assertIn("DTCommon", spec.provider_ids)
            self.assertIn("DTHoomans", spec.provider_ids)
        self.assertEqual(spec.materialization_mode, "physical")
        self.assertEqual(
            spec.neutral_environment()["SEMANTIC_HARNESS_MATERIALIZATION_MODE"],
            "physical",
        )


if __name__ == "__main__":
    unittest.main()
