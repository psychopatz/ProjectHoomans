"""Compatibility re-export for Core-owned source/working-world state."""

from __future__ import annotations

import importlib

from .process import _load_core_process


_load_core_process()
_CORE_STATE = importlib.import_module("semantic_harness.state")

HarnessWorkingWorld = _CORE_STATE.HarnessWorkingWorld
ImportedSourceSnapshot = _CORE_STATE.ImportedSourceSnapshot
PROVENANCE_SCHEMA = _CORE_STATE.PROVENANCE_SCHEMA
Provenance = _CORE_STATE.Provenance
SOURCE_SNAPSHOT_SCHEMA = _CORE_STATE.SOURCE_SNAPSHOT_SCHEMA
WORKING_WORLD_SCHEMA = _CORE_STATE.WORKING_WORLD_SCHEMA

__all__ = [
    "HarnessWorkingWorld",
    "ImportedSourceSnapshot",
    "PROVENANCE_SCHEMA",
    "Provenance",
    "SOURCE_SNAPSHOT_SCHEMA",
    "WORKING_WORLD_SCHEMA",
]
