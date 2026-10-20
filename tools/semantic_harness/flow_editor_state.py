"""Compatibility facade for :mod:`tools.semantic_harness.ui.flow_editor.state`."""

from __future__ import annotations

from .ui.flow_editor.state import *  # noqa: F401,F403
from .ui.flow_editor import state as _implementation


def __getattr__(name: str):
    """Preserve access to legacy Flow Editor state helpers."""

    return getattr(_implementation, name)
