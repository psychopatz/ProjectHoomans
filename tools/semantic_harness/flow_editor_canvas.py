"""Compatibility facade for :mod:`tools.semantic_harness.ui.flow_editor.canvas`."""

from __future__ import annotations

from .ui.flow_editor.canvas import *  # noqa: F401,F403
from .ui.flow_editor import canvas as _implementation


def __getattr__(name: str):
    """Preserve access to legacy Flow Editor canvas helpers."""

    return getattr(_implementation, name)
