"""Compatibility facade for :mod:`tools.semantic_harness.studio.dataset_library`."""

from __future__ import annotations

from .studio.dataset_library import *  # noqa: F401,F403
from .studio import dataset_library as _implementation


def __getattr__(name: str):
    """Preserve access to legacy dataset-library helpers."""

    return getattr(_implementation, name)
