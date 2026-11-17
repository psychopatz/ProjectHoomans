"""Shared hermetic helpers for Semantic Lab Tk integration tests."""

from __future__ import annotations

from pathlib import Path
import gc
import os
import sqlite3
import struct
import tempfile
import time

os.environ["XMODIFIERS"] = "@im=none"

import tkinter as tk
import unittest
from typing import Any, Callable, Iterable

from tools.providers.pnc.runtime.player_engine_state import PLAYER_WORLD_VERSION
from tools.providers.pnc.tests.save_test_support import pz_file
from tools.semantic_harness.entrypoints.cli import _parser
from tools.semantic_harness.runtime.save_catalog import SaveCatalog
from tools.semantic_harness.ui.shell import SemanticHarnessApp


def _pz_utf(text: str) -> bytes:
    raw = text.encode("utf-8")
    return struct.pack(">h", len(raw)) + raw


def _kahlua_string_table(entries: dict[str, str]) -> bytes:
    parts = [struct.pack(">i", len(entries))]
    for key, value in entries.items():
        parts.append(b"\x00" + _pz_utf(key))
        parts.append(b"\x00" + _pz_utf(value))
    return b"".join(parts)


def _synthetic_player_blob(
    *,
    character_uuid: str,
    account_key: str,
    inventory_registry_ids: tuple[tuple[int, int], ...],
) -> bytes:
    parts = [
        b"\x01\x01",  # IsoPlayer serialise flag + IsoObject class id
        b"\x00" * 24,  # IsoMovingObject offsets/position (20) + forward (4)
        b"\x01",  # has modData
        _kahlua_string_table(
            {
                "PNC_CharacterUUID": character_uuid,
                "PNC_CharacterAccountKey": account_key,
                "PNC_CharacterIdentityVersion": "1",
            }
        ),
        b"\x00",  # no SurvivorDesc prefix required
        b"\x00",  # HumanVisual flags
        b"\x00\x00\x00",  # body hair, skin texture, rotation stage
        b"\x00\x00\x00",  # 3 zero-length HumanVisual byte arrays
        b"\x00",  # 0 ItemVisuals
        _pz_utf(""),  # non-attached hair
        b"\x00",  # trailing HumanVisual flags
        _pz_utf("inventory"),
        b"\x01",  # explored
        struct.pack(">h", len(inventory_registry_ids)),
    ]
    next_item_id = 100
    for registry_id, stack in inventory_registry_ids:
        payload = struct.pack(">hB", registry_id, 0)
        parts.append(struct.pack(">ii", stack, len(payload)))
        parts.append(payload)
        for _ in range(stack - 1):
            parts.append(struct.pack(">i", next_item_id))
            next_item_id += 1
    parts.append(b"\x00")  # hasBeenLooted
    parts.append(struct.pack(">i", 50))  # capacity
    return b"".join(parts)


