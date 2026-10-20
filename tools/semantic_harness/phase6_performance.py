"""Compatibility facade for :mod:`tools.semantic_harness.testing.performance`."""

from __future__ import annotations

from .testing.performance import *  # noqa: F401,F403
from .testing import performance as _implementation


def __getattr__(name: str):
    """Preserve access to legacy performance helpers."""

    return getattr(_implementation, name)


if __name__ == "__main__":
    raise SystemExit(_implementation.main())
