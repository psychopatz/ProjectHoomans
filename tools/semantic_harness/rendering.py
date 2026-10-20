"""Compatibility facade for :mod:`tools.semantic_harness.inspection.rendering`."""

from __future__ import annotations

from .inspection.rendering import *  # noqa: F401,F403
from .inspection import rendering as _implementation


def __getattr__(name: str):
    """Preserve access to legacy rendering helpers."""

    return getattr(_implementation, name)
