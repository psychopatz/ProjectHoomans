"""Compatibility facade for :mod:`tools.semantic_harness.codebuilder.interaction_explorer`."""

from __future__ import annotations

from .codebuilder.interaction_explorer import *  # noqa: F401,F403
from .codebuilder import interaction_explorer as _implementation


def __getattr__(name: str):
    """Preserve access to legacy interaction-explorer helpers."""

    return getattr(_implementation, name)
