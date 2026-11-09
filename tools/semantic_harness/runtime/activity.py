"""Compatibility facade for the Core-owned semantic activity stream."""

from __future__ import annotations

import importlib
import sys
from pathlib import Path


def _load_core_activity():
    repository = Path(__file__).resolve().parents[3].parent / "psychopatzCore"
    tools_root = repository / "tools"
    rendered = str(tools_root)
    if rendered not in sys.path:
        sys.path.insert(0, rendered)
    return importlib.import_module("semantic_harness.activity")


_CORE_ACTIVITY = _load_core_activity()
ActivityLog = _CORE_ACTIVITY.ActivityLog
default_activity_path = _CORE_ACTIVITY.default_activity_path
format_activity_event = _CORE_ACTIVITY.format_activity_event
MAX_SHARED_BYTES = _CORE_ACTIVITY.MAX_SHARED_BYTES

__all__ = [
    "ActivityLog",
    "MAX_SHARED_BYTES",
    "default_activity_path",
    "format_activity_event",
]
