"""Compatibility facade for :mod:`tools.semantic_harness.ui.flow_editor.model`."""

from __future__ import annotations

from .ui.flow_editor.model import *  # noqa: F401,F403
from .ui.flow_editor import model as _implementation


def __getattr__(name: str):
    """Preserve access to legacy Flow Editor model helpers."""

    return getattr(_implementation, name)
