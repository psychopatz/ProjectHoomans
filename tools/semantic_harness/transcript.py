"""Compatibility facade for :mod:`tools.semantic_harness.inspection.transcript`."""

from __future__ import annotations

from .inspection.transcript import *  # noqa: F401,F403
from .inspection import transcript as _implementation


def __getattr__(name: str):
    """Preserve access to legacy transcript helpers."""

    return getattr(_implementation, name)
