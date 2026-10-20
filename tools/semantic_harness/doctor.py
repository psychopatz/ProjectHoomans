"""Compatibility facade for :mod:`tools.semantic_harness.testing.doctor`."""

from __future__ import annotations

from .testing.doctor import *  # noqa: F401,F403
from .testing import doctor as _implementation


def __getattr__(name: str):
    """Preserve access to legacy doctor helpers."""

    return getattr(_implementation, name)
