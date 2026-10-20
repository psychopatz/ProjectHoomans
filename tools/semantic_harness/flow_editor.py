"""Compatibility facade for :mod:`tools.semantic_harness.ui.flow_editor.pane`."""

from __future__ import annotations

from .ui.flow_editor.pane import *  # noqa: F401,F403
from .ui.flow_editor import pane as _implementation


def __getattr__(name: str):
    """Preserve access to legacy Flow Editor pane helpers."""

    return getattr(_implementation, name)