def _write_synthetic_save_slot(
    slot_dir: Path,
    *,
    player_name: str,
    player_uuid: str,
    npc_id: str,
    npc_display: str,
) -> Path:
    slot_dir.mkdir(parents=True, exist_ok=True)
    save_path = slot_dir / "global_mod_data.bin"
    tables = [
        (
            "PNC_PlayerCharacters",
            [
                ("schemaVersion", 6),
                (
                    "byUUID",
                    {
                        player_uuid: {
                            "uuid": player_uuid,
                            "accountKey": "slot_0",
                            "displayName": player_name,
                            "forename": player_name.split()[0],
                            "surname": player_name.split()[-1],
                            "status": "active",
                        }
                    },
                ),
            ],
        ),
        ("PNC_Core_Global", [("schemaVersion", 16), ("layoutVersion", 2)]),
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
                            "status": "active",
                            "memberIDs": {npc_id: True},
                        }
                    },
                ),
            ],
        ),
        (
            f"PNC_{npc_id}",
            [
                ("schemaVersion", 16),
                ("recordRevision", 12),
                ("id", npc_id),
                (
                    "identity",
                    {
                        "displayName": npc_display,
                        "isFemale": False,
                        "archetypeID": "General",
                        "seed": 42,
                        "survivor": {
                            "forename": npc_display.split()[0],
                            "surname": npc_display.split()[-1],
                        },
                    },
                ),
                (
                    "affiliation",
                    {
                        "factionID": "faction_saved",
                        "communityID": "community_saved",
                    },
                ),
                (
                    "hostility",
                    {"mode": "defend_owner", "attackPlayers": False},
                ),
                ("orderSpec", {"kind": "follow"}),
                ("generation", {"source": "WORLD_POPULATION_DIRECTOR"}),
                (
                    "inventory",
                    {
                        "items": {
                            1: {
                                "itemID": "npc_apple_1",
                                "fullType": "Base.Apple",
                                "displayName": "Apple",
                                "stack": 1,
                            }
                        }
                    },
                ),
                (
                    "social",
                    {
                        "relationships": {
                            f"player:slot_0:{player_uuid}": {
                                "approval": 60,
                                "trust": 50,
                                "fear": 5,
                            }
                        }
                    },
                ),
            ],
        ),
        (
            "PNC_npcTrader",
            [
                ("schemaVersion", 16),
                ("id", "npcTrader"),
                ("identity", {"displayName": "Trader Saved"}),
                ("affiliation", {"originArchetypeID": "trader"}),
                ("hostility", {"mode": "neutral"}),
                ("orderSpec", {"kind": "roam"}),
                ("generation", {"source": "dynamic_trading"}),
            ],
        ),
        (
            "PNC_npcHostile",
            [
                ("schemaVersion", 16),
                ("id", "npcHostile"),
                ("identity", {"displayName": "Hostile Saved"}),
                ("affiliation", {}),
                ("hostility", {"mode": "hostile", "attackPlayers": True}),
                ("orderSpec", {"kind": "roam"}),
                ("generation", {}),
            ],
        ),
    ]
    save_path.write_bytes(pz_file(tables, world_version=PLAYER_WORLD_VERSION))
    (slot_dir / "mods.txt").write_text(
        'VERSION = 1,\n\nmods\n{\n  "PsychopatzCore",\n  "ProjectHoomans",\n}\n',
        encoding="utf-8",
    )
    (slot_dir / "WorldDictionaryReadable.lua").write_text(
        'items = {\n'
        '\t{\n\t\tregistryID = 1,\n\t\tfulltype = "Base.Bandage",\n\t},\n'
        '\t{\n\t\tregistryID = 2,\n\t\tfulltype = "Base.Apple",\n\t},\n'
        '}\n',
        encoding="utf-8",
    )
    blob = _synthetic_player_blob(
        character_uuid=player_uuid,
        account_key="slot_0",
        inventory_registry_ids=((1, 2), (2, 1)),
    )
    connection = sqlite3.connect(slot_dir / "players.db")
    try:
        connection.execute(
            "CREATE TABLE localPlayers ("
            "id INTEGER PRIMARY KEY, name STRING, wx INTEGER, wy INTEGER, "
            "x FLOAT, y FLOAT, z FLOAT, worldversion INTEGER, data BLOB, isDead BOOLEAN)"
        )
        connection.execute(
            "INSERT INTO localPlayers VALUES (1, ?, 0, 0, 0, 0, 0, ?, ?, 0)",
            (player_name, PLAYER_WORLD_VERSION, blob),
        )
        connection.commit()
    finally:
        connection.close()
    return save_path


def install_synthetic_save_root(test_case: unittest.TestCase) -> Path:
    """Install an isolated PZ_SAVE_ROOT with complete synthetic saves."""

    directory = tempfile.TemporaryDirectory(prefix="pnc-synthetic-saves-")
    test_case.addCleanup(directory.cleanup)
    previous = os.environ.get("PZ_SAVE_ROOT")

    def _restore() -> None:
        if previous is None:
            os.environ.pop("PZ_SAVE_ROOT", None)
        else:
            os.environ["PZ_SAVE_ROOT"] = previous

    test_case.addCleanup(_restore)
    save_root = Path(directory.name)
    primary = _write_synthetic_save_slot(
        save_root / "Apocalypse" / "2026-10-14_13-57-03",
        player_name="Loaded Player",
        player_uuid="char_saved",
        npc_id="npcAdamBloom_48G5",
        npc_display="Adam Bloom",
    )
    _write_synthetic_save_slot(
        save_root / "Apocalypse" / "2026-10-13_09-00-00",
        player_name="Secondary Player",
        player_uuid="char_second",
        npc_id="npcSecondary",
        npc_display="Elena Moss",
    )
    os.environ["PZ_SAVE_ROOT"] = str(save_root)
    return primary


