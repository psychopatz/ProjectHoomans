"""Compatibility facade for the Core-owned semantic activity stream."""

from __future__ import annotations

from semantic_harness.activity import (
    MAX_SHARED_BYTES,
    ActivityLog,
    default_activity_path,
    format_activity_event,
)

__all__ = [
    "ActivityLog",
    "MAX_SHARED_BYTES",
    "default_activity_path",
    "format_activity_event",
]
