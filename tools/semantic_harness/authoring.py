"""Compatibility facade for :mod:`tools.semantic_harness.studio.authoring`."""

from __future__ import annotations

from .studio.authoring import *  # noqa: F401,F403
from .studio import authoring as _implementation


def __getattr__(name: str):
    """Preserve access to legacy authoring helpers and constants."""

    return getattr(_implementation, name)