def require_supported_save(test_case: unittest.TestCase) -> dict[str, Any]:
    """Skip save-backed GUI coverage when no verified local save is present."""

    catalog = SaveCatalog().discover()
    saves = [
        entry for entry in catalog.get("saves", [])
        if isinstance(entry, dict)
        and (entry.get("capabilities") or {}).get("projectHoomans")
    ]
    if not saves:
        test_case.skipTest("no compatible offline save is available")
    return {**catalog, "saves": saves}


class SemanticLabGuiTestCase(unittest.TestCase):
    """Create GUI tests with isolated, fixture-first UI state by default."""

    def setUp(self) -> None:
        super().setUp()
        os.environ["XMODIFIERS"] = "@im=none"

    def new_ui_state_path(self, prefix: str = "semantic-lab-test-") -> Path:
        directory = tempfile.TemporaryDirectory(prefix=prefix)
        self.addCleanup(directory.cleanup)
        return Path(directory.name) / "ui-state.json"

    def install_synthetic_save_root(self) -> Path:
        return install_synthetic_save_root(self)

    def require_supported_save(self) -> dict[str, Any]:
        return require_supported_save(self)

    def gui_arguments(
        self,
        *extra_args: str,
        ui_state_path: Path | None = None,
        reset: bool = True,
    ) -> Any:
        """Build arguments that cannot read the developer's default state."""

        state_path = ui_state_path or self.new_ui_state_path()
        values = ["--gui", "--ui-state", str(state_path)]
        if reset:
            values.append("--reset-ui-state")
        values.extend(extra_args)
        return _parser().parse_args(values)

    def make_gui_app(
        self,
        root: tk.Misc,
        *extra_args: str,
        ui_state_path: Path | None = None,
        reset: bool = True,
    ) -> SemanticHarnessApp:
        """Construct and clean up a fixture-first Semantic Lab application."""

        os.environ["XMODIFIERS"] = "@im=none"
        app = SemanticHarnessApp(
            root,
            self.gui_arguments(
                *extra_args,
                ui_state_path=ui_state_path,
                reset=reset,
            ),
        )
        self.addCleanup(self.close_gui_app, app, root)
        return app

    @staticmethod
    def close_gui_app(app: SemanticHarnessApp, root: tk.Misc) -> None:
        if not getattr(app, "__dict__", None):
            try:
                root.destroy()
            except tk.TclError:
                pass
            return
        # SemanticHarnessApp deliberately uses a nonblocking production close
        # so an interactive window never freezes while a serialized worker
        # request drains.  Tests own the process boundary, so finish any
        # queued work before destroying the last Tk references.
        session = getattr(app, "session", None)
        if session is not None:
            session.close(wait=True)
        try:
            app.close()
        except tk.TclError:
            pass
        authoring_service = getattr(app, "authoring_service", None)
        if authoring_service is not None and hasattr(authoring_service, "close"):
            try:
                authoring_service.close()
            except Exception:
                pass
        try:
            root.destroy()
        except tk.TclError:
            pass
        # Release Tk variables/widgets while this fixture is still executing
        # on the main thread.  Otherwise cyclic app state can be collected by
        # a later worker-thread teardown and tkinter reports a wrong-thread
        # async-handler deletion when the next test creates its root.
        app.__dict__.clear()
        gc.collect()

    def wait_for(
        self,
        root: tk.Misc,
        predicate: Callable[[], bool],
        message: str,
        *,
        timeout: float = 20.0,
    ) -> None:
        deadline = time.monotonic() + timeout
        while not predicate() and time.monotonic() < deadline:
            try:
                root.update()
            except tk.TclError:
                break
            time.sleep(0.01)
        self.assertTrue(predicate(), message)

    def wait_for_worker_ready(
        self, root: tk.Misc, app: SemanticHarnessApp, *, timeout: float = 20.0
    ) -> None:
        self.wait_for(
            root,
            lambda: app.worker_ready,
            "timed out waiting for the production Lua worker",
            timeout=timeout,
        )

    def wait_for_explore_loaded(
        self, root: tk.Misc, app: SemanticHarnessApp, *, timeout: float = 20.0
    ) -> None:
        self.wait_for(
            root,
            lambda: app.observatory.catalog_ready
            and not app.observatory.loading,
            "timed out waiting for the bounded Explore catalog page",
            timeout=timeout,
        )

    def wait_for_operation(
        self, root: tk.Misc, app: SemanticHarnessApp, *, timeout: float = 20.0
    ) -> None:
        self.wait_for(
            root,
            lambda: not app.busy,
            "timed out waiting for the foreground worker operation",
            timeout=timeout,
        )


__all__ = ["SemanticLabGuiTestCase", "require_supported_save"]
