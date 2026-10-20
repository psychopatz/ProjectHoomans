"""Compatibility facade for :mod:`tools.semantic_harness.runtime.worker`."""

from __future__ import annotations

from .runtime.worker import *  # noqa: F401,F403
from .runtime import worker as _implementation


def __getattr__(name: str):
    """Preserve access to legacy worker helpers."""

    return getattr(_implementation, name)
