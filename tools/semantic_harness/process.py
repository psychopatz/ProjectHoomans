"""Compatibility facade for :mod:`tools.semantic_harness.runtime.process`."""

from __future__ import annotations

from .runtime.process import *  # noqa: F401,F403
from .runtime import process as _implementation


def __getattr__(name: str):
    """Preserve access to legacy process helpers."""

    return getattr(_implementation, name)
