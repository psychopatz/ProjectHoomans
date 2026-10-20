"""Compatibility facade for :mod:`tools.semantic_harness.studio.workflow`."""

from __future__ import annotations

from .studio.workflow import *  # noqa: F401,F403
from .studio import workflow as _implementation


def __getattr__(name: str):
    """Preserve access to legacy workflow helpers."""

    return getattr(_implementation, name)
