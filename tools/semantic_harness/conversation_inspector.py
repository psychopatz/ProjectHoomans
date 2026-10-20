"""Compatibility facade for :mod:`tools.semantic_harness.inspection.conversation_inspector`."""

from __future__ import annotations

from .inspection.conversation_inspector import *  # noqa: F401,F403
from .inspection import conversation_inspector as _implementation


def __getattr__(name: str):
    """Preserve access to legacy inspector helpers."""

    return getattr(_implementation, name)
