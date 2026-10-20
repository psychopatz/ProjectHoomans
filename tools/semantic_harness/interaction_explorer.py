"""Compatibility facade for :mod:`tools.semantic_harness.studio.interaction_explorer`."""

from __future__ import annotations

from .studio.interaction_explorer import *  # noqa: F401,F403
from .studio import interaction_explorer as _implementation


def __getattr__(name: str):
    """Preserve access to legacy interaction-explorer helpers."""

    return getattr(_implementation, name)
