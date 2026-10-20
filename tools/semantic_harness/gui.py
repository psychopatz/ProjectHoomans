"""Compatibility facade for :mod:`tools.semantic_harness.ui.shell`."""

from __future__ import annotations

from .ui.shell import *  # noqa: F401,F403
from .ui import shell as _implementation


def __getattr__(name: str):
    """Preserve access to legacy GUI helpers."""

    return getattr(_implementation, name)
