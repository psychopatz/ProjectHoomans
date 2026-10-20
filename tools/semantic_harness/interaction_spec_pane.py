"""Compatibility facade for :mod:`tools.semantic_harness.studio.interaction_spec_pane`."""

from __future__ import annotations

from .studio.interaction_spec_pane import *  # noqa: F401,F403
from .studio import interaction_spec_pane as _implementation


def __getattr__(name: str):
    """Preserve access to legacy interaction-spec pane helpers."""

    return getattr(_implementation, name)
