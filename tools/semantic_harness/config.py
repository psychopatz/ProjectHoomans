"""Compatibility facade for :mod:`tools.semantic_harness.runtime.config`."""

from __future__ import annotations

from .runtime.config import *  # noqa: F401,F403
from .runtime import config as _implementation


def __getattr__(name: str):
    """Preserve access to legacy private discovery helpers."""

    return getattr(_implementation, name)
