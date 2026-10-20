"""Compatibility facade for :mod:`tools.semantic_harness.ui.dialogs.settings`."""

from __future__ import annotations

from .ui.dialogs.settings import *  # noqa: F401,F403
from .ui.dialogs import settings as _implementation


def __getattr__(name: str):
    """Preserve access to legacy settings-dialog helpers."""

    return getattr(_implementation, name)
