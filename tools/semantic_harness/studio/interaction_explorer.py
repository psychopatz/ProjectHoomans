"""Compatibility facade for the canonical interaction catalog projection."""

from __future__ import annotations

from ..codebuilder.interaction_explorer import *  # noqa: F401,F403
from ..codebuilder import interaction_explorer as _implementation


def __getattr__(name: str):
    """Preserve the historical Studio interaction-explorer surface."""

    return getattr(_implementation, name)
