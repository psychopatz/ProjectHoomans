"""Compatibility facade for :mod:`tools.semantic_harness.runtime.worker_session`."""

from __future__ import annotations

from .runtime.worker_session import *  # noqa: F401,F403
from .runtime import worker_session as _implementation


def __getattr__(name: str):
    """Preserve access to legacy worker-session helpers."""

    return getattr(_implementation, name)
