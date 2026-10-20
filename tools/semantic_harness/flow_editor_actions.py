"""Compatibility facade for :mod:`tools.semantic_harness.ui.flow_editor.actions`."""

from __future__ import annotations

from .ui.flow_editor.actions import *  # noqa: F401,F403
from .ui.flow_editor import actions as _implementation


def __getattr__(name: str):
    """Preserve access to legacy Flow Editor action helpers."""

    return getattr(_implementation, name)
