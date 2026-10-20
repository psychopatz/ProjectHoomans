"""Compatibility facade for :mod:`tools.semantic_harness.codebuilder.authoring`."""

from __future__ import annotations

from .codebuilder.authoring import *  # noqa: F401,F403
from .codebuilder import authoring as _implementation


def __getattr__(name: str):
    """Preserve access to legacy authoring helpers and constants."""

    return getattr(_implementation, name)
