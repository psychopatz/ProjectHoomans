"""Compatibility facade for :mod:`tools.semantic_harness.runtime.scenario`."""

from __future__ import annotations

from .runtime.scenario import *  # noqa: F401,F403
from .runtime import scenario as _implementation


def __getattr__(name: str):
    """Preserve access to legacy scenario helpers."""

    return getattr(_implementation, name)
