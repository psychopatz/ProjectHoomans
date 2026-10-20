"""Compatibility facade for :mod:`tools.semantic_harness.testing.runner`."""

from __future__ import annotations

from .testing.runner import *  # noqa: F401,F403
from .testing import runner as _implementation
import sys as _sys


def __getattr__(name: str):
    """Preserve access to legacy case-runner helpers."""

    return getattr(_implementation, name)


# Keep module-level constants and monkeypatches on the legacy path bound to the
# canonical implementation. Symbol-only re-exports cannot preserve that
# behavior for callers that patch bounded ledger limits.
_sys.modules[__name__] = _implementation
