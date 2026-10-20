"""Compatibility facade for :mod:`tools.semantic_harness.testing.suite`."""

from __future__ import annotations

from .testing.suite import *  # noqa: F401,F403
from .testing import suite as _implementation


def __getattr__(name: str):
    """Preserve access to legacy Lua-suite helpers."""

    return getattr(_implementation, name)
