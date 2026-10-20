"""Compatibility facade for :mod:`tools.semantic_harness.runtime.protocol`."""

from __future__ import annotations

from .runtime.protocol import *  # noqa: F401,F403
from .runtime import protocol as _implementation


def __getattr__(name: str):
    """Preserve access to legacy protocol helpers."""

    return getattr(_implementation, name)
