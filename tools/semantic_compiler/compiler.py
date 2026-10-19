"""Compatibility wrapper for Semantic Lab's embedded CodeBuilder compiler."""

from __future__ import annotations

from tools.semantic_harness.codebuilder.compiler import *  # noqa: F401,F403
from tools.semantic_harness.codebuilder import compiler as _implementation


def __getattr__(name: str):
    """Keep legacy access to private implementation helpers when required."""
    return getattr(_implementation, name)
