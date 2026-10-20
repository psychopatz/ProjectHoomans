"""Compatibility facade for :mod:`tools.semantic_harness.studio.block_registry`."""

from __future__ import annotations

from .studio.block_registry import *  # noqa: F401,F403
from .studio import block_registry as _implementation


def __getattr__(name: str):
    """Preserve access to legacy block-registry helpers."""

    return getattr(_implementation, name)
